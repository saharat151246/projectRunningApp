import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:share_plus/share_plus.dart';
import '../../theme/app_theme.dart';
import '../../services/run_service.dart';


/// หน้ารายละเอียดการวิ่งครั้งเดียว - แสดงเส้นทาง GPS จริงบนแผนที่ + สถิติครบ
class RunDetailScreen extends StatefulWidget {
  final String runId;
  const RunDetailScreen({super.key, required this.runId});

  @override
  State<RunDetailScreen> createState() => _RunDetailScreenState();
}

class _RunDetailScreenState extends State<RunDetailScreen> {
  RunDetail? _detail;
  bool _loading = true;
  bool _notFound = false;

  static const _thaiMonths = [
    'ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.',
    'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.'
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final detail = await RunService.instance.fetchRunDetail(widget.runId);
    if (!mounted) return;
    setState(() {
      _detail = detail;
      _notFound = detail == null;
      _loading = false;
    });
  }

  String _formatDate(DateTime d) {
    final buddhistYear = d.year + 543;
    final time =
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    return '${d.day} ${_thaiMonths[d.month - 1]} $buddhistYear • $time น.';
  }

  String _formatDuration(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String _formatPace(double? minPerKm) {
    if (minPerKm == null || minPerKm <= 0) return '--:--';
    final m = minPerKm.floor();
    final s = ((minPerKm - m) * 60).round();
    return '$m:${s.toString().padLeft(2, '0')} /กม.';
  }

  String _mapsRouteUrl(RunDetail run) {
    if (run.route.length < 2) return '';
    String coordinate(LatLng point) => '${point.latitude},${point.longitude}';
    final step = (run.route.length / 9).ceil();
    final waypoints = <String>[];
    for (var index = step; index < run.route.length - 1; index += step) {
      waypoints.add(coordinate(run.route[index]));
    }
    return Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'origin': coordinate(run.route.first),
      'destination': coordinate(run.route.last),
      if (waypoints.isNotEmpty) 'waypoints': waypoints.join('|'),
    }).toString();
  }

  String _shareText(RunDetail run) {
    final routeUrl = _mapsRouteUrl(run);
    return '''🏃 ฉันเพิ่งวิ่งกับ RunMate!

ระยะทาง ${run.distanceKm.toStringAsFixed(2)} กม.
เวลา ${_formatDuration(run.durationSec)}
เพซ ${_formatPace(run.avgPace)}
วันที่ ${_formatDate(run.startTime)}
${routeUrl.isEmpty ? '' : '\nดูเส้นทาง: $routeUrl\n'}
#RunMate #Running''';
  }

  String _shareDurationLabel(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m}m ${s.toString().padLeft(2, '0')}s';
  }

  String _sharePaceLabel(double? minPerKm) {
    if (minPerKm == null || minPerKm <= 0) return '--:--';
    final m = minPerKm.floor();
    final s = ((minPerKm - m) * 60).round();
    return '$m:${s.toString().padLeft(2, '0')} /km';
  }

  Future<Uint8List> _buildShareCard(RunDetail run) async {
    const width = 1080.0;
    const height = 1350.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // พื้นหลังดำล้วน มินิมอล เน้นตัวเลข (สไตล์ Strava-like share card)
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, width, height),
      Paint()..color = Colors.black,
    );

    void centeredText(String value, double top, double size, Color color,
        {FontWeight weight = FontWeight.w400, double letterSpacing = 0}) {
      final painter = TextPainter(
        text: TextSpan(
          text: value,
          style: TextStyle(
            color: color,
            fontSize: size,
            fontWeight: weight,
            letterSpacing: letterSpacing,
            fontFamily: 'sans-serif',
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      )..layout(maxWidth: width);
      painter.paint(canvas, Offset(0, top));
    }

    // --- สถิติหลัก 3 บรรทัด: Distance / Pace / Time (label เล็ก + ตัวเลขใหญ่) ---
    final stats = [
      ('Distance', '${run.distanceKm.toStringAsFixed(2)} km'),
      ('Pace', _sharePaceLabel(run.avgPace)),
      ('Time', _shareDurationLabel(run.durationSec)),
    ];

    var cursorY = 108.0;
    for (final stat in stats) {
      centeredText(stat.$1, cursorY, 30, Colors.white70,
          weight: FontWeight.w600, letterSpacing: 0.5);
      cursorY += 46;
      centeredText(stat.$2, cursorY, 82, Colors.white, weight: FontWeight.w800);
      cursorY += 100;
    }

    // --- เส้นทางการวิ่ง วาดลอยตัวบนพื้นดำ ไม่มีกรอบแผนที่/กริด ---
    const routeTop = 650.0;
    const routeHeight = 380.0;
    const routeInset = 90.0;
    final routeBox = Rect.fromLTWH(routeInset, routeTop, width - routeInset * 2, routeHeight);

    if (run.route.length > 1) {
      final lats = run.route.map((point) => point.latitude);
      final lngs = run.route.map((point) => point.longitude);
      final minLat = lats.reduce((a, b) => a < b ? a : b);
      final maxLat = lats.reduce((a, b) => a > b ? a : b);
      final minLng = lngs.reduce((a, b) => a < b ? a : b);
      final maxLng = lngs.reduce((a, b) => a > b ? a : b);
      final latRange = (maxLat - minLat).abs() < 0.00001 ? 0.00001 : maxLat - minLat;
      final lngRange = (maxLng - minLng).abs() < 0.00001 ? 0.00001 : maxLng - minLng;

      // สเกลแบบรักษาสัดส่วน (uniform scale) ไม่ยืดเส้นทางให้ผิดรูป
      final scale = (routeBox.width / lngRange < routeBox.height / latRange)
          ? routeBox.width / lngRange
          : routeBox.height / latRange;
      final routeW = lngRange * scale;
      final routeH = latRange * scale;
      final offsetX = routeBox.left + (routeBox.width - routeW) / 2;
      final offsetY = routeBox.top + (routeBox.height - routeH) / 2;

      Offset project(LatLng point) => Offset(
            offsetX + (point.longitude - minLng) * scale,
            offsetY + (maxLat - point.latitude) * scale,
          );

      final routePath = ui.Path()
        ..moveTo(project(run.route.first).dx, project(run.route.first).dy);
      for (final point in run.route.skip(1)) {
        final offset = project(point);
        routePath.lineTo(offset.dx, offset.dy);
      }
      canvas.drawPath(
        routePath,
        Paint()
          ..color = AppColors.primary
          ..style = PaintingStyle.stroke
          ..strokeWidth = 14
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
      // จุดสิ้นสุดเส้นทาง
      canvas.drawCircle(project(run.route.last), 10, Paint()..color = AppColors.primary);
    } else {
      centeredText('NO GPS ROUTE RECORDED', routeTop + routeHeight / 2 - 14, 22,
          Colors.white38, weight: FontWeight.w700, letterSpacing: 0.5);
    }

    // --- โลโก้/ชื่อแอปด้านล่าง ---
    const brandIconSize = 46.0;
    final brandIconRect = Rect.fromLTWH(
      (width - brandIconSize) / 2 - 118,
      1150,
      brandIconSize,
      brandIconSize,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(brandIconRect, const Radius.circular(14)),
      Paint()
        ..shader = ui.Gradient.linear(
          brandIconRect.topLeft,
          brandIconRect.bottomRight,
          AppColors.primaryGradient,
        ),
    );
    final iconPainter = TextPainter(
      text: const TextSpan(
        text: '🏃',
        style: TextStyle(fontSize: 26),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    iconPainter.paint(
      canvas,
      Offset(
        brandIconRect.left + (brandIconSize - iconPainter.width) / 2,
        brandIconRect.top + (brandIconSize - iconPainter.height) / 2,
      ),
    );
    centeredText('RunMate', 1156, 40, Colors.white, weight: FontWeight.w800, letterSpacing: 0.5);

    final image = await recorder.endRecording().toImage(width.toInt(), height.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    if (bytes == null) throw StateError('ไม่สามารถสร้างภาพแชร์ได้');
    return bytes.buffer.asUint8List();
  }

  Future<void> _shareRun(BuildContext context, RunDetail run) async {
    final box = context.findRenderObject() as RenderBox?;
    final messenger = ScaffoldMessenger.of(context);

    final shouldShare = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('แชร์ผลการวิ่ง'),
        content: Text(
          run.route.length > 1
              ? 'การ์ดรูปภาพนี้จะมีลิงก์แผนที่เส้นทางการวิ่ง ซึ่งอาจเปิดเผยจุดเริ่มต้นและจุดสิ้นสุดของคุณ'
              : 'การ์ดรูปภาพนี้จะมีสถิติการวิ่งของคุณ',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('เลือกแพลตฟอร์ม'),
          ),
        ],
      ),
    );
    if (shouldShare != true || !mounted) return;

    try {
      final imageBytes = await _buildShareCard(run);
      if (!mounted) return;
      await SharePlus.instance.share(
        ShareParams(
          text: _shareText(run),
          subject: 'ผลการวิ่งจาก RunMate',
          files: [XFile.fromData(imageBytes, mimeType: 'image/png')],
          fileNameOverrides: ['runmate-${run.id}.png'],
          sharePositionOrigin:
              box == null ? null : box.localToGlobal(Offset.zero) & box.size,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('ไม่สามารถสร้างการ์ดสำหรับแชร์ได้')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('รายละเอียดการวิ่ง'),
        actions: [
          if (_detail != null)
            IconButton(
              onPressed: () => _shareRun(context, _detail!),
              icon: const Icon(Icons.ios_share_rounded),
              tooltip: 'แชร์ผลการวิ่ง',
            ),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _notFound
              ? _buildNotFound()
              : _buildContent(_detail!),
    );
  }

  Widget _buildNotFound() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline_rounded, color: AppColors.textSecondary, size: 40),
          const SizedBox(height: 12),
          Text('ไม่พบข้อมูลการวิ่งนี้',
              style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          TextButton(onPressed: _load, child: const Text('ลองอีกครั้ง')),
        ],
      ),
    );
  }

  Widget _buildContent(RunDetail run) {
    final hasRoute = run.route.length > 1;
    final calories = (run.distanceKm * 62).toStringAsFixed(0);

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        // แผนที่เส้นทาง
        SizedBox(
          height: 260,
          child: hasRoute
              ? FlutterMap(
                  options: MapOptions(
                    initialCameraFit: CameraFit.bounds(
                      bounds: LatLngBounds.fromPoints(run.route),
                      padding: const EdgeInsets.all(36),
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.running_app',
                    ),
                    PolylineLayer(
                      polylines: [
                        Polyline(points: run.route, color: AppColors.primary, strokeWidth: 4),
                      ],
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: run.route.first,
                          width: 20,
                          height: 20,
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.accent,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                            ),
                          ),
                        ),
                        Marker(
                          point: run.route.last,
                          width: 20,
                          height: 20,
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
                )
              : Container(
                  color: AppColors.secondary,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.map_outlined, color: Colors.white.withValues(alpha: 0.2), size: 40),
                        const SizedBox(height: 8),
                        Text('ไม่มีข้อมูลเส้นทาง GPS สำหรับการวิ่งนี้',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12)),
                      ],
                    ),
                  ),
                ),
        ),

        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_formatDate(run.startTime),
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              const SizedBox(height: 20),

              // สถิติหลัก
              Row(
                children: [
                  Expanded(
                    child: _StatBlock(
                      icon: Icons.map_outlined,
                      label: 'ระยะทาง',
                      value: run.distanceKm.toStringAsFixed(2),
                      unit: 'กม.',
                      color: AppColors.primary,
                    ),
                  ),
                  Expanded(
                    child: _StatBlock(
                      icon: Icons.timer_outlined,
                      label: 'เวลา',
                      value: _formatDuration(run.durationSec),
                      unit: '',
                      color: AppColors.secondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _StatBlock(
                      icon: Icons.speed_rounded,
                      label: 'เพซเฉลี่ย',
                      value: _formatPace(run.avgPace),
                      unit: '',
                      color: AppColors.accent,
                    ),
                  ),
                  Expanded(
                    child: _StatBlock(
                      icon: Icons.local_fire_department_rounded,
                      label: 'แคลอรี่',
                      value: calories,
                      unit: 'kcal',
                      color: AppColors.gold,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 22),

              if (run.mood != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 3)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(run.mood!.emoji, style: const TextStyle(fontSize: 24)),
                          const SizedBox(width: 10),
                          Text('รู้สึก${run.mood!.label}หลังวิ่งครั้งนี้',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 13.5)),
                        ],
                      ),
                      if (run.note != null && run.note!.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(
                          run.note!,
                          style: TextStyle(
                              fontSize: 12.5, color: AppColors.textSecondary, height: 1.5),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _shareRun(context, run),
                  icon: const Icon(Icons.share_rounded),
                  label: const Text('แชร์การ์ดผลการวิ่ง'),
                ),
              ),

              if (hasRoute) ...[
                const SizedBox(height: 24),
                Text('บันทึกพิกัดทั้งหมด ${run.route.length} จุด',
                    style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _StatBlock extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String unit;
  final Color color;

  const _StatBlock({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8, bottom: 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value,
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 3),
                Text(unit, style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ],
          ),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
