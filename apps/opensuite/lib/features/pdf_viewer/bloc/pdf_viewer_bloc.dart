import 'dart:async';
import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:fileutility_storage/fileutility_storage.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../services/pdf_manipulation_service.dart';

// --- Events ---

sealed class PdfViewerEvent extends Equatable {
  const PdfViewerEvent();
  @override
  List<Object?> get props => [];
}

class LoadPdf extends PdfViewerEvent {
  final String filePath;
  const LoadPdf(this.filePath);
  @override
  List<Object?> get props => [filePath];
}

class GoToPage extends PdfViewerEvent {
  final int page;
  const GoToPage(this.page);
  @override
  List<Object?> get props => [page];
}

class NextPage extends PdfViewerEvent {
  const NextPage();
}

class PreviousPage extends PdfViewerEvent {
  const PreviousPage();
}

class SetZoom extends PdfViewerEvent {
  final double zoom;
  const SetZoom(this.zoom);
  @override
  List<Object?> get props => [zoom];
}

class ToggleThumbnails extends PdfViewerEvent {
  const ToggleThumbnails();
}

class SearchInPdf extends PdfViewerEvent {
  final String query;
  const SearchInPdf(this.query);
  @override
  List<Object?> get props => [query];
}

class AddAnnotation extends PdfViewerEvent {
  final PdfAnnotation annotation;
  const AddAnnotation(this.annotation);
  @override
  List<Object?> get props => [annotation];
}

class RemoveAnnotation extends PdfViewerEvent {
  final String annotationId;
  const RemoveAnnotation(this.annotationId);
  @override
  List<Object?> get props => [annotationId];
}

class RotatePage extends PdfViewerEvent {
  final int page;
  final int degrees; // 90, 180, 270
  const RotatePage(this.page, this.degrees);
  @override
  List<Object?> get props => [page, degrees];
}

class SetPageRange extends PdfViewerEvent {
  final int startPage;
  final int endPage;
  const SetPageRange(this.startPage, this.endPage);
  @override
  List<Object?> get props => [startPage, endPage];
}

class SetTotalPages extends PdfViewerEvent {
  final int totalPages;
  const SetTotalPages(this.totalPages);
  @override
  List<Object?> get props => [totalPages];
}

class ClosePdf extends PdfViewerEvent {
  const ClosePdf();
}

class SaveAnnotations extends PdfViewerEvent {
  const SaveAnnotations();
}

class LoadAnnotations extends PdfViewerEvent {
  const LoadAnnotations();
}

class ToggleAnnotationMode extends PdfViewerEvent {
  final String mode; // 'highlight', 'underline', 'note', 'freehand', 'none'
  const ToggleAnnotationMode(this.mode);
  @override
  List<Object?> get props => [mode];
}

class UpdateAnnotation extends PdfViewerEvent {
  final PdfAnnotation annotation;
  const UpdateAnnotation(this.annotation);
  @override
  List<Object?> get props => [annotation];
}

// --- Sprint 18: PDF Manipulation Events ---

class MergePdfs extends PdfViewerEvent {
  final List<Uint8List> pdfBytesList;
  const MergePdfs(this.pdfBytesList);
  @override
  List<Object?> get props => [pdfBytesList];
}

class SplitPdf extends PdfViewerEvent {
  final Uint8List pdfBytes;
  const SplitPdf(this.pdfBytes);
  @override
  List<Object?> get props => [pdfBytes];
}

class ExtractPages extends PdfViewerEvent {
  final Uint8List pdfBytes;
  final List<int> pageIndices;
  const ExtractPages(this.pdfBytes, this.pageIndices);
  @override
  List<Object?> get props => [pdfBytes, pageIndices];
}

class DeletePages extends PdfViewerEvent {
  final Uint8List pdfBytes;
  final List<int> pageIndicesToDelete;
  const DeletePages(this.pdfBytes, this.pageIndicesToDelete);
  @override
  List<Object?> get props => [pdfBytes, pageIndicesToDelete];
}

class AddBookmark extends PdfViewerEvent {
  final String label;
  final int page;
  const AddBookmark(this.label, this.page);
  @override
  List<Object?> get props => [label, page];
}

class RemoveBookmark extends PdfViewerEvent {
  final int index;
  const RemoveBookmark(this.index);
  @override
  List<Object?> get props => [index];
}

class ClearPdfExport extends PdfViewerEvent {
  const ClearPdfExport();
}

// --- Models ---

class PdfAnnotation extends Equatable {
  final String id;
  final int page;
  final String type; // 'highlight', 'underline', 'note', 'freehand'
  final double x;
  final double y;
  final double width;
  final double height;
  final String? text;
  final String color;
  final List<List<double>>? strokePoints; // For freehand

