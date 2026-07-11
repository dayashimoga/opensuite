import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fileutility_storage/fileutility_storage.dart';
import 'package:opensuite/features/document_editor/bloc/document_editor_bloc.dart';

class MockDocumentDao extends Mock implements DocumentDao {}

void main() {
  late MockDocumentDao mockDao;
  late DocumentEditorBloc bloc;

  final testDoc = DocumentEntity(
    id: 'doc-1',
    title: 'Test Document',
    content: '[]',
    plainText: 'Hello world',
    format: 'rich',
    wordCount: 2,
    characterCount: 11,
    createdAt: DateTime(2026, 1, 1),
    modifiedAt: DateTime(2026, 1, 1),
  );

  final testDoc2 = DocumentEntity(
    id: 'doc-2',
    title: 'Report Q4',
    content: '[{"insert":"Report"}]',
    plainText: 'Report',
    format: 'rich',
    wordCount: 1,
    characterCount: 6,
    isFavorite: true,
    createdAt: DateTime(2026, 1, 2),
    modifiedAt: DateTime(2026, 1, 2),
  );

  setUpAll(() {
    registerFallbackValue(DocumentEntity(
      id: '',
      title: '',
      content: '[]',
      createdAt: DateTime(2026),
      modifiedAt: DateTime(2026),
    ));
  });

  setUp(() {
    mockDao = MockDocumentDao();
    bloc = DocumentEditorBloc(documentDao: mockDao);
  });

  tearDown(() {
    bloc.close();
  });

  group('DocumentEditorBloc', () {
    test('initial state is correct', () {
      expect(bloc.state.status, DocumentEditorStatus.initial);
      expect(bloc.state.documents, isEmpty);
      expect(bloc.state.currentDocument, isNull);
      expect(bloc.state.hasUnsavedChanges, false);
      expect(bloc.state.showToolbar, true);
    });

    group('LoadDocuments', () {
      blocTest<DocumentEditorBloc, DocumentEditorState>(
        'emits [loading, loaded] with documents',
        build: () {
          when(() => mockDao.getAllDocuments())
              .thenAnswer((_) async => [testDoc, testDoc2]);
          return bloc;
        },
        act: (bloc) => bloc.add(const LoadDocuments()),
        expect: () => [
          const DocumentEditorState(status: DocumentEditorStatus.loading),
          DocumentEditorState(
            status: DocumentEditorStatus.loaded,
            documents: [testDoc, testDoc2],
          ),
        ],
      );

      blocTest<DocumentEditorBloc, DocumentEditorState>(
        'emits error on failure',
        build: () {
          when(() => mockDao.getAllDocuments())
              .thenThrow(Exception('DB error'));
          return bloc;
        },
        act: (bloc) => bloc.add(const LoadDocuments()),
        expect: () => [
          const DocumentEditorState(status: DocumentEditorStatus.loading),
          isA<DocumentEditorState>()
              .having((s) => s.status, 'status', DocumentEditorStatus.error),
        ],
      );
    });

    group('SearchDocuments', () {
      blocTest<DocumentEditorBloc, DocumentEditorState>(
        'filters documents by query',
        build: () {
          when(() => mockDao.searchDocuments('Report'))
              .thenAnswer((_) async => [testDoc2]);
          return bloc;
        },
        act: (bloc) => bloc.add(const SearchDocuments('Report')),
        wait: const Duration(milliseconds: 100),
        expect: () => [
          isA<DocumentEditorState>()
              .having((s) => s.searchQuery, 'query', 'Report'),
          isA<DocumentEditorState>()
              .having((s) => s.documents, 'docs', [testDoc2]),
        ],
      );

      blocTest<DocumentEditorBloc, DocumentEditorState>(
        'empty query loads all documents',
        build: () {
          when(() => mockDao.getAllDocuments())
              .thenAnswer((_) async => [testDoc, testDoc2]);
          return bloc;
        },
        act: (bloc) => bloc.add(const SearchDocuments('')),
        wait: const Duration(milliseconds: 100),
        expect: () => [
          isA<DocumentEditorState>().having((s) => s.searchQuery, 'query', ''),
          isA<DocumentEditorState>()
              .having((s) => s.documents.length, 'count', 2),
        ],
      );
    });

    group('CreateDocument', () {
      blocTest<DocumentEditorBloc, DocumentEditorState>(
        'creates with default title and empty content',
        build: () {
          when(() => mockDao.insertDocument(any())).thenAnswer((_) async {});
          return bloc;
        },
        act: (bloc) => bloc.add(const CreateDocument()),
        expect: () => [
          isA<DocumentEditorState>()
              .having((s) => s.status, 'status', DocumentEditorStatus.editing)
              .having(
                  (s) => s.currentDocument?.title, 'title', 'Untitled Document')
              .having((s) => s.hasUnsavedChanges, 'unsaved', false)
              .having((s) => s.wordCount, 'words', 0),
        ],
      );
    });

    group('OpenDocument', () {
      blocTest<DocumentEditorBloc, DocumentEditorState>(
        'loads document for editing',
        build: () {
          when(() => mockDao.getDocument('doc-1'))
              .thenAnswer((_) async => testDoc);
          return bloc;
        },
        act: (bloc) => bloc.add(const OpenDocument('doc-1')),
        expect: () => [
          const DocumentEditorState(status: DocumentEditorStatus.loading),
          isA<DocumentEditorState>()
              .having((s) => s.status, 'status', DocumentEditorStatus.editing)
              .having((s) => s.currentDocument?.id, 'id', 'doc-1')
              .having((s) => s.wordCount, 'words', 2),
        ],
      );

      blocTest<DocumentEditorBloc, DocumentEditorState>(
        'emits error when not found',
        build: () {
          when(() => mockDao.getDocument('missing'))
              .thenAnswer((_) async => null);
          return bloc;
        },
        act: (bloc) => bloc.add(const OpenDocument('missing')),
        expect: () => [
          const DocumentEditorState(status: DocumentEditorStatus.loading),
          isA<DocumentEditorState>()
              .having((s) => s.status, 'status', DocumentEditorStatus.error)
              .having((s) => s.errorMessage, 'msg', 'Document not found'),
        ],
      );
    });

    group('UpdateDocumentTitle', () {
      blocTest<DocumentEditorBloc, DocumentEditorState>(
        'updates title and marks unsaved',
        seed: () => DocumentEditorState(
          status: DocumentEditorStatus.editing,
          currentDocument: testDoc,
        ),
        build: () => bloc,
        act: (bloc) => bloc.add(const UpdateDocumentTitle('New Title')),
        expect: () => [
          isA<DocumentEditorState>()
              .having((s) => s.currentDocument?.title, 'title', 'New Title')
              .having((s) => s.hasUnsavedChanges, 'unsaved', true),
        ],
      );
    });

    group('UpdateDocumentContent', () {
      blocTest<DocumentEditorBloc, DocumentEditorState>(
        'updates content, counts, pushes undo stack',
        seed: () => DocumentEditorState(
          status: DocumentEditorStatus.editing,
          currentDocument: testDoc,
        ),
        build: () => bloc,
        act: (bloc) => bloc.add(const UpdateDocumentContent(
          content: '[{"insert":"New content"}]',
          plainText: 'New content here',
        )),
        expect: () => [
          isA<DocumentEditorState>()
              .having((s) => s.hasUnsavedChanges, 'unsaved', true)
              .having((s) => s.wordCount, 'words', 3)
              .having((s) => s.characterCount, 'chars', 16)
              .having((s) => s.undoStack.length, 'undo', 1)
              .having((s) => s.redoStack, 'redo', isEmpty),
        ],
      );
    });

    group('SaveDocument', () {
      blocTest<DocumentEditorBloc, DocumentEditorState>(
        'emits saving → saved → editing cycle',
        seed: () => DocumentEditorState(
          status: DocumentEditorStatus.editing,
          currentDocument: testDoc,
          hasUnsavedChanges: true,
        ),
        build: () {
          when(() => mockDao.updateDocument(any())).thenAnswer((_) async {});
          return bloc;
        },
        act: (bloc) => bloc.add(const SaveDocument()),
        wait: const Duration(seconds: 1),
        expect: () => [
          isA<DocumentEditorState>()
              .having((s) => s.status, 'status', DocumentEditorStatus.saving),
          isA<DocumentEditorState>()
              .having((s) => s.status, 'status', DocumentEditorStatus.saved)
              .having((s) => s.hasUnsavedChanges, 'unsaved', false),
          isA<DocumentEditorState>()
              .having((s) => s.status, 'status', DocumentEditorStatus.editing),
        ],
      );
    });

    group('DeleteDocument', () {
      blocTest<DocumentEditorBloc, DocumentEditorState>(
        'removes document from list',
        seed: () => DocumentEditorState(
          status: DocumentEditorStatus.loaded,
          documents: [testDoc, testDoc2],
        ),
        build: () {
          when(() => mockDao.deleteDocument('doc-1')).thenAnswer((_) async {});
          return bloc;
        },
        act: (bloc) => bloc.add(const DeleteDocument('doc-1')),
        expect: () => [
          isA<DocumentEditorState>()
              .having((s) => s.documents.length, 'count', 1)
              .having((s) => s.documents.first.id, 'id', 'doc-2'),
        ],
      );
    });

    group('ApplyFormatting', () {
      blocTest<DocumentEditorBloc, DocumentEditorState>(
        'toggles bold in activeFormats',
        seed: () => const DocumentEditorState(
          status: DocumentEditorStatus.editing,
        ),
        build: () => bloc,
        act: (bloc) => bloc.add(const ApplyFormatting('bold')),
        expect: () => [
          isA<DocumentEditorState>()
              .having((s) => s.activeFormats.contains('bold'), 'bold', true),
        ],
      );
    });

    group('ToggleToolbar', () {
      blocTest<DocumentEditorBloc, DocumentEditorState>(
        'toggles toolbar visibility',
        seed: () => const DocumentEditorState(
          status: DocumentEditorStatus.editing,
          showToolbar: true,
        ),
        build: () => bloc,
        act: (bloc) => bloc.add(const ToggleToolbar()),
        expect: () => [
          isA<DocumentEditorState>()
              .having((s) => s.showToolbar, 'toolbar', false),
        ],
      );
    });

    group('Undo/Redo', () {
      blocTest<DocumentEditorBloc, DocumentEditorState>(
        'UndoChange restores previous content',
        seed: () => DocumentEditorState(
          status: DocumentEditorStatus.editing,
          currentDocument: testDoc.copyWith(content: 'new'),
          undoStack: const ['old'],
        ),
        build: () => bloc,
        act: (bloc) => bloc.add(const UndoChange()),
        expect: () => [
          isA<DocumentEditorState>()
              .having((s) => s.currentDocument?.content, 'content', 'old')
              .having((s) => s.undoStack, 'undo', isEmpty)
              .having((s) => s.redoStack.length, 'redo', 1),
        ],
      );

      blocTest<DocumentEditorBloc, DocumentEditorState>(
        'UndoChange does nothing when stack empty',
        seed: () => DocumentEditorState(
          status: DocumentEditorStatus.editing,
          currentDocument: testDoc,
          undoStack: const [],
        ),
        build: () => bloc,
        act: (bloc) => bloc.add(const UndoChange()),
        expect: () => [],
      );
    });
  });
}
