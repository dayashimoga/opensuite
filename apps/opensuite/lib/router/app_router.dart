import 'package:go_router/go_router.dart';

import '../features/document_editor/pages/rich_document_editor_page.dart';
import '../features/document_editor/pages/rich_document_list_page.dart';
import '../features/file_manager/pages/file_manager_page.dart';
import '../features/home/home_page.dart';
import '../features/image_editor/pages/image_editor_page.dart';
import '../features/notes/pages/note_editor_page.dart';
import '../features/notes/pages/notes_page.dart';
import '../features/pdf_viewer/pages/pdf_viewer_page.dart';
import '../features/presentation/pages/presentation_editor_page.dart';
import '../features/presentation/pages/presentation_list_page.dart';
import '../features/settings/pages/settings_page.dart';
import '../features/spreadsheet/pages/spreadsheet_editor_page.dart';
import '../features/spreadsheet/pages/spreadsheet_list_page.dart';
import '../features/text_editor/pages/document_list_page.dart';
import '../features/text_editor/pages/text_editor_page.dart';
import 'shell_page.dart';

/// Application router configuration.
///
/// Uses GoRouter with a shell route for the main navigation
/// scaffold, and nested routes for each feature module.
class AppRouter {
  AppRouter._();

  /// Route paths.
  static const String home = '/';
  static const String notes = '/notes';
  static const String noteEditor = '/notes/:id';
  static const String newNote = '/notes/new';
  static const String files = '/files';
  static const String documents = '/documents';
  static const String documentEditor = '/documents/:id';
  static const String newRichDocument = '/documents/new';
  static const String spreadsheets = '/spreadsheets';
  static const String spreadsheetEditor = '/spreadsheets/:id';
  static const String newSpreadsheet = '/spreadsheets/new';
  static const String presentations = '/presentations';
  static const String presentationEditor = '/presentations/:id';
  static const String newPresentation = '/presentations/new';
  static const String pdfViewer = '/pdf';
  static const String imageEditor = '/images';
  static const String editor = '/editor';
  static const String editorDocument = '/editor/:id';
  static const String newDocument = '/editor/new';
  static const String settings = '/settings';

  /// The router configuration.
  static final GoRouter router = GoRouter(
    initialLocation: home,
    routes: [
      ShellRoute(
        builder: (context, state, child) => ShellPage(child: child),
        routes: [
          GoRoute(
            path: home,
            name: 'home',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HomePage(),
            ),
          ),
          GoRoute(
            path: notes,
            name: 'notes',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: NotesPage(),
            ),
            routes: [
              GoRoute(
                path: 'new',
                name: 'newNote',
                builder: (context, state) => const NoteEditorPage(),
              ),
              GoRoute(
                path: ':id',
                name: 'noteEditor',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return NoteEditorPage(noteId: id);
                },
              ),
            ],
          ),
          GoRoute(
            path: files,
            name: 'files',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: FileManagerPage(),
            ),
          ),
          GoRoute(
            path: documents,
            name: 'documents',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: RichDocumentListPage(),
            ),
            routes: [
              GoRoute(
                path: 'new',
                name: 'newRichDocument',
                builder: (context, state) => const RichDocumentEditorPage(),
              ),
              GoRoute(
                path: ':id',
                name: 'documentEditor',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return RichDocumentEditorPage(documentId: id);
                },
              ),
            ],
          ),
          GoRoute(
            path: spreadsheets,
            name: 'spreadsheets',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SpreadsheetListPage(),
            ),
            routes: [
              GoRoute(
                path: 'new',
                name: 'newSpreadsheet',
                builder: (context, state) => const SpreadsheetEditorPage(),
              ),
              GoRoute(
                path: ':id',
                name: 'spreadsheetEditor',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return SpreadsheetEditorPage(spreadsheetId: id);
                },
              ),
            ],
          ),
          GoRoute(
            path: presentations,
            name: 'presentations',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: PresentationListPage(),
            ),
            routes: [
              GoRoute(
                path: 'new',
                name: 'newPresentation',
                builder: (context, state) => const PresentationEditorPage(),
              ),
              GoRoute(
                path: ':id',
                name: 'presentationEditor',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return PresentationEditorPage(presentationId: id);
                },
              ),
            ],
          ),
          GoRoute(
            path: pdfViewer,
            name: 'pdfViewer',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: PdfViewerPage(),
            ),
          ),
          GoRoute(
            path: imageEditor,
            name: 'imageEditor',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ImageEditorPage(),
            ),
          ),
          GoRoute(
            path: editor,
            name: 'editor',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: DocumentListPage(),
            ),
            routes: [
              GoRoute(
                path: 'new',
                name: 'newDocument',
                builder: (context, state) => const TextEditorPage(),
              ),
              GoRoute(
                path: ':id',
                name: 'editorDocument',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return TextEditorPage(documentId: id);
                },
              ),
            ],
          ),
          GoRoute(
            path: settings,
            name: 'settings',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SettingsPage(),
            ),
          ),
        ],
      ),
    ],
  );
}
