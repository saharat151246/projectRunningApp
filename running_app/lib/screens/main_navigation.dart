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
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(colors: AppColors.primaryGradient),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: _openTracking,
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(Icons.directions_run_rounded, color: Colors.white),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
          bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        color: AppColors.surface,
        elevation: 8,
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(color: color, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}
