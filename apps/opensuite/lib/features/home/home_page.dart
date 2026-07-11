import 'package:fileutility_l10n/fileutility_l10n.dart';
import 'package:fileutility_ui_kit/fileutility_ui_kit.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../router/app_router.dart';
import 'widgets/animated_card.dart';

/// Home / Dashboard page.
///
/// Provides quick access to recent files, quick actions, and
/// an overview of the application modules.
class HomePage extends StatelessWidget {
  /// Creates a [HomePage].
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenSize = ResponsiveBuilder.of(context);
    final isDesktop = screenSize.isDesktop;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: _buildHeader(context, theme),
          ),

          // Quick Actions
          SliverToBoxAdapter(
            child: _buildQuickActions(context, theme, isDesktop),
          ),

          // Module Cards
          SliverPadding(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? AppSpacing.xxxl : AppSpacing.lg,
              vertical: AppSpacing.lg,
            ),
            sliver: SliverToBoxAdapter(
              child: _buildModuleGrid(context, theme, isDesktop),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xxl,
        AppSpacing.xxxl,
        AppSpacing.xxl,
        AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.08),
            theme.colorScheme.tertiary.withValues(alpha: 0.04),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.welcomeTitle,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            AppLocalizations.welcomeDescription,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(
    BuildContext context,
    ThemeData theme,
    bool isDesktop,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? AppSpacing.xxxl : AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.quickActions,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _QuickActionChip(
                icon: Icons.note_add_rounded,
                label: AppLocalizations.newNote,
                onTap: () => context.go(AppRouter.newNote),
              ),
              _QuickActionChip(
                icon: Icons.description_rounded,
                label: AppLocalizations.newDocument,
                onTap: () => context.go(AppRouter.newDocument),
              ),
              _QuickActionChip(
                icon: Icons.table_chart_rounded,
                label: 'New Sheet',
                onTap: () => context.go(AppRouter.newSpreadsheet),
              ),
              _QuickActionChip(
                icon: Icons.slideshow_rounded,
                label: 'New Slides',
                onTap: () => context.go(AppRouter.newPresentation),
              ),
              _QuickActionChip(
                icon: Icons.folder_open_rounded,
                label: AppLocalizations.browse,
                onTap: () => context.go(AppRouter.files),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModuleGrid(
    BuildContext context,
    ThemeData theme,
    bool isDesktop,
  ) {
    final modules = [
      _ModuleInfo(
        title: AppLocalizations.notes,
        description:
            'Create and organize notes with rich text, markdown, and checklists.',
        icon: Icons.note_alt_rounded,
        color: const Color(0xFF8B5CF6),
        route: AppRouter.notes,
      ),
      _ModuleInfo(
        title: AppLocalizations.fileManager,
        description: 'Browse, search, and manage your documents and files.',
        icon: Icons.folder_rounded,
        color: const Color(0xFFF59E0B),
        route: AppRouter.files,
      ),
      _ModuleInfo(
        title: AppLocalizations.textEditor,
        description:
            'Edit text and markdown files with live preview and syntax support.',
        icon: Icons.edit_document,
        color: const Color(0xFF14B8A6),
        route: AppRouter.editor,
      ),
      _ModuleInfo(
        title: AppLocalizations.documents,
        description:
            'Create and edit rich documents with formatting, tables, and images.',
        icon: Icons.description_rounded,
        color: const Color(0xFF3B82F6),
        route: AppRouter.documents,
      ),
      _ModuleInfo(
        title: AppLocalizations.spreadsheets,
        description:
            'Work with spreadsheets featuring formulas, charts, and more.',
        icon: Icons.table_chart_rounded,
        color: const Color(0xFF22C55E),
        route: AppRouter.spreadsheets,
      ),
      _ModuleInfo(
        title: AppLocalizations.pdf,
        description: 'View, annotate, merge, split, and manage PDF documents.',
        icon: Icons.picture_as_pdf_rounded,
        color: const Color(0xFFEF4444),
        route: AppRouter.pdfViewer,
      ),
      _ModuleInfo(
        title: 'Presentations',
        description:
            'Create slide decks with themes, transitions, and speaker notes.',
        icon: Icons.slideshow_rounded,
        color: const Color(0xFFEC4899),
        route: AppRouter.presentations,
      ),
      _ModuleInfo(
        title: 'Image Editor',
        description: 'Crop, rotate, resize, and adjust images with filters.',
        icon: Icons.image_rounded,
        color: const Color(0xFF06B6D4),
        route: AppRouter.imageEditor,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Modules', style: theme.textTheme.titleMedium),
        const SizedBox(height: AppSpacing.md),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isDesktop ? 4 : 2,
            childAspectRatio: isDesktop ? 1.6 : 1.4,
            crossAxisSpacing: AppSpacing.md,
            mainAxisSpacing: AppSpacing.md,
          ),
          itemCount: modules.length,
          itemBuilder: (context, index) {
            final module = modules[index];
            return AnimatedModuleCard(
              title: module.title,
              description: module.description,
              icon: module.icon,
              color: module.color,
              staggerIndex: index,
              onTap:
                  module.route != null ? () => context.go(module.route!) : null,
            );
          },
        ),
      ],
    );
  }
}

class _ModuleInfo {
  _ModuleInfo({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    this.route,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final String? route;
}

class _QuickActionChip extends StatelessWidget {
  const _QuickActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      onPressed: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
    );
  }
}
