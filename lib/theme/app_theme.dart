import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const _ink = Color(0xFF202A27);
  static const _muted = Color(0xFF69746F);
  static const _paper = Color(0xFFFFFCF7);
  static const _canvas = Color(0xFFF6F2EA);
  static const _sage = Color(0xFF4E8F7A);
  static const _coral = Color(0xFFE27D5F);

  static ThemeData get lightTheme {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: _sage,
          brightness: Brightness.light,
        ).copyWith(
          primary: _sage,
          secondary: _coral,
          surface: _paper,
          onSurface: _ink,
          surfaceContainerHighest: const Color(0xFFE6EEE9),
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: _canvas,
      textTheme: GoogleFonts.notoSansKrTextTheme().apply(
        bodyColor: _ink,
        displayColor: _ink,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: _canvas,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.notoSansKr(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          color: _ink,
        ),
        iconTheme: const IconThemeData(color: _ink),
      ),
      cardTheme: CardThemeData(
        color: _paper,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: Color(0xFFE5DED2)),
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: _paper,
        indicatorColor: const Color(0xFFDCEBE4),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);

          return GoogleFonts.notoSansKr(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? _ink : _muted,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);

          return IconThemeData(color: isSelected ? _sage : _muted, size: 24);
        }),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: _sage,
        foregroundColor: Colors.white,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: _sage,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _sage,
          side: const BorderSide(color: _sage),
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _paper,
        labelStyle: const TextStyle(color: _muted),
        hintStyle: const TextStyle(color: _muted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
