import 'package:flutter/material.dart';

/// A reusable context menu widget that works cross-platform.
///
/// On desktop: triggered by right-click.
/// On mobile: triggered by long-press.
///
/// Usage:
/// ```dart
/// ContextMenuRegion(
///   menuItems: [
///     ContextMenuItem(
///       icon: Icons.copy,
///       label: 'Copy',
///       shortcut: 'Ctrl+C',
///       onTap: () => handleCopy(),
///     ),
///     const ContextMenuDivider(),
///     ContextMenuItem(
///       icon: Icons.delete,
///       label: 'Delete',
///       isDestructive: true,
///       onTap: () => handleDelete(),
///     ),
///   ],
///   child: MyWidget(),
/// )
/// ```
class ContextMenuRegion extends StatelessWidget {
  /// The child widget that the context menu is attached to.
  final Widget child;

  /// The menu items to display.
  final List<ContextMenuEntry> menuItems;

  /// Optional callback when the menu is opened.
  final VoidCallback? onMenuOpened;

  const ContextMenuRegion({
    super.key,
    required this.child,
    required this.menuItems,
    this.onMenuOpened,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onSecondaryTapDown: (details) {
        _showContextMenu(context, details.globalPosition);
      },
      onLongPressStart: (details) {
        _showContextMenu(context, details.globalPosition);
      },
      child: child,
    );
  }

  void _showContextMenu(BuildContext context, Offset position) {
    onMenuOpened?.call();

    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final theme = Theme.of(context);

    showMenu<void>(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromLTWH(position.dx, position.dy, 0, 0),
        Offset.zero & overlay.size,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: 8,
      color: theme.colorScheme.surfaceContainer,
      items: menuItems.map((entry) {
        if (entry is ContextMenuDivider) {
          return PopupMenuItem<void>(
            enabled: false,
            height: 9,
            padding: EdgeInsets.zero,
            child: Divider(
              height: 1,
              color: theme.colorScheme.outlineVariant,
            ),
          );
        }

        final item = entry as ContextMenuItem;
        return PopupMenuItem<void>(
          enabled: item.enabled,
          height: 36,
          onTap: item.onTap,
          child: Row(
            children: [
              if (item.icon != null) ...[
                Icon(
                  item.icon,
                  size: 18,
                  color: item.isDestructive
                      ? theme.colorScheme.error
                      : item.enabled
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.onSurface.withValues(alpha: 0.38),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Text(
                  item.label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: item.isDestructive
                        ? theme.colorScheme.error
                        : item.enabled
                            ? null
                            : theme.colorScheme.onSurface
                                .withValues(alpha: 0.38),
                  ),
                ),
              ),
              if (item.shortcut != null) ...[
                const SizedBox(width: 24),
                Text(
                  item.shortcut!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color:
                        theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }
}

/// Base class for context menu entries.
sealed class ContextMenuEntry {
  const ContextMenuEntry();
}

/// A clickable context menu item.
class ContextMenuItem extends ContextMenuEntry {
  /// The item label.
  final String label;

  /// Optional leading icon.
  final IconData? icon;

  /// Optional keyboard shortcut label.
  final String? shortcut;

  /// Callback when the item is tapped.
  final VoidCallback? onTap;

  /// Whether this item is enabled.
  final bool enabled;

  /// Whether this is a destructive action (shown in red).
  final bool isDestructive;

  const ContextMenuItem({
    required this.label,
    this.icon,
    this.shortcut,
    this.onTap,
    this.enabled = true,
    this.isDestructive = false,
  });
}

/// A divider line between context menu items.
class ContextMenuDivider extends ContextMenuEntry {
  const ContextMenuDivider();
}
