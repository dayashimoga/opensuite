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

class _ViewerContent extends StatefulWidget {
  const _ViewerContent();

  @override
  State<_ViewerContent> createState() => _ViewerContentState();
}

class _ViewerContentState extends State<_ViewerContent> {
  late final PdfViewerController _pdfViewerController;
  late final PdfTextSearcher _pdfTextSearcher;
  final _searchController = TextEditingController();
  bool _showSearchBar = false;

  @override
  void initState() {
    super.initState();
    _pdfViewerController = PdfViewerController();
    _pdfTextSearcher = PdfTextSearcher(_pdfViewerController)
      ..addListener(_onSearchUpdate);

    _pdfViewerController.addListener(_onViewerUpdate);
  }

  void _onSearchUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  void _onViewerUpdate() {
    if (!mounted) return;
    final zoom = _pdfViewerController.currentZoom;
    final stateZoom = context.read<PdfViewerBloc>().state.zoom;
    if ((zoom - stateZoom).abs() > 0.01) {
      context.read<PdfViewerBloc>().add(SetZoom(zoom));
    }
    final page = _pdfViewerController.pageNumber;
    final statePage = context.read<PdfViewerBloc>().state.currentPage;
    if (page != null && page != statePage) {
      context.read<PdfViewerBloc>().add(GoToPage(page));
    }
  }

  @override
  void dispose() {
    _pdfViewerController.removeListener(_onViewerUpdate);

    _pdfTextSearcher.removeListener(_onSearchUpdate);
    _pdfTextSearcher.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocConsumer<PdfViewerBloc, PdfViewerState>(
      listenWhen: (prev, curr) =>
          prev.zoom != curr.zoom || prev.currentPage != curr.currentPage,
      listener: (context, state) {
        if (_pdfViewerController.isReady) {
          if ((_pdfViewerController.currentZoom - state.zoom).abs() > 0.01) {
            _pdfViewerController.setZoom(
              _pdfViewerController.centerPosition,
              state.zoom,
            );
          }
          if (_pdfViewerController.pageNumber != state.currentPage) {
            _pdfViewerController.goToPage(pageNumber: state.currentPage);
          }
        }
      },
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
                // Sidebar thumbnails toggle
                IconButton(
                  icon: Icon(
                    state.showThumbnails
                        ? Icons.grid_on
                        : Icons.grid_off_outlined,
                    size: 20,
                  ),
                  onPressed: () => context
                      .read<PdfViewerBloc>()
                      .add(const ToggleThumbnails()),
                  tooltip: 'Toggle Thumbnails',
                ),
                // Search button
                IconButton(
                  icon: const Icon(Icons.search, size: 20),
                  onPressed: () {
                    setState(() {
                      _showSearchBar = !_showSearchBar;
                      if (!_showSearchBar) {
                        _searchController.clear();
                        _pdfTextSearcher.startTextSearch('', caseInsensitive: true);
                      }
                    });
                  },
                  tooltip: 'Search Text',
                ),
                const SizedBox(width: 8),
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
          body: Row(
            children: [
              if (state.showThumbnails && state.filePath != null)
                Container(
                  width: 130,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerLow,
                    border: Border(
                      right: BorderSide(
                        color: theme.colorScheme.outlineVariant,
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: PdfDocumentViewBuilder.file(
                    state.filePath!,
                    builder: (context, document) {
                      if (document == null) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      return ListView.builder(
                        itemCount: document.pages.length,
                        padding: const EdgeInsets.all(8),
                        itemBuilder: (context, index) {
                          final pageNum = index + 1;
                          final isCurrent = state.currentPage == pageNum;
                          return InkWell(
                            onTap: () {
                              context.read<PdfViewerBloc>().add(GoToPage(pageNum));
                              _pdfViewerController.goToPage(pageNumber: pageNum);
                            },
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: isCurrent
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.outlineVariant,
                                  width: isCurrent ? 2 : 1,
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(3),
                                child: SizedBox(
                                  height: 140,
                                  child: PdfPageView(
                                    document: document,
                                    pageNumber: pageNum,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              Expanded(
                child: Column(
                  children: [
                    if (_showSearchBar && state.filePath != null)
                      Container(
                        height: 48,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHigh,
                          border: Border(
                            bottom: BorderSide(
                              color: theme.colorScheme.outlineVariant,
                              width: 0.5,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.search, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                decoration: const InputDecoration(
                                  hintText: 'Search text...',
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                                style: theme.textTheme.bodyMedium,
                                onChanged: (value) {
                                  context
                                      .read<PdfViewerBloc>()
                                      .add(SearchInPdf(value));
                                  _pdfTextSearcher.startTextSearch(
                                    value,
                                    caseInsensitive: true,
                                  );
                                },
                              ),
                            ),
                            if (_pdfTextSearcher.matches.isNotEmpty) ...[
                              Text(
                                '${(_pdfTextSearcher.currentIndex ?? 0) + 1}/${_pdfTextSearcher.matches.length}',
                                style: theme.textTheme.labelMedium,
                              ),
                              IconButton(
                                icon: const Icon(Icons.navigate_before, size: 20),
                                onPressed: () {
                                  _pdfTextSearcher.goToPrevMatch();
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.navigate_next, size: 20),
                                onPressed: () {
                                  _pdfTextSearcher.goToNextMatch();
                                },
                              ),
                            ],
                            IconButton(
                              icon: const Icon(Icons.close, size: 20),
                              onPressed: () {
                                setState(() {
                                  _showSearchBar = false;
                                  _searchController.clear();
                                  _pdfTextSearcher.startTextSearch(
                                    '',
                                    caseInsensitive: true,
                                  );
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    Expanded(
                      child: _buildBody(context, state),
                    ),
                  ],
                ),
              ),
            ],
          ),
          bottomNavigationBar: state.filePath != null
              ? _PageNavigationBar(
                  currentPage: state.currentPage,
                  totalPages: state.totalPages > 0 ? state.totalPages : 1,
                  onPrevious: () {
                    context.read<PdfViewerBloc>().add(const PreviousPage());
                    if (_pdfViewerController.isReady && state.currentPage > 1) {
                      _pdfViewerController.goToPage(pageNumber: state.currentPage - 1);
                    }
                  },
                  onNext: () {
                    context.read<PdfViewerBloc>().add(const NextPage());
                    if (_pdfViewerController.isReady && state.currentPage < state.totalPages) {
                      _pdfViewerController.goToPage(pageNumber: state.currentPage + 1);
                    }
                  },
                  onGoTo: (page) {
                    context.read<PdfViewerBloc>().add(GoToPage(page));
                    _pdfViewerController.goToPage(pageNumber: page);
                  },
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
      controller: _pdfViewerController,
      params: PdfViewerParams(
        enableTextSelection: true,
        maxScale: 5.0,
        pagePaintCallbacks: [_pdfTextSearcher.pageTextMatchPaintCallback],
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
