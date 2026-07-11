import 'package:flutter_test/flutter_test.dart';
import 'package:opensuite/features/image_editor/bloc/image_editor_bloc.dart';
import 'package:opensuite/features/notes/bloc/notes_bloc.dart';
import 'package:opensuite/features/file_manager/bloc/file_manager_bloc.dart';
import 'package:opensuite/features/settings/bloc/settings_bloc.dart';

/// Smoke tests that verify core BLoC and state classes compile and initialize.
/// Full widget tests require platform-specific setup (database, preferences).
void main() {
  group('Smoke tests', () {
    test('NotesState initializes correctly', () {
      const state = NotesState();
      expect(state.status, NotesStatus.initial);
      expect(state.notes, isEmpty);
      expect(state.searchQuery, '');
      expect(state.pinnedNotes, isEmpty);
      expect(state.unpinnedNotes, isEmpty);
    });

    test('FileManagerState initializes correctly', () {
      const state = FileManagerState();
      expect(state.status, FileManagerStatus.initial);
      expect(state.files, isEmpty);
      expect(state.viewMode, FileViewMode.list);
      expect(state.activeTab, FileTab.recent);
    });

    test('ImageEditorState initializes correctly', () {
      const state = ImageEditorState();
      expect(state.status, ImageEditorStatus.initial);
      expect(state.filePath, isNull);
      expect(state.activeTool, 'adjust');
      expect(state.canUndo, false);
      expect(state.canRedo, false);
    });

    test('ImageAdjustments default values', () {
      const adj = ImageAdjustments();
      expect(adj.brightness, 0.0);
      expect(adj.contrast, 1.0);
      expect(adj.saturation, 1.0);
      expect(adj.rotation, 0.0);
      expect(adj.flipHorizontal, false);
      expect(adj.flipVertical, false);
    });

    test('SettingsState initializes correctly', () {
      const state = SettingsState();
      expect(state.themeMode, isNotNull);
      expect(state.fontSize, 14.0);
      expect(state.showLineNumbers, true);
      expect(state.wordWrap, true);
      expect(state.autosaveEnabled, true);
      expect(state.autosaveIntervalSeconds, 30);
      expect(state.localeCode, 'en');
    });

    test('ImageEditorBloc creates without errors', () {
      final bloc = ImageEditorBloc();
      expect(bloc.state, const ImageEditorState());
      bloc.close();
    });
  });
}
