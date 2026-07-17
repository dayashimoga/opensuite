import 'dart:math' as math;

import 'package:file_picker/file_picker.dart' as fp;
import 'package:fileutility_core/fileutility_core.dart';
import 'package:fileutility_ui_kit/fileutility_ui_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/image_editor_bloc.dart';
import '../utils/photo_tile_generator.dart';

/// Enhanced Image Editor Page with interactive free crop, aspect ratio chips,
/// numerical/slider resize, multi-tile photo sheet generator (A4, A3, B4, B5, Letter, Passport, Visa, Stamp),
/// and direct browser Blob file downloads.
class ImageEditorPage extends StatelessWidget {
  final String? filePath;
  const ImageEditorPage({super.key, this.filePath});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ImageEditorBloc>(
      create: (_) {
        final bloc = ImageEditorBloc();
        if (filePath != null) {
          bloc.add(LoadImage(filePath: filePath));
        }
        return bloc;
      },
      child: const _EditorContent(),
    );
  }
}

class _EditorContent extends StatefulWidget {
  const _EditorContent();

  @override
  State<_EditorContent> createState() => _EditorContentState();
}

class _EditorContentState extends State<_EditorContent> {
  // Global Crop Rect (normalized 0.0 - 1.0)
  Rect _cropRect = const Rect.fromLTWH(0.0, 0.0, 1.0, 1.0);
  double? _targetAspectRatio; // null = free

  // Global Tile Generator Settings
  PaperFormat _selectedPaper = PhotoTileConfig.paperFormats[0]; // A4
  PhotoFormat _selectedPhotoFormat =
      PhotoTileConfig.photoFormats[0]; // Passport
  bool _drawCutLines = true;
  double _marginMm = 5.0;
  double _gapMm = 2.0;

  void _resetCropRect() {
    setState(() {
      _cropRect = const Rect.fromLTWH(0.0, 0.0, 1.0, 1.0);
      _targetAspectRatio = null;
    });
  }

  void _applyCrop(BuildContext context, ImageEditorState state) {
    if (state.imageWidth <= 0 || state.imageHeight <= 0) return;

    final left = (_cropRect.left * state.imageWidth).roundToDouble();
    final top = (_cropRect.top * state.imageHeight).roundToDouble();
    final right = (_cropRect.right * state.imageWidth).roundToDouble();
    final bottom = (_cropRect.bottom * state.imageHeight).roundToDouble();

    context.read<ImageEditorBloc>().add(CropImage(left, top, right, bottom));
    _resetCropRect();
  }

