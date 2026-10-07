import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Primary Palette
  static const Color primary = Color(0xFF4F46E5); // Indigo
  static const Color primaryDark = Color(0xFF3730A3);
  static const Color primaryLight = Color(0xFF818CF8);

  // Status Colors (Attendance Statuses)
  static const Color present = Color(0xFF10B981); // Emerald Green
  static const Color presentLight = Color(0xFFD1FAE5);
  static const Color late = Color(0xFFF59E0B); // Amber
  static const Color lateLight = Color(0xFFFEF3C7);
  static const Color absent = Color(0xFFEF4444); // Crimson Rose
  static const Color absentLight = Color(0xFFFEE2E2);

  // Neutral Palette
  static const Color surface = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFF8FAFC);
  static const Color cardBorder = Color(0xFFE2E8F0);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);

  // Tutor Mobile Design Custom Palette
  static const Color tutorPrimary = Color(0xFF0050CB);
  static const Color tutorPrimaryContainer = Color(0xFF1D68F5);
  static const Color tutorSecondary = Color(0xFF006C49);
  static const Color tutorSecondaryContainer = Color(0xFF6CF8BB);
  static const Color tutorSurface = Color(0xFFF8F9FF);
  static const Color tutorSurfaceContainer = Color(0xFFE5EEFF);
  static const Color tutorSurfaceHigh = Color(0xFFDCE9FF);
  static const Color tutorOnSurface = Color(0xFF0B1C30);
  static const Color tutorOnSurfaceVariant = Color(0xFF424655);
  static const Color tutorError = Color(0xFFBA1A1A);
  static const Color tutorErrorContainer = Color(0xFFFFDAD6);
  static const Color tutorWarningBg = Color(0xFFFEF3C7);
  static const Color tutorWarningText = Color(0xFF92400E);
  static const Color tutorSuccessBg = Color(0xFFD1FAE5);
  static const Color tutorSuccessText = Color(0xFF065F46);

  // Dark Palette
  static const Color darkBackground = Color(0xFF0F172A);
  static const Color darkSurface = Color(0xFF1E293B);
  static const Color darkBorder = Color(0xFF334155);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: const Color(0xFF06B6D4),
        surface: surface,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: background,
      textTheme: GoogleFonts.interTextTheme(),
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: textPrimary),
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: cardBorder, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
      ),
    );
  }
}
