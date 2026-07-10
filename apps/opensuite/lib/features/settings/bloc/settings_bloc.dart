import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fileutility_storage/fileutility_storage.dart';

// ── Events ──────────────────────────────────────────────────

/// Base event for settings.
sealed class SettingsEvent extends Equatable {
  const SettingsEvent();

  @override
  List<Object?> get props => [];
}

/// Load settings from storage.
class LoadSettings extends SettingsEvent {
  const LoadSettings();
}

/// Change theme mode.
class ChangeThemeMode extends SettingsEvent {
  const ChangeThemeMode(this.themeMode);
  final ThemeMode themeMode;

  @override
  List<Object?> get props => [themeMode];
}

/// Change editor font size.
class ChangeFontSize extends SettingsEvent {
  const ChangeFontSize(this.fontSize);
  final double fontSize;

  @override
  List<Object?> get props => [fontSize];
}

/// Toggle line numbers in editor.
class ToggleLineNumbers extends SettingsEvent {
  const ToggleLineNumbers();
}

/// Toggle word wrap in editor.
class ToggleWordWrap extends SettingsEvent {
  const ToggleWordWrap();
}

/// Toggle autosave.
class ToggleAutosave extends SettingsEvent {
  const ToggleAutosave();
}

/// Change autosave interval.
class ChangeAutosaveInterval extends SettingsEvent {
  const ChangeAutosaveInterval(this.seconds);
  final int seconds;

  @override
  List<Object?> get props => [seconds];
}

/// Toggle high contrast mode for WCAG AAA accessibility.
class ToggleHighContrast extends SettingsEvent {
  const ToggleHighContrast();
}

/// Change application locale.
class ChangeLocale extends SettingsEvent {
  const ChangeLocale(this.localeCode);
  final String localeCode;

  @override
  List<Object?> get props => [localeCode];
}

// ── State ───────────────────────────────────────────────────

/// Settings state.
class SettingsState extends Equatable {
  const SettingsState({
    this.themeMode = ThemeMode.system,
    this.fontSize = 14.0,
    this.showLineNumbers = true,
    this.wordWrap = true,
    this.autosaveEnabled = true,
    this.autosaveIntervalSeconds = 30,
    this.highContrastMode = false,
    this.localeCode = 'en',
    this.isLoading = false,
  });

  final ThemeMode themeMode;
  final double fontSize;
  final bool showLineNumbers;
  final bool wordWrap;
  final bool autosaveEnabled;
  final int autosaveIntervalSeconds;
  final bool highContrastMode;
  final String localeCode;
  final bool isLoading;

  SettingsState copyWith({
    ThemeMode? themeMode,
    double? fontSize,
    bool? showLineNumbers,
    bool? wordWrap,
    bool? autosaveEnabled,
    int? autosaveIntervalSeconds,
    bool? highContrastMode,
    String? localeCode,
    bool? isLoading,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      fontSize: fontSize ?? this.fontSize,
      showLineNumbers: showLineNumbers ?? this.showLineNumbers,
      wordWrap: wordWrap ?? this.wordWrap,
      autosaveEnabled: autosaveEnabled ?? this.autosaveEnabled,
      autosaveIntervalSeconds:
          autosaveIntervalSeconds ?? this.autosaveIntervalSeconds,
      highContrastMode: highContrastMode ?? this.highContrastMode,
      localeCode: localeCode ?? this.localeCode,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [
        themeMode, fontSize, showLineNumbers,
        wordWrap, autosaveEnabled, autosaveIntervalSeconds,
        highContrastMode, localeCode, isLoading,
      ];
}

// ── BLoC ────────────────────────────────────────────────────

/// Manages application settings state.
class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  SettingsBloc({required PreferencesService preferencesService})
      : _prefs = preferencesService,
        super(const SettingsState()) {
    on<LoadSettings>(_onLoadSettings);
    on<ChangeThemeMode>(_onChangeThemeMode);
    on<ChangeFontSize>(_onChangeFontSize);
    on<ToggleLineNumbers>(_onToggleLineNumbers);
    on<ToggleWordWrap>(_onToggleWordWrap);
    on<ToggleAutosave>(_onToggleAutosave);
    on<ChangeAutosaveInterval>(_onChangeAutosaveInterval);
    on<ToggleHighContrast>(_onToggleHighContrast);
    on<ChangeLocale>(_onChangeLocale);
  }

  final PreferencesService _prefs;

  Future<void> _onLoadSettings(
    LoadSettings event,
    Emitter<SettingsState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));

