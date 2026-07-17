import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:fileutility_core/fileutility_core.dart';
import 'package:fileutility_storage/fileutility_storage.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../services/pptx_service.dart';
import '../services/presentation_pdf_service.dart';

// --- Events ---

sealed class PresentationEvent extends Equatable {
  const PresentationEvent();
  @override
  List<Object?> get props => [];
}

class LoadPresentations extends PresentationEvent {
  const LoadPresentations();
}

class SearchPresentations extends PresentationEvent {
  final String query;
  const SearchPresentations(this.query);
  @override
  List<Object?> get props => [query];
}

class CreatePresentation extends PresentationEvent {
  final String title;
  const CreatePresentation({this.title = 'Untitled Presentation'});
  @override
  List<Object?> get props => [title];
}

class OpenPresentation extends PresentationEvent {
  final String id;
  const OpenPresentation(this.id);
  @override
  List<Object?> get props => [id];
}

class SelectSlide extends PresentationEvent {
  final int index;
  const SelectSlide(this.index);
  @override
  List<Object?> get props => [index];
}

class AddSlide extends PresentationEvent {
  final String layout;
  final List<SlideElement>? initialElements;
  const AddSlide({this.layout = 'blank', this.initialElements});
  @override
  List<Object?> get props => [layout, initialElements];
}

class DeleteSlide extends PresentationEvent {
  final int index;
  const DeleteSlide(this.index);
  @override
  List<Object?> get props => [index];
}

class DuplicateSlide extends PresentationEvent {
  final int index;
  const DuplicateSlide(this.index);
  @override
  List<Object?> get props => [index];
}

class AddElement extends PresentationEvent {
  final SlideElement element;
  const AddElement(this.element);
  @override
  List<Object?> get props => [element];
}

class UpdateElement extends PresentationEvent {
  final String elementId;
  final SlideElement element;
  const UpdateElement(this.elementId, this.element);
  @override
  List<Object?> get props => [elementId, element];
}

class UpdateElementContent extends PresentationEvent {
  final String elementId;
  final String content;
  const UpdateElementContent(this.elementId, this.content);
  @override
  List<Object?> get props => [elementId, content];
}

class DeleteElement extends PresentationEvent {
  final String elementId;
  const DeleteElement(this.elementId);
  @override
  List<Object?> get props => [elementId];
}

class SelectElement extends PresentationEvent {
  final String? elementId;
  const SelectElement(this.elementId);
  @override
  List<Object?> get props => [elementId];
}

class MoveElement extends PresentationEvent {
  final String elementId;
  final double x;
  final double y;
  const MoveElement(this.elementId, this.x, this.y);
  @override
  List<Object?> get props => [elementId, x, y];
}

class ResizeElement extends PresentationEvent {
  final String elementId;
  final double width;
  final double height;
  const ResizeElement(this.elementId, this.width, this.height);
  @override
  List<Object?> get props => [elementId, width, height];
}

class UpdateSpeakerNotes extends PresentationEvent {
  final String notes;
  const UpdateSpeakerNotes(this.notes);
  @override
  List<Object?> get props => [notes];
}

class SetSlideTransition extends PresentationEvent {
  final String transition;
  const SetSlideTransition(this.transition);
  @override
  List<Object?> get props => [transition];
}

class SetSlideBackground extends PresentationEvent {
  final String color;
  const SetSlideBackground(this.color);
  @override
  List<Object?> get props => [color];
}

class TogglePresentationMode extends PresentationEvent {
  const TogglePresentationMode();
}

class SavePresentation extends PresentationEvent {
  const SavePresentation();
}

class AutoSavePresentation extends PresentationEvent {
  const AutoSavePresentation();
}

class DeletePresentationEntry extends PresentationEvent {
  final String id;
  const DeletePresentationEntry(this.id);
  @override
  List<Object?> get props => [id];
}

class TogglePresentationFavorite extends PresentationEvent {
  final String id;
  const TogglePresentationFavorite(this.id);
  @override
  List<Object?> get props => [id];
}

class DuplicatePresentationEntry extends PresentationEvent {
  final String id;
  const DuplicatePresentationEntry(this.id);
  @override
  List<Object?> get props => [id];
}

// --- New events for Sprint 14 ---

class UndoPresentation extends PresentationEvent {
  const UndoPresentation();
}

class RedoPresentation extends PresentationEvent {
  const RedoPresentation();
}

class BringToFront extends PresentationEvent {
  final String elementId;
  const BringToFront(this.elementId);
  @override
  List<Object?> get props => [elementId];
}

