import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fileutility_storage/fileutility_storage.dart';
import 'package:opensuite/features/file_manager/bloc/file_manager_bloc.dart';

class MockRecentFileDao extends Mock implements RecentFileDao {}

void main() {
  late MockRecentFileDao mockDao;
  late FileManagerBloc bloc;

  final testFile = RecentFileEntity(
    id: 'file-1',
    fileName: 'report.pdf',
    filePath: '/docs/report.pdf',
    fileType: 'pdf',
    sizeBytes: 1024,
    lastOpenedAt: DateTime(2026, 1, 1),
    createdAt: DateTime(2026, 1, 1),
  );

  final testFile2 = RecentFileEntity(
    id: 'file-2',
    fileName: 'photo.jpg',
    filePath: '/imgs/photo.jpg',
    fileType: 'image',
    isFavorite: true,
    lastOpenedAt: DateTime(2026, 1, 2),
    createdAt: DateTime(2026, 1, 2),
  );

  setUp(() {
    mockDao = MockRecentFileDao();
    bloc = FileManagerBloc(recentFileDao: mockDao);
  });

  tearDown(() => bloc.close());

  group('FileManagerBloc', () {
    test('initial state is correct', () {
      expect(bloc.state.status, FileManagerStatus.initial);
      expect(bloc.state.files, isEmpty);
      expect(bloc.state.viewMode, FileViewMode.list);
      expect(bloc.state.activeTab, FileTab.recent);
    });

    group('LoadRecentFiles', () {
      blocTest<FileManagerBloc, FileManagerState>(
        'emits [loading, loaded] with files on success',
        build: () {
          when(() => mockDao.getAll())
              .thenAnswer((_) async => [testFile, testFile2]);
          return bloc;
        },
        act: (bloc) => bloc.add(const LoadRecentFiles()),
        expect: () => [
          const FileManagerState(
            status: FileManagerStatus.loading,
            activeTab: FileTab.recent,
          ),
          FileManagerState(
            status: FileManagerStatus.loaded,
            activeTab: FileTab.recent,
            files: [testFile, testFile2],
          ),
        ],
      );

      blocTest<FileManagerBloc, FileManagerState>(
        'emits [loading, error] on failure',
        build: () {
          when(() => mockDao.getAll()).thenThrow(Exception('DB error'));
          return bloc;
        },
        act: (bloc) => bloc.add(const LoadRecentFiles()),
        expect: () => [
          const FileManagerState(
            status: FileManagerStatus.loading,
            activeTab: FileTab.recent,
          ),
          isA<FileManagerState>()
              .having((s) => s.status, 'status', FileManagerStatus.error),
        ],
      );
    });

    group('LoadFavoriteFiles', () {
      blocTest<FileManagerBloc, FileManagerState>(
        'emits [loading, loaded] with favorites',
        build: () {
          when(() => mockDao.getFavorites())
              .thenAnswer((_) async => [testFile2]);
          return bloc;
        },
        act: (bloc) => bloc.add(const LoadFavoriteFiles()),
        expect: () => [
          const FileManagerState(
            status: FileManagerStatus.loading,
            activeTab: FileTab.favorites,
          ),
          FileManagerState(
            status: FileManagerStatus.loaded,
            activeTab: FileTab.favorites,
            files: [testFile2],
          ),
        ],
      );
    });

    group('SearchFiles', () {
      blocTest<FileManagerBloc, FileManagerState>(
        'emits search query and loaded state',
        build: () {
          when(() => mockDao.search('report'))
              .thenAnswer((_) async => [testFile]);
          return bloc;
        },
        act: (bloc) => bloc.add(const SearchFiles('report')),
        expect: () => [
          const FileManagerState(searchQuery: 'report'),
          FileManagerState(
            status: FileManagerStatus.loaded,
            searchQuery: 'report',
            files: [testFile],
          ),
        ],
      );
    });

    group('ChangeViewMode', () {
      blocTest<FileManagerBloc, FileManagerState>(
        'emits new view mode',
        build: () => bloc,
        act: (bloc) => bloc.add(const ChangeViewMode(FileViewMode.grid)),
        expect: () => [
          const FileManagerState(viewMode: FileViewMode.grid),
        ],
      );
    });

    group('DeleteRecentFile', () {
      blocTest<FileManagerBloc, FileManagerState>(
        'calls dao.delete and reloads',
        build: () {
          when(() => mockDao.delete(any())).thenAnswer((_) async => 1);
          when(() => mockDao.getAll()).thenAnswer((_) async => []);
          return bloc;
        },
        act: (bloc) => bloc.add(const DeleteRecentFile('file-1')),
        verify: (_) {
          verify(() => mockDao.delete('file-1')).called(1);
        },
      );
    });

    group('ClearRecentFiles', () {
      blocTest<FileManagerBloc, FileManagerState>(
        'calls dao.clearNonFavorites and reloads',
        build: () {
          when(() => mockDao.clearNonFavorites()).thenAnswer((_) async {});
          when(() => mockDao.getAll()).thenAnswer((_) async => [testFile2]);
          return bloc;
        },
        act: (bloc) => bloc.add(const ClearRecentFiles()),
        verify: (_) {
          verify(() => mockDao.clearNonFavorites()).called(1);
        },
      );
    });
  });
}
