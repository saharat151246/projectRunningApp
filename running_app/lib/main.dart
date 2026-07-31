import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'services/stats_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StatsService.instance.init();
  runApp(const RunningApp());
}

class RunningApp extends StatelessWidget {
  const RunningApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RunMate',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}
