import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../theme/app_theme.dart';
import '../../widgets/stat_card.dart';
import '../../services/stats_service.dart';
import '../../services/run_service.dart';
import '../../services/auth_service.dart';
import '../../services/coach_service.dart';
import '../../widgets/overtraining_warning_card.dart';
import '../../widgets/daily_plan_card.dart';
import '../coach/coach_chat_screen.dart';
import '../coach/coach_insight_screen.dart';
import '../history/run_detail_screen.dart';
import '../../widgets/user_avatar.dart';

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
  DailyPlanItem? _dailyPlan;
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
    final plan = await CoachService.instance.fetchDailyPlan();
    if (!mounted) return;
    setState(() {
      _coach = advice;
      _dailyPlan = plan;
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
      color: AppColors.primary,
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
                  Text('ยินดีต้อนรับ',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(userName,
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary)),
                ],
              ),
              UserAvatar(
                avatarUrl: AuthService.instance.currentUser?['avatar_url'] as String?,
                size: 46,
                iconSize: 24,
              ),
            ],
          ),
          const SizedBox(height: 20),

          if (_coach != null)
            OvertrainingWarningCard(
              advice: _coach!,
              onConsultCoach: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CoachChatScreen()),
                );
              },
            ),

          if (_dailyPlan != null)
            DailyPlanCard(
              plan: _dailyPlan!,
              onConsultCoach: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CoachChatScreen()),
                );
              },
            ),

          if (_loading)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
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
                            color: const Color(0xFFFF6B6B),
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
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
            const SizedBox(height: 14),
            Container(
              height: 160,
              padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.divider),
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
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondary)),
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
                          width: 16,
                          borderRadius: BorderRadius.circular(8),
                          gradient: LinearGradient(
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

            // สรุปคำแนะนำวันนี้ + ทางลัดไปหน้าข้อมูลเชิงลึก รวมเป็นบล็อกเดียว
            // (เดิมมีการ์ดแยกสามจุดที่พูดเรื่องเดียวกัน ลดให้เหลือจุดเดียวเพื่อไม่ให้ซ้ำซ้อน)
            GestureDetector(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CoachInsightScreen()),
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(Icons.insights_rounded, color: AppColors.primary, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('สรุปสภาพร่างกายวันนี้',
                              style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15)),
                          const SizedBox(height: 6),
                          if (_coachLoading)
                            Row(
                              children: [
                                SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.primary.withValues(alpha: 0.5),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text('กำลังดูข้อมูลการวิ่งของคุณ...',
                                    style: TextStyle(
                                        color: AppColors.textSecondary, fontSize: 12.5)),
                              ],
                            )
                          else
                            Text(
                              (_coach?.advice.isNotEmpty ?? false)
                                  ? _coach!.advice
                                  : 'ยังไม่มีคำแนะนำ ลองวิ่งดูสักครั้งแล้วกลับมาดูอีกที',
                              style: TextStyle(
                                color: AppColors.textPrimary.withValues(alpha: 0.85),
                                fontSize: 13,
                                height: 1.45,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          const SizedBox(height: 8),
                          Text('ดูรายละเอียดเพิ่มเติม',
                              style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 28),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('การวิ่งล่าสุด',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
              ],
            ),
            const SizedBox(height: 12),
            if (_recentRuns.isEmpty)
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Center(
                  child: Text('ยังไม่มีประวัติการวิ่ง เริ่มต้นการวิ่งครั้งแรกของคุณวันนี้',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
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
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
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
                              Text(
                                  '${run.distanceKm.toStringAsFixed(2)} กม. • ${_formatDuration(run.durationSec)}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w800, fontSize: 14.5)),
                              const SizedBox(height: 2),
                              Text(_formatDate(run.startTime),
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right_rounded,
                            color: AppColors.textSecondary, size: 22),
                      ],
                    ),
                  ))),
          ],
        ],
      ),
    );
  }
}
