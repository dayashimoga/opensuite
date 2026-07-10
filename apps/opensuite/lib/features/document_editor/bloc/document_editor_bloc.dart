import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fileutility_storage/fileutility_storage.dart';

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
    on<SearchDocuments>(_onSearchDocuments);
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

  @override
  Future<void> close() {
    _autoSaveTimer?.cancel();
    return super.close();
  }
}
