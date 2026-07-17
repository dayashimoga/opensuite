import 'package:flutter/material.dart';

/// Dialog for merging multiple PDF files or splitting a PDF.
class MergeSplitDialog extends StatefulWidget {
  final int totalPages;
  final String currentFileName;
  final ValueChanged<MergeSplitAction>? onAction;

  const MergeSplitDialog({
    super.key,
    required this.totalPages,
    required this.currentFileName,
    this.onAction,
  });

  @override
  State<MergeSplitDialog> createState() => _MergeSplitDialogState();
}

enum MergeSplitMode { merge, split, extract, delete }

class MergeSplitAction {
  final MergeSplitMode mode;
  final List<int>? pages; // For split/extract/delete
  final List<String>? filePaths; // For merge

  const MergeSplitAction({
    required this.mode,
    this.pages,
    this.filePaths,
  });
}

class _MergeSplitDialogState extends State<MergeSplitDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _rangeController = TextEditingController();
  final Set<int> _selectedPages = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _rangeController.dispose();
    super.dispose();
  }

  List<int> _parsePageRange(String input) {
    final pages = <int>{};
    for (final part in input.split(',')) {
      final trimmed = part.trim();
      if (trimmed.contains('-')) {
        final bounds = trimmed.split('-');
        if (bounds.length == 2) {
          final start = int.tryParse(bounds[0].trim());
          final end = int.tryParse(bounds[1].trim());
          if (start != null && end != null) {
            for (int i = start; i <= end && i <= widget.totalPages; i++) {
              if (i >= 1) pages.add(i);
            }
          }
        }
      } else {
        final page = int.tryParse(trimmed);
        if (page != null && page >= 1 && page <= widget.totalPages) {
          pages.add(page);
        }
      }
    }
    return pages.toList()..sort();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('PDF Page Operations'),
      content: SizedBox(
        width: 420,
        height: 360,
        child: Column(
          children: [
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Split'),
                Tab(text: 'Extract'),
                Tab(text: 'Delete'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Split tab
                  _buildPageRangeTab(
                    'Split pages into a separate PDF.',
                    MergeSplitMode.split,
                  ),
                  // Extract tab
                  _buildPageRangeTab(
                    'Extract selected pages to a new PDF.',
                    MergeSplitMode.extract,
                  ),
                  // Delete tab
                  _buildPageRangeTab(
                    'Remove selected pages from the PDF.',
                    MergeSplitMode.delete,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final mode =
                MergeSplitMode.values[_tabController.index + 1]; // skip merge
            final pages = _parsePageRange(_rangeController.text);
            if (pages.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('No valid pages selected')),
              );
              return;
            }
            widget.onAction?.call(MergeSplitAction(
              mode: mode,
              pages: pages,
            ));
            Navigator.pop(context);
          },
          child: const Text('Apply'),
        ),
      ],
    );
  }

  Widget _buildPageRangeTab(String description, MergeSplitMode mode) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(description, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 8),
          Text('Total pages: ${widget.totalPages}',
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 12),
          TextField(
            controller: _rangeController,
            decoration: const InputDecoration(
              labelText: 'Page Range',
              hintText: 'e.g. 1-3, 5, 7-9',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 4,
                runSpacing: 4,
                children: List.generate(widget.totalPages, (idx) {
                  final page = idx + 1;
                  final selected = _selectedPages.contains(page);
                  return FilterChip(
                    label: Text('$page', style: const TextStyle(fontSize: 11)),
                    selected: selected,
                    onSelected: (v) {
                      setState(() {
                        if (v) {
                          _selectedPages.add(page);
                        } else {
                          _selectedPages.remove(page);
                        }
                        _rangeController.text = _selectedPages
                            .toList()
                            .sorted((a, b) => a.compareTo(b))
                            .join(', ');
                      });
                    },
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

extension _SortedList<T> on List<T> {
  List<T> sorted(int Function(T, T) compare) => List.from(this)..sort(compare);
}
