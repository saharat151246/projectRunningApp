import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../theme/app_theme.dart';
import '../../services/run_service.dart';
import '../../services/language_controller.dart';
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
    return LanguageController.instance.formatDate(d);
  }

  String _formatDuration(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String _formatPace(double? minPerKm, LanguageController lang) {
    if (minPerKm == null || minPerKm <= 0) return '--:--';
    final m = minPerKm.floor();
    final s = ((minPerKm - m) * 60).round();
    return '$m:${s.toString().padLeft(2, '0')} ${lang.perKm}';
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

  String _shareText(RunDetail run, LanguageController lang) {
    final routeUrl = _mapsRouteUrl(run);
    if (lang.isEnglish) {
      return '''🏃 I just ran with RunMate!

Distance: ${run.distanceKm.toStringAsFixed(2)} km
Time: ${_formatDuration(run.durationSec)}
Pace: ${_formatPace(run.avgPace, lang)}
Date: ${_formatDate(run.startTime)}
${routeUrl.isEmpty ? '' : '\nView Route: $routeUrl\n'}
#RunMate #Running''';
    }
    return '''🏃 ฉันเพิ่งวิ่งกับ RunMate!

ระยะทาง ${run.distanceKm.toStringAsFixed(2)} กม.
เวลา ${_formatDuration(run.durationSec)}
เพซ ${_formatPace(run.avgPace, lang)}
วันที่ ${_formatDate(run.startTime)}
${routeUrl.isEmpty ? '' : '\nดูเส้นทาง: $routeUrl\n'}
#RunMate #Running''';
  }

  Future<void> _shareRun(BuildContext context, RunDetail run) async {
    final lang = LanguageController.instance;
    if (run.route.length > 1) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(lang.text('แชร์ผลการวิ่ง', 'Share Run Result')),
          content: Text(
            lang.text(
              'การ์ดรูปภาพนี้จะมีเส้นทางการวิ่ง ซึ่งอาจเปิดเผยจุดเริ่มต้นและจุดสิ้นสุดของคุณ',
              'This image card includes the run route, which may reveal your start and end locations.',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(lang.text('ยกเลิก', 'Cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(lang.text('เลือกสไตล์การ์ด', 'Choose Card Style')),
            ),
          ],
        ),
      );
      if (proceed != true || !context.mounted) return;
    }
    if (!context.mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => ShareCardPickerSheet(run: run, shareText: _shareText(run, lang)),
    );
  }

  Future<void> _confirmDeleteRun(BuildContext context) async {
    final lang = LanguageController.instance;
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.delete_outline_rounded, color: Color(0xFFE82A2A)),
            const SizedBox(width: 8),
            Text(
              lang.text('ลบประวัติการวิ่ง', 'Delete Run History'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          lang.text(
            'คุณต้องการลบรายการวิ่งนี้ใช่หรือไม่? ข้อมูลประวัติและสถิติของกิจกรรมนี้จะถูกลบออกจากระบบและไม่สามารถกู้คืนได้',
            'Are you sure you want to delete this run? The history and statistics of this activity will be permanently removed.',
          ),
          style: const TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(lang.text('ยกเลิก', 'Cancel'), style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE82A2A),
              foregroundColor: Colors.white,
              minimumSize: const Size(100, 44),
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(lang.text('ลบรายการ', 'Delete')),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    final result = await RunService.instance.deleteRun(widget.runId);
    if (!mounted) return;

    if (result.success) {
      messenger.showSnackBar(
        SnackBar(content: Text(lang.text('ลบประวัติการวิ่งเรียบร้อยแล้ว', 'Run history deleted successfully'))),
      );
      nav.pop(true);
    } else {
      messenger.showSnackBar(
        SnackBar(content: Text(result.errorMessage ?? lang.text('ไม่สามารถลบรายการได้', 'Failed to delete run'))),
      );
    }
  }

  String _getMoodLabel(RunMood mood, LanguageController lang) {
    if (lang.isEnglish) {
      switch (mood) {
        case RunMood.exhausted: return 'Exhausted';
        case RunMood.veryTired: return 'Very Tired';
        case RunMood.good: return 'Good';
        case RunMood.great: return 'Great';
        case RunMood.chill: return 'Chill';
      }
    }
    return mood.label;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: LanguageController.instance,
      builder: (context, _) {
        final lang = LanguageController.instance;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.background,
            title: Text(lang.text('รายละเอียดการวิ่ง', 'Run Details')),
            actions: [
              if (_detail != null) ...[
                IconButton(
                  onPressed: () => _shareRun(context, _detail!),
                  icon: const Icon(Icons.ios_share_rounded),
                  tooltip: lang.text('แชร์ผลการวิ่ง', 'Share run result'),
                ),
                IconButton(
                  onPressed: () => _confirmDeleteRun(context),
                  icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFE82A2A)),
                  tooltip: lang.text('ลบประวัติการวิ่ง', 'Delete run history'),
                ),
              ],
            ],
          ),
          body: _loading
              ? Center(child: CircularProgressIndicator(color: AppColors.primary))
              : _notFound
                  ? _buildNotFound(lang)
                  : _buildContent(_detail!, lang),
        );
      },
    );
  }

  Widget _buildNotFound(LanguageController lang) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline_rounded, color: AppColors.textSecondary, size: 40),
          const SizedBox(height: 12),
          Text(
            lang.text('ไม่พบข้อมูลการวิ่งนี้', 'Run data not found'),
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          TextButton(onPressed: _load, child: Text(lang.text('ลองอีกครั้ง', 'Try Again'))),
        ],
      ),
    );
  }

  Widget _buildContent(RunDetail run, LanguageController lang) {
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
                        Text(
                          lang.text('ไม่มีข้อมูลเส้นทาง GPS สำหรับการวิ่งนี้', 'No GPS route data for this run'),
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12),
                        ),
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
              Text(
                _formatDate(run.startTime),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 20),

              // สถิติหลัก
              Row(
                children: [
                  Expanded(
                    child: _StatBlock(
                      icon: Icons.map_outlined,
                      label: lang.text('ระยะทาง', 'Distance'),
                      value: run.distanceKm.toStringAsFixed(2),
                      unit: lang.km,
                      color: AppColors.primary,
                    ),
                  ),
                  Expanded(
                    child: _StatBlock(
                      icon: Icons.timer_outlined,
                      label: lang.text('เวลา', 'Duration'),
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
                      label: lang.text('เพซเฉลี่ย', 'Avg Pace'),
                      value: _formatPace(run.avgPace, lang),
                      unit: '',
                      color: AppColors.accent,
                    ),
                  ),
                  Expanded(
                    child: _StatBlock(
                      icon: Icons.local_fire_department_rounded,
                      label: lang.text('แคลอรี่', 'Calories'),
                      value: calories,
                      unit: lang.kcal,
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
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(run.mood!.emoji, style: const TextStyle(fontSize: 24)),
                          const SizedBox(width: 10),
                          Text(
                            lang.text(
                              'รู้สึก${run.mood!.label}หลังวิ่งครั้งนี้',
                              'Felt ${_getMoodLabel(run.mood!, lang)} after this run',
                            ),
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13.5,
                            ),
                          ),
                        ],
                      ),
                      if (run.note != null && run.note!.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(
                          run.note!,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
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
                  label: Text(lang.text('แชร์การ์ดผลการวิ่ง', 'Share Run Card')),
                ),
              ),

              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: () => _confirmDeleteRun(context),
                  icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFE82A2A), size: 20),
                  label: Text(
                    lang.text('ลบประวัติการวิ่งนี้', 'Delete This Run'),
                    style: const TextStyle(color: Color(0xFFE82A2A), fontWeight: FontWeight.w600),
                  ),
                ),
              ),

              if (hasRoute) ...[
                const SizedBox(height: 24),
                Text(
                  lang.text(
                    'บันทึกพิกัดทั้งหมด ${run.route.length} จุด',
                    'Recorded ${run.route.length} GPS points in total',
                  ),
                  style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                ),
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
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
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
