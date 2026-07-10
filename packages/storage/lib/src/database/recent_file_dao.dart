import 'package:uuid/uuid.dart';

import '../models/recent_file_entity.dart';
import 'database_provider.dart';

/// Data Access Object for recent files tracking.
///
/// Manages the history of recently opened files, including
/// favorites and search functionality.
class RecentFileDao {
  /// Creates a [RecentFileDao] with the given database provider.
  RecentFileDao({DatabaseProvider? provider})
      : _provider = provider ?? DatabaseProvider.instance;

  final DatabaseProvider _provider;
  static const _table = 'recent_files';
  static const _uuid = Uuid();
  static const int _maxEntries = 50;

  /// Retrieves all recent files, ordered by last opened date.
  Future<List<RecentFileEntity>> getAll() async {
    final db = await _provider.database;
    final maps = await db.query(
      _table,
      orderBy: 'last_opened_at DESC',
      limit: _maxEntries,
    );
    return maps.map(RecentFileEntity.fromMap).toList();
  }

  /// Records a file as recently opened.
  ///
  /// If the file path already exists, updates the last opened timestamp.
  /// Otherwise, creates a new entry.
  Future<RecentFileEntity> recordOpened({
    required String fileName,
    required String filePath,
    required String fileType,
    int? sizeBytes,
  }) async {
    final db = await _provider.database;

    // Check if file already exists in recents
    final existing = await db.query(
      _table,
      where: 'file_path = ?',
      whereArgs: [filePath],
      limit: 1,
    );

    final now = DateTime.now();

    if (existing.isNotEmpty) {
      final entity = RecentFileEntity.fromMap(existing.first);
      final updated = entity.copyWith(
        lastOpenedAt: now,
        fileName: fileName,
        sizeBytes: sizeBytes,
      );
      await db.update(
        _table,
        updated.toMap(),
        where: 'id = ?',
        whereArgs: [entity.id],
      );
      return updated;
    }

    final entity = RecentFileEntity(
      id: _uuid.v4(),
      fileName: fileName,
      filePath: filePath,
      fileType: fileType,
      sizeBytes: sizeBytes,
      lastOpenedAt: now,
      createdAt: now,
    );

    await db.insert(_table, entity.toMap());

    // Trim old entries beyond max
    await _trimEntries(db);

    return entity;
  }

  /// Toggles the favorite status of a recent file.
  Future<void> toggleFavorite(String id) async {
    final db = await _provider.database;
    await db.rawUpdate(
      'UPDATE $_table SET is_favorite = CASE WHEN is_favorite = 1 THEN 0 ELSE 1 END '
      'WHERE id = ?',
      [id],
    );
  }

  /// Removes a file from recents.
  Future<int> delete(String id) async {
    final db = await _provider.database;
    return db.delete(_table, where: 'id = ?', whereArgs: [id]);
  }

  /// Clears all recent files (preserving favorites).
  Future<void> clearNonFavorites() async {
    final db = await _provider.database;
    await db.delete(_table, where: 'is_favorite = 0');
  }

  /// Retrieves favorite files.
  Future<List<RecentFileEntity>> getFavorites() async {
    final db = await _provider.database;
    final maps = await db.query(
      _table,
      where: 'is_favorite = 1',
      orderBy: 'last_opened_at DESC',
    );
    return maps.map(RecentFileEntity.fromMap).toList();
  }

  /// Searches recent files by name.
  Future<List<RecentFileEntity>> search(String query) async {
    if (query.trim().isEmpty) return getAll();
    final db = await _provider.database;
    final maps = await db.query(
      _table,
      where: 'file_name LIKE ?',
      whereArgs: ['%$query%'],
      orderBy: 'last_opened_at DESC',
    );
    return maps.map(RecentFileEntity.fromMap).toList();
  }

  Future<void> _trimEntries(dynamic db) async {
    final count = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $_table WHERE is_favorite = 0',
    );
    final total = count.first['count'] as int;
    if (total > _maxEntries) {
      await db.rawDelete(
        'DELETE FROM $_table WHERE id IN ('
        '  SELECT id FROM $_table WHERE is_favorite = 0 '
        '  ORDER BY last_opened_at ASC LIMIT ?'
        ')',
        [total - _maxEntries],
      );
    }
  }
}
