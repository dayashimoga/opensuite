import 'package:fileutility_core/fileutility_core.dart';
import 'package:fileutility_storage/fileutility_storage.dart';
import 'package:fileutility_ui_kit/fileutility_ui_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../di/app_module.dart';
import '../bloc/presentation_bloc.dart';

/// Page listing all presentations.
class PresentationListPage extends StatelessWidget {
  const PresentationListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<PresentationBloc>(
      create: (_) => AppModule.presentationBloc..add(const LoadPresentations()),
      child: const _ListContent(),
    );
  }
}

class _ListContent extends StatelessWidget {
  const _ListContent();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Presentations')),
      body: BlocBuilder<PresentationBloc, PresentationState>(
        builder: (context, state) {
          if (state.status == PresentationStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.presentations.isEmpty) {
            return EmptyState(
              icon: Icons.slideshow_outlined,
              title: 'No Presentations',
              description: 'Create a new presentation to get started',
              actionLabel: 'New Presentation',
              onAction: () => context.go('/presentations/new'),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(AppSpacing.md),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 280,
              mainAxisSpacing: AppSpacing.md,
              crossAxisSpacing: AppSpacing.md,
              childAspectRatio: 16 / 11,
            ),
            itemCount: state.presentations.length,
            itemBuilder: (context, index) {
              final pres = state.presentations[index];
              return _PresentationCard(
                presentation: pres,
                onTap: () => context.go('/presentations/${pres.id}'),
                onFavorite: () => context
                    .read<PresentationBloc>()
                    .add(TogglePresentationFavorite(pres.id)),
                onDuplicate: () => context
                    .read<PresentationBloc>()
                    .add(DuplicatePresentationEntry(pres.id)),
                onDelete: () {
                  ConfirmationDialog.show(
                    context,
                    title: 'Delete Presentation',
                    message: 'Delete "${pres.title}"?',
                  ).then((confirmed) {
                    if (confirmed && context.mounted) {
                      context
                          .read<PresentationBloc>()
                          .add(DeletePresentationEntry(pres.id));
                    }
                  });
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/presentations/new'),
        icon: const Icon(Icons.add),
        label: const Text('New Presentation'),
      ),
    );
  }
}

class _PresentationCard extends StatelessWidget {
  final PresentationEntity presentation;
  final VoidCallback onTap;
  final VoidCallback onFavorite;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;

  const _PresentationCard({
    required this.presentation,
    required this.onTap,
    required this.onFavorite,
    required this.onDuplicate,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Slide thumbnail preview
            Expanded(
              child: Container(
                color: const Color(0xFF1E3A5F),
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.slideshow,
                        size: 36, color: Colors.white.withValues(alpha: 0.7)),
                    const SizedBox(height: 4),
                    Text(
                      '${presentation.slideCount} slide${presentation.slideCount > 1 ? "s" : ""}',
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
            // Info footer
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          presentation.title,
                          style: theme.textTheme.labelMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          AppDateUtils.formatRelative(presentation.modifiedAt),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    iconSize: 18,
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 24, minHeight: 24),
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: 'favorite',
                        child: Text(presentation.isFavorite
                            ? 'Unfavorite'
                            : 'Favorite'),
                      ),
                      const PopupMenuItem(
                          value: 'duplicate', child: Text('Duplicate')),
                      const PopupMenuItem(
                          value: 'delete', child: Text('Delete')),
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
          ],
        ),
      ),
    );
  }
}
