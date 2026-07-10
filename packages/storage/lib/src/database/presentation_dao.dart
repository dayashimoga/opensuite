import 'package:sqflite/sqflite.dart';

import 'database_provider.dart';
import '../models/presentation_entity.dart';

/// Data access object for presentations.
class PresentationDao {
  Future<List<PresentationEntity>> getAllPresentations() async {
    final db = await DatabaseProvider.instance.database;
    final maps = await db.query('presentations', orderBy: 'modified_at DESC');
    return maps.map(PresentationEntity.fromMap).toList();
  }

  Future<PresentationEntity?> getPresentation(String id) async {
    final db = await DatabaseProvider.instance.database;
    final maps = await db.query('presentations',
        where: 'id = ?', whereArgs: [id], limit: 1);
    if (maps.isEmpty) return null;
    return PresentationEntity.fromMap(maps.first);
  }

  Future<List<PresentationEntity>> searchPresentations(String query) async {
    final db = await DatabaseProvider.instance.database;
    final maps = await db.query(
      'presentations',
      where: 'title LIKE ?',
      whereArgs: ['%$query%'],
      orderBy: 'modified_at DESC',
    );
    return maps.map(PresentationEntity.fromMap).toList();
  }

  Future<void> insertPresentation(PresentationEntity presentation) async {
    final db = await DatabaseProvider.instance.database;
    await db.insert('presentations', presentation.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updatePresentation(PresentationEntity presentation) async {
    final db = await DatabaseProvider.instance.database;
    await db.update('presentations', presentation.toMap(),
        where: 'id = ?', whereArgs: [presentation.id]);
  }

  Future<void> toggleFavorite(String id) async {
    final db = await DatabaseProvider.instance.database;
    await db.rawUpdate(
      'UPDATE presentations SET is_favorite = CASE WHEN is_favorite = 1 THEN 0 ELSE 1 END, modified_at = ? WHERE id = ?',
      [DateTime.now().toIso8601String(), id],
    );
  }

  Future<void> deletePresentation(String id) async {
    final db = await DatabaseProvider.instance.database;
    await db.delete('presentations', where: 'id = ?', whereArgs: [id]);
  }

  Future<PresentationEntity> duplicatePresentation(String id) async {
    final original = await getPresentation(id);
    if (original == null) throw Exception('Presentation not found: $id');
    final now = DateTime.now();
    final copy = PresentationEntity(
      id: now.microsecondsSinceEpoch.toString(),
      title: '${original.title} (Copy)',
      content: original.content,
      slideCount: original.slideCount,
      theme: original.theme,
      createdAt: now,
      modifiedAt: now,
    );
    await insertPresentation(copy);
    return copy;
  }
}
