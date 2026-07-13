import 'package:file_picker/file_picker.dart' as fp;
import 'package:fileutility_core/fileutility_core.dart';
import 'package:fileutility_ui_kit/fileutility_ui_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../di/app_module.dart';
import '../bloc/spreadsheet_bloc.dart';

/// Page listing all spreadsheet workbooks.
class SpreadsheetListPage extends StatelessWidget {
  const SpreadsheetListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SpreadsheetBloc>(
      create: (_) => AppModule.spreadsheetBloc..add(const LoadSpreadsheets()),
      child: const _ListContent(),
    );
  }
}

class _ListContent extends StatefulWidget {
  const _ListContent();

  @override
  State<_ListContent> createState() => _ListContentState();
}

class _ListContentState extends State<_ListContent> {
  bool _isCreating = false;
  String _sortBy = 'modified'; // 'modified', 'name', 'created'
  bool _sortAsc = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocListener<SpreadsheetBloc, SpreadsheetState>(
      listenWhen: (prev, curr) => prev.status != curr.status,
      listener: (context, state) {
        if (state.status == SpreadsheetStatus.editing &&
            state.currentSpreadsheet != null &&
            _isCreating) {
          _isCreating = false;
          context.go('/spreadsheets/${state.currentSpreadsheet!.id}');
        }
        if (state.status == SpreadsheetStatus.saved) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Saved ✓'),
              duration: Duration(seconds: 1),
            ),
          );
        }
        if (state.status == SpreadsheetStatus.error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage ?? 'An error occurred'),
              backgroundColor: theme.colorScheme.error,
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Spreadsheets'),
          actions: [
            // Sort options
            PopupMenuButton<String>(
              icon: const Icon(Icons.sort),
              tooltip: 'Sort by',
              onSelected: (value) {
                setState(() {
                  if (_sortBy == value) {
                    _sortAsc = !_sortAsc;
                  } else {
                    _sortBy = value;
                    _sortAsc = value == 'name';
                  }
                });
              },
              itemBuilder: (_) => [
                _sortMenuItem('modified', 'Date Modified', Icons.schedule),
                _sortMenuItem('name', 'Name', Icons.sort_by_alpha),
                _sortMenuItem('created', 'Date Created', Icons.calendar_today),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.folder_open),
              tooltip: 'Open File',
              onPressed: () => _openFile(context),
            ),
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () => _showSearch(context),
            ),
          ],
        ),
        body: BlocBuilder<SpreadsheetBloc, SpreadsheetState>(
          builder: (context, state) {
            if (state.status == SpreadsheetStatus.loading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state.spreadsheets.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    EmptyState(
                      icon: Icons.grid_on_outlined,
                      title: 'No Spreadsheets',
                      description:
                          'Create a new spreadsheet or start from a template',
                      actionLabel: 'New Spreadsheet',
                      onAction: () => _create(context),
                    ),
                    const SizedBox(height: 16),
                    _TemplateSection(
                      onCreateFromTemplate: (title) =>
                          _createWithTitle(context, title),
                    ),
                  ],
                ),
              );
            }

            // Sort the spreadsheets
            final sorted = List.of(state.spreadsheets)..sort(_comparator);

            return Column(
              children: [
                // Sort indicator
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg, vertical: 4),
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Sorted by $_sortLabel ${_sortAsc ? '↑' : '↓'}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md),
                    itemCount: sorted.length,
                    itemBuilder: (context, index) {
                      final sheet = sorted[index];
                      return Card(
                        margin:
                            const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: ListTile(
                          leading: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.tertiaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Icon(
                                  Icons.grid_on,
                                  color: theme
                                      .colorScheme.onTertiaryContainer,
                                ),
                                if (sheet.isFavorite)
                                  Positioned(
                                    top: 2,
                                    right: 2,
                                    child: Icon(
                                      Icons.star,
                                      size: 12,
                                      color: theme.colorScheme.secondary,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          title: Text(sheet.title),
                          subtitle: Text(
                            '${sheet.sheetCount} sheet${sheet.sheetCount > 1 ? "s" : ""} • ${AppDateUtils.formatRelative(sheet.modifiedAt)}',
                            style: theme.textTheme.bodySmall,
                          ),
                          trailing: PopupMenuButton<String>(
                            itemBuilder: (_) => [
                              PopupMenuItem(
                                value: 'favorite',
                                child: Row(children: [
                                  Icon(sheet.isFavorite
                                      ? Icons.star
                                      : Icons.star_outline),
                                  const SizedBox(width: 8),
                                  Text(sheet.isFavorite
                                      ? 'Unfavorite'
                                      : 'Favorite'),
                                ]),
                              ),
                              const PopupMenuItem(
                                value: 'duplicate',
                                child: Row(children: [
                                  Icon(Icons.copy),
                                  SizedBox(width: 8),
                                  Text('Duplicate'),
                                ]),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(children: [
                                  Icon(Icons.delete_outline,
                                      color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Delete',
                                      style:
                                          TextStyle(color: Colors.red)),
                                ]),
                              ),
                            ],
                            onSelected: (value) {
                              switch (value) {
                                case 'favorite':
                                  context
                                      .read<SpreadsheetBloc>()
                                      .add(ToggleSpreadsheetFavorite(
                                          sheet.id));
                                case 'duplicate':
                                  context
                                      .read<SpreadsheetBloc>()
                                      .add(DuplicateSpreadsheetEntry(
                                          sheet.id));
                                case 'delete':
                                  ConfirmationDialog.show(
                                    context,
                                    title: 'Delete Spreadsheet',
                                    message:
                                        'Delete "${sheet.title}"?',
                                  ).then((confirmed) {
                                    if (confirmed && context.mounted) {
                                      context
                                          .read<SpreadsheetBloc>()
                                          .add(
                                              DeleteSpreadsheetEntry(
                                                  sheet.id));
                                    }
                                  });
                              }
                            },
                          ),
                          onTap: () {
                            context.go('/spreadsheets/${sheet.id}');
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _isCreating
              ? null
              : () => _showCreateOptions(context),
          icon: _isCreating
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child:
                      CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.add),
          label: Text(_isCreating ? 'Creating...' : 'New Spreadsheet'),
        ),
      ),
    );
  }

  String get _sortLabel {
    switch (_sortBy) {
      case 'name':
        return 'Name';
      case 'created':
        return 'Date Created';
      default:
        return 'Date Modified';
    }
  }

  int Function(dynamic, dynamic) get _comparator {
    return (a, b) {
      int cmp;
      switch (_sortBy) {
        case 'name':
          cmp = a.title.toLowerCase().compareTo(b.title.toLowerCase());
        case 'created':
          cmp = a.createdAt.compareTo(b.createdAt);
        default:
          cmp = a.modifiedAt.compareTo(b.modifiedAt);
      }
      return _sortAsc ? cmp : -cmp;
    };
  }

  PopupMenuItem<String> _sortMenuItem(
      String value, String label, IconData icon) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(children: [
        Icon(icon, size: 18),
        const SizedBox(width: 8),
        Text(label),
        if (_sortBy == value) ...[
          const Spacer(),
          Icon(_sortAsc ? Icons.arrow_upward : Icons.arrow_downward,
              size: 14),
        ],
      ]),
    );
  }

  void _showCreateOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('New Spreadsheet',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            ListTile(
              leading:
                  const Icon(Icons.grid_on, color: Color(0xFF22C55E)),
              title: const Text('Blank Spreadsheet'),
              subtitle: const Text('Start with an empty grid'),
              onTap: () {
                Navigator.pop(context);
                _create(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.attach_money,
                  color: Color(0xFF3B82F6)),
              title: const Text('Budget'),
              subtitle: const Text('Monthly budget tracker'),
              onTap: () {
                Navigator.pop(context);
                _createWithTitle(context, 'Monthly Budget');
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_month,
                  color: Color(0xFFF59E0B)),
              title: const Text('Calendar'),
              subtitle: const Text('Annual calendar planner'),
              onTap: () {
                Navigator.pop(context);
                _createWithTitle(context, 'Calendar Planner');
              },
            ),
            ListTile(
              leading: const Icon(Icons.school,
                  color: Color(0xFF8B5CF6)),
              title: const Text('Gradebook'),
              subtitle: const Text('Student grade tracker'),
              onTap: () {
                Navigator.pop(context);
                _createWithTitle(context, 'Gradebook');
              },
            ),
            ListTile(
              leading: const Icon(Icons.inventory_2,
                  color: Color(0xFFEF4444)),
              title: const Text('Inventory'),
              subtitle: const Text('Product inventory tracker'),
              onTap: () {
                Navigator.pop(context);
                _createWithTitle(context, 'Inventory Tracker');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _create(BuildContext context) {
    setState(() => _isCreating = true);
    context.read<SpreadsheetBloc>().add(const CreateSpreadsheet());
  }

  void _createWithTitle(BuildContext context, String title) {
    setState(() => _isCreating = true);
    context.read<SpreadsheetBloc>().add(CreateSpreadsheet(title: title));
  }

  void _showSearch(BuildContext context) {
    showSearch(
      context: context,
      delegate: _SpreadsheetSearchDelegate(
        onSearch: (q) =>
            context.read<SpreadsheetBloc>().add(SearchSpreadsheets(q)),
      ),
    );
  }

  Future<void> _openFile(BuildContext context) async {
    final result = await fp.FilePicker.platform.pickFiles(
      type: fp.FileType.custom,
      allowedExtensions: ['xlsx', 'xls', 'csv', 'ods'],
      allowMultiple: false,
    );
    if (result != null && result.files.isNotEmpty && context.mounted) {
      final file = result.files.single;
      final title = file.name.replaceAll(RegExp(r'\.(xlsx|xls|csv|ods)$'), '');
      setState(() => _isCreating = true);
      context.read<SpreadsheetBloc>().add(CreateSpreadsheet(title: title));
    }
  }
}

class _SpreadsheetSearchDelegate extends SearchDelegate<String> {
  final void Function(String) onSearch;
  _SpreadsheetSearchDelegate({required this.onSearch});

  @override
  List<Widget> buildActions(BuildContext context) => [
        IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              query = '';
              onSearch('');
            }),
      ];

  @override
  Widget buildLeading(BuildContext context) => IconButton(
      icon: const Icon(Icons.arrow_back), onPressed: () => close(context, ''));

  @override
  Widget buildResults(BuildContext context) {
    onSearch(query);
    close(context, query);
    return const SizedBox.shrink();
  }

  @override
  Widget buildSuggestions(BuildContext context) =>
      const Center(child: Text('Type to search spreadsheets'));
}

/// Template chips shown on the empty state for quick creation.
class _TemplateSection extends StatelessWidget {
  final ValueChanged<String> onCreateFromTemplate;

  const _TemplateSection({required this.onCreateFromTemplate});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Or start from a template',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _templateChip(
                  context, 'Budget', Icons.attach_money, const Color(0xFF3B82F6)),
              _templateChip(
                  context, 'Calendar', Icons.calendar_month, const Color(0xFFF59E0B)),
              _templateChip(
                  context, 'Gradebook', Icons.school, const Color(0xFF8B5CF6)),
              _templateChip(
                  context, 'Inventory', Icons.inventory_2, const Color(0xFFEF4444)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _templateChip(
      BuildContext context, String label, IconData icon, Color color) {
    return ActionChip(
      avatar: Icon(icon, size: 16, color: color),
      label: Text(label),
      onPressed: () => onCreateFromTemplate(label),
    );
  }
}
