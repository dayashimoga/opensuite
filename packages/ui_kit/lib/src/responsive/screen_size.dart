/// Screen size classifications for responsive layouts.
enum ScreenSize {
  /// Mobile phones (< 600px).
  mobile,

  /// Tablets (600px - 1023px).
  tablet,

  /// Desktop/Laptop (>= 1024px).
  desktop,
}

/// Extension methods for [ScreenSize].
extension ScreenSizeExtension on ScreenSize {
  /// Whether the screen is mobile.
  bool get isMobile => this == ScreenSize.mobile;

  /// Whether the screen is tablet.
  bool get isTablet => this == ScreenSize.tablet;

  /// Whether the screen is desktop.
  bool get isDesktop => this == ScreenSize.desktop;

  /// Whether the screen is at least tablet size.
  bool get isTabletOrLarger =>
      this == ScreenSize.tablet || this == ScreenSize.desktop;

  /// Whether the screen is at most tablet size.
  bool get isTabletOrSmaller =>
      this == ScreenSize.mobile || this == ScreenSize.tablet;
}

/// Determines the [ScreenSize] from a width value.
ScreenSize screenSizeFromWidth(double width) {
  if (width >= 1024) return ScreenSize.desktop;
  if (width >= 600) return ScreenSize.tablet;
  return ScreenSize.mobile;
}
