import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'home/home_screen.dart';
import 'tracking/tracking_screen.dart';
import 'dashboard/dashboard_screen.dart';
import 'gamification/gamification_screen.dart';
import 'profile/profile_screen.dart';
import '../widgets/coach_chat_popup.dart';

/// Shell หลักที่มี Bottom Navigation เชื่อม 5 หน้าจอหลักของแอป
class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _index = 0;

  final _screens = const [
    HomeScreen(),
    DashboardScreen(),
    SizedBox.shrink(), // placeholder - ปุ่มกลางเปิด Tracking แบบ full screen แทน
    GamificationScreen(),
    ProfileScreen(),
  ];

  void _openTracking() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const TrackingScreen()),
    );
  }

  void _onTap(int i) {
    if (i == 2) {
      _openTracking();
      return;
    }
    setState(() => _index = i);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(child: _screens[_index]),
          floatingActionButton: Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: AppColors.primaryGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.4),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: FloatingActionButton(
              onPressed: _openTracking,
              backgroundColor: Colors.transparent,
              elevation: 0,
              highlightElevation: 0,
              child: const Icon(Icons.directions_run_rounded,
                  color: Colors.white, size: 28),
            ),
          ),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerDocked,
          bottomNavigationBar: BottomAppBar(
            shape: const CircularNotchedRectangle(),
            notchMargin: 8,
            color: AppColors.surface,
            elevation: 12,
            shadowColor: Colors.black.withValues(alpha: 0.08),
            child: SizedBox(
              height: 62,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _navItem(0, Icons.home_rounded, 'หน้าหลัก'),
                  _navItem(1, Icons.bar_chart_rounded, 'สถิติ'),
                  const SizedBox(width: 48), // เว้นที่ให้ FAB
                  _navItem(3, Icons.emoji_events_rounded, 'ภารกิจ'),
                  _navItem(4, Icons.person_rounded, 'โปรไฟล์'),
                ],
              ),
            ),
          ),
        ),
        const CoachChatPopup(),
      ],
    );
  }

  Widget _navItem(int i, IconData icon, String label) {
    final selected = _index == i;
    final color = selected ? AppColors.primary : AppColors.textSecondary;
    return Expanded(
      child: InkWell(
        onTap: () => _onTap(i),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.primaryLight
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: selected ? 24 : 22),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
