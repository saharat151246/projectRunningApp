import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../theme/app_theme.dart';
import '../../config/map_config.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/map_attribution.dart';
import '../../services/stats_service.dart';
import '../../services/run_service.dart';
import '../../services/coach_service.dart';
import '../mood/mood_checkin_screen.dart';
import '../coach/coach_chat_screen.dart';

/// หน้าจอติดตามการวิ่งด้วย GPS จริง
/// - ขอ permission ตำแหน่งจากอุปกรณ์
/// - ฟัง position stream แบบ real-time
/// - คำนวณระยะทางจริงจากพิกัด GPS ที่เปลี่ยนไป
/// - วาดเส้นทางบนแผนที่ (OpenStreetMap ผ่าน flutter_map)
///
/// โครงจอ: แผนที่เต็มจอเป็นชั้นล่างสุด ด้านบนลอย "stage sheet" (DraggableScrollableSheet)
/// ที่ลากขึ้น-ลงได้ 2 ระดับ:
///   - Peek (~30% จอ)  : แถบสถิติย่อ + ปุ่มเริ่ม/หยุด (คล้ายวิดเจ็ต Google Fit/แผนที่)
///   - Full (100% จอ)  : มุมมองสถิติเต็มจอ (RunStatsView) พร้อมกราฟ splits รายกม.
class TrackingScreen extends StatefulWidget {
  const TrackingScreen({super.key});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  Timer? _secondTimer;
  StreamSubscription<Position>? _positionStream;
  final MapController _mapController = MapController();
  CoachAdvice? _coachAdvice;

  // ควบคุม stage sheet (ลาก/สั่งขยับจากปุ่มขยาย-ย่อ)
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();
  static const double _peekSize = 0.30;
  static const double _fullSize = 1.0;
  static const double _expandThreshold = 0.65; // เกินค่านี้ถือว่า "เต็มจอ" แล้ว
  final ValueNotifier<double> _sheetExtentNotifier = ValueNotifier(_peekSize);

  int _seconds = 0;
  bool _isRunning = false;
  bool _isPaused = false;
  DateTime?
      _runStartTime; // เวลาเริ่มวิ่งจริง (ตั้งครั้งเดียวตอนกดเริ่ม ไม่ถูกรีเซ็ตตอน resume)

  double _totalDistanceMeters = 0;
  Position? _lastPosition;
  final List<LatLng> _routePoints = [];
  final List<DateTime> _routeTimestamps =
      []; // เวลาที่บันทึกแต่ละจุด คู่กับ _routePoints

  // ติดตามช่วง (split) ปัจจุบัน เพื่อคำนวณเพซแยกรายกม.
  int _splitSeconds = 0;
  double _splitStartDistanceMeters = 0;
  final List<double> _completedSplitPaces = [];
  final ValueNotifier<List<double>> _splitsNotifier = ValueNotifier(const []);
  final ValueNotifier<double> _currentSplitPaceNotifier = ValueNotifier(0);

  // ค่าที่เปลี่ยนบ่อยมาก (ทุกวินาที/ทุกครั้งที่ GPS ขยับ) แยกออกมาเป็น ValueNotifier
  // แทนการ setState() ทั้งจอ เพื่อให้เฉพาะตัวเลข/เส้นทางบนแผนที่อัปเดต ไม่ต้อง build()
  // ปุ่มกด, แผนที่ทั้งก้อน, ฯลฯ ใหม่ทุกวินาที - ช่วยให้จอลื่นขึ้นมากตอนกำลังวิ่งจริง
  final ValueNotifier<int> _secondsNotifier = ValueNotifier(0);
  final ValueNotifier<double> _distanceNotifier = ValueNotifier(0);
  final ValueNotifier<List<LatLng>> _routeNotifier = ValueNotifier(const []);