class SendToBack extends PresentationEvent {
  final String elementId;
  const SendToBack(this.elementId);
  @override
  List<Object?> get props => [elementId];
}

class FormatElement extends PresentationEvent {
  final String elementId;
  final String? fontWeight;
  final String? textAlign;
  final String? textColor;
  final double? fontSize;
  final String? fillColor;
  final String? borderColor;
  final double? borderWidth;
  const FormatElement(
    this.elementId, {
    this.fontWeight,
    this.textAlign,
    this.textColor,
    this.fontSize,
    this.fillColor,
    this.borderColor,
    this.borderWidth,
  });
  @override
  List<Object?> get props => [
        elementId,
        fontWeight,
        textAlign,
        textColor,
        fontSize,
        fillColor,
        borderColor,
        borderWidth
      ];
}

class ReorderSlides extends PresentationEvent {
  final int oldIndex;
  final int newIndex;
  const ReorderSlides(this.oldIndex, this.newIndex);
  @override
  List<Object?> get props => [oldIndex, newIndex];
}

// --- Sprint 3 additions: Rotate, Align, Duplicate, Group ---

class RotateElement extends PresentationEvent {
  final String elementId;
  final double degrees;
  const RotateElement(this.elementId, this.degrees);
  @override
  List<Object?> get props => [elementId, degrees];
}

class AlignElements extends PresentationEvent {
  final String
      alignment; // 'left', 'center', 'right', 'top', 'middle', 'bottom'
  final List<String> elementIds;
  const AlignElements(this.alignment, this.elementIds);
  @override
  List<Object?> get props => [alignment, elementIds];
}

class DuplicateElement extends PresentationEvent {
  final String elementId;
  const DuplicateElement(this.elementId);
  @override
  List<Object?> get props => [elementId];
}

class GroupElements extends PresentationEvent {
  final List<String> elementIds;
  const GroupElements(this.elementIds);
  @override
  List<Object?> get props => [elementIds];
}

class UngroupElements extends PresentationEvent {
  final String groupId;
  const UngroupElements(this.groupId);
  @override
  List<Object?> get props => [groupId];
}

// --- Sprint 16: PPTX / PDF Export/Import ---

class ExportPptx extends PresentationEvent {
  const ExportPptx();
}

class ExportPresentationPdf extends PresentationEvent {
  const ExportPresentationPdf();
}

class ImportPptx extends PresentationEvent {
  final Uint8List fileBytes;
  final String fileName;
  const ImportPptx(this.fileBytes, {this.fileName = 'presentation.pptx'});
  @override
  List<Object?> get props => [fileBytes, fileName];
}

class ClearExportedPresentation extends PresentationEvent {
  const ClearExportedPresentation();
}

// --- State ---

enum PresentationStatus {
  initial,
  loading,
  loaded,
  editing,
  presenting,
  saving,
  saved,
  exporting,
  exported,
  importing,
  error
}

/// Sentinel for distinguishing 'not set' from explicit null in copyWith.
const _sentinel = Object();

class PresentationState extends Equatable {
  final PresentationStatus status;
  final List<PresentationEntity> presentations;
  final PresentationEntity? currentPresentation;
  final List<SlideData> slides;
  final int activeSlideIndex;
  final String? selectedElementId;
  final bool isPresentationMode;
  final bool showSpeakerNotes;
  final bool hasUnsavedChanges;
  final bool canUndo;
  final bool canRedo;
  final String searchQuery;
  final String? errorMessage;

  // Export state
  final Uint8List? exportedBytes;
  final String? exportedFileName;
  final String? exportedMimeType;

  const PresentationState({
    this.status = PresentationStatus.initial,
    this.presentations = const [],
    this.currentPresentation,
    this.slides = const [],
    this.activeSlideIndex = 0,
    this.selectedElementId,
    this.isPresentationMode = false,
    this.showSpeakerNotes = true,
    this.hasUnsavedChanges = false,
    this.canUndo = false,
    this.canRedo = false,
    this.searchQuery = '',
    this.errorMessage,
    this.exportedBytes,
    this.exportedFileName,
    this.exportedMimeType,
  });

  SlideData? get activeSlide =>
      activeSlideIndex < slides.length ? slides[activeSlideIndex] : null;

