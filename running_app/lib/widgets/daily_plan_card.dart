import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/coach_model.dart';
import '../services/language_controller.dart';

class DailyPlanCard extends StatelessWidget {
  final DailyPlanItem plan;
  final VoidCallback? onConsultCoach;

  const DailyPlanCard({
    super.key,
    required this.plan,
    this.onConsultCoach,
  });

  IconData _getActivityIcon() {
    switch (plan.activityType) {
      case 'rest':
        return Icons.airline_seat_flat_rounded;
      case 'interval':
        return Icons.speed_rounded;
      case 'long_run':
        return Icons.directions_run_rounded;
      case 'easy_run':
      default:
        return Icons.directions_walk_rounded;
    }
  }

  Color _getActivityColor() {
    switch (plan.activityType) {
      case 'rest':
        return AppColors.secondary;
      case 'interval':
        return AppColors.primaryDark;
      case 'long_run':
        return AppColors.gold;
      case 'easy_run':
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: LanguageController.instance,
      builder: (context, _) {
        final lang = LanguageController.instance;
        final themeColor = _getActivityColor();
        final isRest = plan.activityType == 'rest';

        return Container(
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: themeColor.withValues(alpha: 0.3), width: 1.2),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: themeColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(_getActivityIcon(), color: themeColor, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lang.text('แผนซ้อมวันนี้', "Today's Training Plan"),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            plan.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Targets row
                if (!isRest) ...[
                  Row(
                    children: [
                      Expanded(
                        child: _buildTargetChip(
                          icon: Icons.straighten_rounded,
                          label: lang.text('เป้าหมาย', 'Target'),
                          value: '${plan.targetDistanceKm.toStringAsFixed(1)} ${lang.km}',
                          color: themeColor,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildTargetChip(
                          icon: Icons.timer_outlined,
                          label: lang.text('เป้าหมายเพซ', 'Target Pace'),
                          value: plan.targetPace,
                          color: themeColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],

                // Rationale
                if (plan.rationale.isNotEmpty) ...[
                  Text(
                    plan.rationale,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.45,
                      color: AppColors.textPrimary.withValues(alpha: 0.85),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],

                // Tips
                if (plan.tips.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.lightbulb_outline_rounded, size: 16, color: themeColor),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            plan.tips,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Button
                if (onConsultCoach != null)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: onConsultCoach,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: themeColor,
                        side: BorderSide(color: themeColor.withValues(alpha: 0.5)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                      label: Text(
                        lang.text('คุยปรับแผนกับโค้ช', 'Discuss Plan with Coach'),
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTargetChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                Text(value, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: color)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
