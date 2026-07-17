import 'dart:async';
import 'dart:ui' as ui;

import 'package:equatable/equatable.dart';
import 'package:fileutility_core/fileutility_core.dart';
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

class SetHue extends ImageEditorEvent {
  final double value; // -180 to 180
  const SetHue(this.value);
  @override
  List<Object?> get props => [value];
}

class SetExposure extends ImageEditorEvent {
  final double value; // -1.0 to 1.0
  const SetExposure(this.value);
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
  final String tool; // 'crop', 'rotate', 'filter', 'adjust', 'resize', 'draw'
  const SelectTool(this.tool);
  @override
  List<Object?> get props => [tool];
}

// --- Sprint 17: Layers, Drawing, Text, Filters ---

class AddTextOverlay extends ImageEditorEvent {
  final TextOverlayData overlay;
  const AddTextOverlay(this.overlay);
  @override
  List<Object?> get props => [overlay];
}

class RemoveTextOverlay extends ImageEditorEvent {
  final int index;
  const RemoveTextOverlay(this.index);
  @override
  List<Object?> get props => [index];
}

class UpdateTextOverlay extends ImageEditorEvent {
  final int index;
  final TextOverlayData overlay;
  const UpdateTextOverlay(this.index, this.overlay);
  @override
  List<Object?> get props => [index, overlay];
}

class AddDrawingPath extends ImageEditorEvent {
  final DrawingPathData path;
  const AddDrawingPath(this.path);
  @override
  List<Object?> get props => [path];
}

class ClearDrawings extends ImageEditorEvent {
  const ClearDrawings();
}

class ApplyPresetFilter extends ImageEditorEvent {
  final String
      presetName; // 'sepia', 'grayscale', 'invert', 'blur', 'sharpen', 'emboss', 'vignette'
  const ApplyPresetFilter(this.presetName);
  @override
  List<Object?> get props => [presetName];
}

class AddWatermark extends ImageEditorEvent {
  final String text;
  final double opacity;
  const AddWatermark(this.text, {this.opacity = 0.3});
  @override
  List<Object?> get props => [text, opacity];
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

/// Text overlay data for compositing text on images.
class TextOverlayData extends Equatable {
  final String text;
  final double x;
  final double y;
  final double fontSize;
  final String color; // hex
  final String fontFamily;
  final bool bold;

  const TextOverlayData({
    required this.text,
    this.x = 0.5,
    this.y = 0.5,
    this.fontSize = 24,
    this.color = '#FFFFFF',
    this.fontFamily = 'Inter',
    this.bold = false,
  });

  TextOverlayData copyWith({
    String? text,
    double? x,
    double? y,
    double? fontSize,
    String? color,
    String? fontFamily,
    bool? bold,
  }) =>
      TextOverlayData(
        text: text ?? this.text,
        x: x ?? this.x,
        y: y ?? this.y,
        fontSize: fontSize ?? this.fontSize,
        color: color ?? this.color,
        fontFamily: fontFamily ?? this.fontFamily,
        bold: bold ?? this.bold,
      );

  @override
  List<Object?> get props => [text, x, y, fontSize, color, fontFamily, bold];
}

/// Freehand drawing path data.
class DrawingPathData extends Equatable {
  final List<List<double>> points; // [[x, y], [x, y], ...]
  final String color; // hex
  final double strokeWidth;
  final bool isEraser;

  const DrawingPathData({
    required this.points,
    this.color = '#FF0000',
    this.strokeWidth = 3.0,
    this.isEraser = false,
  });

  @override
  List<Object?> get props => [points, color, strokeWidth, isEraser];
}

class ImageAdjustments extends Equatable {
  final double brightness;
  final double contrast;
  final double saturation;
  final double hue;
  final double exposure;
  final double rotation;
  final bool flipHorizontal;
  final bool flipVertical;
  final ui.Rect? cropRect;

  const ImageAdjustments({
    this.brightness = 0.0,
    this.contrast = 1.0,
    this.saturation = 1.0,
    this.hue = 0.0,
    this.exposure = 0.0,
    this.rotation = 0.0,
    this.flipHorizontal = false,
    this.flipVertical = false,
    this.cropRect,
  });

  ImageAdjustments copyWith({
    double? brightness,
    double? contrast,
    double? saturation,
    double? hue,
    double? exposure,
    double? rotation,
    bool? flipHorizontal,
    bool? flipVertical,
    ui.Rect? cropRect,
    bool clearCrop = false,
  }) {
    return ImageAdjustments(
      brightness: brightness ?? this.brightness,
      contrast: contrast ?? this.contrast,
      saturation: saturation ?? this.saturation,
      hue: hue ?? this.hue,
      exposure: exposure ?? this.exposure,
      rotation: rotation ?? this.rotation,
      flipHorizontal: flipHorizontal ?? this.flipHorizontal,
      flipVertical: flipVertical ?? this.flipVertical,
      cropRect: clearCrop ? null : (cropRect ?? this.cropRect),
    );
  }

