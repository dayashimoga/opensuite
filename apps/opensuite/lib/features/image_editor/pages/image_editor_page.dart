import 'dart:math' as math;

import 'package:fileutility_ui_kit/fileutility_ui_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/image_editor_bloc.dart';

/// Image editor page with zoom/pan, adjustment sliders,
/// rotation, flip, crop, resize, and export.
class ImageEditorPage extends StatelessWidget {
  final String? filePath;
  const ImageEditorPage({super.key, this.filePath});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ImageEditorBloc>(
      create: (_) {
        final bloc = ImageEditorBloc();
        if (filePath != null) {
          bloc.add(LoadImage(filePath!));
        }
        return bloc;
      },
      child: const _EditorContent(),
    );
  }
}

class _EditorContent extends StatelessWidget {
  const _EditorContent();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<ImageEditorBloc, ImageEditorState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: Text(state.filePath?.split('/').last ?? 'Image Editor'),
            actions: [
              // Undo/Redo
              IconButton(
                icon: const Icon(Icons.undo, size: 20),
                onPressed: state.canUndo
                    ? () => context.read<ImageEditorBloc>().add(const UndoEdit())
                    : null,
                tooltip: 'Undo',
              ),
              IconButton(
                icon: const Icon(Icons.redo, size: 20),
                onPressed: state.canRedo
                    ? () => context.read<ImageEditorBloc>().add(const RedoEdit())
                    : null,
                tooltip: 'Redo',
              ),
              const SizedBox(width: 8),
              // Reset
              IconButton(
                icon: const Icon(Icons.refresh, size: 20),
                onPressed: state.hasEdits
                    ? () => context.read<ImageEditorBloc>().add(const ResetEdits())
                    : null,
                tooltip: 'Reset',
              ),
              const SizedBox(width: 8),
              // Export
              PopupMenuButton<String>(
                icon: const Icon(Icons.save_alt, size: 20),
                tooltip: 'Export',
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'png', child: Text('Export as PNG')),
                  PopupMenuItem(value: 'jpeg', child: Text('Export as JPEG')),
                  PopupMenuItem(value: 'webp', child: Text('Export as WebP')),
                ],
                onSelected: (format) => context.read<ImageEditorBloc>()
                    .add(ExportImage(format: format)),
              ),
            ],
          ),
          body: Row(
            children: [
              // Tool sidebar
              _ToolSidebar(
                activeTool: state.activeTool,
                onSelectTool: (tool) => context.read<ImageEditorBloc>()
                    .add(SelectTool(tool)),
              ),
              // Main canvas
              Expanded(
                child: _ImageCanvas(state: state),
              ),
              // Adjustments panel
              _AdjustmentsPanel(state: state),
            ],
          ),
          // Status bar
          bottomNavigationBar: _StatusBar(state: state),
        );
      },
    );
  }
}

