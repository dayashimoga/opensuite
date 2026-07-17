import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:fileutility_storage/fileutility_storage.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../services/docx_service.dart';
import '../services/pdf_export_service.dart';

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

/// Update the document content with Quill Delta JSON.
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

/// Toggle the formatting toolbar visibility.
class ToggleToolbar extends DocumentEditorEvent {
  const ToggleToolbar();
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

/// Export the document to DOCX format.
class ExportDocx extends DocumentEditorEvent {
  const ExportDocx();
}

/// Export the document to PDF format.
class ExportPdf extends DocumentEditorEvent {
  const ExportPdf();
}

/// Import a DOCX file and load its content.
class ImportDocx extends DocumentEditorEvent {
  final Uint8List fileBytes;
  final String fileName;
  const ImportDocx({required this.fileBytes, required this.fileName});

  @override
  List<Object?> get props => [fileName, fileBytes];
}

/// Import content from a plain text or markdown file.
class ImportTextFile extends DocumentEditorEvent {
  final String content;
  final String fileName;
  final String format;
  const ImportTextFile({
    required this.content,
    required this.fileName,
    this.format = 'txt',
  });

  @override
  List<Object?> get props => [content, fileName, format];
}

/// Set the exported bytes after a successful export operation.
class SetExportedBytes extends DocumentEditorEvent {
  final Uint8List bytes;
  final String fileName;
  final String mimeType;
  const SetExportedBytes({
    required this.bytes,
    required this.fileName,
    required this.mimeType,
  });

  @override
  List<Object?> get props => [fileName, mimeType];
}

/// Clear exported bytes after download completes.
class ClearExportedBytes extends DocumentEditorEvent {
  const ClearExportedBytes();
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
  exporting,
  exported,
  importing,
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

  /// Error message if status is error.
  final String? errorMessage;

  /// Word count of current document.
  final int wordCount;

  /// Character count of current document.
  final int characterCount;

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

  /// Exported file bytes ready for download.
  final Uint8List? exportedBytes;

  /// Exported file name for download.
  final String? exportedFileName;

  /// Exported file MIME type.
  final String? exportedMimeType;

  /// Status/progress message for long operations.
  final String? progressMessage;

  const DocumentEditorState({
    this.status = DocumentEditorStatus.initial,
    this.documents = const [],
    this.currentDocument,
    this.hasUnsavedChanges = false,
    this.searchQuery = '',
    this.showToolbar = true,
    this.errorMessage,
    this.wordCount = 0,
    this.characterCount = 0,
    this.showFindReplace = false,
    this.findQuery = '',
    this.replaceQuery = '',
    this.findMatches = const [],
    this.currentFindIndex = 0,
    this.exportedBytes,
    this.exportedFileName,
    this.exportedMimeType,
    this.progressMessage,
  });

  /// The Delta JSON content of the current document, or empty Delta.
  String get deltaJson => currentDocument?.content ?? '[{"insert":"\\n"}]';

