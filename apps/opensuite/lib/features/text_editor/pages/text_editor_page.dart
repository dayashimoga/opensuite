import 'dart:async';

import 'package:fileutility_core/fileutility_core.dart';
import 'package:fileutility_l10n/fileutility_l10n.dart';
import 'package:fileutility_ui_kit/fileutility_ui_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../di/app_module.dart';
import '../../settings/bloc/settings_bloc.dart';
import '../bloc/text_editor_bloc.dart';

/// Text/Markdown editor page with live preview and toolbar.
class TextEditorPage extends StatelessWidget {
  const TextEditorPage({this.documentId, super.key});

  /// The document ID to edit. Null creates a new document.
  final String? documentId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final bloc = AppModule.textEditorBloc;
        if (documentId != null) {
          bloc.add(LoadDocument(documentId!));
        } else {
          bloc.add(const CreateNewDocument());
        }
        return bloc;
      },
      child: const _TextEditorContent(),
    );
  }
}

class _TextEditorContent extends StatefulWidget {
  const _TextEditorContent();

  @override
  State<_TextEditorContent> createState() => _TextEditorContentState();
}

class _TextEditorContentState extends State<_TextEditorContent> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  late final TextEditingController _findController;
  late final TextEditingController _replaceController;
  Timer? _autosaveTimer;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _contentController = TextEditingController();
    _findController = TextEditingController();
    _replaceController = TextEditingController();

    _autosaveTimer = Timer.periodic(
      const Duration(seconds: AppConstants.autosaveIntervalSeconds),
      (_) {
        final bloc = context.read<TextEditorBloc>();
        if (bloc.state.isModified) {
          bloc.add(const SaveDocument());
        }
      },
    );
  }

  @override
  void dispose() {
    _autosaveTimer?.cancel();
    _titleController.dispose();
    _contentController.dispose();
    _findController.dispose();
    _replaceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocConsumer<TextEditorBloc, TextEditorState>(
      listenWhen: (prev, curr) =>
          prev.title != curr.title || prev.content != curr.content,
      listener: (context, state) {
        if (_titleController.text != state.title) {
          _titleController.text = state.title;
        }
        if (_contentController.text != state.content) {
          _contentController.text = state.content;
        }
      },
      builder: (context, state) {
        return CallbackShortcuts(
          bindings: {
            const SingleActivator(LogicalKeyboardKey.keyS, control: true): () {
              context.read<TextEditorBloc>().add(const SaveDocument());
            },
            const SingleActivator(LogicalKeyboardKey.keyF, control: true): () {
              context.read<TextEditorBloc>().add(const ToggleFindReplace());
            },
            const SingleActivator(LogicalKeyboardKey.keyP, control: true): () {
              if (state.isMarkdown) {
                context.read<TextEditorBloc>().add(const TogglePreview());
              }
            },
          },
          child: Focus(
            autofocus: true,
            child: Scaffold(
              appBar: AppBar(
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: () {
                    if (state.isModified) {
                      context.read<TextEditorBloc>().add(const SaveDocument());
                    }
                    context.go('/editor');
                  },
                ),
                title: SizedBox(
                  height: 36,
                  child: TextField(
                    controller: _titleController,
                    onChanged: (value) {
                      context
                          .read<TextEditorBloc>()
                          .add(UpdateDocumentTitle(value));
                    },
                    style: theme.textTheme.titleMedium,
                    decoration: const InputDecoration(
                      hintText: AppLocalizations.untitled,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      fillColor: Colors.transparent,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                actions: [
                  // Undo/Redo (native controller)
                  IconButton(
                    icon: const Icon(Icons.undo, size: 20),
                    tooltip: 'Undo (Ctrl+Z)',
                    onPressed: () {
                      if (_contentController.value.composing ==
                          TextRange.empty) {
                        // Trigger native undo via action
                      }
                    },
                  ),
                  // File type toggle
                  IconButton(
                    icon: Icon(
                      state.isMarkdown
                          ? Icons.code_rounded
                          : Icons.text_snippet_rounded,
                    ),
                    tooltip: state.isMarkdown ? 'Markdown' : 'Plain Text',
                    onPressed: () {
                      context.read<TextEditorBloc>().add(CreateNewDocument(
                            title: state.title,
                            fileType: state.isMarkdown ? 'text' : 'markdown',
                          ));
                    },
                  ),

                  // Preview toggle (markdown only)
                  if (state.isMarkdown)
                    IconButton(
                      icon: Icon(
                        state.showPreview
                            ? Icons.edit_rounded
                            : Icons.preview_rounded,
                      ),
                      tooltip: state.showPreview
                          ? '${AppLocalizations.edit} (Ctrl+P)'
                          : '${AppLocalizations.preview} (Ctrl+P)',
                      onPressed: () {
                        context
                            .read<TextEditorBloc>()
                            .add(const TogglePreview());
                      },
                    ),

                  // Find & Replace
                  IconButton(
                    icon: const Icon(Icons.find_replace_rounded),
                    tooltip: '${AppLocalizations.findAndReplace} (Ctrl+F)',
                    onPressed: () {
                      context
                          .read<TextEditorBloc>()
                          .add(const ToggleFindReplace());
                    },
                  ),

                  // Save indicator
                  if (state.isModified)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 2),
                      child: Icon(Icons.circle, size: 10, color: Colors.orange),
                    ),

                  // Save
                  IconButton(
                    icon: Icon(
                      state.isModified
                          ? Icons.save_rounded
                          : Icons.check_circle_outline_rounded,
                    ),
                    tooltip: '${AppLocalizations.save} (Ctrl+S)',
                    onPressed: () {
                      context.read<TextEditorBloc>().add(const SaveDocument());
                    },
                  ),
                ],
              ),
              body: Column(
                children: [
                  // Find & Replace bar
                  if (state.showFindReplace)
                    _FindReplaceBar(
                      findController: _findController,
                      replaceController: _replaceController,
                      matchCount: state.findMatches,
                    ),

                  // Editor content
                  Expanded(
                    child: state.showPreview && state.isMarkdown
                        ? _buildMarkdownPreview(context, state)
                        : _buildEditor(context, state),
                  ),

                  // Formatting toolbar for markdown (when editing)
                  if (state.isMarkdown && !state.showPreview)
                    _MarkdownFormatBar(controller: _contentController),

                  // Status bar
                  _StatusBar(state: state),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEditor(BuildContext context, TextEditorState state) {
    final theme = Theme.of(context);
    final settings = context.watch<SettingsBloc>().state;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: TextField(
        controller: _contentController,
        onChanged: (value) {
          context.read<TextEditorBloc>().add(UpdateDocumentContent(value));
        },
        style: state.isMarkdown
            ? AppTypography.monoStyle(
                fontSize: settings.fontSize,
                color: theme.colorScheme.onSurface,
              )
            : theme.textTheme.bodyLarge?.copyWith(
                fontSize: settings.fontSize,
                height: 1.6,
              ),
        decoration: const InputDecoration(
          hintText: 'Start typing...',
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          fillColor: Colors.transparent,
          filled: false,
        ),
        maxLines: null,
        expands: true,
        textAlignVertical: TextAlignVertical.top,
        keyboardType: TextInputType.multiline,
      ),
    );
  }

  Widget _buildMarkdownPreview(
    BuildContext context,
    TextEditorState state,
  ) {
    final theme = Theme.of(context);

    // Simple markdown rendering (in production, use flutter_markdown)
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: SelectableText(
        state.content.isEmpty ? 'Preview will appear here...' : state.content,
        style: theme.textTheme.bodyLarge?.copyWith(height: 1.8),
      ),
    );
  }
}

class _FindReplaceBar extends StatelessWidget {
  const _FindReplaceBar({
    required this.findController,
    required this.replaceController,
    required this.matchCount,
  });

  final TextEditingController findController;
  final TextEditingController replaceController;
  final int matchCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(bottom: BorderSide(color: theme.dividerColor)),
      ),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 36,
              child: TextField(
                controller: findController,
                onChanged: (value) {
                  context.read<TextEditorBloc>().add(FindInDocument(value));
                },
                style: theme.textTheme.bodySmall,
                decoration: InputDecoration(
                  hintText: AppLocalizations.findPlaceholder,
                  suffixText: '$matchCount matches',
                  suffixStyle: theme.textTheme.labelSmall,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: SizedBox(
              height: 36,
              child: TextField(
                controller: replaceController,
                style: theme.textTheme.bodySmall,
                decoration: const InputDecoration(
                  hintText: AppLocalizations.replacePlaceholder,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          TextButton(
            onPressed: () {
              context.read<TextEditorBloc>().add(ReplaceInDocument(
                    find: findController.text,
                    replace: replaceController.text,
                  ));
            },
            child: const Text('Replace'),
          ),
          TextButton(
            onPressed: () {
              context.read<TextEditorBloc>().add(ReplaceInDocument(
                    find: findController.text,
                    replace: replaceController.text,
                    replaceAll: true,
                  ));
            },
            child: const Text(AppLocalizations.replaceAll),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 18),
            onPressed: () {
              context.read<TextEditorBloc>().add(const ToggleFindReplace());
            },
          ),
        ],
      ),
    );
  }
}

class _StatusBar extends StatelessWidget {
  const _StatusBar({required this.state});

  final TextEditorState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(top: BorderSide(color: theme.dividerColor)),
      ),
      child: Row(
        children: [
          Icon(
            state.isMarkdown ? Icons.code_rounded : Icons.text_snippet_rounded,
            size: 14,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            state.isMarkdown ? 'Markdown' : 'Plain Text',
            style: theme.textTheme.labelSmall,
          ),
          const SizedBox(width: AppSpacing.lg),
          Text(
            '${state.lineCount} lines',
            style: theme.textTheme.labelSmall,
          ),
          const SizedBox(width: AppSpacing.lg),
          Text(
            '${state.wordCount} ${AppLocalizations.wordCount.toLowerCase()}',
            style: theme.textTheme.labelSmall,
          ),
          const SizedBox(width: AppSpacing.lg),
          Text(
            '${state.charCount} chars',
            style: theme.textTheme.labelSmall,
          ),
          const Spacer(),
          if (state.status == TextEditorStatus.saving)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Text('Saving...', style: theme.textTheme.labelSmall),
              ],
            )
          else if (state.isModified)
            Text(
              'Modified',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            )
          else if (state.lastSavedAt != null)
            Text(
              'Saved ${AppDateUtils.formatRelative(state.lastSavedAt!)}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.success,
              ),
            ),
        ],
      ),
    );
  }
}

