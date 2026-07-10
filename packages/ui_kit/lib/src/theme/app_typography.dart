import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Application typography system.
///
/// Uses Inter as the primary font family for clean, modern readability
/// across all platforms. Provides a complete type scale from display
/// to label sizes.
class AppTypography {
  AppTypography._();

  /// Creates the complete text theme for the application.
  static TextTheme textTheme({required bool isDark}) {
    final baseColor = isDark
        ? const Color(0xFFE2E8F0)
        : const Color(0xFF1E293B);

    return GoogleFonts.interTextTheme(
      TextTheme(
        // Display
        displayLarge: TextStyle(
          fontSize: 57,
          fontWeight: FontWeight.w400,
          letterSpacing: -0.25,
          color: baseColor,
          height: 1.12,
        ),
        displayMedium: TextStyle(
          fontSize: 45,
          fontWeight: FontWeight.w400,
          color: baseColor,
          height: 1.16,
        ),
        displaySmall: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.w400,
          color: baseColor,
          height: 1.22,
        ),

        // Headline
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w600,
          color: baseColor,
          height: 1.25,
        ),
        headlineMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: baseColor,
          height: 1.29,
        ),
        headlineSmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: baseColor,
          height: 1.33,
        ),

        // Title
        titleLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: baseColor,
          height: 1.27,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.15,
          color: baseColor,
          height: 1.50,
        ),
        titleSmall: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
          color: baseColor,
          height: 1.43,
        ),

        // Body
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.5,
          color: baseColor,
          height: 1.50,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.25,
          color: baseColor,
          height: 1.43,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.4,
          color: baseColor.withValues(alpha: 0.7),
          height: 1.33,
        ),

        // Label
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
          color: baseColor,
          height: 1.43,
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
          color: baseColor,
          height: 1.33,
        ),
        labelSmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
          color: baseColor.withValues(alpha: 0.7),
          height: 1.45,
        ),
      ),
    );
  }

  /// Monospace text style for code blocks and editors.
  static TextStyle monoStyle({
    double fontSize = 14,
    Color? color,
    FontWeight fontWeight = FontWeight.w400,
  }) {
    return GoogleFonts.jetBrainsMono(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: 1.6,
    );
  }
}
