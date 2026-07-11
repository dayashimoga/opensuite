import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fileutility_storage/fileutility_storage.dart';
import 'package:opensuite/features/text_editor/bloc/text_editor_bloc.dart';

class MockFileStorageService extends Mock implements FileStorageService {}

void main() {
  late MockFileStorageService mockStorage;
  late TextEditorBloc bloc;

  setUp(() {
    mockStorage = MockFileStorageService();
    bloc = TextEditorBloc(fileStorageService: mockStorage);
  });

  tearDown(() {
    bloc.close();
  });

  group('TextEditorBloc', () {
    test('initial state is correct', () {
      expect(bloc.state.status, TextEditorStatus.initial);
      expect(bloc.state.documentId, isNull);
      expect(bloc.state.title, 'Untitled');
      expect(bloc.state.content, '');
      expect(bloc.state.fileType, 'text');
      expect(bloc.state.isModified, false);
      expect(bloc.state.showPreview, false);
      expect(bloc.state.showFindReplace, false);
      expect(bloc.state.findQuery, '');
      expect(bloc.state.findMatches, 0);
    });

    group('LoadDocument', () {
      blocTest<TextEditorBloc, TextEditorState>(
        'emits loaded state with documentId',
        build: () => bloc,
        act: (bloc) => bloc.add(const LoadDocument('doc-1')),
        expect: () => [
          const TextEditorState(status: TextEditorStatus.loading),
          const TextEditorState(
            status: TextEditorStatus.loaded,
            documentId: 'doc-1',
          ),
        ],
      );
    });

    group('CreateNewDocument', () {
      blocTest<TextEditorBloc, TextEditorState>(
        'emits loaded state with initialized document details',
        build: () => bloc,
        act: (bloc) => bloc
            .add(const CreateNewDocument(title: 'Notes', fileType: 'markdown')),
        expect: () => [
          isA<TextEditorState>()
              .having((s) => s.status, 'status', TextEditorStatus.loaded)
              .having((s) => s.documentId, 'document id', isNotNull)
              .having((s) => s.title, 'title', 'Notes')
              .having((s) => s.fileType, 'file type', 'markdown')
              .having((s) => s.content, 'content', ''),
        ],
      );
    });

    group('Content updates', () {
      blocTest<TextEditorBloc, TextEditorState>(
        'UpdateDocumentContent updates text, counts, and isModified flag',
        build: () => bloc,
        act: (bloc) =>
            bloc.add(const UpdateDocumentContent('Hello Flutter development!')),
        expect: () => [
          isA<TextEditorState>()
              .having((s) => s.content, 'content text',
                  'Hello Flutter development!')
              .having((s) => s.wordCount, 'word count', 3)
              .having((s) => s.charCount, 'char count', 26)
              .having((s) => s.isModified, 'modified flag', true),
        ],
      );

      blocTest<TextEditorBloc, TextEditorState>(
        'UpdateDocumentTitle updates title name and modified state',
        build: () => bloc,
        act: (bloc) => bloc.add(const UpdateDocumentTitle('Refined Pitch')),
        expect: () => [
          isA<TextEditorState>()
              .having((s) => s.title, 'title', 'Refined Pitch')
              .having((s) => s.isModified, 'modified flag', true),
        ],
      );
    });

    group('SaveDocument', () {
      blocTest<TextEditorBloc, TextEditorState>(
        'SaveDocument triggers storage save and resets isModified on success',
        seed: () => const TextEditorState(
          status: TextEditorStatus.loaded,
          title: 'Notes',
          content: 'Important content',
          fileType: 'text',
          isModified: true,
        ),
        build: () {
          when(() => mockStorage.saveToAppStorage(
                'Notes.txt',
                'Important content',
                subdirectory: 'documents',
              )).thenAnswer((_) async => 'app-path/Notes.txt');
          return bloc;
        },
        act: (bloc) => bloc.add(const SaveDocument()),
        expect: () => [
          isA<TextEditorState>()
              .having((s) => s.status, 'status', TextEditorStatus.saving),
          isA<TextEditorState>()
              .having((s) => s.status, 'status', TextEditorStatus.loaded)
              .having((s) => s.isModified, 'modified flag', false)
              .having((s) => s.lastSavedAt, 'saved timestamp', isNotNull),
        ],
      );
    });

    group('Search and replace', () {
      blocTest<TextEditorBloc, TextEditorState>(
        'TogglePreview swaps showPreview flag',
        build: () => bloc,
        act: (bloc) => bloc.add(const TogglePreview()),
        expect: () => [
          isA<TextEditorState>()
              .having((s) => s.showPreview, 'show preview', true),
        ],
      );

      blocTest<TextEditorBloc, TextEditorState>(
        'ToggleFindReplace swaps find/replace bar view state',
        build: () => bloc,
        act: (bloc) => bloc.add(const ToggleFindReplace()),
        expect: () => [
          isA<TextEditorState>()
              .having((s) => s.showFindReplace, 'show find replace', true),
        ],
      );

      blocTest<TextEditorBloc, TextEditorState>(
        'FindInDocument performs matches query count',
        seed: () => const TextEditorState(
          content: 'Flutter is awesome. I love Flutter!',
        ),
        build: () => bloc,
        act: (bloc) => bloc.add(const FindInDocument('Flutter')),
        expect: () => [
          isA<TextEditorState>()
              .having((s) => s.findQuery, 'query', 'Flutter')
              .having((s) => s.findMatches, 'matches count', 2),
        ],
      );

      blocTest<TextEditorBloc, TextEditorState>(
        'ReplaceInDocument replaces first match when replaceAll is false',
        seed: () => const TextEditorState(
          content: 'one two one',
        ),
        build: () => bloc,
        act: (bloc) => bloc.add(const ReplaceInDocument(
            find: 'one', replace: 'three', replaceAll: false)),
        expect: () => [
          isA<TextEditorState>()
              .having((s) => s.content, 'replaced content', 'three two one'),
        ],
      );

      blocTest<TextEditorBloc, TextEditorState>(
        'ReplaceInDocument replaces all matches when replaceAll is true',
        seed: () => const TextEditorState(
          content: 'one two one',
        ),
        build: () => bloc,
        act: (bloc) => bloc.add(const ReplaceInDocument(
            find: 'one', replace: 'three', replaceAll: true)),
        expect: () => [
          isA<TextEditorState>()
              .having((s) => s.content, 'replaced content', 'three two three'),
        ],
      );
    });
  });
}
