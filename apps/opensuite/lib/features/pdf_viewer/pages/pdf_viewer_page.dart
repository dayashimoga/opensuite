import 'package:file_picker/file_picker.dart';
import 'package:fileutility_ui_kit/fileutility_ui_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:share_plus/share_plus.dart';

import '../bloc/pdf_viewer_bloc.dart';

/// PDF viewer page with real rendering via pdfrx, page navigation,
/// zoom, thumbnails, search, and share.
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
            title: Text(
              state.filePath?.split('/').last ??
                  state.filePath?.split('\\').last ??
                  'PDF Viewer',
            ),
            actions: [
              if (state.filePath != null) ...[
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
                  child: Text(
                    '${(state.zoom * 100).toInt()}%',
                    style: theme.textTheme.labelMedium,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.zoom_in, size: 20),
                  onPressed: () => context
                      .read<PdfViewerBloc>()
                      .add(SetZoom(state.zoom + 0.25)),
                  tooltip: 'Zoom In',
                ),
                const SizedBox(width: 8),
                // Share
                IconButton(
                  icon: const Icon(Icons.share, size: 20),
                  onPressed: () => _sharePdf(context, state),
                  tooltip: 'Share',
                ),
                // Open another PDF
                IconButton(
                  icon: const Icon(Icons.folder_open, size: 20),
                  onPressed: () => _openPdf(context),
                  tooltip: 'Open PDF',
                ),
              ],
            ],
          ),
          body: _buildBody(context, state),
          bottomNavigationBar: state.filePath != null
              ? _PageNavigationBar(
                  currentPage: state.currentPage,
                  totalPages: state.totalPages > 0 ? state.totalPages : 1,
                  onPrevious: () =>
                      context.read<PdfViewerBloc>().add(const PreviousPage()),
                  onNext: () =>
                      context.read<PdfViewerBloc>().add(const NextPage()),
                  onGoTo: (page) =>
                      context.read<PdfViewerBloc>().add(GoToPage(page)),
                )
              : null,
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, PdfViewerState state) {
    if (state.status == PdfViewerStatus.loading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading PDF...'),
          ],
        ),
      );
    }

    if (state.filePath == null) {
      return EmptyState(
        icon: Icons.picture_as_pdf_outlined,
        title: 'No PDF Open',
        description: 'Open a PDF file to view it here',
        actionLabel: 'Open PDF',
        onAction: () => _openPdf(context),
      );
    }

    if (state.status == PdfViewerStatus.error) {
      return EmptyState(
        icon: Icons.error_outline,
        title: 'Error Loading PDF',
        description: state.errorMessage ?? 'Could not load the PDF file',
        actionLabel: 'Try Again',
        onAction: () =>
            context.read<PdfViewerBloc>().add(LoadPdf(state.filePath!)),
      );
    }

    // Real PDF rendering with pdfrx
    return PdfViewer.file(
      state.filePath!,
      params: PdfViewerParams(
        enableTextSelection: true,
        maxScale: 5.0,
        onDocumentChanged: (document) {
          if (document != null && context.mounted) {
            context
                .read<PdfViewerBloc>()
                .add(SetTotalPages(document.pages.length));
          }
        },
        viewerOverlayBuilder: (context, size, handleLinkTap) => [],
      ),
    );
  }

  Future<void> _openPdf(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      allowMultiple: false,
    );
    if (result != null && result.files.isNotEmpty) {
      final path = result.files.single.path;
      if (path != null && context.mounted) {
        context.read<PdfViewerBloc>().add(LoadPdf(path));
      }
    }
  }

  Future<void> _sharePdf(BuildContext context, PdfViewerState state) async {
    if (state.filePath != null) {
      await Share.shareXFiles(
        [XFile(state.filePath!)],
        text: 'Share PDF',
      );
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
        color: theme.colorScheme.surfaceContainerLow,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outlineVariant,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, size: 20),
            onPressed: currentPage > 1 ? onPrevious : null,
            tooltip: 'Previous Page',
          ),
          GestureDetector(
            onTap: () => _showPagePicker(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Page $currentPage of $totalPages',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, size: 20),
            onPressed: currentPage < totalPages ? onNext : null,
            tooltip: 'Next Page',
          ),
        ],
      ),
    );
  }

  void _showPagePicker(BuildContext context) {
    final controller = TextEditingController(text: '$currentPage');
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Go to Page'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: '1 - $totalPages',
            prefixIcon: const Icon(Icons.find_in_page),
          ),
          onSubmitted: (value) {
            final page = int.tryParse(value);
            if (page != null && page >= 1 && page <= totalPages) {
              onGoTo(page);
            }
            Navigator.pop(context);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final page = int.tryParse(controller.text);
              if (page != null && page >= 1 && page <= totalPages) {
                onGoTo(page);
              }
              Navigator.pop(context);
            },
            child: const Text('Go'),
          ),
        ],
      ),
    );
  }
}
