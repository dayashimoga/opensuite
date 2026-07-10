import 'package:fileutility_core/fileutility_core.dart';
import 'package:fileutility_storage/fileutility_storage.dart';

import '../features/document_editor/bloc/document_editor_bloc.dart';
import '../features/file_manager/bloc/file_manager_bloc.dart';
import '../features/notes/bloc/notes_bloc.dart';
import '../features/presentation/bloc/presentation_bloc.dart';
import '../features/settings/bloc/settings_bloc.dart';
import '../features/spreadsheet/bloc/spreadsheet_bloc.dart';
import '../features/text_editor/bloc/text_editor_bloc.dart';

/// Application-level dependency injection module.
///
/// Registers all feature-specific services and BLoCs
/// with the global service locator.
class AppModule {
  AppModule._();

  /// Initializes all app-level dependencies.
  static Future<void> initialize() async {
    // DAOs
    sl.registerLazySingleton<NoteDao>(() => NoteDao());
    sl.registerLazySingleton<RecentFileDao>(() => RecentFileDao());
    sl.registerLazySingleton<DocumentDao>(() => DocumentDao());
    sl.registerLazySingleton<SpreadsheetDao>(() => SpreadsheetDao());
    sl.registerLazySingleton<PresentationDao>(() => PresentationDao());
    sl.registerLazySingleton<VersionDao>(() => VersionDao());
    sl.registerLazySingleton<PreferencesService>(() => PreferencesService());
    sl.registerLazySingleton<FileStorageService>(
      () => FileStorageService.instance,
    );
  }

  /// Creates a new [NotesBloc] instance.
  static NotesBloc get notesBloc => NotesBloc(noteDao: sl<NoteDao>());

  /// Creates a new [FileManagerBloc] instance.
  static FileManagerBloc get fileManagerBloc => FileManagerBloc(
        recentFileDao: sl<RecentFileDao>(),
        fileStorageService: sl<FileStorageService>(),
      );

  /// Creates a new [TextEditorBloc] instance.
  static TextEditorBloc get textEditorBloc => TextEditorBloc(
        fileStorageService: sl<FileStorageService>(),
        preferencesService: sl<PreferencesService>(),
      );

  /// Creates a new [DocumentEditorBloc] instance.
  static DocumentEditorBloc get documentEditorBloc => DocumentEditorBloc(
        documentDao: sl<DocumentDao>(),
      );

  /// Creates a new [SpreadsheetBloc] instance.
  static SpreadsheetBloc get spreadsheetBloc => SpreadsheetBloc(
        spreadsheetDao: sl<SpreadsheetDao>(),
      );

  /// Creates a new [PresentationBloc] instance.
  static PresentationBloc get presentationBloc => PresentationBloc(
        presentationDao: sl<PresentationDao>(),
      );

  /// Creates a new [SettingsBloc] instance.
  static SettingsBloc get settingsBloc => SettingsBloc(
        preferencesService: sl<PreferencesService>(),
      );
}
