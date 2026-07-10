import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fileutility_storage/fileutility_storage.dart';

// ── Events ──────────────────────────────────────────────────

sealed class NotesEvent extends Equatable {
  const NotesEvent();

  @override
  List<Object?> get props => [];
}

class LoadNotes extends NotesEvent {
  const LoadNotes();
}

class SearchNotes extends NotesEvent {
  const SearchNotes(this.query);
  final String query;

  @override
  List<Object?> get props => [query];
}

class CreateNote extends NotesEvent {
  const CreateNote({
    this.title = '',
    this.content = '',
    this.contentType = NoteContentType.plain,
  });

  final String title;
  final String content;
  final NoteContentType contentType;

  @override
  List<Object?> get props => [title, content, contentType];
}

class UpdateNote extends NotesEvent {
  const UpdateNote(this.note);
  final NoteEntity note;

  @override
  List<Object?> get props => [note];
}

class DeleteNote extends NotesEvent {
  const DeleteNote(this.id);
  final String id;

  @override
  List<Object?> get props => [id];
}

class TogglePinNote extends NotesEvent {
  const TogglePinNote(this.id);
  final String id;

  @override
  List<Object?> get props => [id];
}

class ToggleFavoriteNote extends NotesEvent {
  const ToggleFavoriteNote(this.id);
  final String id;

  @override
  List<Object?> get props => [id];
}

// ── State ───────────────────────────────────────────────────

enum NotesStatus { initial, loading, loaded, error }

class NotesState extends Equatable {
  const NotesState({
    this.status = NotesStatus.initial,
    this.notes = const [],
    this.searchQuery = '',
    this.errorMessage,
    this.selectedNote,
  });

  final NotesStatus status;
  final List<NoteEntity> notes;
  final String searchQuery;
  final String? errorMessage;
  final NoteEntity? selectedNote;

  /// Notes filtered by pinned status.
  List<NoteEntity> get pinnedNotes =>
      notes.where((n) => n.isPinned).toList();

  /// Notes that are not pinned.
  List<NoteEntity> get unpinnedNotes =>
      notes.where((n) => !n.isPinned).toList();

  NotesState copyWith({
    NotesStatus? status,
    List<NoteEntity>? notes,
    String? searchQuery,
    String? errorMessage,
    NoteEntity? selectedNote,
  }) {
    return NotesState(
      status: status ?? this.status,
      notes: notes ?? this.notes,
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: errorMessage ?? this.errorMessage,
      selectedNote: selectedNote ?? this.selectedNote,
    );
  }

  @override
  List<Object?> get props => [
        status, notes, searchQuery, errorMessage, selectedNote,
      ];
}

// ── BLoC ────────────────────────────────────────────────────

class NotesBloc extends Bloc<NotesEvent, NotesState> {
  NotesBloc({required NoteDao noteDao})
      : _noteDao = noteDao,
        super(const NotesState()) {
    on<LoadNotes>(_onLoadNotes);
    on<SearchNotes>(_onSearchNotes);
    on<CreateNote>(_onCreateNote);
    on<UpdateNote>(_onUpdateNote);
    on<DeleteNote>(_onDeleteNote);
    on<TogglePinNote>(_onTogglePinNote);
    on<ToggleFavoriteNote>(_onToggleFavoriteNote);
  }

  final NoteDao _noteDao;

  Future<void> _onLoadNotes(
    LoadNotes event,
    Emitter<NotesState> emit,
  ) async {
    emit(state.copyWith(status: NotesStatus.loading));
    try {
      final notes = await _noteDao.getAll();
      emit(state.copyWith(status: NotesStatus.loaded, notes: notes));
    } catch (e) {
      emit(state.copyWith(
        status: NotesStatus.error,
        errorMessage: 'Failed to load notes: $e',
      ));
    }
  }

  Future<void> _onSearchNotes(
    SearchNotes event,
    Emitter<NotesState> emit,
  ) async {
    emit(state.copyWith(searchQuery: event.query));
    try {
      final notes = await _noteDao.search(event.query);
      emit(state.copyWith(status: NotesStatus.loaded, notes: notes));
    } catch (e) {
      emit(state.copyWith(
        status: NotesStatus.error,
        errorMessage: 'Search failed: $e',
      ));
    }
  }

  Future<void> _onCreateNote(
    CreateNote event,
    Emitter<NotesState> emit,
  ) async {
    try {
      await _noteDao.create(
        title: event.title,
        content: event.content,
        contentType: event.contentType,
      );
      add(const LoadNotes());
    } catch (e) {
      emit(state.copyWith(
        status: NotesStatus.error,
        errorMessage: 'Failed to create note: $e',
      ));
    }
  }

  Future<void> _onUpdateNote(
    UpdateNote event,
    Emitter<NotesState> emit,
  ) async {
    try {
      await _noteDao.update(event.note);
      add(const LoadNotes());
    } catch (e) {
      emit(state.copyWith(
        status: NotesStatus.error,
        errorMessage: 'Failed to update note: $e',
      ));
    }
  }

  Future<void> _onDeleteNote(
    DeleteNote event,
    Emitter<NotesState> emit,
  ) async {
    try {
      await _noteDao.delete(event.id);
      add(const LoadNotes());
    } catch (e) {
      emit(state.copyWith(
        status: NotesStatus.error,
        errorMessage: 'Failed to delete note: $e',
      ));
    }
  }

  Future<void> _onTogglePinNote(
    TogglePinNote event,
    Emitter<NotesState> emit,
  ) async {
    try {
      await _noteDao.togglePin(event.id);
      add(const LoadNotes());
    } catch (e) {
      emit(state.copyWith(
        status: NotesStatus.error,
        errorMessage: 'Failed to toggle pin: $e',
      ));
    }
  }

  Future<void> _onToggleFavoriteNote(
    ToggleFavoriteNote event,
    Emitter<NotesState> emit,
  ) async {
    try {
      await _noteDao.toggleFavorite(event.id);
      add(const LoadNotes());
    } catch (e) {
      emit(state.copyWith(
        status: NotesStatus.error,
        errorMessage: 'Failed to toggle favorite: $e',
      ));
    }
  }
}
