import 'package:uuid/uuid.dart';

import '../models/note_entity.dart';
import 'database_provider.dart';

/// Data Access Object for notes CRUD operations.
///
/// Provides methods to create, read, update, and delete notes
/// in the SQLite database. All operations are performed through
/// the [DatabaseProvider] singleton.
class NoteDao {
  /// Creates a [NoteDao] with the given database provider.
  NoteDao({DatabaseProvider? provider})
      : _provider = provider ?? DatabaseProvider.instance;

  final DatabaseProvider _provider;
  static const _table = 'notes';
  static const _uuid = Uuid();

  /// Retrieves all notes, ordered by pinned status then modification date.
  Future<List<NoteEntity>> getAll() async {
    final db = await _provider.database;
    final maps = await db.query(
      _table,
      orderBy: 'is_pinned DESC, modified_at DESC',
    );
    return maps.map(NoteEntity.fromMap).toList();
  }

  /// Retrieves a single note by its ID.
  ///
  /// Returns null if the note does not exist.
  Future<NoteEntity?> getById(String id) async {
    final db = await _provider.database;
    final maps = await db.query(
      _table,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return NoteEntity.fromMap(maps.first);
  }

  /// Creates a new note and returns it with a generated ID.
  Future<NoteEntity> create({
    String title = '',
    String content = '',
    NoteContentType contentType = NoteContentType.plain,
    String? color,
    List<String> tags = const [],
  }) async {
    final now = DateTime.now();
    final note = NoteEntity(
      id: _uuid.v4(),
      title: title,
      content: content,
      contentType: contentType,
      color: color,
      tags: tags,
      createdAt: now,
      modifiedAt: now,
    );

    final db = await _provider.database;
    await db.insert(_table, note.toMap());
    return note;
  }

  /// Updates an existing note.
  ///
  /// Returns the number of rows affected (0 if not found).
  Future<int> update(NoteEntity note) async {
    final updatedNote = note.copyWith(modifiedAt: DateTime.now());
    final db = await _provider.database;
    return db.update(
      _table,
      updatedNote.toMap(),
      where: 'id = ?',
      whereArgs: [note.id],
    );
  }

  /// Deletes a note by its ID.
  ///
  /// Returns the number of rows affected (0 if not found).
  Future<int> delete(String id) async {
    final db = await _provider.database;
    return db.delete(_table, where: 'id = ?', whereArgs: [id]);
  }

  /// Deletes multiple notes by their IDs.
  Future<int> deleteMultiple(List<String> ids) async {
    if (ids.isEmpty) return 0;
    final db = await _provider.database;
    final placeholders = ids.map((_) => '?').join(',');
    return db.delete(
      _table,
      where: 'id IN ($placeholders)',
      whereArgs: ids,
    );
  }

  /// Searches notes by title and content.
  Future<List<NoteEntity>> search(String query) async {
    if (query.trim().isEmpty) return getAll();
    final db = await _provider.database;
    final maps = await db.query(
      _table,
      where: 'title LIKE ? OR content LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'is_pinned DESC, modified_at DESC',
    );
    return maps.map(NoteEntity.fromMap).toList();
  }

  /// Toggles the pinned status of a note.
  Future<void> togglePin(String id) async {
    final db = await _provider.database;
    await db.rawUpdate(
      'UPDATE $_table SET is_pinned = CASE WHEN is_pinned = 1 THEN 0 ELSE 1 END, '
      'modified_at = ? WHERE id = ?',
      [DateTime.now().toIso8601String(), id],
    );
  }

  /// Toggles the favorite status of a note.
  Future<void> toggleFavorite(String id) async {
    final db = await _provider.database;
    await db.rawUpdate(
      'UPDATE $_table SET is_favorite = CASE WHEN is_favorite = 1 THEN 0 ELSE 1 END, '
      'modified_at = ? WHERE id = ?',
      [DateTime.now().toIso8601String(), id],
    );
  }

  /// Returns the total number of notes.
  Future<int> count() async {
    final db = await _provider.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM $_table');
    return result.first['count'] as int;
  }

  /// Retrieves only favorite notes.
  Future<List<NoteEntity>> getFavorites() async {
    final db = await _provider.database;
    final maps = await db.query(
      _table,
      where: 'is_favorite = 1',
      orderBy: 'modified_at DESC',
    );
    return maps.map(NoteEntity.fromMap).toList();
  }
}