/// Markdown formatting toolbar for the text editor.
class _MarkdownFormatBar extends StatelessWidget {
  final TextEditingController controller;

  const _MarkdownFormatBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant, width: 0.5),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _btn(Icons.format_bold, 'Bold', () => _wrap('**', '**')),
            _btn(Icons.format_italic, 'Italic', () => _wrap('*', '*')),
            _btn(Icons.strikethrough_s, 'Strikethrough',
                () => _wrap('~~', '~~')),
            _sep(),
            _btn(Icons.title, 'Heading', () => _prefix('# ')),
            _btn(
                Icons.format_list_bulleted, 'Bullet List', () => _prefix('- ')),
            _btn(Icons.format_list_numbered, 'Numbered List',
                () => _prefix('1. ')),
            _btn(Icons.check_box_outlined, 'Checkbox', () => _prefix('- [ ] ')),
            _sep(),
            _btn(Icons.code, 'Code', () => _wrap('`', '`')),
            _btn(Icons.data_object, 'Code Block',
                () => _wrap('\n```\n', '\n```\n')),
            _btn(Icons.link, 'Link', () => _wrap('[', '](url)')),
            _btn(Icons.format_quote, 'Quote', () => _prefix('> ')),
            _btn(Icons.horizontal_rule, 'Rule', () => _insert('\n---\n')),
          ],
        ),
      ),
    );
  }

  Widget _btn(IconData icon, String tip, VoidCallback onTap) {
    return IconButton(
      icon: Icon(icon, size: 18),
      tooltip: tip,
      onPressed: onTap,
      padding: const EdgeInsets.all(4),
      constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
    );
  }

  Widget _sep() {
    return const SizedBox(
        width: 1, height: 18, child: VerticalDivider(width: 1));
  }

  void _wrap(String before, String after) {
    final text = controller.text;
    final sel = controller.selection;
    if (!sel.isValid) return;
    final selected = text.substring(sel.start, sel.end);
    controller.text =
        text.replaceRange(sel.start, sel.end, '$before$selected$after');
    controller.selection = TextSelection.collapsed(
        offset: sel.start + before.length + selected.length);
  }

  void _prefix(String prefix) {
    final text = controller.text;
    final sel = controller.selection;
    if (!sel.isValid) return;
    int lineStart = sel.start;
    while (lineStart > 0 && text[lineStart - 1] != '\n') {
      lineStart--;
    }
    controller.text = text.replaceRange(lineStart, lineStart, prefix);
    controller.selection =
        TextSelection.collapsed(offset: sel.start + prefix.length);
  }

  void _insert(String snippet) {
    final text = controller.text;
    final sel = controller.selection;
    if (!sel.isValid) return;
    controller.text = text.replaceRange(sel.start, sel.end, snippet);
    controller.selection =
        TextSelection.collapsed(offset: sel.start + snippet.length);
  }
}