  PresentationState copyWith({
    PresentationStatus? status,
    List<PresentationEntity>? presentations,
    PresentationEntity? currentPresentation,
    List<SlideData>? slides,
    int? activeSlideIndex,
    Object? selectedElementId = _sentinel,
    bool? isPresentationMode,
    bool? showSpeakerNotes,
    bool? hasUnsavedChanges,
    bool? canUndo,
    bool? canRedo,
    String? searchQuery,
    String? errorMessage,
    Uint8List? exportedBytes,
    String? exportedFileName,
    String? exportedMimeType,
  }) {
    return PresentationState(
      status: status ?? this.status,
      presentations: presentations ?? this.presentations,
      currentPresentation: currentPresentation ?? this.currentPresentation,
      slides: slides ?? this.slides,
      activeSlideIndex: activeSlideIndex ?? this.activeSlideIndex,
      selectedElementId: identical(selectedElementId, _sentinel)
          ? this.selectedElementId
          : selectedElementId as String?,
      isPresentationMode: isPresentationMode ?? this.isPresentationMode,
      showSpeakerNotes: showSpeakerNotes ?? this.showSpeakerNotes,
      hasUnsavedChanges: hasUnsavedChanges ?? this.hasUnsavedChanges,
      canUndo: canUndo ?? this.canUndo,
      canRedo: canRedo ?? this.canRedo,
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: errorMessage ?? this.errorMessage,
      exportedBytes: exportedBytes,
      exportedFileName: exportedFileName,
      exportedMimeType: exportedMimeType,
    );
  }

  @override
  List<Object?> get props => [
        status,
        presentations,
        currentPresentation,
        slides,
        activeSlideIndex,
        selectedElementId,
        isPresentationMode,
        hasUnsavedChanges,
        searchQuery,
        errorMessage
      ];
}

// --- BLoC ---

class PresentationBloc extends Bloc<PresentationEvent, PresentationState> {
  final PresentationDao _dao;
  Timer? _autoSaveTimer;
  final UndoRedoManager<List<SlideData>> _undoRedo = UndoRedoManager();

  PresentationBloc({required PresentationDao presentationDao})
      : _dao = presentationDao,
        super(const PresentationState()) {
    on<LoadPresentations>(_onLoad);
    on<SearchPresentations>(_onSearch, transformer: restartable());
    on<CreatePresentation>(_onCreate);
    on<OpenPresentation>(_onOpen);
    on<SelectSlide>(_onSelectSlide);
    on<AddSlide>(_onAddSlide);
    on<DeleteSlide>(_onDeleteSlide);
    on<DuplicateSlide>(_onDuplicateSlide);
    on<AddElement>(_onAddElement);
    on<UpdateElement>(_onUpdateElement);
    on<UpdateElementContent>(_onUpdateElementContent);
    on<DeleteElement>(_onDeleteElement);
    on<SelectElement>(_onSelectElement);
    on<MoveElement>(_onMoveElement);
    on<ResizeElement>(_onResizeElement);
    on<UpdateSpeakerNotes>(_onUpdateSpeakerNotes);
    on<SetSlideTransition>(_onSetTransition);
    on<SetSlideBackground>(_onSetBackground);
    on<TogglePresentationMode>(_onTogglePresentationMode);
    on<SavePresentation>(_onSave);
    on<AutoSavePresentation>(_onAutoSave);
    on<DeletePresentationEntry>(_onDelete);
    on<TogglePresentationFavorite>(_onToggleFavorite);
    on<DuplicatePresentationEntry>(_onDuplicate);
    on<UndoPresentation>(_onUndo);
    on<RedoPresentation>(_onRedo);
    on<BringToFront>(_onBringToFront);
    on<SendToBack>(_onSendToBack);
    on<FormatElement>(_onFormatElement);
    on<ReorderSlides>(_onReorderSlides);
    on<RotateElement>(_onRotateElement);
    on<AlignElements>(_onAlignElements);
    on<DuplicateElement>(_onDuplicateElement);
    on<GroupElements>(_onGroupElements);
    on<UngroupElements>(_onUngroupElements);
    on<ExportPptx>(_onExportPptx);
    on<ExportPresentationPdf>(_onExportPdf);
    on<ImportPptx>(_onImportPptx);
    on<ClearExportedPresentation>(_onClearExported);
  }

  Future<void> _onLoad(
      LoadPresentations event, Emitter<PresentationState> emit) async {
    emit(state.copyWith(status: PresentationStatus.loading));
    try {
      final list = await _dao.getAllPresentations();
      emit(state.copyWith(
          status: PresentationStatus.loaded, presentations: list));
    } catch (e) {
      emit(
          state.copyWith(status: PresentationStatus.error, errorMessage: '$e'));
    }
  }

