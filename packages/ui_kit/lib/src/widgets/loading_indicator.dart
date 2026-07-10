import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// A styled loading indicator with optional message.
class AppLoadingIndicator extends StatelessWidget {
  /// Creates an [AppLoadingIndicator].
  const AppLoadingIndicator({
    this.message,
    this.size = 36,
    super.key,
  });

  /// Optional message displayed below the indicator.
  final String? message;

  /// Size of the circular indicator.
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(
                theme.colorScheme.primary,
              ),
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
