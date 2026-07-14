import 'package:fileutility_core/fileutility_core.dart';
import 'package:fileutility_l10n/fileutility_l10n.dart';
import 'package:fileutility_storage/fileutility_storage.dart';
import 'package:fileutility_ui_kit/fileutility_ui_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../di/app_module.dart';
import '../bloc/file_manager_bloc.dart';

/// File Manager page for browsing recent and favorite files.
class FileManagerPage extends StatelessWidget {
  const FileManagerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AppModule.fileManagerBloc..add(const LoadRecentFiles()),
      child: const _FileManagerContent(),
    );
  }
}

class _FileManagerContent extends StatefulWidget {
  const _FileManagerContent();

  @override
  State<_FileManagerContent> createState() => _FileManagerContentState();
}

class _FileManagerContentState extends State<_FileManagerContent> {
  String _sortBy = 'date'; // 'date', 'name', 'size', 'type'
  bool _sortAsc = false;
  String? _filterType; // null = all, or 'document', 'spreadsheet', etc.

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppLocalizations.fileManager),
        centerTitle: false,
        actions: [
          // Sort
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
              _sortItem('date', 'Date Opened', Icons.schedule),
              _sortItem('name', 'Name', Icons.sort_by_alpha),
              _sortItem('size', 'Size', Icons.storage),
              _sortItem('type', 'Type', Icons.category),
            ],
          ),
          // View mode toggle
          BlocBuilder<FileManagerBloc, FileManagerState>(
            buildWhen: (prev, curr) => prev.viewMode != curr.viewMode,
            builder: (context, state) {
              return IconButton(
                icon: Icon(
                  state.viewMode == FileViewMode.grid
                      ? Icons.view_list_rounded
                      : Icons.grid_view_rounded,
                ),
                tooltip: state.viewMode == FileViewMode.grid
                    ? 'List view'
                    : 'Grid view',
                onPressed: () {
                  final newMode = state.viewMode == FileViewMode.grid
                      ? FileViewMode.list
                      : FileViewMode.grid;
                  context.read<FileManagerBloc>().add(ChangeViewMode(newMode));
                },
              );
            },
          ),
          // Clear recents
          PopupMenuButton<String>(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.clear_all_rounded, size: 18),
                    SizedBox(width: AppSpacing.sm),
                    Text('Clear Recent'),
                  ],
                ),
              ),
            ],
            onSelected: (value) async {
              if (value == 'clear') {
                final confirmed = await ConfirmationDialog.show(
                  context,
                  title: 'Clear Recent Files',
                  message:
                      'Remove all recent files? Favorites will be preserved.',
                  confirmLabel: 'Clear',
                );
                if (confirmed && context.mounted) {
                  context.read<FileManagerBloc>().add(const ClearRecentFiles());
                }
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            child: AppSearchBar(
              hintText: AppLocalizations.searchFiles,
              onChanged: (query) {
                context.read<FileManagerBloc>().add(SearchFiles(query));
              },
            ),
          ),

          // Tabs
          BlocBuilder<FileManagerBloc, FileManagerState>(
            buildWhen: (prev, curr) => prev.activeTab != curr.activeTab,
            builder: (context, state) {
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                ),
                child: Row(
                  children: [
                    _TabChip(
                      label: AppLocalizations.recentFiles,
                      isSelected: state.activeTab == FileTab.recent,
                      onTap: () => context
                          .read<FileManagerBloc>()
                          .add(const LoadRecentFiles()),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _TabChip(
                      label: AppLocalizations.favorites,
                      isSelected: state.activeTab == FileTab.favorites,
                      onTap: () => context
                          .read<FileManagerBloc>()
                          .add(const LoadFavoriteFiles()),
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: AppSpacing.sm),

          // File type filter chips
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: 'All',
                    isSelected: _filterType == null,
                    onTap: () => setState(() => _filterType = null),
                  ),
                  const SizedBox(width: 6),
                  _FilterChip(
                    label: 'Documents',
                    icon: Icons.description_rounded,
                    color: const Color(0xFF3B82F6),
                    isSelected: _filterType == 'document',
                    onTap: () => setState(() => _filterType =
                        _filterType == 'document' ? null : 'document'),
                  ),
                  const SizedBox(width: 6),
                  _FilterChip(
                    label: 'Sheets',
                    icon: Icons.table_chart_rounded,
                    color: const Color(0xFF22C55E),
                    isSelected: _filterType == 'spreadsheet',
                    onTap: () => setState(() => _filterType =
                        _filterType == 'spreadsheet' ? null : 'spreadsheet'),
                  ),
                  const SizedBox(width: 6),
                  _FilterChip(
                    label: 'Slides',
                    icon: Icons.slideshow_rounded,
                    color: const Color(0xFFF59E0B),
                    isSelected: _filterType == 'presentation',
                    onTap: () => setState(() => _filterType =
                        _filterType == 'presentation' ? null : 'presentation'),
                  ),
                  const SizedBox(width: 6),
                  _FilterChip(
                    label: 'Images',
                    icon: Icons.image_rounded,
                    color: const Color(0xFF8B5CF6),
                    isSelected: _filterType == 'image',
                    onTap: () => setState(() =>
                        _filterType = _filterType == 'image' ? null : 'image'),
                  ),
                  const SizedBox(width: 6),
                  _FilterChip(
                    label: 'PDFs',
                    icon: Icons.picture_as_pdf_rounded,
                    color: const Color(0xFFEF4444),
                    isSelected: _filterType == 'pdf',
                    onTap: () => setState(() =>
                        _filterType = _filterType == 'pdf' ? null : 'pdf'),
                  ),
                ],
              ),
            ),
          ),

          Expanded(
            child: BlocBuilder<FileManagerBloc, FileManagerState>(
              builder: (context, state) {
                if (state.status == FileManagerStatus.loading) {
                  return const AppLoadingIndicator(message: 'Loading files...');
                }

                if (state.status == FileManagerStatus.error) {
                  return EmptyState(
                    icon: Icons.error_outline_rounded,
                    title: AppLocalizations.error,
                    description: state.errorMessage,
                    actionLabel: AppLocalizations.retry,
                    onAction: () => context
                        .read<FileManagerBloc>()
                        .add(const LoadRecentFiles()),
                  );
                }

                // Apply type filter
                var filtered = state.files;
                if (_filterType != null) {
                  filtered = filtered.where((f) {
                    final ft = FileType.fromPath(f.fileName);
                    switch (_filterType) {
                      case 'document':
                        return ft.isDocument;
                      case 'spreadsheet':
                        return ft.isSpreadsheet;
                      case 'presentation':
                        return ft.isPresentation;
                      case 'image':
                        return ft.isImage;
                      case 'pdf':
                        return ft == FileType.pdf;
                      default:
                        return true;
                    }
                  }).toList();
                }

                // Apply sort
                filtered = List.of(filtered)
                  ..sort((a, b) {
                    int cmp;
                    switch (_sortBy) {
                      case 'name':
                        cmp = a.fileName
                            .toLowerCase()
                            .compareTo(b.fileName.toLowerCase());
                      case 'size':
                        cmp = (a.sizeBytes ?? 0).compareTo(b.sizeBytes ?? 0);
                      case 'type':
                        cmp = a.fileType.compareTo(b.fileType);
                      default:
                        cmp = a.lastOpenedAt.compareTo(b.lastOpenedAt);
                    }
                    return _sortAsc ? cmp : -cmp;
                  });

                if (filtered.isEmpty) {
                  return EmptyState(
                    icon: Icons.folder_open_rounded,
                    title: _filterType != null
                        ? 'No $_filterType files'
                        : state.activeTab == FileTab.favorites
                            ? 'No favorites'
                            : AppLocalizations.noFiles,
                    description: _filterType != null
                        ? 'No files match the selected filter.'
                        : state.activeTab == FileTab.favorites
                            ? 'Mark files as favorites for quick access.'
                            : AppLocalizations.noFilesDescription,
                  );
                }

                if (state.viewMode == FileViewMode.grid) {
                  return _buildGridView(context, filtered);
                }
                return _buildListView(context, filtered);
              },
            ),
          ),

          // Storage summary bar
          BlocBuilder<FileManagerBloc, FileManagerState>(
            builder: (context, state) {
              if (state.files.isEmpty) return const SizedBox.shrink();
              int totalSize = 0;
              for (final f in state.files) {
                totalSize += f.sizeBytes ?? 0;
              }
              return Container(
                height: 28,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest
                      .withValues(alpha: 0.4),
                  border: Border(
                    top: BorderSide(
                        color: Theme.of(context).colorScheme.outlineVariant,
                        width: 0.5),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      '${state.files.length} files',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                    const Spacer(),
                    if (totalSize > 0)
                      Text(
                        'Total: ${FileUtils.formatSize(totalSize)}',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildListView(BuildContext context, List<RecentFileEntity> files) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      itemCount: files.length,
      itemBuilder: (context, index) {
        final file = files[index];
        return _FileListTile(file: file);
      },
    );
  }

  Widget _buildGridView(BuildContext context, List<RecentFileEntity> files) {
    final isDesktop = ResponsiveBuilder.of(context).isDesktop;

    return GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.lg),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isDesktop ? 5 : 3,
        childAspectRatio: 0.85,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.sm,
      ),
      itemCount: files.length,
      itemBuilder: (context, index) {
        final file = files[index];
        return _FileGridCard(file: file);
      },
    );
  }

  PopupMenuItem<String> _sortItem(String value, String label, IconData icon) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(children: [
        Icon(icon, size: 18),
        const SizedBox(width: 8),
        Text(label),
        if (_sortBy == value) ...[
          const Spacer(),
          Icon(_sortAsc ? Icons.arrow_upward : Icons.arrow_downward, size: 14),
        ],
      ]),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.icon,
    this.color,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData? icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      avatar: icon != null
          ? Icon(icon, size: 16, color: isSelected ? color : null)
          : null,
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
    );
  }
}

