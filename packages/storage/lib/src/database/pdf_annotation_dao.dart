import '../models/pdf_annotation_entity.dart';
import 'database_provider.dart';

/// Data access object for PDF annotation persistence.
///
/// Provides CRUD operations for PDF annotations, organized by file path
/// and page number for efficient retrieval.
class PdfAnnotationDao {
  final DatabaseProvider _dbProvider = DatabaseProvider.instance;

  static const String _table = 'pdf_annotations';

  /// Retrieves all annotations for a given file path.
  Future<List<PdfAnnotationEntity>> getAnnotationsForFile(
      String filePath) async {
    final db = await _dbProvider.database;
    final maps = await db.query(
      _table,
      where: 'file_path = ?',
      whereArgs: [filePath],
      orderBy: 'page_number ASC, created_at ASC',
    );
    return maps.map((m) => PdfAnnotationEntity.fromMap(m)).toList();
  }

  /// Retrieves annotations for a specific page.
  Future<List<PdfAnnotationEntity>> getAnnotationsForPage(
      String filePath, int pageNumber) async {
    final db = await _dbProvider.database;
    final maps = await db.query(
      _table,
      where: 'file_path = ? AND page_number = ?',
      whereArgs: [filePath, pageNumber],
      orderBy: 'created_at ASC',
    );
    return maps.map((m) => PdfAnnotationEntity.fromMap(m)).toList();
  }

  /// Inserts a new annotation.
  Future<void> insertAnnotation(PdfAnnotationEntity annotation) async {
    final db = await _dbProvider.database;
    await db.insert(_table, annotation.toMap());
  }

  /// Updates an existing annotation.
  Future<void> updateAnnotation(PdfAnnotationEntity annotation) async {
    final db = await _dbProvider.database;
    await db.update(
      _table,
      annotation.toMap(),
      where: 'id = ?',
      whereArgs: [annotation.id],
    );
  }

  /// Deletes an annotation by ID.
  Future<void> deleteAnnotation(String id) async {
    final db = await _dbProvider.database;
    await db.delete(_table, where: 'id = ?', whereArgs: [id]);
  }

  /// Deletes all annotations for a given file.
  Future<void> deleteAllForFile(String filePath) async {
    final db = await _dbProvider.database;
    await db.delete(_table, where: 'file_path = ?', whereArgs: [filePath]);
  }

  /// Returns the count of annotations for a file.
  Future<int> getAnnotationCount(String filePath) async {
    final db = await _dbProvider.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $_table WHERE file_path = ?',
      [filePath],
    );
    return result.first['count'] as int? ?? 0;
  }
}
