import 'dart:io' show Directory, File, Platform;

import 'package:equatable/equatable.dart';
import 'package:fileutility_storage/fileutility_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_bloc/flutter_bloc.dart';

// ── Events ──────────────────────────────────────────────────

sealed class FileManagerEvent extends Equatable {
  const FileManagerEvent();

  @override
  List<Object?> get props => [];
}

class LoadRecentFiles extends FileManagerEvent {
  const LoadRecentFiles();
}

class LoadFavoriteFiles extends FileManagerEvent {
  const LoadFavoriteFiles();
}

class SearchFiles extends FileManagerEvent {
  const SearchFiles(this.query);
  final String query;

  @override
  List<Object?> get props => [query];
}

class ToggleFileFavorite extends FileManagerEvent {
  const ToggleFileFavorite(this.id);
  final String id;

  @override
  List<Object?> get props => [id];
}

class DeleteRecentFile extends FileManagerEvent {
  const DeleteRecentFile(this.id);
  final String id;

  @override
  List<Object?> get props => [id];
}

class ClearRecentFiles extends FileManagerEvent {
  const ClearRecentFiles();
}

class RecordFileOpened extends FileManagerEvent {
  const RecordFileOpened({
    required this.fileName,
    required this.filePath,
    required this.fileType,
    this.sizeBytes,
  });

  final String fileName;
  final String filePath;
  final String fileType;
  final int? sizeBytes;

  @override
  List<Object?> get props => [fileName, filePath, fileType, sizeBytes];
}

class ChangeViewMode extends FileManagerEvent {
  const ChangeViewMode(this.viewMode);
  final FileViewMode viewMode;

  @override
  List<Object?> get props => [viewMode];
}

/// Browse a local directory (non-web only).
class BrowseDirectory extends FileManagerEvent {
  const BrowseDirectory(this.path);
  final String path;

  @override
  List<Object?> get props => [path];
}

/// Rename a file.
class RenameFile extends FileManagerEvent {
  const RenameFile({required this.id, required this.newName});
  final String id;
  final String newName;

  @override
  List<Object?> get props => [id, newName];
}

/// Copy a file to a destination.
class CopyFile extends FileManagerEvent {
  const CopyFile({required this.sourcePath, required this.destPath});
  final String sourcePath;
  final String destPath;

  @override
  List<Object?> get props => [sourcePath, destPath];
}

/// Move a file to a destination.
class MoveFile extends FileManagerEvent {
  const MoveFile({required this.sourcePath, required this.destPath});
  final String sourcePath;
  final String destPath;

  @override
  List<Object?> get props => [sourcePath, destPath];
}

/// Sort files by a field.
class SortFiles extends FileManagerEvent {
  const SortFiles({required this.field, this.ascending = true});
  final String field; // 'name', 'date', 'size', 'type'
  final bool ascending;

  @override
  List<Object?> get props => [field, ascending];
}

/// Toggle multi-select mode.
class ToggleMultiSelect extends FileManagerEvent {
  const ToggleMultiSelect();
}

/// Select/deselect a file in multi-select mode.
class SelectFile extends FileManagerEvent {
  const SelectFile(this.id);
  final String id;

  @override
  List<Object?> get props => [id];
}

/// Clear all selections.
class ClearSelection extends FileManagerEvent {
  const ClearSelection();
}

/// Delete all selected files.
class PerformBulkDelete extends FileManagerEvent {
  const PerformBulkDelete();
}

// ── State ───────────────────────────────────────────────────

enum FileManagerStatus { initial, loading, loaded, error }

enum FileViewMode { grid, list }

enum FileTab { recent, favorites }

/// Represents a file or directory item from local file system browsing.
class FileSystemItem extends Equatable {
  final String name;
  final String path;
  final bool isDirectory;
  final int sizeBytes;
  final DateTime modifiedAt;
  final String extension;

  const FileSystemItem({
    required this.name,
    required this.path,
    required this.isDirectory,
    this.sizeBytes = 0,
    required this.modifiedAt,
    this.extension = '',
  });

  @override
  List<Object?> get props => [name, path, isDirectory, sizeBytes, modifiedAt];
}

class FileManagerState extends Equatable {
  const FileManagerState({
    this.status = FileManagerStatus.initial,
    this.files = const [],
    this.searchQuery = '',
    this.viewMode = FileViewMode.list,
    this.activeTab = FileTab.recent,
    this.errorMessage,
    this.directoryPath,
    this.directoryContents = const [],
    this.isMultiSelect = false,
    this.selectedIds = const {},
    this.sortField = 'date',
    this.sortAscending = false,
  });

