import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:fileutility_core/fileutility_core.dart';
import 'package:fileutility_ui_kit/fileutility_ui_kit.dart';
import 'package:fileutility_l10n/fileutility_l10n.dart';
import 'package:fileutility_storage/fileutility_storage.dart';

import '../../../di/app_module.dart';
import '../../../router/app_router.dart';
import '../bloc/notes_bloc.dart';

/// Notes list page showing all notes with search, pin, and CRUD.
class NotesPage extends StatelessWidget {
  const NotesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AppModule.notesBloc..add(const LoadNotes()),
      child: const _NotesPageContent(),
    );
  }
}

class _NotesPageContent extends StatelessWidget {
  const _NotesPageContent();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppLocalizations.notes),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: AppLocalizations.newNote,
            onPressed: () => context.go(AppRouter.newNote),
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
              hintText: AppLocalizations.searchNotes,
              onChanged: (query) {
                context.read<NotesBloc>().add(SearchNotes(query));
              },
            ),
          ),

          // Notes list
          Expanded(
            child: BlocBuilder<NotesBloc, NotesState>(
              builder: (context, state) {
                if (state.status == NotesStatus.loading) {
                  return const AppLoadingIndicator(message: 'Loading notes...');
                }

                if (state.status == NotesStatus.error) {
                  return EmptyState(
                    icon: Icons.error_outline_rounded,
                    title: AppLocalizations.error,
                    description: state.errorMessage,
                    actionLabel: AppLocalizations.retry,
                    onAction: () =>
                        context.read<NotesBloc>().add(const LoadNotes()),
                  );
                }

                if (state.notes.isEmpty) {
                  return EmptyState(
                    icon: Icons.note_alt_outlined,
                    title: state.searchQuery.isNotEmpty
                        ? AppLocalizations.noResults
                        : AppLocalizations.noNotes,
                    description: state.searchQuery.isNotEmpty
                        ? null
                        : AppLocalizations.noNotesDescription,
                    actionLabel: state.searchQuery.isEmpty
                        ? AppLocalizations.newNote
                        : null,
                    onAction: state.searchQuery.isEmpty
                        ? () => context.go(AppRouter.newNote)
                        : null,
                  );
                }

                return _buildNotesList(context, state);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go(AppRouter.newNote),
        tooltip: AppLocalizations.newNote,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  Widget _buildNotesList(BuildContext context, NotesState state) {
    final pinned = state.pinnedNotes;
    final unpinned = state.unpinnedNotes;
    final screenSize = ResponsiveBuilder.of(context);
    final isDesktop = screenSize.isDesktop;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        if (pinned.isNotEmpty) ...[
          _SectionLabel(label: 'Pinned'),
          const SizedBox(height: AppSpacing.sm),
          _NotesGrid(
            notes: pinned,
            crossAxisCount: isDesktop ? 4 : 2,
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
        if (unpinned.isNotEmpty) ...[
          if (pinned.isNotEmpty) _SectionLabel(label: 'Other'),
          if (pinned.isNotEmpty) const SizedBox(height: AppSpacing.sm),
          _NotesGrid(
            notes: unpinned,
            crossAxisCount: isDesktop ? 4 : 2,
          ),
        ],
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            fontWeight: FontWeight.w600,
          ),
    );
  }
}

class _NotesGrid extends StatelessWidget {
  const _NotesGrid({required this.notes, required this.crossAxisCount});

  final List<NoteEntity> notes;
  final int crossAxisCount;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 1.2,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.sm,
      ),
      itemCount: notes.length,
      itemBuilder: (context, index) => _NoteCard(note: notes[index]),
    );
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({required this.note});

  final NoteEntity note;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Color? cardColor;
    if (note.color != null) {
      try {
        cardColor = Color(int.parse(note.color!, radix: 16));
      } catch (_) {
        cardColor = null;
      }
    }

    return Card(
      color: cardColor,
      child: InkWell(
        onTap: () => context.go('/notes/${note.id}'),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title row with pin indicator
              Row(
                children: [
                  if (note.isPinned)
                    Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.xs),
                      child: Icon(
                        Icons.push_pin_rounded,
                        size: 14,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  Expanded(
                    child: Text(
                      note.title.isNotEmpty ? note.title : 'Untitled',
                      style: theme.textTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _NotePopupMenu(note: note),
                ],
              ),

              const SizedBox(height: AppSpacing.xs),

              // Content type badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xxs,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                ),
                child: Text(
                  note.contentType.label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.sm),

              // Content preview
              Expanded(
                child: Text(
                  note.contentPreview,
                  style: theme.textTheme.bodySmall,
                  overflow: TextOverflow.fade,
                ),
              ),

              // Timestamp
              Text(
                AppDateUtils.formatRelative(note.modifiedAt),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotePopupMenu extends StatelessWidget {
  const _NotePopupMenu({required this.note});

  final NoteEntity note;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      iconSize: 18,
      icon: const Icon(Icons.more_vert_rounded),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'pin',
          child: Row(
            children: [
              Icon(
                note.isPinned
                    ? Icons.push_pin_outlined
                    : Icons.push_pin_rounded,
                size: 18,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(note.isPinned
                  ? AppLocalizations.unpinNote
                  : AppLocalizations.pinNote),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'favorite',
          child: Row(
            children: [
              Icon(
                note.isFavorite
                    ? Icons.favorite_rounded
                    : Icons.favorite_outline_rounded,
                size: 18,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(note.isFavorite
                  ? AppLocalizations.unfavoriteNote
                  : AppLocalizations.favoriteNote),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(
                Icons.delete_outline_rounded,
                size: 18,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                AppLocalizations.deleteNote,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
          ),
        ),
      ],
      onSelected: (value) async {
        final bloc = context.read<NotesBloc>();
        switch (value) {
          case 'pin':
            bloc.add(TogglePinNote(note.id));
          case 'favorite':
            bloc.add(ToggleFavoriteNote(note.id));
          case 'delete':
            final confirmed = await ConfirmationDialog.show(
              context,
              title: AppLocalizations.deleteNote,
              message: AppLocalizations.deleteNoteConfirm,
            );
            if (confirmed) {
              bloc.add(DeleteNote(note.id));
            }
        }
      },
    );
  }
}
