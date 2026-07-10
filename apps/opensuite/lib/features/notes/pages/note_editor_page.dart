import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:fileutility_core/fileutility_core.dart';
import 'package:fileutility_ui_kit/fileutility_ui_kit.dart';
import 'package:fileutility_l10n/fileutility_l10n.dart';
import 'package:fileutility_storage/fileutility_storage.dart';

import '../../../di/app_module.dart';
import '../bloc/notes_bloc.dart';

/// Note editor page for creating and editing notes.
///
/// Supports plain text, markdown, and checklist content types
/// with autosave functionality.
class NoteEditorPage extends StatefulWidget {
  const NoteEditorPage({this.noteId, super.key});

  /// The ID of the note to edit. Null for a new note.
  final String? noteId;

  @override
  State<NoteEditorPage> createState() => _NoteEditorPageState();
}

class _NoteEditorPageState extends State<NoteEditorPage> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  late NotesBloc _bloc;
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
    _bloc = AppModule.notesBloc;
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

    // Start autosave timer
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
    _bloc.close();
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

    if (_note != null) {
      _bloc.add(UpdateNote(_note!.copyWith(
        title: title.isEmpty ? 'Untitled' : title,
        content: content,
        contentType: _contentType,
      )));
    } else {
      _bloc.add(CreateNote(
        title: title.isEmpty ? 'Untitled' : title,
        content: content,
        contentType: _contentType,
      ));
    }

    setState(() => _isModified = false);
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

    return Scaffold(
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
          // Content type selector
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

          // Save button
          IconButton(
            icon: Icon(
              _isModified
                  ? Icons.save_rounded
                  : Icons.check_circle_outline_rounded,
            ),
            tooltip: AppLocalizations.save,
            onPressed: _save,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            // Title field
            TextField(
              controller: _titleController,
              onChanged: (_) => _onContentChanged(),
              style: theme.textTheme.headlineSmall,
              decoration: InputDecoration(
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

            // Content field
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

            // Status bar
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
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
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
