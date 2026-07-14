import 'dart:async';

import 'package:fileutility_core/fileutility_core.dart';
import 'package:fileutility_l10n/fileutility_l10n.dart';
import 'package:fileutility_storage/fileutility_storage.dart';
import 'package:fileutility_ui_kit/fileutility_ui_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../di/app_module.dart';
import '../bloc/notes_bloc.dart';

/// Note editor page for creating and editing notes.
///
/// Supports plain text, markdown, and checklist content types
/// with autosave functionality.
class NoteEditorPage extends StatelessWidget {
  const NoteEditorPage({this.noteId, super.key});

  final String? noteId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<NotesBloc>(
      create: (_) => AppModule.notesBloc,
      child: _NoteEditorContent(noteId: noteId),
    );
  }
}

class _NoteEditorContent extends StatefulWidget {
  const _NoteEditorContent({this.noteId});

  final String? noteId;

  @override
  State<_NoteEditorContent> createState() => _NoteEditorContentState();
}

class _NoteEditorContentState extends State<_NoteEditorContent> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  NoteEntity? _note;
  NoteContentType _contentType = NoteContentType.plain;
  Timer? _autosaveTimer;
  bool _isModified = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _contentController = TextEditingController();
    _loadNote();
  }

  Future<void> _loadNote() async {
    if (widget.noteId != null) {
      final noteDao = sl<NoteDao>();
      final note = await noteDao.getById(widget.noteId!);
      if (note != null && mounted) {
        setState(() {
          _note = note;
          _titleController.text = note.title;
          _contentController.text = note.content;
          _contentType = note.contentType;
          _isLoading = false;
        });
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } else {
      setState(() => _isLoading = false);
    }

    _autosaveTimer = Timer.periodic(
      const Duration(seconds: AppConstants.autosaveIntervalSeconds),
      (_) => _autoSave(),
    );
  }

  @override
  void dispose() {
    _autosaveTimer?.cancel();
    if (_isModified) _save();
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _onContentChanged() {
    if (!_isModified) {
      setState(() => _isModified = true);
    }
  }

  Future<void> _autoSave() async {
    if (_isModified) {
      await _save();
    }
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    final content = _contentController.text;

    if (title.isEmpty && content.isEmpty) return;

    final bloc = context.read<NotesBloc>();
    if (_note != null) {
      bloc.add(UpdateNote(_note!.copyWith(
        title: title.isEmpty ? 'Untitled' : title,
        content: content,
        contentType: _contentType,
      )));
    } else {
      bloc.add(CreateNote(
        title: title.isEmpty ? 'Untitled' : title,
        content: content,
        contentType: _contentType,
      ));
    }

    setState(() => _isModified = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Saved ✓'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(),
        body: const AppLoadingIndicator(message: 'Loading note...'),
      );
    }

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyS, control: true): () {
          _save();
        },
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () {
                if (_isModified) _save();
                context.go('/notes');
              },
            ),
            title: Text(widget.noteId != null
                ? AppLocalizations.editNote
                : AppLocalizations.newNote),
            actions: [
              PopupMenuButton<NoteContentType>(
                icon: const Icon(Icons.text_format_rounded),
                tooltip: 'Content type',
                initialValue: _contentType,
                onSelected: (type) {
                  setState(() {
                    _contentType = type;
                    _isModified = true;
                  });
                },
                itemBuilder: (context) => NoteContentType.values.map((type) {
                  return PopupMenuItem(
                    value: type,
                    child: Row(
                      children: [
                        Icon(
                          _iconForType(type),
                          size: 18,
                          color: _contentType == type
                              ? theme.colorScheme.primary
                              : null,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(type.label),
                      ],
                    ),
                  );
                }).toList(),
              ),
              IconButton(
                icon: Icon(
                  _isModified
                      ? Icons.save_rounded
                      : Icons.check_circle_outline_rounded,
                ),
                tooltip: AppLocalizations.save,
                onPressed: _save,
              ),
              IconButton(
                icon: const Icon(Icons.share_rounded),
                tooltip: 'Share',
                onPressed: () {
                  final title = _titleController.text.isNotEmpty
                      ? _titleController.text
                      : 'Note';
                  final content = _contentController.text;
                  Share.share(
                    '$title\n\n$content',
                    subject: title,
                  );
                },
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                TextField(
                  controller: _titleController,
                  onChanged: (_) => _onContentChanged(),
                  style: theme.textTheme.headlineSmall,
                  decoration: const InputDecoration(
                    hintText: AppLocalizations.noteTitle,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    fillColor: Colors.transparent,
                    filled: false,
                  ),
                  maxLines: 1,
                ),
                const Divider(),
                Expanded(
                  child: TextField(
                    controller: _contentController,
                    onChanged: (_) => _onContentChanged(),
                    style: _contentType == NoteContentType.plain
                        ? theme.textTheme.bodyLarge
                        : AppTypography.monoStyle(
                            fontSize: 14,
                            color: theme.colorScheme.onSurface,
                          ),
                    decoration: InputDecoration(
                      hintText: _hintForType(_contentType),
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
                ),
                if (_contentType == NoteContentType.markdown ||
                    _contentType == NoteContentType.richText)
                  _MarkdownToolbar(
                    controller: _contentController,
                    onChanged: _onContentChanged,
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    border: Border(
                      top: BorderSide(color: theme.dividerColor),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _iconForType(_contentType),
                        size: 14,
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        _contentType.label,
                        style: theme.textTheme.labelSmall,
                      ),
                      const Spacer(),
                      Text(
                        '${StringUtils.wordCount(_contentController.text)} words',
                        style: theme.textTheme.labelSmall,
                      ),
                      const SizedBox(width: AppSpacing.lg),
                      if (_isModified)
                        Text(
                          'Modified',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        )
                      else
                        Text(
                          AppLocalizations.autoSaved,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.success,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _iconForType(NoteContentType type) {
    return switch (type) {
      NoteContentType.plain => Icons.text_snippet_rounded,
      NoteContentType.markdown => Icons.code_rounded,
      NoteContentType.richText => Icons.text_format_rounded,
      NoteContentType.checklist => Icons.checklist_rounded,
    };
  }

  String _hintForType(NoteContentType type) {
    return switch (type) {
      NoteContentType.plain => 'Start typing...',
      NoteContentType.markdown => '# Start writing in Markdown...',
      NoteContentType.richText => 'Start writing...',
      NoteContentType.checklist => '- [ ] Add checklist items...',
    };
  }
}

/// Markdown formatting toolbar with common shortcuts.
class _MarkdownToolbar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onChanged;

  const _MarkdownToolbar({
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 44,
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
            _toolButton(Icons.format_bold, 'Bold', () => _wrap('**', '**')),
            _toolButton(Icons.format_italic, 'Italic', () => _wrap('*', '*')),
            _toolButton(Icons.strikethrough_s, 'Strikethrough',
                () => _wrap('~~', '~~')),
            _divider(),
            _toolButton(Icons.title, 'Heading', () => _prefix('# ')),
            _toolButton(
                Icons.format_list_bulleted, 'Bullet List', () => _prefix('- ')),
            _toolButton(Icons.format_list_numbered, 'Numbered List',
                () => _prefix('1. ')),
            _toolButton(
                Icons.check_box_outlined, 'Checkbox', () => _prefix('- [ ] ')),
            _divider(),
            _toolButton(Icons.code, 'Code', () => _wrap('`', '`')),
            _toolButton(Icons.data_object, 'Code Block',
                () => _wrap('\n```\n', '\n```\n')),
            _toolButton(Icons.link, 'Link', () => _wrap('[', '](url)')),
            _toolButton(
                Icons.image_outlined, 'Image', () => _wrap('![alt](', ')')),
            _toolButton(Icons.format_quote, 'Quote', () => _prefix('> ')),
            _toolButton(Icons.horizontal_rule, 'Horizontal Rule',
                () => _insert('\n---\n')),
          ],
        ),
      ),
    );
  }

  Widget _toolButton(IconData icon, String tooltip, VoidCallback onPressed) {
    return IconButton(
      icon: Icon(icon, size: 18),
      tooltip: tooltip,
      onPressed: onPressed,
      padding: const EdgeInsets.all(6),
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
    );
  }

  Widget _divider() {
    return const SizedBox(
      width: 1,
      height: 20,
      child: VerticalDivider(width: 1),
    );
  }

  void _wrap(String before, String after) {
    final text = controller.text;
    final sel = controller.selection;
    if (!sel.isValid) return;

    final selected = text.substring(sel.start, sel.end);
    final newText = '$before$selected$after';
    controller.text = text.replaceRange(sel.start, sel.end, newText);
    controller.selection = TextSelection.collapsed(
        offset: sel.start + before.length + selected.length);
    onChanged();
  }

  void _prefix(String prefix) {
    final text = controller.text;
    final sel = controller.selection;
    if (!sel.isValid) return;

    // Find the start of the current line
    int lineStart = sel.start;
    while (lineStart > 0 && text[lineStart - 1] != '\n') {
      lineStart--;
    }

    controller.text = text.replaceRange(lineStart, lineStart, prefix);
    controller.selection =
        TextSelection.collapsed(offset: sel.start + prefix.length);
    onChanged();
  }

  void _insert(String snippet) {
    final text = controller.text;
    final sel = controller.selection;
    if (!sel.isValid) return;

    controller.text = text.replaceRange(sel.start, sel.end, snippet);
    controller.selection =
        TextSelection.collapsed(offset: sel.start + snippet.length);
    onChanged();
  }
}