  const PdfAnnotation({
    required this.id,
    required this.page,
    required this.type,
    this.x = 0,
    this.y = 0,
    this.width = 0,
    this.height = 0,
    this.text,
    this.color = '#FFFF00',
    this.strokePoints,
  });

  PdfAnnotation copyWith({
    String? id,
    int? page,
    String? type,
    double? x,
    double? y,
    double? width,
    double? height,
    String? text,
    String? color,
    List<List<double>>? strokePoints,
  }) {
    return PdfAnnotation(
      id: id ?? this.id,
      page: page ?? this.page,
      type: type ?? this.type,
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      text: text ?? this.text,
      color: color ?? this.color,
      strokePoints: strokePoints ?? this.strokePoints,
    );
  }

  @override
  List<Object?> get props => [id, page, type, x, y];
}

// --- State ---

enum PdfViewerStatus { initial, loading, loaded, error }

class PdfViewerState extends Equatable {
  final PdfViewerStatus status;
  final String? filePath;
  final int currentPage;
  final int totalPages;
  final double zoom;
  final bool showThumbnails;
  final String searchQuery;
  final List<int> searchResults; // Page numbers with matches
  final List<PdfAnnotation> annotations;
  final Map<int, int> pageRotations; // page -> degrees
  final String? errorMessage;
  final String
      annotationMode; // 'none', 'highlight', 'underline', 'note', 'freehand'
  final int? extractStartPage;
  final int? extractEndPage;
  final List<PdfBookmark> bookmarks;
  final Uint8List? exportedPdfBytes;
  final String? exportedPdfFileName;

  const PdfViewerState({
    this.status = PdfViewerStatus.initial,
    this.filePath,
    this.currentPage = 1,
    this.totalPages = 0,
    this.zoom = 1.0,
    this.showThumbnails = false,
    this.searchQuery = '',
    this.searchResults = const [],
    this.annotations = const [],
    this.pageRotations = const {},
    this.errorMessage,
    this.annotationMode = 'none',
    this.extractStartPage,
    this.extractEndPage,
    this.bookmarks = const [],
    this.exportedPdfBytes,
    this.exportedPdfFileName,
  });

  PdfViewerState copyWith({
    PdfViewerStatus? status,
    String? filePath,
    int? currentPage,
    int? totalPages,
    double? zoom,
    bool? showThumbnails,
    String? searchQuery,
    List<int>? searchResults,
    List<PdfAnnotation>? annotations,
    Map<int, int>? pageRotations,
    String? errorMessage,
    String? annotationMode,
    int? extractStartPage,
    int? extractEndPage,
    List<PdfBookmark>? bookmarks,
    Uint8List? exportedPdfBytes,
    String? exportedPdfFileName,
  }) {
    return PdfViewerState(
      status: status ?? this.status,
      filePath: filePath ?? this.filePath,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      zoom: zoom ?? this.zoom,
      showThumbnails: showThumbnails ?? this.showThumbnails,
      searchQuery: searchQuery ?? this.searchQuery,
      searchResults: searchResults ?? this.searchResults,
      annotations: annotations ?? this.annotations,
      pageRotations: pageRotations ?? this.pageRotations,
      errorMessage: errorMessage ?? this.errorMessage,
      annotationMode: annotationMode ?? this.annotationMode,
      extractStartPage: extractStartPage ?? this.extractStartPage,
      extractEndPage: extractEndPage ?? this.extractEndPage,
      bookmarks: bookmarks ?? this.bookmarks,
      exportedPdfBytes: exportedPdfBytes,
      exportedPdfFileName: exportedPdfFileName,
    );
  }

  /// Annotations for the current page.
  List<PdfAnnotation> get currentPageAnnotations =>
      annotations.where((a) => a.page == currentPage).toList();

  @override
  List<Object?> get props => [
        status,
        filePath,
        currentPage,
        totalPages,
        zoom,
        showThumbnails,
        searchQuery,
        annotations,
        pageRotations,
        annotationMode,
      ];
}

// --- BLoC ---

class PdfViewerBloc extends Bloc<PdfViewerEvent, PdfViewerState> {
  final PdfAnnotationDao? _annotationDao;

