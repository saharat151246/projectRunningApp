import 'package:flutter/material.dart';
import '../services/language_controller.dart';
import '../theme/app_theme.dart';

/// ปุ่มสลับภาษา TH / EN ดีไซน์มินิมอล เรียบหรู สะอาดตา
class LanguageToggle extends StatelessWidget {
  final bool compact;

  const LanguageToggle({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: LanguageController.instance,
      builder: (context, _) {
        final isTh = LanguageController.instance.isThai;

        return InkWell(
          onTap: () => LanguageController.instance.toggleLanguage(),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 10 : 12,
              vertical: compact ? 4 : 6,
            ),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.divider, width: 1.2),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.translate_rounded,
                  size: 15,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                _LanguageTab(label: 'TH', active: isTh),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    '/',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.divider,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                _LanguageTab(label: 'EN', active: !isTh),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LanguageTab extends StatelessWidget {
  final String label;
  final bool active;

  const _LanguageTab({required this.label, required this.active});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 12,
        fontWeight: active ? FontWeight.w800 : FontWeight.w500,
        color: active ? AppColors.primary : AppColors.textSecondary,
        letterSpacing: 0.3,
      ),
    );
  }
}
