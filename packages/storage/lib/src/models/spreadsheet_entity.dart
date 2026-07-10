import 'package:equatable/equatable.dart';

/// Represents a spreadsheet workbook stored in the database.
class SpreadsheetEntity extends Equatable {
  /// Unique identifier.
  final String id;

  /// Workbook title.
  final String title;

  /// JSON-encoded sheet data (list of sheets with cells).
  final String content;

  /// Number of sheets.
  final int sheetCount;

  /// Whether this workbook is favorited.
  final bool isFavorite;

  /// Custom tags.
  final String? tags;

  /// ISO 8601 creation timestamp.
  final DateTime createdAt;

  /// ISO 8601 last modification timestamp.
  final DateTime modifiedAt;

  const SpreadsheetEntity({
    required this.id,
    required this.title,
    required this.content,
    this.sheetCount = 1,
    this.isFavorite = false,
    this.tags,
    required this.createdAt,
    required this.modifiedAt,
  });

  factory SpreadsheetEntity.fromMap(Map<String, dynamic> map) {
    return SpreadsheetEntity(
      id: map['id'] as String,
      title: map['title'] as String,
      content: map['content'] as String,
      sheetCount: (map['sheet_count'] as int?) ?? 1,
      isFavorite: (map['is_favorite'] as int?) == 1,
      tags: map['tags'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      modifiedAt: DateTime.parse(map['modified_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'sheet_count': sheetCount,
      'is_favorite': isFavorite ? 1 : 0,
      'tags': tags,
      'created_at': createdAt.toIso8601String(),
      'modified_at': modifiedAt.toIso8601String(),
    };
  }

  SpreadsheetEntity copyWith({
    String? title,
    String? content,
    int? sheetCount,
    bool? isFavorite,
    String? tags,
    DateTime? modifiedAt,
  }) {
    return SpreadsheetEntity(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
      sheetCount: sheetCount ?? this.sheetCount,
      isFavorite: isFavorite ?? this.isFavorite,
      tags: tags ?? this.tags,
      createdAt: createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
    );
  }

  @override
  List<Object?> get props =>
      [id, title, content, sheetCount, isFavorite, modifiedAt];
}
