// カワイイ風パステルテーマ。ピンク・水色・キラキラを基調にした配色。
/*
Dependency Memo
- Depends on: Flutter ThemeData and ColorScheme APIs.
- Requires methods: ThemeData constructors.
- Provides methods: AppTheme.build(), AppTheme.pink, AppTheme.blue, etc.
*/
import 'package:flutter/material.dart';

class AppTheme {
  const AppTheme._();

  // カワイイ風カラーパレット
  static const Color pink = Color(0xFFFF8FAB);
  static const Color pinkLight = Color(0xFFFFB3C6);
  static const Color pinkDark = Color(0xFFE0607E);
  static const Color blue = Color(0xFF8ED6F0);
  static const Color blueLight = Color(0xFFBCEAFF);
  static const Color cream = Color(0xFFFFF5F7);
  static const Color shellPink = Color(0xFFFFD1DC);
  static const Color shellWhite = Color(0xFFFFF0F5);
  static const Color heartRed = Color(0xFFFF4D6D);
  static const Color gold = Color(0xFFFFD700);
  static const Color screenBg = Color(0xFF1A0A14);

  static ThemeData build() {
    return ThemeData(
      useMaterial3: false,
      scaffoldBackgroundColor: cream,
      colorScheme: ColorScheme.fromSeed(
        seedColor: pink,
        brightness: Brightness.light,
        primary: pink,
      ),
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      textTheme: const TextTheme(
        bodyMedium: TextStyle(
          letterSpacing: 0.1,
          height: 1.2,
          color: Color(0xFF4A2030),
          fontWeight: FontWeight.w600,
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
