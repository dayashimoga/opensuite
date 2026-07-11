import 'package:fileutility_ui_kit/fileutility_ui_kit.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'app_router.dart';

/// Shell page providing the main navigation scaffold.
///
/// On desktop/tablet: shows a full sidebar with all navigation items.
/// On mobile: shows a condensed 5-item bottom navigation bar.
class ShellPage extends StatelessWidget {
  /// Creates a [ShellPage].
  const ShellPage({required this.child, super.key});

  /// The child route page to display.
  final Widget child;

  /// Full navigation destinations (used on desktop sidebar).
  static const List<NavigationItem> _allDestinations = [
    NavigationItem(
      label: 'Home',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
    ),
    NavigationItem(
      label: 'Notes',
      icon: Icons.note_alt_outlined,
      selectedIcon: Icons.note_alt_rounded,
    ),
    NavigationItem(
      label: 'Documents',
      icon: Icons.description_outlined,
      selectedIcon: Icons.description_rounded,
    ),
    NavigationItem(
      label: 'Sheets',
      icon: Icons.grid_on_outlined,
      selectedIcon: Icons.grid_on_rounded,
    ),
    NavigationItem(
      label: 'Slides',
      icon: Icons.slideshow_outlined,
      selectedIcon: Icons.slideshow_rounded,
    ),
    NavigationItem(
      label: 'PDF',
      icon: Icons.picture_as_pdf_outlined,
      selectedIcon: Icons.picture_as_pdf_rounded,
    ),
    NavigationItem(
      label: 'Images',
      icon: Icons.image_outlined,
      selectedIcon: Icons.image_rounded,
    ),
    NavigationItem(
      label: 'Files',
      icon: Icons.folder_outlined,
      selectedIcon: Icons.folder_rounded,
    ),
    NavigationItem(
      label: 'Editor',
      icon: Icons.edit_document,
      selectedIcon: Icons.edit_document,
    ),
    NavigationItem(
      label: 'Settings',
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings_rounded,
    ),
  ];

  /// Mobile-only condensed destinations (max 5 for Material 3).
  static const List<NavigationItem> _mobileDestinations = [
    NavigationItem(
      label: 'Home',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
    ),
    NavigationItem(
      label: 'Notes',
      icon: Icons.note_alt_outlined,
      selectedIcon: Icons.note_alt_rounded,
    ),
    NavigationItem(
      label: 'Docs',
      icon: Icons.description_outlined,
      selectedIcon: Icons.description_rounded,
    ),
    NavigationItem(
      label: 'Tools',
      icon: Icons.build_outlined,
      selectedIcon: Icons.build_rounded,
    ),
    NavigationItem(
      label: 'Settings',
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings_rounded,
    ),
  ];

  /// Maps route paths to desktop navigation indices (0-9).
  static int _calculateDesktopIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith(AppRouter.notes)) return 1;
    if (location.startsWith(AppRouter.documents)) return 2;
    if (location.startsWith(AppRouter.spreadsheets)) return 3;
    if (location.startsWith(AppRouter.presentations)) return 4;
    if (location.startsWith(AppRouter.pdfViewer)) return 5;
    if (location.startsWith(AppRouter.imageEditor)) return 6;
    if (location.startsWith(AppRouter.files)) return 7;
    if (location.startsWith(AppRouter.editor)) return 8;
    if (location.startsWith(AppRouter.settings)) return 9;
    return 0; // home
  }

  /// Maps route paths to mobile navigation indices (0-4).
  static int _calculateMobileIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith(AppRouter.notes)) return 1;
    // Documents hub: documents, spreadsheets, presentations
    if (location.startsWith(AppRouter.documents) ||
        location.startsWith(AppRouter.spreadsheets) ||
        location.startsWith(AppRouter.presentations)) {
      return 2;
    }
    // Tools hub: PDF, Images, Files, Editor
    if (location.startsWith(AppRouter.pdfViewer) ||
        location.startsWith(AppRouter.imageEditor) ||
        location.startsWith(AppRouter.files) ||
        location.startsWith(AppRouter.editor)) {
      return 3;
    }
    if (location.startsWith(AppRouter.settings)) return 4;
    return 0; // home
  }

  void _onDesktopDestinationSelected(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(AppRouter.home);
      case 1:
        context.go(AppRouter.notes);
      case 2:
        context.go(AppRouter.documents);
      case 3:
        context.go(AppRouter.spreadsheets);
      case 4:
        context.go(AppRouter.presentations);
      case 5:
        context.go(AppRouter.pdfViewer);
      case 6:
        context.go(AppRouter.imageEditor);
      case 7:
        context.go(AppRouter.files);
      case 8:
        context.go(AppRouter.editor);
      case 9:
        context.go(AppRouter.settings);
    }
  }

  void _onMobileDestinationSelected(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(AppRouter.home);
      case 1:
        context.go(AppRouter.notes);
      case 2:
        // Documents hub — go to documents list
        context.go(AppRouter.documents);
      case 3:
        // Tools hub — go to files as default entry
        context.go(AppRouter.files);
      case 4:
        context.go(AppRouter.settings);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = ResponsiveBuilder.of(context);
    final isMobile = screenSize == ScreenSize.mobile;

    if (isMobile) {
      return _buildMobileLayout(context);
    }
    return _buildDesktopLayout(context,
        compact: screenSize == ScreenSize.tablet);
  }

  Widget _buildMobileLayout(BuildContext context) {
    final selectedIndex = _calculateMobileIndex(context);

    return AppScaffold(
      destinations: _mobileDestinations,
      selectedIndex: selectedIndex,
      onDestinationSelected: (index) =>
          _onMobileDestinationSelected(context, index),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        child: KeyedSubtree(
          key: ValueKey(selectedIndex),
          child: child,
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context, {required bool compact}) {
    final selectedIndex = _calculateDesktopIndex(context);

    return AppScaffold(
      destinations: _allDestinations,
      selectedIndex: selectedIndex,
      onDestinationSelected: (index) =>
          _onDesktopDestinationSelected(context, index),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        child: KeyedSubtree(
          key: ValueKey(selectedIndex),
          child: child,
        ),
      ),
    );
  }
}