  final FileManagerStatus status;
  final List<RecentFileEntity> files;
  final String searchQuery;
  final FileViewMode viewMode;
  final FileTab activeTab;
  final String? errorMessage;

  /// Current browsed directory path (non-web).
  final String? directoryPath;

  /// Contents of the current browsed directory.
  final List<FileSystemItem> directoryContents;

  /// Whether multi-select mode is active.
  final bool isMultiSelect;

  /// IDs of selected files in multi-select mode.
  final Set<String> selectedIds;

  /// Current sort field: 'name', 'date', 'size', 'type'.
  final String sortField;

  /// Sort direction.
  final bool sortAscending;

  FileManagerState copyWith({
    FileManagerStatus? status,
    List<RecentFileEntity>? files,
    String? searchQuery,
    FileViewMode? viewMode,
    FileTab? activeTab,
    String? errorMessage,
    String? directoryPath,
    List<FileSystemItem>? directoryContents,
    bool? isMultiSelect,
    Set<String>? selectedIds,
    String? sortField,
    bool? sortAscending,
  }) {
    return FileManagerState(
      status: status ?? this.status,
      files: files ?? this.files,
      searchQuery: searchQuery ?? this.searchQuery,
      viewMode: viewMode ?? this.viewMode,
      activeTab: activeTab ?? this.activeTab,
      errorMessage: errorMessage ?? this.errorMessage,
      directoryPath: directoryPath ?? this.directoryPath,
      directoryContents: directoryContents ?? this.directoryContents,
      isMultiSelect: isMultiSelect ?? this.isMultiSelect,
      selectedIds: selectedIds ?? this.selectedIds,
      sortField: sortField ?? this.sortField,
      sortAscending: sortAscending ?? this.sortAscending,
    );
  }

  @override
  List<Object?> get props => [
        status,
        files,
        searchQuery,
        viewMode,
        activeTab,
        errorMessage,
        directoryPath,
        directoryContents.length,
        isMultiSelect,
        selectedIds.length,
        sortField,
        sortAscending,
      ];
}

// ── BLoC ────────────────────────────────────────────────────

class FileManagerBloc extends Bloc<FileManagerEvent, FileManagerState> {
  FileManagerBloc({
    required RecentFileDao recentFileDao,
  })  : _recentFileDao = recentFileDao,
        super(const FileManagerState()) {
    on<LoadRecentFiles>(_onLoadRecentFiles);
    on<LoadFavoriteFiles>(_onLoadFavoriteFiles);
    on<SearchFiles>(_onSearchFiles);
    on<ToggleFileFavorite>(_onToggleFileFavorite);
    on<DeleteRecentFile>(_onDeleteRecentFile);
    on<ClearRecentFiles>(_onClearRecentFiles);
    on<RecordFileOpened>(_onRecordFileOpened);
    on<ChangeViewMode>(_onChangeViewMode);
    on<BrowseDirectory>(_onBrowseDirectory);
    on<RenameFile>(_onRenameFile);
    on<CopyFile>(_onCopyFile);
    on<MoveFile>(_onMoveFile);
    on<SortFiles>(_onSortFiles);
    on<ToggleMultiSelect>(_onToggleMultiSelect);
    on<SelectFile>(_onSelectFile);
    on<ClearSelection>(_onClearSelection);
    on<PerformBulkDelete>(_onPerformBulkDelete);
  }

  final RecentFileDao _recentFileDao;

  Future<void> _onLoadRecentFiles(
    LoadRecentFiles event,
    Emitter<FileManagerState> emit,
  ) async {
    emit(state.copyWith(
      status: FileManagerStatus.loading,
      activeTab: FileTab.recent,
    ));
    try {
      final files = await _recentFileDao.getAll();
      emit(state.copyWith(
        status: FileManagerStatus.loaded,
        files: files,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: FileManagerStatus.error,
        errorMessage: 'Failed to load files: $e',
      ));
    }
  }

  Future<void> _onLoadFavoriteFiles(
    LoadFavoriteFiles event,
    Emitter<FileManagerState> emit,
  ) async {
    emit(state.copyWith(
      status: FileManagerStatus.loading,
      activeTab: FileTab.favorites,
    ));
    try {
      final files = await _recentFileDao.getFavorites();
      emit(state.copyWith(
        status: FileManagerStatus.loaded,
        files: files,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: FileManagerStatus.error,
        errorMessage: 'Failed to load favorites: $e',
      ));
    }
  }