  Future<void> _onSearch(
      SearchPresentations event, Emitter<PresentationState> emit) async {
    emit(state.copyWith(searchQuery: event.query));
    try {
      final list = event.query.isEmpty
          ? await _dao.getAllPresentations()
          : await _dao.searchPresentations(event.query);
      emit(state.copyWith(
          status: PresentationStatus.loaded, presentations: list));
    } catch (e) {
      emit(
          state.copyWith(status: PresentationStatus.error, errorMessage: '$e'));
    }
  }

  Future<void> _onCreate(
      CreatePresentation event, Emitter<PresentationState> emit) async {
    final now = DateTime.now();
    final titleSlide = SlideData(
      id: '1',
      backgroundColor: '#1E3A5F',
      elements: [
        SlideElement(
          id: 'title_1',
          type: 'text',
          x: 0.1,
          y: 0.3,
          width: 0.8,
          height: 0.15,
          content: event.title,
          fontSize: 44,
          fontWeight: 'bold',
          textColor: '#FFFFFF',
          textAlign: 'center',
        ),
        const SlideElement(
          id: 'subtitle_1',
          type: 'text',
          x: 0.2,
          y: 0.55,
          width: 0.6,
          height: 0.1,
          content: 'Click to add subtitle',
          fontSize: 20,
          textColor: '#B0C4DE',
          textAlign: 'center',
        ),
      ],
    );

    final entity = PresentationEntity(
      id: now.microsecondsSinceEpoch.toString(),
      title: event.title,
      content: jsonEncode([titleSlide.toMap()]),
      slideCount: 1,
      createdAt: now,
      modifiedAt: now,
    );

    try {
      await _dao.insertPresentation(entity);
      emit(state.copyWith(
        status: PresentationStatus.editing,
        currentPresentation: entity,
        slides: [titleSlide],
        activeSlideIndex: 0,
        hasUnsavedChanges: false,
      ));
    } catch (e) {
      emit(
          state.copyWith(status: PresentationStatus.error, errorMessage: '$e'));
    }
  }

  Future<void> _onOpen(
      OpenPresentation event, Emitter<PresentationState> emit) async {
    emit(state.copyWith(status: PresentationStatus.loading));
    try {
      final entity = await _dao.getPresentation(event.id);
      if (entity == null) {
        emit(state.copyWith(
            status: PresentationStatus.error, errorMessage: 'Not found'));
        return;
      }
      final slidesJson = jsonDecode(entity.content) as List;
      final slides = slidesJson
          .map((s) => SlideData.fromMap(s as Map<String, dynamic>))
          .toList();
      emit(state.copyWith(
        status: PresentationStatus.editing,
        currentPresentation: entity,
        slides: slides,
        activeSlideIndex: 0,
        hasUnsavedChanges: false,
      ));
    } catch (e) {
      emit(
          state.copyWith(status: PresentationStatus.error, errorMessage: '$e'));
    }
  }

  void _onSelectSlide(SelectSlide event, Emitter<PresentationState> emit) {
    if (event.index >= 0 && event.index < state.slides.length) {
      emit(state.copyWith(
          activeSlideIndex: event.index, selectedElementId: null));
    }
  }

  void _onAddSlide(AddSlide event, Emitter<PresentationState> emit) {
    final newSlide = SlideData(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      layout: event.layout,
      elements: event.initialElements ?? const [],
    );
    final newSlides = List<SlideData>.from(state.slides)
      ..insert(state.activeSlideIndex + 1, newSlide);
    emit(state.copyWith(
      slides: newSlides,
      activeSlideIndex: state.activeSlideIndex + 1,
      hasUnsavedChanges: true,
    ));
    _scheduleAutoSave();
  }

  void _onDeleteSlide(DeleteSlide event, Emitter<PresentationState> emit) {
    if (state.slides.length <= 1) return;
    final newSlides = List<SlideData>.from(state.slides)..removeAt(event.index);
    final newIndex = state.activeSlideIndex >= newSlides.length
        ? newSlides.length - 1
        : state.activeSlideIndex;
    emit(state.copyWith(
        slides: newSlides,
        activeSlideIndex: newIndex,
        hasUnsavedChanges: true));
    _scheduleAutoSave();
  }

