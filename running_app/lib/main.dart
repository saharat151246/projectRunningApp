import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'services/stats_service.dart';
import 'services/theme_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StatsService.instance.init();
  await ThemeController.instance.init();
  runApp(const RunningApp());
}

class RunningApp extends StatelessWidget {
  const RunningApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeController.instance,
      builder: (context, _) {
        final token = ThemeController.instance.rebuildToken;
        return MaterialApp(
          title: 'RunMate',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeController.instance.mode,
          // ValueKey เปลี่ยนทุกครั้งที่สลับโหมด -> Flutter สร้างทั้งต้นไม้ใหม่
          // ทำให้ทุกหน้าจอที่อ้างอิง AppColors.xxx โดยตรง build ใหม่ด้วยสีที่ถูกต้อง
          // token == 0 คือเปิดแอปครั้งแรก (เล่น intro animation ตามปกติ)
          // token > 0 คือสลับโหมดสีจากผู้ใช้ (ข้าม intro ไปหน้าเดิมทันที)
          home: SplashScreen(
            key: ValueKey('app-root-$token'),
            skipIntro: token > 0,
          ),
        );
      },
    );
  }
}
