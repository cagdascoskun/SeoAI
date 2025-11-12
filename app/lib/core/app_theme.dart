import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData light() {
    final base = ThemeData.dark(useMaterial3: true);
    final cardTheme = base.cardTheme.copyWith(
      elevation: 4,
      color: const Color(0xFF1F1F24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
    );

    return base.copyWith(
      scaffoldBackgroundColor: const Color(0xFF0F0F13),
      colorScheme: base.colorScheme.copyWith(
        primary: const Color(0xFF7DF9FF),
        secondary: const Color(0xFF9D4EDD),
        surface: const Color(0xFF18181F),
      ),
      textTheme: base.textTheme.apply(
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        filled: true,
        fillColor: const Color(0xFF1B1B21),
      ),
      cardTheme: cardTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0F0F13),
        foregroundColor: Colors.white,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Color(0xFF7DF9FF),
        foregroundColor: Colors.black,
      ),
    );
  }
}
