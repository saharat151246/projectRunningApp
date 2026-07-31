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
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        children: [
          const Text('สถิติของฉัน',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          const Text('ภาพรวมความก้าวหน้าการวิ่งทั้งหมด (ข้อมูลจริงจากฐานข้อมูล)',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 24),

          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 60),
              child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
            )
          else ...[
            Container(
              height: 200,
              padding: const EdgeInsets.fromLTRB(8, 20, 16, 12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4)),
                ],
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
                                style: const TextStyle(
                                    fontSize: 11, color: AppColors.textSecondary)),
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
                      color: AppColors.primary,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppColors.primary.withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 28),
            const Text('ประวัติการวิ่งทั้งหมด',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 12),

            if (_runs.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Text('ยังไม่มีประวัติการวิ่ง',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
                ),
              )
            else
              ..._runs.map((run) => GestureDetector(
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
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 3)),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.directions_run_rounded,
                              color: AppColors.primary),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_formatDate(run.startTime),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700, fontSize: 13.5)),
                              const SizedBox(height: 4),
                              Text(
                                '${run.distanceKm.toStringAsFixed(2)} กม. • ${_formatDuration(run.durationSec)} • ${_formatPace(run.avgPace)}',
                                style: const TextStyle(
                                    fontSize: 12, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded,
                            color: AppColors.textSecondary),
                      ],
                    ),
                  ))),
          ],
        ],
      ),
    );
  }
}
