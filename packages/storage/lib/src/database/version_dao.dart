import 'package:sqflite/sqflite.dart';

import '../database/database_provider.dart';
import '../models/version_entity.dart';

/// Data access object for document version history.
///
/// Tracks content snapshots for notes, documents, spreadsheets,
/// and presentations. Supports creating, listing, restoring,
/// and pruning old versions.
class VersionDao {
  /// Creates a [VersionDao] with the given database provider.
  VersionDao({DatabaseProvider? provider})
      : _provider = provider ?? DatabaseProvider.instance;

  final DatabaseProvider _provider;
  static const _table = 'document_versions';

  Future<Database> _getDb() => _provider.database;

  /// Creates a new version snapshot.
  ///
  /// Automatically sets the version number based on existing versions.
  Future<VersionEntity> createVersion({
    required String documentId,
    required String documentType,
    required String content,
    required String title,
    String? label,
  }) async {
    final db = await _getDb();

    // Get next version number
    final countResult = await db.rawQuery(
      'SELECT COUNT(*) as cnt FROM $_table WHERE document_id = ?',
      [documentId],
    );
    final nextVersion = (countResult.first['cnt'] as int) + 1;

    final id = '${documentId}_v$nextVersion';
    final entity = VersionEntity(
      id: id,
      documentId: documentId,
      documentType: documentType,
      content: content,
      title: title,
      versionNumber: nextVersion,
      contentSize: content.length,
      createdAt: DateTime.now(),
      label: label,
    );

    await db.insert(_table, entity.toMap());
    return entity;
  }

  /// Gets all versions for a document, newest first.
  Future<List<VersionEntity>> getVersions(String documentId) async {
    final db = await _getDb();
    final results = await db.query(
      _table,
      where: 'document_id = ?',
      whereArgs: [documentId],
      orderBy: 'version_number DESC',
    );
    return results.map(VersionEntity.fromMap).toList();
  }

  /// Gets a specific version by ID.
  Future<VersionEntity?> getVersion(String versionId) async {
    final db = await _getDb();
    final results = await db.query(
      _table,
      where: 'id = ?',
      whereArgs: [versionId],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return VersionEntity.fromMap(results.first);
  }

  /// Gets the latest version for a document.
  Future<VersionEntity?> getLatestVersion(String documentId) async {
    final db = await _getDb();
    final results = await db.query(
      _table,
      where: 'document_id = ?',
      whereArgs: [documentId],
      orderBy: 'version_number DESC',
      limit: 1,
    );
    if (results.isEmpty) return null;
    return VersionEntity.fromMap(results.first);
  }

  /// Gets the total number of versions for a document.
  Future<int> getVersionCount(String documentId) async {
    final db = await _getDb();
    final result = await db.rawQuery(
      'SELECT COUNT(*) as cnt FROM $_table WHERE document_id = ?',
      [documentId],
    );
    return result.first['cnt'] as int;
  }

  /// Updates the label for a version.
  Future<void> updateLabel(String versionId, String? label) async {
    final db = await _getDb();
    await db.update(
      _table,
      {'label': label},
      where: 'id = ?',
      whereArgs: [versionId],
    );
  }

  /// Deletes a specific version.
  Future<void> deleteVersion(String versionId) async {
    final db = await _getDb();
    await db.delete(
      _table,
      where: 'id = ?',
      whereArgs: [versionId],
    );
  }

  /// Deletes all versions for a document.
  Future<void> deleteAllVersions(String documentId) async {
    final db = await _getDb();
    await db.delete(
      _table,
      where: 'document_id = ?',
      whereArgs: [documentId],
    );
  }

  /// Prunes old versions, keeping only the most recent [keepCount] versions.
  Future<int> pruneVersions(String documentId, {int keepCount = 50}) async {
    final db = await _getDb();

    // Get IDs to keep
    final keepResults = await db.query(
      _table,
      columns: ['id'],
      where: 'document_id = ?',
      whereArgs: [documentId],
      orderBy: 'version_number DESC',
      limit: keepCount,
    );

    if (keepResults.length < keepCount) return 0;

    final keepIds = keepResults.map((r) => r['id'] as String).toList();
    final placeholders = keepIds.map((_) => '?').join(',');

    final deleted = await db.delete(
      _table,
      where: 'document_id = ? AND id NOT IN ($placeholders)',
      whereArgs: [documentId, ...keepIds],
    );

    return deleted;
  }

  /// Gets total storage used by all versions in bytes.
  Future<int> getTotalStorageUsed() async {
    final db = await _getDb();
    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(content_size), 0) as total FROM $_table',
    );
    return result.first['total'] as int;
  }
}
