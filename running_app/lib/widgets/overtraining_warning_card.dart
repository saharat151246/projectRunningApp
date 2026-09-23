import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/coach_model.dart';
import '../services/language_controller.dart';

class OvertrainingWarningCard extends StatelessWidget {
  final CoachAdvice advice;
  final VoidCallback? onConsultCoach;
  final VoidCallback? onDismiss;

  const OvertrainingWarningCard({
    super.key,
    required this.advice,
    this.onConsultCoach,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    if (!advice.overtrainingRisk && !advice.fatigueSignal) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: LanguageController.instance,
      builder: (context, _) {
        final lang = LanguageController.instance;
        final changePercent = advice.weeklyChangePercent;
        final isHighIncrease = advice.overtrainingRisk;
        final isFatigue = advice.fatigueSignal;

        String reasonText = '';
        if (isHighIncrease && isFatigue) {
          reasonText = lang.text(
            'สัปดาห์นี้ระยะทางวิ่งของคุณเพิ่มขึ้น ${changePercent?.toStringAsFixed(1) ?? '10+'}% (เกินเกณฑ์ปลอดภัย 10%) และตรวจพบความรู้สึกเหนื่อยล้าสะสมจากการเช็คอินย้อนหลัง',
            'This week your running distance increased by ${changePercent?.toStringAsFixed(1) ?? '10+'}% (exceeding safe 10% rule) and fatigue accumulation was detected from check-ins.',
          );
        } else if (isHighIncrease) {
          reasonText = lang.text(
            'สัปดาห์นี้ระยะทางวิ่งของคุณ (${advice.thisWeekKm.toStringAsFixed(1)} กม.) เพิ่มขึ้น ${changePercent?.toStringAsFixed(1) ?? '10+'}% จากสัปดาห์ก่อน (${advice.lastWeekKm.toStringAsFixed(1)} กม.) ซึ่งเกินกฎปลอดภัย "ไม่เกิน 10%/สัปดาห์"',
            'This week your distance (${advice.thisWeekKm.toStringAsFixed(1)} ${lang.km}) increased by ${changePercent?.toStringAsFixed(1) ?? '10+'}% from last week (${advice.lastWeekKm.toStringAsFixed(1)} ${lang.km}), exceeding the safe 10%/week rule.',
          );
        } else {
          reasonText = lang.text(
            'จากการเช็คอินความรู้สึกหลังวิ่งย้อนหลัง ร่างกายส่งสัญญาณเหนื่อยล้าต่อเนื่องเกินเกณฑ์ปกติ ควรเพิ่มเวลาพักฟื้นกล้ามเนื้อ',
            'Based on post-run check-ins, your body indicates persistent fatigue beyond normal levels. Please take extra recovery time.',
          );
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFFFFF1F0),
                Color(0xFFFFF6F0),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFFF4D4F).withValues(alpha: 0.3),
              width: 1.2,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF4D4F).withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.warning_amber_rounded,
                        color: Color(0xFFE82A2A),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lang.text(
                              'ความเสี่ยงบาดเจ็บสูง (Overtraining)',
                              'High Injury Risk (Overtraining)',
                            ),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFC01C1C),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            lang.text(
                              'คำเตือนด้านสุขภาพและการฝึกซ้อม',
                              'Health & Training Warning',
                            ),
                            style: TextStyle(
                              fontSize: 11.5,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (onDismiss != null)
                      IconButton(
                        icon: Icon(Icons.close_rounded, size: 18, color: AppColors.textSecondary),
                        onPressed: onDismiss,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  reasonText,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    color: Color(0xFF374151),
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFFD6D6)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.health_and_safety_outlined, size: 18, color: Color(0xFFE82A2A)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          lang.text(
                            'คำแนะนำ: แนะนำให้ลดระยะทางลง 20-30% หรือเพิ่มวันพัก 1-2 วัน',
                            'Recommendation: Reduce mileage by 20-30% or add 1-2 rest days.',
                          ),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF991B1B),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (onConsultCoach != null) ...[
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: onConsultCoach,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE82A2A),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.forum_outlined, size: 18),
                      label: Text(
                        lang.text('ปรึกษา AI Coach ปรับแผนซ้อม', 'Consult AI Coach to Adjust Plan'),
                        style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
