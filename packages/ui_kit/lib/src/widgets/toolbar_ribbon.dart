import 'package:flutter/material.dart';

/// A tabbed ribbon toolbar for office productivity editors.
///
/// Provides a compact, collapsible ribbon with tab groups similar to
/// Microsoft Office ribbon. Each tab contains groups of related
/// toolbar actions.
///
/// Usage:
/// ```dart
/// ToolbarRibbon(
///   tabs: [
///     RibbonTab(label: 'Home', groups: [
///       RibbonGroup(label: 'Font', children: [...]),
///       RibbonGroup(label: 'Alignment', children: [...]),
///     ]),
///     RibbonTab(label: 'Insert', groups: [...]),
///   ],
/// )
/// ```
class ToolbarRibbon extends StatefulWidget {
  /// The ribbon tabs to display.
  final List<RibbonTab> tabs;

  /// Whether the ribbon content is collapsed (only tab headers shown).
  final bool initiallyCollapsed;

  /// Optional fixed height for the ribbon content area.
  final double contentHeight;

  const ToolbarRibbon({
    super.key,
    required this.tabs,
    this.initiallyCollapsed = false,
    this.contentHeight = 72,
  });

  @override
  State<ToolbarRibbon> createState() => _ToolbarRibbonState();
}

class _ToolbarRibbonState extends State<ToolbarRibbon>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late bool _isCollapsed;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: widget.tabs.length,
      vsync: this,
    );
    _isCollapsed = widget.initiallyCollapsed;
  }

  @override
  void didUpdateWidget(ToolbarRibbon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tabs.length != widget.tabs.length) {
      _tabController.dispose();
      _tabController = TabController(
        length: widget.tabs.length,
        vsync: this,
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Tab headers
        Container(
          height: 32,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            border: Border(
              bottom: BorderSide(
                color: theme.colorScheme.outlineVariant,
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  labelPadding:
                      const EdgeInsets.symmetric(horizontal: 16),
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicatorWeight: 2,
                  labelStyle: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  unselectedLabelStyle: theme.textTheme.labelSmall,
                  dividerColor: Colors.transparent,
                  tabs: widget.tabs
                      .map((tab) => Tab(
                            height: 28,
                            text: tab.label,
                          ))
                      .toList(),
                ),
              ),
              // Collapse toggle
              IconButton(
                icon: Icon(
                  _isCollapsed
                      ? Icons.expand_more
                      : Icons.expand_less,
                  size: 16,
                ),
                onPressed: () =>
                    setState(() => _isCollapsed = !_isCollapsed),
                tooltip: _isCollapsed ? 'Expand ribbon' : 'Collapse ribbon',
                padding: const EdgeInsets.all(4),
                constraints:
                    const BoxConstraints(minWidth: 28, minHeight: 28),
              ),
            ],
          ),
        ),
        // Tab content (ribbon groups)
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: _isCollapsed ? 0 : widget.contentHeight,
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: _isCollapsed
                ? null
                : Border(
                    bottom: BorderSide(
                      color: theme.colorScheme.outlineVariant,
                      width: 0.5,
                    ),
                  ),
          ),
          child: TabBarView(
            controller: _tabController,
            physics: const NeverScrollableScrollPhysics(),
            children: widget.tabs.map((tab) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                    horizontal: 4, vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _buildGroupsWithSeparators(theme, tab.groups),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildGroupsWithSeparators(
      ThemeData theme, List<RibbonGroup> groups) {
    final widgets = <Widget>[];
    for (var i = 0; i < groups.length; i++) {
      widgets.add(_buildGroup(theme, groups[i]));
      if (i < groups.length - 1) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: SizedBox(
              height: 56,
              child: VerticalDivider(
                width: 1,
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
          ),
        );
      }
    }
    return widgets;
  }

  Widget _buildGroup(ThemeData theme, RibbonGroup group) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Group content
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: group.children,
            ),
          ),
        ),
        // Group label
        if (group.label.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text(
              group.label,
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 9,
                color: theme.colorScheme.onSurfaceVariant
                    .withValues(alpha: 0.6),
              ),
            ),
          ),
      ],
    );
  }
}

/// A tab in the ribbon toolbar.
class RibbonTab {
  /// The tab header label.
  final String label;

  /// Groups of actions within this tab.
  final List<RibbonGroup> groups;

  const RibbonTab({
    required this.label,
    required this.groups,
  });
}

/// A group of related actions within a ribbon tab.
class RibbonGroup {
  /// The group label shown below the actions.
  final String label;

  /// The action widgets in this group.
  final List<Widget> children;

  const RibbonGroup({
    required this.label,
    required this.children,
  });
}

/// A compact icon button sized for the ribbon toolbar.
class RibbonButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool isActive;
  final double iconSize;

  const RibbonButton({
    super.key,
    required this.icon,
    required this.tooltip,
    this.onPressed,
    this.isActive = false,
    this.iconSize = 20,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isActive
                ? theme.colorScheme.primaryContainer
                : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(
            icon,
            size: iconSize,
            color: isActive
                ? theme.colorScheme.primary
                : onPressed != null
                    ? theme.colorScheme.onSurface
                    : theme.colorScheme.onSurface.withValues(alpha: 0.38),
          ),
        ),
      ),
    );
  }
}

/// A dropdown button sized for the ribbon toolbar.
class RibbonDropdown<T> extends StatelessWidget {
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final double width;

  const RibbonDropdown({
    super.key,
    required this.value,
    required this.items,
    this.onChanged,
    this.width = 100,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: width,
      height: 28,
      child: DropdownButtonFormField<T>(
        value: value,
        items: items,
        onChanged: onChanged,
        isDense: true,
        isExpanded: true,
        decoration: InputDecoration(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: BorderSide(
              color: theme.colorScheme.outlineVariant,
              width: 0.5,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: BorderSide(
              color: theme.colorScheme.outlineVariant,
              width: 0.5,
            ),
          ),
          filled: false,
          isDense: true,
        ),
        style: theme.textTheme.bodySmall,
      ),
    );
  }
}
