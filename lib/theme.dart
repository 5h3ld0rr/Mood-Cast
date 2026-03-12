import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primary = Color(0xFF2B6CEE);
  static const Color backgroundLight = Color(0xFFF6F6F8);
  static const Color backgroundDark = Color(0xFF080C14);
  static const Color backgroundDeep = Color(0xFF020408);
  static const Color cardBg = Color(0x331E293B);
  static const Color textLight = Color(0xFFF1F5F9);
  static const Color textMuted = Color(0xFF94A3B8);

  static Map<String, Color> get moodColors => {
    'Happy': const Color(0xFFFFD700), // Gold
    'Sad': const Color(0xFF4A90E2), // Blue
    'Angry': const Color(0xFFFF3B30), // Red
    'Natural': primary, // Default Blue
  };

  static Map<String, Color> get moodBackgrounds => {
    'Happy': const Color(0xFF0F0E01),
    'Sad': const Color(0xFF050A14),
    'Angry': const Color(0xFF140505),
    'Natural': backgroundDark,
  };

  static ThemeData getThemeForMood(String mood) {
    final primaryColor = moodColors[mood] ?? primary;
    final bgColor = moodBackgrounds[mood] ?? backgroundDark;

    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: primaryColor,
      scaffoldBackgroundColor:
          Colors.transparent, // Allow global background to show
      canvasColor: bgColor,
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme)
          .copyWith(
            displayLarge: GoogleFonts.spaceGrotesk(
              color: textLight,
              fontWeight: FontWeight.bold,
            ),
            displayMedium: GoogleFonts.spaceGrotesk(
              color: textLight,
              fontWeight: FontWeight.bold,
            ),
            displaySmall: GoogleFonts.spaceGrotesk(
              color: textLight,
              fontWeight: FontWeight.bold,
            ),
            headlineLarge: GoogleFonts.spaceGrotesk(
              color: textLight,
              fontWeight: FontWeight.bold,
            ),
            headlineMedium: GoogleFonts.spaceGrotesk(
              color: textLight,
              fontWeight: FontWeight.bold,
            ),
            titleLarge: GoogleFonts.spaceGrotesk(
              color: textLight,
              fontWeight: FontWeight.bold,
            ),
            bodyLarge: const TextStyle(color: textLight),
            bodyMedium: const TextStyle(color: textMuted),
          ),
      colorScheme: ColorScheme.dark(
        primary: primaryColor,
        surface: cardBg,
        onSurface: textLight,
        onPrimary: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 8,
          shadowColor: primaryColor.withValues(alpha: 0.4),
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
            color: primaryColor.withValues(alpha: 0.5),
            width: 2,
          ),
        ),
        labelStyle: const TextStyle(color: textMuted),
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
      ),
    );
  }

  // Legacy support for static darkTheme
  static ThemeData get darkTheme => getThemeForMood('Natural');
}