  Future<void> _exportAndDownload(
      BuildContext context, ImageEditorState state, String format) async {
    if (state.imageBytes == null) return;

    final effectiveBrightness =
        (state.adjustments.brightness + state.adjustments.exposure)
            .clamp(-1.0, 1.0);

    final renderedBytes = await ImageProcessor.renderWithAdjustments(
      sourceBytes: state.imageBytes!,
      brightness: effectiveBrightness,
      contrast: state.adjustments.contrast,
      saturation: state.adjustments.saturation,
      rotation: state.adjustments.rotation,
      flipHorizontal: state.adjustments.flipHorizontal,
      flipVertical: state.adjustments.flipVertical,
      targetWidth: state.imageWidth > 0 ? state.imageWidth : null,
      targetHeight: state.imageHeight > 0 ? state.imageHeight : null,
      cropRect: state.adjustments.cropRect,
    );

    final baseName = state.filePath != null
        ? state.filePath!.split('/').last.split('.').first
        : 'edited_image';
    final fileName = '$baseName.$format';
    final mimeType = format == 'png'
        ? 'image/png'
        : (format == 'webp' ? 'image/webp' : 'image/jpeg');

    await FileDownloadUtils.downloadBytes(
      bytes: renderedBytes,
      fileName: fileName,
      mimeType: mimeType,
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Exported and saved $fileName')),
      );
    }
  }

  Future<void> _downloadTileSheet(
      BuildContext context, ImageEditorState state) async {
    if (state.imageBytes == null) return;

    final tileSheetBytes = await PhotoTileGenerator.generateTileSheet(
      sourceBytes: state.imageBytes!,
      paper: _selectedPaper,
      photo: _selectedPhotoFormat,
      marginMm: _marginMm,
      gapMm: _gapMm,
      drawCutLines: _drawCutLines,
    );

    final paperShortName = _selectedPaper.name.split(' ').first.toLowerCase();
    final photoShortName =
        _selectedPhotoFormat.name.split(' ').first.toLowerCase();
    final fileName = 'tile_sheet_${paperShortName}_$photoShortName.png';

    await FileDownloadUtils.downloadBytes(
      bytes: tileSheetBytes,
      fileName: fileName,
      mimeType: 'image/png',
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Downloaded print tile sheet: $fileName')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ImageEditorBloc, ImageEditorState>(
      builder: (context, state) {
        return CallbackShortcuts(
          bindings: {
            const SingleActivator(LogicalKeyboardKey.keyZ, control: true): () {
              context.read<ImageEditorBloc>().add(const UndoEdit());
            },
            const SingleActivator(LogicalKeyboardKey.keyY, control: true): () {
              context.read<ImageEditorBloc>().add(const RedoEdit());
            },
            const SingleActivator(LogicalKeyboardKey.keyS, control: true): () {
              _exportAndDownload(context, state, 'png');
            },
            const SingleActivator(LogicalKeyboardKey.delete): () {
              context.read<ImageEditorBloc>().add(const ResetEdits());
            },
          },
          child: Focus(
            autofocus: true,
            child: Scaffold(
              appBar: AppBar(
                title: Text(state.filePath?.split('/').last ?? 'Image Editor'),
                actions: [
                  // Undo/Redo
                  IconButton(
                    icon: const Icon(Icons.undo, size: 20),
                    onPressed: state.canUndo
                        ? () => context
                            .read<ImageEditorBloc>()
                            .add(const UndoEdit())
                        : null,
                    tooltip: 'Undo (Ctrl+Z)',
                  ),
                  IconButton(
                    icon: const Icon(Icons.redo, size: 20),
                    onPressed: state.canRedo
                        ? () => context
                            .read<ImageEditorBloc>()
                            .add(const RedoEdit())
                        : null,
                    tooltip: 'Redo (Ctrl+Y)',
                  ),
                  const SizedBox(width: 8),
                  // Reset
                  IconButton(
                    icon: const Icon(Icons.refresh, size: 20),
                    onPressed: state.hasEdits
                        ? () => context
                            .read<ImageEditorBloc>()
                            .add(const ResetEdits())
                        : null,
                    tooltip: 'Reset All',
                  ),
                  const SizedBox(width: 8),
                  // Download / Export Menu
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.download, size: 20),
                    tooltip: 'Export & Download',
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'png', child: Text('Download PNG')),
                      PopupMenuItem(
                          value: 'jpeg', child: Text('Download JPEG')),
                      PopupMenuItem(
                          value: 'webp', child: Text('Download WebP')),
                    ],
                    onSelected: (format) =>
                        _exportAndDownload(context, state, format),
                  ),
                ],
              ),
              body: ResponsiveBuilder(
                mobile: (context, _) => Column(
                  children: [
                    Expanded(
                      child: _ImageCanvas(
                        state: state,
                        cropRect: _cropRect,
                        onCropChanged: (r) => setState(() => _cropRect = r),
                        selectedPaper: _selectedPaper,
                        selectedPhotoFormat: _selectedPhotoFormat,
                        marginMm: _marginMm,
                        gapMm: _gapMm,
                        drawCutLines: _drawCutLines,
                      ),
                    ),
                    _MobileToolBar(
                      activeTool: state.activeTool,
                      onSelectTool: (tool) =>
                          context.read<ImageEditorBloc>().add(SelectTool(tool)),
                    ),
                    SizedBox(
                      height: 220,
                      child: _AdjustmentsPanel(
                        state: state,
                        cropRect: _cropRect,
                        targetAspectRatio: _targetAspectRatio,
                        onSetAspectRatio: (ratio) {
                          setState(() {
                            _targetAspectRatio = ratio;
                            if (ratio != null) {
                              // Center constrain crop rect to aspect ratio
                              double w = 0.8;
                              double h = w / ratio;
                              if (h > 0.8) {
                                h = 0.8;
                                w = h * ratio;
                              }
                              final l = (1.0 - w) / 2.0;
                              final t = (1.0 - h) / 2.0;
                              _cropRect = Rect.fromLTWH(l, t, w, h);
                            }
                          });
                        },
                        onApplyCrop: () => _applyCrop(context, state),
                        onResetCrop: _resetCropRect,
                        selectedPaper: _selectedPaper,
                        selectedPhotoFormat: _selectedPhotoFormat,
                        onSelectPaper: (p) =>
                            setState(() => _selectedPaper = p),
                        onSelectPhotoFormat: (pf) =>
                            setState(() => _selectedPhotoFormat = pf),
                        marginMm: _marginMm,
                        gapMm: _gapMm,
                        drawCutLines: _drawCutLines,
                        onMarginChanged: (m) => setState(() => _marginMm = m),
                        onGapChanged: (g) => setState(() => _gapMm = g),
                        onCutLinesToggled: (v) =>
                            setState(() => _drawCutLines = v),
                        onDownloadTileSheet: () =>
                            _downloadTileSheet(context, state),
                      ),
                    ),
                  ],
                ),
                desktop: (context, _) => Row(
                  children: [
                    _ToolSidebar(
                      activeTool: state.activeTool,
                      onSelectTool: (tool) =>
                          context.read<ImageEditorBloc>().add(SelectTool(tool)),
                    ),
                    Expanded(
                      child: _ImageCanvas(
                        state: state,
                        cropRect: _cropRect,
                        onCropChanged: (r) => setState(() => _cropRect = r),
                        selectedPaper: _selectedPaper,
                        selectedPhotoFormat: _selectedPhotoFormat,
                        marginMm: _marginMm,
                        gapMm: _gapMm,
                        drawCutLines: _drawCutLines,
                      ),
                    ),
                    _AdjustmentsPanel(
                      state: state,
                      cropRect: _cropRect,
                      targetAspectRatio: _targetAspectRatio,
                      onSetAspectRatio: (ratio) {
                        setState(() {
                          _targetAspectRatio = ratio;
                          if (ratio != null) {
                            double w = 0.8;
                            double h = w / ratio;
                            if (h > 0.8) {
                              h = 0.8;
                              w = h * ratio;
                            }
                            final l = (1.0 - w) / 2.0;
                            final t = (1.0 - h) / 2.0;
                            _cropRect = Rect.fromLTWH(l, t, w, h);
                          }
                        });
                      },
                      onApplyCrop: () => _applyCrop(context, state),
                      onResetCrop: _resetCropRect,
                      selectedPaper: _selectedPaper,
                      selectedPhotoFormat: _selectedPhotoFormat,
                      onSelectPaper: (p) => setState(() => _selectedPaper = p),
                      onSelectPhotoFormat: (pf) =>
                          setState(() => _selectedPhotoFormat = pf),
                      marginMm: _marginMm,
                      gapMm: _gapMm,
                      drawCutLines: _drawCutLines,
                      onMarginChanged: (m) => setState(() => _marginMm = m),
                      onGapChanged: (g) => setState(() => _gapMm = g),
                      onCutLinesToggled: (v) =>
                          setState(() => _drawCutLines = v),
                      onDownloadTileSheet: () =>
                          _downloadTileSheet(context, state),
                    ),
                  ],
                ),
              ),
              bottomNavigationBar: _StatusBar(state: state),
            ),
          ),
        );
      },
    );
  }
}

