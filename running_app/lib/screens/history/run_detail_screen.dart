import 'package:flutter/material.dart';

import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../theme/app_theme.dart';
import '../../services/run_service.dart';
import '../../config/map_config.dart';
import '../../widgets/share_cards.dart';
import '../../widgets/map_attribution.dart';


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

  Future<void> _shareRun(BuildContext context, RunDetail run) async {
    if (run.route.length > 1) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('แชร์ผลการวิ่ง'),
          content: const Text(
            'การ์ดรูปภาพนี้จะมีเส้นทางการวิ่ง ซึ่งอาจเปิดเผยจุดเริ่มต้นและจุดสิ้นสุดของคุณ',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('ยกเลิก'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('เลือกสไตล์การ์ด'),
            ),
          ],
        ),
      );
      if (proceed != true || !mounted) return;
    }
    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => ShareCardPickerSheet(run: run, shareText: _shareText(run)),
    );
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
              ? Stack(
                  children: [
                    FlutterMap(
                      options: MapOptions(
                        initialCameraFit: CameraFit.bounds(
                          bounds: LatLngBounds.fromPoints(run.route),
                          padding: const EdgeInsets.all(36),
                        ),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: MapConfig.tileUrlTemplate,
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
                    ),
                    const Positioned(right: 6, bottom: 4, child: MapAttribution()),
                    if (!MapConfig.hasValidToken)
                      const Positioned(left: 0, right: 0, top: 0, child: MapTokenWarning()),
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