  Future<void> _onSearchFiles(
    SearchFiles event,
    Emitter<FileManagerState> emit,
  ) async {
    emit(state.copyWith(searchQuery: event.query));
    try {
      final files = await _recentFileDao.search(event.query);
      emit(state.copyWith(
        status: FileManagerStatus.loaded,
        files: files,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: FileManagerStatus.error,
        errorMessage: 'Search failed: $e',
      ));
    }
  }

  Future<void> _onToggleFileFavorite(
    ToggleFileFavorite event,
    Emitter<FileManagerState> emit,
  ) async {
    try {
      await _recentFileDao.toggleFavorite(event.id);
      // Reload current tab
      if (state.activeTab == FileTab.favorites) {
        add(const LoadFavoriteFiles());
      } else {
        add(const LoadRecentFiles());
      }
    } catch (e) {
      emit(state.copyWith(
        status: FileManagerStatus.error,
        errorMessage: 'Failed to toggle favorite: $e',
      ));
    }
  }

  Future<void> _onDeleteRecentFile(
    DeleteRecentFile event,
    Emitter<FileManagerState> emit,
  ) async {
    try {
      await _recentFileDao.delete(event.id);
      add(const LoadRecentFiles());
    } catch (e) {
      emit(state.copyWith(
        status: FileManagerStatus.error,
        errorMessage: 'Failed to delete: $e',
      ));
    }
  }

  Future<void> _onClearRecentFiles(
    ClearRecentFiles event,
    Emitter<FileManagerState> emit,
  ) async {
    try {
      await _recentFileDao.clearNonFavorites();
      add(const LoadRecentFiles());
    } catch (e) {
      emit(state.copyWith(
        status: FileManagerStatus.error,
        errorMessage: 'Failed to clear: $e',
      ));
    }
  }

  Future<void> _onRecordFileOpened(
    RecordFileOpened event,
    Emitter<FileManagerState> emit,
  ) async {
    try {
      await _recentFileDao.recordOpened(
        fileName: event.fileName,
        filePath: event.filePath,
        fileType: event.fileType,
        sizeBytes: event.sizeBytes,
      );
    } catch (e) {
      // Non-critical, log only
    }
  }

  void _onChangeViewMode(
    ChangeViewMode event,
    Emitter<FileManagerState> emit,
  ) {
    emit(state.copyWith(viewMode: event.viewMode));
  }

  // --- Local Directory Browsing ---

  Future<void> _onBrowseDirectory(
    BrowseDirectory event,
    Emitter<FileManagerState> emit,
  ) async {
    if (kIsWeb) {
      emit(state.copyWith(
        status: FileManagerStatus.error,
        errorMessage: 'Directory browsing is not supported on web',
      ));
      return;
    }

    emit(state.copyWith(status: FileManagerStatus.loading));
    try {
      final dir = Directory(event.path);
      if (!await dir.exists()) {
        emit(state.copyWith(
          status: FileManagerStatus.error,
          errorMessage: 'Directory does not exist: ${event.path}',
        ));
        return;
      }

      final entities = await dir.list().toList();
      final items = <FileSystemItem>[];

      for (final entity in entities) {
        final name = entity.path.split(Platform.pathSeparator).last;
        // Skip hidden files/directories
        if (name.startsWith('.')) continue;

        final stat = await entity.stat();
        final isDir = entity is Directory;
        final ext = isDir
            ? ''
            : name.contains('.')
                ? name.split('.').last.toLowerCase()
                : '';

        items.add(FileSystemItem(
          name: name,
          path: entity.path,
          isDirectory: isDir,
          sizeBytes: stat.size,
          modifiedAt: stat.modified,
          extension: ext,
        ));
      }

      // Sort: directories first, then by name
      items.sort((a, b) {
        if (a.isDirectory && !b.isDirectory) return -1;
        if (!a.isDirectory && b.isDirectory) return 1;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });

      emit(state.copyWith(
        status: FileManagerStatus.loaded,
        directoryPath: event.path,
        directoryContents: items,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: FileManagerStatus.error,
        errorMessage: 'Failed to browse directory: $e',
      ));
    }
  }

  // --- File Operations ---

