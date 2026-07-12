import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'dart:typed_data';
import 'package:cross_file/cross_file.dart';

// --- Events ---

sealed class ImageEditorEvent extends Equatable {
  const ImageEditorEvent();
  @override
  List<Object?> get props => [];
}

class LoadImage extends ImageEditorEvent {
  final String? filePath;
  final Uint8List? imageBytes;
  const LoadImage({this.filePath, this.imageBytes});
  @override
  List<Object?> get props => [filePath, imageBytes];
}

class RotateImage extends ImageEditorEvent {
  final double degrees;
  const RotateImage(this.degrees);
  @override
  List<Object?> get props => [degrees];
}

class CropImage extends ImageEditorEvent {
  final double left;
  final double top;
  final double right;
  final double bottom;
  const CropImage(this.left, this.top, this.right, this.bottom);
  @override
  List<Object?> get props => [left, top, right, bottom];
}

class ResizeImageDimensions extends ImageEditorEvent {
  final int width;
  final int height;
  final bool maintainAspectRatio;
  const ResizeImageDimensions(this.width, this.height,
      {this.maintainAspectRatio = true});
  @override
  List<Object?> get props => [width, height, maintainAspectRatio];
}

class ApplyFilter extends ImageEditorEvent {
  final String filterName;
  final double value;
  const ApplyFilter(this.filterName, this.value);
  @override
  List<Object?> get props => [filterName, value];
}

class SetBrightness extends ImageEditorEvent {
  final double value; // -1.0 to 1.0
  const SetBrightness(this.value);
  @override
  List<Object?> get props => [value];
}

class SetContrast extends ImageEditorEvent {
  final double value; // 0.0 to 2.0
  const SetContrast(this.value);
  @override
  List<Object?> get props => [value];
}

class SetSaturation extends ImageEditorEvent {
  final double value; // 0.0 to 2.0
  const SetSaturation(this.value);
  @override
  List<Object?> get props => [value];
}

class FlipImage extends ImageEditorEvent {
  final bool horizontal;
  const FlipImage({this.horizontal = true});
  @override
  List<Object?> get props => [horizontal];
}

class UndoEdit extends ImageEditorEvent {
  const UndoEdit();
}

class RedoEdit extends ImageEditorEvent {
  const RedoEdit();
}

class ResetEdits extends ImageEditorEvent {
  const ResetEdits();
}

class ExportImage extends ImageEditorEvent {
  final String format; // 'jpeg', 'png', 'webp'
  final int quality; // 1-100
  const ExportImage({this.format = 'png', this.quality = 90});
  @override
  List<Object?> get props => [format, quality];
}

class SelectTool extends ImageEditorEvent {
  final String tool; // 'crop', 'rotate', 'filter', 'adjust', 'resize'
  const SelectTool(this.tool);
  @override
  List<Object?> get props => [tool];
}

// --- State ---

enum ImageEditorStatus {
  initial,
  loading,
  loaded,
  processing,
  saving,
  saved,
  error
}

class ImageAdjustments extends Equatable {
  final double brightness;
  final double contrast;
  final double saturation;
  final double rotation;
  final bool flipHorizontal;
  final bool flipVertical;

  const ImageAdjustments({
    this.brightness = 0.0,
    this.contrast = 1.0,
    this.saturation = 1.0,
    this.rotation = 0.0,
    this.flipHorizontal = false,
    this.flipVertical = false,
  });

  ImageAdjustments copyWith({
    double? brightness,
    double? contrast,
    double? saturation,
    double? rotation,
    bool? flipHorizontal,
    bool? flipVertical,
  }) {
    return ImageAdjustments(
      brightness: brightness ?? this.brightness,
      contrast: contrast ?? this.contrast,
      saturation: saturation ?? this.saturation,
      rotation: rotation ?? this.rotation,
      flipHorizontal: flipHorizontal ?? this.flipHorizontal,
      flipVertical: flipVertical ?? this.flipVertical,
    );
  }

  @override
  List<Object?> get props => [
        brightness,
        contrast,
        saturation,
        rotation,
        flipHorizontal,
        flipVertical
      ];
}

class ImageEditorState extends Equatable {
  final ImageEditorStatus status;
  final String? filePath;
  final Uint8List? imageBytes;
  final int imageWidth;
  final int imageHeight;
  final String activeTool;
  final ImageAdjustments adjustments;
  final List<ImageAdjustments> undoStack;
  final List<ImageAdjustments> redoStack;
  final bool hasEdits;
  final String? errorMessage;

  const ImageEditorState({
    this.status = ImageEditorStatus.initial,
    this.filePath,
    this.imageBytes,
    this.imageWidth = 0,
    this.imageHeight = 0,
    this.activeTool = 'adjust',
    this.adjustments = const ImageAdjustments(),
    this.undoStack = const [],
    this.redoStack = const [],
    this.hasEdits = false,
    this.errorMessage,
  });

  bool get canUndo => undoStack.isNotEmpty;
  bool get canRedo => redoStack.isNotEmpty;

