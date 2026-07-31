import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../theme/app_theme.dart';
import '../../widgets/stat_card.dart';
import '../../services/stats_service.dart';
import '../../services/run_service.dart';
import '../../services/auth_service.dart';
import '../../services/coach_service.dart';
import '../history/run_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  RunSummary? _summary;
  List<RunItem> _recentRuns = [];
  bool _loading = true;

  CoachAdvice? _coach;
  bool _coachLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
    _loadCoach();
  }

  Future<void> _loadCoach() async {
    setState(() => _coachLoading = true);
    final advice = await CoachService.instance.fetchAdvice();
    if (!mounted) return;
    setState(() {
      _coach = advice;
      _coachLoading = false;
    });
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final summary = await RunService.instance.fetchSummary();
    final runs = await RunService.instance.fetchRuns();
    if (!mounted) return;
    setState(() {
      _summary = summary;
      _recentRuns = runs.take(3).toList();
      _loading = false;
    });
  }

  String _formatDuration(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
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
    final userName = AuthService.instance.currentUser?['name'] as String? ?? 'นักวิ่ง';

    return RefreshIndicator(
      onRefresh: () => Future.wait([_load(), _loadCoach()]),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('สวัสดี ☀️',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(userName,
                      style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary)),
                ],
              ),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_rounded, color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 24),

          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
            )
          else ...[
            // Stat cards - ระยะทาง/จำนวนครั้งจาก MongoDB จริง, แต้ม/streak จากสถิติในเครื่อง
            AnimatedBuilder(
              animation: StatsService.instance,
              builder: (context, _) {
                final localStats = StatsService.instance.stats;
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: StatCard(
                            label: 'ระยะทางรวม',
                            value: summary.totalDistanceKm.toStringAsFixed(1),
                            unit: 'กม.',
                            icon: Icons.map_outlined,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: StatCard(
                            label: 'จำนวนครั้งที่วิ่ง',
                            value: '${summary.totalRuns}',
                            unit: 'ครั้ง',
                            icon: Icons.repeat_rounded,
                            color: AppColors.accent,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: StatCard(
                            label: 'แต้มสะสม',
                            value: '${localStats.totalPoints}',
                            unit: 'pt',
                            icon: Icons.star_rounded,
                            color: AppColors.gold,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: StatCard(
                            label: 'วิ่งต่อเนื่อง',
                            value: '${localStats.currentStreakDays}',
                            unit: 'วัน',
                            icon: Icons.local_fire_department_rounded,
                            color: const Color(0xFFFF5A3C),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 28),
            const Text('สรุประยะทาง 7 วันล่าสุด',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 14),
            Container(
              height: 160,
              padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
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
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: (summary.weeklyDistance.isEmpty
                          ? 1
                          : summary.weeklyDistance.reduce((a, b) => a > b ? a : b))
                      .clamp(1, double.infinity) *
                      1.3,
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
                  barGroups: List.generate(summary.weeklyDistance.length, (i) {
                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: summary.weeklyDistance[i],
                          width: 18,
                          borderRadius: BorderRadius.circular(6),
                          gradient: const LinearGradient(
                            colors: AppColors.primaryGradient,
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),

            const SizedBox(height: 28),

            // AI Coach - คำแนะนำจริงจาก Gemini (fallback เป็น rule-based ถ้า Gemini ใช้ไม่ได้)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: const LinearGradient(
                  colors: AppColors.darkGradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.psychology_alt_rounded,
                        color: AppColors.accent, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text('AI Coach แนะนำ',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14)),
                            if (!_coachLoading && _coach?.source == 'gemini') ...[
                              const SizedBox(width: 6),
                              Container(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.accent.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text('AI',
                                    style: TextStyle(
                                        color: AppColors.accent,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700)),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 6),
                        if (_coachLoading)
                          Row(
                            children: [
                              SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white.withOpacity(0.6),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text('กำลังวิเคราะห์ข้อมูลการวิ่งของคุณ...',
                                  style: TextStyle(
                                      color: Colors.white.withOpacity(0.6), fontSize: 12.5)),
                            ],
                          )
                        else
                          Text(
                            (_coach?.advice.isNotEmpty ?? false)
                                ? _coach!.advice
                                : 'ยังไม่มีคำแนะนำในตอนนี้ ลองวิ่งดูสักครั้งแล้วกลับมาดูอีกครั้ง',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.85),
                              fontSize: 13,
                              height: 1.5,
                            ),
                          ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: OutlinedButton.icon(
                            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('เปิดแชท AI Coach ได้จากปุ่มลอยด้านขวาล่าง')),
                            ),
                            style: OutlinedButton.styleFrom(
                              minimumSize: Size.zero,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              side: BorderSide(color: Colors.white.withOpacity(0.3)),
                              foregroundColor: Colors.white,
                            ),
                            icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                            label: const Text('เปิดจากปุ่มแชทด้านขวา', style: TextStyle(fontSize: 12.5)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text('การวิ่งล่าสุด',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 12),
            if (_recentRuns.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Text('ยังไม่มีประวัติการวิ่ง ลองไปกดเริ่มวิ่งดูก่อนเลย!',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
                ),
              )
            else
              ..._recentRuns.map((run) => GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => RunDetailScreen(runId: run.id),
                        ),
                      );
                    },
                    child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
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
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: AppColors.accent.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.directions_run_rounded,
                              color: AppColors.accent, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  '${run.distanceKm.toStringAsFixed(2)} กม. • ${_formatDuration(run.durationSec)}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700, fontSize: 14)),
                              const SizedBox(height: 2),
                              Text(_formatDate(run.startTime),
                                  style: const TextStyle(
                                      fontSize: 12, color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded,
                            color: AppColors.textSecondary, size: 20),
                      ],
                    ),
                  ))),
          ],
        ],
      ),
    );
  }
}
