import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fileutility_storage/fileutility_storage.dart';

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

// ── State ───────────────────────────────────────────────────

enum FileManagerStatus { initial, loading, loaded, error }

enum FileViewMode { grid, list }

enum FileTab { recent, favorites }

class FileManagerState extends Equatable {
  const FileManagerState({
    this.status = FileManagerStatus.initial,
    this.files = const [],
    this.searchQuery = '',
    this.viewMode = FileViewMode.list,
    this.activeTab = FileTab.recent,
    this.errorMessage,
  });

  final FileManagerStatus status;
  final List<RecentFileEntity> files;
  final String searchQuery;
  final FileViewMode viewMode;
  final FileTab activeTab;
  final String? errorMessage;

  FileManagerState copyWith({
    FileManagerStatus? status,
    List<RecentFileEntity>? files,
    String? searchQuery,
    FileViewMode? viewMode,
    FileTab? activeTab,
    String? errorMessage,
  }) {
    return FileManagerState(
      status: status ?? this.status,
      files: files ?? this.files,
      searchQuery: searchQuery ?? this.searchQuery,
      viewMode: viewMode ?? this.viewMode,
      activeTab: activeTab ?? this.activeTab,
      errorMessage: errorMessage ?? this.errorMessage,
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
}