  void _onDuplicateSlide(
      DuplicateSlide event, Emitter<PresentationState> emit) {
    if (event.index >= 0 && event.index < state.slides.length) {
      final original = state.slides[event.index];
      final copy = SlideData(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        backgroundColor: original.backgroundColor,
        elements: original.elements
            .map((e) => SlideElement(
                  id: '${e.id}_copy_${DateTime.now().microsecond}',
                  type: e.type,
                  x: e.x,
                  y: e.y,
                  width: e.width,
                  height: e.height,
                  content: e.content,
                  fontSize: e.fontSize,
                  fontWeight: e.fontWeight,
                  textAlign: e.textAlign,
                  textColor: e.textColor,
                  fillColor: e.fillColor,
                  borderColor: e.borderColor,
                  borderWidth: e.borderWidth,
                  shapeType: e.shapeType,
                  zIndex: e.zIndex,
                ))
            .toList(),
        speakerNotes: original.speakerNotes,
        transition: original.transition,
        layout: original.layout,
      );
      final newSlides = List<SlideData>.from(state.slides)
        ..insert(event.index + 1, copy);
      emit(state.copyWith(
        slides: newSlides,
        activeSlideIndex: event.index + 1,
        hasUnsavedChanges: true,
      ));
      _scheduleAutoSave();
    }
  }

  void _onAddElement(AddElement event, Emitter<PresentationState> emit) {
    if (state.activeSlide == null) return;
    final updatedSlide = state.activeSlide!.copyWith(
      elements: [...state.activeSlide!.elements, event.element],
    );
    _updateCurrentSlide(emit, updatedSlide);
  }

  void _onUpdateElement(UpdateElement event, Emitter<PresentationState> emit) {
    if (state.activeSlide == null) return;
    final elements = state.activeSlide!.elements.map((e) {
      return e.id == event.elementId ? event.element : e;
    }).toList();
    _updateCurrentSlide(emit, state.activeSlide!.copyWith(elements: elements));
  }

  void _onUpdateElementContent(
      UpdateElementContent event, Emitter<PresentationState> emit) {
    if (state.activeSlide == null) return;
    final elements = state.activeSlide!.elements.map((e) {
      return e.id == event.elementId ? e.copyWith(content: event.content) : e;
    }).toList();
    _updateCurrentSlide(emit, state.activeSlide!.copyWith(elements: elements));
  }

  void _onDeleteElement(DeleteElement event, Emitter<PresentationState> emit) {
    if (state.activeSlide == null) return;
    final elements = state.activeSlide!.elements
        .where((e) => e.id != event.elementId)
        .toList();
    final updatedSlide = state.activeSlide!.copyWith(elements: elements);
    final newSlides = List<SlideData>.from(state.slides);
    newSlides[state.activeSlideIndex] = updatedSlide;
    emit(state.copyWith(
      slides: newSlides,
      selectedElementId: null,
      hasUnsavedChanges: true,
    ));
    _scheduleAutoSave();
  }

  void _onSelectElement(SelectElement event, Emitter<PresentationState> emit) {
    emit(state.copyWith(selectedElementId: event.elementId));
  }

  void _onMoveElement(MoveElement event, Emitter<PresentationState> emit) {
    if (state.activeSlide == null) return;
    final elements = state.activeSlide!.elements.map((e) {
      return e.id == event.elementId ? e.copyWith(x: event.x, y: event.y) : e;
    }).toList();
    _updateCurrentSlide(emit, state.activeSlide!.copyWith(elements: elements));
  }

  void _onResizeElement(ResizeElement event, Emitter<PresentationState> emit) {
    if (state.activeSlide == null) return;
    final elements = state.activeSlide!.elements.map((e) {
      return e.id == event.elementId
          ? e.copyWith(width: event.width, height: event.height)
          : e;
    }).toList();
    _updateCurrentSlide(emit, state.activeSlide!.copyWith(elements: elements));
  }

  void _onUpdateSpeakerNotes(
      UpdateSpeakerNotes event, Emitter<PresentationState> emit) {
    if (state.activeSlide == null) return;
    _updateCurrentSlide(
        emit, state.activeSlide!.copyWith(speakerNotes: event.notes));
  }

  void _onSetTransition(
      SetSlideTransition event, Emitter<PresentationState> emit) {
    if (state.activeSlide == null) return;
    _updateCurrentSlide(
        emit, state.activeSlide!.copyWith(transition: event.transition));
  }

  void _onSetBackground(
      SetSlideBackground event, Emitter<PresentationState> emit) {
    if (state.activeSlide == null) return;
    _updateCurrentSlide(
        emit, state.activeSlide!.copyWith(backgroundColor: event.color));
  }

  void _onTogglePresentationMode(
      TogglePresentationMode event, Emitter<PresentationState> emit) {
    emit(state.copyWith(
      isPresentationMode: !state.isPresentationMode,
      status: state.isPresentationMode
          ? PresentationStatus.editing
          : PresentationStatus.presenting,
    ));
  }

