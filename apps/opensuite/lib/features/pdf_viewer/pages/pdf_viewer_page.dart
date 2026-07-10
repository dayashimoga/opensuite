import 'package:fileutility_ui_kit/fileutility_ui_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/pdf_viewer_bloc.dart';

/// PDF viewer page with page navigation, zoom, thumbnails,
/// annotations toolbar, and search.
class PdfViewerPage extends StatelessWidget {
  final String? filePath;
  const PdfViewerPage({super.key, this.filePath});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<PdfViewerBloc>(
      create: (_) {
        final bloc = PdfViewerBloc();
        if (filePath != null) {
          bloc.add(LoadPdf(filePath!));
        }
        return bloc;
      },
      child: const _ViewerContent(),
    );
  }
}

class _ViewerContent extends StatelessWidget {
  const _ViewerContent();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<PdfViewerBloc, PdfViewerState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: Text(state.filePath?.split('/').last ?? 'PDF Viewer'),
            actions: [
              // Zoom controls
              IconButton(
                icon: const Icon(Icons.zoom_out, size: 20),
                onPressed: () => context
                    .read<PdfViewerBloc>()
                    .add(SetZoom(state.zoom - 0.25)),
                tooltip: 'Zoom Out',
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text('${(state.zoom * 100).toInt()}%',
                    style: theme.textTheme.labelMedium),
              ),
              IconButton(
                icon: const Icon(Icons.zoom_in, size: 20),
                onPressed: () => context
                    .read<PdfViewerBloc>()
                    .add(SetZoom(state.zoom + 0.25)),
                tooltip: 'Zoom In',
              ),
              const SizedBox(width: 8),
              // Thumbnail toggle
              IconButton(
                icon: Icon(
                  state.showThumbnails
                      ? Icons.view_sidebar
                      : Icons.view_sidebar_outlined,
                  size: 20,
                ),
                onPressed: () =>
                    context.read<PdfViewerBloc>().add(const ToggleThumbnails()),
                tooltip: 'Thumbnails',
              ),
              // Rotate
              IconButton(
                icon: const Icon(Icons.rotate_right, size: 20),
                onPressed: () => context
                    .read<PdfViewerBloc>()
                    .add(RotatePage(state.currentPage, 90)),
                tooltip: 'Rotate Page',
              ),
              // Annotation tools
              PopupMenuButton<String>(
                icon: const Icon(Icons.edit_note, size: 20),
                tooltip: 'Annotations',
                itemBuilder: (_) => const [
                  PopupMenuItem(
                      value: 'highlight',
                      child: Row(children: [
                        Icon(Icons.highlight, color: Colors.yellow),
                        SizedBox(width: 8),
                        Text('Highlight'),
                      ])),
                  PopupMenuItem(
                      value: 'underline',
                      child: Row(children: [
                        Icon(Icons.format_underlined, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Underline'),
                      ])),
                  PopupMenuItem(
                      value: 'note',
                      child: Row(children: [
                        Icon(Icons.sticky_note_2, color: Colors.amber),
                        SizedBox(width: 8),
                        Text('Sticky Note'),
                      ])),
                  PopupMenuItem(
                      value: 'draw',
                      child: Row(children: [
                        Icon(Icons.draw, color: Colors.blue),
                        SizedBox(width: 8),
                        Text('Freehand Draw'),
                      ])),
                ],
                onSelected: (tool) => _addAnnotation(context, state, tool),
              ),
              // Search
              IconButton(
                icon: const Icon(Icons.search, size: 20),
                onPressed: () => _showSearch(context),
                tooltip: 'Search',
              ),
            ],
          ),
          body: Row(
            children: [
              // Thumbnail sidebar
              if (state.showThumbnails)
                _ThumbnailSidebar(
                  currentPage: state.currentPage,
                  totalPages: state.totalPages > 0 ? state.totalPages : 10,
                  onPageTap: (page) =>
                      context.read<PdfViewerBloc>().add(GoToPage(page)),
                ),
              // Main PDF viewing area
              Expanded(
                child: _PdfContentArea(state: state),
              ),
            ],
          ),
          // Bottom page navigation bar
          bottomNavigationBar: _PageNavigationBar(
            currentPage: state.currentPage,
            totalPages: state.totalPages > 0 ? state.totalPages : 1,
            onPrevious: () =>
                context.read<PdfViewerBloc>().add(const PreviousPage()),
            onNext: () => context.read<PdfViewerBloc>().add(const NextPage()),
            onGoTo: (page) => context.read<PdfViewerBloc>().add(GoToPage(page)),
          ),
        );
      },
    );
  }

  void _addAnnotation(BuildContext context, PdfViewerState state, String type) {
    final annotation = PdfAnnotation(
      id: 'ann_${DateTime.now().microsecondsSinceEpoch}',
      page: state.currentPage,
      type: type,
      x: 0.3,
      y: 0.3,
      width: 0.4,
      height: 0.05,
      color: type == 'highlight'
          ? '#FFFF00'
          : type == 'underline'
              ? '#FF0000'
              : '#FFA500',
      text: type == 'note' ? 'New note' : null,
    );
    context.read<PdfViewerBloc>().add(AddAnnotation(annotation));
  }

  void _showSearch(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Search in PDF'),
        content: TextField(
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search text...',
            prefixIcon: Icon(Icons.search),
          ),
          onSubmitted: (query) {
            context.read<PdfViewerBloc>().add(SearchInPdf(query));
            Navigator.pop(context);
          },
        ),
      ),
    );
  }
}