  PdfViewerBloc({PdfAnnotationDao? annotationDao})
      : _annotationDao = annotationDao,
        super(const PdfViewerState()) {
    on<LoadPdf>(_onLoad);
    on<GoToPage>(_onGoToPage);
    on<NextPage>(_onNextPage);
    on<PreviousPage>(_onPreviousPage);
    on<SetZoom>(_onSetZoom);
    on<ToggleThumbnails>(_onToggleThumbnails);
    on<SearchInPdf>(_onSearch);
    on<AddAnnotation>(_onAddAnnotation);
    on<RemoveAnnotation>(_onRemoveAnnotation);
    on<UpdateAnnotation>(_onUpdateAnnotation);
    on<RotatePage>(_onRotatePage);
    on<SetPageRange>(_onSetPageRange);
    on<SetTotalPages>(_onSetTotalPages);
    on<ClosePdf>(_onClose);
    on<SaveAnnotations>(_onSaveAnnotations);
    on<LoadAnnotations>(_onLoadAnnotations);
    on<ToggleAnnotationMode>(_onToggleAnnotationMode);
    on<MergePdfs>(_onMergePdfs);
    on<SplitPdf>(_onSplitPdf);
    on<ExtractPages>(_onExtractPages);
    on<DeletePages>(_onDeletePages);
    on<AddBookmark>(_onAddBookmark);
    on<RemoveBookmark>(_onRemoveBookmark);
    on<ClearPdfExport>(_onClearPdfExport);
  }

  Future<void> _onLoad(LoadPdf event, Emitter<PdfViewerState> emit) async {
    emit(state.copyWith(
      status: PdfViewerStatus.loading,
      filePath: event.filePath,
      annotations: const [],
    ));
    // The actual PDF loading is done by pdfrx PdfViewer widget.
    // We transition to loaded state — totalPages will be set by
    // SetTotalPages event from the widget's onDocumentLoaded callback.
    emit(state.copyWith(
      status: PdfViewerStatus.loaded,
      currentPage: 1,
    ));

    // Load persisted annotations for this file
    add(const LoadAnnotations());
  }

  void _onSetTotalPages(SetTotalPages event, Emitter<PdfViewerState> emit) {
    emit(state.copyWith(totalPages: event.totalPages));
  }

  void _onGoToPage(GoToPage event, Emitter<PdfViewerState> emit) {
    final maxPage = state.totalPages > 0 ? state.totalPages : 1;
    if (event.page >= 1 && event.page <= maxPage) {
      emit(state.copyWith(currentPage: event.page));
    }
  }

  void _onNextPage(NextPage event, Emitter<PdfViewerState> emit) {
    if (state.currentPage < state.totalPages) {
      emit(state.copyWith(currentPage: state.currentPage + 1));
    }
  }

  void _onPreviousPage(PreviousPage event, Emitter<PdfViewerState> emit) {
    if (state.currentPage > 1) {
      emit(state.copyWith(currentPage: state.currentPage - 1));
    }
  }

  void _onSetZoom(SetZoom event, Emitter<PdfViewerState> emit) {
    emit(state.copyWith(zoom: event.zoom.clamp(0.25, 5.0)));
  }

  void _onToggleThumbnails(
      ToggleThumbnails event, Emitter<PdfViewerState> emit) {
    emit(state.copyWith(showThumbnails: !state.showThumbnails));
  }

  void _onSearch(SearchInPdf event, Emitter<PdfViewerState> emit) {
    emit(state.copyWith(searchQuery: event.query));
  }

  void _onAddAnnotation(AddAnnotation event, Emitter<PdfViewerState> emit) {
    emit(state.copyWith(
      annotations: [...state.annotations, event.annotation],
    ));
    // Auto-persist
    add(const SaveAnnotations());
  }

  void _onRemoveAnnotation(
      RemoveAnnotation event, Emitter<PdfViewerState> emit) {
    emit(state.copyWith(
      annotations:
          state.annotations.where((a) => a.id != event.annotationId).toList(),
    ));
    add(const SaveAnnotations());
  }

  void _onUpdateAnnotation(
      UpdateAnnotation event, Emitter<PdfViewerState> emit) {
    emit(state.copyWith(
      annotations: state.annotations
          .map((a) => a.id == event.annotation.id ? event.annotation : a)
          .toList(),
    ));
    add(const SaveAnnotations());
  }

  void _onRotatePage(RotatePage event, Emitter<PdfViewerState> emit) {
    final rotations = Map<int, int>.from(state.pageRotations);
    final current = rotations[event.page] ?? 0;
    rotations[event.page] = (current + event.degrees) % 360;
    emit(state.copyWith(pageRotations: rotations));
  }

  /// FIX: Was an empty method body. Now stores the page range for extract/split operations.
  void _onSetPageRange(SetPageRange event, Emitter<PdfViewerState> emit) {
    final start =
        event.startPage.clamp(1, state.totalPages > 0 ? state.totalPages : 1);
    final end =
        event.endPage.clamp(start, state.totalPages > 0 ? state.totalPages : 1);
    emit(state.copyWith(
      extractStartPage: start,
      extractEndPage: end,
    ));
  }

  void _onClose(ClosePdf event, Emitter<PdfViewerState> emit) {
    emit(const PdfViewerState());
  }