  ImageEditorState copyWith({
    ImageEditorStatus? status,
    String? filePath,
    Uint8List? imageBytes,
    int? imageWidth,
    int? imageHeight,
    String? activeTool,
    ImageAdjustments? adjustments,
    List<ImageAdjustments>? undoStack,
    List<ImageAdjustments>? redoStack,
    bool? hasEdits,
    String? errorMessage,
  }) {
    return ImageEditorState(
      status: status ?? this.status,
      filePath: filePath ?? this.filePath,
      imageBytes: imageBytes ?? this.imageBytes,
      imageWidth: imageWidth ?? this.imageWidth,
      imageHeight: imageHeight ?? this.imageHeight,
      activeTool: activeTool ?? this.activeTool,
      adjustments: adjustments ?? this.adjustments,
      undoStack: undoStack ?? this.undoStack,
      redoStack: redoStack ?? this.redoStack,
      hasEdits: hasEdits ?? this.hasEdits,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        filePath,
        imageBytes,
        imageWidth,
        imageHeight,
        activeTool,
        adjustments,
        undoStack,
        hasEdits
      ];
}

// --- BLoC ---

class ImageEditorBloc extends Bloc<ImageEditorEvent, ImageEditorState> {
  ImageEditorBloc() : super(const ImageEditorState()) {
    on<LoadImage>(_onLoad);
    on<RotateImage>(_onRotate);
    on<SetBrightness>(_onBrightness);
    on<SetContrast>(_onContrast);
    on<SetSaturation>(_onSaturation);
    on<FlipImage>(_onFlip);
    on<UndoEdit>(_onUndo);
    on<RedoEdit>(_onRedo);
    on<ResetEdits>(_onReset);
    on<SelectTool>(_onSelectTool);
    on<ExportImage>(_onExport);
    on<ResizeImageDimensions>(_onResize);
  }

  Future<void> _onLoad(LoadImage event, Emitter<ImageEditorState> emit) async {
    emit(state.copyWith(
      status: ImageEditorStatus.loading,
      filePath: event.filePath,
    ));
    try {
      Uint8List? bytes = event.imageBytes;
      if (bytes == null && event.filePath != null) {
        bytes = await XFile(event.filePath!).readAsBytes();
      }

      if (bytes == null) {
        throw Exception(
            'Failed to load image bytes: filePath and imageBytes are both null');
      }

      emit(state.copyWith(
        status: ImageEditorStatus.loaded,
        imageBytes: bytes,
        imageWidth: 1920,
        imageHeight: 1080,
      ));
    } catch (e) {
      emit(state.copyWith(status: ImageEditorStatus.error, errorMessage: '$e'));
    }
  }

  void _pushUndo(Emitter<ImageEditorState> emit) {
    emit(state.copyWith(
      undoStack: [...state.undoStack, state.adjustments],
      redoStack: [],
      hasEdits: true,
    ));
  }

  void _onRotate(RotateImage event, Emitter<ImageEditorState> emit) {
    _pushUndo(emit);
    final newRotation = (state.adjustments.rotation + event.degrees) % 360;
    emit(state.copyWith(
      adjustments: state.adjustments.copyWith(rotation: newRotation),
    ));
  }

  void _onBrightness(SetBrightness event, Emitter<ImageEditorState> emit) {
    _pushUndo(emit);
    emit(state.copyWith(
      adjustments:
          state.adjustments.copyWith(brightness: event.value.clamp(-1.0, 1.0)),
    ));
  }

  void _onContrast(SetContrast event, Emitter<ImageEditorState> emit) {
    _pushUndo(emit);
    emit(state.copyWith(
      adjustments:
          state.adjustments.copyWith(contrast: event.value.clamp(0.0, 2.0)),
    ));
  }

  void _onSaturation(SetSaturation event, Emitter<ImageEditorState> emit) {
    _pushUndo(emit);
    emit(state.copyWith(
      adjustments:
          state.adjustments.copyWith(saturation: event.value.clamp(0.0, 2.0)),
    ));
  }

  void _onFlip(FlipImage event, Emitter<ImageEditorState> emit) {
    _pushUndo(emit);
    emit(state.copyWith(
      adjustments: event.horizontal
          ? state.adjustments
              .copyWith(flipHorizontal: !state.adjustments.flipHorizontal)
          : state.adjustments
              .copyWith(flipVertical: !state.adjustments.flipVertical),
    ));
  }

  void _onUndo(UndoEdit event, Emitter<ImageEditorState> emit) {
    if (state.undoStack.isEmpty) return;
    final previous = state.undoStack.last;
    emit(state.copyWith(
      undoStack: state.undoStack.sublist(0, state.undoStack.length - 1),
      redoStack: [...state.redoStack, state.adjustments],
      adjustments: previous,
    ));
  }

  void _onRedo(RedoEdit event, Emitter<ImageEditorState> emit) {
    if (state.redoStack.isEmpty) return;
    final next = state.redoStack.last;
    emit(state.copyWith(
      undoStack: [...state.undoStack, state.adjustments],
      redoStack: state.redoStack.sublist(0, state.redoStack.length - 1),
      adjustments: next,
    ));
  }

  void _onReset(ResetEdits event, Emitter<ImageEditorState> emit) {
    _pushUndo(emit);
    emit(state.copyWith(adjustments: const ImageAdjustments()));
  }

  void _onSelectTool(SelectTool event, Emitter<ImageEditorState> emit) {
    emit(state.copyWith(activeTool: event.tool));
  }

  void _onResize(ResizeImageDimensions event, Emitter<ImageEditorState> emit) {
    _pushUndo(emit);
    emit(state.copyWith(imageWidth: event.width, imageHeight: event.height));
  }

  Future<void> _onExport(
      ExportImage event, Emitter<ImageEditorState> emit) async {
    emit(state.copyWith(status: ImageEditorStatus.saving));
    try {
      // In production, apply adjustments and save to the chosen format
      await Future.delayed(const Duration(milliseconds: 500));
      emit(state.copyWith(status: ImageEditorStatus.saved, hasEdits: false));
      await Future.delayed(const Duration(milliseconds: 500));
      emit(state.copyWith(status: ImageEditorStatus.loaded));
    } catch (e) {
      emit(state.copyWith(status: ImageEditorStatus.error, errorMessage: '$e'));
    }
  }
}