    final themeModeStr = await _prefs.getString(
      PreferenceKeys.themeMode,
      defaultValue: 'system',
    );
    final fontSize = await _prefs.getDouble(
      PreferenceKeys.editorFontSize,
      defaultValue: 14.0,
    );
    final showLineNumbers = await _prefs.getBool(
      PreferenceKeys.showLineNumbers,
      defaultValue: true,
    );
    final wordWrap = await _prefs.getBool(
      PreferenceKeys.wordWrap,
      defaultValue: true,
    );
    final autosaveEnabled = await _prefs.getBool(
      PreferenceKeys.autosaveEnabled,
      defaultValue: true,
    );
    final autosaveInterval = await _prefs.getInt(
      PreferenceKeys.autosaveInterval,
      defaultValue: 30,
    );
    final highContrast = await _prefs.getBool(
      PreferenceKeys.highContrastMode,
      defaultValue: false,
    );
    final locale = await _prefs.getString(
      PreferenceKeys.locale,
      defaultValue: 'en',
    );

    emit(SettingsState(
      themeMode: _parseThemeMode(themeModeStr),
      fontSize: fontSize,
      showLineNumbers: showLineNumbers,
      wordWrap: wordWrap,
      autosaveEnabled: autosaveEnabled,
      autosaveIntervalSeconds: autosaveInterval,
      highContrastMode: highContrast,
      localeCode: locale,
    ));
  }

  Future<void> _onChangeThemeMode(
    ChangeThemeMode event,
    Emitter<SettingsState> emit,
  ) async {
    final modeStr = switch (event.themeMode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    await _prefs.setString(PreferenceKeys.themeMode, modeStr);
    emit(state.copyWith(themeMode: event.themeMode));
  }

  Future<void> _onChangeFontSize(
    ChangeFontSize event,
    Emitter<SettingsState> emit,
  ) async {
    await _prefs.setDouble(PreferenceKeys.editorFontSize, event.fontSize);
    emit(state.copyWith(fontSize: event.fontSize));
  }

  Future<void> _onToggleLineNumbers(
    ToggleLineNumbers event,
    Emitter<SettingsState> emit,
  ) async {
    final newValue = !state.showLineNumbers;
    await _prefs.setBool(PreferenceKeys.showLineNumbers, newValue);
    emit(state.copyWith(showLineNumbers: newValue));
  }

  Future<void> _onToggleWordWrap(
    ToggleWordWrap event,
    Emitter<SettingsState> emit,
  ) async {
    final newValue = !state.wordWrap;
    await _prefs.setBool(PreferenceKeys.wordWrap, newValue);
    emit(state.copyWith(wordWrap: newValue));
  }

  Future<void> _onToggleAutosave(
    ToggleAutosave event,
    Emitter<SettingsState> emit,
  ) async {
    final newValue = !state.autosaveEnabled;
    await _prefs.setBool(PreferenceKeys.autosaveEnabled, newValue);
    emit(state.copyWith(autosaveEnabled: newValue));
  }

  Future<void> _onChangeAutosaveInterval(
    ChangeAutosaveInterval event,
    Emitter<SettingsState> emit,
  ) async {
    await _prefs.setInt(PreferenceKeys.autosaveInterval, event.seconds);
    emit(state.copyWith(autosaveIntervalSeconds: event.seconds));
  }

  Future<void> _onToggleHighContrast(
    ToggleHighContrast event,
    Emitter<SettingsState> emit,
  ) async {
    final newValue = !state.highContrastMode;
    await _prefs.setBool(PreferenceKeys.highContrastMode, newValue);
    emit(state.copyWith(highContrastMode: newValue));
  }

  Future<void> _onChangeLocale(
    ChangeLocale event,
    Emitter<SettingsState> emit,
  ) async {
    await _prefs.setString(PreferenceKeys.locale, event.localeCode);
    emit(state.copyWith(localeCode: event.localeCode));
  }

  ThemeMode _parseThemeMode(String value) {
    return switch (value) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }
}
