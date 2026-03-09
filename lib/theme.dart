import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primary = Color(0xFF2B6CEE);
  static const Color backgroundLight = Color(0xFFF6F6F8);
  static const Color backgroundDark = Color(0xFF101622);
  static const Color backgroundDeep = Color(0xFF020617);
  static const Color cardBg = Color(0x331E293B); // slate-800/20 approx
  static const Color textLight = Color(0xFFF1F5F9); // slate-100
  static const Color textMuted = Color(0xFF94A3B8); // slate-400

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: primary,
      scaffoldBackgroundColor: backgroundDark,
      textTheme: GoogleFonts.spaceGroteskTextTheme(ThemeData.dark().textTheme)
          .copyWith(
            displayLarge: const TextStyle(
              color: textLight,
              fontWeight: FontWeight.bold,
            ),
            titleLarge: const TextStyle(
              color: textLight,
              fontWeight: FontWeight.bold,
            ),
            bodyLarge: const TextStyle(color: textLight),
            bodyMedium: const TextStyle(color: textMuted),
          ),
      colorScheme: const ColorScheme.dark(primary: primary, surface: cardBg),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 8,
          shadowColor: primary.withValues(alpha: 0.4),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.03),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: primary.withValues(alpha: 0.5),
            width: 2,
          ),
        ),
        labelStyle: const TextStyle(color: textMuted),
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
      ),
    );
  }
}