/// Tool sidebar with primary editor tool actions.
class _ToolSidebar extends StatelessWidget {
  final String activeTool;
  final ValueChanged<String> onSelectTool;

  const _ToolSidebar({required this.activeTool, required this.onSelectTool});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final tools = [
      ('adjust', Icons.tune, 'Adjust'),
      ('crop', Icons.crop, 'Crop'),
      ('rotate', Icons.rotate_right, 'Rotate'),
      ('resize', Icons.aspect_ratio, 'Resize'),
      ('tiles', Icons.grid_on, 'Print Tiles'),
    ];

    return Container(
      width: 72,
      decoration: BoxDecoration(
        border: Border(
          right:
              BorderSide(color: theme.colorScheme.outlineVariant, width: 0.5),
        ),
      ),
      child: Column(
        children: tools.map((tool) {
          final isActive = activeTool == tool.$1;
          return Tooltip(
            message: tool.$3,
            child: InkWell(
              onTap: () => onSelectTool(tool.$1),
              child: Container(
                width: 72,
                height: 60,
                decoration: BoxDecoration(
                  color: isActive ? theme.colorScheme.primaryContainer : null,
                  border: Border(
                    left: BorderSide(
                      color: isActive
                          ? theme.colorScheme.primary
                          : Colors.transparent,
                      width: 3,
                    ),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      tool.$2,
                      size: 20,
                      color: isActive
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tool.$3,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 9,
                        fontWeight:
                            isActive ? FontWeight.bold : FontWeight.normal,
                        color: isActive
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Main Canvas supporting Interactive Viewing, Drag-Crop Handles, & Print Sheet Preview.
class _ImageCanvas extends StatelessWidget {
  final ImageEditorState state;
  final Rect cropRect;
  final ValueChanged<Rect> onCropChanged;
  final PaperFormat selectedPaper;
  final PhotoFormat selectedPhotoFormat;
  final double marginMm;
  final double gapMm;
  final bool drawCutLines;

  const _ImageCanvas({
    required this.state,
    required this.cropRect,
    required this.onCropChanged,
    required this.selectedPaper,
    required this.selectedPhotoFormat,
    required this.marginMm,
    required this.gapMm,
    required this.drawCutLines,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (state.status == ImageEditorStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.filePath == null && state.imageBytes == null) {
      return EmptyState(
        icon: Icons.image_outlined,
        title: 'No Image Selected',
        description:
            'Open a local photo or image to edit and create print sheets',
        actionLabel: 'Open Image',
        onAction: () async {
          final result = await fp.FilePicker.platform.pickFiles(
            type: fp.FileType.image,
            allowMultiple: false,
            withData: true,
          );
          if (result != null && result.files.isNotEmpty) {
            final file = result.files.single;
            if (context.mounted) {
              context.read<ImageEditorBloc>().add(LoadImage(
                    filePath: file.path ?? file.name,
                    imageBytes: file.bytes,
                  ));
            }
          }
        },
      );
    }

    if (state.activeTool == 'tiles') {
      return _buildTileSheetPreview(theme);
    }

    return Container(
      color: theme.colorScheme.surfaceContainerLowest,
      child: InteractiveViewer(
        minScale: 0.1,
        maxScale: 10.0,
        child: Center(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final aspect = (state.imageWidth > 0 && state.imageHeight > 0)
                  ? state.imageWidth / state.imageHeight
                  : 1.5;

              double dispW = math.min(constraints.maxWidth * 0.8, 700.0);
              double dispH = dispW / aspect;
              if (dispH > constraints.maxHeight * 0.8) {
                dispH = constraints.maxHeight * 0.8;
                dispW = dispH * aspect;
              }

              return Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..rotateZ(state.adjustments.rotation * math.pi / 180)
                  ..scale(
                    state.adjustments.flipHorizontal ? -1.0 : 1.0,
                    state.adjustments.flipVertical ? -1.0 : 1.0,
                  ),
                child: SizedBox(
                  width: dispW,
                  height: dispH,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.25),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ColorFiltered(
                            colorFilter: ColorFilter.matrix(
                                _buildColorMatrix(state.adjustments)),
                            child: state.imageBytes != null
                                ? Image.memory(
                                    state.imageBytes!,
                                    fit: BoxFit.cover,
                                  )
                                : const Icon(Icons.image, size: 64),
                          ),
                        ),
                      ),
                      if (state.activeTool == 'crop')
                        _InteractiveCropBox(
                          cropRect: cropRect,
                          onCropChanged: onCropChanged,
                          containerSize: Size(dispW, dispH),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTileSheetPreview(ThemeData theme) {
    final calc = TileCalculation.calculate(
      paper: selectedPaper,
      photo: selectedPhotoFormat,
      marginMm: marginMm,
      gapMm: gapMm,
    );

    return Container(
      color: theme.colorScheme.surfaceContainerLowest,
      padding: const EdgeInsets.all(16),
      child: Center(
        child: AspectRatio(
          aspectRatio: selectedPaper.widthMm / selectedPaper.heightMm,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final scaleW = constraints.maxWidth / selectedPaper.widthMm;
                final scaleH = constraints.maxHeight / selectedPaper.heightMm;

                final tileW = selectedPhotoFormat.widthMm * scaleW;
                final tileH = selectedPhotoFormat.heightMm * scaleH;
                final marginPx = marginMm * scaleW;
                final gapPx = gapMm * scaleW;

                return Stack(
                  children: [
                    for (int r = 0; r < calc.rows; r++)
                      for (int c = 0; c < calc.cols; c++)
                        Positioned(
                          left: marginPx + c * (tileW + gapPx),
                          top: marginPx + r * (tileH + gapPx),
                          width: tileW,
                          height: tileH,
                          child: Container(
                            decoration: BoxDecoration(
                              border: drawCutLines
                                  ? Border.all(
                                      color: Colors.grey.shade400, width: 1)
                                  : null,
                            ),
                            child: state.imageBytes != null
                                ? Image.memory(state.imageBytes!,
                                    fit: BoxFit.cover)
                                : Container(color: Colors.grey.shade300),
                          ),
                        ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  List<double> _buildColorMatrix(ImageAdjustments adj) {
    final b = adj.brightness;
    final c = adj.contrast;
    final s = adj.saturation;

    const lr = 0.2126;
    const lg = 0.7152;
    const lb = 0.0722;

    final sr = (1 - s) * lr;
    final sg = (1 - s) * lg;
    final sb = (1 - s) * lb;

    return [
      c * (sr + s),
      c * sg,
      c * sb,
      0,
      b * 255 * 0.5,
      c * sr,
      c * (sg + s),
      c * sb,
      0,
      b * 255 * 0.5,
      c * sr,
      c * sg,
      c * (sb + s),
      0,
      b * 255 * 0.5,
      0,
      0,
      0,
      1,
      0,
    ];
  }
}

/// Interactive 8-point Drag Handle Bounding Box for Free & Constrained Image Cropping.
class _InteractiveCropBox extends StatelessWidget {
  final Rect cropRect;
  final ValueChanged<Rect> onCropChanged;
  final Size containerSize;

  const _InteractiveCropBox({
    required this.cropRect,
    required this.onCropChanged,
    required this.containerSize,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final left = cropRect.left * containerSize.width;
    final top = cropRect.top * containerSize.height;
    final width = cropRect.width * containerSize.width;
    final height = cropRect.height * containerSize.height;

    return Stack(
      children: [
        // Darkened overlay surrounding active crop box
        Positioned.fill(
          child: CustomPaint(
            painter: _CropOverlayPainter(
              cropBox: Rect.fromLTWH(left, top, width, height),
            ),
          ),
        ),
        // Active crop outline box
        Positioned(
          left: left,
          top: top,
          width: width,
          height: height,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Top-Left Handle
                Positioned(
                  top: -8,
                  left: -8,
                  child: _handle(theme, (details) {
                    final dx = details.delta.dx / containerSize.width;
                    final dy = details.delta.dy / containerSize.height;
                    final newL =
                        (cropRect.left + dx).clamp(0.0, cropRect.right - 0.05);
                    final newT =
                        (cropRect.top + dy).clamp(0.0, cropRect.bottom - 0.05);
                    onCropChanged(Rect.fromLTRB(
                        newL, newT, cropRect.right, cropRect.bottom));
                  }),
                ),
                // Top-Right Handle
                Positioned(
                  top: -8,
                  right: -8,
                  child: _handle(theme, (details) {
                    final dx = details.delta.dx / containerSize.width;
                    final dy = details.delta.dy / containerSize.height;
                    final newR =
                        (cropRect.right + dx).clamp(cropRect.left + 0.05, 1.0);
                    final newT =
                        (cropRect.top + dy).clamp(0.0, cropRect.bottom - 0.05);
                    onCropChanged(Rect.fromLTRB(
                        cropRect.left, newT, newR, cropRect.bottom));
                  }),
                ),
                // Bottom-Left Handle
                Positioned(
                  bottom: -8,
                  left: -8,
                  child: _handle(theme, (details) {
                    final dx = details.delta.dx / containerSize.width;
                    final dy = details.delta.dy / containerSize.height;
                    final newL =
                        (cropRect.left + dx).clamp(0.0, cropRect.right - 0.05);
                    final newB =
                        (cropRect.bottom + dy).clamp(cropRect.top + 0.05, 1.0);
                    onCropChanged(Rect.fromLTRB(
                        newL, cropRect.top, cropRect.right, newB));
                  }),
                ),
                // Bottom-Right Handle
                Positioned(
                  bottom: -8,
                  right: -8,
                  child: _handle(theme, (details) {
                    final dx = details.delta.dx / containerSize.width;
                    final dy = details.delta.dy / containerSize.height;
                    final newR =
                        (cropRect.right + dx).clamp(cropRect.left + 0.05, 1.0);
                    final newB =
                        (cropRect.bottom + dy).clamp(cropRect.top + 0.05, 1.0);
                    onCropChanged(
                        Rect.fromLTRB(cropRect.left, cropRect.top, newR, newB));
                  }),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _handle(ThemeData theme, void Function(DragUpdateDetails) onDrag) {
    return GestureDetector(
      onPanUpdate: onDrag,
      child: Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          color: theme.colorScheme.primary,
          shape: BoxShape.rectangle,
          borderRadius: BorderRadius.circular(2),
          border: Border.all(color: Colors.white, width: 2),
        ),
      ),
    );
  }
}

class _CropOverlayPainter extends CustomPainter {
  final Rect cropBox;
  _CropOverlayPainter({required this.cropBox});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withValues(alpha: 0.45);
    final fullRect = Rect.fromLTWH(0, 0, size.width, size.height);

    final path = Path()
      ..addRect(fullRect)
      ..addRect(cropBox);

    canvas.drawPath(path..fillType = PathFillType.evenOdd, paint);
  }

  @override
  bool shouldRepaint(covariant _CropOverlayPainter oldDelegate) =>
      oldDelegate.cropBox != cropBox;
}

/// Comprehensive Tools Panel: Adjustments, Interactive Crop, Pixel Resize, & Multi-Tile Sheet Generator.
class _AdjustmentsPanel extends StatefulWidget {
  final ImageEditorState state;
  final Rect cropRect;
  final double? targetAspectRatio;
  final ValueChanged<double?> onSetAspectRatio;
  final VoidCallback onApplyCrop;
  final VoidCallback onResetCrop;

  final PaperFormat selectedPaper;
  final PhotoFormat selectedPhotoFormat;
  final ValueChanged<PaperFormat> onSelectPaper;
  final ValueChanged<PhotoFormat> onSelectPhotoFormat;

  final double marginMm;
  final double gapMm;
  final bool drawCutLines;
  final ValueChanged<double> onMarginChanged;
  final ValueChanged<double> onGapChanged;
  final ValueChanged<bool> onCutLinesToggled;
  final VoidCallback onDownloadTileSheet;

  const _AdjustmentsPanel({
    required this.state,
    required this.cropRect,
    required this.targetAspectRatio,
    required this.onSetAspectRatio,
    required this.onApplyCrop,
    required this.onResetCrop,
    required this.selectedPaper,
    required this.selectedPhotoFormat,
    required this.onSelectPaper,
    required this.onSelectPhotoFormat,
    required this.marginMm,
    required this.gapMm,
    required this.drawCutLines,
    required this.onMarginChanged,
    required this.onGapChanged,
    required this.onCutLinesToggled,
    required this.onDownloadTileSheet,
  });

  @override
  State<_AdjustmentsPanel> createState() => _AdjustmentsPanelState();
}

class _AdjustmentsPanelState extends State<_AdjustmentsPanel> {
  late TextEditingController _widthController;
  late TextEditingController _heightController;
  bool _maintainAspect = true;

  @override
  void initState() {
    super.initState();
    _widthController =
        TextEditingController(text: widget.state.imageWidth.toString());
    _heightController =
        TextEditingController(text: widget.state.imageHeight.toString());
  }

  @override
  void didUpdateWidget(_AdjustmentsPanel old) {
    super.didUpdateWidget(old);
    if (old.state.imageWidth != widget.state.imageWidth) {
      _widthController.text = widget.state.imageWidth.toString();
    }
    if (old.state.imageHeight != widget.state.imageHeight) {
      _heightController.text = widget.state.imageHeight.toString();
    }
  }

  @override
  void dispose() {
    _widthController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  void _applyResize() {
    final w = int.tryParse(_widthController.text) ?? widget.state.imageWidth;
    final h = int.tryParse(_heightController.text) ?? widget.state.imageHeight;
    context
        .read<ImageEditorBloc>()
        .add(ResizeImageDimensions(w, h, maintainAspectRatio: _maintainAspect));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bloc = context.read<ImageEditorBloc>();

    return Container(
      width: 280,
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: theme.colorScheme.outlineVariant, width: 0.5),
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.state.activeTool == 'adjust') ...[
              Text('Image Adjustments', style: theme.textTheme.titleSmall),
              const SizedBox(height: 16),
              _SliderControl(
                label: 'Brightness',
                value: widget.state.adjustments.brightness,
                min: -1.0,
                max: 1.0,
                onChanged: (v) => bloc.add(SetBrightness(v)),
              ),
              _SliderControl(
                label: 'Contrast',
                value: widget.state.adjustments.contrast,
                min: 0.0,
                max: 2.0,
                onChanged: (v) => bloc.add(SetContrast(v)),
              ),
              _SliderControl(
                label: 'Saturation',
                value: widget.state.adjustments.saturation,
                min: 0.0,
                max: 2.0,
                onChanged: (v) => bloc.add(SetSaturation(v)),
              ),
            ],
            if (widget.state.activeTool == 'crop') ...[
              Text('Crop & Aspect Ratio', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              Text('Drag corners on canvas to select crop area.',
                  style: theme.textTheme.bodySmall),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _ChipOption(
                    label: 'Free',
                    icon: Icons.crop_free,
                    isSelected: widget.targetAspectRatio == null,
                    onTap: () => widget.onSetAspectRatio(null),
                  ),
                  _ChipOption(
                    label: '16:9',
                    icon: Icons.crop_16_9,
                    isSelected: widget.targetAspectRatio == 16 / 9,
                    onTap: () => widget.onSetAspectRatio(16 / 9),
                  ),
                  _ChipOption(
                    label: '4:3',
                    icon: Icons.crop_landscape,
                    isSelected: widget.targetAspectRatio == 4 / 3,
                    onTap: () => widget.onSetAspectRatio(4 / 3),
                  ),
                  _ChipOption(
                    label: '1:1',
                    icon: Icons.crop_square,
                    isSelected: widget.targetAspectRatio == 1.0,
                    onTap: () => widget.onSetAspectRatio(1.0),
                  ),
                  _ChipOption(
                    label: 'Passport (3.5:4.5)',
                    icon: Icons.portrait,
                    isSelected: widget.targetAspectRatio == 3.5 / 4.5,
                    onTap: () => widget.onSetAspectRatio(3.5 / 4.5),
                  ),
                  _ChipOption(
                    label: '3:2',
                    icon: Icons.crop_3_2,
                    isSelected: widget.targetAspectRatio == 3 / 2,
                    onTap: () => widget.onSetAspectRatio(3 / 2),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: widget.onApplyCrop,
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Apply Crop'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: widget.onResetCrop,
                    child: const Text('Reset'),
                  ),
                ],
              ),
            ],
            if (widget.state.activeTool == 'rotate') ...[
              Text('Rotate & Flip', style: theme.textTheme.titleSmall),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _ActionChip(
                      label: 'Rotate 90°',
                      icon: Icons.rotate_right,
                      onTap: () => bloc.add(const RotateImage(90))),
                  _ActionChip(
                      label: 'Rotate -90°',
                      icon: Icons.rotate_left,
                      onTap: () => bloc.add(const RotateImage(-90))),
                  _ActionChip(
                      label: 'Flip H',
                      icon: Icons.flip,
                      onTap: () => bloc.add(const FlipImage(horizontal: true))),
                  _ActionChip(
                      label: 'Flip V',
                      icon: Icons.flip,
                      onTap: () =>
                          bloc.add(const FlipImage(horizontal: false))),
                ],
              ),
            ],
            if (widget.state.activeTool == 'resize') ...[
              Text('Resize Dimensions', style: theme.textTheme.titleSmall),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _widthController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Width (px)',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      onChanged: (val) {
                        if (_maintainAspect && widget.state.imageWidth > 0) {
                          final w = int.tryParse(val);
                          if (w != null) {
                            final aspect = widget.state.imageHeight /
                                widget.state.imageWidth;
                            _heightController.text =
                                (w * aspect).toInt().toString();
                          }
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _heightController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Height (px)',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Checkbox(
                    value: _maintainAspect,
                    onChanged: (v) =>
                        setState(() => _maintainAspect = v ?? true),
                  ),
                  const Text('Maintain Aspect Ratio',
                      style: TextStyle(fontSize: 12)),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _ActionChip(
                      label: '50%',
                      icon: Icons.photo_size_select_small,
                      onTap: () {
                        final w = widget.state.imageWidth ~/ 2;
                        final h = widget.state.imageHeight ~/ 2;
                        bloc.add(ResizeImageDimensions(w, h));
                      }),
                  _ActionChip(
                      label: '1080p',
                      icon: Icons.hd,
                      onTap: () =>
                          bloc.add(const ResizeImageDimensions(1920, 1080))),
                  _ActionChip(
                      label: '720p',
                      icon: Icons.sd,
                      onTap: () =>
                          bloc.add(const ResizeImageDimensions(1280, 720))),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _applyResize,
                  icon: const Icon(Icons.aspect_ratio, size: 18),
                  label: const Text('Apply Resize'),
                ),
              ),
            ],
            if (widget.state.activeTool == 'tiles') ...[
              Text('Print Photo Tiles', style: theme.textTheme.titleSmall),
              const SizedBox(height: 4),
              Text('Generate multi-photo layout on paper sheets.',
                  style: theme.textTheme.bodySmall),
              const SizedBox(height: 16),
              // Paper Format Selector
              DropdownButtonFormField<PaperFormat>(
                value: widget.selectedPaper,
                decoration: const InputDecoration(
                  labelText: 'Paper Format Size',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: PhotoTileConfig.paperFormats
                    .map((pf) => DropdownMenuItem(
                          value: pf,
                          child: Text(pf.name,
                              style: const TextStyle(fontSize: 13)),
                        ))
                    .toList(),
                onChanged: (val) {
                  if (val != null) widget.onSelectPaper(val);
                },
              ),
              const SizedBox(height: 12),
              // Photo Standard Format Selector
              DropdownButtonFormField<PhotoFormat>(
                value: widget.selectedPhotoFormat,
                decoration: const InputDecoration(
                  labelText: 'Photo Size Standard',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: PhotoTileConfig.photoFormats
                    .map((pf) => DropdownMenuItem(
                          value: pf,
                          child: Text(pf.name,
                              style: const TextStyle(fontSize: 13)),
                        ))
                    .toList(),
                onChanged: (val) {
                  if (val != null) widget.onSelectPhotoFormat(val);
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Checkbox(
                    value: widget.drawCutLines,
                    onChanged: (v) => widget.onCutLinesToggled(v ?? true),
                  ),
                  const Text('Draw Tile Cut Outlines',
                      style: TextStyle(fontSize: 12)),
                ],
              ),
              const SizedBox(height: 12),
              // Live Tile Statistics Calculation
              Builder(builder: (context) {
                final calc = TileCalculation.calculate(
                  paper: widget.selectedPaper,
                  photo: widget.selectedPhotoFormat,
                  marginMm: widget.marginMm,
                  gapMm: widget.gapMm,
                );
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer
                        .withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Layout: ${calc.cols} columns × ${calc.rows} rows',
                        style: theme.textTheme.labelMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Total Photos: ${calc.totalTiles} tiles per sheet',
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: widget.onDownloadTileSheet,
                  icon: const Icon(Icons.print, size: 18),
                  label: const Text('Download Print Sheet'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ChipOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ChipOption({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FilterChip(
      avatar: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 11)),
      selected: isSelected,
      selectedColor: theme.colorScheme.primaryContainer,
      onSelected: (_) => onTap(),
    );
  }
}

class _SliderControl extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  const _SliderControl({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: theme.textTheme.labelSmall),
            Text(value.toStringAsFixed(2), style: theme.textTheme.labelSmall),
          ],
        ),
        Slider(
          value: value.clamp(min, max),
          min: min,
          max: max,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _ActionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _ActionChip(
      {required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 11)),
      onPressed: onTap,
    );
  }
}

class _StatusBar extends StatelessWidget {
  final ImageEditorState state;
  const _StatusBar({required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Text('${state.imageWidth} × ${state.imageHeight} px',
              style: theme.textTheme.labelSmall),
          const Spacer(),
          if (state.adjustments.rotation != 0)
            Text(
                'Rotation: ${state.adjustments.rotation.toStringAsFixed(0)}°  ',
                style: theme.textTheme.labelSmall),
          if (state.hasEdits)
            Text('Modified',
                style:
                    theme.textTheme.labelSmall?.copyWith(color: Colors.orange)),
        ],
      ),
    );
  }
}

class _MobileToolBar extends StatelessWidget {
  final String activeTool;
  final ValueChanged<String> onSelectTool;

  const _MobileToolBar({required this.activeTool, required this.onSelectTool});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final tools = [
      ('adjust', Icons.tune, 'Adjust'),
      ('crop', Icons.crop, 'Crop'),
      ('rotate', Icons.rotate_right, 'Rotate'),
      ('resize', Icons.aspect_ratio, 'Resize'),
      ('tiles', Icons.grid_on, 'Print Tiles'),
    ];

    return Container(
      height: 48,
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant, width: 0.5),
          bottom:
              BorderSide(color: theme.colorScheme.outlineVariant, width: 0.5),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: tools.map((tool) {
          final isActive = activeTool == tool.$1;
          return GestureDetector(
            onTap: () => onSelectTool(tool.$1),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isActive ? theme.colorScheme.primaryContainer : null,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    tool.$2,
                    size: 16,
                    color: isActive
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    tool.$3,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 10,
                      color: isActive
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
