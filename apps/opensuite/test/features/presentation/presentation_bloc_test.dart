import 'dart:convert';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fileutility_core/fileutility_core.dart';
import 'package:fileutility_storage/fileutility_storage.dart';
import 'package:opensuite/features/presentation/bloc/presentation_bloc.dart';

class MockPresentationDao extends Mock implements PresentationDao {}

void main() {
  late MockPresentationDao mockDao;
  late PresentationBloc bloc;

  final testEntity = PresentationEntity(
    id: 'pres-1',
    title: 'Test Presentation',
    content: jsonEncode([
      {
        'id': '1',
        'backgroundColor': '#1E3A5F',
        'elements': [
          {
            'id': 'title_1',
            'type': 'text',
            'x': 0.1,
            'y': 0.3,
            'width': 0.8,
            'height': 0.15,
            'content': 'Test Presentation',
            'fontSize': 44.0,
            'fontWeight': 'bold',
            'textColor': '#FFFFFF',
            'textAlign': 'center',
          }
        ],
        'speakerNotes': '',
        'transition': 'none',
        'layout': 'blank',
      }
    ]),
    slideCount: 1,
    createdAt: DateTime(2026, 1, 1),
    modifiedAt: DateTime(2026, 1, 1),
  );

  final testEntity2 = PresentationEntity(
    id: 'pres-2',
    title: 'Pitch Deck',
    content: jsonEncode([
      {
        'id': '1',
        'backgroundColor': '#FFFFFF',
        'elements': [],
        'speakerNotes': '',
        'transition': 'none',
        'layout': 'blank',
      }
    ]),
    slideCount: 1,
    isFavorite: true,
    createdAt: DateTime(2026, 1, 2),
    modifiedAt: DateTime(2026, 1, 2),
  );

  setUpAll(() {
    registerFallbackValue(PresentationEntity(
      id: '',
      title: '',
      content: '[]',
      createdAt: DateTime(2026),
      modifiedAt: DateTime(2026),
    ));
  });

  setUp(() {
    mockDao = MockPresentationDao();
    bloc = PresentationBloc(presentationDao: mockDao);
  });

  tearDown(() {
    bloc.close();
  });

  group('PresentationBloc', () {
    test('initial state is correct', () {
      expect(bloc.state.status, PresentationStatus.initial);
      expect(bloc.state.presentations, isEmpty);
      expect(bloc.state.slides, isEmpty);
      expect(bloc.state.activeSlideIndex, 0);
      expect(bloc.state.selectedElementId, isNull);
      expect(bloc.state.isPresentationMode, false);
      expect(bloc.state.hasUnsavedChanges, false);
    });

    group('LoadPresentations', () {
      blocTest<PresentationBloc, PresentationState>(
        'emits [loading, loaded] with presentations',
        build: () {
          when(() => mockDao.getAllPresentations())
              .thenAnswer((_) async => [testEntity, testEntity2]);
          return bloc;
        },
        act: (bloc) => bloc.add(const LoadPresentations()),
        expect: () => [
          const PresentationState(status: PresentationStatus.loading),
          PresentationState(
            status: PresentationStatus.loaded,
            presentations: [testEntity, testEntity2],
          ),
        ],
      );

      blocTest<PresentationBloc, PresentationState>(
        'emits error status on failure',
        build: () {
          when(() => mockDao.getAllPresentations())
              .thenThrow(Exception('Database error'));
          return bloc;
        },
        act: (bloc) => bloc.add(const LoadPresentations()),
        expect: () => [
          const PresentationState(status: PresentationStatus.loading),
          isA<PresentationState>()
              .having((s) => s.status, 'status', PresentationStatus.error)
              .having((s) => s.errorMessage, 'error', isNotNull),
        ],
      );
    });

    group('CreatePresentation', () {
      blocTest<PresentationBloc, PresentationState>(
        'creates a new presentation with title slide',
        build: () {
          when(() => mockDao.insertPresentation(any()))
              .thenAnswer((_) async {});
          return bloc;
        },
        act: (bloc) => bloc.add(const CreatePresentation(title: 'Sales Pitch')),
        expect: () => [
          isA<PresentationState>()
              .having((s) => s.status, 'status', PresentationStatus.editing)
              .having((s) => s.slides.length, 'slides count', 1)
              .having(
                  (s) => s.slides.first.elements.length, 'elements count', 2)
              .having((s) => s.activeSlideIndex, 'active index', 0)
              .having(
                  (s) => s.currentPresentation?.title, 'title', 'Sales Pitch'),
        ],
      );
    });

    group('OpenPresentation', () {
      blocTest<PresentationBloc, PresentationState>(
        'opens and parses presentation',
        build: () {
          when(() => mockDao.getPresentation('pres-1'))
              .thenAnswer((_) async => testEntity);
          return bloc;
        },
        act: (bloc) => bloc.add(const OpenPresentation('pres-1')),
        expect: () => [
          const PresentationState(status: PresentationStatus.loading),
          isA<PresentationState>()
              .having((s) => s.status, 'status', PresentationStatus.editing)
              .having((s) => s.currentPresentation?.id, 'id', 'pres-1')
              .having((s) => s.slides.length, 'slides count', 1)
              .having((s) => s.slides.first.elements.first.content,
                  'title text', 'Test Presentation'),
        ],
      );

      blocTest<PresentationBloc, PresentationState>(
        'emits error when presentation not found',
        build: () {
          when(() => mockDao.getPresentation('missing'))
              .thenAnswer((_) async => null);
          return bloc;
        },
        act: (bloc) => bloc.add(const OpenPresentation('missing')),
        expect: () => [
          const PresentationState(status: PresentationStatus.loading),
          isA<PresentationState>()
              .having((s) => s.status, 'status', PresentationStatus.error)
              .having((s) => s.errorMessage, 'error', 'Not found'),
        ],
      );
    });

    group('Slide operations', () {
      final initialSlide =
          SlideData(id: '1', backgroundColor: '#FFFFFF', elements: const []);

      blocTest<PresentationBloc, PresentationState>(
        'SelectSlide updates active slide index',
        seed: () => PresentationState(
          status: PresentationStatus.editing,
          slides: [
            initialSlide,
            SlideData(id: '2', backgroundColor: '#000000')
          ],
        ),
        build: () => bloc,
        act: (bloc) => bloc.add(const SelectSlide(1)),
        expect: () => [
          isA<PresentationState>()
              .having((s) => s.activeSlideIndex, 'active index', 1),
        ],
      );

      blocTest<PresentationBloc, PresentationState>(
        'AddSlide inserts slide after active slide',
        seed: () => PresentationState(
          status: PresentationStatus.editing,
          slides: [initialSlide],
          activeSlideIndex: 0,
        ),
        build: () => bloc,
        act: (bloc) => bloc.add(const AddSlide()),
        expect: () => [
          isA<PresentationState>()
              .having((s) => s.slides.length, 'slides count', 2)
              .having((s) => s.activeSlideIndex, 'active index', 1)
              .having((s) => s.hasUnsavedChanges, 'has unsaved changes', true),
        ],
      );

      blocTest<PresentationBloc, PresentationState>(
        'DeleteSlide removes slide',
        seed: () => PresentationState(
          status: PresentationStatus.editing,
          slides: [
            initialSlide,
            SlideData(id: '2', backgroundColor: '#000000')
          ],
          activeSlideIndex: 1,
        ),
        build: () => bloc,
        act: (bloc) => bloc.add(const DeleteSlide(1)),
        expect: () => [
          isA<PresentationState>()
              .having((s) => s.slides.length, 'slides count', 1)
              .having((s) => s.activeSlideIndex, 'active index', 0)
              .having((s) => s.hasUnsavedChanges, 'has unsaved changes', true),
        ],
      );

      blocTest<PresentationBloc, PresentationState>(
        'DuplicateSlide duplicates active slide',
        seed: () => PresentationState(
          status: PresentationStatus.editing,
          slides: [initialSlide],
          activeSlideIndex: 0,
        ),
        build: () => bloc,
        act: (bloc) => bloc.add(const DuplicateSlide(0)),
        expect: () => [
          isA<PresentationState>()
              .having((s) => s.slides.length, 'slides count', 2)
              .having((s) => s.activeSlideIndex, 'active index', 1),
        ],
      );
    });

    group('Element operations', () {
      final initialSlide =
          SlideData(id: '1', backgroundColor: '#FFFFFF', elements: const []);
      final testElement = SlideElement(
          id: 'el-1',
          type: 'text',
          x: 0.1,
          y: 0.1,
          width: 0.2,
          height: 0.2,
          content: 'Text');

      blocTest<PresentationBloc, PresentationState>(
        'AddElement adds element to active slide',
        seed: () => PresentationState(
          status: PresentationStatus.editing,
          slides: [initialSlide],
          activeSlideIndex: 0,
        ),
        build: () => bloc,
        act: (bloc) => bloc.add(AddElement(testElement)),
        expect: () => [
          isA<PresentationState>()
              .having(
                  (s) => s.slides.first.elements.length, 'elements count', 1)
              .having((s) => s.hasUnsavedChanges, 'has unsaved changes', true),
        ],
      );

      blocTest<PresentationBloc, PresentationState>(
        'UpdateElement modifies existing element',
        seed: () => PresentationState(
          status: PresentationStatus.editing,
          slides: [
            initialSlide.copyWith(elements: [testElement])
          ],
          activeSlideIndex: 0,
        ),
        build: () => bloc,
        act: (bloc) => bloc.add(
            UpdateElement('el-1', testElement.copyWith(content: 'New Text'))),
        expect: () => [
          isA<PresentationState>().having(
              (s) => s.slides.first.elements.first.content,
              'updated text',
              'New Text'),
        ],
      );

      blocTest<PresentationBloc, PresentationState>(
        'DeleteElement removes element',
        seed: () => PresentationState(
          status: PresentationStatus.editing,
          slides: [
            initialSlide.copyWith(elements: [testElement])
          ],
          activeSlideIndex: 0,
          selectedElementId: 'el-1',
        ),
        build: () => bloc,
        act: (bloc) => bloc.add(const DeleteElement('el-1')),
        expect: () => [
          isA<PresentationState>()
              .having((s) => s.slides.first.elements, 'elements list', isEmpty)
              .having(
                  (s) => s.selectedElementId, 'selected element id', isNull),
        ],
      );

      blocTest<PresentationBloc, PresentationState>(
        'SelectElement updates selection',
        seed: () => PresentationState(
          status: PresentationStatus.editing,
          slides: [
            initialSlide.copyWith(elements: [testElement])
          ],
          activeSlideIndex: 0,
        ),
        build: () => bloc,
        act: (bloc) => bloc.add(const SelectElement('el-1')),
        expect: () => [
          isA<PresentationState>().having(
              (s) => s.selectedElementId, 'selected element id', 'el-1'),
        ],
      );
    });

    group('SavePresentation', () {
      blocTest<PresentationBloc, PresentationState>(
        'saves and transitions status',
        seed: () => PresentationState(
          status: PresentationStatus.editing,
          currentPresentation: testEntity,
          slides: [
            SlideData(id: '1', backgroundColor: '#FFFFFF', elements: const [])
          ],
          hasUnsavedChanges: true,
        ),
        build: () {
          when(() => mockDao.updatePresentation(any()))
              .thenAnswer((_) async {});
          return bloc;
        },
        act: (bloc) => bloc.add(const SavePresentation()),
        wait: const Duration(seconds: 1),
        expect: () => [
          isA<PresentationState>()
              .having((s) => s.status, 'status', PresentationStatus.saving),
          isA<PresentationState>()
              .having((s) => s.status, 'status', PresentationStatus.saved)
              .having((s) => s.hasUnsavedChanges, 'has unsaved changes', false),
          isA<PresentationState>()
              .having((s) => s.status, 'status', PresentationStatus.editing),
        ],
      );
    });
  });
}
