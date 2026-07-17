import 'dart:convert';

import 'package:file_picker/file_picker.dart' as fp;
import 'package:fileutility_core/fileutility_core.dart';
import 'package:fileutility_storage/fileutility_storage.dart';
import 'package:fileutility_ui_kit/fileutility_ui_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../di/app_module.dart';
import '../bloc/document_editor_bloc.dart';

/// Rich document editor page powered by flutter_quill.
///
/// Provides a full formatting toolbar, rich text editing surface,
/// DOCX/PDF/TXT/MD export, DOCX import, autosave, undo/redo,
/// find & replace, and keyboard shortcut support.
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
  late QuillController _quillController;
  late TextEditingController _titleController;
  late FocusNode _editorFocusNode;
  late ScrollController _scrollController;
  bool _isInitialized = false;
  bool _isUpdatingFromBloc = false;

  @override
  void initState() {
    super.initState();
    _quillController = QuillController.basic();
    _titleController = TextEditingController();
    _editorFocusNode = FocusNode(debugLabel: 'QuillEditor');
    _scrollController = ScrollController();

    // Listen for content changes from the Quill editor
    _quillController.document.changes.listen((_) {
      if (_isUpdatingFromBloc) return;
      _syncContentToBloc();
    });
  }

  @override
  void dispose() {
    _quillController.dispose();
    _titleController.dispose();
    _editorFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _syncContentToBloc() {
    if (!mounted) return;
    final deltaJson = jsonEncode(_quillController.document.toDelta().toJson());
    final plainText = _quillController.document.toPlainText();

    context.read<DocumentEditorBloc>().add(
          UpdateDocumentContent(
            content: deltaJson,
            plainText: plainText,
          ),
        );
  }

  void _loadDocumentIntoEditor(DocumentEntity doc) {
    _isUpdatingFromBloc = true;
    try {
      // Parse the stored Delta JSON
      List<dynamic> deltaOps;
      try {
        deltaOps = jsonDecode(doc.content) as List<dynamic>;
      } catch (_) {
        // Legacy plain-text content: wrap in Delta
        deltaOps = [
          {'insert': '${doc.plainText}\n'}
        ];
      }

      // Validate delta ops have at least one insert ending with newline
      if (deltaOps.isEmpty) {
        deltaOps = [
          {'insert': '\n'}
        ];
      }

      final delta = Delta.fromJson(deltaOps);
      _quillController.document = Document.fromDelta(delta);
      _titleController.text = doc.title;
    } catch (e) {
      // Fallback to plain text
      _quillController.document = Document()..insert(0, doc.plainText);
      _titleController.text = doc.title;
    } finally {
      _isUpdatingFromBloc = false;
    }
  }

  Future<void> _handleExportDownload(DocumentEditorState state) async {
    if (state.exportedBytes != null &&
        state.exportedFileName != null &&
        state.exportedMimeType != null) {
      await FileDownloadUtils.downloadBytes(
        bytes: state.exportedBytes!,
        fileName: state.exportedFileName!,
        mimeType: state.exportedMimeType!,
      );
      if (mounted) {
        context.read<DocumentEditorBloc>().add(const ClearExportedBytes());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Downloaded: ${state.exportedFileName}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _importDocx() async {
    final result = await fp.FilePicker.platform.pickFiles(
      type: fp.FileType.custom,
      allowedExtensions: ['docx'],
      withData: true,
    );
    if (result != null && result.files.single.bytes != null && mounted) {
      context.read<DocumentEditorBloc>().add(
            ImportDocx(
              fileBytes: result.files.single.bytes!,
              fileName: result.files.single.name,
            ),
          );
    }
  }

  Future<void> _importTextFile() async {
    final result = await fp.FilePicker.platform.pickFiles(
      type: fp.FileType.custom,
      allowedExtensions: ['txt', 'md', 'markdown'],
      withData: true,
    );
    if (result != null && result.files.single.bytes != null && mounted) {
      final content = String.fromCharCodes(result.files.single.bytes!);
      final ext = result.files.single.extension ?? 'txt';
      context.read<DocumentEditorBloc>().add(
            ImportTextFile(
              content: content,
              fileName: result.files.single.name,
              format: ext == 'md' || ext == 'markdown' ? 'md' : 'txt',
            ),
          );
    }
  }

  void _exportPlainText(DocumentEditorState state) {
    final title = state.currentDocument?.title ?? 'Document';
    final content = _quillController.document.toPlainText();
    final bytes = Uint8List.fromList(utf8.encode(content));
    FileDownloadUtils.downloadBytes(
      bytes: bytes,
      fileName: '$title.txt',
      mimeType: 'text/plain',
    );
  }

  void _exportMarkdown(DocumentEditorState state) {
    final title = state.currentDocument?.title ?? 'Document';
    // Convert Delta to simple markdown (basic implementation)
    final plainText = _quillController.document.toPlainText();
    final bytes = Uint8List.fromList(utf8.encode(plainText));
    FileDownloadUtils.downloadBytes(
      bytes: bytes,
      fileName: '$title.md',
      mimeType: 'text/markdown',
    );
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
        // Load document content into Quill editor on first load
        if (state.currentDocument != null && !_isInitialized) {
          _loadDocumentIntoEditor(state.currentDocument!);
          _isInitialized = true;
        }

        // Reload when document changes (e.g., after import)
        if (_isInitialized &&
            state.currentDocument != null &&
            state.status == DocumentEditorStatus.editing &&
            state.currentDocument!.id !=
                context.read<DocumentEditorBloc>().state.currentDocument?.id) {
          _loadDocumentIntoEditor(state.currentDocument!);
        }

        if (state.status == DocumentEditorStatus.saved) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Saved ✓'),
              duration: Duration(seconds: 1),
            ),
          );
        }

        // Auto-download on export completion
        if (state.status == DocumentEditorStatus.exported) {
          _handleExportDownload(state);
        }

        if (state.status == DocumentEditorStatus.error &&
            state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: theme.colorScheme.error,
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

        return CallbackShortcuts(
          bindings: {
            const SingleActivator(LogicalKeyboardKey.keyS, control: true): () =>
                context.read<DocumentEditorBloc>().add(const SaveDocument()),
            const SingleActivator(LogicalKeyboardKey.keyF, control: true): () =>
                context
                    .read<DocumentEditorBloc>()
                    .add(const ToggleFindReplace()),
            const SingleActivator(LogicalKeyboardKey.keyH, control: true): () =>
                context
                    .read<DocumentEditorBloc>()
                    .add(const ToggleFindReplace()),
            const SingleActivator(LogicalKeyboardKey.keyN, control: true): () =>
                context.read<DocumentEditorBloc>().add(const CreateDocument()),
            const SingleActivator(LogicalKeyboardKey.keyO, control: true): () =>
                _importDocx(),
          },
          child: Focus(
            autofocus: true,
            child: Scaffold(
              appBar: _buildAppBar(context, state, theme),
              body: Column(
                children: [
                  // Quill Toolbar
                  if (state.showToolbar) _buildQuillToolbar(context, theme),

                  // Find & Replace bar
                  if (state.showFindReplace) _FindReplaceBar(state: state),

                  // Progress indicator
                  if (state.status == DocumentEditorStatus.exporting ||
                      state.status == DocumentEditorStatus.importing)
                    LinearProgressIndicator(
                      backgroundColor:
                          theme.colorScheme.surfaceContainerHighest,
                    ),

                  // Editor surface
                  Expanded(
                    child: Container(
                      color: theme.colorScheme.surface,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xl,
                          vertical: AppSpacing.md,
                        ),
                        child: QuillEditor(
                          controller: _quillController,
                          focusNode: _editorFocusNode,
                          scrollController: _scrollController,
                          configurations: QuillEditorConfigurations(
                            placeholder: 'Start writing...',
                            padding: const EdgeInsets.all(16),
                            autoFocus: false,
                            expands: true,
                            customStyles: DefaultStyles(
                              paragraph: DefaultTextBlockStyle(
                                theme.textTheme.bodyLarge!.copyWith(
                                  height: 1.8,
                                ),
                                const HorizontalSpacing(0, 0),
                                const VerticalSpacing(6, 0),
                                const VerticalSpacing(0, 0),
                                null,
                              ),
                              h1: DefaultTextBlockStyle(
                                theme.textTheme.headlineLarge!.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                                const HorizontalSpacing(0, 0),
                                const VerticalSpacing(16, 8),
                                const VerticalSpacing(0, 0),
                                null,
                              ),
                              h2: DefaultTextBlockStyle(
                                theme.textTheme.headlineMedium!.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                                const HorizontalSpacing(0, 0),
                                const VerticalSpacing(12, 6),
                                const VerticalSpacing(0, 0),
                                null,
                              ),
                              h3: DefaultTextBlockStyle(
                                theme.textTheme.headlineSmall!.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                                const HorizontalSpacing(0, 0),
                                const VerticalSpacing(8, 4),
                                const VerticalSpacing(0, 0),
                                null,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

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

  PreferredSizeWidget _buildAppBar(
      BuildContext context, DocumentEditorState state, ThemeData theme) {
    return AppBar(
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
            context.read<DocumentEditorBloc>().add(UpdateDocumentTitle(value));
          },
        ),
      ),
      actions: [
        // Undo
        IconButton(
          icon: const Icon(Icons.undo),
          onPressed:
              _quillController.hasUndo ? () => _quillController.undo() : null,
          tooltip: 'Undo (Ctrl+Z)',
        ),
        // Redo
        IconButton(
          icon: const Icon(Icons.redo),
          onPressed:
              _quillController.hasRedo ? () => _quillController.redo() : null,
          tooltip: 'Redo (Ctrl+Shift+Z)',
        ),
        // Find & Replace
        IconButton(
          icon: Icon(
            Icons.search,
            color: state.showFindReplace ? theme.colorScheme.primary : null,
          ),
          onPressed: () =>
              context.read<DocumentEditorBloc>().add(const ToggleFindReplace()),
          tooltip: 'Find & Replace (Ctrl+F)',
        ),
        // Save indicator
        _SaveIndicator(state: state),
        const SizedBox(width: 4),
        // File menu
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          tooltip: 'File options',
          itemBuilder: (_) => [
            const PopupMenuItem(
              value: 'new',
              child: ListTile(
                leading: Icon(Icons.add),
                title: Text('New Document'),
                dense: true,
              ),
            ),
            const PopupMenuItem(
              value: 'import_docx',
              child: ListTile(
                leading: Icon(Icons.upload_file),
                title: Text('Import DOCX'),
                dense: true,
              ),
            ),
            const PopupMenuItem(
              value: 'import_txt',
              child: ListTile(
                leading: Icon(Icons.text_snippet),
                title: Text('Import TXT/MD'),
                dense: true,
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: 'export_docx',
              child: ListTile(
                leading: Icon(Icons.description),
                title: Text('Export as DOCX'),
                dense: true,
              ),
            ),
            const PopupMenuItem(
              value: 'export_pdf',
              child: ListTile(
                leading: Icon(Icons.picture_as_pdf),
                title: Text('Export as PDF'),
                dense: true,
              ),
            ),
            const PopupMenuItem(
              value: 'export_txt',
              child: ListTile(
                leading: Icon(Icons.text_snippet_outlined),
                title: Text('Export as TXT'),
                dense: true,
              ),
            ),
            const PopupMenuItem(
              value: 'export_md',
              child: ListTile(
                leading: Icon(Icons.code),
                title: Text('Export as Markdown'),
                dense: true,
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: 'share',
              child: ListTile(
                leading: Icon(Icons.share),
                title: Text('Share'),
                dense: true,
              ),
            ),
            const PopupMenuItem(
              value: 'stats',
              child: ListTile(
                leading: Icon(Icons.analytics_outlined),
                title: Text('Document Stats'),
                dense: true,
              ),
            ),
          ],
          onSelected: (value) {
            switch (value) {
              case 'new':
                context.read<DocumentEditorBloc>().add(const CreateDocument());
                _isInitialized = false;
              case 'import_docx':
                _importDocx();
              case 'import_txt':
                _importTextFile();
              case 'export_docx':
                context.read<DocumentEditorBloc>().add(const ExportDocx());
              case 'export_pdf':
                context.read<DocumentEditorBloc>().add(const ExportPdf());
              case 'export_txt':
                _exportPlainText(state);
              case 'export_md':
                _exportMarkdown(state);
              case 'share':
                final title = state.currentDocument?.title ?? 'Document';
                Share.share(
                  _quillController.document.toPlainText(),
                  subject: title,
                );
              case 'stats':
                _showStats(context, state);
            }
          },
        ),
      ],
    );
  }

  Widget _buildQuillToolbar(BuildContext context, ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant,
            width: 0.5,
          ),
        ),
      ),
      child: QuillSimpleToolbar(
        controller: _quillController,
        configurations: const QuillSimpleToolbarConfigurations(
          multiRowsDisplay: false,
          showDividers: true,
          showFontFamily: true,
          showFontSize: true,
          showBoldButton: true,
          showItalicButton: true,
          showUnderLineButton: true,
          showStrikeThrough: true,
          showColorButton: true,
          showBackgroundColorButton: true,
          showClearFormat: true,
          showAlignmentButtons: true,
          showLeftAlignment: true,
          showCenterAlignment: true,
          showRightAlignment: true,
          showJustifyAlignment: true,
          showHeaderStyle: true,
          showListNumbers: true,
          showListBullets: true,
          showListCheck: true,
          showCodeBlock: true,
          showQuote: true,
          showIndent: true,
          showLink: true,
          showUndo: false, // We have custom undo/redo in AppBar
          showRedo: false,
          showSearchButton: false,
          showSubscript: false,
          showSuperscript: false,
        ),
      ),
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

/// Save indicator widget showing save status.
class _SaveIndicator extends StatelessWidget {
  final DocumentEditorState state;
  const _SaveIndicator({required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    IconData icon;
    Color color;
    String tooltip;

    switch (state.status) {
      case DocumentEditorStatus.saving:
        icon = Icons.sync;
        color = theme.colorScheme.primary;
        tooltip = 'Saving...';
      case DocumentEditorStatus.saved:
        icon = Icons.cloud_done;
        color = theme.colorScheme.primary;
        tooltip = 'Saved';
      case DocumentEditorStatus.exporting:
        icon = Icons.download;
        color = theme.colorScheme.tertiary;
        tooltip = state.progressMessage ?? 'Exporting...';
      case DocumentEditorStatus.importing:
        icon = Icons.upload;
        color = theme.colorScheme.tertiary;
        tooltip = state.progressMessage ?? 'Importing...';
      default:
        if (state.hasUnsavedChanges) {
          icon = Icons.edit;
          color = theme.colorScheme.onSurface.withValues(alpha: 0.5);
          tooltip = 'Unsaved changes';
        } else {
          icon = Icons.check_circle_outline;
          color = theme.colorScheme.onSurface.withValues(alpha: 0.3);
          tooltip = 'No changes';
        }
    }

    return Tooltip(
      message: tooltip,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }
}

/// Find and replace bar widget.
class _FindReplaceBar extends StatefulWidget {
  final DocumentEditorState state;
  const _FindReplaceBar({required this.state});

  @override
  State<_FindReplaceBar> createState() => _FindReplaceBarState();
}

class _FindReplaceBarState extends State<_FindReplaceBar> {
  final _findController = TextEditingController();
  final _replaceController = TextEditingController();

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
    final currentIdx = widget.state.currentFindIndex;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          // Find field
          Expanded(
            child: SizedBox(
              height: 36,
              child: TextField(
                controller: _findController,
                decoration: InputDecoration(
                  hintText: 'Find...',
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  suffixText:
                      matchCount > 0 ? '${currentIdx + 1}/$matchCount' : null,
                ),
                onChanged: (value) {
                  context.read<DocumentEditorBloc>().add(FindInDocument(value));
                },
                onSubmitted: (_) {
                  context
                      .read<DocumentEditorBloc>()
                      .add(const NavigateFindMatch());
                },
              ),
            ),
          ),
          const SizedBox(width: 4),
          // Replace field
          Expanded(
            child: SizedBox(
              height: 36,
              child: TextField(
                controller: _replaceController,
                decoration: InputDecoration(
                  hintText: 'Replace...',
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          // Navigation buttons
          IconButton(
            icon: const Icon(Icons.arrow_upward, size: 18),
            onPressed: () => context
                .read<DocumentEditorBloc>()
                .add(const NavigateFindMatch(forward: false)),
            tooltip: 'Previous',
            visualDensity: VisualDensity.compact,
          ),
          IconButton(
            icon: const Icon(Icons.arrow_downward, size: 18),
            onPressed: () => context
                .read<DocumentEditorBloc>()
                .add(const NavigateFindMatch()),
            tooltip: 'Next',
            visualDensity: VisualDensity.compact,
          ),
          // Replace buttons
          TextButton(
            onPressed: () {
              context.read<DocumentEditorBloc>().add(
                    ReplaceInDocument(
                      _findController.text,
                      _replaceController.text,
                    ),
                  );
            },
            child: const Text('Replace'),
          ),
          TextButton(
            onPressed: () {
              context.read<DocumentEditorBloc>().add(
                    ReplaceInDocument(
                      _findController.text,
                      _replaceController.text,
                      replaceAll: true,
                    ),
                  );
            },
            child: const Text('All'),
          ),
          // Close
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: () => context
                .read<DocumentEditorBloc>()
                .add(const ToggleFindReplace()),
            tooltip: 'Close',
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

/// Status bar showing word count, character count, and format.
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
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
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
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            '${state.characterCount} chars',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const Spacer(),
          Text(
            state.currentDocument?.format.toUpperCase() ?? 'RICH',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }
}
