import 'package:sqflite/sqflite.dart';

import 'database_provider.dart';
import '../models/spreadsheet_entity.dart';

/// Data access object for spreadsheet workbooks.
class SpreadsheetDao {
  /// Retrieves all spreadsheets, ordered by modification date.
  Future<List<SpreadsheetEntity>> getAllSpreadsheets() async {
    final db = await DatabaseProvider.instance.database;
    final maps = await db.query('spreadsheets', orderBy: 'modified_at DESC');
    return maps.map(SpreadsheetEntity.fromMap).toList();
  }

  /// Retrieves a single spreadsheet by [id].
  Future<SpreadsheetEntity?> getSpreadsheet(String id) async {
    final db = await DatabaseProvider.instance.database;
    final maps = await db.query(
      'spreadsheets',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return SpreadsheetEntity.fromMap(maps.first);
  }

  /// Searches spreadsheets by title.
  Future<List<SpreadsheetEntity>> searchSpreadsheets(String query) async {
    final db = await DatabaseProvider.instance.database;
    final maps = await db.query(
      'spreadsheets',
      where: 'title LIKE ?',
      whereArgs: ['%$query%'],
      orderBy: 'modified_at DESC',
    );
    return maps.map(SpreadsheetEntity.fromMap).toList();
  }

  /// Inserts a new spreadsheet.
  Future<void> insertSpreadsheet(SpreadsheetEntity spreadsheet) async {
    final db = await DatabaseProvider.instance.database;
    await db.insert(
      'spreadsheets',
      spreadsheet.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Updates an existing spreadsheet.
  Future<void> updateSpreadsheet(SpreadsheetEntity spreadsheet) async {
    final db = await DatabaseProvider.instance.database;
    await db.update(
      'spreadsheets',
      spreadsheet.toMap(),
      where: 'id = ?',
      whereArgs: [spreadsheet.id],
    );
  }

  /// Toggles favorite status.
  Future<void> toggleFavorite(String id) async {
    final db = await DatabaseProvider.instance.database;
    await db.rawUpdate(
      'UPDATE spreadsheets SET is_favorite = CASE WHEN is_favorite = 1 THEN 0 ELSE 1 END, modified_at = ? WHERE id = ?',
      [DateTime.now().toIso8601String(), id],
    );
  }

  /// Deletes a spreadsheet by [id].
  Future<void> deleteSpreadsheet(String id) async {
    final db = await DatabaseProvider.instance.database;
    await db.delete('spreadsheets', where: 'id = ?', whereArgs: [id]);
  }

  /// Duplicates a spreadsheet.
  Future<SpreadsheetEntity> duplicateSpreadsheet(String id) async {
    final original = await getSpreadsheet(id);
    if (original == null) throw Exception('Spreadsheet not found: $id');
    final now = DateTime.now();
    final copy = SpreadsheetEntity(
      id: now.microsecondsSinceEpoch.toString(),
      title: '${original.title} (Copy)',
      content: original.content,
      sheetCount: original.sheetCount,
      isFavorite: false,
      tags: original.tags,
      createdAt: now,
      modifiedAt: now,
    );
    await insertSpreadsheet(copy);
    return copy;
  }
}
