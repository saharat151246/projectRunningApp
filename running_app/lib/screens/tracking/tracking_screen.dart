import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../theme/app_theme.dart';
import '../../widgets/primary_button.dart';
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

  int _seconds = 0;
  bool _isRunning = false;
  bool _isPaused = false;
  DateTime? _runStartTime; // เวลาเริ่มวิ่งจริง (ตั้งครั้งเดียวตอนกดเริ่ม ไม่ถูกรีเซ็ตตอน resume)

  double _totalDistanceMeters = 0;
  Position? _lastPosition;
  final List<LatLng> _routePoints = [];
  final List<DateTime> _routeTimestamps = []; // เวลาที่บันทึกแต่ละจุด คู่กับ _routePoints

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
        _errorMessage = 'กรุณาเปิด GPS/Location Service ของอุปกรณ์ก่อนเริ่มวิ่ง';
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
    } catch (e) {
      setState(() {
        _checkingPermission = false;
        _errorMessage = e is TimeoutException
            ? e.message
            : 'ไม่สามารถดึงตำแหน่งได้: $e';
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
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFC01C1C)),
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
                style: TextStyle(fontSize: 12, color: Color(0xFF991B1B), fontWeight: FontWeight.w600),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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

    _secondTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _seconds++);
    });

    const settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 3,
    );
    _positionStream =
        Geolocator.getPositionStream(locationSettings: settings)
            .listen(_onPositionUpdate);
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

    setState(() {
      _lastPosition = position;
      _routePoints.add(newPoint);
      _routeTimestamps.add(DateTime.now());
    });

    _mapController.move(newPoint, _mapController.camera.zoom);
  }

  void _pauseResume() {
    if (_isPaused) {
      // Resume existing stream + timer instead of creating new ones
      _positionStream?.resume();
      _secondTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        setState(() => _seconds++);
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
        'timestamp': (i < _routeTimestamps.length ? _routeTimestamps[i] : endTime)
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
      for (final b in result.newlyUnlockedBadges) '${b.emoji} ปลดล็อกเหรียญ: ${b.title}',
      for (final m in result.newlyCompletedMissions) '🎯 สำเร็จภารกิจ: ${m.title}',
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
                  savedToServer ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
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
                        style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.gold)),
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
                  MaterialPageRoute(builder: (_) => MoodCheckinScreen(runId: runId)),
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

  @override
  void dispose() {
    _secondTimer?.cancel();
    _positionStream?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final distanceKm = _totalDistanceMeters / 1000;
    final paceMinPerKm = distanceKm > 0.01 ? (_seconds / 60) / distanceKm : 0.0;
    final calories = (distanceKm * 62).toStringAsFixed(0);

    return Scaffold(
      backgroundColor: AppColors.secondary,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  if (_checkingPermission)
                    const Center(
                      child: CircularProgressIndicator(color: AppColors.accent),
                    )
                  else if (_errorMessage != null)
                    Container(
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
                              child: const Text('ลองอีกครั้ง',
                                  style: TextStyle(color: AppColors.accent)),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: _routePoints.isNotEmpty
                            ? _routePoints.first
                            : const LatLng(13.7563, 100.5018),
                        initialZoom: 17,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.example.running_app',
                        ),
                        if (_routePoints.length > 1)
                          PolylineLayer(
                            polylines: [
                              Polyline(
                                points: _routePoints,
                                color: AppColors.primary,
                                strokeWidth: 4,
                              ),
                            ],
                          ),
                        if (_routePoints.isNotEmpty)
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: _routePoints.last,
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
                    ),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                  if (_isRunning && !_isPaused)
                    Positioned(
                      top: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.circle, size: 8, color: AppColors.accent),
                            SizedBox(width: 6),
                            Text('กำลังบันทึก GPS จริง',
                                style: TextStyle(color: AppColors.accent, fontSize: 11)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              flex: 4,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
                decoration: const BoxDecoration(
                  color: AppColors.secondary,
                ),
                child: Column(
                  children: [
                    Text(
                      _formatTime(_seconds),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 56,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('เวลา',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
                    const SizedBox(height: 28),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _metric(distanceKm.toStringAsFixed(2), 'กม.', 'ระยะทาง'),
                        _metric(_formatPace(paceMinPerKm), '/กม.', 'เพซ'),
                        _metric(calories, 'kcal', 'แคลอรี่'),
                      ],
                    ),
                    const Spacer(),
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
                                side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metric(String value, String unit, String label) {
    return Column(
      children: [
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: value,
                style: const TextStyle(
                    color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
              ),
              TextSpan(
                text: ' $unit',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11)),
      ],
    );
  }
}
