import 'dart:typed_data';

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
    content: '[{"insert":"Hello world\\n"}]',
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
    content: '[{"insert":"Report\\n"}]',
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
      content: '[{"insert":"\\n"}]',
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
      expect(bloc.state.showFindReplace, false);
      expect(bloc.state.exportedBytes, isNull);
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
        'creates with default title and empty Delta content',
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
              .having((s) => s.wordCount, 'words', 0)
              .having((s) => s.currentDocument?.content, 'content',
                  contains('insert')),
        ],
      );

      blocTest<DocumentEditorBloc, DocumentEditorState>(
        'creates with custom title',
        build: () {
          when(() => mockDao.insertDocument(any())).thenAnswer((_) async {});
          return bloc;
        },
        act: (bloc) =>
            bloc.add(const CreateDocument(title: 'My Custom Doc')),
        expect: () => [
          isA<DocumentEditorState>()
              .having(
                  (s) => s.currentDocument?.title, 'title', 'My Custom Doc'),
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
        'updates content and word/char counts',
        seed: () => DocumentEditorState(
          status: DocumentEditorStatus.editing,
          currentDocument: testDoc,
        ),
        build: () => bloc,
        act: (bloc) => bloc.add(const UpdateDocumentContent(
          content: '[{"insert":"New content here\\n"}]',
          plainText: 'New content here',
        )),
        expect: () => [
          isA<DocumentEditorState>()
              .having((s) => s.hasUnsavedChanges, 'unsaved', true)
              .having((s) => s.wordCount, 'words', 3)
              .having((s) => s.characterCount, 'chars', 16),
        ],
      );

      blocTest<DocumentEditorBloc, DocumentEditorState>(
        'does nothing without current document',
        build: () => bloc,
        act: (bloc) => bloc.add(const UpdateDocumentContent(
          content: '[]',
          plainText: 'test',
        )),
        expect: () => [],
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

      blocTest<DocumentEditorBloc, DocumentEditorState>(
        'clears current document if deleted',
        seed: () => DocumentEditorState(
          status: DocumentEditorStatus.editing,
          documents: [testDoc],
          currentDocument: testDoc,
        ),
        build: () {
          when(() => mockDao.deleteDocument('doc-1')).thenAnswer((_) async {});
          return bloc;
        },
        act: (bloc) => bloc.add(const DeleteDocument('doc-1')),
        expect: () => [
          isA<DocumentEditorState>()
              .having((s) => s.documents, 'docs', isEmpty)
              .having((s) => s.currentDocument, 'current', isNull),
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

    group('ToggleFindReplace', () {
      blocTest<DocumentEditorBloc, DocumentEditorState>(
        'toggles find/replace bar',
        build: () => bloc,
        act: (bloc) => bloc.add(const ToggleFindReplace()),
        expect: () => [
          isA<DocumentEditorState>()
              .having((s) => s.showFindReplace, 'findReplace', true),
        ],
      );
    });

    group('FindInDocument', () {
      blocTest<DocumentEditorBloc, DocumentEditorState>(
        'finds matches in plain text',
        seed: () => DocumentEditorState(
          status: DocumentEditorStatus.editing,
          currentDocument: testDoc,
        ),
        build: () => bloc,
        act: (bloc) => bloc.add(const FindInDocument('llo')),
        expect: () => [
          isA<DocumentEditorState>()
              .having((s) => s.findQuery, 'query', 'llo')
              .having((s) => s.findMatches.length, 'matches', 1)
              .having((s) => s.findMatches.first, 'pos', 2),
        ],
      );

      blocTest<DocumentEditorBloc, DocumentEditorState>(
        'returns empty matches for empty query',
        seed: () => DocumentEditorState(
          status: DocumentEditorStatus.editing,
          currentDocument: testDoc,
          findQuery: 'llo',
          findMatches: const [2],
        ),
        build: () => bloc,
        act: (bloc) => bloc.add(const FindInDocument('')),
        expect: () => [
          isA<DocumentEditorState>()
              .having((s) => s.findQuery, 'query', '')
              .having((s) => s.findMatches, 'matches', isEmpty),
        ],
      );
    });

    group('NavigateFindMatch', () {
      blocTest<DocumentEditorBloc, DocumentEditorState>(
        'navigates forward through matches',
        seed: () => const DocumentEditorState(
          status: DocumentEditorStatus.editing,
          findMatches: [0, 5, 10],
          currentFindIndex: 0,
        ),
        build: () => bloc,
        act: (bloc) => bloc.add(const NavigateFindMatch()),
        expect: () => [
          isA<DocumentEditorState>()
              .having((s) => s.currentFindIndex, 'idx', 1),
        ],
      );

      blocTest<DocumentEditorBloc, DocumentEditorState>(
        'wraps around at end',
        seed: () => const DocumentEditorState(
          status: DocumentEditorStatus.editing,
          findMatches: [0, 5, 10],
          currentFindIndex: 2,
        ),
        build: () => bloc,
        act: (bloc) => bloc.add(const NavigateFindMatch()),
        expect: () => [
          isA<DocumentEditorState>()
              .having((s) => s.currentFindIndex, 'idx', 0),
        ],
      );
    });

    group('ExportDocx', () {
      blocTest<DocumentEditorBloc, DocumentEditorState>(
        'generates DOCX bytes and sets exported state',
        seed: () => DocumentEditorState(
          status: DocumentEditorStatus.editing,
          currentDocument: testDoc,
        ),
        build: () => bloc,
        act: (bloc) => bloc.add(const ExportDocx()),
        expect: () => [
          isA<DocumentEditorState>()
              .having(
                  (s) => s.status, 'status', DocumentEditorStatus.exporting),
          isA<DocumentEditorState>()
              .having((s) => s.status, 'status', DocumentEditorStatus.exported)
              .having((s) => s.exportedBytes, 'bytes', isNotNull)
              .having((s) => s.exportedFileName, 'name', endsWith('.docx'))
              .having((s) => s.exportedMimeType, 'mime', contains('word')),
        ],
      );

      blocTest<DocumentEditorBloc, DocumentEditorState>(
        'does nothing without current document',
        build: () => bloc,
        act: (bloc) => bloc.add(const ExportDocx()),
        expect: () => [],
      );
    });

    group('ExportPdf', () {
      blocTest<DocumentEditorBloc, DocumentEditorState>(
        'generates PDF bytes and sets exported state',
        seed: () => DocumentEditorState(
          status: DocumentEditorStatus.editing,
          currentDocument: testDoc,
        ),
        build: () => bloc,
        act: (bloc) => bloc.add(const ExportPdf()),
        expect: () => [
          isA<DocumentEditorState>()
              .having(
                  (s) => s.status, 'status', DocumentEditorStatus.exporting),
          isA<DocumentEditorState>()
              .having((s) => s.status, 'status', DocumentEditorStatus.exported)
              .having((s) => s.exportedBytes, 'bytes', isNotNull)
              .having((s) => s.exportedFileName, 'name', endsWith('.pdf'))
              .having(
                  (s) => s.exportedMimeType, 'mime', 'application/pdf'),
        ],
      );
    });

    group('ImportTextFile', () {
      blocTest<DocumentEditorBloc, DocumentEditorState>(
        'imports plain text file as new document',
        build: () {
          when(() => mockDao.insertDocument(any())).thenAnswer((_) async {});
          return bloc;
        },
        act: (bloc) => bloc.add(const ImportTextFile(
          content: 'Hello from a text file',
          fileName: 'readme.txt',
        )),
        expect: () => [
          isA<DocumentEditorState>()
              .having((s) => s.status, 'status',
                  DocumentEditorStatus.importing),
          isA<DocumentEditorState>()
              .having((s) => s.status, 'status', DocumentEditorStatus.editing)
              .having((s) => s.currentDocument?.title, 'title', 'readme')
              .having((s) => s.wordCount, 'words', 5),
        ],
      );
    });

    group('ClearExportedBytes', () {
      blocTest<DocumentEditorBloc, DocumentEditorState>(
        'clears export state',
        seed: () => DocumentEditorState(
          status: DocumentEditorStatus.exported,
          currentDocument: testDoc,
          exportedBytes: Uint8List.fromList([1, 2, 3]),
          exportedFileName: 'test.pdf',
          exportedMimeType: 'application/pdf',
        ),
        build: () => bloc,
        act: (bloc) => bloc.add(const ClearExportedBytes()),
        expect: () => [
          isA<DocumentEditorState>()
              .having((s) => s.status, 'status', DocumentEditorStatus.editing)
              .having((s) => s.exportedBytes, 'bytes', isNull),
        ],
      );
    });

    group('AutoSaveDocument', () {
      blocTest<DocumentEditorBloc, DocumentEditorState>(
        'saves when has unsaved changes',
        seed: () => DocumentEditorState(
          status: DocumentEditorStatus.editing,
          currentDocument: testDoc,
          hasUnsavedChanges: true,
        ),
        build: () {
          when(() => mockDao.updateDocument(any())).thenAnswer((_) async {});
          return bloc;
        },
        act: (bloc) => bloc.add(const AutoSaveDocument()),
        expect: () => [
          isA<DocumentEditorState>()
              .having((s) => s.hasUnsavedChanges, 'unsaved', false),
        ],
      );

      blocTest<DocumentEditorBloc, DocumentEditorState>(
        'does nothing when no unsaved changes',
        seed: () => DocumentEditorState(
          status: DocumentEditorStatus.editing,
          currentDocument: testDoc,
          hasUnsavedChanges: false,
        ),
        build: () => bloc,
        act: (bloc) => bloc.add(const AutoSaveDocument()),
        expect: () => [],
      );
    });

    group('ToggleDocumentFavorite', () {
      blocTest<DocumentEditorBloc, DocumentEditorState>(
        'toggles favorite and reloads',
        build: () {
          when(() => mockDao.toggleFavorite('doc-1'))
              .thenAnswer((_) async {});
          when(() => mockDao.getAllDocuments())
              .thenAnswer((_) async => [testDoc]);
          return bloc;
        },
        act: (bloc) => bloc.add(const ToggleDocumentFavorite('doc-1')),
        wait: const Duration(milliseconds: 100),
        expect: () => [
          // LoadDocuments triggered internally
          isA<DocumentEditorState>()
              .having((s) => s.status, 'status', DocumentEditorStatus.loading),
          isA<DocumentEditorState>()
              .having((s) => s.status, 'status', DocumentEditorStatus.loaded),
        ],
      );
    });

    group('DuplicateDocument', () {
      blocTest<DocumentEditorBloc, DocumentEditorState>(
        'duplicates and reloads',
        build: () {
          when(() => mockDao.duplicateDocument('doc-1'))
              .thenAnswer((_) async => testDoc.copyWith(title: 'Copy'));
          when(() => mockDao.getAllDocuments())
              .thenAnswer((_) async => [testDoc, testDoc2]);
          return bloc;
        },
        act: (bloc) => bloc.add(const DuplicateDocument('doc-1')),
        wait: const Duration(milliseconds: 100),
        expect: () => [
          isA<DocumentEditorState>()
              .having((s) => s.status, 'status', DocumentEditorStatus.loading),
          isA<DocumentEditorState>()
              .having((s) => s.documents.length, 'count', 2),
        ],
      );
    });
  });
}