  void _updateCurrentSlide(
      Emitter<PresentationState> emit, SlideData updatedSlide) {
    _undoRedo.push(state.slides);
    final newSlides = List<SlideData>.from(state.slides);
    newSlides[state.activeSlideIndex] = updatedSlide;
    emit(state.copyWith(
      slides: newSlides,
      hasUnsavedChanges: true,
      canUndo: _undoRedo.canUndo,
      canRedo: _undoRedo.canRedo,
    ));
    _scheduleAutoSave();
  }

  Future<void> _onSave(
      SavePresentation event, Emitter<PresentationState> emit) async {
    if (state.currentPresentation == null) return;
    emit(state.copyWith(status: PresentationStatus.saving));
    try {
      final content = jsonEncode(state.slides.map((s) => s.toMap()).toList());
      final updated = state.currentPresentation!.copyWith(
        content: content,
        slideCount: state.slides.length,
        modifiedAt: DateTime.now(),
      );
      await _dao.updatePresentation(updated);
      emit(state.copyWith(
        status: PresentationStatus.saved,
        currentPresentation: updated,
        hasUnsavedChanges: false,
      ));
      await Future.delayed(const Duration(milliseconds: 500));
      emit(state.copyWith(status: PresentationStatus.editing));
    } catch (e) {
      emit(
          state.copyWith(status: PresentationStatus.error, errorMessage: '$e'));
    }
  }

  Future<void> _onAutoSave(
      AutoSavePresentation event, Emitter<PresentationState> emit) async {
    if (state.currentPresentation == null || !state.hasUnsavedChanges) return;
    try {
      final content = jsonEncode(state.slides.map((s) => s.toMap()).toList());
      final updated = state.currentPresentation!.copyWith(
        content: content,
        slideCount: state.slides.length,
        modifiedAt: DateTime.now(),
      );
      await _dao.updatePresentation(updated);
      emit(state.copyWith(
          currentPresentation: updated, hasUnsavedChanges: false));
    } catch (_) {}
  }

  Future<void> _onDelete(
      DeletePresentationEntry event, Emitter<PresentationState> emit) async {
    try {
      await _dao.deletePresentation(event.id);
      final updated =
          state.presentations.where((p) => p.id != event.id).toList();
      emit(state.copyWith(presentations: updated));
    } catch (e) {
      emit(
          state.copyWith(status: PresentationStatus.error, errorMessage: '$e'));
    }
  }

  Future<void> _onToggleFavorite(
      TogglePresentationFavorite event, Emitter<PresentationState> emit) async {
    try {
      await _dao.toggleFavorite(event.id);
      add(const LoadPresentations());
    } catch (e) {
      emit(
          state.copyWith(status: PresentationStatus.error, errorMessage: '$e'));
    }
  }

  Future<void> _onDuplicate(
      DuplicatePresentationEntry event, Emitter<PresentationState> emit) async {
    try {
      await _dao.duplicatePresentation(event.id);
      add(const LoadPresentations());
    } catch (e) {
      emit(
          state.copyWith(status: PresentationStatus.error, errorMessage: '$e'));
    }
  }

  void _onUndo(UndoPresentation event, Emitter<PresentationState> emit) {
    final previous = _undoRedo.undo();
    if (previous != null) {
      emit(state.copyWith(
        slides: previous,
        hasUnsavedChanges: true,
        canUndo: _undoRedo.canUndo,
        canRedo: _undoRedo.canRedo,
      ));
    }
  }

  void _onRedo(RedoPresentation event, Emitter<PresentationState> emit) {
    final next = _undoRedo.redo();
    if (next != null) {
      emit(state.copyWith(
        slides: next,
        hasUnsavedChanges: true,
        canUndo: _undoRedo.canUndo,
        canRedo: _undoRedo.canRedo,
      ));
    }
  }

  void _onBringToFront(BringToFront event, Emitter<PresentationState> emit) {
    if (state.activeSlide == null) return;
    final elements = List<SlideElement>.from(state.activeSlide!.elements);
    final idx = elements.indexWhere((e) => e.id == event.elementId);
    if (idx < 0) return;
    final maxZ =
        elements.fold<int>(0, (max, e) => e.zIndex > max ? e.zIndex : max);
    elements[idx] = elements[idx].copyWith(zIndex: maxZ + 1);
    _updateCurrentSlide(emit, state.activeSlide!.copyWith(elements: elements));
  }

