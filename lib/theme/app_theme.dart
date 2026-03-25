import 'package:flutter/material.dart';

class BeatSpillTheme {
  // ── Core palette ──────────────────────────────────
  static const Color background    = Color(0xFF121212);
  static const Color surface       = Color(0xFF1A1A1A);
  static const Color surfaceAlt    = Color(0xFF282828);
  static const Color green         = Color(0xFF1DB954);
  static const Color greenDark     = Color(0xFF145A32);
  static const Color textPrimary   = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB3B3B3);
  static const Color textMuted     = Color(0xFF535353);
  static const Color orange        = Color(0xFFE8821A);
  static const Color red           = Color(0xFFE74C3C);
  static const Color purple        = Color(0xFF8E44AD);
  static const Color blue          = Color(0xFF4285F4);

  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: background,
    colorScheme: const ColorScheme.dark(
      primary:   green,
      secondary: greenDark,
      surface:   surface,
      onPrimary: Colors.black,
      onSurface: textPrimary,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: background,
      foregroundColor: textPrimary,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: textPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.w900),
      headlineMedium: TextStyle(color: textPrimary, fontWeight: FontWeight.w700, fontSize: 22),
      titleMedium: TextStyle(color: textPrimary, fontWeight: FontWeight.w600, fontSize: 14),
      titleSmall: TextStyle(color: textPrimary, fontWeight: FontWeight.w600, fontSize: 12),
      bodyMedium: TextStyle(color: textSecondary, fontSize: 13),
      bodySmall: TextStyle(color: textSecondary, fontSize: 11),
      labelSmall: TextStyle(color: textMuted, fontSize: 10, letterSpacing: 0.8),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: green,
        foregroundColor: Colors.black,
        minimumSize: const Size(double.infinity, 48),
        shape: const StadiumBorder(),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: textPrimary,
        minimumSize: const Size(double.infinity, 48),
        shape: const StadiumBorder(),
        side: const BorderSide(color: textMuted),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
    ),
    dividerColor: surfaceAlt,
    listTileTheme: const ListTileThemeData(
      iconColor: textSecondary,
      textColor: textPrimary,
      subtitleTextStyle: TextStyle(color: textSecondary, fontSize: 12),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF0D0D0D),
      selectedItemColor: textPrimary,
      unselectedItemColor: textSecondary,
      showSelectedLabels: true,
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
      unselectedLabelStyle: TextStyle(fontSize: 10),
    ),
  );
}