  DocumentEditorState copyWith({
    DocumentEditorStatus? status,
    List<DocumentEntity>? documents,
    DocumentEntity? currentDocument,
    bool? hasUnsavedChanges,
    String? searchQuery,
    bool? showToolbar,
    String? errorMessage,
    int? wordCount,
    int? characterCount,
    bool? showFindReplace,
    String? findQuery,
    String? replaceQuery,
    List<int>? findMatches,
    int? currentFindIndex,
    Uint8List? exportedBytes,
    String? exportedFileName,
    String? exportedMimeType,
    String? progressMessage,
    bool clearCurrentDocument = false,
  }) {
    return DocumentEditorState(
      status: status ?? this.status,
      documents: documents ?? this.documents,
      currentDocument: clearCurrentDocument
          ? null
          : (currentDocument ?? this.currentDocument),
      hasUnsavedChanges: hasUnsavedChanges ?? this.hasUnsavedChanges,
      searchQuery: searchQuery ?? this.searchQuery,
      showToolbar: showToolbar ?? this.showToolbar,
      errorMessage: errorMessage ?? this.errorMessage,
      wordCount: wordCount ?? this.wordCount,
      characterCount: characterCount ?? this.characterCount,
      showFindReplace: showFindReplace ?? this.showFindReplace,
      findQuery: findQuery ?? this.findQuery,
      replaceQuery: replaceQuery ?? this.replaceQuery,
      findMatches: findMatches ?? this.findMatches,
      currentFindIndex: currentFindIndex ?? this.currentFindIndex,
      exportedBytes: exportedBytes,
      exportedFileName: exportedFileName,
      exportedMimeType: exportedMimeType,
      progressMessage: progressMessage,
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
        errorMessage,
        wordCount,
        characterCount,
        showFindReplace,
        findQuery,
        findMatches.length,
        currentFindIndex,
        exportedFileName,
        progressMessage,
      ];
}

// --- BLoC ---

/// BLoC managing the document editor feature.
///
/// Handles document CRUD, rich text (Quill Delta) persistence,
/// DOCX/PDF export, and autosave.
///
/// Undo/redo is handled by flutter_quill's built-in HistoryController,
/// so the BLoC no longer manages an undo/redo stack.
class DocumentEditorBloc
    extends Bloc<DocumentEditorEvent, DocumentEditorState> {
  final DocumentDao _documentDao;

  Timer? _autoSaveTimer;
  static const _autoSaveDelay = Duration(seconds: 5);

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
    on<ToggleToolbar>(_onToggleToolbar);
    on<ToggleFindReplace>(_onToggleFindReplace);
    on<FindInDocument>(_onFindInDocument);
    on<ReplaceInDocument>(_onReplaceInDocument);
    on<NavigateFindMatch>(_onNavigateFindMatch);
    on<ExportDocx>(_onExportDocx);
    on<ExportPdf>(_onExportPdf);
    on<ImportDocx>(_onImportDocx);
    on<ImportTextFile>(_onImportTextFile);
    on<SetExportedBytes>(_onSetExportedBytes);
    on<ClearExportedBytes>(_onClearExportedBytes);
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
    // Empty Quill Delta document (single newline insert)
    const emptyDelta = '[{"insert":"\\n"}]';
    final document = DocumentEntity(
      id: now.microsecondsSinceEpoch.toString(),
      title: event.title,
      content: emptyDelta,
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

    // Count words and characters from plain text
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
      final isDeletedCurrent = state.currentDocument?.id == event.documentId;
      emit(state.copyWith(
        documents: updated,
        clearCurrentDocument: isDeletedCurrent,
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

  void _onToggleToolbar(
    ToggleToolbar event,
    Emitter<DocumentEditorState> emit,
  ) {
    emit(state.copyWith(showToolbar: !state.showToolbar));
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
    // Find/replace operates on plain text but the actual replacement
    // should be done via the Quill controller in the UI layer.
    // The BLoC only tracks match positions.
    // The UI calls UpdateDocumentContent after performing the replacement.
    if (state.currentDocument == null || event.find.isEmpty) return;

    // Update find matches after replacement is applied externally
    if (state.findQuery.isNotEmpty) {
      add(FindInDocument(state.findQuery));
    }
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

  // --- Import/Export ---

  Future<void> _onExportDocx(
    ExportDocx event,
    Emitter<DocumentEditorState> emit,
  ) async {
    if (state.currentDocument == null) return;
    emit(state.copyWith(
      status: DocumentEditorStatus.exporting,
      progressMessage: 'Generating DOCX...',
    ));
    try {
      final title = state.currentDocument!.title;
      final plainText = state.currentDocument!.plainText;
      final deltaJson = state.currentDocument!.content;

      // Generate DOCX bytes using DocxService
      final bytes = DocxService.exportFromDelta(
        deltaJson: deltaJson,
        plainText: plainText,
        title: title,
      );

      emit(state.copyWith(
        status: DocumentEditorStatus.exported,
        exportedBytes: bytes,
        exportedFileName: '${_sanitizeFileName(title)}.docx',
        exportedMimeType:
            'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
        progressMessage: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: DocumentEditorStatus.error,
        errorMessage: 'DOCX export failed: $e',
        progressMessage: null,
      ));
    }
  }

  Future<void> _onExportPdf(
    ExportPdf event,
    Emitter<DocumentEditorState> emit,
  ) async {
    if (state.currentDocument == null) return;
    emit(state.copyWith(
      status: DocumentEditorStatus.exporting,
      progressMessage: 'Generating PDF...',
    ));
    try {
      final title = state.currentDocument!.title;
      final plainText = state.currentDocument!.plainText;
      final deltaJson = state.currentDocument!.content;

      // Generate PDF bytes using PdfExportService
      final bytes = await PdfExportService.exportFromDelta(
        deltaJson: deltaJson,
        plainText: plainText,
        title: title,
      );

      emit(state.copyWith(
        status: DocumentEditorStatus.exported,
        exportedBytes: bytes,
        exportedFileName: '${_sanitizeFileName(title)}.pdf',
        exportedMimeType: 'application/pdf',
        progressMessage: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: DocumentEditorStatus.error,
        errorMessage: 'PDF export failed: $e',
        progressMessage: null,
      ));
    }
  }

  Future<void> _onImportDocx(
    ImportDocx event,
    Emitter<DocumentEditorState> emit,
  ) async {
    emit(state.copyWith(
      status: DocumentEditorStatus.importing,
      progressMessage: 'Importing DOCX...',
    ));
    try {
      final result = DocxService.importToDocument(
        fileBytes: event.fileBytes,
        fileName: event.fileName,
      );

      final now = DateTime.now();
      final title = result['title'] ?? event.fileName.replaceAll('.docx', '');
      final deltaJson = result['deltaJson'] as String;
      final plainText = result['plainText'] as String;

      final document = DocumentEntity(
        id: now.microsecondsSinceEpoch.toString(),
        title: title,
        content: deltaJson,
        plainText: plainText,
        format: 'rich',
        wordCount: _countWords(plainText),
        characterCount: plainText.length,
        createdAt: now,
        modifiedAt: now,
      );

      await _documentDao.insertDocument(document);

      emit(state.copyWith(
        status: DocumentEditorStatus.editing,
        currentDocument: document,
        hasUnsavedChanges: false,
        wordCount: document.wordCount,
        characterCount: document.characterCount,
        progressMessage: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: DocumentEditorStatus.error,
        errorMessage: 'DOCX import failed: $e',
        progressMessage: null,
      ));
    }
  }

  Future<void> _onImportTextFile(
    ImportTextFile event,
    Emitter<DocumentEditorState> emit,
  ) async {
    emit(state.copyWith(
      status: DocumentEditorStatus.importing,
      progressMessage: 'Importing file...',
    ));
    try {
      final now = DateTime.now();
      final title = event.fileName
          .replaceAll('.txt', '')
          .replaceAll('.md', '')
          .replaceAll('.markdown', '');

      // Convert plain text to Quill Delta JSON
      final deltaJson = jsonEncode([
        {'insert': '${event.content}\n'}
      ]);

      final document = DocumentEntity(
        id: now.microsecondsSinceEpoch.toString(),
        title: title,
        content: deltaJson,
        plainText: event.content,
        format: event.format == 'md' ? 'markdown' : 'rich',
        wordCount: _countWords(event.content),
        characterCount: event.content.length,
        createdAt: now,
        modifiedAt: now,
      );

      await _documentDao.insertDocument(document);

      emit(state.copyWith(
        status: DocumentEditorStatus.editing,
        currentDocument: document,
        hasUnsavedChanges: false,
        wordCount: document.wordCount,
        characterCount: document.characterCount,
        progressMessage: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: DocumentEditorStatus.error,
        errorMessage: 'Import failed: $e',
        progressMessage: null,
      ));
    }
  }

  void _onSetExportedBytes(
    SetExportedBytes event,
    Emitter<DocumentEditorState> emit,
  ) {
    emit(state.copyWith(
      status: DocumentEditorStatus.exported,
      exportedBytes: event.bytes,
      exportedFileName: event.fileName,
      exportedMimeType: event.mimeType,
    ));
  }

  void _onClearExportedBytes(
    ClearExportedBytes event,
    Emitter<DocumentEditorState> emit,
  ) {
    emit(state.copyWith(
      status: DocumentEditorStatus.editing,
    ));
  }

  int _countWords(String text) {
    if (text.trim().isEmpty) return 0;
    return text.trim().split(RegExp(r'\s+')).length;
  }

  String _sanitizeFileName(String name) {
    return name
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
        .replaceAll(RegExp(r'\s+'), '_')
        .toLowerCase();
  }

  @override
  Future<void> close() {
    _autoSaveTimer?.cancel();
    return super.close();
  }
}
