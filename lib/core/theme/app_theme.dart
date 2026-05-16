import 'package:flutter/material.dart';

class AppTheme {
  static const Color midnight = Color(0xFF05070D);
  static const Color ink = Color(0xFF0E1626);
  static const Color indigo = Color(0xFF1D3557);
  static const Color royalBlue = Color(0xFF1D5CFF);
  static const Color sampaguita = Color(0xFFF8F5EC);
  static const Color pearl = Color(0xFFEAF2FF);
  static const Color gold = Color(0xFFF5C451);
  static const Color coral = Color(0xFFFF4D6D);

  static ThemeData get lightTheme => darkTheme;

  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: royalBlue,
      brightness: Brightness.dark,
      primary: royalBlue,
      secondary: gold,
      tertiary: coral,
      surface: ink,
      onSurface: sampaguita,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: midnight,
      colorScheme: colorScheme,
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: midnight,
        foregroundColor: sampaguita,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: ink,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFF080C14),
        indicatorColor: royalBlue.withValues(alpha: 0.24),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            color: states.contains(WidgetState.selected) ? pearl : Colors.grey,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected) ? gold : Colors.grey,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ink,
        labelStyle: const TextStyle(color: Color(0xFF9FB3D9)),
        hintStyle: const TextStyle(color: Color(0xFF8091B3)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF2C4168)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: gold),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }
}
