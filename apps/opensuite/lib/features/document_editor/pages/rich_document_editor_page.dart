import 'package:fileutility_core/fileutility_core.dart';
import 'package:fileutility_ui_kit/fileutility_ui_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../di/app_module.dart';
import '../bloc/document_editor_bloc.dart';

/// Rich document editor page.
///
/// Provides a formatting toolbar, rich text editing surface,
/// autosave, undo/redo, and keyboard shortcut support.
class RichDocumentEditorPage extends StatelessWidget {
  /// The document ID to edit, or null for a new document.
  final String? documentId;

  /// Creates a [RichDocumentEditorPage].
  const RichDocumentEditorPage({super.key, this.documentId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<DocumentEditorBloc>(
      create: (_) {
        final bloc = AppModule.documentEditorBloc;
        if (documentId != null) {
          bloc.add(OpenDocument(documentId!));
        } else {
          bloc.add(const CreateDocument());
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
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _contentController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocConsumer<DocumentEditorBloc, DocumentEditorState>(
      listenWhen: (prev, curr) =>
          prev.currentDocument?.id != curr.currentDocument?.id ||
          (!_isInitialized && curr.currentDocument != null),
      listener: (context, state) {
        if (state.currentDocument != null && !_isInitialized) {
          _titleController.text = state.currentDocument!.title;
          _contentController.text = state.currentDocument!.plainText;
          _isInitialized = true;
        }
      },
      builder: (context, state) {
        if (state.status == DocumentEditorStatus.loading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                if (state.hasUnsavedChanges) {
                  context.read<DocumentEditorBloc>().add(const SaveDocument());
                }
                context.go('/documents');
              },
            ),
            title: SizedBox(
              height: 40,
              child: TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  hintText: 'Document Title',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                style: theme.textTheme.titleMedium,
                onChanged: (value) {
                  context
                      .read<DocumentEditorBloc>()
                      .add(UpdateDocumentTitle(value));
                },
              ),
            ),
            actions: [
              // Undo
              IconButton(
                icon: const Icon(Icons.undo),
                onPressed: state.undoStack.isNotEmpty
                    ? () => context
                        .read<DocumentEditorBloc>()
                        .add(const UndoChange())
                    : null,
                tooltip: 'Undo (Ctrl+Z)',
              ),
              // Redo
              IconButton(
                icon: const Icon(Icons.redo),
                onPressed: state.redoStack.isNotEmpty
                    ? () => context
                        .read<DocumentEditorBloc>()
                        .add(const RedoChange())
                    : null,
                tooltip: 'Redo (Ctrl+Shift+Z)',
              ),
              // Save indicator
              _SaveIndicator(state: state),
              const SizedBox(width: 8),
              // More actions
              PopupMenuButton<String>(
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'export_txt',
                    child: Row(
                      children: [
                        Icon(Icons.text_snippet),
                        SizedBox(width: 8),
                        Text('Export as TXT'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'export_md',
                    child: Row(
                      children: [
                        Icon(Icons.code),
                        SizedBox(width: 8),
                        Text('Export as Markdown'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'word_count',
                    child: Row(
                      children: [
                        Icon(Icons.analytics_outlined),
                        SizedBox(width: 8),
                        Text('Document Stats'),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) {
                  switch (value) {
                    case 'word_count':
                      _showStats(context, state);
                  }
                },
              ),
            ],
          ),
          body: Column(
            children: [
              // Formatting toolbar
              if (state.showToolbar) _FormattingToolbar(state: state),

              // Editor surface
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  child: TextField(
                    controller: _contentController,
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    decoration: InputDecoration(
                      hintText: 'Start writing...',
                      border: InputBorder.none,
                      hintStyle: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
                    ),
                    style: theme.textTheme.bodyLarge?.copyWith(
                      height: 1.8,
                    ),
                    onChanged: (value) {
                      context.read<DocumentEditorBloc>().add(
                            UpdateDocumentContent(
                              content: value,
                              plainText: value,
                            ),
                          );
                    },
                  ),
                ),
              ),

              // Status bar
              _StatusBar(state: state),
            ],
          ),
        );
      },
    );
  }

  void _showStats(BuildContext context, DocumentEditorState state) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Document Statistics'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StatRow('Words', '${state.wordCount}'),
            _StatRow('Characters', '${state.characterCount}'),
            _StatRow('Format', state.currentDocument?.format ?? 'rich'),
            _StatRow(
              'Created',
              state.currentDocument != null
                  ? AppDateUtils.formatRelative(
                      state.currentDocument!.createdAt)
                  : '-',
            ),
            _StatRow(
              'Modified',
              state.currentDocument != null
                  ? AppDateUtils.formatRelative(
                      state.currentDocument!.modifiedAt)
                  : '-',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;

  const _StatRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(value, style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          )),
        ],
      ),
    );
  }
}

/// Formatting toolbar with bold, italic, underline, headings, lists, etc.
class _FormattingToolbar extends StatelessWidget {
  final DocumentEditorState state;