  void _onSendToBack(SendToBack event, Emitter<PresentationState> emit) {
    if (state.activeSlide == null) return;
    final elements = List<SlideElement>.from(state.activeSlide!.elements);
    final idx = elements.indexWhere((e) => e.id == event.elementId);
    if (idx < 0) return;
    final minZ =
        elements.fold<int>(0, (min, e) => e.zIndex < min ? e.zIndex : min);
    elements[idx] = elements[idx].copyWith(zIndex: minZ - 1);
    _updateCurrentSlide(emit, state.activeSlide!.copyWith(elements: elements));
  }

  void _onFormatElement(FormatElement event, Emitter<PresentationState> emit) {
    if (state.activeSlide == null) return;
    final elements = state.activeSlide!.elements.map((e) {
      if (e.id != event.elementId) return e;
      return e.copyWith(
        fontWeight: event.fontWeight,
        textAlign: event.textAlign,
        textColor: event.textColor,
        fontSize: event.fontSize,
        fillColor: event.fillColor,
        borderColor: event.borderColor,
        borderWidth: event.borderWidth,
      );
    }).toList();
    _updateCurrentSlide(emit, state.activeSlide!.copyWith(elements: elements));
  }

  void _onReorderSlides(ReorderSlides event, Emitter<PresentationState> emit) {
    _undoRedo.push(state.slides);
    final slides = List<SlideData>.from(state.slides);
    final slide = slides.removeAt(event.oldIndex);
    final newIdx =
        event.newIndex > event.oldIndex ? event.newIndex - 1 : event.newIndex;
    slides.insert(newIdx, slide);
    emit(state.copyWith(
      slides: slides,
      activeSlideIndex: newIdx,
      hasUnsavedChanges: true,
      canUndo: _undoRedo.canUndo,
      canRedo: _undoRedo.canRedo,
    ));
    _scheduleAutoSave();
  }

  void _onRotateElement(RotateElement event, Emitter<PresentationState> emit) {
    if (state.activeSlide == null) return;

    final slide = state.activeSlide!;
    final elements = slide.elements.map((e) {
      if (e.id == event.elementId) {
        return e.copyWith(
          rotation: (e.rotation + event.degrees) % 360,
        );
      }
      return e;
    }).toList();

    _updateCurrentSlide(emit, slide.copyWith(elements: elements));
  }

  void _onAlignElements(AlignElements event, Emitter<PresentationState> emit) {
    if (state.activeSlide == null || event.elementIds.length < 2) return;

    final slide = state.activeSlide!;
    final targets =
        slide.elements.where((e) => event.elementIds.contains(e.id)).toList();

    if (targets.isEmpty) return;

    double? refValue;
    switch (event.alignment) {
      case 'left':
        refValue = targets.map((e) => e.x).reduce((a, b) => a < b ? a : b);
      case 'right':
        refValue =
            targets.map((e) => e.x + e.width).reduce((a, b) => a > b ? a : b);
      case 'center':
        final minX = targets.map((e) => e.x).reduce((a, b) => a < b ? a : b);
        final maxX =
            targets.map((e) => e.x + e.width).reduce((a, b) => a > b ? a : b);
        refValue = (minX + maxX) / 2;
      case 'top':
        refValue = targets.map((e) => e.y).reduce((a, b) => a < b ? a : b);
      case 'bottom':
        refValue =
            targets.map((e) => e.y + e.height).reduce((a, b) => a > b ? a : b);
      case 'middle':
        final minY = targets.map((e) => e.y).reduce((a, b) => a < b ? a : b);
        final maxY =
            targets.map((e) => e.y + e.height).reduce((a, b) => a > b ? a : b);
        refValue = (minY + maxY) / 2;
    }

    if (refValue == null) return;

    final ref = refValue;
    final elements = slide.elements.map((e) {
      if (!event.elementIds.contains(e.id)) return e;
      switch (event.alignment) {
        case 'left':
          return e.copyWith(x: ref);
        case 'right':
          return e.copyWith(x: ref - e.width);
        case 'center':
          return e.copyWith(x: ref - e.width / 2);
        case 'top':
          return e.copyWith(y: ref);
        case 'bottom':
          return e.copyWith(y: ref - e.height);
        case 'middle':
          return e.copyWith(y: ref - e.height / 2);
        default:
          return e;
      }
    }).toList();

    _updateCurrentSlide(emit, slide.copyWith(elements: elements));
  }