  Future<void> _onRenameFile(
    RenameFile event,
    Emitter<FileManagerState> emit,
  ) async {
    try {
      // Find the file record
      final file = state.files.cast<RecentFileEntity?>().firstWhere(
            (f) => f!.id == event.id,
            orElse: () => null,
          );

      // Re-record with updated name (upsert behavior)
      if (file != null) {
        await _recentFileDao.recordOpened(
          fileName: event.newName,
          filePath: file.filePath,
          fileType: file.fileType,
          sizeBytes: file.sizeBytes,
        );
      }

      // Also rename the actual file on disk (non-web)
      if (!kIsWeb && file != null) {
        final sourceFile = File(file.filePath);
        if (await sourceFile.exists()) {
          final dir = sourceFile.parent.path;
          final newPath = '$dir${Platform.pathSeparator}${event.newName}';
          await sourceFile.rename(newPath);
        }
      }

      // Reload
      if (state.activeTab == FileTab.favorites) {
        add(const LoadFavoriteFiles());
      } else {
        add(const LoadRecentFiles());
      }
    } catch (e) {
      emit(state.copyWith(
        status: FileManagerStatus.error,
        errorMessage: 'Failed to rename: $e',
      ));
    }
  }

  Future<void> _onCopyFile(
    CopyFile event,
    Emitter<FileManagerState> emit,
  ) async {
    if (kIsWeb) return;
    try {
      final source = File(event.sourcePath);
      if (await source.exists()) {
        await source.copy(event.destPath);
      }
      // If browsing a directory, refresh it
      if (state.directoryPath != null) {
        add(BrowseDirectory(state.directoryPath!));
      }
    } catch (e) {
      emit(state.copyWith(
        status: FileManagerStatus.error,
        errorMessage: 'Failed to copy file: $e',
      ));
    }
  }

  Future<void> _onMoveFile(
    MoveFile event,
    Emitter<FileManagerState> emit,
  ) async {
    if (kIsWeb) return;
    try {
      final source = File(event.sourcePath);
      if (await source.exists()) {
        await source.rename(event.destPath);
      }
      // If browsing a directory, refresh it
      if (state.directoryPath != null) {
        add(BrowseDirectory(state.directoryPath!));
      }
    } catch (e) {
      emit(state.copyWith(
        status: FileManagerStatus.error,
        errorMessage: 'Failed to move file: $e',
      ));
    }
  }

  // --- Sorting ---

  void _onSortFiles(
    SortFiles event,
    Emitter<FileManagerState> emit,
  ) {
    final sortedFiles = List<RecentFileEntity>.from(state.files);
    switch (event.field) {
      case 'name':
        sortedFiles.sort((a, b) => event.ascending
            ? a.fileName.toLowerCase().compareTo(b.fileName.toLowerCase())
            : b.fileName.toLowerCase().compareTo(a.fileName.toLowerCase()));
      case 'date':
        sortedFiles.sort((a, b) => event.ascending
            ? a.lastOpenedAt.compareTo(b.lastOpenedAt)
            : b.lastOpenedAt.compareTo(a.lastOpenedAt));
      case 'size':
        sortedFiles.sort((a, b) => event.ascending
            ? (a.sizeBytes ?? 0).compareTo(b.sizeBytes ?? 0)
            : (b.sizeBytes ?? 0).compareTo(a.sizeBytes ?? 0));
      case 'type':
        sortedFiles.sort((a, b) => event.ascending
            ? a.fileType.compareTo(b.fileType)
            : b.fileType.compareTo(a.fileType));
    }
    emit(state.copyWith(
      files: sortedFiles,
      sortField: event.field,
      sortAscending: event.ascending,
    ));
  }

  // --- Multi-Select ---

  void _onToggleMultiSelect(
    ToggleMultiSelect event,
    Emitter<FileManagerState> emit,
  ) {
    emit(state.copyWith(
      isMultiSelect: !state.isMultiSelect,
      selectedIds: const {},
    ));
  }

  void _onSelectFile(
    SelectFile event,
    Emitter<FileManagerState> emit,
  ) {
    final selected = Set<String>.from(state.selectedIds);
    if (selected.contains(event.id)) {
      selected.remove(event.id);
    } else {
      selected.add(event.id);
    }
    emit(state.copyWith(selectedIds: selected));
  }

  void _onClearSelection(
    ClearSelection event,
    Emitter<FileManagerState> emit,
  ) {
    emit(state.copyWith(selectedIds: const {}));
  }

  Future<void> _onPerformBulkDelete(
    PerformBulkDelete event,
    Emitter<FileManagerState> emit,
  ) async {
    if (state.selectedIds.isEmpty) return;
    try {
      for (final id in state.selectedIds) {
        await _recentFileDao.delete(id);
      }
      emit(state.copyWith(
        selectedIds: const {},
        isMultiSelect: false,
      ));
      // Reload
      if (state.activeTab == FileTab.favorites) {
        add(const LoadFavoriteFiles());
      } else {
        add(const LoadRecentFiles());
      }
    } catch (e) {
      emit(state.copyWith(
        status: FileManagerStatus.error,
        errorMessage: 'Failed to delete selected files: $e',
      ));
    }
  }
}