/// Thumbnail sidebar showing page previews.
class _ThumbnailSidebar extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final ValueChanged<int> onPageTap;

  const _ThumbnailSidebar({
    required this.currentPage,
    required this.totalPages,
    required this.onPageTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 120,
      decoration: BoxDecoration(
        border: Border(
          right:
              BorderSide(color: theme.colorScheme.outlineVariant, width: 0.5),
        ),
      ),
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: totalPages,
        itemBuilder: (context, index) {
          final page = index + 1;
          final isActive = page == currentPage;
          return GestureDetector(
            onTap: () => onPageTap(page),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isActive
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outlineVariant,
                  width: isActive ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: AspectRatio(
                aspectRatio: 210 / 297, // A4 ratio
                child: Container(
                  color: Colors.white,
                  alignment: Alignment.center,
                  child: Text(
                    '$page',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Main PDF content area with annotation overlay.
class _PdfContentArea extends StatelessWidget {
  final PdfViewerState state;

  const _PdfContentArea({required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (state.status == PdfViewerStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.filePath == null) {
      return EmptyState(
        icon: Icons.picture_as_pdf_outlined,
        title: 'No PDF Open',
        description: 'Open a PDF file to view it here',
        actionLabel: 'Open PDF',
        onAction: () {
          // Would trigger file picker
        },
      );
    }

    // PDF page display with annotation overlay
    return InteractiveViewer(
      minScale: 0.25,
      maxScale: 5.0,
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          constraints: BoxConstraints(maxWidth: 800 * state.zoom),
          child: AspectRatio(
            aspectRatio: 210 / 297,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // PDF page content placeholder
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.picture_as_pdf,
                          size: 64,
                          color:
                              theme.colorScheme.primary.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Page ${state.currentPage}',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.5),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          state.filePath?.split('/').last ?? '',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.3),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Annotation overlays
                  ...state.annotations
                      .where((a) => a.page == state.currentPage)
                      .map((annotation) =>
                          _AnnotationOverlay(annotation: annotation)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Renders an annotation overlay on the PDF page.
class _AnnotationOverlay extends StatelessWidget {
  final PdfAnnotation annotation;

  const _AnnotationOverlay({required this.annotation});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: annotation.x * 800,
      top: annotation.y * 1131,
      width: annotation.width * 800,
      height: annotation.height * 1131,
      child: Container(
        decoration: BoxDecoration(
          color: _parseColor(annotation.color).withValues(alpha: 0.3),
          border: annotation.type == 'underline'
              ? Border(
                  bottom: BorderSide(
                      color: _parseColor(annotation.color), width: 2))
              : null,
        ),
        child: annotation.type == 'note'
            ? Tooltip(
                message: annotation.text ?? '',
                child: Icon(Icons.sticky_note_2,
                    size: 20, color: _parseColor(annotation.color)),
              )
            : null,
      ),
    );
  }

  Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return Colors.yellow;
    }
  }
}

/// Bottom page navigation bar.
class _PageNavigationBar extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final ValueChanged<int> onGoTo;

  const _PageNavigationBar({
    required this.currentPage,
    required this.totalPages,
    required this.onPrevious,
    required this.onNext,
    required this.onGoTo,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant, width: 0.5),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: currentPage > 1 ? onPrevious : null,
          ),
          const SizedBox(width: 8),
          Text(
            'Page $currentPage of $totalPages',
            style: theme.textTheme.labelMedium,
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: currentPage < totalPages ? onNext : null,
          ),
        ],
      ),
    );
  }
}