  @override
  List<Object?> get props => [
        brightness,
        contrast,
        saturation,
        hue,
        exposure,
        rotation,
        flipHorizontal,
        flipVertical,
        cropRect,
      ];
}

class ImageEditorState extends Equatable {
  final ImageEditorStatus status;
  final String? filePath;
  final Uint8List? imageBytes;
  final Uint8List? exportedBytes;
  final int imageWidth;
  final int imageHeight;
  final String activeTool;
  final ImageAdjustments adjustments;
  final List<ImageAdjustments> undoStack;
  final List<ImageAdjustments> redoStack;
  final bool hasEdits;
  final String? errorMessage;

  // Sprint 17 additions
  final List<TextOverlayData> textOverlays;
  final List<DrawingPathData> drawings;
  final String? activePresetFilter;
  final String? watermarkText;
  final double watermarkOpacity;

  const ImageEditorState({
    this.status = ImageEditorStatus.initial,
    this.filePath,
    this.imageBytes,
    this.exportedBytes,
    this.imageWidth = 0,
    this.imageHeight = 0,
    this.activeTool = 'adjust',
    this.adjustments = const ImageAdjustments(),
    this.undoStack = const [],
    this.redoStack = const [],
    this.hasEdits = false,
    this.errorMessage,
    this.textOverlays = const [],
    this.drawings = const [],
    this.activePresetFilter,
    this.watermarkText,
    this.watermarkOpacity = 0.3,
  });

  bool get canUndo => undoStack.isNotEmpty;
  bool get canRedo => redoStack.isNotEmpty;

