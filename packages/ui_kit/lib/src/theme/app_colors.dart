import 'package:flutter/material.dart';

/// Application color palette.
///
/// Provides a curated, harmonious color system using HSL-derived
/// colors for both light and dark themes. Avoids generic primary colors
/// in favor of a sophisticated, modern palette.
class AppColors {
  AppColors._();

  // ── Brand Colors ──────────────────────────────────────────
  /// Primary brand color — deep indigo-blue.
  static const Color primary = Color(0xFF4F46E5);

  /// Primary variant — lighter shade.
  static const Color primaryLight = Color(0xFF818CF8);

  /// Primary variant — darker shade.
  static const Color primaryDark = Color(0xFF3730A3);

  /// Secondary accent — warm amber.
  static const Color secondary = Color(0xFFF59E0B);

  /// Secondary variant — lighter shade.
  static const Color secondaryLight = Color(0xFFFBBF24);

  /// Tertiary accent — teal.
  static const Color tertiary = Color(0xFF14B8A6);

  // ── Semantic Colors ───────────────────────────────────────
  /// Success / positive state.
  static const Color success = Color(0xFF22C55E);

  /// Warning / attention needed.
  static const Color warning = Color(0xFFF59E0B);

  /// Error / destructive state.
  static const Color error = Color(0xFFEF4444);

  /// Info / informational state.
  static const Color info = Color(0xFF3B82F6);

  // ── Light Theme Colors ────────────────────────────────────
  /// Light background.
  static const Color lightBackground = Color(0xFFF8FAFC);

  /// Light surface.
  static const Color lightSurface = Color(0xFFFFFFFF);

  /// Light surface variant (cards, panels).
  static const Color lightSurfaceVariant = Color(0xFFF1F5F9);

  /// Light on-background text.
  static const Color lightOnBackground = Color(0xFF0F172A);

  /// Light on-surface text.
  static const Color lightOnSurface = Color(0xFF1E293B);

  /// Light secondary text.
  static const Color lightOnSurfaceVariant = Color(0xFF64748B);

  /// Light outline / borders.
  static const Color lightOutline = Color(0xFFCBD5E1);

  /// Light divider.
  static const Color lightDivider = Color(0xFFE2E8F0);

  // ── Dark Theme Colors ─────────────────────────────────────
  /// Dark background.
  static const Color darkBackground = Color(0xFF0F172A);

  /// Dark surface.
  static const Color darkSurface = Color(0xFF1E293B);

  /// Dark surface variant (cards, panels).
  static const Color darkSurfaceVariant = Color(0xFF334155);

  /// Dark on-background text.
  static const Color darkOnBackground = Color(0xFFF1F5F9);

  /// Dark on-surface text.
  static const Color darkOnSurface = Color(0xFFE2E8F0);

  /// Dark secondary text.
  static const Color darkOnSurfaceVariant = Color(0xFF94A3B8);

  /// Dark outline / borders.
  static const Color darkOutline = Color(0xFF475569);

  /// Dark divider.
  static const Color darkDivider = Color(0xFF334155);

  // ── Note Colors ───────────────────────────────────────────
  /// Predefined note card colors.
  static const List<Color> noteColors = [
    Color(0xFFFFEBEE), // rose
    Color(0xFFFFF3E0), // amber
    Color(0xFFFFFDE7), // yellow
    Color(0xFFE8F5E9), // green
    Color(0xFFE3F2FD), // blue
    Color(0xFFF3E5F5), // purple
    Color(0xFFECEFF1), // grey
    Color(0xFFE0F2F1), // teal
  ];

  /// Dark mode note card colors.
  static const List<Color> noteColorsDark = [
    Color(0xFF3B1C22), // rose
    Color(0xFF3B2E1A), // amber
    Color(0xFF3B3A17), // yellow
    Color(0xFF1A3B1E), // green
    Color(0xFF1A2A3B), // blue
    Color(0xFF2E1A3B), // purple
    Color(0xFF2A2E31), // grey
    Color(0xFF1A3B37), // teal
  ];

  // ── High Contrast Colors ──────────────────────────────────
  // WCAG AAA (7:1 contrast ratio) compliant palette

  /// High contrast background — pure white.
  static const Color hcBackground = Color(0xFFFFFFFF);

  /// High contrast surface.
  static const Color hcSurface = Color(0xFFF5F5F5);

  /// High contrast primary — deep blue.
  static const Color hcPrimary = Color(0xFF0000CC);

  /// High contrast on-surface — pure black.
  static const Color hcOnSurface = Color(0xFF000000);

  /// High contrast outline — solid black.
  static const Color hcOutline = Color(0xFF333333);

  /// High contrast error — dark red.
  static const Color hcError = Color(0xFFCC0000);

  /// High contrast success — dark green.
  static const Color hcSuccess = Color(0xFF006600);

  /// High contrast warning — dark orange.
  static const Color hcWarning = Color(0xFFCC6600);

  /// Dark high contrast background — pure black.
  static const Color hcDarkBackground = Color(0xFF000000);

  /// Dark high contrast surface.
  static const Color hcDarkSurface = Color(0xFF1A1A1A);

  /// Dark high contrast on-surface — pure white.
  static const Color hcDarkOnSurface = Color(0xFFFFFFFF);

  /// Dark high contrast primary — bright blue.
  static const Color hcDarkPrimary = Color(0xFF6699FF);

  /// Dark high contrast outline.
  static const Color hcDarkOutline = Color(0xFFCCCCCC);
}
