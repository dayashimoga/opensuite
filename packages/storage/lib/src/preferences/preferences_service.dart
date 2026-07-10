import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../database/database_provider.dart';

/// Key-value preferences storage service.
///
/// Stores user preferences in SQLite for consistent cross-platform behavior.
/// Supports string, int, double, bool, and list values.
class PreferencesService {
  /// Creates a [PreferencesService] with the given database provider.
  PreferencesService({DatabaseProvider? provider})
      : _provider = provider ?? DatabaseProvider.instance;

  final DatabaseProvider _provider;
  static const _table = 'preferences';
  static bool _tableCreated = false;

  Future<Database> _getDb() async {
    final db = await _provider.database;
    if (!_tableCreated) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $_table (
          key TEXT PRIMARY KEY NOT NULL,
          value TEXT NOT NULL,
          type TEXT NOT NULL DEFAULT 'string'
        )
      ''');
      _tableCreated = true;
    }
    return db;
  }

  /// Gets a string value by key, or [defaultValue] if not found.
  Future<String> getString(String key, {String defaultValue = ''}) async {
    final value = await _getValue(key);
    return value ?? defaultValue;
  }

  /// Gets an integer value by key, or [defaultValue] if not found.
  Future<int> getInt(String key, {int defaultValue = 0}) async {
    final value = await _getValue(key);
    return value != null ? int.tryParse(value) ?? defaultValue : defaultValue;
  }

  /// Gets a double value by key, or [defaultValue] if not found.
  Future<double> getDouble(String key, {double defaultValue = 0.0}) async {
    final value = await _getValue(key);
    return value != null
        ? double.tryParse(value) ?? defaultValue
        : defaultValue;
  }

  /// Gets a boolean value by key, or [defaultValue] if not found.
  Future<bool> getBool(String key, {bool defaultValue = false}) async {
    final value = await _getValue(key);
    return value != null ? value == 'true' : defaultValue;
  }

  /// Sets a string value.
  Future<void> setString(String key, String value) async {
    await _setValue(key, value, 'string');
  }

  /// Sets an integer value.
  Future<void> setInt(String key, int value) async {
    await _setValue(key, value.toString(), 'int');
  }

  /// Sets a double value.
  Future<void> setDouble(String key, double value) async {
    await _setValue(key, value.toString(), 'double');
  }

  /// Sets a boolean value.
  Future<void> setBool(String key, bool value) async {
    await _setValue(key, value.toString(), 'bool');
  }

  /// Removes a value by key.
  Future<void> remove(String key) async {
    final db = await _getDb();
    await db.delete(_table, where: 'key = ?', whereArgs: [key]);
  }

  /// Returns true if a key exists.
  Future<bool> containsKey(String key) async {
    final value = await _getValue(key);
    return value != null;
  }

  /// Clears all preferences.
  Future<void> clear() async {
    final db = await _getDb();
    await db.delete(_table);
  }

  Future<String?> _getValue(String key) async {
    try {
      final db = await _getDb();
      final maps = await db.query(
        _table,
        columns: ['value'],
        where: 'key = ?',
        whereArgs: [key],
        limit: 1,
      );
      if (maps.isEmpty) return null;
      return maps.first['value'] as String?;
    } catch (e) {
      debugPrint('PreferencesService error reading key "$key": $e');
      return null;
    }
  }

  Future<void> _setValue(String key, String value, String type) async {
    final db = await _getDb();
    await db.insert(
      _table,
      {'key': key, 'value': value, 'type': type},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}

/// Well-known preference keys.
class PreferenceKeys {
  PreferenceKeys._();

  /// Theme mode: 'system', 'light', or 'dark'.
  static const String themeMode = 'theme_mode';

  /// UI locale code (e.g., 'en', 'es').
  static const String locale = 'locale';

  /// Editor font size in pixels.
  static const String editorFontSize = 'editor_font_size';

  /// Whether to show line numbers in the editor.
  static const String showLineNumbers = 'show_line_numbers';

  /// Whether word wrap is enabled.
  static const String wordWrap = 'word_wrap';

  /// Autosave interval in seconds.
  static const String autosaveInterval = 'autosave_interval';

  /// Whether autosave is enabled.
  static const String autosaveEnabled = 'autosave_enabled';

  /// Whether to show the sidebar on startup.
  static const String sidebarExpanded = 'sidebar_expanded';

  /// Default note content type.
  static const String defaultNoteType = 'default_note_type';

  /// Whether the app has been set up (first run complete).
  static const String setupComplete = 'setup_complete';

  /// Whether high contrast mode is enabled.
  static const String highContrastMode = 'high_contrast_mode';
}
