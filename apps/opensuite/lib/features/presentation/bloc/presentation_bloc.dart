import 'dart:async';
import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:fileutility_core/fileutility_core.dart';
import 'package:fileutility_storage/fileutility_storage.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// --- Events ---

sealed class PresentationEvent extends Equatable {
  const PresentationEvent();
  @override
  List<Object?> get props => [];
}

class LoadPresentations extends PresentationEvent {
  const LoadPresentations();
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
  const AddSlide({this.layout = 'blank'});
  @override
  List<Object?> get props => [layout];
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

// --- State ---

enum PresentationStatus {
  initial,
  loading,
  loaded,
  editing,
  presenting,
  saving,
  saved,
  error
}

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
  final String? errorMessage;

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
    this.errorMessage,
  });

  SlideData? get activeSlide =>
      activeSlideIndex < slides.length ? slides[activeSlideIndex] : null;

  PresentationState copyWith({
    PresentationStatus? status,
    List<PresentationEntity>? presentations,
    PresentationEntity? currentPresentation,
    List<SlideData>? slides,
    int? activeSlideIndex,
    String? selectedElementId,
    bool? isPresentationMode,
    bool? showSpeakerNotes,
    bool? hasUnsavedChanges,
    String? errorMessage,
  }) {
    return PresentationState(
      status: status ?? this.status,
      presentations: presentations ?? this.presentations,
      currentPresentation: currentPresentation ?? this.currentPresentation,
      slides: slides ?? this.slides,
      activeSlideIndex: activeSlideIndex ?? this.activeSlideIndex,
      selectedElementId: selectedElementId ?? this.selectedElementId,
      isPresentationMode: isPresentationMode ?? this.isPresentationMode,
      showSpeakerNotes: showSpeakerNotes ?? this.showSpeakerNotes,
      hasUnsavedChanges: hasUnsavedChanges ?? this.hasUnsavedChanges,
      errorMessage: errorMessage ?? this.errorMessage,
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
        errorMessage
      ];
}

// --- BLoC ---

class PresentationBloc extends Bloc<PresentationEvent, PresentationState> {
  final PresentationDao _dao;
  Timer? _autoSaveTimer;

  PresentationBloc({required PresentationDao presentationDao})
      : _dao = presentationDao,
        super(const PresentationState()) {
    on<LoadPresentations>(_onLoad);
    on<CreatePresentation>(_onCreate);
    on<OpenPresentation>(_onOpen);
    on<SelectSlide>(_onSelectSlide);
    on<AddSlide>(_onAddSlide);
    on<DeleteSlide>(_onDeleteSlide);
    on<DuplicateSlide>(_onDuplicateSlide);
    on<AddElement>(_onAddElement);
    on<UpdateElement>(_onUpdateElement);
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

  void _onDeleteElement(DeleteElement event, Emitter<PresentationState> emit) {
    if (state.activeSlide == null) return;
    final elements = state.activeSlide!.elements
        .where((e) => e.id != event.elementId)
        .toList();
    _updateCurrentSlide(emit, state.activeSlide!.copyWith(elements: elements));
    emit(state.copyWith(selectedElementId: null));
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
    final newSlides = List<SlideData>.from(state.slides);
    newSlides[state.activeSlideIndex] = updatedSlide;
    emit(state.copyWith(slides: newSlides, hasUnsavedChanges: true));
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
