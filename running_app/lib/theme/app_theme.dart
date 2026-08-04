import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ธีมหลักของแอป - โทนสีมินิมอลชมพู (Blush Pink / Rose Gold) + Soft Charcoal
/// สื่อถึงความอ่อนโยน ทันสมัย เป็นมิตร เข้าถึงง่าย ไม่ดูแข็งเป็นสไตล์ AI เทมเพลต
class AppColors {
  static const Color primary = Color(0xFFE8627C); // Soft Rose Pink
  static const Color primaryDark = Color(0xFFC7435D);
  static const Color primaryLight = Color(0xFFFDE8EC);
  static const Color secondary = Color(0xFF2D2B3D); // Soft Charcoal / Dark Violet
  static const Color accent = Color(0xFF7C5CFC); // Soft Lavender / Violet
  static const Color accentLight = Color(0xFFF0ECFF);
  static const Color gold = Color(0xFFF5A623); // Warm Rose Gold / Honey

  static const Color background = Color(0xFFFDF5F7); // Blush Cream
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF2D2B3D);
  static const Color textSecondary = Color(0xFF8E8B9E);
  static const Color divider = Color(0xFFF0EAEE);

  static const List<Color> primaryGradient = [
    Color(0xFFE8627C),
    Color(0xFFF58A9F),
  ];

  static const List<Color> darkGradient = [
    Color(0xFF2D2B3D),
    Color(0xFF3F3B54),
  ];

  static const List<Color> goldGradient = [
    Color(0xFFF5A623),
    Color(0xFFFFC05A),
  ];
}

class AppTheme {
  static ThemeData get lightTheme {
    final base = ThemeData.light();
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.primary,
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.surface,
      ),
      textTheme: GoogleFonts.nunitoTextTheme(base.textTheme).apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: AppColors.textPrimary),
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
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
          side: const BorderSide(color: AppColors.divider, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          foregroundColor: AppColors.textPrimary,
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.8),
        ),
      ),
    );
  }
}
