import 'package:flutter/material.dart';

/// Theme configuration for the application.
///
/// Provides both light and dark theme configurations following Material 3
/// design guidelines.
class ThemeConfig {
  ThemeConfig._();

  /// Seed color for generating the color scheme (淡化色調)
  static const Color seedColor = Color(0xFFB0B0B0); // 淺灰色

  /// 極簡風格的中性色彩
  static const Color neutralLight = Color(0xFFF5F5F5); // 背景淺灰
  static const Color neutralBorder = Color(0xFFE0E0E0); // 邊框灰
  static const Color neutralText = Color(0xFF424242); // 文字深灰
  static const Color accentColor = Color(0xFF90A4AE); // 柔和藍灰色作為強調色

  /// Light theme configuration
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: Brightness.light,
        primary: accentColor,
        surface: Colors.white,
      ),
      scaffoldBackgroundColor: neutralLight,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: neutralText,
      ),
      cardTheme: CardThemeData(
        elevation: 0, // 移除陰影
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: neutralBorder, width: 1), // 添加邊框
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: neutralBorder),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  /// Dark theme configuration
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: Brightness.dark,
      ),
      appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
      ),
    );
  }
}
