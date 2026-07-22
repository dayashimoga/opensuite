import 'dart:convert';
import 'dart:io' as io;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart' as fp;
import 'package:fileutility_core/fileutility_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../di/app_module.dart';
import '../bloc/presentation_bloc.dart';
import '../widgets/slide_table_widget.dart';
import '../widgets/animation_panel.dart';

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
  bool _showAnimationPanel = false;

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
        final theme = Theme.of(context);
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
                  // Shape Library Dropdown
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.category_outlined, size: 20),
                    tooltip: 'Insert Shape',
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: 'rectangle',
                        child: Row(children: [
                          Icon(Icons.crop_square, size: 18),
                          SizedBox(width: 8),
                          Text('Rectangle'),
                        ]),
                      ),
                      PopupMenuItem(
                        value: 'circle',
                        child: Row(children: [
                          Icon(Icons.circle_outlined, size: 18),
                          SizedBox(width: 8),
                          Text('Circle'),
                        ]),
                      ),
                      PopupMenuItem(
                        value: 'triangle',
                        child: Row(children: [
                          Icon(Icons.change_history, size: 18),
                          SizedBox(width: 8),
                          Text('Triangle'),
                        ]),
                      ),
                      PopupMenuItem(
                        value: 'diamond',
                        child: Row(children: [
                          Icon(Icons.details, size: 18),
                          SizedBox(width: 8),
                          Text('Diamond'),
                        ]),
                      ),
                      PopupMenuItem(
                        value: 'star',
                        child: Row(children: [
                          Icon(Icons.star_outline, size: 18),
                          SizedBox(width: 8),
                          Text('Star'),
                        ]),
                      ),
                      PopupMenuItem(
                        value: 'arrow',
                        child: Row(children: [
                          Icon(Icons.arrow_forward, size: 18),
                          SizedBox(width: 8),
                          Text('Arrow'),
                        ]),
                      ),
                      PopupMenuItem(
                        value: 'line',
                        child: Row(children: [
                          Icon(Icons.horizontal_rule, size: 18),
                          SizedBox(width: 8),
                          Text('Line'),
                        ]),
                      ),
                      PopupMenuItem(
                        value: 'callout',
                        child: Row(children: [
                          Icon(Icons.chat_bubble_outline, size: 18),
                          SizedBox(width: 8),
                          Text('Callout'),
                        ]),
                      ),
                    ],
                    onSelected: (shapeType) => _addShape(context, shapeType),
                  ),
                  IconButton(
                    icon: const Icon(Icons.table_chart_outlined, size: 20),
                    onPressed: () => _addTable(context),
                    tooltip: 'Insert Table',
                  ),
                  IconButton(
                    icon: const Icon(Icons.image_outlined, size: 20),
                    onPressed: () => _addImagePlaceholder(context),
                    tooltip: 'Add Image',
                  ),
                  IconButton(
                    icon: Icon(
                      _showAnimationPanel
                          ? Icons.animation
                          : Icons.animation_outlined,
                      size: 20,
                      color: _showAnimationPanel
                          ? theme.colorScheme.primary
                          : null,
                    ),
                    onPressed: () => setState(
                        () => _showAnimationPanel = !_showAnimationPanel),
                    tooltip: 'Animations Panel',
                  ),
                  const SizedBox(width: 8),
                  // Present button
                  FilledButton.tonalIcon(
                    onPressed: () => _startPresenterMode(context, state),
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
                  if (_showAnimationPanel)
                    AnimationPanel(
                      animations: state.activeSlide?.animations ?? const [],
                      elements: state.activeSlide?.elements ?? const [],
                      selectedElementId: state.selectedElementId,
                      onAdd: (anim) => context
                          .read<PresentationBloc>()
                          .add(AddAnimation(anim)),
                      onRemove: (id) => context
                          .read<PresentationBloc>()
                          .add(RemoveAnimation(id)),
                      onUpdate: (id, anim) => context
                          .read<PresentationBloc>()
                          .add(UpdateAnimation(id, anim)),
                      onReorder: (oldIdx, newIdx) => context
                          .read<PresentationBloc>()
                          .add(ReorderAnimations(oldIdx, newIdx)),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _startPresenterMode(BuildContext context, PresentationState state) {
    if (state.slides.isEmpty) return;
    int currentIndex = state.activeSlideIndex.clamp(0, state.slides.length - 1);

    showDialog(
      context: context,
      useSafeArea: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final currentSlide = state.slides[currentIndex];
            return _PresentationModeView(
              slide: currentSlide,
              slideIndex: currentIndex,
              totalSlides: state.slides.length,
              onExit: () => Navigator.of(dialogContext).pop(),
              onNext: () {
                if (currentIndex < state.slides.length - 1) {
                  setDialogState(() => currentIndex++);
                }
              },
              onPrevious: () {
                if (currentIndex > 0) {
                  setDialogState(() => currentIndex--);
                }
              },
            );
          },
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

  void _addShape(BuildContext context, [String shapeType = 'rectangle']) {
    context.read<PresentationBloc>().add(AddElement(SlideElement(
          id: 'shape_${DateTime.now().microsecondsSinceEpoch}',
          type: 'shape',
          x: 0.3,
          y: 0.3,
          width: 0.2,
          height: 0.2,
          shapeType: shapeType,
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

  void _addTable(BuildContext context) {
    // Encode table data as JSON in content field (3x3 default)
    final tableData = jsonEncode({
      'rows': 3,
      'cols': 3,
      'cells': [
        ['Header 1', 'Header 2', 'Header 3'],
        ['Cell 1', 'Cell 2', 'Cell 3'],
        ['Cell 4', 'Cell 5', 'Cell 6'],
      ],
    });
    context.read<PresentationBloc>().add(AddElement(SlideElement(
          id: 'table_${DateTime.now().microsecondsSinceEpoch}',
          type: 'table',
          x: 0.1,
          y: 0.25,
          width: 0.8,
          height: 0.45,
          content: tableData,
        )));
  }
}

/// Element formatting bar shown when an element is selected.
class _ElementFormatBar extends StatefulWidget {
  final String elementId;
  final SlideData? slide;

  const _ElementFormatBar({
    required this.elementId,
    required this.slide,
  });

  @override
  State<_ElementFormatBar> createState() => _ElementFormatBarState();
}

class _ElementFormatBarState extends State<_ElementFormatBar> {
  late TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    final element = widget.slide?.elements
        .cast<SlideElement?>()
        .firstWhere((e) => e?.id == widget.elementId, orElse: () => null);
    _textController = TextEditingController(text: element?.content ?? '');
  }

  @override
  void didUpdateWidget(_ElementFormatBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.elementId != widget.elementId) {
      final element = widget.slide?.elements
          .cast<SlideElement?>()
          .firstWhere((e) => e?.id == widget.elementId, orElse: () => null);
      _textController.text = element?.content ?? '';
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final element = widget.slide?.elements
        .cast<SlideElement?>()
        .firstWhere((e) => e?.id == widget.elementId, orElse: () => null);
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
                      widget.elementId,
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
                  .add(FormatElement(widget.elementId, textAlign: 'left')),
              iconSize: 18,
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
            IconButton(
              icon: const Icon(Icons.format_align_center, size: 18),
              isSelected: element.textAlign == 'center',
              onPressed: () => context
                  .read<PresentationBloc>()
                  .add(FormatElement(widget.elementId, textAlign: 'center')),
              iconSize: 18,
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
            IconButton(
              icon: const Icon(Icons.format_align_right, size: 18),
              isSelected: element.textAlign == 'right',
              onPressed: () => context
                  .read<PresentationBloc>()
                  .add(FormatElement(widget.elementId, textAlign: 'right')),
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
                initialValue: element.fontSize,
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
                        .add(FormatElement(widget.elementId, fontSize: v));
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            // Content editing TextField
            Expanded(
              child: SizedBox(
                height: 28,
                child: TextField(
                  controller: _textController,
                  decoration: InputDecoration(
                    hintText: 'Edit text...',
                    isDense: true,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  style: theme.textTheme.bodySmall,
                  onChanged: (value) {
                    context.read<PresentationBloc>().add(
                          UpdateElement(
                            widget.elementId,
                            element.copyWith(content: value),
                          ),
                        );
                  },
                ),
              ),
            ),
          ] else if (element.type == 'image') ...[
            Text(
              'Image Element',
              style: theme.textTheme.bodySmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.photo_library, size: 18),
              tooltip: 'Choose Image File',
              onPressed: () async {
                final result = await fp.FilePicker.platform.pickFiles(
                  type: fp.FileType.image,
                  allowMultiple: false,
                  withData: true,
                );
                if (result != null && result.files.isNotEmpty) {
                  final file = result.files.single;
                  String imgData = '';
                  if (file.bytes != null) {
                    final base64String = base64Encode(file.bytes!);
                    final extension = file.extension ?? 'png';
                    imgData = 'data:image/$extension;base64,$base64String';
                  } else if (file.path != null) {
                    imgData = file.path!;
                  }
                  if (context.mounted && imgData.isNotEmpty) {
                    final updatedElement = element.copyWith(content: imgData);
                    context.read<PresentationBloc>().add(
                          UpdateElement(widget.elementId, updatedElement),
                        );
                  }
                }
              },
              iconSize: 18,
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                element.content.length > 50
                    ? '${element.content.substring(0, 50)}...'
                    : element.content,
                style: theme.textTheme.labelSmall?.copyWith(color: Colors.grey),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
          const Spacer(),
          // Layer ordering
          IconButton(
            icon: const Icon(Icons.flip_to_front, size: 18),
            tooltip: 'Bring to Front',
            onPressed: () => context
                .read<PresentationBloc>()
                .add(BringToFront(widget.elementId)),
            iconSize: 18,
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
          IconButton(
            icon: const Icon(Icons.flip_to_back, size: 18),
            tooltip: 'Send to Back',
            onPressed: () => context
                .read<PresentationBloc>()
                .add(SendToBack(widget.elementId)),
            iconSize: 18,
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
          const SizedBox(width: 8),
          // Delete
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
            tooltip: 'Delete Element',
            onPressed: () => context
                .read<PresentationBloc>()
                .add(DeleteElement(widget.elementId)),
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
            child: ReorderableListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: slides.length,
              onReorderItem: (oldIndex, newIndex) {
                context
                    .read<PresentationBloc>()
                    .add(ReorderSlides(oldIndex, newIndex));
              },
              itemBuilder: (context, index) {
                final isActive = index == activeIndex;
                return GestureDetector(
                  key: ValueKey(slides[index].id),
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
                onPressed: () => _showAddSlideLayoutDialog(context),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Slide'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddSlideLayoutDialog(BuildContext context) {
    final bloc = context.read<PresentationBloc>();
    showDialog(
      context: context,
      builder: (_) => SimpleDialog(
        title: const Text('Choose Slide Layout'),
        children: [
          SimpleDialogOption(
            onPressed: () {
              Navigator.pop(context);
              bloc.add(AddSlide(
                layout: 'title',
                initialElements: [
                  SlideElement(
                    id: 'title_${DateTime.now().microsecondsSinceEpoch}',
                    type: 'text',
                    x: 0.15,
                    y: 0.25,
                    width: 0.7,
                    height: 0.2,
                    content: 'Presentation Title',
                    fontSize: 36,
                    fontWeight: 'bold',
                    textAlign: 'center',
                  ),
                  SlideElement(
                    id: 'sub_${DateTime.now().microsecondsSinceEpoch}',
                    type: 'text',
                    x: 0.2,
                    y: 0.5,
                    width: 0.6,
                    height: 0.15,
                    content: 'Subtitle or Presenter Name',
                    fontSize: 20,
                    textAlign: 'center',
                  ),
                ],
              ));
            },
            child: const Row(children: [
              Icon(Icons.title),
              SizedBox(width: 12),
              Text('Title Slide'),
            ]),
          ),
          SimpleDialogOption(
            onPressed: () {
              Navigator.pop(context);
              bloc.add(AddSlide(
                layout: 'title_content',
                initialElements: [
                  SlideElement(
                    id: 'title_${DateTime.now().microsecondsSinceEpoch}',
                    type: 'text',
                    x: 0.1,
                    y: 0.1,
                    width: 0.8,
                    height: 0.15,
                    content: 'Slide Header',
                    fontSize: 28,
                    fontWeight: 'bold',
                  ),
                  SlideElement(
                    id: 'body_${DateTime.now().microsecondsSinceEpoch}',
                    type: 'text',
                    x: 0.1,
                    y: 0.3,
                    width: 0.8,
                    height: 0.55,
                    content:
                        '• First key bullet point\n• Second key bullet point\n• Summary detail',
                    fontSize: 20,
                  ),
                ],
              ));
            },
            child: const Row(children: [
              Icon(Icons.view_headline),
              SizedBox(width: 12),
              Text('Title & Content'),
            ]),
          ),
          SimpleDialogOption(
            onPressed: () {
              Navigator.pop(context);
              bloc.add(const AddSlide(
                layout: 'blank',
              ));
            },
            child: const Row(children: [
              Icon(Icons.crop_free),
              SizedBox(width: 12),
              Text('Blank Slide'),
            ]),
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
                        onResize: (dw, dh) {
                          final newW =
                              (element.width + dw / constraints.maxWidth)
                                  .clamp(0.05, 1.0);
                          final newH =
                              (element.height + dh / constraints.maxHeight)
                                  .clamp(0.05, 1.0);
                          context
                              .read<PresentationBloc>()
                              .add(ResizeElement(element.id, newW, newH));
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
class _CanvasElement extends StatefulWidget {
  final SlideElement element;
  final Size canvasSize;
  final bool isSelected;
  final VoidCallback onTap;
  final void Function(double dx, double dy) onMove;
  final void Function(double dw, double dh) onResize;
  final VoidCallback onDelete;

  const _CanvasElement({
    required this.element,
    required this.canvasSize,
    required this.isSelected,
    required this.onTap,
    required this.onMove,
    required this.onResize,
    required this.onDelete,
  });

  @override
  State<_CanvasElement> createState() => _CanvasElementState();
}

class _CanvasElementState extends State<_CanvasElement> {
  bool _isEditingInline = false;
  late TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.element.content);
  }

  @override
  void didUpdateWidget(_CanvasElement old) {
    super.didUpdateWidget(old);
    if (!_isEditingInline && widget.element.content != _textController.text) {
      _textController.text = widget.element.content;
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _finishInlineEditing() {
    setState(() => _isEditingInline = false);
    context.read<PresentationBloc>().add(UpdateElementContent(
          widget.element.id,
          _textController.text,
        ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final left = widget.element.x * widget.canvasSize.width;
    final top = widget.element.y * widget.canvasSize.height;
    final width = widget.element.width * widget.canvasSize.width;
    final height = widget.element.height * widget.canvasSize.height;

    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: GestureDetector(
        onTap: () {
          widget.onTap();
        },
        onDoubleTap: () {
          if (widget.element.type == 'text') {
            setState(() => _isEditingInline = true);
          }
        },
        onPanUpdate: (details) =>
            widget.onMove(details.delta.dx, details.delta.dy),
        child: Container(
          decoration: BoxDecoration(
            color: widget.element.fillColor != null
                ? _parseColor(widget.element.fillColor!)
                : null,
            border: Border.all(
              color: widget.isSelected
                  ? theme.colorScheme.primary
                  : (widget.element.borderColor != null
                      ? _parseColor(widget.element.borderColor!)
                      : Colors.transparent),
              width: widget.isSelected ? 2 : widget.element.borderWidth,
            ),
            borderRadius: widget.element.shapeType == 'circle'
                ? BorderRadius.circular(9999)
                : BorderRadius.circular(2),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Element content
              Positioned.fill(
                child: _buildContent(theme),
              ),
              // Delete button when selected
              if (widget.isSelected)
                Positioned(
                  top: -10,
                  right: -10,
                  child: GestureDetector(
                    onTap: widget.onDelete,
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
              // 8 Resize handles when selected
              if (widget.isSelected) ...[
                // Top-Left handle
                Positioned(
                  top: -5,
                  left: -5,
                  child: _resizeHandle(theme, (details) {
                    widget.onResize(-details.delta.dx, -details.delta.dy);
                  }),
                ),
                // Top-Right handle
                Positioned(
                  top: -5,
                  right: -5,
                  child: _resizeHandle(theme, (details) {
                    widget.onResize(details.delta.dx, -details.delta.dy);
                  }),
                ),
                // Bottom-Left handle
                Positioned(
                  bottom: -5,
                  left: -5,
                  child: _resizeHandle(theme, (details) {
                    widget.onResize(-details.delta.dx, details.delta.dy);
                  }),
                ),
                // Bottom-Right handle
                Positioned(
                  bottom: -5,
                  right: -5,
                  child: _resizeHandle(theme, (details) {
                    widget.onResize(details.delta.dx, details.delta.dy);
                  }),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _resizeHandle(
      ThemeData theme, void Function(DragUpdateDetails) onDrag) {
    return GestureDetector(
      onPanUpdate: onDrag,
      child: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: theme.colorScheme.primary,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
        ),
      ),
    );
  }

  Widget _buildContent(ThemeData theme) {
    switch (widget.element.type) {
      case 'text':
        if (_isEditingInline) {
          return Padding(
            padding: const EdgeInsets.all(4),
            child: TextField(
              controller: _textController,
              autofocus: true,
              maxLines: null,
              expands: true,
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              style: TextStyle(
                fontSize: widget.element.fontSize * 0.5,
                fontWeight: widget.element.fontWeight == 'bold'
                    ? FontWeight.bold
                    : FontWeight.normal,
                fontStyle: widget.element.fontWeight == 'italic'
                    ? FontStyle.italic
                    : FontStyle.normal,
                color: _parseColor(widget.element.textColor),
              ),
              textAlign: widget.element.textAlign == 'center'
                  ? TextAlign.center
                  : widget.element.textAlign == 'right'
                      ? TextAlign.right
                      : TextAlign.left,
              onChanged: (val) {
                context.read<PresentationBloc>().add(UpdateElementContent(
                      widget.element.id,
                      val,
                    ));
              },
              onSubmitted: (_) => _finishInlineEditing(),
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.all(8),
          child: Text(
            widget.element.content,
            style: TextStyle(
              fontSize: widget.element.fontSize * 0.5, // Scale to canvas
              fontWeight: widget.element.fontWeight == 'bold'
                  ? FontWeight.bold
                  : FontWeight.normal,
              fontStyle: widget.element.fontWeight == 'italic'
                  ? FontStyle.italic
                  : FontStyle.normal,
              color: _parseColor(widget.element.textColor),
            ),
            textAlign: widget.element.textAlign == 'center'
                ? TextAlign.center
                : widget.element.textAlign == 'right'
                    ? TextAlign.right
                    : TextAlign.left,
          ),
        );
      case 'shape':
        return const SizedBox.expand();
      case 'image':
        if (widget.element.content.startsWith('data:image')) {
          try {
            final uri = Uri.parse(widget.element.content);
            final base64Data = uri.data?.contentAsBytes();
            if (base64Data != null) {
              return Image.memory(
                base64Data,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Center(
                  child: Icon(Icons.broken_image, color: Colors.grey, size: 36),
                ),
              );
            }
          } catch (_) {}
        } else if (!kIsWeb && io.File(widget.element.content).existsSync()) {
          return Image.file(
            io.File(widget.element.content),
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const Center(
              child: Icon(Icons.broken_image, color: Colors.grey, size: 36),
            ),
          );
        } else if (widget.element.content.startsWith('http')) {
          return Image.network(
            widget.element.content,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const Center(
              child: Icon(Icons.broken_image, color: Colors.grey, size: 36),
            ),
          );
        }
        return Container(
          color: theme.colorScheme.surfaceContainerHighest,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.image,
                  size: 32, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(height: 4),
              Text('Image placeholder',
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ],
          ),
        );
      case 'table':
        SlideTable table;
        try {
          final data =
              jsonDecode(widget.element.content) as Map<String, dynamic>;
          final cells = <String, String>{};
          final cellsData = data['cells'] as List?;
          if (cellsData != null) {
            for (int r = 0; r < cellsData.length; r++) {
              final row = cellsData[r] as List;
              for (int c = 0; c < row.length; c++) {
                cells['$r,$c'] = row[c].toString();
              }
            }
          }
          table = SlideTable(
            id: widget.element.id,
            rows: (data['rows'] as int?) ?? 3,
            columns: (data['cols'] as int?) ?? 3,
            cells: cells,
            headerColor: '#4A90D9',
          );
        } catch (_) {
          table = SlideTable(
            id: widget.element.id,
            rows: 3,
            columns: 3,
            headerColor: '#4A90D9',
          );
        }
        return SlideTableWidget(
          table: table,
          onChanged: (updated) {
            // Serialize table back to JSON content
            final cells = <List<String>>[];
            for (int r = 0; r < updated.rows; r++) {
              final row = <String>[];
              for (int c = 0; c < updated.columns; c++) {
                row.add(updated.getCell(r, c));
              }
              cells.add(row);
            }
            final content = jsonEncode({
              'rows': updated.rows,
              'cols': updated.columns,
              'cells': cells,
            });
            context
                .read<PresentationBloc>()
                .add(UpdateElementContent(widget.element.id, content));
          },
        );
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
