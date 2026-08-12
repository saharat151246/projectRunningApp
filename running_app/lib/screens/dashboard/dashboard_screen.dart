import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../theme/app_theme.dart';
import '../../services/run_service.dart';
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
    return '$m:${s.toString().padLeft(2, '0')} /กม.';
  }

  String _formatDate(DateTime d) {
    const months = [
      'ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.',
      'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.'
    ];
    final buddhistYear = d.year + 543;
    return '${d.day} ${months[d.month - 1]} $buddhistYear';
  }

  String _weekdayLabel(String dateKey) {
    if (dateKey.isEmpty) return '';
    final d = DateTime.parse(dateKey);
    const labels = ['จ', 'อ', 'พ', 'พฤ', 'ศ', 'ส', 'อา'];
    return labels[d.weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    final summary = _summary ?? RunSummary.empty();

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
                  const Text('สถิติของฉัน',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text('ภาพรวมความก้าวหน้าการวิ่งทั้งหมด',
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
                    const Text('ประวัติการวิ่งทั้งหมด',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
                    const SizedBox(height: 12),
                    if (_runs.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Center(
                          child: Text('ยังไม่มีประวัติการวิ่ง',
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
          // รายการประวัติการวิ่ง - ใช้ SliverList.builder แทนการสร้าง widget ของทุกรายการล่วงหน้า
          // (เดิมใช้ ..._runs.map(...) ใน ListView เดียว ทำให้พอประวัติสะสมเยอะขึ้นเรื่อยๆ
          // จะยิ่งกิน memory และหน่วงตอนเปิดหน้านี้ เพราะสร้าง widget ของทุกรายการตั้งแต่แรกทั้งที่ยังไม่เห็นบนจอ)
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
  }

  Widget _runTile(RunItem run) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => RunDetailScreen(runId: run.id),
          ),
        );
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
                    '${run.distanceKm.toStringAsFixed(2)} กม. • ${_formatDuration(run.durationSec)} • ${_formatPace(run.avgPace)}',
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
    );
  }
}
