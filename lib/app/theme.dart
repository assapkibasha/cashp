import 'package:flutter/material.dart';

class CashguardTheme {
  static const Color green = Color(0xFF18C964);
  static const Color darkBackground = Color(0xFF050706);
  static const Color darkCard = Color(0xFF121614);
  static const Color lightBackground = Color(0xFFF8FAF8);
  static const Color lightCard = Colors.white;

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: green,
      brightness: Brightness.light,
      primary: green,
      surface: lightCard,
    );
    return _base(scheme).copyWith(
      scaffoldBackgroundColor: lightBackground,
      cardColor: lightCard,
    );
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: green,
      brightness: Brightness.dark,
      primary: green,
      surface: darkCard,
    );
    return _base(scheme).copyWith(
      scaffoldBackgroundColor: darkBackground,
      cardColor: darkCard,
    );
  }

  static ThemeData _base(ColorScheme scheme) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: 'Roboto',
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: scheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: green,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: green.withValues(alpha: 0.18),
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
