import 'package:equatable/equatable.dart';

/// Represents a rich text document stored in the database.
///
/// Documents are stored with their content as JSON-encoded Delta format,
/// supporting rich formatting, lists, images, and other block elements.
class DocumentEntity extends Equatable {
  /// Unique identifier.
  final String id;

  /// Document title.
  final String title;

  /// JSON-encoded rich text content (Delta format).
  final String content;

  /// Plain text extract for search indexing.
  final String plainText;

  /// Document format type: 'rich', 'docx', 'rtf', 'odt'.
  final String format;

  /// Word count.
  final int wordCount;

  /// Character count.
  final int characterCount;

  /// Whether the document is starred/favorited.
  final bool isFavorite;

  /// Custom tags for organization.
  final String? tags;

  /// ISO 8601 creation timestamp.
  final DateTime createdAt;

  /// ISO 8601 last modification timestamp.
  final DateTime modifiedAt;

  /// Creates a [DocumentEntity].
  const DocumentEntity({
    required this.id,
    required this.title,
    required this.content,
    this.plainText = '',
    this.format = 'rich',
    this.wordCount = 0,
    this.characterCount = 0,
    this.isFavorite = false,
    this.tags,
    required this.createdAt,
    required this.modifiedAt,
  });

  /// Creates from a database map.
  factory DocumentEntity.fromMap(Map<String, dynamic> map) {
    return DocumentEntity(
      id: map['id'] as String,
      title: map['title'] as String,
      content: map['content'] as String,
      plainText: (map['plain_text'] as String?) ?? '',
      format: (map['format'] as String?) ?? 'rich',
      wordCount: (map['word_count'] as int?) ?? 0,
      characterCount: (map['character_count'] as int?) ?? 0,
      isFavorite: (map['is_favorite'] as int?) == 1,
      tags: map['tags'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      modifiedAt: DateTime.parse(map['modified_at'] as String),
    );
  }

  /// Converts to a database map.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'plain_text': plainText,
      'format': format,
      'word_count': wordCount,
      'character_count': characterCount,
      'is_favorite': isFavorite ? 1 : 0,
      'tags': tags,
      'created_at': createdAt.toIso8601String(),
      'modified_at': modifiedAt.toIso8601String(),
    };
  }

  /// Creates a copy with optional overrides.
  DocumentEntity copyWith({
    String? title,
    String? content,
    String? plainText,
    String? format,
    int? wordCount,
    int? characterCount,
    bool? isFavorite,
    String? tags,
    DateTime? modifiedAt,
  }) {
    return DocumentEntity(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
      plainText: plainText ?? this.plainText,
      format: format ?? this.format,
      wordCount: wordCount ?? this.wordCount,
      characterCount: characterCount ?? this.characterCount,
      isFavorite: isFavorite ?? this.isFavorite,
      tags: tags ?? this.tags,
      createdAt: createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
    );
  }

  @override
  List<Object?> get props =>
      [id, title, content, format, isFavorite, modifiedAt];
}
