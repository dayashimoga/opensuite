import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fileutility_storage/fileutility_storage.dart';
import 'package:opensuite/features/settings/bloc/settings_bloc.dart';

class MockPreferencesService extends Mock implements PreferencesService {}

void main() {
  late MockPreferencesService mockPrefs;
  late SettingsBloc bloc;

  setUp(() {
    mockPrefs = MockPreferencesService();
    bloc = SettingsBloc(preferencesService: mockPrefs);
  });

  tearDown(() => bloc.close());

  void stubAllPrefsDefaults() {
    when(() => mockPrefs.getString(any(),
            defaultValue: any(named: 'defaultValue')))
        .thenAnswer((_) async => 'system');
    when(() => mockPrefs.getDouble(any(),
            defaultValue: any(named: 'defaultValue')))
        .thenAnswer((_) async => 14.0);
    when(() =>
            mockPrefs.getBool(any(), defaultValue: any(named: 'defaultValue')))
        .thenAnswer((inv) async => inv.namedArguments[#defaultValue] as bool);
    when(() =>
            mockPrefs.getInt(any(), defaultValue: any(named: 'defaultValue')))
        .thenAnswer((_) async => 30);
  }

  group('SettingsBloc', () {
    test('initial state is correct', () {
      expect(bloc.state.themeMode, ThemeMode.system);
      expect(bloc.state.fontSize, 14.0);
      expect(bloc.state.showLineNumbers, true);
      expect(bloc.state.wordWrap, true);
      expect(bloc.state.autosaveEnabled, true);
      expect(bloc.state.autosaveIntervalSeconds, 30);
      expect(bloc.state.highContrastMode, false);
      expect(bloc.state.localeCode, 'en');
      expect(bloc.state.isLoading, false);
    });

    group('LoadSettings', () {
      blocTest<SettingsBloc, SettingsState>(
        'loads all settings from preferences',
        build: () {
          stubAllPrefsDefaults();
          return bloc;
        },
        act: (bloc) => bloc.add(const LoadSettings()),
        expect: () => [
          isA<SettingsState>().having((s) => s.isLoading, 'isLoading', true),
          isA<SettingsState>()
              .having((s) => s.isLoading, 'isLoading', false)
              .having((s) => s.themeMode, 'themeMode', ThemeMode.system),
        ],
      );
    });

    group('ChangeThemeMode', () {
      blocTest<SettingsBloc, SettingsState>(
        'persists and emits new theme mode',
        build: () {
          when(() => mockPrefs.setString(any(), any()))
              .thenAnswer((_) async {});
          return bloc;
        },
        act: (bloc) => bloc.add(const ChangeThemeMode(ThemeMode.dark)),
        expect: () => [
          isA<SettingsState>()
              .having((s) => s.themeMode, 'themeMode', ThemeMode.dark),
        ],
        verify: (_) {
          verify(() => mockPrefs.setString(PreferenceKeys.themeMode, 'dark'))
              .called(1);
        },
      );
    });

    group('ChangeFontSize', () {
      blocTest<SettingsBloc, SettingsState>(
        'persists and emits new font size',
        build: () {
          when(() => mockPrefs.setDouble(any(), any()))
              .thenAnswer((_) async {});
          return bloc;
        },
        act: (bloc) => bloc.add(const ChangeFontSize(18.0)),
        expect: () => [
          isA<SettingsState>().having((s) => s.fontSize, 'fontSize', 18.0),
        ],
      );
    });

    group('ToggleLineNumbers', () {
      blocTest<SettingsBloc, SettingsState>(
        'toggles showLineNumbers from true to false',
        build: () {
          when(() => mockPrefs.setBool(any(), any())).thenAnswer((_) async {});
          return bloc;
        },
        act: (bloc) => bloc.add(const ToggleLineNumbers()),
        expect: () => [
          isA<SettingsState>()
              .having((s) => s.showLineNumbers, 'showLineNumbers', false),
        ],
      );
    });

    group('ToggleWordWrap', () {
      blocTest<SettingsBloc, SettingsState>(
        'toggles wordWrap from true to false',
        build: () {
          when(() => mockPrefs.setBool(any(), any())).thenAnswer((_) async {});
          return bloc;
        },
        act: (bloc) => bloc.add(const ToggleWordWrap()),
        expect: () => [
          isA<SettingsState>().having((s) => s.wordWrap, 'wordWrap', false),
        ],
      );
    });

    group('ToggleAutosave', () {
      blocTest<SettingsBloc, SettingsState>(
        'toggles autosaveEnabled from true to false',
        build: () {
          when(() => mockPrefs.setBool(any(), any())).thenAnswer((_) async {});
          return bloc;
        },
        act: (bloc) => bloc.add(const ToggleAutosave()),
        expect: () => [
          isA<SettingsState>()
              .having((s) => s.autosaveEnabled, 'autosave', false),
        ],
      );
    });

    group('ChangeAutosaveInterval', () {
      blocTest<SettingsBloc, SettingsState>(
        'persists and emits new interval',
        build: () {
          when(() => mockPrefs.setInt(any(), any())).thenAnswer((_) async {});
          return bloc;
        },
        act: (bloc) => bloc.add(const ChangeAutosaveInterval(60)),
        expect: () => [
          isA<SettingsState>()
              .having((s) => s.autosaveIntervalSeconds, 'interval', 60),
        ],
      );
    });

    group('ToggleHighContrast', () {
      blocTest<SettingsBloc, SettingsState>(
        'toggles high contrast from false to true',
        build: () {
          when(() => mockPrefs.setBool(any(), any())).thenAnswer((_) async {});
          return bloc;
        },
        act: (bloc) => bloc.add(const ToggleHighContrast()),
        expect: () => [
          isA<SettingsState>()
              .having((s) => s.highContrastMode, 'highContrast', true),
        ],
      );
    });

    group('ChangeLocale', () {
      blocTest<SettingsBloc, SettingsState>(
        'persists and emits new locale code',
        build: () {
          when(() => mockPrefs.setString(any(), any()))
              .thenAnswer((_) async {});
          return bloc;
        },
        act: (bloc) => bloc.add(const ChangeLocale('de')),
        expect: () => [
          isA<SettingsState>().having((s) => s.localeCode, 'locale', 'de'),
        ],
      );
    });

    group('SettingsState', () {
      test('copyWith preserves unmodified values', () {
        const state = SettingsState(
          themeMode: ThemeMode.dark,
          fontSize: 18.0,
          localeCode: 'fr',
        );
        final copy = state.copyWith(fontSize: 20.0);
        expect(copy.themeMode, ThemeMode.dark);
        expect(copy.fontSize, 20.0);
        expect(copy.localeCode, 'fr');
      });
    });
  });
}
