import 'dart:async';

import 'package:bloc_concurrency/bloc_concurrency.dart';

import 'package:equatable/equatable.dart';
import 'package:fileutility_storage/fileutility_storage.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// --- Events ---

/// Base event for the document editor.
sealed class DocumentEditorEvent extends Equatable {
  const DocumentEditorEvent();

  @override
  List<Object?> get props => [];
}

/// Load all documents for the list view.
class LoadDocuments extends DocumentEditorEvent {
  const LoadDocuments();
}

/// Search documents by query.
class SearchDocuments extends DocumentEditorEvent {
  final String query;
  const SearchDocuments(this.query);

  @override
  List<Object?> get props => [query];
}

/// Create a new empty document.
class CreateDocument extends DocumentEditorEvent {
  final String title;
  final String format;
  const CreateDocument(
      {this.title = 'Untitled Document', this.format = 'rich'});

  @override
  List<Object?> get props => [title, format];
}

/// Open an existing document for editing.
class OpenDocument extends DocumentEditorEvent {
  final String documentId;
  const OpenDocument(this.documentId);

  @override
  List<Object?> get props => [documentId];
}

/// Update the document title.
class UpdateDocumentTitle extends DocumentEditorEvent {
  final String title;
  const UpdateDocumentTitle(this.title);

  @override
  List<Object?> get props => [title];
}

/// Update the document content.
class UpdateDocumentContent extends DocumentEditorEvent {
  final String content;
  final String plainText;
  const UpdateDocumentContent({required this.content, required this.plainText});

  @override
  List<Object?> get props => [content, plainText];
}

/// Save the current document.
class SaveDocument extends DocumentEditorEvent {
  const SaveDocument();
}

/// Auto-save triggered by timer.
class AutoSaveDocument extends DocumentEditorEvent {
  const AutoSaveDocument();
}

/// Delete a document.
class DeleteDocument extends DocumentEditorEvent {
  final String documentId;
  const DeleteDocument(this.documentId);

  @override
  List<Object?> get props => [documentId];
}

/// Toggle favorite status.
class ToggleDocumentFavorite extends DocumentEditorEvent {
  final String documentId;
  const ToggleDocumentFavorite(this.documentId);

  @override
  List<Object?> get props => [documentId];
}

/// Duplicate a document.
class DuplicateDocument extends DocumentEditorEvent {
  final String documentId;
  const DuplicateDocument(this.documentId);

  @override
  List<Object?> get props => [documentId];
}

/// Apply text formatting.
class ApplyFormatting extends DocumentEditorEvent {
  final String formatType; // 'bold', 'italic', 'underline', etc.
  const ApplyFormatting(this.formatType);

  @override
  List<Object?> get props => [formatType];
}

/// Toggle the formatting toolbar visibility.
class ToggleToolbar extends DocumentEditorEvent {
  const ToggleToolbar();
}

/// Undo last change.
class UndoChange extends DocumentEditorEvent {
  const UndoChange();
}

/// Redo last undone change.
class RedoChange extends DocumentEditorEvent {
  const RedoChange();
}

/// Toggle find/replace bar visibility.
class ToggleFindReplace extends DocumentEditorEvent {
  const ToggleFindReplace();
}

/// Find text in document.
class FindInDocument extends DocumentEditorEvent {
  final String query;
  const FindInDocument(this.query);

  @override
  List<Object?> get props => [query];
}

/// Replace text in document.
class ReplaceInDocument extends DocumentEditorEvent {
  final String find;
  final String replace;
  final bool replaceAll;
  const ReplaceInDocument(this.find, this.replace, {this.replaceAll = false});

  @override
  List<Object?> get props => [find, replace, replaceAll];
}

/// Navigate to next/previous find match.
class NavigateFindMatch extends DocumentEditorEvent {
  final bool forward;
  const NavigateFindMatch({this.forward = true});

  @override
  List<Object?> get props => [forward];
}

