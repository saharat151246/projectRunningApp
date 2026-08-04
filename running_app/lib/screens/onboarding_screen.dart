import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/primary_button.dart';
import 'auth/login_screen.dart';

class _OnboardData {
  final IconData icon;
  final String title;
  final String description;
  const _OnboardData(this.icon, this.title, this.description);
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
      Icons.gps_fixed_rounded,
      'ติดตามการวิ่งแบบ Real-time',
      'บันทึกเส้นทาง ระยะทาง ความเร็ว\nและเวลาการวิ่งได้อย่างแม่นยำ',
    ),
    _OnboardData(
      Icons.psychology_alt_rounded,
      'AI Coach ส่วนตัว',
      'วิเคราะห์การวิ่งของคุณ\nแนะนำแผนฝึกซ้อมลดความเสี่ยงบาดเจ็บ',
    ),
    _OnboardData(
      Icons.emoji_events_rounded,
      'สนุกกับภารกิจและเหรียญตรา',
      'สะสมแต้ม ปลดล็อกความสำเร็จ\nสร้างแรงจูงใจให้วิ่งต่อเนื่องทุกวัน',
    ),
  ];

  void _goToLogin() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final isLast = _page == _slides.length - 1;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextButton(
                  onPressed: _goToLogin,
                  child: const Text(
                    'ข้าม',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
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
                          s.title,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: isTablet ? 26 : 22,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          s.description,
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
                  label: isLast ? 'เริ่มต้นใช้งาน' : 'ถัดไป',
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
  }
}
