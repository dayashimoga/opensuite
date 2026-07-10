import 'package:fileutility_ui_kit/fileutility_ui_kit.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'app_router.dart';

/// Shell page providing the main navigation scaffold.
///
/// Wraps all top-level routes with either a sidebar (desktop/tablet)
/// or bottom navigation bar (mobile) using [AppScaffold].
class ShellPage extends StatelessWidget {
  /// Creates a [ShellPage].
  const ShellPage({required this.child, super.key});

  /// The child route page to display.
  final Widget child;

  /// Navigation destinations.
  static const List<NavigationItem> _destinations = [
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

  /// Maps route paths to navigation indices.
  static int _calculateSelectedIndex(BuildContext context) {
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

  void _onDestinationSelected(BuildContext context, int index) {
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

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _calculateSelectedIndex(context);

    return AppScaffold(
      destinations: _destinations,
      selectedIndex: selectedIndex,
      onDestinationSelected: (index) =>
          _onDestinationSelected(context, index),
      body: child,
    );
  }
}
