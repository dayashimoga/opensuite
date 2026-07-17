import 'package:flutter/material.dart';

/// Bookmark data model for PDF navigation.
class PdfBookmarkItem {
  final String id;
  final String title;
  final int page;
  final List<PdfBookmarkItem> children;

  const PdfBookmarkItem({
    required this.id,
    required this.title,
    required this.page,
    this.children = const [],
  });
}

/// Sidebar panel for PDF bookmark navigation.
class BookmarkPanel extends StatelessWidget {
  final List<PdfBookmarkItem> bookmarks;
  final ValueChanged<int>? onNavigate;
  final ValueChanged<PdfBookmarkItem>? onAdd;
  final ValueChanged<String>? onRemove;
  final int currentPage;

  const BookmarkPanel({
    super.key,
    required this.bookmarks,
    this.onNavigate,
    this.onAdd,
    this.onRemove,
    this.currentPage = 0,
  });

  void _showAddDialog(BuildContext context) {
    final titleController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Bookmark'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Bookmark Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Text('Page: ${currentPage + 1}',
                style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (titleController.text.isNotEmpty) {
                onAdd?.call(PdfBookmarkItem(
                  id: DateTime.now().microsecondsSinceEpoch.toString(),
                  title: titleController.text,
                  page: currentPage,
                ));
              }
              Navigator.pop(ctx);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        border: Border(right: BorderSide(color: theme.dividerColor)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(Icons.bookmark, size: 20,
                    color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text('Bookmarks', style: theme.textTheme.titleSmall),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.add, size: 20),
                  tooltip: 'Add Bookmark',
                  onPressed: () => _showAddDialog(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: bookmarks.isEmpty
                ? Center(
                    child: Text(
                      'No bookmarks yet.\nTap + to add one.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(4),
                    itemCount: bookmarks.length,
                    itemBuilder: (ctx, idx) {
                      final bm = bookmarks[idx];
                      return _BookmarkTile(
                        bookmark: bm,
                        onNavigate: onNavigate,
                        onRemove: onRemove,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _BookmarkTile extends StatelessWidget {
  final PdfBookmarkItem bookmark;
  final ValueChanged<int>? onNavigate;
  final ValueChanged<String>? onRemove;
  final int indent;

  const _BookmarkTile({
    required this.bookmark,
    this.onNavigate,
    this.onRemove,
    this.indent = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          dense: true,
          contentPadding:
              EdgeInsets.only(left: 12.0 + indent * 16.0, right: 4),
          leading: const Icon(Icons.bookmark_outline, size: 18),
          title: Text(bookmark.title,
              style: const TextStyle(fontSize: 13)),
          subtitle: Text('Page ${bookmark.page + 1}',
              style: const TextStyle(fontSize: 11)),
          trailing: IconButton(
            icon: const Icon(Icons.close, size: 16),
            onPressed: () => onRemove?.call(bookmark.id),
          ),
          onTap: () => onNavigate?.call(bookmark.page),
        ),
        ...bookmark.children.map((child) => _BookmarkTile(
              bookmark: child,
              onNavigate: onNavigate,
              onRemove: onRemove,
              indent: indent + 1,
            )),
      ],
    );
  }
}
