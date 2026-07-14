/// A generic undo/redo manager that maintains a history stack of states.
///
/// Used by Spreadsheet, Presentation, and Image Editor to provide
/// consistent undo/redo behavior with configurable history depth.
///
/// Usage:
/// ```dart
/// final manager = UndoRedoManager<MyState>(maxHistory: 50);
/// manager.push(currentState);
/// // ... user makes changes ...
/// manager.push(newState);
/// final previous = manager.undo(); // returns currentState
/// final next = manager.redo();     // returns newState
/// ```
class UndoRedoManager<T> {
  /// Maximum number of history states to keep.
  final int maxHistory;

  /// The undo stack (past states).
  final List<T> _undoStack = [];

  /// The redo stack (future states).
  final List<T> _redoStack = [];

  /// Creates an [UndoRedoManager] with the given [maxHistory] limit.
  UndoRedoManager({this.maxHistory = 100});

  /// Pushes a new state onto the history.
  ///
  /// Clears the redo stack since the user has taken a new action.
  /// If history exceeds [maxHistory], the oldest entry is removed.
  void push(T state) {
    _undoStack.add(state);
    _redoStack.clear();
    if (_undoStack.length > maxHistory) {
      _undoStack.removeAt(0);
    }
  }

  /// Undoes the last action and returns the previous state.
  ///
  /// Returns `null` if there's nothing to undo.
  /// The current state is moved to the redo stack.
  T? undo() {
    if (_undoStack.isEmpty) return null;
    final state = _undoStack.removeLast();
    _redoStack.add(state);
    return _undoStack.isNotEmpty ? _undoStack.last : null;
  }

  /// Redoes the last undone action and returns the restored state.
  ///
  /// Returns `null` if there's nothing to redo.
  T? redo() {
    if (_redoStack.isEmpty) return null;
    final state = _redoStack.removeLast();
    _undoStack.add(state);
    return state;
  }

  /// Whether undo is available.
  bool get canUndo => _undoStack.length > 1;

  /// Whether redo is available.
  bool get canRedo => _redoStack.isNotEmpty;

  /// The current state (top of undo stack).
  T? get current => _undoStack.isNotEmpty ? _undoStack.last : null;

  /// Number of undo steps available.
  int get undoCount => _undoStack.length > 0 ? _undoStack.length - 1 : 0;

  /// Number of redo steps available.
  int get redoCount => _redoStack.length;

  /// Clears all history.
  void clear() {
    _undoStack.clear();
    _redoStack.clear();
  }
}
