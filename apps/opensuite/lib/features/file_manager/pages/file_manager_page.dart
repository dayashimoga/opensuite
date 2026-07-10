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

class _FileManagerContent extends StatelessWidget {
  const _FileManagerContent();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppLocalizations.fileManager),
        centerTitle: false,
        actions: [
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

          // File list
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

                if (state.files.isEmpty) {
                  return EmptyState(
                    icon: Icons.folder_open_rounded,
                    title: state.activeTab == FileTab.favorites
                        ? 'No favorites'
                        : AppLocalizations.noFiles,
                    description: state.activeTab == FileTab.favorites
                        ? 'Mark files as favorites for quick access.'
                        : AppLocalizations.noFilesDescription,
                  );
                }

                if (state.viewMode == FileViewMode.grid) {
                  return _buildGridView(context, state);
                }
                return _buildListView(context, state);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListView(BuildContext context, FileManagerState state) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      itemCount: state.files.length,
      itemBuilder: (context, index) {
        final file = state.files[index];
        return _FileListTile(file: file);
      },
    );
  }

  Widget _buildGridView(BuildContext context, FileManagerState state) {
    final isDesktop = ResponsiveBuilder.of(context).isDesktop;

    return GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.lg),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isDesktop ? 5 : 3,
        childAspectRatio: 0.85,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.sm,
      ),
      itemCount: state.files.length,
      itemBuilder: (context, index) {
        final file = state.files[index];
        return _FileGridCard(file: file);
      },
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
