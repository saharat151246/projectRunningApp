import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../onboarding_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AuthService.instance,
      builder: (context, _) {
        final user = AuthService.instance.currentUser;
        final name = user?['name'] as String? ?? 'ผู้ใช้';
        final email = user?['email'] as String? ?? '-';
        final provider = user?['auth_provider'] as String? ?? 'email';

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
          children: [
            const Text('โปรไฟล์',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 24),

            // Profile header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4)),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(colors: AppColors.primaryGradient),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person_rounded, color: Colors.white, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name,
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                        const SizedBox(height: 4),
                        Text(email,
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
                        const SizedBox(height: 6),
                        Text(
                          provider == 'google' ? 'เข้าสู่ระบบด้วย Google' : 'เข้าสู่ระบบด้วยอีเมล',
                          style: const TextStyle(
                              color: AppColors.accent, fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            const Row(
              children: [
                Expanded(child: _MiniStat(label: 'น้ำหนัก', value: '-- กก.')),
                SizedBox(width: 12),
                Expanded(child: _MiniStat(label: 'ส่วนสูง', value: '-- ซม.')),
                SizedBox(width: 12),
                Expanded(child: _MiniStat(label: 'อายุ', value: '-- ปี')),
              ],
            ),

            const SizedBox(height: 28),
            const Text('บัญชีของฉัน', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(height: 8),
            const _MenuTile(icon: Icons.person_outline_rounded, label: 'แก้ไขข้อมูลส่วนตัว'),
            const _MenuTile(icon: Icons.favorite_border_rounded, label: 'เป้าหมายการวิ่ง'),
            const _MenuTile(icon: Icons.notifications_none_rounded, label: 'การแจ้งเตือน'),

            const SizedBox(height: 20),
            const Text('ทั่วไป', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(height: 8),
            const _MenuTile(icon: Icons.privacy_tip_outlined, label: 'ความเป็นส่วนตัว'),
            const _MenuTile(icon: Icons.help_outline_rounded, label: 'ช่วยเหลือ'),
            _MenuTile(
              icon: Icons.logout_rounded,
              label: 'ออกจากระบบ',
              isDanger: true,
              onTap: () async {
                await AuthService.instance.logout();
                if (!context.mounted) return;
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const OnboardingScreen()),
                  (route) => false,
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDanger;
  final VoidCallback? onTap;

  const _MenuTile({
    required this.icon,
    required this.label,
    this.isDanger = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDanger ? Colors.redAccent : AppColors.textPrimary;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        onTap: onTap ?? () {},
        leading: Icon(icon, color: color, size: 22),
        title: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13.5)),
        trailing: Icon(Icons.chevron_right_rounded, color: color.withValues(alpha: 0.5)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
