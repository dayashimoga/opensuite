import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// Application theme configuration.
///
/// Provides light and dark [ThemeData] instances built on Material 3
/// with the application's custom color palette, typography, and
/// component themes.
class AppTheme {
  AppTheme._();

  /// Light theme.
  static ThemeData get light {
    final textTheme = AppTypography.textTheme(isDark: false);
    final colorScheme = ColorScheme.light(
      primary: AppColors.primary,
      primaryContainer: AppColors.primaryLight,
      secondary: AppColors.secondary,
      secondaryContainer: AppColors.secondaryLight,
      tertiary: AppColors.tertiary,
      surface: AppColors.lightSurface,
      error: AppColors.error,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: AppColors.lightOnSurface,
      onError: Colors.white,
      outline: AppColors.lightOutline,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: AppColors.lightBackground,
      dividerColor: AppColors.lightDivider,

      // AppBar
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: AppColors.lightSurface,
        foregroundColor: AppColors.lightOnSurface,
        titleTextStyle: textTheme.titleLarge,
        surfaceTintColor: Colors.transparent,
      ),

      // Card
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          side: BorderSide(color: AppColors.lightOutline.withValues(alpha: 0.5)),
        ),
        color: AppColors.lightSurface,
        surfaceTintColor: Colors.transparent,
      ),

      // Navigation Rail
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: AppColors.lightSurface,
        selectedIconTheme: const IconThemeData(color: AppColors.primary),
        unselectedIconTheme: IconThemeData(
          color: AppColors.lightOnSurfaceVariant,
        ),
        indicatorColor: AppColors.primary.withValues(alpha: 0.12),
      ),

      // Bottom Navigation
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.lightSurface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.lightOnSurfaceVariant,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
      ),

      // FAB
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: CircleBorder(),
      ),

      // Input
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightSurfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
      ),

      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.lightSurfaceVariant,
        selectedColor: AppColors.primary.withValues(alpha: 0.12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        ),
      ),

      // Dialog
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        ),
        backgroundColor: AppColors.lightSurface,
        surfaceTintColor: Colors.transparent,
      ),

      // Snackbar
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: AppColors.lightDivider,
        thickness: 1,
        space: 1,
      ),

      // Tooltip
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.lightOnSurface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
        textStyle: textTheme.bodySmall?.copyWith(color: AppColors.lightSurface),
      ),
    );
  }

  /// Dark theme.
  static ThemeData get dark {
    final textTheme = AppTypography.textTheme(isDark: true);
    final colorScheme = ColorScheme.dark(
      primary: AppColors.primaryLight,
      primaryContainer: AppColors.primaryDark,
      secondary: AppColors.secondaryLight,
      secondaryContainer: AppColors.secondary,
      tertiary: AppColors.tertiary,
      surface: AppColors.darkSurface,
      error: AppColors.error,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: AppColors.darkOnSurface,
      onError: Colors.white,
      outline: AppColors.darkOutline,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: AppColors.darkBackground,
      dividerColor: AppColors.darkDivider,

      // AppBar
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: AppColors.darkSurface,
        foregroundColor: AppColors.darkOnSurface,
        titleTextStyle: textTheme.titleLarge,
        surfaceTintColor: Colors.transparent,
      ),

      // Card
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          side: BorderSide(color: AppColors.darkOutline.withValues(alpha: 0.5)),
        ),
        color: AppColors.darkSurface,
        surfaceTintColor: Colors.transparent,
      ),

      // Navigation Rail
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: AppColors.darkSurface,
        selectedIconTheme: const IconThemeData(color: AppColors.primaryLight),
        unselectedIconTheme: IconThemeData(
          color: AppColors.darkOnSurfaceVariant,
        ),
        indicatorColor: AppColors.primaryLight.withValues(alpha: 0.12),
      ),

      // Bottom Navigation
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.darkSurface,
        selectedItemColor: AppColors.primaryLight,
        unselectedItemColor: AppColors.darkOnSurfaceVariant,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
      ),

      // FAB
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primaryLight,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: CircleBorder(),
      ),

      // Input
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: AppColors.primaryLight, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
      ),

      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.darkSurfaceVariant,
        selectedColor: AppColors.primaryLight.withValues(alpha: 0.12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        ),
      ),

      // Dialog
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        ),
        backgroundColor: AppColors.darkSurface,
        surfaceTintColor: Colors.transparent,
      ),

      // Snackbar
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: AppColors.darkDivider,
        thickness: 1,
        space: 1,
      ),

      // Tooltip
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.darkOnSurface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
        textStyle: textTheme.bodySmall?.copyWith(color: AppColors.darkSurface),
      ),
    );
  }

  /// High contrast light theme — WCAG AAA compliant.
  static ThemeData get highContrastLight {
    final textTheme = AppTypography.textTheme(isDark: false);
    final colorScheme = ColorScheme.light(
      primary: AppColors.hcPrimary,
      primaryContainer: const Color(0xFFCCCCFF),
      secondary: AppColors.hcWarning,
      surface: AppColors.hcSurface,
      error: AppColors.hcError,
      onPrimary: Colors.white,
      onSecondary: Colors.black,
      onSurface: AppColors.hcOnSurface,
      onError: Colors.white,
      outline: AppColors.hcOutline,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      textTheme: _boldifyTextTheme(textTheme),
      scaffoldBackgroundColor: AppColors.hcBackground,
      dividerColor: AppColors.hcOutline,
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 2,
        backgroundColor: AppColors.hcSurface,
        foregroundColor: AppColors.hcOnSurface,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: AppColors.hcOnSurface,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          side: const BorderSide(color: AppColors.hcOutline, width: 2),
        ),
        color: AppColors.hcSurface,
      ),
      navigationRailTheme: NavigationRailThemeData(
        selectedIconTheme: const IconThemeData(color: AppColors.hcPrimary, size: 26),
        unselectedIconTheme: const IconThemeData(color: AppColors.hcOnSurface, size: 24),
        selectedLabelTextStyle: textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: AppColors.hcPrimary,
        ),
        indicatorColor: AppColors.hcPrimary.withValues(alpha: 0.15),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          borderSide: const BorderSide(color: AppColors.hcOutline, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          borderSide: const BorderSide(color: AppColors.hcPrimary, width: 3),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: AppColors.hcPrimary,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
          side: const BorderSide(color: AppColors.hcOutline, width: 2),
        ),
      ),
      focusColor: AppColors.hcPrimary.withValues(alpha: 0.3),
    );
  }

  /// High contrast dark theme — WCAG AAA compliant.
  static ThemeData get highContrastDark {
    final textTheme = AppTypography.textTheme(isDark: true);
    final colorScheme = ColorScheme.dark(
      primary: AppColors.hcDarkPrimary,
      primaryContainer: const Color(0xFF003399),
      secondary: const Color(0xFFFFCC00),
      surface: AppColors.hcDarkSurface,
      error: const Color(0xFFFF6666),
      onPrimary: Colors.black,
      onSecondary: Colors.black,
      onSurface: AppColors.hcDarkOnSurface,
      onError: Colors.black,
      outline: AppColors.hcDarkOutline,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      textTheme: _boldifyTextTheme(textTheme),
      scaffoldBackgroundColor: AppColors.hcDarkBackground,
      dividerColor: AppColors.hcDarkOutline,
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 2,
        backgroundColor: AppColors.hcDarkSurface,
        foregroundColor: AppColors.hcDarkOnSurface,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: AppColors.hcDarkOnSurface,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          side: const BorderSide(color: AppColors.hcDarkOutline, width: 2),
        ),
        color: AppColors.hcDarkSurface,
      ),
      navigationRailTheme: NavigationRailThemeData(
        selectedIconTheme: const IconThemeData(color: AppColors.hcDarkPrimary, size: 26),
        unselectedIconTheme: const IconThemeData(color: AppColors.hcDarkOnSurface, size: 24),
        selectedLabelTextStyle: textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: AppColors.hcDarkPrimary,
        ),
        indicatorColor: AppColors.hcDarkPrimary.withValues(alpha: 0.2),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          borderSide: const BorderSide(color: AppColors.hcDarkOutline, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          borderSide: const BorderSide(color: AppColors.hcDarkPrimary, width: 3),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.black,
          backgroundColor: AppColors.hcDarkPrimary,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
          side: const BorderSide(color: AppColors.hcDarkOutline, width: 2),
        ),
      ),
      focusColor: AppColors.hcDarkPrimary.withValues(alpha: 0.3),
    );
  }

  /// Increases font weight across all text styles for better readability.
  static TextTheme _boldifyTextTheme(TextTheme theme) {
    return theme.copyWith(
      displayLarge: theme.displayLarge?.copyWith(fontWeight: FontWeight.w700),
      displayMedium: theme.displayMedium?.copyWith(fontWeight: FontWeight.w700),
      displaySmall: theme.displaySmall?.copyWith(fontWeight: FontWeight.w700),
      headlineLarge: theme.headlineLarge?.copyWith(fontWeight: FontWeight.w700),
      headlineMedium: theme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
      headlineSmall: theme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
      titleLarge: theme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      titleMedium: theme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      titleSmall: theme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
      bodyLarge: theme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
      bodyMedium: theme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
      bodySmall: theme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
      labelLarge: theme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
      labelMedium: theme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
      labelSmall: theme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
    );
  }
}