  void _onToggleAnnotationMode(
      ToggleAnnotationMode event, Emitter<PdfViewerState> emit) {
    final newMode = state.annotationMode == event.mode ? 'none' : event.mode;
    emit(state.copyWith(annotationMode: newMode));
  }

  /// Persists annotations to SQLite via PdfAnnotationDao.
  Future<void> _onSaveAnnotations(
      SaveAnnotations event, Emitter<PdfViewerState> emit) async {
    if (_annotationDao == null || state.filePath == null) return;
    try {
      final now = DateTime.now();
      // Delete existing annotations for this file, then insert current ones
      final entities = state.annotations
          .map((a) => PdfAnnotationEntity(
                id: a.id,
                filePath: state.filePath!,
                pageNumber: a.page,
                type: a.type,
                x: a.x,
                y: a.y,
                width: a.width,
                height: a.height,
                content: a.text ?? '',
                color: a.color,
                createdAt: now,
                modifiedAt: now,
              ))
          .toList();

      // Clear and re-insert (simple strategy for small annotation counts)
      await _annotationDao!.deleteAllForFile(state.filePath!);
      for (final entity in entities) {
        await _annotationDao!.insertAnnotation(entity);
      }
    } catch (_) {
      // Silent failure for annotation persistence — don't disrupt viewing
    }
  }

  /// Loads persisted annotations from SQLite.
  Future<void> _onLoadAnnotations(
      LoadAnnotations event, Emitter<PdfViewerState> emit) async {
    if (_annotationDao == null || state.filePath == null) return;
    try {
      final entities =
          await _annotationDao!.getAnnotationsForFile(state.filePath!);
      final annotations = entities
          .map((e) => PdfAnnotation(
                id: e.id,
                page: e.pageNumber,
                type: e.type,
                x: e.x,
                y: e.y,
                width: e.width,
                height: e.height,
                text: e.content,
                color: e.color ?? '#FFFF00',
              ))
          .toList();
      emit(state.copyWith(annotations: annotations));
    } catch (_) {
      // Silent failure
    }
  }

  // --- PDF Manipulation Handlers ---

  Future<void> _onMergePdfs(
      MergePdfs event, Emitter<PdfViewerState> emit) async {
    try {
      final merged = await PdfManipulationService.mergePdfs(event.pdfBytesList);
      emit(state.copyWith(
        exportedPdfBytes: merged,
        exportedPdfFileName: 'merged.pdf',
      ));
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Merge failed: $e'));
    }
  }

  Future<void> _onSplitPdf(
      SplitPdf event, Emitter<PdfViewerState> emit) async {
    try {
      final pages = await PdfManipulationService.splitPdf(event.pdfBytes);
      // Export the first split page; full split exposes all pages
      if (pages.isNotEmpty) {
        emit(state.copyWith(
          exportedPdfBytes: pages.first,
          exportedPdfFileName: 'split_page_1.pdf',
        ));
      }
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Split failed: $e'));
    }
  }

  Future<void> _onExtractPages(
      ExtractPages event, Emitter<PdfViewerState> emit) async {
    try {
      final extracted = await PdfManipulationService.extractPages(
        event.pdfBytes,
        event.pageIndices,
      );
      emit(state.copyWith(
        exportedPdfBytes: extracted,
        exportedPdfFileName: 'extracted_pages.pdf',
      ));
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Extract failed: $e'));
    }
  }

  Future<void> _onDeletePages(
      DeletePages event, Emitter<PdfViewerState> emit) async {
    try {
      final result = await PdfManipulationService.deletePages(
        event.pdfBytes,
        event.pageIndicesToDelete,
      );
      emit(state.copyWith(
        exportedPdfBytes: result,
        exportedPdfFileName: 'modified.pdf',
      ));
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Delete pages failed: $e'));
    }
  }

  void _onAddBookmark(
      AddBookmark event, Emitter<PdfViewerState> emit) {
    final updated = List<PdfBookmark>.from(state.bookmarks)
      ..add(PdfBookmark(label: event.label, page: event.page));
    emit(state.copyWith(bookmarks: updated));
  }

  void _onRemoveBookmark(
      RemoveBookmark event, Emitter<PdfViewerState> emit) {
    if (event.index < 0 || event.index >= state.bookmarks.length) return;
    final updated = List<PdfBookmark>.from(state.bookmarks)
      ..removeAt(event.index);
    emit(state.copyWith(bookmarks: updated));
  }

  void _onClearPdfExport(
      ClearPdfExport event, Emitter<PdfViewerState> emit) {
    emit(state.copyWith());
  }
}

/// Bookmark model for PDF navigation.
class PdfBookmark extends Equatable {
  final String label;
  final int page;

  const PdfBookmark({required this.label, required this.page});

  @override
  List<Object?> get props => [label, page];
}