/// Insert text at a specific position in the content.
class InsertAtCursor extends DocumentEditorEvent {
  final String text;
  final int position;
  const InsertAtCursor(this.text, this.position);

  @override
  List<Object?> get props => [text, position];
}

// --- State ---

/// Status of the document editor.
enum DocumentEditorStatus {
  initial,
  loading,
  loaded,
  editing,
  saving,
  saved,
  error,
}

/// State of the document editor.
class DocumentEditorState extends Equatable {
  /// Current status.
  final DocumentEditorStatus status;

  /// All documents (for list view).
  final List<DocumentEntity> documents;

  /// Currently open document (for editor view).
  final DocumentEntity? currentDocument;

  /// Whether the current document has unsaved changes.
  final bool hasUnsavedChanges;

  /// Current search query.
  final String searchQuery;

  /// Whether the formatting toolbar is visible.
  final bool showToolbar;

  /// Active formatting styles at cursor position.
  final Set<String> activeFormats;

  /// Error message if status is error.
  final String? errorMessage;

  /// Word count of current document.
  final int wordCount;

  /// Character count of current document.
  final int characterCount;

  /// Undo history stack.
  final List<String> undoStack;

  /// Redo history stack.
  final List<String> redoStack;

  /// Whether the find/replace bar is visible.
  final bool showFindReplace;

  /// Current find query.
  final String findQuery;

  /// Current replace query.
  final String replaceQuery;

  /// List of match positions (start indices) in the content.
  final List<int> findMatches;

  /// Index of the currently highlighted match.
  final int currentFindIndex;

  const DocumentEditorState({
    this.status = DocumentEditorStatus.initial,
    this.documents = const [],
    this.currentDocument,
    this.hasUnsavedChanges = false,
    this.searchQuery = '',
    this.showToolbar = true,
    this.activeFormats = const {},
    this.errorMessage,
    this.wordCount = 0,
    this.characterCount = 0,
    this.undoStack = const [],
    this.redoStack = const [],
    this.showFindReplace = false,
    this.findQuery = '',
    this.replaceQuery = '',
    this.findMatches = const [],
    this.currentFindIndex = 0,
  });

  DocumentEditorState copyWith({
    DocumentEditorStatus? status,
    List<DocumentEntity>? documents,
    DocumentEntity? currentDocument,
    bool? hasUnsavedChanges,
    String? searchQuery,
    bool? showToolbar,
    Set<String>? activeFormats,
    String? errorMessage,
    int? wordCount,
    int? characterCount,
    List<String>? undoStack,
    List<String>? redoStack,
    bool? showFindReplace,
    String? findQuery,
    String? replaceQuery,
    List<int>? findMatches,
    int? currentFindIndex,
  }) {
    return DocumentEditorState(
      status: status ?? this.status,
      documents: documents ?? this.documents,
      currentDocument: currentDocument ?? this.currentDocument,
      hasUnsavedChanges: hasUnsavedChanges ?? this.hasUnsavedChanges,
      searchQuery: searchQuery ?? this.searchQuery,
      showToolbar: showToolbar ?? this.showToolbar,
      activeFormats: activeFormats ?? this.activeFormats,
      errorMessage: errorMessage ?? this.errorMessage,
      wordCount: wordCount ?? this.wordCount,
      characterCount: characterCount ?? this.characterCount,
      undoStack: undoStack ?? this.undoStack,
      redoStack: redoStack ?? this.redoStack,
      showFindReplace: showFindReplace ?? this.showFindReplace,
      findQuery: findQuery ?? this.findQuery,
      replaceQuery: replaceQuery ?? this.replaceQuery,
      findMatches: findMatches ?? this.findMatches,
      currentFindIndex: currentFindIndex ?? this.currentFindIndex,
    );
  }

  @override
  List<Object?> get props => [
        status,
        documents,
        currentDocument,
        hasUnsavedChanges,
        searchQuery,
        showToolbar,
        activeFormats,
        errorMessage,
        wordCount,
        characterCount,
        undoStack.length,
        redoStack.length,
        showFindReplace,
        findQuery,
        findMatches.length,
        currentFindIndex,
      ];
}

