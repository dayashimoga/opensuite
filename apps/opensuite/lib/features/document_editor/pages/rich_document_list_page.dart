import 'package:fileutility_core/fileutility_core.dart';
import 'package:fileutility_storage/fileutility_storage.dart';
import 'package:fileutility_ui_kit/fileutility_ui_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../di/app_module.dart';
import '../bloc/document_editor_bloc.dart';

/// Page showing a list of all rich text documents.
///
/// Provides search, create, favorite, duplicate, and delete operations.
class RichDocumentListPage extends StatelessWidget {
  /// Creates the [RichDocumentListPage].
  const RichDocumentListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<DocumentEditorBloc>(
      create: (_) => AppModule.documentEditorBloc..add(const LoadDocuments()),
      child: const _DocumentListContent(),
    );
  }
}

class _DocumentListContent extends StatelessWidget {
  const _DocumentListContent();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Documents'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearch(context),
            tooltip: 'Search documents',
          ),
        ],
      ),
      body: BlocBuilder<DocumentEditorBloc, DocumentEditorState>(
        builder: (context, state) {
          if (state.status == DocumentEditorStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.documents.isEmpty) {
            return EmptyState(
              icon: Icons.description_outlined,
              title: 'No Documents',
              description: 'Create a new document to get started',
              actionLabel: 'New Document',
              onAction: () => _createDocument(context),
            );
          }

          final favorites = state.documents.where((d) => d.isFavorite).toList();
          final others = state.documents.where((d) => !d.isFavorite).toList();

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              // Search query indicator
              if (state.searchQuery.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: Chip(
                    label: Text('Search: ${state.searchQuery}'),
                    onDeleted: () => context
                        .read<DocumentEditorBloc>()
                        .add(const SearchDocuments('')),
                  ),
                ),

              // Favorites section
              if (favorites.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Text(
                    'Favorites',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                ...favorites.map((doc) => _DocumentCard(
                      document: doc,
                      onTap: () => _openDocument(context, doc.id),
                      onFavorite: () => context
                          .read<DocumentEditorBloc>()
                          .add(ToggleDocumentFavorite(doc.id)),
                      onDuplicate: () => context
                          .read<DocumentEditorBloc>()
                          .add(DuplicateDocument(doc.id)),
                      onDelete: () => _confirmDelete(context, doc),
                    )),
                const SizedBox(height: AppSpacing.md),
              ],

              // All documents section
              if (others.isNotEmpty) ...[
                if (favorites.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Text(
                      'All Documents',
                      style: theme.textTheme.titleSmall,
                    ),
                  ),
                ...others.map((doc) => _DocumentCard(
                      document: doc,
                      onTap: () => _openDocument(context, doc.id),
                      onFavorite: () => context
                          .read<DocumentEditorBloc>()
                          .add(ToggleDocumentFavorite(doc.id)),
                      onDuplicate: () => context
                          .read<DocumentEditorBloc>()
                          .add(DuplicateDocument(doc.id)),
                      onDelete: () => _confirmDelete(context, doc),
                    )),
              ],
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createDocument(context),
        icon: const Icon(Icons.add),
        label: const Text('New Document'),
      ),
    );
  }

  void _showSearch(BuildContext context) {
    showSearch(
      context: context,
      delegate: _DocumentSearchDelegate(
        onSearch: (query) {
          context.read<DocumentEditorBloc>().add(SearchDocuments(query));
        },
      ),
    );
  }

  void _createDocument(BuildContext context) {
    context.read<DocumentEditorBloc>().add(const CreateDocument());
  }

  void _openDocument(BuildContext context, String id) {
    context.go('/documents/$id');
  }

  void _confirmDelete(BuildContext context, DocumentEntity doc) {
    ConfirmationDialog.show(
      context,
      title: 'Delete Document',
      message:
          'Are you sure you want to delete "${doc.title}"? This cannot be undone.',
      confirmLabel: 'Delete',
      isDestructive: true,
    ).then((confirmed) {
      if (confirmed && context.mounted) {
        context.read<DocumentEditorBloc>().add(DeleteDocument(doc.id));
      }
    });
  }
}

/// Card widget displaying a document's summary.
class _DocumentCard extends StatelessWidget {
  final DocumentEntity document;
  final VoidCallback onTap;
  final VoidCallback onFavorite;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;

  const _DocumentCard({
    required this.document,
    required this.onTap,
    required this.onFavorite,
    required this.onDuplicate,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              // Document icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getFormatIcon(document.format),
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: AppSpacing.md),

              // Title and metadata
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      document.title.isEmpty ? 'Untitled' : document.title,
                      style: theme.textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${document.format.toUpperCase()} • ${document.wordCount} words • ${AppDateUtils.formatRelative(document.modifiedAt)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (document.plainText.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          document.plainText,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.7),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),

              // Actions
              PopupMenuButton<String>(
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'favorite',
                    child: Row(
                      children: [
                        Icon(document.isFavorite
                            ? Icons.star
                            : Icons.star_outline),
                        const SizedBox(width: 8),
                        Text(document.isFavorite
                            ? 'Remove Favorite'
                            : 'Add Favorite'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'duplicate',
                    child: Row(
                      children: [
                        Icon(Icons.copy),
                        SizedBox(width: 8),
                        Text('Duplicate'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) {
                  switch (value) {
                    case 'favorite':
                      onFavorite();
                    case 'duplicate':
                      onDuplicate();
                    case 'delete':
                      onDelete();
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getFormatIcon(String format) {
    switch (format) {
      case 'docx':
        return Icons.description;
      case 'rtf':
        return Icons.text_fields;
      case 'odt':
        return Icons.article;
      default:
        return Icons.edit_document;
    }
  }
}

class _DocumentSearchDelegate extends SearchDelegate<String> {
  final void Function(String) onSearch;

  _DocumentSearchDelegate({required this.onSearch});

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
          onSearch('');
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, ''),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    onSearch(query);
    close(context, query);
    return const SizedBox.shrink();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return const Center(child: Text('Type to search documents'));
  }
}
