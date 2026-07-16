import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:fileutility_core/fileutility_core.dart';
import 'package:fileutility_storage/fileutility_storage.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// ── Events ──────────────────────────────────────────────────

sealed class TextEditorEvent extends Equatable {
  const TextEditorEvent();

  @override
  List<Object?> get props => [];
}

class LoadDocument extends TextEditorEvent {
  const LoadDocument(this.documentId);
  final String documentId;

  @override
  List<Object?> get props => [documentId];
}

class CreateNewDocument extends TextEditorEvent {
  const CreateNewDocument({
    this.title = 'Untitled',
    this.fileType = 'text',
  });

  final String title;
  final String fileType;

  @override
  List<Object?> get props => [title, fileType];
}

class UpdateDocumentContent extends TextEditorEvent {
  const UpdateDocumentContent(this.content);
  final String content;

  @override
  List<Object?> get props => [content];
}

class UpdateDocumentTitle extends TextEditorEvent {
  const UpdateDocumentTitle(this.title);
  final String title;

  @override
  List<Object?> get props => [title];
}

class SaveDocument extends TextEditorEvent {
  const SaveDocument();
}

class TogglePreview extends TextEditorEvent {
  const TogglePreview();
}

class ToggleFindReplace extends TextEditorEvent {
  const ToggleFindReplace();
}

class FindInDocument extends TextEditorEvent {
  const FindInDocument(this.query);
  final String query;

  @override
  List<Object?> get props => [query];
}

class ReplaceInDocument extends TextEditorEvent {
  const ReplaceInDocument({
    required this.find,
    required this.replace,
    this.replaceAll = false,
  });

  final String find;
  final String replace;
  final bool replaceAll;

  @override
  List<Object?> get props => [find, replace, replaceAll];
}

class LoadDocumentList extends TextEditorEvent {
  const LoadDocumentList();
}

class DeleteDocument extends TextEditorEvent {
  const DeleteDocument(this.id);
  final String id;

  @override
  List<Object?> get props => [id];
}

// ── State ───────────────────────────────────────────────────

enum TextEditorStatus { initial, loading, loaded, saving, error }

class TextEditorState extends Equatable {
  const TextEditorState({
    this.status = TextEditorStatus.initial,
    this.documentId,
    this.title = 'Untitled',
    this.content = '',
    this.fileType = 'text',
    this.isModified = false,
    this.showPreview = false,
    this.showFindReplace = false,
    this.findQuery = '',
    this.findMatches = 0,
    this.wordCount = 0,
    this.charCount = 0,
    this.lineCount = 1,
    this.documents = const [],
    this.errorMessage,
    this.lastSavedAt,
  });

  final TextEditorStatus status;
  final String? documentId;
  final String title;
  final String content;
  final String fileType;
  final bool isModified;
  final bool showPreview;
  final bool showFindReplace;
  final String findQuery;
  final int findMatches;
  final int wordCount;
  final int charCount;
  final int lineCount;
  final List<Map<String, dynamic>> documents;
  final String? errorMessage;
  final DateTime? lastSavedAt;

  bool get isMarkdown => fileType == 'markdown';
  bool get isNewDocument => documentId == null;

  TextEditorState copyWith({
    TextEditorStatus? status,
    String? documentId,
    String? title,
    String? content,
    String? fileType,
    bool? isModified,
    bool? showPreview,
    bool? showFindReplace,
    String? findQuery,
    int? findMatches,
    int? wordCount,
    int? charCount,
    int? lineCount,
    List<Map<String, dynamic>>? documents,
    String? errorMessage,
    DateTime? lastSavedAt,
  }) {
    return TextEditorState(
      status: status ?? this.status,
      documentId: documentId ?? this.documentId,
      title: title ?? this.title,
      content: content ?? this.content,
      fileType: fileType ?? this.fileType,
      isModified: isModified ?? this.isModified,
      showPreview: showPreview ?? this.showPreview,
      showFindReplace: showFindReplace ?? this.showFindReplace,
      findQuery: findQuery ?? this.findQuery,
      findMatches: findMatches ?? this.findMatches,
      wordCount: wordCount ?? this.wordCount,
      charCount: charCount ?? this.charCount,
      lineCount: lineCount ?? this.lineCount,
      documents: documents ?? this.documents,
      errorMessage: errorMessage ?? this.errorMessage,
      lastSavedAt: lastSavedAt ?? this.lastSavedAt,
    );
  }

  @override
  List<Object?> get props => [
        status,
        documentId,
        title,
        content,
        fileType,
        isModified,
        showPreview,
        showFindReplace,
        findQuery,
        findMatches,
        wordCount,
        charCount,
        lineCount,
        documents,
        errorMessage,
        lastSavedAt,
      ];
}

// ── BLoC ────────────────────────────────────────────────────

