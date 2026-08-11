import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/coach_service.dart';
import 'coach_chat_screen.dart';

class CoachInsightScreen extends StatefulWidget {
  const CoachInsightScreen({super.key});

  @override
  State<CoachInsightScreen> createState() => _CoachInsightScreenState();
}

class _CoachInsightScreenState extends State<CoachInsightScreen> {
  CoachInsightReport? _report;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final report = await CoachService.instance.fetchInsights();
    if (!mounted) return;
    setState(() {
      _report = report;
      _loading = false;
    });
  }

  String _formatPace(double? pace) {
    if (pace == null || pace <= 0) return '-';
    final min = pace.floor();
    final sec = ((pace - min) * 60).round().toString().padLeft(2, '0');
    return '$min:$sec';
  }

  String _weatherLabel(String? w) {
    switch (w) {
      case 'cool':
        return '❄️ เย็นสบาย';
      case 'hot':
        return '☀️ ร้อน';
      case 'rainy':
        return '🌧️ ฝนตก';
      case 'normal':
        return '☁️ ปกติ';
      default:
        return 'ยังไม่มีข้อมูล';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Row(
          children: [
            Icon(Icons.insights_rounded, color: AppColors.primary, size: 22),
            const SizedBox(width: 8),
            const Text('Athlete Intelligence'),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        color: AppColors.primary,
        child: _loading
            ? Center(child: CircularProgressIndicator(color: AppColors.primary))
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                children: [
                  // Title Banner
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: AppColors.primaryGradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.25),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.auto_awesome, color: Colors.white, size: 14),
                                  SizedBox(width: 4),
                                  Text(
                                    'Long-term Pattern',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            Text(
                              'วิเคราะห์จาก ${_report?.totalRuns ?? 0} การวิ่ง',
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 11),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'บทวิเคราะห์การพักฟื้น & สมรรถภาพ',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _report?.summary ?? '',
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.45,
                            color: Colors.white.withValues(alpha: 0.95),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  Text(
                    'ปัจจัยการฟื้นฟูร่างกาย (Recovery Insights)',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 💤 Sleep vs Pace Card
                  _buildMetricCard(
                    icon: Icons.nightlight_round,
                    iconColor: const Color(0xFF6366F1),
                    title: 'ผลของการนอนหลับต่อเพซ (Sleep Impact)',
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildSubStat(
                                label: 'นอน 7+ ชม.',
                                value: _formatPace(_report?.goodSleepAvgPace),
                                subText: 'เพซเฉลี่ย',
                                color: const Color(0xFF10B981),
                              ),
                            ),
                            Container(width: 1, height: 40, color: AppColors.divider),
                            Expanded(
                              child: _buildSubStat(
                                label: 'นอนน้อย (<6 ชม.)',
                                value: _formatPace(_report?.poorSleepAvgPace),
                                subText: 'เพซเฉลี่ย',
                                color: const Color(0xFFEF4444),
                              ),
                            ),
                          ],
                        ),
                        if (_report?.sleepPaceDiffSec != null && _report!.sleepPaceDiffSec! > 0) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6366F1).withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.bolt, color: Color(0xFF6366F1), size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'นอนเต็มอิ่มช่วยให้เพซเร็วขึ้น ${_report!.sleepPaceDiffSec} วินาที/กม.',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF4338CA),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 🧘 Stress Impact Card
                  _buildMetricCard(
                    icon: Icons.psychology,
                    iconColor: const Color(0xFFF59E0B),
                    title: 'ระดับความเครียด (Stress Level)',
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildSubStat(
                            label: 'ความเครียดต่ำ',
                            value: _formatPace(_report?.lowStressAvgPace),
                            subText: 'เพซเฉลี่ย',
                            color: const Color(0xFF10B981),
                          ),
                        ),
                        Container(width: 1, height: 40, color: AppColors.divider),
                        Expanded(
                          child: _buildSubStat(
                            label: 'ความเครียดสูง',
                            value: _formatPace(_report?.highStressAvgPace),
                            subText: 'เพซเฉลี่ย',
                            color: const Color(0xFFF59E0B),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 🌤️ Best Running Weather Card
                  _buildMetricCard(
                    icon: Icons.wb_sunny_rounded,
                    iconColor: const Color(0xFF0EA5E9),
                    title: 'สภาพอากาศที่คุณวิ่งได้ดีที่สุด',
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0EA5E9).withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.thermostat, color: Color(0xFF0EA5E9), size: 24),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _weatherLabel(_report?.bestWeather),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              'สภาพอากาศที่ทำเพซได้ดีที่สุดของคุณ',
                              style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const CoachChatScreen()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.forum_outlined, size: 18),
                      label: const Text(
                        'พูดคุยวิเคราะห์เชิงลึกกับ AI Coach',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _buildSubStat({
    required String label,
    required String value,
    required String subText,
    required Color color,
  }) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
        Text(subText, style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
      ],
    );
  }
}
