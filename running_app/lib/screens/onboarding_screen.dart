import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/primary_button.dart';
import '../widgets/language_toggle.dart';
import '../services/language_controller.dart';
import 'auth/login_screen.dart';

class _OnboardData {
  final IconData icon;
  final String titleTh;
  final String titleEn;
  final String descTh;
  final String descEn;

  const _OnboardData({
    required this.icon,
    required this.titleTh,
    required this.titleEn,
    required this.descTh,
    required this.descEn,
  });
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _page = 0;

  final List<_OnboardData> _slides = const [
    _OnboardData(
      icon: Icons.gps_fixed_rounded,
      titleTh: 'ติดตามการวิ่งแบบ Real-time',
      titleEn: 'Real-time Run Tracking',
      descTh: 'บันทึกเส้นทาง ระยะทาง ความเร็ว\nและเวลาการวิ่งได้อย่างแม่นยำ',
      descEn: 'Accurately track your route, distance, pace\nand running time via GPS',
    ),
    _OnboardData(
      icon: Icons.psychology_alt_rounded,
      titleTh: 'AI Coach ส่วนตัว',
      titleEn: 'Personal AI Coach',
      descTh: 'วิเคราะห์การวิ่งของคุณ\nแนะนำแผนฝึกซ้อมลดความเสี่ยงบาดเจ็บ',
      descEn: 'Analyze your running progress and get\nsmart plans that prevent injuries',
    ),
    _OnboardData(
      icon: Icons.emoji_events_rounded,
      titleTh: 'สนุกกับภารกิจและเหรียญตรา',
      titleEn: 'Fun Missions & Badges',
      descTh: 'สะสมแต้ม ปลดล็อกความสำเร็จ\nสร้างแรงจูงใจให้วิ่งต่อเนื่องทุกวัน',
      descEn: 'Earn points, unlock achievements\nand stay inspired to run every day',
    ),
  ];

  void _goToLogin() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: LanguageController.instance,
      builder: (context, _) {
        final lang = LanguageController.instance;
        final screenSize = MediaQuery.of(context).size;
        final isTablet = screenSize.width > 600;
        final isLast = _page == _slides.length - 1;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const LanguageToggle(),
                      TextButton(
                        onPressed: _goToLogin,
                        child: Text(
                          lang.text('ข้าม', 'Skip'),
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    itemCount: _slides.length,
                    onPageChanged: (i) => setState(() => _page = i),
                    itemBuilder: (context, i) {
                      final s = _slides[i];
                      return Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: isTablet ? 64 : 32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: isTablet ? 180 : 130,
                              height: isTablet ? 180 : 130,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(alpha: 0.15),
                                    blurRadius: 30,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Icon(
                                s.icon,
                                size: isTablet ? 80 : 58,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 36),
                            Text(
                              lang.text(s.titleTh, s.titleEn),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: isTablet ? 26 : 22,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              lang.text(s.descTh, s.descEn),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: isTablet ? 16 : 14.5,
                                color: AppColors.textSecondary,
                                height: 1.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _slides.length,
                    (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _page == i ? 26 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _page == i ? AppColors.primary : AppColors.divider,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(isTablet ? 32 : 24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: PrimaryButton(
                      label: isLast
                          ? lang.text('เริ่มต้นใช้งาน', 'Get Started')
                          : lang.text('ถัดไป', 'Next'),
                      icon: isLast ? Icons.arrow_forward_rounded : null,
                      onPressed: () {
                        if (isLast) {
                          _goToLogin();
                        } else {
                          _controller.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOut,
                          );
                        }
                      },
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
}