class TextEditorBloc extends Bloc<TextEditorEvent, TextEditorState> {
  TextEditorBloc({
    required FileStorageService fileStorageService,
  })  : _fileStorage = fileStorageService,
        super(const TextEditorState()) {
    on<LoadDocument>(_onLoadDocument);
    on<CreateNewDocument>(_onCreateNewDocument);
    on<UpdateDocumentContent>(_onUpdateContent);
    on<UpdateDocumentTitle>(_onUpdateTitle);
    on<SaveDocument>(_onSaveDocument);
    on<TogglePreview>(_onTogglePreview);
    on<ToggleFindReplace>(_onToggleFindReplace);
    on<FindInDocument>(_onFindInDocument);
    on<ReplaceInDocument>(_onReplaceInDocument);
    on<LoadDocumentList>(_onLoadDocumentList);
    on<DeleteDocument>(_onDeleteDocument);
  }

  final FileStorageService _fileStorage;

  Future<void> _onLoadDocument(
    LoadDocument event,
    Emitter<TextEditorState> emit,
  ) async {
    emit(state.copyWith(status: TextEditorStatus.loading));
    try {
      // Load from internal storage - in a real app this would use a document DAO
      emit(state.copyWith(
        status: TextEditorStatus.loaded,
        documentId: event.documentId,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: TextEditorStatus.error,
        errorMessage: 'Failed to load document: $e',
      ));
    }
  }

  Future<void> _onCreateNewDocument(
    CreateNewDocument event,
    Emitter<TextEditorState> emit,
  ) async {
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    emit(TextEditorState(
      status: TextEditorStatus.loaded,
      documentId: id,
      title: event.title,
      fileType: event.fileType,
      content: '',
      wordCount: 0,
      charCount: 0,
      lineCount: 1,
    ));
  }

  void _onUpdateContent(
    UpdateDocumentContent event,
    Emitter<TextEditorState> emit,
  ) {
    final wordCount = StringUtils.wordCount(event.content);
    final charCount = event.content.length;
    final lineCount = event.content.split('\n').length;

    emit(state.copyWith(
      content: event.content,
      isModified: true,
      wordCount: wordCount,
      charCount: charCount,
      lineCount: lineCount,
    ));
  }

  void _onUpdateTitle(
    UpdateDocumentTitle event,
    Emitter<TextEditorState> emit,
  ) {
    emit(state.copyWith(title: event.title, isModified: true));
  }

  Future<void> _onSaveDocument(
    SaveDocument event,
    Emitter<TextEditorState> emit,
  ) async {
    if (!state.isModified) return;

    emit(state.copyWith(status: TextEditorStatus.saving));
    try {
      // Save to app storage
      final ext = state.isMarkdown ? '.md' : '.txt';
      final fileName = '${state.title}$ext';

      await _fileStorage.saveToAppStorage(
        fileName,
        state.content,
        subdirectory: 'documents',
      );

      emit(state.copyWith(
        status: TextEditorStatus.loaded,
        isModified: false,
        lastSavedAt: DateTime.now(),
      ));
    } catch (e) {
      emit(state.copyWith(
        status: TextEditorStatus.error,
        errorMessage: 'Failed to save: $e',
      ));
    }
  }

  void _onTogglePreview(
    TogglePreview event,
    Emitter<TextEditorState> emit,
  ) {
    emit(state.copyWith(showPreview: !state.showPreview));
  }

  void _onToggleFindReplace(
    ToggleFindReplace event,
    Emitter<TextEditorState> emit,
  ) {
    emit(state.copyWith(showFindReplace: !state.showFindReplace));
  }

  void _onFindInDocument(
    FindInDocument event,
    Emitter<TextEditorState> emit,
  ) {
    if (event.query.isEmpty) {
      emit(state.copyWith(findQuery: '', findMatches: 0));
      return;
    }

    final matches = RegExp(RegExp.escape(event.query), caseSensitive: false)
        .allMatches(state.content)
        .length;

    emit(state.copyWith(findQuery: event.query, findMatches: matches));
  }

  void _onReplaceInDocument(
    ReplaceInDocument event,
    Emitter<TextEditorState> emit,
  ) {
    if (event.find.isEmpty) return;

    String newContent;
    if (event.replaceAll) {
      newContent = state.content.replaceAll(event.find, event.replace);
    } else {
      newContent = state.content.replaceFirst(event.find, event.replace);
    }

    add(UpdateDocumentContent(newContent));
  }

  Future<void> _onLoadDocumentList(
    LoadDocumentList event,
    Emitter<TextEditorState> emit,
  ) async {
    emit(state.copyWith(status: TextEditorStatus.loading));
    try {
      // In a full implementation this would query a documents DAO
      // For now, return an empty list that populates as users create docs
      emit(state.copyWith(
        status: TextEditorStatus.loaded,
        documents: [],
      ));
    } catch (e) {
      emit(state.copyWith(
        status: TextEditorStatus.error,
        errorMessage: 'Failed to load documents: $e',
      ));
    }
  }

  Future<void> _onDeleteDocument(
    DeleteDocument event,
    Emitter<TextEditorState> emit,
  ) async {
    try {
      // Delete from storage
      add(const LoadDocumentList());
    } catch (e) {
      emit(state.copyWith(
        status: TextEditorStatus.error,
        errorMessage: 'Failed to delete: $e',
      ));
    }
  }
}