class _TabChip extends StatelessWidget {
  const _TabChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
    );
  }
}

class _FileListTile extends StatelessWidget {
  const _FileListTile({required this.file});

  final RecentFileEntity file;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fileType = FileType.fromPath(file.fileName);

    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _colorForType(fileType).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: Icon(
          _iconForType(fileType),
          color: _colorForType(fileType),
          size: 22,
        ),
      ),
      title: Text(
        file.fileName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '${fileType.label} • ${AppDateUtils.formatRelative(file.lastOpenedAt)}'
        '${file.sizeBytes != null ? ' • ${FileUtils.formatSize(file.sizeBytes!)}' : ''}',
        style: theme.textTheme.bodySmall,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(
              file.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
              color: file.isFavorite ? AppColors.secondary : null,
              size: 20,
            ),
            tooltip: file.isFavorite
                ? AppLocalizations.unfavoriteNote
                : AppLocalizations.favoriteNote,
            onPressed: () {
              context.read<FileManagerBloc>().add(ToggleFileFavorite(file.id));
            },
          ),
          PopupMenuButton<String>(
            iconSize: 18,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline_rounded, size: 18),
                    SizedBox(width: AppSpacing.sm),
                    Text('Remove'),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'delete') {
                context.read<FileManagerBloc>().add(DeleteRecentFile(file.id));
              }
            },
          ),
        ],
      ),
    );
  }
}

