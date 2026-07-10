import 'package:flutter/material.dart';

import 'screen_size.dart';

/// A builder widget that provides responsive layout adaptation.
///
/// Automatically determines the current [ScreenSize] and rebuilds
/// with the appropriate layout. Requires a [mobile] builder and
/// optionally accepts [tablet] and [desktop] builders.
///
/// ```dart
/// ResponsiveBuilder(
///   mobile: (context, size) => MobileLayout(),
///   tablet: (context, size) => TabletLayout(),
///   desktop: (context, size) => DesktopLayout(),
/// )
/// ```
class ResponsiveBuilder extends StatelessWidget {
  /// Creates a [ResponsiveBuilder].
  const ResponsiveBuilder({
    required this.mobile,
    this.tablet,
    this.desktop,
    super.key,
  });

  /// Builder for mobile layout (always required as fallback).
  final Widget Function(BuildContext context, ScreenSize screenSize) mobile;

  /// Optional builder for tablet layout.
  final Widget Function(BuildContext context, ScreenSize screenSize)? tablet;

  /// Optional builder for desktop layout.
  final Widget Function(BuildContext context, ScreenSize screenSize)? desktop;

  /// Returns the current [ScreenSize] for the given context.
  static ScreenSize of(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return screenSizeFromWidth(width);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenSize = screenSizeFromWidth(constraints.maxWidth);

        return switch (screenSize) {
          ScreenSize.desktop => (desktop ?? tablet ?? mobile)(
              context,
              screenSize,
            ),
          ScreenSize.tablet => (tablet ?? mobile)(context, screenSize),
          ScreenSize.mobile => mobile(context, screenSize),
        };
      },
    );
  }
}

/// A widget that shows/hides content based on screen size.
class ResponsiveVisibility extends StatelessWidget {
  /// Creates a [ResponsiveVisibility].
  const ResponsiveVisibility({
    required this.child,
    this.visibleOn = const {
      ScreenSize.mobile,
      ScreenSize.tablet,
      ScreenSize.desktop,
    },
    this.replacement,
    super.key,
  });

  /// The child widget to conditionally display.
  final Widget child;

  /// Screen sizes where the child is visible.
  final Set<ScreenSize> visibleOn;

  /// Optional replacement widget when not visible.
  final Widget? replacement;

  @override
  Widget build(BuildContext context) {
    final screenSize = ResponsiveBuilder.of(context);
    if (visibleOn.contains(screenSize)) {
      return child;
    }
    return replacement ?? const SizedBox.shrink();
  }
}