  const _FormattingToolbar({required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 48,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant,
            width: 0.5,
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: Row(
          children: [
            _FormatButton(
              icon: Icons.format_bold,
              label: 'Bold',
              isActive: state.activeFormats.contains('bold'),
              onPressed: () => context
                  .read<DocumentEditorBloc>()
                  .add(const ApplyFormatting('bold')),
            ),
            _FormatButton(
              icon: Icons.format_italic,
              label: 'Italic',
              isActive: state.activeFormats.contains('italic'),
              onPressed: () => context
                  .read<DocumentEditorBloc>()
                  .add(const ApplyFormatting('italic')),
            ),
            _FormatButton(
              icon: Icons.format_underlined,
              label: 'Underline',
              isActive: state.activeFormats.contains('underline'),
              onPressed: () => context
                  .read<DocumentEditorBloc>()
                  .add(const ApplyFormatting('underline')),
            ),
            _FormatButton(
              icon: Icons.strikethrough_s,
              label: 'Strikethrough',
              isActive: state.activeFormats.contains('strikethrough'),
              onPressed: () => context
                  .read<DocumentEditorBloc>()
                  .add(const ApplyFormatting('strikethrough')),
            ),
            _divider(theme),
            _FormatButton(
              icon: Icons.title,
              label: 'Heading 1',
              isActive: state.activeFormats.contains('h1'),
              onPressed: () => context
                  .read<DocumentEditorBloc>()
                  .add(const ApplyFormatting('h1')),
            ),
            _FormatButton(
              icon: Icons.text_fields,
              label: 'Heading 2',
              isActive: state.activeFormats.contains('h2'),
              onPressed: () => context
                  .read<DocumentEditorBloc>()
                  .add(const ApplyFormatting('h2')),
            ),
            _divider(theme),
            _FormatButton(
              icon: Icons.format_list_bulleted,
              label: 'Bullet List',
              isActive: state.activeFormats.contains('bullet'),
              onPressed: () => context
                  .read<DocumentEditorBloc>()
                  .add(const ApplyFormatting('bullet')),
            ),
            _FormatButton(
              icon: Icons.format_list_numbered,
              label: 'Numbered List',
              isActive: state.activeFormats.contains('numbered'),
              onPressed: () => context
                  .read<DocumentEditorBloc>()
                  .add(const ApplyFormatting('numbered')),
            ),
            _FormatButton(
              icon: Icons.check_box,
              label: 'Checklist',
              isActive: state.activeFormats.contains('checklist'),
              onPressed: () => context
                  .read<DocumentEditorBloc>()
                  .add(const ApplyFormatting('checklist')),
            ),
            _divider(theme),
            _FormatButton(
              icon: Icons.format_quote,
              label: 'Quote',
              isActive: state.activeFormats.contains('quote'),
              onPressed: () => context
                  .read<DocumentEditorBloc>()
                  .add(const ApplyFormatting('quote')),
            ),
            _FormatButton(
              icon: Icons.code,
              label: 'Code Block',
              isActive: state.activeFormats.contains('code'),
              onPressed: () => context
                  .read<DocumentEditorBloc>()
                  .add(const ApplyFormatting('code')),
            ),
            _FormatButton(
              icon: Icons.link,
              label: 'Link',
              isActive: state.activeFormats.contains('link'),
              onPressed: () => context
                  .read<DocumentEditorBloc>()
                  .add(const ApplyFormatting('link')),
            ),
            _FormatButton(
              icon: Icons.image,
              label: 'Image',
              isActive: false,
              onPressed: () {
                // Image insertion will be handled in a future sprint
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _divider(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: SizedBox(
        height: 24,
        child: VerticalDivider(
          width: 1,
          color: theme.colorScheme.outlineVariant,
        ),
      ),
    );
  }
}

class _FormatButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onPressed;

  const _FormatButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Tooltip(
      message: label,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isActive
                ? theme.colorScheme.primaryContainer
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            icon,
            size: 20,
            color: isActive
                ? theme.colorScheme.onPrimaryContainer
                : theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

/// Save status indicator.
class _SaveIndicator extends StatelessWidget {
  final DocumentEditorState state;

  const _SaveIndicator({required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    IconData icon;
    String label;
    Color color;

    if (state.status == DocumentEditorStatus.saving) {
      icon = Icons.cloud_upload;
      label = 'Saving...';
      color = theme.colorScheme.primary;
    } else if (state.hasUnsavedChanges) {
      icon = Icons.circle;
      label = 'Unsaved';
      color = theme.colorScheme.error;
    } else {
      icon = Icons.cloud_done;
      label = 'Saved';
      color = theme.colorScheme.primary.withValues(alpha: 0.6);
    }

    return Tooltip(
      message: label,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }
}

/// Status bar showing word count, character count, and position.
class _StatusBar extends StatelessWidget {
  final DocumentEditorState state;

  const _StatusBar({required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outlineVariant,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Text(
            '${state.wordCount} words',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(
            '${state.characterCount} characters',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          Text(
            state.currentDocument?.format.toUpperCase() ?? 'RICH',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          if (state.undoStack.isNotEmpty)
            Text(
              'History: ${state.undoStack.length}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}
