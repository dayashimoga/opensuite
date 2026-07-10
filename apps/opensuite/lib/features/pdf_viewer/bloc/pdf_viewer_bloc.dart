import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
    );
  }

  @override
  List<Object?> get props => [status, filePath, currentPage, totalPages,
    zoom, showThumbnails, searchQuery, annotations, pageRotations];
}

// --- BLoC ---

class PdfViewerBloc extends Bloc<PdfViewerEvent, PdfViewerState> {
  PdfViewerBloc() : super(const PdfViewerState()) {
    on<LoadPdf>(_onLoad);
    on<GoToPage>(_onGoToPage);
    on<NextPage>(_onNextPage);
    on<PreviousPage>(_onPreviousPage);
    on<SetZoom>(_onSetZoom);
    on<ToggleThumbnails>(_onToggleThumbnails);
    on<SearchInPdf>(_onSearch);
    on<AddAnnotation>(_onAddAnnotation);
    on<RemoveAnnotation>(_onRemoveAnnotation);
    on<RotatePage>(_onRotatePage);
    on<SetPageRange>(_onSetPageRange);
  }

  Future<void> _onLoad(LoadPdf event, Emitter<PdfViewerState> emit) async {
    emit(state.copyWith(status: PdfViewerStatus.loading, filePath: event.filePath));
    try {
      // In a real implementation, we'd use pdfrx/pdf_render to load the PDF.
      // For now, we set up the viewer state. The actual rendering is done
      // by the PdfViewer widget in the page layer.
      emit(state.copyWith(
        status: PdfViewerStatus.loaded,
        currentPage: 1,
        totalPages: 1, // Will be set by the viewer widget
      ));
    } catch (e) {
      emit(state.copyWith(status: PdfViewerStatus.error, errorMessage: '$e'));
    }
  }

  void _onGoToPage(GoToPage event, Emitter<PdfViewerState> emit) {
    if (event.page >= 1 && event.page <= state.totalPages) {
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

  void _onToggleThumbnails(ToggleThumbnails event, Emitter<PdfViewerState> emit) {
    emit(state.copyWith(showThumbnails: !state.showThumbnails));
  }

  void _onSearch(SearchInPdf event, Emitter<PdfViewerState> emit) {
    emit(state.copyWith(searchQuery: event.query));
    // Actual text search would be performed via the PDF rendering engine
  }

  void _onAddAnnotation(AddAnnotation event, Emitter<PdfViewerState> emit) {
    emit(state.copyWith(
      annotations: [...state.annotations, event.annotation],
    ));
  }

  void _onRemoveAnnotation(RemoveAnnotation event, Emitter<PdfViewerState> emit) {
    emit(state.copyWith(
      annotations: state.annotations.where((a) => a.id != event.annotationId).toList(),
    ));
  }

  void _onRotatePage(RotatePage event, Emitter<PdfViewerState> emit) {
    final rotations = Map<int, int>.from(state.pageRotations);
    final current = rotations[event.page] ?? 0;
    rotations[event.page] = (current + event.degrees) % 360;
    emit(state.copyWith(pageRotations: rotations));
  }

  void _onSetPageRange(SetPageRange event, Emitter<PdfViewerState> emit) {
    // Used for split/extract operations — stores the selected range
    // The actual extraction is done via the page layer
  }
}