  // สถานะ permission/GPS
  bool _checkingPermission = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initLocation();
    _checkCoachWarning();
  }

  Future<void> _checkCoachWarning() async {
    final advice = await CoachService.instance.fetchAdvice();
    if (!mounted) return;
    setState(() => _coachAdvice = advice);
  }

  Future<void> _initLocation() async {
    setState(() {
      _checkingPermission = true;
      _errorMessage = null;
    });

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _checkingPermission = false;
        _errorMessage =
            'กรุณาเปิด GPS/Location Service ของอุปกรณ์ก่อนเริ่มวิ่ง';
      });
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _checkingPermission = false;
          _errorMessage = 'แอปต้องการสิทธิ์เข้าถึงตำแหน่งเพื่อบันทึกการวิ่ง';
        });
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _checkingPermission = false;
        _errorMessage =
            'สิทธิ์ตำแหน่งถูกปฏิเสธถาวร กรุณาเปิดใน Settings ของอุปกรณ์';
      });
      return;
    }

    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw TimeoutException(
              'รอสัญญาณ GPS นานเกินไป (ถ้าใช้ Emulator ต้องตั้งค่าตำแหน่งจำลองใน Extended Controls > Location ก่อน)');
        },
      );
      setState(() {
        _checkingPermission = false;
        _routePoints.add(LatLng(pos.latitude, pos.longitude));
        _routeTimestamps.add(DateTime.now());
      });
      _routeNotifier.value = List<LatLng>.from(_routePoints);
    } catch (e) {
      setState(() {
        _checkingPermission = false;
        _errorMessage =
            e is TimeoutException ? e.message : 'ไม่สามารถดึงตำแหน่งได้: $e';
      });
    }
  }

  void _onStartPressed() {
    if (_coachAdvice != null &&
        (_coachAdvice!.overtrainingRisk || _coachAdvice!.fatigueSignal)) {
      _showOvertrainingDialog();
    } else {
      _start();
    }
  }

  void _showOvertrainingDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFE82A2A)),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'แจ้งเตือนเสี่ยงบาดเจ็บ',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFC01C1C)),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _coachAdvice?.overtrainingRisk == true
                  ? 'สัปดาห์นี้ระยะทางวิ่งของคุณเพิ่มขึ้นเกินเกณฑ์ปลอดภัย 10%/สัปดาห์ การออกกำลังกายหนักต่อเนื่องอาจเพิ่มความเสี่ยงบาดเจ็บ'
                  : 'ตรวจพบสัญญาณเหนื่อยล้าสะสมจากการเช็คอินย้อนหลังหลายครั้ง ร่างกายต้องการการพักฟื้นเพิ่มเติม',
              style: const TextStyle(fontSize: 13.5, height: 1.4),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1F0),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                '💡 คำแนะนำ: แนะนำให้วิ่งเพซสบายๆ หรือลดระยะทางในการวิ่งครั้งนี้ลง 20-30%',
                style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF991B1B),
                    fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CoachChatScreen()),
              );
            },
            child: const Text('ปรึกษา AI Coach'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE82A2A),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _start();
            },
            child: const Text('รับทราบและเริ่มวิ่ง'),
          ),
        ],
      ),
    );
  }

  void _start() {
    _runStartTime ??= DateTime.now();
    setState(() {
      _isRunning = true;
      _isPaused = false;
    });

    // ติ๊กทุกวินาที: อัปเดตแค่ ValueNotifier ไม่ setState() ทั้งจอ
    _secondTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _seconds++;
      _splitSeconds++;
      _secondsNotifier.value = _seconds;
      _updateCurrentSplitPace();
    });

    late final LocationSettings settings;
    if (defaultTargetPlatform == TargetPlatform.android) {
      settings = AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 3,
        forceLocationManager: true,
        intervalDuration: const Duration(seconds: 1),
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationText: 'RunMate กำลังบันทึกพิกัดการวิ่งในเบื้องหลัง',
          notificationTitle: 'กำลังวิ่งอยู่...',
          enableWifiLock: true,
        ),
      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      settings = AppleSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 3,
        activityType: ActivityType.fitness,
        allowBackgroundLocationUpdates: true,
        showBackgroundLocationIndicator: true,
      );
    } else {
      settings = const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 3,
      );
    }

    _positionStream = Geolocator.getPositionStream(locationSettings: settings)
        .listen(_onPositionUpdate);
  }

  /// อัปเดตเพซของช่วงกม.ปัจจุบันที่ยังวิ่งไม่ครบ (live split) - เรียกทุกวินาที
  void _updateCurrentSplitPace() {
    final splitDistanceKm =
        (_totalDistanceMeters - _splitStartDistanceMeters) / 1000;
    final pace =
        splitDistanceKm > 0.01 ? (_splitSeconds / 60) / splitDistanceKm : 0.0;
    _currentSplitPaceNotifier.value = pace;
  }

  void _onPositionUpdate(Position position) {
    final newPoint = LatLng(position.latitude, position.longitude);

    if (_lastPosition != null) {
      final segmentMeters = Geolocator.distanceBetween(
        _lastPosition!.latitude,
        _lastPosition!.longitude,
        position.latitude,
        position.longitude,
      );
      if (segmentMeters > 2) {
        _totalDistanceMeters += segmentMeters;
      }
    }

    _lastPosition = position;
    _routePoints.add(newPoint);
    _routeTimestamps.add(DateTime.now());

    // ทุกครั้งที่ระยะทางรวมข้ามหลักกม.ใหม่ ปิดช่วง (split) เดิมแล้วบันทึกเพซของกม.นั้น
    while (_totalDistanceMeters - _splitStartDistanceMeters >= 1000) {
      final splitPace = _splitSeconds > 0 ? (_splitSeconds / 60) / 1.0 : 0.0;
      _completedSplitPaces.add(splitPace);
      _splitsNotifier.value = List<double>.from(_completedSplitPaces);
      _splitStartDistanceMeters += 1000;
      _splitSeconds = 0;
    }
    _updateCurrentSplitPace();

    // อัปเดตเฉพาะ ValueNotifier - ไม่ setState() ทั้งจอทุกครั้งที่ GPS ขยับ
    // (เดิมเรียก setState() ตรงนี้ ทำให้ทั้งแผนที่/ปุ่ม/ข้อความ rebuild ใหม่หมดทุกจุด GPS)
    _routeNotifier.value = List<LatLng>.from(_routePoints);
    _distanceNotifier.value = _totalDistanceMeters;

    _mapController.move(newPoint, _mapController.camera.zoom);
  }

  void _pauseResume() {
    if (_isPaused) {
      // Resume existing stream + timer instead of creating new ones
      _positionStream?.resume();
      _secondTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        _seconds++;
        _splitSeconds++;
        _secondsNotifier.value = _seconds;
        _updateCurrentSplitPace();
      });
      setState(() => _isPaused = false);
    } else {
      _secondTimer?.cancel();
      _positionStream?.pause();
      setState(() => _isPaused = true);
    }
  }

  Future<void> _stop() async {
    _secondTimer?.cancel();
    _positionStream?.cancel();

    final distanceKm = _totalDistanceMeters / 1000;
    final paceMinPerKm = distanceKm > 0 ? (_seconds / 60) / distanceKm : 0.0;
    final endTime = DateTime.now();
    final startTime = _runStartTime ?? endTime;

    // บันทึกสถิติ/เหรียญ/ภารกิจไว้ในเครื่อง (ยังคงไว้เพื่อ Gamification)
    final result = await StatsService.instance.recordRun(
      distanceKm: distanceKm,
      durationSeconds: _seconds,
      completedAt: endTime,
    );

    // บันทึกการวิ่งจริงลง MongoDB ผ่าน backend
    final routeJson = List.generate(_routePoints.length, (i) {
      return {
        'lat': _routePoints[i].latitude,
        'lng': _routePoints[i].longitude,
        'timestamp':
            (i < _routeTimestamps.length ? _routeTimestamps[i] : endTime)
                .toIso8601String(),
      };
    });

    final saveResult = await RunService.instance.createRun(
      startTime: startTime,
      endTime: endTime,
      distanceKm: distanceKm,
      durationSec: _seconds,
      avgPace: paceMinPerKm > 0 ? paceMinPerKm : null,
      route: routeJson,
    );
    final savedToServer = saveResult.success;

    if (!mounted) return;

    final achievementLines = <String>[
      for (final b in result.newlyUnlockedBadges)
        '${b.emoji} ปลดล็อกเหรียญ: ${b.title}',
      for (final m in result.newlyCompletedMissions)
        '🎯 สำเร็จภารกิจ: ${m.title}',
    ];

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('จบการวิ่งแล้ว! 🎉'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ระยะทาง: ${distanceKm.toStringAsFixed(2)} กม.\n'
              'เวลา: ${_formatTime(_seconds)}\n'
              'เพซเฉลี่ย: ${_formatPace(paceMinPerKm)} /กม.\n'
              '+${result.pointsEarned} แต้ม',
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  savedToServer
                      ? Icons.cloud_done_rounded
                      : Icons.cloud_off_rounded,
                  size: 16,
                  color: savedToServer ? AppColors.accent : Colors.orange,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    savedToServer
                        ? 'บันทึกลงฐานข้อมูลเรียบร้อยแล้ว'
                        : 'บันทึกลงฐานข้อมูลไม่สำเร็จ (เช็คว่า backend รันอยู่หรือไม่ — ข้อมูลนี้จะหายไปถ้าไม่บันทึกซ้ำ)',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: savedToServer ? AppColors.accent : Colors.orange,
                    ),
                  ),
                ),
              ],
            ),
            if (achievementLines.isNotEmpty) ...[
              const SizedBox(height: 14),
              const Divider(),
              const SizedBox(height: 6),
              ...achievementLines.map((line) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(line,
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.gold)),
                  )),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop(); // ปิด dialog สรุปผล

              final runId = saveResult.runId;
              if (savedToServer && runId != null) {
                // เด้งไปเช็คอินความรู้สึกก่อนกลับหน้าหลัก
                await Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => MoodCheckinScreen(runId: runId)),
                );
              }

              if (!mounted) return;
              Navigator.of(context).pop(); // กลับไปหน้าหลัก
            },
            child: const Text('เสร็จสิ้น'),
          ),
        ],
      ),
    );
  }

  String _formatTime(int totalSeconds) {
    final m = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String _formatPace(double minPerKm) {
    if (minPerKm <= 0 || minPerKm.isInfinite || minPerKm.isNaN) return '--:--';
    final m = minPerKm.floor();
    final s = ((minPerKm - m) * 60).round();
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  void _collapseSheet() {
    _sheetController.animateTo(
      _peekSize,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  void _expandSheet() {
    _sheetController.animateTo(
      _fullSize,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _secondTimer?.cancel();
    _positionStream?.cancel();
    _mapController.dispose();
    _sheetController.dispose();
    _secondsNotifier.dispose();
    _distanceNotifier.dispose();
    _routeNotifier.dispose();
    _splitsNotifier.dispose();
    _currentSplitPaceNotifier.dispose();
    _sheetExtentNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.secondary,
      // ไม่ใช้ SafeArea ครอบทั้งจอ เพราะแผนที่ต้องเต็มขอบจอ (bleed ใต้ status bar)
      // ปุ่ม/แบดจ์ลอยด้านบนจึงเผื่อ topInset เอง ส่วนตัว stage sheet เผื่อ bottomInset เอง
      body: Stack(
        children: [
          Positioned.fill(child: _buildMapArea()),
          Positioned(
            top: topInset + 12,
            left: 12,
            child: _buildCloseButton(),
          ),
          if (_isRunning && !_isPaused)
            Positioned(
              top: topInset + 16,
              right: 16,
              child: _buildRecordingBadge(),
            ),
          if (!_checkingPermission && _errorMessage == null)
            ValueListenableBuilder<double>(
              valueListenable: _sheetExtentNotifier,
              builder: (context, extent, _) {
                // ให้ attribution/คำเตือน token ลอยอยู่เหนือขอบบนของ stage sheet เสมอ
                final sheetTopY = screenHeight * (1 - extent);
                final bottomOffset =
                    (screenHeight - sheetTopY + 8).clamp(8.0, screenHeight);
                return Positioned(
                  right: 8,
                  bottom: bottomOffset,
                  child: const MapAttribution(),
                );
              },
            ),
          if (!_checkingPermission &&
              _errorMessage == null &&
              !MapConfig.hasValidToken)
            Positioned(
              left: 0,
              right: 0,
              bottom: screenHeight * (1 - _peekSize),
              child: const MapTokenWarning(),
            ),
          _buildStageSheet(topInset, bottomInset, screenHeight),
        ],
      ),
    );
  }

  Widget _buildMapArea() {
    if (_checkingPermission) {
      return Center(
        child: CircularProgressIndicator(color: AppColors.accent),
      );
    }
    if (_errorMessage != null) {
      return Container(
        color: const Color(0xFF283248),
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_off_rounded,
                  color: Colors.white54, size: 44),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _initLocation,
                child: Text('ลองอีกครั้ง',
                    style: TextStyle(color: AppColors.accent)),
              ),
            ],
          ),
        ),
      );
    }
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _routePoints.isNotEmpty
            ? _routePoints.first
            : const LatLng(13.7563, 100.5018),
        initialZoom: 17,
      ),
      children: [
        TileLayer(
          urlTemplate: MapConfig.tileUrlTemplate,
          userAgentPackageName: 'com.example.running_app',
        ),
        // เส้นทาง/หมุดล่าสุด แยกฟัง _routeNotifier ต่างหาก
        // เพื่อไม่ให้ TileLayer/แผนที่ทั้งก้อน rebuild ทุกครั้งที่ GPS ขยับ
        ValueListenableBuilder<List<LatLng>>(
          valueListenable: _routeNotifier,
          builder: (context, points, _) {
            return Stack(
              children: [
                if (points.length > 1)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: points,
                        color: AppColors.primary,
                        strokeWidth: 4,
                      ),
                    ],
                  ),
                if (points.isNotEmpty)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: points.last,
                        width: 22,
                        height: 22,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildCloseButton() {
    return IconButton(
      onPressed: () => Navigator.of(context).pop(),
      icon: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.3),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _buildRecordingBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 8, color: AppColors.accent),
          const SizedBox(width: 6),
          Text('กำลังบันทึก GPS จริง',
              style: TextStyle(color: AppColors.accent, fontSize: 11)),
        ],
      ),
    );
  }

  /// Stage sheet: ลอยทับแผนที่ ลากขึ้น-ลงได้ 2 ระดับ (peek / full) พร้อม snap
  Widget _buildStageSheet(
      double topInset, double bottomInset, double screenHeight) {
    return NotificationListener<DraggableScrollableNotification>(
      onNotification: (notification) {
        _sheetExtentNotifier.value = notification.extent;
        return false;
      },
      child: DraggableScrollableSheet(
        controller: _sheetController,
        initialChildSize: _peekSize,
        minChildSize: _peekSize,
        maxChildSize: _fullSize,
        snap: true,
        snapSizes: const [_peekSize, _fullSize],
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(28)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 20,
                  offset: const Offset(0, -6),
                ),
              ],
            ),
            child: SingleChildScrollView(
              controller: scrollController,
              physics: const ClampingScrollPhysics(),
              child: ValueListenableBuilder<double>(
                valueListenable: _sheetExtentNotifier,
                builder: (context, extent, _) {
                  final expanded = extent > _expandThreshold;
                  final minHeight = screenHeight * extent;
                  return expanded
                      ? _buildExpandedContent(topInset, minHeight)
                      : _buildPeekContent(bottomInset, minHeight);
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildExpandedContent(double topInset, double minHeight) {
    return SizedBox(
      height: minHeight,
      child: ValueListenableBuilder<int>(
        valueListenable: _secondsNotifier,
        builder: (context, seconds, __) {
          return ValueListenableBuilder<double>(
            valueListenable: _distanceNotifier,
            builder: (context, distanceMeters, __) {
              return ValueListenableBuilder<double>(
                valueListenable: _currentSplitPaceNotifier,
                builder: (context, currentSplitPace, __) {
                  return ValueListenableBuilder<List<double>>(
                    valueListenable: _splitsNotifier,
                    builder: (context, splits, __) {
                      return RunStatsView(
                        elapsedSeconds: seconds,
                        distanceKm: distanceMeters / 1000,
                        currentSplitPaceMinPerKm: currentSplitPace,
                        completedSplitPaces: splits,
                        isPaused: _isPaused,
                        onPauseResume: _pauseResume,
                        onStop: _stop,
                        onCollapse: _collapseSheet,
                        topPadding: topInset,
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildPeekContent(double bottomInset, double minHeight) {
    return Container(
      constraints: BoxConstraints(minHeight: minHeight),
      padding: EdgeInsets.fromLTRB(24, 12, 24, 20 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _dragHandle(),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _isRunning ? 'วิ่ง' : 'พร้อมวิ่ง',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700),
              ),
              IconButton(
                onPressed: _expandSheet,
                icon: const Icon(Icons.open_in_full_rounded,
                    color: Colors.white70, size: 18),
                tooltip: 'ดูรายละเอียดเต็มจอ',
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 6),
          ValueListenableBuilder<int>(
            valueListenable: _secondsNotifier,
            builder: (context, seconds, __) {
              return ValueListenableBuilder<double>(
                valueListenable: _distanceNotifier,
                builder: (context, distanceMeters, __) {
                  final distanceKm = distanceMeters / 1000;
                  final paceMinPerKm =
                      distanceKm > 0.01 ? (seconds / 60) / distanceKm : 0.0;
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _peekMetric(_formatTime(seconds), 'เวลา'),
                      _peekMetric(
                          _formatPace(paceMinPerKm), 'ค่าเฉลี่ยช่วง (/กม.)'),
                      _peekMetric(
                          distanceKm.toStringAsFixed(2), 'ระยะทาง (กม.)'),
                    ],
                  );
                },
              );
            },
          ),
          const SizedBox(height: 22),
          if (_checkingPermission || _errorMessage != null)
            const SizedBox(height: 54)
          else if (!_isRunning)
            SizedBox(
              width: double.infinity,
              child: PrimaryButton(
                label: 'เริ่มวิ่ง',
                icon: Icons.play_arrow_rounded,
                onPressed: _onStartPressed,
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _pauseResume,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _isPaused
                              ? Icons.play_arrow_rounded
                              : Icons.pause_rounded,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _isPaused ? 'ต่อ' : 'พัก',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: PrimaryButton(
                    label: 'จบการวิ่ง',
                    icon: Icons.stop_rounded,
                    onPressed: _stop,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _dragHandle() {
    return Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _peekMetric(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
              color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(label,
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5), fontSize: 11)),
      ],
    );
  }
}

// ============================================================
// RunStatsView — มุมมองสถิติเต็มจอ (รวมมาจาก run_stats_view.dart เดิม
// เพื่อให้ทั้งระบบ stage view อยู่ในไฟล์เดียว แทนที่ไฟล์เก่าได้จบในไฟล์นี้ไฟล์เดียว)
// ============================================================

class RunStatsView extends StatelessWidget {
  /// เวลารวมทั้งหมดที่วิ่ง (วินาที)
  final int elapsedSeconds;

  /// ระยะทางรวมทั้งหมด (กม.)
  final double distanceKm;

  /// เพซของช่วงกม.ปัจจุบันที่กำลังวิ่งอยู่ (นาที/กม.) - อัปเดตสดทุกวินาที
  final double currentSplitPaceMinPerKm;

  /// เพซเฉลี่ยของแต่ละกม.ที่วิ่งจบไปแล้ว (นาที/กม.) เรียงจากกม.แรกสุด
  final List<double> completedSplitPaces;

  final bool isPaused;
  final VoidCallback onPauseResume;
  final VoidCallback onStop;
  final VoidCallback onCollapse;

  /// ระยะเผื่อขอบบน (เช่น status bar) เวลา stage ถูกลากขึ้นเต็มจอทับพื้นที่ปลอดภัย
  final double topPadding;

  const RunStatsView({
    super.key,
    required this.elapsedSeconds,
    required this.distanceKm,
    required this.currentSplitPaceMinPerKm,
    required this.completedSplitPaces,
    required this.isPaused,
    required this.onPauseResume,
    required this.onStop,
    required this.onCollapse,
    this.topPadding = 0,
  });

  String _formatElapsed(int totalSeconds) {
    final h = totalSeconds ~/ 3600;
    final m = ((totalSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final s = (totalSeconds % 60).toString().padLeft(2, '0');
    return '${h.toString().padLeft(2, '0')}:$m:$s';
  }

  String _formatPace(double minPerKm) {
    if (minPerKm <= 0 || minPerKm.isInfinite || minPerKm.isNaN) return '-:--';
    final m = minPerKm.floor();
    final s = ((minPerKm - m) * 60).round();
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    // ช่วงกม.ปัจจุบันที่ยังวิ่งไม่ครบ (แสดงเป็นแท่งสุดท้าย ไฮไลต์ว่ากำลัง live)
    final hasLiveSplit = distanceKm - completedSplitPaces.length > 0.01;

    // เนื้อหานี้ถูกฝังอยู่ใน SizedBox(height: ความสูงจริงของ stage sheet ตอนนั้น)
    // (ควบคุมโดย TrackingScreen) จึงมีความสูงชัดเจน (bounded) แล้ว - ใช้ Expanded ได้
    // เพื่อดันแถบปุ่ม (pause/stop) ให้ติดขอบล่างเสมอ ส่วนเนื้อหาสถิติด้านบน
    // เลื่อนขึ้น-ลงได้เองถ้าจอเล็กจนเนื้อหาไม่พอดี (ไม่ overflow)
    return Column(
      mainAxisSize: MainAxisSize.max,
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                  0, topPadding > 0 ? topPadding * 0.4 : 8, 0, 0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: onCollapse,
                          icon: const Icon(Icons.close_fullscreen_rounded,
                              color: Colors.white70, size: 20),
                          tooltip: 'ย่อกลับไปมุมมองแผนที่',
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatElapsed(elapsedSeconds),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 40,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 12),
                        Text(
                          _formatPace(currentSplitPaceMinPerKm),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 76,
                            fontWeight: FontWeight.w800,
                            height: 1,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'ค่าเฉลี่ยช่วง (/กม.)',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.55),
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          distanceKm.toStringAsFixed(2),
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 56,
                            fontWeight: FontWeight.w800,
                            height: 1,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'ระยะทาง (กม.)',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.55),
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 32),
                        _buildSplitsRow(hasLiveSplit),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        _buildBottomControls(context),
      ],
    );
  }

  Widget _buildSplitsRow(bool hasLiveSplit) {
    final splitCount = completedSplitPaces.length + (hasLiveSplit ? 1 : 0);

    final validPaces = <double>[];
    for (final p in completedSplitPaces) {
      if (p > 0 && !p.isInfinite && !p.isNaN) validPaces.add(p);
    }
    if (hasLiveSplit &&
        currentSplitPaceMinPerKm > 0 &&
        !currentSplitPaceMinPerKm.isInfinite &&
        !currentSplitPaceMinPerKm.isNaN) {
      validPaces.add(currentSplitPaceMinPerKm);
    }

    final double minPaces =
        validPaces.isEmpty ? 5.0 : validPaces.reduce((a, b) => a < b ? a : b);
    final double maxPaces =
        validPaces.isEmpty ? 5.0 : validPaces.reduce((a, b) => a > b ? a : b);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (splitCount == 0)
            SizedBox(
              height: 135,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.directions_run_rounded,
                        color: Colors.white.withValues(alpha: 0.25), size: 32),
                    const SizedBox(height: 8),
                    Text(
                      'เริ่มวิ่งเพื่อสะสมแท่งเพซรายกิโลเมตร',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SizedBox(
              height: 135,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                reverse:
                    true, // เรียงจากขวาไปซ้าย: ช่วงล่าสุด/ปัจจุบันอยู่ขวาสุดเสมอ
                itemCount: splitCount,
                separatorBuilder: (_, __) => const SizedBox(width: 14),
                itemBuilder: (context, reversedIndex) {
                  final index = splitCount - 1 - reversedIndex;
                  final isLive = hasLiveSplit && index == splitCount - 1;
                  final pace = isLive
                      ? currentSplitPaceMinPerKm
                      : completedSplitPaces[index];

                  double fillRatio;
                  if (pace <= 0 || pace.isInfinite || pace.isNaN) {
                    fillRatio = 0.3;
                  } else if (maxPaces == minPaces) {
                    fillRatio = 0.7;
                  } else {
                    fillRatio = 0.35 +
                        0.55 * ((maxPaces - pace) / (maxPaces - minPaces));
                  }
                  fillRatio = fillRatio.clamp(0.25, 1.0);

                  return _SplitColumnBar(
                    splitLabel: '${index + 1}',
                    paceLabel: _formatPace(pace),
                    isLive: isLive,
                    fillRatio: fillRatio,
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomControls(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
          20, 18, 20, 16 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 20,
              offset: const Offset(0, -6)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 54,
                  child: ElevatedButton(
                    onPressed: onPauseResume,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isPaused ? AppColors.accent : const Color(0xFFFF7A1A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(27),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(isPaused
                            ? Icons.play_arrow_rounded
                            : Icons.pause_rounded),
                        const SizedBox(width: 8),
                        Text(
                          isPaused ? 'ไปต่อ' : 'หยุดชั่วคราว',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                height: 54,
                width: 54,
                child: OutlinedButton(
                  onPressed: onStop,
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    side:
                        BorderSide(color: Colors.white.withValues(alpha: 0.25)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(27)),
                  ),
                  child: const Icon(Icons.stop_rounded, color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SplitColumnBar extends StatelessWidget {
  final String splitLabel;
  final String paceLabel;
  final bool isLive;
  final double fillRatio;

  const _SplitColumnBar({
    required this.splitLabel,
    required this.paceLabel,
    required this.isLive,
    required this.fillRatio,
  });

  @override
  Widget build(BuildContext context) {
    const double maxTrackHeight = 72;
    final double barHeight =
        (maxTrackHeight * fillRatio).clamp(18.0, maxTrackHeight);

    return SizedBox(
      width: 48,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Text(
              paceLabel,
              style: TextStyle(
                color: isLive ? AppColors.gold : Colors.white,
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            height: maxTrackHeight,
            width: 28,
            alignment: Alignment.bottomCenter,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: barHeight,
              width: 28,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isLive
                      ? [const Color(0xFFFFB03A), const Color(0xFFFF5E62)]
                      : AppColors.primaryGradient,
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: (isLive ? AppColors.gold : AppColors.primary)
                        .withValues(alpha: isLive ? 0.5 : 0.3),
                    blurRadius: isLive ? 8 : 4,
                    offset: const Offset(0, 2),
                  ),
                ],
                border: isLive
                    ? Border.all(
                        color: Colors.white.withValues(alpha: 0.9), width: 1.5)
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: isLive
                  ? AppColors.gold.withValues(alpha: 0.2)
                  : Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: isLive
                  ? Border.all(
                      color: AppColors.gold.withValues(alpha: 0.5), width: 1)
                  : null,
            ),
            child: Text(
              'กม. $splitLabel',
              style: TextStyle(
                color: isLive ? AppColors.gold : Colors.white70,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
