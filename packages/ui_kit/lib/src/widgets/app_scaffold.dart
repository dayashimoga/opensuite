import 'package:flutter/material.dart';

import '../responsive/responsive_builder.dart';
import '../responsive/screen_size.dart';
import '../theme/app_spacing.dart';
import 'sidebar_navigation.dart';

/// Main application scaffold providing responsive navigation.
///
/// On desktop: shows a sidebar with a navigation rail.
/// On tablet: shows a collapsible sidebar.
/// On mobile: shows a bottom navigation bar.
class AppScaffold extends StatelessWidget {
  /// Creates an [AppScaffold].
  const AppScaffold({
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.body,
    this.floatingActionButton,
    this.appBar,
    super.key,
  });

  /// Navigation destinations.
  final List<NavigationItem> destinations;

  /// Currently selected destination index.
  final int selectedIndex;

  /// Called when a destination is selected.
  final ValueChanged<int> onDestinationSelected;

  /// The main content area.
  final Widget body;

  /// Optional floating action button.
  final Widget? floatingActionButton;

  /// Optional app bar (used only on mobile).
  final PreferredSizeWidget? appBar;

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      mobile: (context, size) => _buildMobileLayout(context),
      tablet: (context, size) => _buildDesktopLayout(context, compact: true),
      desktop: (context, size) => _buildDesktopLayout(context, compact: false),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      body: body,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: onDestinationSelected,
        destinations: destinations
            .map(
              (d) => NavigationDestination(
                icon: Icon(d.icon),
                selectedIcon: Icon(d.selectedIcon ?? d.icon),
                label: d.label,
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context, {required bool compact}) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          SidebarNavigation(
            destinations: destinations,
            selectedIndex: selectedIndex,
            onDestinationSelected: onDestinationSelected,
            compact: compact,
          ),

          // Divider
          VerticalDivider(
            width: 1,
            thickness: 1,
            color: theme.dividerColor,
          ),

          // Content
          Expanded(
            child: Column(
              children: [
                if (appBar != null) appBar!,
                Expanded(child: body),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: floatingActionButton,
    );
  }
}
