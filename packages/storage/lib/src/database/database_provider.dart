import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

/// Provides and manages the SQLite database instance.
///
/// Handles database creation, migrations, and lifecycle.
/// Uses a singleton pattern to ensure only one database
/// connection is active.
class DatabaseProvider {
  DatabaseProvider._();

  static DatabaseProvider? _instance;
  static Database? _database;

  /// Returns the singleton instance.
  static DatabaseProvider get instance {
    _instance ??= DatabaseProvider._();
    return _instance!;
  }

  /// Database version for migration tracking.
  static const int _version = 5;

  /// Database file name.
  static const String _dbName = 'fileutility.db';

  /// Returns the database instance, creating it if necessary.
  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final String dbPath;

    if (kIsWeb) {
      dbPath = _dbName;
    } else {
      final directory = await getApplicationDocumentsDirectory();
      dbPath = p.join(directory.path, 'FileUtility', _dbName);
    }

    return openDatabase(
      dbPath,
      version: _version,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: _onConfigure,
    );
  }

  Future<void> _onConfigure(Database db) async {
    // foreign_keys is a simple setter — safe to use execute.
    await db.execute('PRAGMA foreign_keys = ON');

    // journal_mode returns a result set, so we must use rawQuery
    // instead of execute (which crashes on Android native sqflite).
    // On web, sqflite_common_ffi handles journaling internally.
    if (!kIsWeb) {
      await db.rawQuery('PRAGMA journal_mode = WAL');
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    // Notes table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS notes (
        id TEXT PRIMARY KEY NOT NULL,
        title TEXT NOT NULL DEFAULT '',
        content TEXT NOT NULL DEFAULT '',
        content_type TEXT NOT NULL DEFAULT 'plain',
        is_pinned INTEGER NOT NULL DEFAULT 0,
        is_favorite INTEGER NOT NULL DEFAULT 0,
        color TEXT,
        tags TEXT NOT NULL DEFAULT '[]',
        created_at TEXT NOT NULL,
        modified_at TEXT NOT NULL
      )
    ''');

    // Recent files table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS recent_files (
        id TEXT PRIMARY KEY NOT NULL,
        file_name TEXT NOT NULL,
        file_path TEXT NOT NULL,
        file_type TEXT NOT NULL,
        size_bytes INTEGER,
        is_favorite INTEGER NOT NULL DEFAULT 0,
        last_opened_at TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    // Text documents table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS text_documents (
        id TEXT PRIMARY KEY NOT NULL,
        title TEXT NOT NULL DEFAULT '',
        content TEXT NOT NULL DEFAULT '',
        file_type TEXT NOT NULL DEFAULT 'text',
        file_path TEXT,
        is_modified INTEGER NOT NULL DEFAULT 0,
        word_count INTEGER NOT NULL DEFAULT 0,
        char_count INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        modified_at TEXT NOT NULL
      )
    ''');

    // Create indexes
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_notes_modified_at ON notes(modified_at DESC)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_notes_is_pinned ON notes(is_pinned DESC)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_recent_files_last_opened ON recent_files(last_opened_at DESC)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_text_documents_modified ON text_documents(modified_at DESC)',
    );

    // Documents table (Sprint 2 — rich text editor)
    await _createDocumentsTable(db);

    // Spreadsheets table (Sprint 3)
    await _createSpreadsheetsTable(db);

    // Presentations table (Sprint 4)
    await _createPresentationsTable(db);

    // Version history table (Sprint 7)
    await _createVersionsTable(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createDocumentsTable(db);
    }
    if (oldVersion < 3) {
      await _createSpreadsheetsTable(db);
    }
    if (oldVersion < 4) {
      await _createPresentationsTable(db);
    }
    if (oldVersion < 5) {
      await _createVersionsTable(db);
    }
  }

  /// Creates the documents table and its indexes.
  static Future<void> _createDocumentsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS documents (
        id TEXT PRIMARY KEY NOT NULL,
        title TEXT NOT NULL DEFAULT '',
        content TEXT NOT NULL DEFAULT '',
        plain_text TEXT NOT NULL DEFAULT '',
        format TEXT NOT NULL DEFAULT 'rich',
        word_count INTEGER NOT NULL DEFAULT 0,
        character_count INTEGER NOT NULL DEFAULT 0,
        is_favorite INTEGER NOT NULL DEFAULT 0,
        tags TEXT,
        created_at TEXT NOT NULL,
        modified_at TEXT NOT NULL
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_documents_modified ON documents(modified_at DESC)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_documents_format ON documents(format)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_documents_favorite ON documents(is_favorite)',
    );
  }

  /// Creates the spreadsheets table and its indexes.
  static Future<void> _createSpreadsheetsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS spreadsheets (
        id TEXT PRIMARY KEY NOT NULL,
        title TEXT NOT NULL DEFAULT '',
        content TEXT NOT NULL DEFAULT '[]',
        sheet_count INTEGER NOT NULL DEFAULT 1,
        is_favorite INTEGER NOT NULL DEFAULT 0,
        tags TEXT,
        created_at TEXT NOT NULL,
        modified_at TEXT NOT NULL
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_spreadsheets_modified ON spreadsheets(modified_at DESC)',
    );
  }

  /// Creates the presentations table and its indexes.
  static Future<void> _createPresentationsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS presentations (
        id TEXT PRIMARY KEY NOT NULL,
        title TEXT NOT NULL DEFAULT '',
        content TEXT NOT NULL DEFAULT '[]',
        slide_count INTEGER NOT NULL DEFAULT 1,
        theme TEXT NOT NULL DEFAULT 'default',
        is_favorite INTEGER NOT NULL DEFAULT 0,
        tags TEXT,
        created_at TEXT NOT NULL,
        modified_at TEXT NOT NULL
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_presentations_modified ON presentations(modified_at DESC)',
    );
  }

  /// Creates the document_versions table and its indexes.
  static Future<void> _createVersionsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS document_versions (
        id TEXT PRIMARY KEY NOT NULL,
        document_id TEXT NOT NULL,
        document_type TEXT NOT NULL,
        content TEXT NOT NULL,
        title TEXT NOT NULL DEFAULT '',
        version_number INTEGER NOT NULL,
        content_size INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL,
        label TEXT
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_versions_document ON document_versions(document_id, version_number DESC)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_versions_type ON document_versions(document_type)',
    );
  }

  /// Closes the database connection.
  Future<void> close() async {
    final db = _database;
    if (db != null && db.isOpen) {
      await db.close();
      _database = null;
    }
  }

  /// Deletes the database (primarily for testing).
  Future<void> deleteDatabase() async {
    await close();
    if (!kIsWeb) {
      final directory = await getApplicationDocumentsDirectory();
      final dbPath = p.join(directory.path, 'FileUtility', _dbName);
      await databaseFactory.deleteDatabase(dbPath);
    }
  }
}
