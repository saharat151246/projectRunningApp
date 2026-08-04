import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';

/// จัดการโหมดการแสดงผลของทั้งแอป (สว่าง / มืด / ตามระบบ)
///
/// เนื่องจากหลายหน้าจอในแอปอ้างอิงสีผ่าน `AppColors.xxx` โดยตรง (ไม่ผ่าน
/// Theme.of(context)) ตัวนี้จึงทำหน้าที่ 2 อย่างเมื่อโหมดเปลี่ยน:
/// 1. อัปเดตค่าใน [AppColors] ให้ตรงกับพาเลตใหม่ (ดู AppColors.setBrightness)
/// 2. แจ้ง listeners (main.dart) ให้ rebuild ทั้งต้นไม้ของแอป ด้วย key ใหม่
///    เพื่อให้ทุกหน้าจอ build ใหม่ด้วยสีที่อัปเดตแล้ว
class ThemeController extends ChangeNotifier {
  ThemeController._();
  static final ThemeController instance = ThemeController._();

  static const _prefKey = 'pref_theme_mode';

  ThemeMode _mode = ThemeMode.system;
  ThemeMode get mode => _mode;

  /// เพิ่มค่าทุกครั้งที่ต้องบังคับ rebuild ต้นไม้ทั้งหมด (ใช้เป็น ValueKey ใน main.dart)
  int rebuildToken = 0;

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    WidgetsBinding.instance.platformDispatcher.onPlatformBrightnessChanged =
        () {
      if (_mode == ThemeMode.system) {
        _applyBrightness();
        rebuildToken++;
        notifyListeners();
      }
    };

    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefKey);
    _mode = switch (saved) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    _applyBrightness();
  }

  Brightness get _platformBrightness =>
      WidgetsBinding.instance.platformDispatcher.platformBrightness;

  void _applyBrightness() {
    final brightness = switch (_mode) {
      ThemeMode.light => Brightness.light,
      ThemeMode.dark => Brightness.dark,
      ThemeMode.system => _platformBrightness,
    };
    AppColors.setBrightness(brightness);
  }

  Future<void> setMode(ThemeMode mode) async {
    if (_mode == mode) return;
    _mode = mode;
    _applyBrightness();
    rebuildToken++;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    });
  }
}
