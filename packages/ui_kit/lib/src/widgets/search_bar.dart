import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// A styled search bar widget with debounced input.
class AppSearchBar extends StatefulWidget {
  /// Creates an [AppSearchBar].
  const AppSearchBar({
    required this.onChanged,
    this.hintText = 'Search...',
    this.debounceMs = 300,
    this.controller,
    super.key,
  });

  /// Called when the search text changes (after debounce).
  final ValueChanged<String> onChanged;

  /// Placeholder text.
  final String hintText;

  /// Debounce duration in milliseconds.
  final int debounceMs;

  /// Optional external text controller.
  final TextEditingController? controller;

  @override
  State<AppSearchBar> createState() => _AppSearchBarState();
}

class _AppSearchBarState extends State<AppSearchBar> {
  late final TextEditingController _controller;
  bool _isOwned = false;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _controller = widget.controller!;
    } else {
      _controller = TextEditingController();
      _isOwned = true;
    }
  }

  @override
  void dispose() {
    if (_isOwned) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _onClear() {
    _controller.clear();
    widget.onChanged('');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      height: 44,
      child: TextField(
        controller: _controller,
        onChanged: widget.onChanged,
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            size: 20,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
          ),
          suffixIcon: _controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  onPressed: _onClear,
                  tooltip: 'Clear search',
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
          ),
        ),
        style: theme.textTheme.bodyMedium,
        textInputAction: TextInputAction.search,
      ),
    );
  }
}
