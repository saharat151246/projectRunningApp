import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ธีมหลักของแอป - โทนสีมินิมอลชมพู (Blush Pink / Rose Gold) + Soft Charcoal
/// สื่อถึงความอ่อนโยน ทันสมัย เป็นมิตร เข้าถึงง่าย ไม่ดูแข็งเป็นสไตล์ AI เทมเพลต
///
/// รองรับทั้ง Light และ Dark mode: AppColors เป็นตัวแปร static ที่ "เปลี่ยนค่าได้"
/// (ไม่ใช่ const เหมือนเดิม) เพื่อให้ทุกหน้าจอที่อ้างอิง AppColors.xxx โดยตรง
/// (ไม่ผ่าน Theme.of(context)) อัปเดตสีตามโหมดปัจจุบันได้โดยไม่ต้องแก้ไฟล์ทีละหน้า
/// ดู [ThemeController] ที่เป็นตัวสลับโหมด + สั่ง rebuild ทั้งแอปเมื่อมีการเปลี่ยนโหมด
class _Palette {
  final Color primary;
  final Color primaryDark;
  final Color primaryLight;
  final Color secondary;
  final Color accent;
  final Color accentLight;
  final Color gold;
  final Color background;
  final Color surface;
  final Color textPrimary;
  final Color textSecondary;
  final Color divider;
  final List<Color> primaryGradient;
  final List<Color> darkGradient;
  final List<Color> goldGradient;

  const _Palette({
    required this.primary,
    required this.primaryDark,
    required this.primaryLight,
    required this.secondary,
    required this.accent,
    required this.accentLight,
    required this.gold,
    required this.background,
    required this.surface,
    required this.textPrimary,
    required this.textSecondary,
    required this.divider,
    required this.primaryGradient,
    required this.darkGradient,
    required this.goldGradient,
  });
}

const _light = _Palette(
  primary: Color(0xFFE8627C), // Soft Rose Pink
  primaryDark: Color(0xFFC7435D),
  primaryLight: Color(0xFFFDE8EC),
  secondary: Color(0xFF2D2B3D), // Soft Charcoal / Dark Violet
  accent: Color(0xFF7C5CFC), // Soft Lavender / Violet
  accentLight: Color(0xFFF0ECFF),
  gold: Color(0xFFF5A623), // Warm Rose Gold / Honey
  background: Color(0xFFFDF5F7), // Blush Cream
  surface: Color(0xFFFFFFFF),
  textPrimary: Color(0xFF2D2B3D),
  textSecondary: Color(0xFF8E8B9E),
  divider: Color(0xFFF0EAEE),
  primaryGradient: [Color(0xFFE8627C), Color(0xFFF58A9F)],
  darkGradient: [Color(0xFF2D2B3D), Color(0xFF3F3B54)],
  goldGradient: [Color(0xFFF5A623), Color(0xFFFFC05A)],
);

const _dark = _Palette(
  primary: Color(0xFFF0839A), // Rose สว่างขึ้นให้คมบนพื้นมืด
  primaryDark: Color(0xFFE8627C),
  primaryLight: Color(0xFF3D2833), // pink tint สำหรับกล่อง/badge บนพื้นมืด
  secondary: Color(0xFF3A3648), // charcoal panel (สว่างกว่าพื้นหลักเล็กน้อยให้ยังแยกชั้นได้)
  accent: Color(0xFFA48CFF), // Lavender สว่างขึ้น
  accentLight: Color(0xFF2E2A45),
  gold: Color(0xFFF5B23D),
  background: Color(0xFF17151C), // Charcoal อมชมพูเข้ม (คง personality ของแบรนด์)
  surface: Color(0xFF221F29),
  textPrimary: Color(0xFFF5F1F3),
  textSecondary: Color(0xFFA9A3B5),
  divider: Color(0xFF322E3B),
  primaryGradient: [Color(0xFFE8627C), Color(0xFFF0839A)],
  darkGradient: [Color(0xFF2A2733), Color(0xFF3A3548)],
  goldGradient: [Color(0xFFF5A623), Color(0xFFFFC05A)],
);

class AppColors {
  AppColors._();

  static bool isDark = false;

  static Color primary = _light.primary;
  static Color primaryDark = _light.primaryDark;
  static Color primaryLight = _light.primaryLight;
  static Color secondary = _light.secondary;
  static Color accent = _light.accent;
  static Color accentLight = _light.accentLight;
  static Color gold = _light.gold;
  static Color background = _light.background;
  static Color surface = _light.surface;
  static Color textPrimary = _light.textPrimary;
  static Color textSecondary = _light.textSecondary;
  static Color divider = _light.divider;
  static List<Color> primaryGradient = _light.primaryGradient;
  static List<Color> darkGradient = _light.darkGradient;
  static List<Color> goldGradient = _light.goldGradient;

  /// เรียกโดย [ThemeController] เมื่อโหมดเปลี่ยน (light/dark/system)
  /// เพื่ออัปเดตค่าสีทั้งหมดให้ตรงกับ brightness ปัจจุบัน
  static void setBrightness(Brightness brightness) {
    final p = brightness == Brightness.dark ? _dark : _light;
    isDark = brightness == Brightness.dark;
    primary = p.primary;
    primaryDark = p.primaryDark;
    primaryLight = p.primaryLight;
    secondary = p.secondary;
    accent = p.accent;
    accentLight = p.accentLight;
    gold = p.gold;
    background = p.background;
    surface = p.surface;
    textPrimary = p.textPrimary;
    textSecondary = p.textSecondary;
    divider = p.divider;
    primaryGradient = p.primaryGradient;
    darkGradient = p.darkGradient;
    goldGradient = p.goldGradient;
  }
}

class AppTheme {
  static ThemeData _themeFor(_Palette p, Brightness brightness) {
    final base = ThemeData(brightness: brightness);
    return base.copyWith(
      scaffoldBackgroundColor: p.background,
      primaryColor: p.primary,
      colorScheme: base.colorScheme.copyWith(
        brightness: brightness,
        primary: p.primary,
        secondary: p.accent,
        surface: p.surface,
      ),
      textTheme: GoogleFonts.nunitoTextTheme(base.textTheme).apply(
        bodyColor: p.textPrimary,
        displayColor: p.textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: p.textPrimary),
        titleTextStyle: TextStyle(
          color: p.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: p.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          side: BorderSide(color: p.divider, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          foregroundColor: p.textPrimary,
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: p.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: p.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: p.primary, width: 1.8),
        ),
      ),
    );
  }

  static ThemeData get lightTheme => _themeFor(_light, Brightness.light);
  static ThemeData get darkTheme => _themeFor(_dark, Brightness.dark);
}
