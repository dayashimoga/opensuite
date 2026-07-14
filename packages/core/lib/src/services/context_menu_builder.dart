import 'package:flutter/material.dart';

/// Represents a single context menu item.
class ContextMenuItem {
  /// Unique identifier for this item.
  final String id;

  /// Display label.
  final String label;

  /// Leading icon.
  final IconData? icon;

  /// Callback when the item is tapped.
  final VoidCallback? onTap;

  /// Whether the item is enabled.
  final bool enabled;

  /// Whether this is a destructive action (shown in red).
  final bool isDestructive;

  /// Keyboard shortcut text to display (e.g., 'Ctrl+C').
  final String? shortcut;

  /// Sub-items for nested menus.
  final List<ContextMenuItem>? children;

  /// Whether this is a divider (separator line).
  final bool isDivider;

  const ContextMenuItem({
    required this.id,
    required this.label,
    this.icon,
    this.onTap,
    this.enabled = true,
    this.isDestructive = false,
    this.shortcut,
    this.children,
    this.isDivider = false,
  });

  /// Creates a divider item.
  const ContextMenuItem.divider()
      : id = '_divider',
        label = '',
        icon = null,
        onTap = null,
        enabled = false,
        isDestructive = false,
        shortcut = null,
        children = null,
        isDivider = true;
}

/// Builds and shows a context menu at a given position.
///
/// Provides a consistent context menu experience across all editors
/// with support for nested menus, keyboard shortcuts, and destructive actions.
class ContextMenuBuilder {
  ContextMenuBuilder._();

  /// Shows a context menu at [position] with the given [items].
  ///
  /// Returns the ID of the selected item, or null if dismissed.
  static Future<String?> show(
    BuildContext context, {
    required Offset position,
    required List<ContextMenuItem> items,
    double maxWidth = 240,
  }) async {
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;

    return showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromPoints(position, position),
        Offset.zero & overlay.size,
      ),
      constraints: BoxConstraints(maxWidth: maxWidth),
      items: items.map((item) => _buildMenuItem(context, item)).toList(),
    );
  }

  static PopupMenuEntry<String> _buildMenuItem(
      BuildContext context, ContextMenuItem item) {
    if (item.isDivider) {
      return const PopupMenuDivider();
    }

    if (item.children != null && item.children!.isNotEmpty) {
      // Nested submenu — show as expandable item
      return PopupMenuItem<String>(
        enabled: item.enabled,
        value: item.id,
        child: _buildItemContent(context, item, hasSubmenu: true),
      );
    }

    return PopupMenuItem<String>(
      enabled: item.enabled,
      value: item.id,
      onTap: item.onTap,
      child: _buildItemContent(context, item),
    );
  }

  static Widget _buildItemContent(
    BuildContext context,
    ContextMenuItem item, {
    bool hasSubmenu = false,
  }) {
    final theme = Theme.of(context);
    final color = item.isDestructive
        ? theme.colorScheme.error
        : item.enabled
            ? theme.colorScheme.onSurface
            : theme.colorScheme.onSurface.withValues(alpha: 0.38);

    return Row(
      children: [
        if (item.icon != null) ...[
          Icon(item.icon, size: 20, color: color),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Text(
            item.label,
            style: theme.textTheme.bodyMedium?.copyWith(color: color),
          ),
        ),
        if (item.shortcut != null) ...[
          const SizedBox(width: 16),
          Text(
            item.shortcut!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        if (hasSubmenu) ...[
          const SizedBox(width: 8),
          Icon(
            Icons.arrow_right,
            size: 16,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ],
      ],
    );
  }

  /// Common context menu for text editing operations.
  static List<ContextMenuItem> textEditingItems({
    VoidCallback? onCut,
    VoidCallback? onCopy,
    VoidCallback? onPaste,
    VoidCallback? onSelectAll,
    VoidCallback? onUndo,
    VoidCallback? onRedo,
    bool canUndo = false,
    bool canRedo = false,
    bool hasSelection = false,
  }) {
    return [
      ContextMenuItem(
        id: 'undo',
        label: 'Undo',
        icon: Icons.undo,
        shortcut: 'Ctrl+Z',
        onTap: onUndo,
        enabled: canUndo,
      ),
      ContextMenuItem(
        id: 'redo',
        label: 'Redo',
        icon: Icons.redo,
        shortcut: 'Ctrl+Y',
        onTap: onRedo,
        enabled: canRedo,
      ),
      const ContextMenuItem.divider(),
      ContextMenuItem(
        id: 'cut',
        label: 'Cut',
        icon: Icons.content_cut,
        shortcut: 'Ctrl+X',
        onTap: onCut,
        enabled: hasSelection,
      ),
      ContextMenuItem(
        id: 'copy',
        label: 'Copy',
        icon: Icons.content_copy,
        shortcut: 'Ctrl+C',
        onTap: onCopy,
        enabled: hasSelection,
      ),
      ContextMenuItem(
        id: 'paste',
        label: 'Paste',
        icon: Icons.content_paste,
        shortcut: 'Ctrl+V',
        onTap: onPaste,
      ),
      const ContextMenuItem.divider(),
      ContextMenuItem(
        id: 'select_all',
        label: 'Select All',
        icon: Icons.select_all,
        shortcut: 'Ctrl+A',
        onTap: onSelectAll,
      ),
    ];
  }

  /// Common context menu for file operations.
  static List<ContextMenuItem> fileOperationItems({
    VoidCallback? onOpen,
    VoidCallback? onRename,
    VoidCallback? onDuplicate,
    VoidCallback? onFavorite,
    VoidCallback? onDelete,
    bool isFavorite = false,
  }) {
    return [
      ContextMenuItem(
        id: 'open',
        label: 'Open',
        icon: Icons.open_in_new,
        onTap: onOpen,
      ),
      const ContextMenuItem.divider(),
      ContextMenuItem(
        id: 'rename',
        label: 'Rename',
        icon: Icons.edit,
        onTap: onRename,
      ),
      ContextMenuItem(
        id: 'duplicate',
        label: 'Duplicate',
        icon: Icons.copy,
        onTap: onDuplicate,
      ),
      ContextMenuItem(
        id: 'favorite',
        label: isFavorite ? 'Remove from Favorites' : 'Add to Favorites',
        icon: isFavorite ? Icons.star : Icons.star_border,
        onTap: onFavorite,
      ),
      const ContextMenuItem.divider(),
      ContextMenuItem(
        id: 'delete',
        label: 'Delete',
        icon: Icons.delete_outline,
        onTap: onDelete,
        isDestructive: true,
      ),
    ];
  }
}
