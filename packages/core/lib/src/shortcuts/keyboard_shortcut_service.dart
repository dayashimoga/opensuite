import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Defines a keyboard shortcut with its action.
class KeyboardShortcutAction {
  /// Human-readable label for the shortcut.
  final String label;

  /// The key combination that triggers this action.
  final ShortcutActivator activator;

  /// The callback to execute when the shortcut is triggered.
  final VoidCallback onInvoke;

  /// Optional category for grouping in help dialogs.
  final String category;

  /// Whether this shortcut is currently enabled.
  final bool enabled;

  /// Creates a [KeyboardShortcutAction].
  const KeyboardShortcutAction({
    required this.label,
    required this.activator,
    required this.onInvoke,
    this.category = 'General',
    this.enabled = true,
  });
}

/// Service that manages keyboard shortcuts across the application.
///
/// Provides a centralized registry for keyboard shortcuts with
/// category-based organization and conflict detection.
class KeyboardShortcutService {
  KeyboardShortcutService._();

  static final KeyboardShortcutService _instance = KeyboardShortcutService._();

  /// Singleton instance.
  static KeyboardShortcutService get instance => _instance;

  final Map<String, KeyboardShortcutAction> _shortcuts = {};

  /// Registers a shortcut with a unique [id].
  void register(String id, KeyboardShortcutAction action) {
    _shortcuts[id] = action;
  }

  /// Unregisters a shortcut by [id].
  void unregister(String id) {
    _shortcuts.remove(id);
  }

  /// Returns all registered shortcuts.
  Map<String, KeyboardShortcutAction> get shortcuts =>
      Map.unmodifiable(_shortcuts);

  /// Returns shortcuts filtered by [category].
  List<KeyboardShortcutAction> getByCategory(String category) {
    return _shortcuts.values
        .where((s) => s.category == category && s.enabled)
        .toList();
  }

  /// Returns all unique categories.
  List<String> get categories {
    return _shortcuts.values.map((s) => s.category).toSet().toList()..sort();
  }

  /// Builds a [Map] of [ShortcutActivator] → [Intent] for use with
  /// Flutter's [Shortcuts] widget.
  Map<ShortcutActivator, Intent> buildShortcutMap() {
    final map = <ShortcutActivator, Intent>{};
    for (final action in _shortcuts.values) {
      if (action.enabled) {
        map[action.activator] = _CallbackIntent(action.onInvoke);
      }
    }
    return map;
  }

  /// Builds a [Map] of [Type] → [Action] for use with Flutter's
  /// [Actions] widget.
  Map<Type, Action<Intent>> buildActionMap() {
    return {
      _CallbackIntent: CallbackAction<_CallbackIntent>(
        onInvoke: (intent) {
          intent.callback();
          return null;
        },
      ),
    };
  }

  /// Clears all registered shortcuts.
  void clear() {
    _shortcuts.clear();
  }

  /// Pre-registers common editor shortcuts.
  void registerEditorDefaults({
    VoidCallback? onSave,
    VoidCallback? onNew,
    VoidCallback? onOpen,
    VoidCallback? onBold,
    VoidCallback? onItalic,
    VoidCallback? onUnderline,
    VoidCallback? onUndo,
    VoidCallback? onRedo,
    VoidCallback? onFind,
    VoidCallback? onFindReplace,
    VoidCallback? onPrint,
  }) {
    if (onSave != null) {
      register(
          'editor.save',
          KeyboardShortcutAction(
            label: 'Save',
            activator:
                const SingleActivator(LogicalKeyboardKey.keyS, control: true),
            onInvoke: onSave,
            category: 'File',
          ));
    }
    if (onNew != null) {
      register(
          'editor.new',
          KeyboardShortcutAction(
            label: 'New Document',
            activator:
                const SingleActivator(LogicalKeyboardKey.keyN, control: true),
            onInvoke: onNew,
            category: 'File',
          ));
    }
    if (onOpen != null) {
      register(
          'editor.open',
          KeyboardShortcutAction(
            label: 'Open',
            activator:
                const SingleActivator(LogicalKeyboardKey.keyO, control: true),
            onInvoke: onOpen,
            category: 'File',
          ));
    }
    if (onBold != null) {
      register(
          'editor.bold',
          KeyboardShortcutAction(
            label: 'Bold',
            activator:
                const SingleActivator(LogicalKeyboardKey.keyB, control: true),
            onInvoke: onBold,
            category: 'Format',
          ));
    }
    if (onItalic != null) {
      register(
          'editor.italic',
          KeyboardShortcutAction(
            label: 'Italic',
            activator:
                const SingleActivator(LogicalKeyboardKey.keyI, control: true),
            onInvoke: onItalic,
            category: 'Format',
          ));
    }
    if (onUnderline != null) {
      register(
          'editor.underline',
          KeyboardShortcutAction(
            label: 'Underline',
            activator:
                const SingleActivator(LogicalKeyboardKey.keyU, control: true),
            onInvoke: onUnderline,
            category: 'Format',
          ));
    }
    if (onUndo != null) {
      register(
          'editor.undo',
          KeyboardShortcutAction(
            label: 'Undo',
            activator:
                const SingleActivator(LogicalKeyboardKey.keyZ, control: true),
            onInvoke: onUndo,
            category: 'Edit',
          ));
    }
    if (onRedo != null) {
      register(
          'editor.redo',
          KeyboardShortcutAction(
            label: 'Redo',
            activator: const SingleActivator(LogicalKeyboardKey.keyZ,
                control: true, shift: true),
            onInvoke: onRedo,
            category: 'Edit',
          ));
    }
    if (onFind != null) {
      register(
          'editor.find',
          KeyboardShortcutAction(
            label: 'Find',
            activator:
                const SingleActivator(LogicalKeyboardKey.keyF, control: true),
            onInvoke: onFind,
            category: 'Edit',
          ));
    }
    if (onFindReplace != null) {
      register(
          'editor.findReplace',
          KeyboardShortcutAction(
            label: 'Find & Replace',
            activator:
                const SingleActivator(LogicalKeyboardKey.keyH, control: true),
            onInvoke: onFindReplace,
            category: 'Edit',
          ));
    }
    if (onPrint != null) {
      register(
          'editor.print',
          KeyboardShortcutAction(
            label: 'Print',
            activator:
                const SingleActivator(LogicalKeyboardKey.keyP, control: true),
            onInvoke: onPrint,
            category: 'File',
          ));
    }
  }
}

/// Internal intent that wraps a callback for the Actions framework.
class _CallbackIntent extends Intent {
  final VoidCallback callback;
  const _CallbackIntent(this.callback);
}
