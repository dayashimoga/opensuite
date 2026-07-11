import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fileutility_storage/fileutility_storage.dart';
import 'package:opensuite/features/notes/bloc/notes_bloc.dart';

class MockNoteDao extends Mock implements NoteDao {}

void main() {
  late MockNoteDao mockNoteDao;
  late NotesBloc bloc;

  final testNote = NoteEntity(
    id: 'test-id-1',
    title: 'Test Note',
    content: 'Test content',
    contentType: NoteContentType.plain,
    createdAt: DateTime(2026, 1, 1),
    modifiedAt: DateTime(2026, 1, 1),
  );

  final testNote2 = NoteEntity(
    id: 'test-id-2',
    title: 'Second Note',
    content: 'More content',
    contentType: NoteContentType.markdown,
    isPinned: true,
    createdAt: DateTime(2026, 1, 2),
    modifiedAt: DateTime(2026, 1, 2),
  );

  setUpAll(() {
    registerFallbackValue(NoteContentType.plain);
    registerFallbackValue(NoteEntity(
      id: '',
      title: '',
      content: '',
      contentType: NoteContentType.plain,
      createdAt: DateTime(2026),
      modifiedAt: DateTime(2026),
    ));
  });

  setUp(() {
    mockNoteDao = MockNoteDao();
    bloc = NotesBloc(noteDao: mockNoteDao);
  });

  tearDown(() {
    bloc.close();
  });

  group('NotesBloc', () {
    test('initial state is correct', () {
      expect(bloc.state, const NotesState());
      expect(bloc.state.status, NotesStatus.initial);
      expect(bloc.state.notes, isEmpty);
    });

    group('LoadNotes', () {
      blocTest<NotesBloc, NotesState>(
        'emits [loading, loaded] with notes on success',
        build: () {
          when(() => mockNoteDao.getAll())
              .thenAnswer((_) async => [testNote, testNote2]);
          return bloc;
        },
        act: (bloc) => bloc.add(const LoadNotes()),
        expect: () => [
          const NotesState(status: NotesStatus.loading),
          NotesState(
            status: NotesStatus.loaded,
            notes: [testNote, testNote2],
          ),
        ],
        verify: (_) {
          verify(() => mockNoteDao.getAll()).called(1);
        },
      );

      blocTest<NotesBloc, NotesState>(
        'emits [loading, error] on failure',
        build: () {
          when(() => mockNoteDao.getAll()).thenThrow(Exception('DB error'));
          return bloc;
        },
        act: (bloc) => bloc.add(const LoadNotes()),
        expect: () => [
          const NotesState(status: NotesStatus.loading),
          isA<NotesState>()
              .having((s) => s.status, 'status', NotesStatus.error)
              .having(
                  (s) => s.errorMessage, 'errorMessage', contains('DB error')),
        ],
      );
    });

    group('SearchNotes', () {
      blocTest<NotesBloc, NotesState>(
        'emits [searchQuery, loaded] with filtered notes',
        build: () {
          when(() => mockNoteDao.search('test'))
              .thenAnswer((_) async => [testNote]);
          return bloc;
        },
        act: (bloc) => bloc.add(const SearchNotes('test')),
        expect: () => [
          const NotesState(searchQuery: 'test'),
          NotesState(
            status: NotesStatus.loaded,
            searchQuery: 'test',
            notes: [testNote],
          ),
        ],
      );
    });

    group('CreateNote', () {
      blocTest<NotesBloc, NotesState>(
        'calls dao.create and then reloads notes',
        build: () {
          when(() => mockNoteDao.create(
                title: any(named: 'title'),
                content: any(named: 'content'),
                contentType: any(named: 'contentType'),
              )).thenAnswer((_) async => testNote);
          when(() => mockNoteDao.getAll()).thenAnswer((_) async => [testNote]);
          return bloc;
        },
        act: (bloc) => bloc.add(const CreateNote(title: 'New Note')),
        verify: (_) {
          verify(() => mockNoteDao.create(
                title: 'New Note',
                content: '',
                contentType: NoteContentType.plain,
              )).called(1);
        },
      );
    });

    group('UpdateNote', () {
      blocTest<NotesBloc, NotesState>(
        'calls dao.update and then reloads notes',
        build: () {
          when(() => mockNoteDao.update(any())).thenAnswer((_) async => 1);
          when(() => mockNoteDao.getAll()).thenAnswer((_) async => [testNote]);
          return bloc;
        },
        act: (bloc) => bloc.add(UpdateNote(testNote)),
        verify: (_) {
          verify(() => mockNoteDao.update(testNote)).called(1);
        },
      );
    });

    group('DeleteNote', () {
      blocTest<NotesBloc, NotesState>(
        'calls dao.delete and then reloads notes',
        build: () {
          when(() => mockNoteDao.delete(any())).thenAnswer((_) async => 1);
          when(() => mockNoteDao.getAll()).thenAnswer((_) async => []);
          return bloc;
        },
        act: (bloc) => bloc.add(const DeleteNote('test-id-1')),
        verify: (_) {
          verify(() => mockNoteDao.delete('test-id-1')).called(1);
        },
      );
    });

    group('TogglePinNote', () {
      blocTest<NotesBloc, NotesState>(
        'calls dao.togglePin and reloads',
        build: () {
          when(() => mockNoteDao.togglePin(any())).thenAnswer((_) async {});
          when(() => mockNoteDao.getAll()).thenAnswer((_) async => [testNote2]);
          return bloc;
        },
        act: (bloc) => bloc.add(const TogglePinNote('test-id-2')),
        verify: (_) {
          verify(() => mockNoteDao.togglePin('test-id-2')).called(1);
        },
      );
    });

    group('ToggleFavoriteNote', () {
      blocTest<NotesBloc, NotesState>(
        'calls dao.toggleFavorite and reloads',
        build: () {
          when(() => mockNoteDao.toggleFavorite(any()))
              .thenAnswer((_) async {});
          when(() => mockNoteDao.getAll()).thenAnswer((_) async => [testNote]);
          return bloc;
        },
        act: (bloc) => bloc.add(const ToggleFavoriteNote('test-id-1')),
        verify: (_) {
          verify(() => mockNoteDao.toggleFavorite('test-id-1')).called(1);
        },
      );
    });

    group('NotesState', () {
      test('pinnedNotes returns only pinned notes', () {
        final state = NotesState(notes: [testNote, testNote2]);
        expect(state.pinnedNotes, [testNote2]);
      });

      test('unpinnedNotes returns only unpinned notes', () {
        final state = NotesState(notes: [testNote, testNote2]);
        expect(state.unpinnedNotes, [testNote]);
      });

      test('copyWith preserves values when not overridden', () {
        final state = NotesState(
          status: NotesStatus.loaded,
          notes: [testNote],
          searchQuery: 'test',
        );
        final copy = state.copyWith();
        expect(copy.status, NotesStatus.loaded);
        expect(copy.notes, [testNote]);
        expect(copy.searchQuery, 'test');
      });
    });
  });
}