class _FileGridCard extends StatelessWidget {
  const _FileGridCard({required this.file});

  final RecentFileEntity file;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fileType = FileType.fromPath(file.fileName);

    return Card(
      child: InkWell(
        onTap: () {
          // Open file
        },
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _iconForType(fileType),
                color: _colorForType(fileType),
                size: 36,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                file.fileName,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                AppDateUtils.formatRelative(file.lastOpenedAt),
                style: theme.textTheme.labelSmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

IconData _iconForType(FileType type) {
  if (type.isDocument) return Icons.description_rounded;
  if (type.isSpreadsheet) return Icons.table_chart_rounded;
  if (type.isPresentation) return Icons.slideshow_rounded;
  if (type.isImage) return Icons.image_rounded;
  if (type == FileType.pdf) return Icons.picture_as_pdf_rounded;
  return Icons.insert_drive_file_rounded;
}

Color _colorForType(FileType type) {
  if (type.isDocument) return const Color(0xFF3B82F6);
  if (type.isSpreadsheet) return const Color(0xFF22C55E);
  if (type.isPresentation) return const Color(0xFFF59E0B);
  if (type.isImage) return const Color(0xFF8B5CF6);
  if (type == FileType.pdf) return const Color(0xFFEF4444);
  return const Color(0xFF64748B);
}
