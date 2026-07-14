import 'dart:async';

/// A generic save manager that provides auto-save with debounce,
/// dirty-state tracking, and manual save triggers.
///
/// Replaces the duplicated `_scheduleAutoSave()` pattern found in
/// SpreadsheetBloc, DocumentEditorBloc, PresentationBloc, NotesBloc,
/// and TextEditorBloc.
///
/// Usage:
/// ```dart
/// final saveManager = SaveManager<MyDocument>(
///   onSave: (doc) async => await dao.update(doc),
///   autoSaveDelay: Duration(seconds: 5),
/// );
///
/// saveManager.markDirty(currentDoc);
/// // Auto-save will trigger after 5 seconds of inactivity
///
/// await saveManager.saveNow(currentDoc);
/// // Immediate save
/// ```
class SaveManager<T> {
  /// Callback invoked to perform the actual save operation.
  final Future<void> Function(T data) onSave;

  /// Callback invoked when save succeeds.
  final void Function()? onSaveSuccess;

  /// Callback invoked when save fails.
  final void Function(Object error)? onSaveError;

  /// Delay before auto-save triggers after the last dirty mark.
  final Duration autoSaveDelay;

  /// Whether auto-save is enabled.
  bool autoSaveEnabled;

  Timer? _autoSaveTimer;
  bool _isDirty = false;
  bool _isSaving = false;
  T? _pendingData;

  /// Creates a [SaveManager].
  SaveManager({
    required this.onSave,
    this.onSaveSuccess,
    this.onSaveError,
    this.autoSaveDelay = const Duration(seconds: 5),
    this.autoSaveEnabled = true,
  });

  /// Whether there are unsaved changes.
  bool get isDirty => _isDirty;

  /// Whether a save operation is currently in progress.
  bool get isSaving => _isSaving;

  /// Marks the data as dirty (modified) and schedules auto-save.
  ///
  /// The [data] parameter is the current state to save.
  /// Auto-save will trigger after [autoSaveDelay] of inactivity.
  void markDirty(T data) {
    _isDirty = true;
    _pendingData = data;
    if (autoSaveEnabled) {
      _scheduleAutoSave();
    }
  }

  /// Performs an immediate save of the provided [data].
  ///
  /// Cancels any pending auto-save timer.
  /// Returns `true` if save succeeded, `false` otherwise.
  Future<bool> saveNow(T data) async {
    _cancelAutoSave();
    _pendingData = data;
    return _performSave();
  }

  /// Performs an immediate save of the last pending data.
  ///
  /// Returns `true` if save succeeded, `false` if no pending data
  /// or save failed.
  Future<bool> savePending() async {
    if (_pendingData == null || !_isDirty) return false;
    _cancelAutoSave();
    return _performSave();
  }

  /// Marks the data as clean (saved).
  void markClean() {
    _isDirty = false;
    _cancelAutoSave();
  }

  /// Cancels any pending auto-save and clears state.
  void dispose() {
    _cancelAutoSave();
    _pendingData = null;
  }

  void _scheduleAutoSave() {
    _cancelAutoSave();
    _autoSaveTimer = Timer(autoSaveDelay, () {
      if (_isDirty && _pendingData != null) {
        _performSave();
      }
    });
  }

  void _cancelAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = null;
  }

  Future<bool> _performSave() async {
    if (_isSaving || _pendingData == null) return false;
    _isSaving = true;
    try {
      await onSave(_pendingData as T);
      _isDirty = false;
      _isSaving = false;
      onSaveSuccess?.call();
      return true;
    } catch (e) {
      _isSaving = false;
      onSaveError?.call(e);
      return false;
    }
  }
}
