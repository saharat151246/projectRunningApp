import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../theme/app_theme.dart';
import '../../services/run_service.dart';
import '../../services/language_controller.dart';
import '../history/run_detail_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  RunSummary? _summary;
  List<RunItem> _runs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final summary = await RunService.instance.fetchSummary();
    final runs = await RunService.instance.fetchRuns();
    if (!mounted) return;
    setState(() {
      _summary = summary;
      _runs = runs;
      _loading = false;
    });
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
    final lang = LanguageController.instance;
    return '$m:${s.toString().padLeft(2, '0')} ${lang.perKm}';
  }

  String _formatDate(DateTime d) =>
      LanguageController.instance.formatDate(d);

  String _weekdayLabel(String dateKey) {
    if (dateKey.isEmpty) return '';
    final d = DateTime.parse(dateKey);
    return LanguageController.instance.weekdayLabel(d.weekday);
  }

  @override
  Widget build(BuildContext context) {
    final lang = LanguageController.instance;
    final summary = _summary ?? RunSummary.empty();

    return AnimatedBuilder(
      animation: lang,
      builder: (context, _) {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _load,
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(lang.text('สถิติของฉัน', 'My Statistics'),
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(lang.text('ภาพรวมความก้าวหน้าการวิ่งทั้งหมด', 'Overview of your running progress'),
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 24),
                  if (_loading)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 60),
                      child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                    )
                  else ...[
                    Container(
                      height: 210,
                      padding: const EdgeInsets.fromLTRB(12, 20, 16, 12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: LineChart(
                        LineChartData(
                          gridData: const FlGridData(show: false),
                          borderData: FlBorderData(show: false),
                          titlesData: FlTitlesData(
                            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  final i = value.toInt();
                                  if (i < 0 || i >= summary.weekLabels.length) {
                                    return const SizedBox.shrink();
                                  }
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Text(_weekdayLabel(summary.weekLabels[i]),
                                        style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textSecondary)),
                                  );
                                },
                              ),
                            ),
                          ),
                          lineBarsData: [
                            LineChartBarData(
                              spots: List.generate(
                                summary.weeklyDistance.length,
                                (i) => FlSpot(i.toDouble(), summary.weeklyDistance[i]),
                              ),
                              isCurved: true,
                              curveSmoothness: 0.35,
                              color: AppColors.primary,
                              barWidth: 3.5,
                              dotData: FlDotData(
                                show: true,
                                getDotPainter: (spot, percent, barData, index) =>
                                    FlDotCirclePainter(
                                  radius: 5,
                                  color: AppColors.primary,
                                  strokeWidth: 2.5,
                                  strokeColor: Colors.white,
                                ),
                              ),
                              belowBarData: BarAreaData(
                                show: true,
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.primary.withValues(alpha: 0.25),
                                    AppColors.primary.withValues(alpha: 0.0),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(lang.text('ประวัติการวิ่งทั้งหมด', 'All Run History'),
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
                    const SizedBox(height: 12),
                    if (_runs.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Center(
                          child: Text(lang.text('ยังไม่มีประวัติการวิ่ง', 'No run history yet'),
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
          // รายการประวัติการวิ่ง - ใช้ SliverList.builder แทนการสร้าง widget ของทุกรายการล่วงหน้า
          if (!_loading && _runs.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
              sliver: SliverList.builder(
                itemCount: _runs.length,
                itemBuilder: (context, index) => _runTile(_runs[index]),
              ),
            )
          else
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
      },
    );
  }

  Widget _runTile(RunItem run) {
    final lang = LanguageController.instance;
    return Dismissible(
      key: Key(run.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                const Icon(Icons.delete_outline_rounded, color: Color(0xFFE82A2A)),
                const SizedBox(width: 8),
                Text(lang.text('ลบประวัติการวิ่ง', 'Delete Run'),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            content: Text(
              lang.text(
                'คุณต้องการลบรายการวิ่งนี้ใช่หรือไม่? ข้อมูลประวัติและสถิติของกิจกรรมนี้จะถูกลบออกจากระบบและไม่สามารถกู้คืนได้',
                'Are you sure you want to delete this run? This action cannot be undone.',
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
      },
      onDismissed: (_) async {
        final result = await RunService.instance.deleteRun(run.id);
        if (mounted) {
          if (result.success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(lang.text('ลบประวัติการวิ่งเรียบร้อยแล้ว', 'Run deleted successfully'))),
            );
            _load();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(result.errorMessage ?? lang.text('ไม่สามารถลบรายการได้', 'Failed to delete'))),
            );
            _load();
          }
        }
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.only(right: 20),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: const Color(0xFFE82A2A),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 24),
      ),
      child: GestureDetector(
        onTap: () async {
          final deleted = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (_) => RunDetailScreen(runId: run.id),
            ),
          );
          if (deleted == true && mounted) {
            _load();
          }
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.directions_run_rounded,
                    color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_formatDate(run.startTime),
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 14.5)),
                    const SizedBox(height: 4),
                    Text(
                      '${run.distanceKm.toStringAsFixed(2)} ${lang.km} • ${_formatDuration(run.durationSec)} • ${_formatPace(run.avgPace)}',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: AppColors.textSecondary, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}
