import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// A styled confirmation dialog for destructive actions.
class ConfirmationDialog extends StatelessWidget {
  /// Creates a [ConfirmationDialog].
  const ConfirmationDialog({
    required this.title,
    required this.message,
    this.confirmLabel = 'Delete',
    this.cancelLabel = 'Cancel',
    this.isDestructive = true,
    super.key,
  });

  /// Dialog title.
  final String title;

  /// Dialog message.
  final String message;

  /// Label for the confirm button.
  final String confirmLabel;

  /// Label for the cancel button.
  final String cancelLabel;

  /// Whether the action is destructive (changes button color).
  final bool isDestructive;

  /// Shows the dialog and returns true if confirmed.
  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Delete',
    String cancelLabel = 'Cancel',
    bool isDestructive = true,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        isDestructive: isDestructive,
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(title),
      content: Text(
        message,
        style: theme.textTheme.bodyMedium,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(cancelLabel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: isDestructive
              ? FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.error,
                  foregroundColor: theme.colorScheme.onError,
                )
              : null,
          child: Text(confirmLabel),
        ),
      ],
    );
  }
}
