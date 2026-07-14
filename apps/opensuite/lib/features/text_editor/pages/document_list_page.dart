import 'package:fileutility_core/fileutility_core.dart';
import 'package:fileutility_l10n/fileutility_l10n.dart';
import 'package:fileutility_ui_kit/fileutility_ui_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../di/app_module.dart';
import '../../../router/app_router.dart';
import '../bloc/text_editor_bloc.dart';

/// Document list page showing all saved text documents.
class DocumentListPage extends StatelessWidget {
  const DocumentListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AppModule.textEditorBloc..add(const LoadDocumentList()),
      child: const _DocumentListContent(),
    );
  }
}

class _DocumentListContent extends StatelessWidget {
  const _DocumentListContent();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppLocalizations.textEditor),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: AppLocalizations.newDocument,
            onPressed: () => context.go(AppRouter.newDocument),
          ),
        ],
      ),
      body: BlocBuilder<TextEditorBloc, TextEditorState>(
        builder: (context, state) {
          if (state.status == TextEditorStatus.loading) {
            return const AppLoadingIndicator(message: 'Loading documents...');
          }

          if (state.documents.isEmpty) {
            return EmptyState(
              icon: Icons.edit_document,
              title: AppLocalizations.noDocuments,
              description: AppLocalizations.noDocumentsDescription,
              actionLabel: AppLocalizations.newDocument,
              onAction: () => context.go(AppRouter.newDocument),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            itemCount: state.documents.length,
            itemBuilder: (context, index) {
              final doc = state.documents[index];
              return _DocumentTile(document: doc);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go(AppRouter.newDocument),
        tooltip: AppLocalizations.newDocument,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}

class _DocumentTile extends StatelessWidget {
  const _DocumentTile({required this.document});

  final Map<String, dynamic> document;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = (document['title'] as String?) ?? 'Untitled';
    final fileType = (document['fileType'] as String?) ?? 'text';
    final id = document['id'] as String? ?? '';
    final content = (document['content'] as String?) ?? '';
    final updatedAt = document['updatedAt'] is DateTime
        ? document['updatedAt'] as DateTime
        : DateTime.now();
    final isMarkdown = fileType == 'markdown';

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        onTap: () => context.go('${AppRouter.editor}/$id'),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color:
                (isMarkdown ? const Color(0xFF14B8A6) : const Color(0xFF3B82F6))
                    .withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: Icon(
            isMarkdown ? Icons.code_rounded : Icons.text_snippet_rounded,
            color:
                isMarkdown ? const Color(0xFF14B8A6) : const Color(0xFF3B82F6),
            size: 22,
          ),
        ),
        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${isMarkdown ? 'Markdown' : 'Text'}'
          ' • ${AppDateUtils.formatRelative(updatedAt)}'
          ' • ${StringUtils.wordCount(content)} words',
          style: theme.textTheme.bodySmall,
        ),
        trailing: PopupMenuButton<String>(
          iconSize: 18,
          itemBuilder: (_) => const [
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_outline_rounded, size: 18),
                  SizedBox(width: AppSpacing.sm),
                  Text('Delete'),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            if (value == 'delete') {
              context.read<TextEditorBloc>().add(DeleteDocument(id));
            }
          },
        ),
      ),
    );
  }
}
