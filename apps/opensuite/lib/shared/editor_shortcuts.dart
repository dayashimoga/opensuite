import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Standardized keyboard shortcut bindings for all editor modules.
///
/// Provides a consistent set of keyboard shortcuts across all editors:
/// - Ctrl+N: New
/// - Ctrl+O: Open
/// - Ctrl+S: Save
/// - Ctrl+Shift+S: Save As / Export
/// - Ctrl+Z: Undo
/// - Ctrl+Y / Ctrl+Shift+Z: Redo
/// - Ctrl+F: Find
/// - Ctrl+H: Find & Replace
/// - Ctrl+P: Print / Preview
/// - Delete: Delete selected
///
/// Usage:
/// ```dart
/// CallbackShortcuts(
///   bindings: EditorShortcuts.build(
///     onSave: () => ...,
///     onUndo: () => ...,
///   ),
///   child: Focus(autofocus: true, child: ...),
/// )
/// ```
class EditorShortcuts {
  EditorShortcuts._();

  /// Build a shortcut binding map with only the provided callbacks.
  ///
  /// Pass `null` for shortcuts you don't want to bind.
  static Map<ShortcutActivator, VoidCallback> build({
    VoidCallback? onNew,
    VoidCallback? onOpen,
    VoidCallback? onSave,
    VoidCallback? onSaveAs,
    VoidCallback? onUndo,
    VoidCallback? onRedo,
    VoidCallback? onFind,
    VoidCallback? onFindReplace,
    VoidCallback? onPrint,
    VoidCallback? onDelete,
    VoidCallback? onCut,
    VoidCallback? onCopy,
    VoidCallback? onPaste,
    VoidCallback? onSelectAll,
    VoidCallback? onEscape,
  }) {
    final map = <ShortcutActivator, VoidCallback>{};

    if (onNew != null) {
      map[const SingleActivator(LogicalKeyboardKey.keyN, control: true)] =
          onNew;
    }
    if (onOpen != null) {
      map[const SingleActivator(LogicalKeyboardKey.keyO, control: true)] =
          onOpen;
    }
    if (onSave != null) {
      map[const SingleActivator(LogicalKeyboardKey.keyS, control: true)] =
          onSave;
    }
    if (onSaveAs != null) {
      map[const SingleActivator(LogicalKeyboardKey.keyS,
          control: true, shift: true)] = onSaveAs;
    }
    if (onUndo != null) {
      map[const SingleActivator(LogicalKeyboardKey.keyZ, control: true)] =
          onUndo;
    }
    if (onRedo != null) {
      map[const SingleActivator(LogicalKeyboardKey.keyY, control: true)] =
          onRedo;
      map[const SingleActivator(LogicalKeyboardKey.keyZ,
          control: true, shift: true)] = onRedo;
    }
    if (onFind != null) {
      map[const SingleActivator(LogicalKeyboardKey.keyF, control: true)] =
          onFind;
    }
    if (onFindReplace != null) {
      map[const SingleActivator(LogicalKeyboardKey.keyH, control: true)] =
          onFindReplace;
    }
    if (onPrint != null) {
      map[const SingleActivator(LogicalKeyboardKey.keyP, control: true)] =
          onPrint;
    }
    if (onDelete != null) {
      map[const SingleActivator(LogicalKeyboardKey.delete)] = onDelete;
    }
    if (onCut != null) {
      map[const SingleActivator(LogicalKeyboardKey.keyX, control: true)] =
          onCut;
    }
    if (onCopy != null) {
      map[const SingleActivator(LogicalKeyboardKey.keyC, control: true)] =
          onCopy;
    }
    if (onPaste != null) {
      map[const SingleActivator(LogicalKeyboardKey.keyV, control: true)] =
          onPaste;
    }
    if (onSelectAll != null) {
      map[const SingleActivator(LogicalKeyboardKey.keyA, control: true)] =
          onSelectAll;
    }
    if (onEscape != null) {
      map[const SingleActivator(LogicalKeyboardKey.escape)] = onEscape;
    }

    return map;
  }

  /// Wraps a child widget with standardized keyboard shortcuts.
  static Widget wrap({
    required Widget child,
    VoidCallback? onNew,
    VoidCallback? onOpen,
    VoidCallback? onSave,
    VoidCallback? onSaveAs,
    VoidCallback? onUndo,
    VoidCallback? onRedo,
    VoidCallback? onFind,
    VoidCallback? onFindReplace,
    VoidCallback? onPrint,
    VoidCallback? onDelete,
    VoidCallback? onCut,
    VoidCallback? onCopy,
    VoidCallback? onPaste,
    VoidCallback? onSelectAll,
    VoidCallback? onEscape,
  }) {
    final bindings = build(
      onNew: onNew,
      onOpen: onOpen,
      onSave: onSave,
      onSaveAs: onSaveAs,
      onUndo: onUndo,
      onRedo: onRedo,
      onFind: onFind,
      onFindReplace: onFindReplace,
      onPrint: onPrint,
      onDelete: onDelete,
      onCut: onCut,
      onCopy: onCopy,
      onPaste: onPaste,
      onSelectAll: onSelectAll,
      onEscape: onEscape,
    );

    if (bindings.isEmpty) return child;

    return CallbackShortcuts(
      bindings: bindings,
      child: Focus(autofocus: true, child: child),
    );
  }
}
