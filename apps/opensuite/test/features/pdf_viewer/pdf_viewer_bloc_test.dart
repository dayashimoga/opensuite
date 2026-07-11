import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opensuite/features/pdf_viewer/bloc/pdf_viewer_bloc.dart';

void main() {
  late PdfViewerBloc bloc;

  setUp(() {
    bloc = PdfViewerBloc();
  });

  tearDown(() {
    bloc.close();
  });

  group('PdfViewerBloc', () {
    test('initial state is correct', () {
      expect(bloc.state.status, PdfViewerStatus.initial);
      expect(bloc.state.filePath, isNull);
      expect(bloc.state.currentPage, 1);
      expect(bloc.state.totalPages, 0);
      expect(bloc.state.zoom, 1.0);
      expect(bloc.state.showThumbnails, false);
      expect(bloc.state.searchQuery, '');
      expect(bloc.state.searchResults, isEmpty);
      expect(bloc.state.annotations, isEmpty);
      expect(bloc.state.pageRotations, isEmpty);
    });

    group('LoadPdf', () {
      blocTest<PdfViewerBloc, PdfViewerState>(
        'emits loaded state with filePath and resets currentPage',
        build: () => bloc,
        act: (bloc) => bloc.add(const LoadPdf('assets/sample.pdf')),
        expect: () => [
          const PdfViewerState(
            status: PdfViewerStatus.loading,
            filePath: 'assets/sample.pdf',
          ),
          const PdfViewerState(
            status: PdfViewerStatus.loaded,
            filePath: 'assets/sample.pdf',
            currentPage: 1,
          ),
        ],
      );
    });

    group('Page Navigation', () {
      blocTest<PdfViewerBloc, PdfViewerState>(
        'GoToPage updates currentPage when within range',
        seed: () => const PdfViewerState(
          status: PdfViewerStatus.loaded,
          totalPages: 10,
          currentPage: 1,
        ),
        build: () => bloc,
        act: (bloc) => bloc.add(const GoToPage(5)),
        expect: () => [
          isA<PdfViewerState>().having((s) => s.currentPage, 'current page', 5),
        ],
      );

      blocTest<PdfViewerBloc, PdfViewerState>(
        'GoToPage ignores update when page is out of range',
        seed: () => const PdfViewerState(
          status: PdfViewerStatus.loaded,
          totalPages: 10,
          currentPage: 1,
        ),
        build: () => bloc,
        act: (bloc) => bloc.add(const GoToPage(15)),
        expect: () => [],
      );

      blocTest<PdfViewerBloc, PdfViewerState>(
        'NextPage increments currentPage if not on last page',
        seed: () => const PdfViewerState(
          status: PdfViewerStatus.loaded,
          totalPages: 5,
          currentPage: 2,
        ),
        build: () => bloc,
        act: (bloc) => bloc.add(const NextPage()),
        expect: () => [
          isA<PdfViewerState>().having((s) => s.currentPage, 'current page', 3),
        ],
      );

      blocTest<PdfViewerBloc, PdfViewerState>(
        'NextPage does nothing if on last page',
        seed: () => const PdfViewerState(
          status: PdfViewerStatus.loaded,
          totalPages: 5,
          currentPage: 5,
        ),
        build: () => bloc,
        act: (bloc) => bloc.add(const NextPage()),
        expect: () => [],
      );

      blocTest<PdfViewerBloc, PdfViewerState>(
        'PreviousPage decrements currentPage if not on first page',
        seed: () => const PdfViewerState(
          status: PdfViewerStatus.loaded,
          totalPages: 5,
          currentPage: 3,
        ),
        build: () => bloc,
        act: (bloc) => bloc.add(const PreviousPage()),
        expect: () => [
          isA<PdfViewerState>().having((s) => s.currentPage, 'current page', 2),
        ],
      );

      blocTest<PdfViewerBloc, PdfViewerState>(
        'PreviousPage does nothing if on first page',
        seed: () => const PdfViewerState(
          status: PdfViewerStatus.loaded,
          totalPages: 5,
          currentPage: 1,
        ),
        build: () => bloc,
        act: (bloc) => bloc.add(const PreviousPage()),
        expect: () => [],
      );
    });

    group('Zoom Settings', () {
      blocTest<PdfViewerBloc, PdfViewerState>(
        'SetZoom updates zoom level within valid bounds',
        build: () => bloc,
        act: (bloc) => bloc.add(const SetZoom(1.5)),
        expect: () => [
          isA<PdfViewerState>().having((s) => s.zoom, 'zoom level', 1.5),
        ],
      );

      blocTest<PdfViewerBloc, PdfViewerState>(
        'SetZoom clamps zoom level to max range',
        build: () => bloc,
        act: (bloc) => bloc.add(const SetZoom(10.0)),
        expect: () => [
          isA<PdfViewerState>()
              .having((s) => s.zoom, 'clamped zoom level', 5.0),
        ],
      );

      blocTest<PdfViewerBloc, PdfViewerState>(
        'SetZoom clamps zoom level to min range',
        build: () => bloc,
        act: (bloc) => bloc.add(const SetZoom(0.1)),
        expect: () => [
          isA<PdfViewerState>()
              .having((s) => s.zoom, 'clamped zoom level', 0.25),
        ],
      );
    });

    group('Thumbnails and Search', () {
      blocTest<PdfViewerBloc, PdfViewerState>(
        'ToggleThumbnails flips showThumbnails status',
        build: () => bloc,
        act: (bloc) => bloc.add(const ToggleThumbnails()),
        expect: () => [
          isA<PdfViewerState>()
              .having((s) => s.showThumbnails, 'show thumbnails', true),
        ],
      );

      blocTest<PdfViewerBloc, PdfViewerState>(
        'SearchInPdf updates query',
        build: () => bloc,
        act: (bloc) => bloc.add(const SearchInPdf('Flutter')),
        expect: () => [
          isA<PdfViewerState>()
              .having((s) => s.searchQuery, 'search query', 'Flutter'),
        ],
      );
    });

    group('Annotations', () {
      const annotation = PdfAnnotation(
        id: 'ann-1',
        page: 1,
        type: 'highlight',
        x: 10,
        y: 10,
        width: 100,
        height: 20,
      );

      blocTest<PdfViewerBloc, PdfViewerState>(
        'AddAnnotation appends annotation to state',
        build: () => bloc,
        act: (bloc) => bloc.add(const AddAnnotation(annotation)),
        expect: () => [
          isA<PdfViewerState>()
              .having((s) => s.annotations.first, 'annotation', annotation),
        ],
      );

      blocTest<PdfViewerBloc, PdfViewerState>(
        'RemoveAnnotation removes targeted annotation',
        seed: () => const PdfViewerState(
          status: PdfViewerStatus.loaded,
          annotations: [annotation],
        ),
        build: () => bloc,
        act: (bloc) => bloc.add(const RemoveAnnotation('ann-1')),
        expect: () => [
          isA<PdfViewerState>()
              .having((s) => s.annotations, 'empty annotations list', isEmpty),
        ],
      );
    });

    group('Rotations', () {
      blocTest<PdfViewerBloc, PdfViewerState>(
        'RotatePage updates orientation degrees for targeted page',
        build: () => bloc,
        act: (bloc) => bloc.add(const RotatePage(1, 90)),
        expect: () => [
          isA<PdfViewerState>()
              .having((s) => s.pageRotations[1], 'page 1 rotation', 90),
        ],
      );

      blocTest<PdfViewerBloc, PdfViewerState>(
        'RotatePage accumulates rotation degrees correctly modulo 360',
        seed: () => const PdfViewerState(
          pageRotations: {1: 270},
        ),
        build: () => bloc,
        act: (bloc) => bloc.add(const RotatePage(1, 180)),
        expect: () => [
          isA<PdfViewerState>().having(
              (s) => s.pageRotations[1], 'page 1 rotation modulo 360', 90),
        ],
      );
    });
  });
}