/// Tool sidebar with editing tools.
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
      ('resize', Icons.photo_size_select_large, 'Resize'),
    ];

    return Container(
      width: 64,
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: theme.colorScheme.outlineVariant, width: 0.5),
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
                width: 64,
                height: 56,
                decoration: BoxDecoration(
                  color: isActive
                      ? theme.colorScheme.primaryContainer
                      : null,
                  border: Border(
                    left: BorderSide(
                      color: isActive ? theme.colorScheme.primary : Colors.transparent,
                      width: 3,
                    ),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(tool.$2, size: 20,
                      color: isActive
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tool.$3,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 9,
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

/// Main image canvas with zoom and pan.
class _ImageCanvas extends StatelessWidget {
  final ImageEditorState state;

  const _ImageCanvas({required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (state.status == ImageEditorStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.filePath == null) {
      return EmptyState(
        icon: Icons.image_outlined,
        title: 'No Image Open',
        description: 'Open an image to start editing',
        actionLabel: 'Open Image',
        onAction: () {},
      );
    }

    return Container(
      color: theme.colorScheme.surfaceContainerLowest,
      child: InteractiveViewer(
        minScale: 0.1,
        maxScale: 10.0,
        child: Center(
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..rotateZ(state.adjustments.rotation * math.pi / 180)
              ..scale(
                state.adjustments.flipHorizontal ? -1.0 : 1.0,
                state.adjustments.flipVertical ? -1.0 : 1.0,
              ),
            child: Container(
              width: 600,
              height: 400,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ColorFiltered(
                colorFilter: ColorFilter.matrix(_buildColorMatrix(state.adjustments)),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.image, size: 80,
                        color: theme.colorScheme.primary.withValues(alpha: 0.3)),
                      const SizedBox(height: 8),
                      Text(
                        state.filePath?.split('/').last ?? '',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                      Text(
                        '${state.imageWidth} × ${state.imageHeight}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Builds a 5x4 color matrix from adjustments (brightness, contrast, saturation).
  List<double> _buildColorMatrix(ImageAdjustments adj) {
    final b = adj.brightness;
    final c = adj.contrast;
    final s = adj.saturation;

    // Luminance weights
    const lr = 0.2126;
    const lg = 0.7152;
    const lb = 0.0722;

    final sr = (1 - s) * lr;
    final sg = (1 - s) * lg;
    final sb = (1 - s) * lb;

    return [
      c * (sr + s), c * sg, c * sb, 0, b * 255 * 0.5,
      c * sr, c * (sg + s), c * sb, 0, b * 255 * 0.5,
      c * sr, c * sg, c * (sb + s), 0, b * 255 * 0.5,
      0, 0, 0, 1, 0,
    ];
  }
}

/// Right-side adjustments panel.
class _AdjustmentsPanel extends StatelessWidget {
  final ImageEditorState state;

  const _AdjustmentsPanel({required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bloc = context.read<ImageEditorBloc>();

    return Container(
      width: 220,
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: theme.colorScheme.outlineVariant, width: 0.5),
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (state.activeTool == 'adjust') ...[
              Text('Adjustments', style: theme.textTheme.titleSmall),
              const SizedBox(height: 12),
              _SliderControl(
                label: 'Brightness',
                value: state.adjustments.brightness,
                min: -1.0,
                max: 1.0,
                onChanged: (v) => bloc.add(SetBrightness(v)),
              ),
              _SliderControl(
                label: 'Contrast',
                value: state.adjustments.contrast,
                min: 0.0,
                max: 2.0,
                onChanged: (v) => bloc.add(SetContrast(v)),
              ),
              _SliderControl(
                label: 'Saturation',
                value: state.adjustments.saturation,
                min: 0.0,
                max: 2.0,
                onChanged: (v) => bloc.add(SetSaturation(v)),
              ),
            ],
            if (state.activeTool == 'rotate') ...[
              Text('Transform', style: theme.textTheme.titleSmall),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _ActionChip(label: 'Rotate 90°', icon: Icons.rotate_right,
                    onTap: () => bloc.add(const RotateImage(90))),
                  _ActionChip(label: 'Rotate -90°', icon: Icons.rotate_left,
                    onTap: () => bloc.add(const RotateImage(-90))),
                  _ActionChip(label: 'Flip H', icon: Icons.flip,
                    onTap: () => bloc.add(const FlipImage(horizontal: true))),
                  _ActionChip(label: 'Flip V', icon: Icons.flip,
                    onTap: () => bloc.add(const FlipImage(horizontal: false))),
                ],
              ),
              const SizedBox(height: 16),
              _SliderControl(
                label: 'Rotation',
                value: state.adjustments.rotation,
                min: -180,
                max: 180,
                onChanged: (v) => bloc.add(RotateImage(v - state.adjustments.rotation)),
              ),
            ],
            if (state.activeTool == 'resize') ...[
              Text('Resize', style: theme.textTheme.titleSmall),
              const SizedBox(height: 12),
              Text('Width: ${state.imageWidth}px', style: theme.textTheme.bodySmall),
              Text('Height: ${state.imageHeight}px', style: theme.textTheme.bodySmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _ActionChip(label: '50%', icon: Icons.photo_size_select_small,
                    onTap: () => bloc.add(ResizeImageDimensions(
                      state.imageWidth ~/ 2, state.imageHeight ~/ 2))),
                  _ActionChip(label: '75%', icon: Icons.photo_size_select_large,
                    onTap: () => bloc.add(ResizeImageDimensions(
                      (state.imageWidth * 0.75).toInt(), (state.imageHeight * 0.75).toInt()))),
                  _ActionChip(label: '1080p', icon: Icons.hd,
                    onTap: () => bloc.add(const ResizeImageDimensions(1920, 1080))),
                  _ActionChip(label: '720p', icon: Icons.sd,
                    onTap: () => bloc.add(const ResizeImageDimensions(1280, 720))),
                ],
              ),
            ],
            if (state.activeTool == 'crop') ...[
              Text('Crop', style: theme.textTheme.titleSmall),
              const SizedBox(height: 12),
              Text('Drag handles on the image to crop.',
                style: theme.textTheme.bodySmall),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _ActionChip(label: 'Free', icon: Icons.crop_free, onTap: () {}),
                  _ActionChip(label: '16:9', icon: Icons.crop_16_9, onTap: () {}),
                  _ActionChip(label: '4:3', icon: Icons.crop_landscape, onTap: () {}),
                  _ActionChip(label: '1:1', icon: Icons.crop_square, onTap: () {}),
                ],
              ),
            ],
          ],
        ),
      ),
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

  const _ActionChip({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 16),
      label: Text(label),
      onPressed: onTap,
    );
  }
}

/// Status bar showing image info.
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
          Text('${state.imageWidth} × ${state.imageHeight}',
            style: theme.textTheme.labelSmall),
          const Spacer(),
          if (state.adjustments.rotation != 0)
            Text('Rotation: ${state.adjustments.rotation.toStringAsFixed(0)}°  ',
              style: theme.textTheme.labelSmall),
          if (state.hasEdits)
            Text('Modified', style: theme.textTheme.labelSmall?.copyWith(
              color: Colors.orange)),
          if (state.status == ImageEditorStatus.saving)
            const SizedBox(width: 16, height: 16,
              child: CircularProgressIndicator(strokeWidth: 2)),
        ],
      ),
    );
  }
}