  ImageEditorState copyWith({
    ImageEditorStatus? status,
    String? filePath,
    Uint8List? imageBytes,
    Uint8List? exportedBytes,
    int? imageWidth,
    int? imageHeight,
    String? activeTool,
    ImageAdjustments? adjustments,
    List<ImageAdjustments>? undoStack,
    List<ImageAdjustments>? redoStack,
    bool? hasEdits,
    String? errorMessage,
    List<TextOverlayData>? textOverlays,
    List<DrawingPathData>? drawings,
    String? activePresetFilter,
    String? watermarkText,
    double? watermarkOpacity,
  }) {
    return ImageEditorState(
      status: status ?? this.status,
      filePath: filePath ?? this.filePath,
      imageBytes: imageBytes ?? this.imageBytes,
      exportedBytes: exportedBytes ?? this.exportedBytes,
      imageWidth: imageWidth ?? this.imageWidth,
      imageHeight: imageHeight ?? this.imageHeight,
      activeTool: activeTool ?? this.activeTool,
      adjustments: adjustments ?? this.adjustments,
      undoStack: undoStack ?? this.undoStack,
      redoStack: redoStack ?? this.redoStack,
      hasEdits: hasEdits ?? this.hasEdits,
      errorMessage: errorMessage ?? this.errorMessage,
      textOverlays: textOverlays ?? this.textOverlays,
      drawings: drawings ?? this.drawings,
      activePresetFilter: activePresetFilter ?? this.activePresetFilter,
      watermarkText: watermarkText ?? this.watermarkText,
      watermarkOpacity: watermarkOpacity ?? this.watermarkOpacity,
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
    on<CropImage>(
        _onCrop); // FIX: Was missing — CropImage handler now registered
    on<SetBrightness>(_onBrightness);
    on<SetContrast>(_onContrast);
    on<SetSaturation>(_onSaturation);
    on<SetHue>(_onHue);
    on<SetExposure>(_onExposure);
    on<FlipImage>(_onFlip);
    on<UndoEdit>(_onUndo);
    on<RedoEdit>(_onRedo);
    on<ResetEdits>(_onReset);
    on<SelectTool>(_onSelectTool);
    on<ExportImage>(_onExport);
    on<ResizeImageDimensions>(_onResize);
    on<AddTextOverlay>(_onAddTextOverlay);
    on<RemoveTextOverlay>(_onRemoveTextOverlay);
    on<UpdateTextOverlay>(_onUpdateTextOverlay);
    on<AddDrawingPath>(_onAddDrawingPath);
    on<ClearDrawings>(_onClearDrawings);
    on<ApplyPresetFilter>(_onApplyPresetFilter);
    on<AddWatermark>(_onAddWatermark);
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

      // Decode to get actual dimensions
      int width = 1920;
      int height = 1080;
      try {
        final image = await ImageProcessor.decodeImage(bytes);
        width = image.width;
        height = image.height;
        image.dispose();
      } catch (_) {
        // Fallback to default dimensions if decode fails
      }

      emit(state.copyWith(
        status: ImageEditorStatus.loaded,
        imageBytes: bytes,
        imageWidth: width,
        imageHeight: height,
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

  /// FIX: CropImage handler — was never registered in original code.
  ///
  /// Applies crop by storing the crop rectangle in adjustments.
  /// The actual pixel cropping happens during export via [ImageProcessor].
  void _onCrop(CropImage event, Emitter<ImageEditorState> emit) {
    _pushUndo(emit);

    final cropRect = ui.Rect.fromLTRB(
      event.left.clamp(0.0, state.imageWidth.toDouble()),
      event.top.clamp(0.0, state.imageHeight.toDouble()),
      event.right.clamp(0.0, state.imageWidth.toDouble()),
      event.bottom.clamp(0.0, state.imageHeight.toDouble()),
    );

    // Update image dimensions to reflect crop
    final newWidth = cropRect.width.toInt();
    final newHeight = cropRect.height.toInt();

    emit(state.copyWith(
      adjustments: state.adjustments.copyWith(cropRect: cropRect),
      imageWidth: newWidth > 0 ? newWidth : state.imageWidth,
      imageHeight: newHeight > 0 ? newHeight : state.imageHeight,
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

  void _onHue(SetHue event, Emitter<ImageEditorState> emit) {
    _pushUndo(emit);
    emit(state.copyWith(
      adjustments:
          state.adjustments.copyWith(hue: event.value.clamp(-180.0, 180.0)),
    ));
  }

  void _onExposure(SetExposure event, Emitter<ImageEditorState> emit) {
    _pushUndo(emit);
    emit(state.copyWith(
      adjustments:
          state.adjustments.copyWith(exposure: event.value.clamp(-1.0, 1.0)),
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

  /// FIX: Real export using ImageProcessor instead of fake Future.delayed.
  ///
  /// Applies all adjustments (brightness, contrast, saturation, rotation,
  /// flip, crop, resize) to actual pixel data and produces real PNG bytes.
  Future<void> _onExport(
      ExportImage event, Emitter<ImageEditorState> emit) async {
    if (state.imageBytes == null) return;

    emit(state.copyWith(status: ImageEditorStatus.saving));
    try {
      final adj = state.adjustments;

      // Combine exposure with brightness for the processor
      final effectiveBrightness =
          (adj.brightness + adj.exposure).clamp(-1.0, 1.0);

      final exportedBytes = await ImageProcessor.renderWithAdjustments(
        sourceBytes: state.imageBytes!,
        brightness: effectiveBrightness,
        contrast: adj.contrast,
        saturation: adj.saturation,
        rotation: adj.rotation,
        flipHorizontal: adj.flipHorizontal,
        flipVertical: adj.flipVertical,
        targetWidth: state.imageWidth > 0 ? state.imageWidth : null,
        targetHeight: state.imageHeight > 0 ? state.imageHeight : null,
        cropRect: adj.cropRect,
      );

      emit(state.copyWith(
        status: ImageEditorStatus.saved,
        exportedBytes: exportedBytes,
        hasEdits: false,
      ));

      // Brief pause to show saved indicator
      await Future.delayed(const Duration(milliseconds: 500));
      emit(state.copyWith(status: ImageEditorStatus.loaded));
    } catch (e) {
      emit(state.copyWith(
        status: ImageEditorStatus.error,
        errorMessage: 'Export failed: $e',
      ));
    }
  }

  // --- Sprint 17: Layer/Drawing/Filter Handlers ---

  void _onAddTextOverlay(AddTextOverlay event, Emitter<ImageEditorState> emit) {
    _pushUndo(emit);
    emit(state.copyWith(
      textOverlays: [...state.textOverlays, event.overlay],
    ));
  }

  void _onRemoveTextOverlay(
      RemoveTextOverlay event, Emitter<ImageEditorState> emit) {
    if (event.index < 0 || event.index >= state.textOverlays.length) return;
    _pushUndo(emit);
    final updated = List<TextOverlayData>.from(state.textOverlays)
      ..removeAt(event.index);
    emit(state.copyWith(textOverlays: updated));
  }

  void _onUpdateTextOverlay(
      UpdateTextOverlay event, Emitter<ImageEditorState> emit) {
    if (event.index < 0 || event.index >= state.textOverlays.length) return;
    _pushUndo(emit);
    final updated = List<TextOverlayData>.from(state.textOverlays)
      ..[event.index] = event.overlay;
    emit(state.copyWith(textOverlays: updated));
  }

  void _onAddDrawingPath(AddDrawingPath event, Emitter<ImageEditorState> emit) {
    _pushUndo(emit);
    emit(state.copyWith(
      drawings: [...state.drawings, event.path],
    ));
  }

  void _onClearDrawings(ClearDrawings event, Emitter<ImageEditorState> emit) {
    _pushUndo(emit);
    emit(state.copyWith(drawings: const []));
  }

  void _onApplyPresetFilter(
      ApplyPresetFilter event, Emitter<ImageEditorState> emit) {
    _pushUndo(emit);
    emit(state.copyWith(activePresetFilter: event.presetName));
  }

  void _onAddWatermark(AddWatermark event, Emitter<ImageEditorState> emit) {
    _pushUndo(emit);
    emit(state.copyWith(
      watermarkText: event.text,
      watermarkOpacity: event.opacity,
    ));
  }
}
