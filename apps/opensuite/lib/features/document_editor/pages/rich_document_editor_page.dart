import 'package:fileutility_core/fileutility_core.dart';
import 'package:fileutility_ui_kit/fileutility_ui_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

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
          (!_isInitialized && curr.currentDocument != null) ||
          prev.status != curr.status,
      listener: (context, state) {
        if (state.currentDocument != null && !_isInitialized) {
          _titleController.text = state.currentDocument!.title;
          _contentController.text = state.currentDocument!.plainText;
          _isInitialized = true;
        }
        if (state.status == DocumentEditorStatus.saved) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Saved ✓'),
              duration: Duration(seconds: 1),
            ),
          );
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
              // Find & Replace
              IconButton(
                icon: Icon(
                  Icons.search,
                  color:
                      state.showFindReplace ? theme.colorScheme.primary : null,
                ),
                onPressed: () => context
                    .read<DocumentEditorBloc>()
                    .add(const ToggleFindReplace()),
                tooltip: 'Find & Replace (Ctrl+H)',
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
                    case 'export_txt':
                    case 'export_md':
                      final title = state.currentDocument?.title ?? 'Document';
                      final content = _contentController.text;
                      Share.share(
                        content,
                        subject:
                            '$title.${value == 'export_md' ? 'md' : 'txt'}',
                      );
                    case 'share':
                      final title = state.currentDocument?.title ?? 'Document';
                      Share.share(
                        _contentController.text,
                        subject: title,
                      );
                  }
                },
              ),
            ],
          ),
          body: Column(
            children: [
              // Formatting toolbar
              if (state.showToolbar)
                _FormattingToolbar(
                  state: state,
                  controller: _contentController,
                ),

              // Find & Replace bar
              if (state.showFindReplace) _FindReplaceBar(state: state),

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
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.4),
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
          Text(value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
  final TextEditingController controller;

  const _FormattingToolbar({
    required this.state,
    required this.controller,
  });

  void _wrap(BuildContext context, String before, String after) {
    final text = controller.text;
    final sel = controller.selection;
    if (!sel.isValid) return;
    final selected = text.substring(sel.start, sel.end);
    final newText =
        text.replaceRange(sel.start, sel.end, '$before$selected$after');
    controller.text = newText;
    controller.selection = TextSelection.collapsed(
        offset: sel.start + before.length + selected.length);
    context.read<DocumentEditorBloc>().add(
          UpdateDocumentContent(
            content: newText,
            plainText: newText,
          ),
        );
  }

  void _prefix(BuildContext context, String prefix) {
    final text = controller.text;
    final sel = controller.selection;
    if (!sel.isValid) return;
    int lineStart = sel.start;
    while (lineStart > 0 && text[lineStart - 1] != '\n') {
      lineStart--;
    }
    final newText = text.replaceRange(lineStart, lineStart, prefix);
    controller.text = newText;
    controller.selection =
        TextSelection.collapsed(offset: sel.start + prefix.length);
    context.read<DocumentEditorBloc>().add(
          UpdateDocumentContent(
            content: newText,
            plainText: newText,
          ),
        );
  }

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
              onPressed: () {
                _wrap(context, '**', '**');
                context
                    .read<DocumentEditorBloc>()
                    .add(const ApplyFormatting('bold'));
              },
            ),
            _FormatButton(
              icon: Icons.format_italic,
              label: 'Italic',
              isActive: state.activeFormats.contains('italic'),
              onPressed: () {
                _wrap(context, '*', '*');
                context
                    .read<DocumentEditorBloc>()
                    .add(const ApplyFormatting('italic'));
              },
            ),
            _FormatButton(
              icon: Icons.format_underlined,
              label: 'Underline',
              isActive: state.activeFormats.contains('underline'),
              onPressed: () {
                _wrap(context, '<u>', '</u>');
                context
                    .read<DocumentEditorBloc>()
                    .add(const ApplyFormatting('underline'));
              },
            ),
            _FormatButton(
              icon: Icons.strikethrough_s,
              label: 'Strikethrough',
              isActive: state.activeFormats.contains('strikethrough'),
              onPressed: () {
                _wrap(context, '~~', '~~');
                context
                    .read<DocumentEditorBloc>()
                    .add(const ApplyFormatting('strikethrough'));
              },
            ),
            _divider(theme),
            _FormatButton(
              icon: Icons.title,
              label: 'Heading 1',
              isActive: state.activeFormats.contains('h1'),
              onPressed: () {
                _prefix(context, '# ');
                context
                    .read<DocumentEditorBloc>()
                    .add(const ApplyFormatting('h1'));
              },
            ),
            _FormatButton(
              icon: Icons.text_fields,
              label: 'Heading 2',
              isActive: state.activeFormats.contains('h2'),
              onPressed: () {
                _prefix(context, '## ');
                context
                    .read<DocumentEditorBloc>()
                    .add(const ApplyFormatting('h2'));
              },
            ),
            _divider(theme),
            _FormatButton(
              icon: Icons.format_list_bulleted,
              label: 'Bullet List',
              isActive: state.activeFormats.contains('bullet'),
              onPressed: () {
                _prefix(context, '- ');
                context
                    .read<DocumentEditorBloc>()
                    .add(const ApplyFormatting('bullet'));
              },
            ),
            _FormatButton(
              icon: Icons.format_list_numbered,
              label: 'Numbered List',
              isActive: state.activeFormats.contains('numbered'),
              onPressed: () {
                _prefix(context, '1. ');
                context
                    .read<DocumentEditorBloc>()
                    .add(const ApplyFormatting('numbered'));
              },
            ),
            _FormatButton(
              icon: Icons.check_box,
              label: 'Checklist',
              isActive: state.activeFormats.contains('checklist'),
              onPressed: () {
                _prefix(context, '- [ ] ');
                context
                    .read<DocumentEditorBloc>()
                    .add(const ApplyFormatting('checklist'));
              },
            ),
            _divider(theme),
            _FormatButton(
              icon: Icons.format_quote,
              label: 'Quote',
              isActive: state.activeFormats.contains('quote'),
              onPressed: () {
                _prefix(context, '> ');
                context
                    .read<DocumentEditorBloc>()
                    .add(const ApplyFormatting('quote'));
              },
            ),
            _FormatButton(
              icon: Icons.code,
              label: 'Code Block',
              isActive: state.activeFormats.contains('code'),
              onPressed: () {
                _wrap(context, '\n```\n', '\n```\n');
                context
                    .read<DocumentEditorBloc>()
                    .add(const ApplyFormatting('code'));
              },
            ),
            _FormatButton(
              icon: Icons.link,
              label: 'Link',
              isActive: state.activeFormats.contains('link'),
              onPressed: () {
                _wrap(context, '[', '](url)');
                context
                    .read<DocumentEditorBloc>()
                    .add(const ApplyFormatting('link'));
              },
            ),
            _FormatButton(
              icon: Icons.image,
              label: 'Image',
              isActive: false,
              onPressed: () {
                _wrap(context, '![alt](', ')');
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

/// Find & Replace bar shown below the formatting toolbar.
class _FindReplaceBar extends StatefulWidget {
  final DocumentEditorState state;

  const _FindReplaceBar({required this.state});

  @override
  State<_FindReplaceBar> createState() => _FindReplaceBarState();
}

class _FindReplaceBarState extends State<_FindReplaceBar> {
  late TextEditingController _findController;
  late TextEditingController _replaceController;

  @override
  void initState() {
    super.initState();
    _findController = TextEditingController(text: widget.state.findQuery);
    _replaceController = TextEditingController();
  }

  @override
  void dispose() {
    _findController.dispose();
    _replaceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final matchCount = widget.state.findMatches.length;
    final currentMatch = matchCount > 0 ? widget.state.currentFindIndex + 1 : 0;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant,
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Find row
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: TextField(
                    controller: _findController,
                    decoration: InputDecoration(
                      hintText: 'Find...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide(
                          color: theme.colorScheme.outlineVariant,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 0,
                      ),
                      isDense: true,
                      suffixText:
                          matchCount > 0 ? '$currentMatch/$matchCount' : null,
                      suffixStyle: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    style: theme.textTheme.bodySmall,
                    onChanged: (value) {
                      context
                          .read<DocumentEditorBloc>()
                          .add(FindInDocument(value));
                    },
                  ),
                ),
              ),
              const SizedBox(width: 4),
              // Previous match
              IconButton(
                icon: const Icon(Icons.keyboard_arrow_up, size: 20),
                onPressed: matchCount > 0
                    ? () => context
                        .read<DocumentEditorBloc>()
                        .add(const NavigateFindMatch(forward: false))
                    : null,
                tooltip: 'Previous',
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
              ),
              // Next match
              IconButton(
                icon: const Icon(Icons.keyboard_arrow_down, size: 20),
                onPressed: matchCount > 0
                    ? () => context
                        .read<DocumentEditorBloc>()
                        .add(const NavigateFindMatch(forward: true))
                    : null,
                tooltip: 'Next',
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
              ),
              // Close
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: () => context
                    .read<DocumentEditorBloc>()
                    .add(const ToggleFindReplace()),
                tooltip: 'Close',
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Replace row
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: TextField(
                    controller: _replaceController,
                    decoration: InputDecoration(
                      hintText: 'Replace...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide(
                          color: theme.colorScheme.outlineVariant,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 0,
                      ),
                      isDense: true,
                    ),
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              // Replace single
              TextButton(
                onPressed: matchCount > 0
                    ? () => context.read<DocumentEditorBloc>().add(
                          ReplaceInDocument(
                            _findController.text,
                            _replaceController.text,
                          ),
                        )
                    : null,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 32),
                ),
                child: const Text('Replace'),
              ),
              // Replace all
              TextButton(
                onPressed: matchCount > 0
                    ? () => context.read<DocumentEditorBloc>().add(
                          ReplaceInDocument(
                            _findController.text,
                            _replaceController.text,
                            replaceAll: true,
                          ),
                        )
                    : null,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 32),
                ),
                child: const Text('All'),
              ),
            ],
          ),
        ],
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