// --- BLoC ---

/// BLoC managing the document editor feature.
///
/// Handles document CRUD, formatting, undo/redo, and autosave.
class DocumentEditorBloc
    extends Bloc<DocumentEditorEvent, DocumentEditorState> {
  final DocumentDao _documentDao;

  Timer? _autoSaveTimer;
  static const _autoSaveDelay = Duration(seconds: 5);
  static const _maxUndoHistory = 50;

  /// Creates a [DocumentEditorBloc].
  DocumentEditorBloc({required DocumentDao documentDao})
      : _documentDao = documentDao,
        super(const DocumentEditorState()) {
    on<LoadDocuments>(_onLoadDocuments);
    on<SearchDocuments>(_onSearchDocuments, transformer: restartable());
    on<CreateDocument>(_onCreateDocument);
    on<OpenDocument>(_onOpenDocument);
    on<UpdateDocumentTitle>(_onUpdateTitle);
    on<UpdateDocumentContent>(_onUpdateContent);
    on<SaveDocument>(_onSaveDocument);
    on<AutoSaveDocument>(_onAutoSave);
    on<DeleteDocument>(_onDeleteDocument);
    on<ToggleDocumentFavorite>(_onToggleFavorite);
    on<DuplicateDocument>(_onDuplicateDocument);
    on<ApplyFormatting>(_onApplyFormatting);
    on<ToggleToolbar>(_onToggleToolbar);
    on<UndoChange>(_onUndo);
    on<RedoChange>(_onRedo);
    on<ToggleFindReplace>(_onToggleFindReplace);
    on<FindInDocument>(_onFindInDocument);
    on<ReplaceInDocument>(_onReplaceInDocument);
    on<NavigateFindMatch>(_onNavigateFindMatch);
    on<InsertAtCursor>(_onInsertAtCursor);
  }

  Future<void> _onLoadDocuments(
    LoadDocuments event,
    Emitter<DocumentEditorState> emit,
  ) async {
    emit(state.copyWith(status: DocumentEditorStatus.loading));
    try {
      final documents = await _documentDao.getAllDocuments();
      emit(state.copyWith(
        status: DocumentEditorStatus.loaded,
        documents: documents,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: DocumentEditorStatus.error,
        errorMessage: 'Failed to load documents: $e',
      ));
    }
  }

  Future<void> _onSearchDocuments(
    SearchDocuments event,
    Emitter<DocumentEditorState> emit,
  ) async {
    emit(state.copyWith(searchQuery: event.query));
    try {
      final documents = event.query.isEmpty
          ? await _documentDao.getAllDocuments()
          : await _documentDao.searchDocuments(event.query);
      emit(state.copyWith(
        status: DocumentEditorStatus.loaded,
        documents: documents,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: DocumentEditorStatus.error,
        errorMessage: 'Search failed: $e',
      ));
    }
  }

  Future<void> _onCreateDocument(
    CreateDocument event,
    Emitter<DocumentEditorState> emit,
  ) async {
    final now = DateTime.now();
    final document = DocumentEntity(
      id: now.microsecondsSinceEpoch.toString(),
      title: event.title,
      content: '[]', // Empty Delta
      plainText: '',
      format: event.format,
      createdAt: now,
      modifiedAt: now,
    );

    try {
      await _documentDao.insertDocument(document);
      emit(state.copyWith(
        status: DocumentEditorStatus.editing,
        currentDocument: document,
        hasUnsavedChanges: false,
        wordCount: 0,
        characterCount: 0,
        undoStack: const [],
        redoStack: const [],
      ));
    } catch (e) {
      emit(state.copyWith(
        status: DocumentEditorStatus.error,
        errorMessage: 'Failed to create document: $e',
      ));
    }
  }

  Future<void> _onOpenDocument(
    OpenDocument event,
    Emitter<DocumentEditorState> emit,
  ) async {
    emit(state.copyWith(status: DocumentEditorStatus.loading));
    try {
      final document = await _documentDao.getDocument(event.documentId);
      if (document != null) {
        emit(state.copyWith(
          status: DocumentEditorStatus.editing,
          currentDocument: document,
          hasUnsavedChanges: false,
          wordCount: document.wordCount,
          characterCount: document.characterCount,
          undoStack: const [],
          redoStack: const [],
        ));
      } else {
        emit(state.copyWith(
          status: DocumentEditorStatus.error,
          errorMessage: 'Document not found',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status: DocumentEditorStatus.error,
        errorMessage: 'Failed to open document: $e',
      ));
    }
  }

  void _onUpdateTitle(
    UpdateDocumentTitle event,
    Emitter<DocumentEditorState> emit,
  ) {
    if (state.currentDocument == null) return;
    final updated = state.currentDocument!.copyWith(
      title: event.title,
      modifiedAt: DateTime.now(),
    );
    emit(state.copyWith(
      currentDocument: updated,
      hasUnsavedChanges: true,
    ));
    _scheduleAutoSave();
  }

  void _onUpdateContent(
    UpdateDocumentContent event,
    Emitter<DocumentEditorState> emit,
  ) {
    if (state.currentDocument == null) return;

    // Push current content to undo stack
    final newUndoStack = List<String>.from(state.undoStack);
    if (state.currentDocument!.content != event.content) {
      newUndoStack.add(state.currentDocument!.content);
      if (newUndoStack.length > _maxUndoHistory) {
        newUndoStack.removeAt(0);
      }
    }

    // Count words and characters
    final words = event.plainText.trim().isEmpty
        ? 0
        : event.plainText.trim().split(RegExp(r'\s+')).length;
    final chars = event.plainText.length;

    final updated = state.currentDocument!.copyWith(
      content: event.content,
      plainText: event.plainText,
      wordCount: words,
      characterCount: chars,
      modifiedAt: DateTime.now(),
    );

    emit(state.copyWith(
      currentDocument: updated,
      hasUnsavedChanges: true,
      wordCount: words,
      characterCount: chars,
      undoStack: newUndoStack,
      redoStack: const [], // Clear redo on new change
    ));
    _scheduleAutoSave();
  }

  Future<void> _onSaveDocument(
    SaveDocument event,
    Emitter<DocumentEditorState> emit,
  ) async {
    if (state.currentDocument == null) return;
    emit(state.copyWith(status: DocumentEditorStatus.saving));
    try {
      await _documentDao.updateDocument(state.currentDocument!);
      emit(state.copyWith(
        status: DocumentEditorStatus.saved,
        hasUnsavedChanges: false,
      ));
      // Transition back to editing after brief saved indicator
      await Future.delayed(const Duration(milliseconds: 500));
      emit(state.copyWith(status: DocumentEditorStatus.editing));
    } catch (e) {
      emit(state.copyWith(
        status: DocumentEditorStatus.error,
        errorMessage: 'Failed to save: $e',
      ));
    }
  }

  Future<void> _onAutoSave(
    AutoSaveDocument event,
    Emitter<DocumentEditorState> emit,
  ) async {
    if (state.currentDocument == null || !state.hasUnsavedChanges) return;
    try {
      await _documentDao.updateDocument(state.currentDocument!);
      emit(state.copyWith(hasUnsavedChanges: false));
    } catch (_) {
      // Silent failure for autosave — don't disrupt the user
    }
  }

  Future<void> _onDeleteDocument(
    DeleteDocument event,
    Emitter<DocumentEditorState> emit,
  ) async {
    try {
      await _documentDao.deleteDocument(event.documentId);
      final updated =
          state.documents.where((d) => d.id != event.documentId).toList();
      emit(state.copyWith(
        documents: updated,
        currentDocument: state.currentDocument?.id == event.documentId
            ? null
            : state.currentDocument,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: DocumentEditorStatus.error,
        errorMessage: 'Failed to delete: $e',
      ));
    }
  }

  Future<void> _onToggleFavorite(
    ToggleDocumentFavorite event,
    Emitter<DocumentEditorState> emit,
  ) async {
    try {
      await _documentDao.toggleFavorite(event.documentId);
      add(const LoadDocuments());
    } catch (e) {
      emit(state.copyWith(
        status: DocumentEditorStatus.error,
        errorMessage: 'Failed to toggle favorite: $e',
      ));
    }
  }

  Future<void> _onDuplicateDocument(
    DuplicateDocument event,
    Emitter<DocumentEditorState> emit,
  ) async {
    try {
      await _documentDao.duplicateDocument(event.documentId);
      add(const LoadDocuments());
    } catch (e) {
      emit(state.copyWith(
        status: DocumentEditorStatus.error,
        errorMessage: 'Failed to duplicate: $e',
      ));
    }
  }

  void _onApplyFormatting(
    ApplyFormatting event,
    Emitter<DocumentEditorState> emit,
  ) {
    final activeFormats = Set<String>.from(state.activeFormats);
    if (activeFormats.contains(event.formatType)) {
      activeFormats.remove(event.formatType);
    } else {
      activeFormats.add(event.formatType);
    }
    emit(state.copyWith(activeFormats: activeFormats));
  }

  void _onToggleToolbar(
    ToggleToolbar event,
    Emitter<DocumentEditorState> emit,
  ) {
    emit(state.copyWith(showToolbar: !state.showToolbar));
  }

  void _onUndo(UndoChange event, Emitter<DocumentEditorState> emit) {
    if (state.undoStack.isEmpty || state.currentDocument == null) return;

    final newUndoStack = List<String>.from(state.undoStack);
    final newRedoStack = List<String>.from(state.redoStack);
    final previousContent = newUndoStack.removeLast();
    newRedoStack.add(state.currentDocument!.content);

    final updated = state.currentDocument!.copyWith(
      content: previousContent,
      modifiedAt: DateTime.now(),
    );

    emit(state.copyWith(
      currentDocument: updated,
      hasUnsavedChanges: true,
      undoStack: newUndoStack,
      redoStack: newRedoStack,
    ));
  }

  void _onRedo(RedoChange event, Emitter<DocumentEditorState> emit) {
    if (state.redoStack.isEmpty || state.currentDocument == null) return;

    final newUndoStack = List<String>.from(state.undoStack);
    final newRedoStack = List<String>.from(state.redoStack);
    final nextContent = newRedoStack.removeLast();
    newUndoStack.add(state.currentDocument!.content);

    final updated = state.currentDocument!.copyWith(
      content: nextContent,
      modifiedAt: DateTime.now(),
    );

    emit(state.copyWith(
      currentDocument: updated,
      hasUnsavedChanges: true,
      undoStack: newUndoStack,
      redoStack: newRedoStack,
    ));
  }

  void _scheduleAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(_autoSaveDelay, () {
      add(const AutoSaveDocument());
    });
  }

  // --- Find & Replace ---

  void _onToggleFindReplace(
    ToggleFindReplace event,
    Emitter<DocumentEditorState> emit,
  ) {
    emit(state.copyWith(
      showFindReplace: !state.showFindReplace,
      findMatches: const [],
      currentFindIndex: 0,
      findQuery: '',
    ));
  }

  void _onFindInDocument(
    FindInDocument event,
    Emitter<DocumentEditorState> emit,
  ) {
    if (event.query.isEmpty || state.currentDocument == null) {
      emit(state.copyWith(
        findQuery: event.query,
        findMatches: const [],
        currentFindIndex: 0,
      ));
      return;
    }

    final content = state.currentDocument!.plainText;
    final query = event.query.toLowerCase();
    final contentLower = content.toLowerCase();
    final matches = <int>[];

    int start = 0;
    while (true) {
      final index = contentLower.indexOf(query, start);
      if (index == -1) break;
      matches.add(index);
      start = index + query.length;
    }

    emit(state.copyWith(
      findQuery: event.query,
      findMatches: matches,
      currentFindIndex: matches.isNotEmpty ? 0 : 0,
    ));
  }

  void _onReplaceInDocument(
    ReplaceInDocument event,
    Emitter<DocumentEditorState> emit,
  ) {
    if (state.currentDocument == null || event.find.isEmpty) return;

    final content = state.currentDocument!.plainText;
    String newContent;

    if (event.replaceAll) {
      // Replace all occurrences (case-insensitive)
      newContent = content;
      final findLower = event.find.toLowerCase();
      int start = 0;
      final buffer = StringBuffer();
      final contentLower = content.toLowerCase();

      while (true) {
        final index = contentLower.indexOf(findLower, start);
        if (index == -1) {
          buffer.write(content.substring(start));
          break;
        }
        buffer.write(content.substring(start, index));
        buffer.write(event.replace);
        start = index + event.find.length;
      }
      newContent = buffer.toString();
    } else {
      // Replace only current match
      if (state.findMatches.isEmpty) return;
      final matchPos = state.findMatches[state.currentFindIndex];
      newContent = content.substring(0, matchPos) +
          event.replace +
          content.substring(matchPos + event.find.length);
    }

    // Push undo
    final newUndoStack = List<String>.from(state.undoStack);
    if (newUndoStack.length >= _maxUndoHistory) {
      newUndoStack.removeAt(0);
    }
    newUndoStack.add(content);

    final updated = state.currentDocument!.copyWith(
      content: newContent,
      plainText: newContent,
      modifiedAt: DateTime.now(),
    );

    emit(state.copyWith(
      currentDocument: updated,
      hasUnsavedChanges: true,
      wordCount: _countWords(newContent),
      characterCount: newContent.length,
      undoStack: newUndoStack,
      redoStack: const [],
      findMatches: const [],
      currentFindIndex: 0,
    ));

    // Re-run find to update matches
    if (state.findQuery.isNotEmpty) {
      add(FindInDocument(state.findQuery));
    }
    _scheduleAutoSave();
  }

  void _onNavigateFindMatch(
    NavigateFindMatch event,
    Emitter<DocumentEditorState> emit,
  ) {
    if (state.findMatches.isEmpty) return;
    int newIndex;
    if (event.forward) {
      newIndex = (state.currentFindIndex + 1) % state.findMatches.length;
    } else {
      newIndex = (state.currentFindIndex - 1 + state.findMatches.length) %
          state.findMatches.length;
    }
    emit(state.copyWith(currentFindIndex: newIndex));
  }

  void _onInsertAtCursor(
    InsertAtCursor event,
    Emitter<DocumentEditorState> emit,
  ) {
    if (state.currentDocument == null) return;

    final content = state.currentDocument!.plainText;
    final pos = event.position.clamp(0, content.length);
    final newContent =
        content.substring(0, pos) + event.text + content.substring(pos);

    // Push undo
    final newUndoStack = List<String>.from(state.undoStack);
    if (newUndoStack.length >= _maxUndoHistory) {
      newUndoStack.removeAt(0);
    }
    newUndoStack.add(content);

    final updated = state.currentDocument!.copyWith(
      content: newContent,
      plainText: newContent,
      modifiedAt: DateTime.now(),
    );

    emit(state.copyWith(
      currentDocument: updated,
      hasUnsavedChanges: true,
      wordCount: _countWords(newContent),
      characterCount: newContent.length,
      undoStack: newUndoStack,
      redoStack: const [],
    ));
    _scheduleAutoSave();
  }

  int _countWords(String text) {
    if (text.trim().isEmpty) return 0;
    return text.trim().split(RegExp(r'\s+')).length;
  }

  @override
  Future<void> close() {
    _autoSaveTimer?.cancel();
    return super.close();
  }
}
