import 'dart:async';

/// Represents the status of a background task.
enum TaskStatus {
  /// Task is queued and waiting to run.
  pending,

  /// Task is currently executing.
  running,

  /// Task completed successfully.
  completed,

  /// Task failed with an error.
  failed,

  /// Task was cancelled.
  cancelled,
}

/// A background task with progress tracking.
class BackgroundTask<T> {
  /// Unique task identifier.
  final String id;

  /// Human-readable task description.
  final String description;

  /// Current task status.
  TaskStatus status;

  /// Progress percentage (0.0 to 1.0).
  double progress;

  /// The result if completed.
  T? result;

  /// Error message if failed.
  String? error;

  /// The completer for awaiting task completion.
  final Completer<T?> _completer = Completer<T?>();

  /// The cancellation token.
  bool _isCancelled = false;

  BackgroundTask({
    required this.id,
    required this.description,
    this.status = TaskStatus.pending,
    this.progress = 0.0,
  });

  /// Whether this task has been cancelled.
  bool get isCancelled => _isCancelled;

  /// Future that completes when the task finishes.
  Future<T?> get future => _completer.future;

  /// Cancels this task.
  void cancel() {
    _isCancelled = true;
    status = TaskStatus.cancelled;
    if (!_completer.isCompleted) {
      _completer.complete(null);
    }
  }

  /// Completes the task with a result.
  void complete(T value) {
    result = value;
    status = TaskStatus.completed;
    progress = 1.0;
    if (!_completer.isCompleted) {
      _completer.complete(value);
    }
  }

  /// Fails the task with an error.
  void fail(String errorMessage) {
    error = errorMessage;
    status = TaskStatus.failed;
    if (!_completer.isCompleted) {
      _completer.complete(null);
    }
  }
}

/// Manages background tasks with progress tracking and cancellation.
///
/// Used for long-running operations like file imports, exports,
/// PDF rendering, image processing, etc.
class BackgroundTaskManager {
  BackgroundTaskManager._();

  static final BackgroundTaskManager _instance = BackgroundTaskManager._();

  /// Singleton instance.
  static BackgroundTaskManager get instance => _instance;

  /// All active and recent tasks.
  final Map<String, BackgroundTask<dynamic>> _tasks = {};

  /// Stream controller for task status updates.
  final _statusController =
      StreamController<BackgroundTask<dynamic>>.broadcast();

  /// Stream of task status updates.
  Stream<BackgroundTask<dynamic>> get taskUpdates => _statusController.stream;

  /// Returns all tasks.
  List<BackgroundTask<dynamic>> get tasks => _tasks.values.toList();

  /// Returns active (pending or running) tasks.
  List<BackgroundTask<dynamic>> get activeTasks => _tasks.values
      .where(
          (t) => t.status == TaskStatus.pending || t.status == TaskStatus.running)
      .toList();

  /// Returns the task with [id], or null.
  BackgroundTask<dynamic>? getTask(String id) => _tasks[id];

  /// Submits a new background task.
  ///
  /// The [execute] function receives the [BackgroundTask] for progress
  /// updates and cancellation checking.
  Future<T?> submit<T>({
    required String id,
    required String description,
    required Future<T> Function(BackgroundTask<T> task) execute,
  }) async {
    // Cancel existing task with same ID
    _tasks[id]?.cancel();

    final task = BackgroundTask<T>(id: id, description: description);
    _tasks[id] = task;

    task.status = TaskStatus.running;
    _notifyUpdate(task);

    try {
      final result = await execute(task);
      if (!task.isCancelled) {
        task.complete(result);
        _notifyUpdate(task);
      }
      return result;
    } catch (e) {
      if (!task.isCancelled) {
        task.fail(e.toString());
        _notifyUpdate(task);
      }
      return null;
    }
  }

  /// Updates the progress of a task and notifies listeners.
  void updateProgress(String id, double progress) {
    final task = _tasks[id];
    if (task != null && !task.isCancelled) {
      task.progress = progress.clamp(0.0, 1.0);
      _notifyUpdate(task);
    }
  }

  /// Cancels a task by ID.
  void cancel(String id) {
    _tasks[id]?.cancel();
    final task = _tasks[id];
    if (task != null) _notifyUpdate(task);
  }

  /// Removes completed/failed/cancelled tasks from the list.
  void clearCompleted() {
    _tasks.removeWhere((_, t) =>
        t.status == TaskStatus.completed ||
        t.status == TaskStatus.failed ||
        t.status == TaskStatus.cancelled);
  }

  void _notifyUpdate(BackgroundTask<dynamic> task) {
    if (!_statusController.isClosed) {
      _statusController.add(task);
    }
  }

  /// Disposes the manager and cancels all tasks.
  void dispose() {
    for (final task in _tasks.values) {
      task.cancel();
    }
    _tasks.clear();
    _statusController.close();
  }
}
