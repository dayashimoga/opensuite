import 'package:flutter/material.dart';
import 'package:fileutility_core/fileutility_core.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Navigation destination item.
class NavigationItem {
  /// Creates a [NavigationItem].
  const NavigationItem({
    required this.label,
    required this.icon,
    this.selectedIcon,
    this.badge,
  });

  /// Display label.
  final String label;

  /// Default icon.
  final IconData icon;

  /// Icon when selected (falls back to [icon]).
  final IconData? selectedIcon;

  /// Optional badge text.
  final String? badge;
}

/// Desktop/tablet sidebar navigation component.
///
/// Provides a vertically-oriented navigation with labels,
/// optional compact mode, and smooth transitions.
class SidebarNavigation extends StatelessWidget {
  /// Creates a [SidebarNavigation].
  const SidebarNavigation({
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.compact = false,
    this.header,
    this.footer,
    super.key,
  });

  /// Navigation destinations.
  final List<NavigationItem> destinations;

  /// Currently selected index.
  final int selectedIndex;

  /// Selection callback.
  final ValueChanged<int> onDestinationSelected;

  /// Whether to show compact mode (icons only).
  final bool compact;

  /// Optional header widget (shown above nav items).
  final Widget? header;

  /// Optional footer widget (shown below nav items).
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final width = compact
        ? AppConstants.sidebarCollapsedWidth
        : AppConstants.sidebarWidth;

    return AnimatedContainer(
      duration: const Duration(milliseconds: AppConstants.animationDurationMs),
      width: width,
      color: theme.colorScheme.surface,
      child: Column(
        children: [
          // Header / Brand
          _buildHeader(context, isDark),

          const SizedBox(height: AppSpacing.sm),

          // Nav items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              itemCount: destinations.length,
              itemBuilder: (context, index) {
                return _buildNavItem(
                  context,
                  destinations[index],
                  isSelected: index == selectedIndex,
                  onTap: () => onDestinationSelected(index),
                );
              },
            ),
          ),

          // Footer
          if (footer != null) footer!,
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    final theme = Theme.of(context);

    if (header != null) return header!;

    return Padding(
      padding: EdgeInsets.all(compact ? AppSpacing.md : AppSpacing.lg),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: const Icon(
              Icons.folder_special_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          if (!compact) ...[
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppConstants.appName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'v${AppConstants.appVersion}',
                    style: theme.textTheme.labelSmall,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    NavigationItem item, {
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final color = isSelected
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurface.withValues(alpha: 0.7);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: isSelected
            ? theme.colorScheme.primary.withValues(alpha: 0.12)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? AppSpacing.md : AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: [
                Icon(
                  isSelected ? (item.selectedIcon ?? item.icon) : item.icon,
                  color: color,
                  size: 22,
                ),
                if (!compact) ...[
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      item.label,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: color,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w400,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (item.badge != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xxs,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusFull),
                      ),
                      child: Text(
                        item.badge!,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
