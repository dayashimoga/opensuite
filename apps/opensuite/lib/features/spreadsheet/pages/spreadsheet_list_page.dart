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

class _ListContent extends StatelessWidget {
  const _ListContent();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Spreadsheets'),
        actions: [
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
            return EmptyState(
              icon: Icons.grid_on_outlined,
              title: 'No Spreadsheets',
              description: 'Create a new spreadsheet to get started',
              actionLabel: 'New Spreadsheet',
              onAction: () => _create(context),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: state.spreadsheets.length,
            itemBuilder: (context, index) {
              final sheet = state.spreadsheets[index];
              return Card(
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: ListTile(
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.tertiaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.grid_on,
                      color: theme.colorScheme.onTertiaryContainer,
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
                          Text(sheet.isFavorite ? 'Unfavorite' : 'Favorite'),
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
                          Icon(Icons.delete_outline, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ]),
                      ),
                    ],
                    onSelected: (value) {
                      switch (value) {
                        case 'favorite':
                          context
                              .read<SpreadsheetBloc>()
                              .add(ToggleSpreadsheetFavorite(sheet.id));
                        case 'duplicate':
                          context
                              .read<SpreadsheetBloc>()
                              .add(DuplicateSpreadsheetEntry(sheet.id));
                        case 'delete':
                          ConfirmationDialog.show(
                            context,
                            title: 'Delete Spreadsheet',
                            message: 'Delete "${sheet.title}"?',
                          ).then((confirmed) {
                            if (confirmed && context.mounted) {
                              context
                                  .read<SpreadsheetBloc>()
                                  .add(DeleteSpreadsheetEntry(sheet.id));
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
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _create(context),
        icon: const Icon(Icons.add),
        label: const Text('New Spreadsheet'),
      ),
    );
  }

  void _create(BuildContext context) {
    context.read<SpreadsheetBloc>().add(const CreateSpreadsheet());
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
