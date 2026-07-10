import 'package:sqflite/sqflite.dart';

import 'database_provider.dart';
import '../models/document_entity.dart';

/// Data access object for rich text documents.
///
/// Provides CRUD operations, search, and favorite management
/// for documents stored in the local SQLite database.
class DocumentDao {
  /// Retrieves all documents, ordered by modification date (newest first).
  Future<List<DocumentEntity>> getAllDocuments() async {
    final db = await DatabaseProvider.instance.database;
    final maps = await db.query(
      'documents',
      orderBy: 'modified_at DESC',
    );
    return maps.map(DocumentEntity.fromMap).toList();
  }

  /// Retrieves a single document by [id].
  Future<DocumentEntity?> getDocument(String id) async {
    final db = await DatabaseProvider.instance.database;
    final maps = await db.query(
      'documents',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return DocumentEntity.fromMap(maps.first);
  }

  /// Retrieves only favorited documents.
  Future<List<DocumentEntity>> getFavoriteDocuments() async {
    final db = await DatabaseProvider.instance.database;
    final maps = await db.query(
      'documents',
      where: 'is_favorite = 1',
      orderBy: 'modified_at DESC',
    );
    return maps.map(DocumentEntity.fromMap).toList();
  }

  /// Searches documents by title or plain text content.
  Future<List<DocumentEntity>> searchDocuments(String query) async {
    final db = await DatabaseProvider.instance.database;
    final searchTerm = '%$query%';
    final maps = await db.query(
      'documents',
      where: 'title LIKE ? OR plain_text LIKE ? OR tags LIKE ?',
      whereArgs: [searchTerm, searchTerm, searchTerm],
      orderBy: 'modified_at DESC',
    );
    return maps.map(DocumentEntity.fromMap).toList();
  }

  /// Retrieves documents filtered by format.
  Future<List<DocumentEntity>> getDocumentsByFormat(String format) async {
    final db = await DatabaseProvider.instance.database;
    final maps = await db.query(
      'documents',
      where: 'format = ?',
      whereArgs: [format],
      orderBy: 'modified_at DESC',
    );
    return maps.map(DocumentEntity.fromMap).toList();
  }

  /// Inserts a new document.
  Future<void> insertDocument(DocumentEntity document) async {
    final db = await DatabaseProvider.instance.database;
    await db.insert(
      'documents',
      document.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Updates an existing document.
  Future<void> updateDocument(DocumentEntity document) async {
    final db = await DatabaseProvider.instance.database;
    await db.update(
      'documents',
      document.toMap(),
      where: 'id = ?',
      whereArgs: [document.id],
    );
  }

  /// Toggles the favorite status of a document.
  Future<void> toggleFavorite(String id) async {
    final db = await DatabaseProvider.instance.database;
    await db.rawUpdate(
      'UPDATE documents SET is_favorite = CASE WHEN is_favorite = 1 THEN 0 ELSE 1 END, modified_at = ? WHERE id = ?',
      [DateTime.now().toIso8601String(), id],
    );
  }

  /// Deletes a document by [id].
  Future<void> deleteDocument(String id) async {
    final db = await DatabaseProvider.instance.database;
    await db.delete('documents', where: 'id = ?', whereArgs: [id]);
  }

  /// Returns the total count of documents.
  Future<int> getDocumentCount() async {
    final db = await DatabaseProvider.instance.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM documents');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Duplicates a document with a new ID and modified title.
  Future<DocumentEntity> duplicateDocument(String id) async {
    final original = await getDocument(id);
    if (original == null) throw Exception('Document not found: $id');

    final now = DateTime.now();
    final copy = DocumentEntity(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: '${original.title} (Copy)',
      content: original.content,
      plainText: original.plainText,
      format: original.format,
      wordCount: original.wordCount,
      characterCount: original.characterCount,
      isFavorite: false,
      tags: original.tags,
      createdAt: now,
      modifiedAt: now,
    );
    await insertDocument(copy);
    return copy;
  }
}