  void _onDuplicateElement(
      DuplicateElement event, Emitter<PresentationState> emit) {
    if (state.activeSlide == null) return;

    final slide = state.activeSlide!;
    final source = slide.elements.cast<SlideElement?>().firstWhere(
          (e) => e!.id == event.elementId,
          orElse: () => null,
        );
    if (source == null) return;

    final duplicate = source.copyWith(
      id: '${source.id}_dup_${DateTime.now().millisecondsSinceEpoch}',
      x: source.x + 0.02,
      y: source.y + 0.02,
    );

    final elements = [...slide.elements, duplicate];
    // Use _updateCurrentSlide for undo, then set selected element
    _updateCurrentSlide(emit, slide.copyWith(elements: elements));
    emit(state.copyWith(selectedElementId: duplicate.id));
  }

  void _onGroupElements(GroupElements event, Emitter<PresentationState> emit) {
    if (state.activeSlide == null || event.elementIds.length < 2) return;

    final slide = state.activeSlide!;
    final groupId = 'group_${DateTime.now().millisecondsSinceEpoch}';

    final elements = slide.elements.map((e) {
      if (event.elementIds.contains(e.id)) {
        return e.copyWith(groupId: groupId);
      }
      return e;
    }).toList();

    _updateCurrentSlide(emit, slide.copyWith(elements: elements));
  }

  void _onUngroupElements(
      UngroupElements event, Emitter<PresentationState> emit) {
    if (state.activeSlide == null) return;

    final slide = state.activeSlide!;
    final elements = slide.elements.map((e) {
      if (e.groupId == event.groupId) {
        return e.copyWith(groupId: '');
      }
      return e;
    }).toList();

    _updateCurrentSlide(emit, slide.copyWith(elements: elements));
  }

  // --- PPTX / PDF Export/Import Handlers ---

  Future<void> _onExportPptx(
      ExportPptx event, Emitter<PresentationState> emit) async {
    if (state.slides.isEmpty) return;
    emit(state.copyWith(status: PresentationStatus.exporting));
    try {
      final title = state.currentPresentation?.title ?? 'Presentation';
      final bytes = PptxService.exportToPptx(
        slides: state.slides,
        title: title,
      );
      emit(state.copyWith(
        status: PresentationStatus.exported,
        exportedBytes: bytes,
        exportedFileName: '$title.pptx',
        exportedMimeType:
            'application/vnd.openxmlformats-officedocument.presentationml.presentation',
      ));
    } catch (e) {
      emit(state.copyWith(
          status: PresentationStatus.error, errorMessage: 'Export failed: $e'));
    }
  }

  Future<void> _onExportPdf(
      ExportPresentationPdf event, Emitter<PresentationState> emit) async {
    if (state.slides.isEmpty) return;
    emit(state.copyWith(status: PresentationStatus.exporting));
    try {
      final title = state.currentPresentation?.title ?? 'Presentation';
      final bytes = await PresentationPdfService.exportToPdf(
        slides: state.slides,
        title: title,
      );
      emit(state.copyWith(
        status: PresentationStatus.exported,
        exportedBytes: bytes,
        exportedFileName: '$title.pdf',
        exportedMimeType: 'application/pdf',
      ));
    } catch (e) {
      emit(state.copyWith(
          status: PresentationStatus.error,
          errorMessage: 'PDF export failed: $e'));
    }
  }

  Future<void> _onImportPptx(
      ImportPptx event, Emitter<PresentationState> emit) async {
    emit(state.copyWith(status: PresentationStatus.importing));
    try {
      final importedSlides =
          PptxService.importFromPptx(fileBytes: event.fileBytes);

      final now = DateTime.now();
      final title =
          event.fileName.replaceAll('.pptx', '').replaceAll('.ppt', '');

      final entity = PresentationEntity(
        id: now.microsecondsSinceEpoch.toString(),
        title: title,
        content: jsonEncode(importedSlides.map((s) => s.toMap()).toList()),
        slideCount: importedSlides.length,
        createdAt: now,
        modifiedAt: now,
      );

      await _dao.insertPresentation(entity);

      emit(state.copyWith(
        status: PresentationStatus.editing,
        currentPresentation: entity,
        slides: importedSlides,
        activeSlideIndex: 0,
      ));
    } catch (e) {
      emit(state.copyWith(
          status: PresentationStatus.error, errorMessage: 'Import failed: $e'));
    }
  }

  void _onClearExported(
      ClearExportedPresentation event, Emitter<PresentationState> emit) {
    emit(state.copyWith(status: PresentationStatus.editing));
  }

  void _scheduleAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(seconds: 5), () {
      add(const AutoSavePresentation());
    });
  }

  @override
  Future<void> close() {
    _autoSaveTimer?.cancel();
    return super.close();
  }
}
