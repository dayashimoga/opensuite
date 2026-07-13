import 'package:fileutility_core/fileutility_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../di/app_module.dart';
import '../bloc/presentation_bloc.dart';

/// Slide editor page with canvas, slide panel, and speaker notes.
class PresentationEditorPage extends StatelessWidget {
  final String? presentationId;
  const PresentationEditorPage({super.key, this.presentationId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<PresentationBloc>(
      create: (_) {
        final bloc = AppModule.presentationBloc;
        if (presentationId != null) {
          bloc.add(OpenPresentation(presentationId!));
        } else {
          bloc.add(const CreatePresentation());
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
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PresentationBloc, PresentationState>(
      listenWhen: (prev, curr) => prev.status != curr.status,
      listener: (context, state) {
        if (state.status == PresentationStatus.saved) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Saved ✓'),
              duration: Duration(seconds: 1),
            ),
          );
        }
      },
      builder: (context, state) {
        if (state.status == PresentationStatus.loading) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        // Full-screen presentation mode
        if (state.isPresentationMode) {
          return _PresentationModeView(
            slide: state.activeSlide,
            slideIndex: state.activeSlideIndex,
            totalSlides: state.slides.length,
            onExit: () => context
                .read<PresentationBloc>()
                .add(const TogglePresentationMode()),
            onNext: () {
              if (state.activeSlideIndex < state.slides.length - 1) {
                context
                    .read<PresentationBloc>()
                    .add(SelectSlide(state.activeSlideIndex + 1));
              }
            },
            onPrevious: () {
              if (state.activeSlideIndex > 0) {
                context
                    .read<PresentationBloc>()
                    .add(SelectSlide(state.activeSlideIndex - 1));
              }
            },
          );
        }

        return CallbackShortcuts(
          bindings: {
            const SingleActivator(LogicalKeyboardKey.keyZ, control: true): () {
              context.read<PresentationBloc>().add(const UndoPresentation());
            },
            const SingleActivator(LogicalKeyboardKey.keyY, control: true): () {
              context.read<PresentationBloc>().add(const RedoPresentation());
            },
            const SingleActivator(LogicalKeyboardKey.keyS, control: true): () {
              context.read<PresentationBloc>().add(const SavePresentation());
            },
            const SingleActivator(LogicalKeyboardKey.delete): () {
              if (state.selectedElementId != null) {
                context
                    .read<PresentationBloc>()
                    .add(DeleteElement(state.selectedElementId!));
              }
            },
          },
          child: Focus(
            autofocus: true,
            child: Scaffold(
              appBar: AppBar(
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    if (state.hasUnsavedChanges) {
                      context
                          .read<PresentationBloc>()
                          .add(const SavePresentation());
                    }
                    context.go('/presentations');
                  },
                ),
                title: Text(state.currentPresentation?.title ?? 'Presentation'),
                actions: [
                  // Undo/Redo
                  IconButton(
                    icon: const Icon(Icons.undo, size: 20),
                    onPressed: state.canUndo
                        ? () => context
                            .read<PresentationBloc>()
                            .add(const UndoPresentation())
                        : null,
                    tooltip: 'Undo (Ctrl+Z)',
                  ),
                  IconButton(
                    icon: const Icon(Icons.redo, size: 20),
                    onPressed: state.canRedo
                        ? () => context
                            .read<PresentationBloc>()
                            .add(const RedoPresentation())
                        : null,
                    tooltip: 'Redo (Ctrl+Y)',
                  ),
                  const SizedBox(width: 4),
                  // Add element buttons
                  IconButton(
                    icon: const Icon(Icons.text_fields, size: 20),
                    onPressed: () => _addTextBox(context),
                    tooltip: 'Add Text',
                  ),
                  IconButton(
                    icon: const Icon(Icons.crop_square, size: 20),
                    onPressed: () => _addShape(context),
                    tooltip: 'Add Shape',
                  ),
                  IconButton(
                    icon: const Icon(Icons.image_outlined, size: 20),
                    onPressed: () => _addImagePlaceholder(context),
                    tooltip: 'Add Image',
                  ),
                  const SizedBox(width: 8),
                  // Present button
                  FilledButton.tonalIcon(
                    onPressed: () => context
                        .read<PresentationBloc>()
                        .add(const TogglePresentationMode()),
                    icon: const Icon(Icons.slideshow, size: 18),
                    label: const Text('Present'),
                  ),
                  const SizedBox(width: 8),
                  // Save indicator
                  if (state.hasUnsavedChanges)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(Icons.circle, size: 10, color: Colors.orange),
                    ),
                  // Save
                  IconButton(
                    icon: const Icon(Icons.save_outlined),
                    onPressed: () => context
                        .read<PresentationBloc>()
                        .add(const SavePresentation()),
                    tooltip: 'Save (Ctrl+S)',
                  ),
                  // Share
                  IconButton(
                    icon: const Icon(Icons.share),
                    tooltip: 'Share',
                    onPressed: () {
                      final title =
                          state.currentPresentation?.title ?? 'Presentation';
                      Share.share(
                        '$title - ${state.slides.length} slides',
                        subject: title,
                      );
                    },
                  ),
                ],
              ),
              body: Row(
                children: [
                  // Slide panel (thumbnails)
                  _SlidePanel(
                    slides: state.slides,
                    activeIndex: state.activeSlideIndex,
                    onSelect: (i) =>
                        context.read<PresentationBloc>().add(SelectSlide(i)),
                    onAdd: () =>
                        context.read<PresentationBloc>().add(const AddSlide()),
                    onDelete: (i) =>
                        context.read<PresentationBloc>().add(DeleteSlide(i)),
                    onDuplicate: (i) =>
                        context.read<PresentationBloc>().add(DuplicateSlide(i)),
                  ),
                  // Main canvas
                  Expanded(
                    child: Column(
                      children: [
                        // Slide canvas
                        Expanded(
                          flex: 3,
                          child: _SlideCanvas(
                            slide: state.activeSlide,
                            selectedElementId: state.selectedElementId,
                            onSelectElement: (id) => context
                                .read<PresentationBloc>()
                                .add(SelectElement(id)),
                            onMoveElement: (id, x, y) => context
                                .read<PresentationBloc>()
                                .add(MoveElement(id, x, y)),
                            onDeleteElement: (id) => context
                                .read<PresentationBloc>()
                                .add(DeleteElement(id)),
                          ),
                        ),
                        // Element formatting bar (shown when element selected)
                        if (state.selectedElementId != null)
                          _ElementFormatBar(
                            elementId: state.selectedElementId!,
                            slide: state.activeSlide,
                          ),
                        // Speaker notes
                        _SpeakerNotesPanel(
                          notes: state.activeSlide?.speakerNotes ?? '',
                          onChanged: (notes) => context
                              .read<PresentationBloc>()
                              .add(UpdateSpeakerNotes(notes)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _addTextBox(BuildContext context) {
    context.read<PresentationBloc>().add(AddElement(SlideElement(
          id: 'text_${DateTime.now().microsecondsSinceEpoch}',
          type: 'text',
          x: 0.2,
          y: 0.3,
          width: 0.6,
          height: 0.15,
          content: 'Click to edit text',
          fontSize: 24,
        )));
  }

  void _addShape(BuildContext context) {
    context.read<PresentationBloc>().add(AddElement(SlideElement(
          id: 'shape_${DateTime.now().microsecondsSinceEpoch}',
          type: 'shape',
          x: 0.3,
          y: 0.3,
          width: 0.2,
          height: 0.2,
          shapeType: 'rectangle',
          fillColor: '#4A90D9',
        )));
  }

  void _addImagePlaceholder(BuildContext context) {
    context.read<PresentationBloc>().add(AddElement(SlideElement(
          id: 'img_${DateTime.now().microsecondsSinceEpoch}',
          type: 'image',
          x: 0.25,
          y: 0.25,
          width: 0.5,
          height: 0.4,
          content: 'Image placeholder',
          fillColor: '#E0E0E0',
        )));
  }
}

/// Element formatting bar shown when an element is selected.
class _ElementFormatBar extends StatelessWidget {
  final String elementId;
  final SlideData? slide;

  const _ElementFormatBar({
    required this.elementId,
    required this.slide,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final element = slide?.elements
        .cast<SlideElement?>()
        .firstWhere((e) => e?.id == elementId, orElse: () => null);
    if (element == null) return const SizedBox.shrink();

    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        border: Border(
          bottom:
              BorderSide(color: theme.colorScheme.outlineVariant, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          if (element.type == 'text') ...[
            // Bold toggle
            IconButton(
              icon: const Icon(Icons.format_bold, size: 18),
              isSelected: element.fontWeight == 'bold',
              onPressed: () {
                context.read<PresentationBloc>().add(FormatElement(
                      elementId,
                      fontWeight:
                          element.fontWeight == 'bold' ? 'normal' : 'bold',
                    ));
              },
              iconSize: 18,
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
            // Alignment
            IconButton(
              icon: const Icon(Icons.format_align_left, size: 18),
              isSelected: element.textAlign == 'left',
              onPressed: () => context
                  .read<PresentationBloc>()
                  .add(FormatElement(elementId, textAlign: 'left')),
              iconSize: 18,
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
            IconButton(
              icon: const Icon(Icons.format_align_center, size: 18),
              isSelected: element.textAlign == 'center',
              onPressed: () => context
                  .read<PresentationBloc>()
                  .add(FormatElement(elementId, textAlign: 'center')),
              iconSize: 18,
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
            IconButton(
              icon: const Icon(Icons.format_align_right, size: 18),
              isSelected: element.textAlign == 'right',
              onPressed: () => context
                  .read<PresentationBloc>()
                  .add(FormatElement(elementId, textAlign: 'right')),
              iconSize: 18,
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
            const SizedBox(width: 8),
            // Font size
            SizedBox(
              width: 56,
              height: 28,
              child: DropdownButtonFormField<double>(
                value: element.fontSize,
                isDense: true,
                isExpanded: true,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 6),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: BorderSide(
                        color: theme.colorScheme.outlineVariant, width: 0.5),
                  ),
                ),
                style: theme.textTheme.bodySmall,
                items: const [
                  DropdownMenuItem(value: 14.0, child: Text('14')),
                  DropdownMenuItem(value: 18.0, child: Text('18')),
                  DropdownMenuItem(value: 24.0, child: Text('24')),
                  DropdownMenuItem(value: 32.0, child: Text('32')),
                  DropdownMenuItem(value: 44.0, child: Text('44')),
                  DropdownMenuItem(value: 56.0, child: Text('56')),
                ],
                onChanged: (v) {
                  if (v != null) {
                    context
                        .read<PresentationBloc>()
                        .add(FormatElement(elementId, fontSize: v));
                  }
                },
              ),
            ),
          ],
          const Spacer(),
          // Layer ordering
          IconButton(
            icon: const Icon(Icons.flip_to_front, size: 18),
            tooltip: 'Bring to Front',
            onPressed: () =>
                context.read<PresentationBloc>().add(BringToFront(elementId)),
            iconSize: 18,
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
          IconButton(
            icon: const Icon(Icons.flip_to_back, size: 18),
            tooltip: 'Send to Back',
            onPressed: () =>
                context.read<PresentationBloc>().add(SendToBack(elementId)),
            iconSize: 18,
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
          const SizedBox(width: 8),
          // Delete
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
            tooltip: 'Delete Element',
            onPressed: () =>
                context.read<PresentationBloc>().add(DeleteElement(elementId)),
            iconSize: 18,
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }
}

/// Slide thumbnail panel on the left.
class _SlidePanel extends StatelessWidget {
  final List<SlideData> slides;
  final int activeIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onAdd;
  final ValueChanged<int> onDelete;
  final ValueChanged<int> onDuplicate;

  const _SlidePanel({
    required this.slides,
    required this.activeIndex,
    required this.onSelect,
    required this.onAdd,
    required this.onDelete,
    required this.onDuplicate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 160,
      decoration: BoxDecoration(
        border: Border(
          right:
              BorderSide(color: theme.colorScheme.outlineVariant, width: 0.5),
        ),
      ),
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: slides.length,
              itemBuilder: (context, index) {
                final isActive = index == activeIndex;
                return GestureDetector(
                  onTap: () => onSelect(index),
                  onLongPress: () => _showSlideMenu(context, index),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isActive
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outlineVariant,
                        width: isActive ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Container(
                        color: _parseColor(slides[index].backgroundColor),
                        alignment: Alignment.bottomLeft,
                        padding: const EdgeInsets.all(4),
                        child: Text(
                          '${index + 1}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // Add slide button
          Padding(
            padding: const EdgeInsets.all(8),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Slide'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSlideMenu(BuildContext context, int index) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.copy),
            title: const Text('Duplicate'),
            onTap: () {
              Navigator.pop(context);
              onDuplicate(index);
            },
          ),
          if (slides.length > 1)
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                onDelete(index);
              },
            ),
        ],
      ),
    );
  }

  Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return Colors.white;
    }
  }
}

/// Main slide canvas with interactive elements.
class _SlideCanvas extends StatelessWidget {
  final SlideData? slide;
  final String? selectedElementId;
  final ValueChanged<String?> onSelectElement;
  final void Function(String, double, double) onMoveElement;
  final ValueChanged<String> onDeleteElement;

  const _SlideCanvas({
    required this.slide,
    required this.selectedElementId,
    required this.onSelectElement,
    required this.onMoveElement,
    required this.onDeleteElement,
  });

  @override
  Widget build(BuildContext context) {
    if (slide == null) {
      return const Center(child: Text('No slide selected'));
    }

    return GestureDetector(
      onTap: () => onSelectElement(null),
      child: Container(
        margin: const EdgeInsets.all(16),
        child: Center(
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              decoration: BoxDecoration(
                color: _parseColor(slide!.backgroundColor),
                borderRadius: BorderRadius.circular(2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Stack(
                    children: slide!.elements.map((element) {
                      return _CanvasElement(
                        element: element,
                        canvasSize: constraints.biggest,
                        isSelected: element.id == selectedElementId,
                        onTap: () => onSelectElement(element.id),
                        onMove: (dx, dy) {
                          final newX = (element.x + dx / constraints.maxWidth)
                              .clamp(0.0, 1.0);
                          final newY = (element.y + dy / constraints.maxHeight)
                              .clamp(0.0, 1.0);
                          onMoveElement(element.id, newX, newY);
                        },
                        onDelete: () => onDeleteElement(element.id),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return Colors.white;
    }
  }
}

/// A single interactive element on the slide canvas.
class _CanvasElement extends StatelessWidget {
  final SlideElement element;
  final Size canvasSize;
  final bool isSelected;
  final VoidCallback onTap;
  final void Function(double dx, double dy) onMove;
  final VoidCallback onDelete;

  const _CanvasElement({
    required this.element,
    required this.canvasSize,
    required this.isSelected,
    required this.onTap,
    required this.onMove,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final left = element.x * canvasSize.width;
    final top = element.y * canvasSize.height;
    final width = element.width * canvasSize.width;
    final height = element.height * canvasSize.height;

    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: GestureDetector(
        onTap: onTap,
        onPanUpdate: (details) => onMove(details.delta.dx, details.delta.dy),
        child: Container(
          decoration: BoxDecoration(
            color: element.fillColor != null
                ? _parseColor(element.fillColor!)
                : null,
            border: Border.all(
              color: isSelected
                  ? theme.colorScheme.primary
                  : (element.borderColor != null
                      ? _parseColor(element.borderColor!)
                      : Colors.transparent),
              width: isSelected ? 2 : element.borderWidth,
            ),
            borderRadius: element.shapeType == 'circle'
                ? BorderRadius.circular(9999)
                : BorderRadius.circular(2),
          ),
          child: Stack(
            children: [
              // Element content
              Positioned.fill(
                child: _buildContent(theme),
              ),
              // Delete button when selected
              if (isSelected)
                Positioned(
                  top: -8,
                  right: -8,
                  child: GestureDetector(
                    onTap: onDelete,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.error,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.close,
                          size: 12, color: theme.colorScheme.onError),
                    ),
                  ),
                ),
              // Resize handles when selected
              if (isSelected) ...[
                // Bottom-right resize handle
                Positioned(
                  bottom: -4,
                  right: -4,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(ThemeData theme) {
    switch (element.type) {
      case 'text':
        return Padding(
          padding: const EdgeInsets.all(8),
          child: Text(
            element.content,
            style: TextStyle(
              fontSize: element.fontSize * 0.5, // Scale to canvas
              fontWeight: element.fontWeight == 'bold'
                  ? FontWeight.bold
                  : FontWeight.normal,
              color: _parseColor(element.textColor),
            ),
            textAlign: element.textAlign == 'center'
                ? TextAlign.center
                : element.textAlign == 'right'
                    ? TextAlign.right
                    : TextAlign.left,
          ),
        );
      case 'shape':
        return const SizedBox.expand();
      default:
        return const SizedBox.expand();
    }
  }

  Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return Colors.black;
    }
  }
}

/// Speaker notes panel at the bottom.
class _SpeakerNotesPanel extends StatelessWidget {
  final String notes;
  final ValueChanged<String> onChanged;

  const _SpeakerNotesPanel({required this.notes, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 100,
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant, width: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Text(
              'Speaker Notes',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: TextField(
              controller: TextEditingController(text: notes),
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                hintText: 'Add speaker notes...',
              ),
              style: theme.textTheme.bodySmall,
              maxLines: null,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

/// Full-screen presentation mode view.
class _PresentationModeView extends StatelessWidget {
  final SlideData? slide;
  final int slideIndex;
  final int totalSlides;
  final VoidCallback onExit;
  final VoidCallback onNext;
  final VoidCallback onPrevious;

  const _PresentationModeView({
    required this.slide,
    required this.slideIndex,
    required this.totalSlides,
    required this.onExit,
    required this.onNext,
    required this.onPrevious,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: KeyboardListener(
        focusNode: FocusNode()..requestFocus(),
        onKeyEvent: (event) {
          if (event is KeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.escape) onExit();
            if (event.logicalKey == LogicalKeyboardKey.arrowRight ||
                event.logicalKey == LogicalKeyboardKey.space) {
              onNext();
            }
            if (event.logicalKey == LogicalKeyboardKey.arrowLeft) onPrevious();
          }
        },
        child: GestureDetector(
          onTap: onNext,
          child: Stack(
            children: [
              // Slide content
              Center(
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Container(
                    color: slide != null
                        ? _parseColor(slide!.backgroundColor)
                        : Colors.white,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        if (slide == null) return const SizedBox.expand();
                        return Stack(
                          children: slide!.elements.map((element) {
                            return Positioned(
                              left: element.x * constraints.maxWidth,
                              top: element.y * constraints.maxHeight,
                              width: element.width * constraints.maxWidth,
                              height: element.height * constraints.maxHeight,
                              child: _buildPresentationElement(element),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ),
                ),
              ),
              // Slide counter
              Positioned(
                bottom: 16,
                right: 16,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${slideIndex + 1} / $totalSlides',
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
              ),
              // Exit button
              Positioned(
                top: 16,
                right: 16,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 28),
                  onPressed: onExit,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPresentationElement(SlideElement element) {
    switch (element.type) {
      case 'text':
        return Container(
          padding: const EdgeInsets.all(8),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              element.content,
              style: TextStyle(
                fontSize: element.fontSize,
                fontWeight: element.fontWeight == 'bold'
                    ? FontWeight.bold
                    : FontWeight.normal,
                color: _parseColor(element.textColor),
              ),
              textAlign: element.textAlign == 'center'
                  ? TextAlign.center
                  : element.textAlign == 'right'
                      ? TextAlign.right
                      : TextAlign.left,
            ),
          ),
        );
      case 'shape':
        return Container(
          decoration: BoxDecoration(
            color: element.fillColor != null
                ? _parseColor(element.fillColor!)
                : Colors.blue,
            borderRadius: element.shapeType == 'circle'
                ? BorderRadius.circular(9999)
                : BorderRadius.circular(4),
          ),
        );
      default:
        return const SizedBox.expand();
    }
  }

  Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return Colors.white;
    }
  }
}
