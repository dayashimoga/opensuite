import 'package:equatable/equatable.dart';

/// Represents a note stored in the database.
class NoteEntity extends Equatable {
  /// Creates a [NoteEntity] instance.
  const NoteEntity({
    required this.id,
    required this.title,
    required this.content,
    required this.contentType,
    required this.createdAt,
    required this.modifiedAt,
    this.isPinned = false,
    this.isFavorite = false,
    this.color,
    this.tags = const [],
  });

  /// Creates a [NoteEntity] from a database row map.
  factory NoteEntity.fromMap(Map<String, dynamic> map) {
    return NoteEntity(
      id: map['id'] as String,
      title: map['title'] as String? ?? '',
      content: map['content'] as String? ?? '',
      contentType: NoteContentType.fromString(
        map['content_type'] as String? ?? 'plain',
      ),
      isPinned: (map['is_pinned'] as int?) == 1,
      isFavorite: (map['is_favorite'] as int?) == 1,
      color: map['color'] as String?,
      tags: _parseTags(map['tags'] as String?),
      createdAt: DateTime.parse(map['created_at'] as String),
      modifiedAt: DateTime.parse(map['modified_at'] as String),
    );
  }

  /// Unique identifier.
  final String id;

  /// Note title.
  final String title;

  /// Note content (plain text, markdown, or JSON for rich text).
  final String content;

  /// The content format type.
  final NoteContentType contentType;

  /// Whether this note is pinned to the top.
  final bool isPinned;

  /// Whether this note is a favorite.
  final bool isFavorite;

  /// Optional color hex string for the note card.
  final String? color;

  /// Tags associated with this note.
  final List<String> tags;

  /// When the note was created.
  final DateTime createdAt;

  /// When the note was last modified.
  final DateTime modifiedAt;

  /// Converts this entity to a database row map.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'content_type': contentType.value,
      'is_pinned': isPinned ? 1 : 0,
      'is_favorite': isFavorite ? 1 : 0,
      'color': color,
      'tags': tags.join(','),
      'created_at': createdAt.toIso8601String(),
      'modified_at': modifiedAt.toIso8601String(),
    };
  }

  /// Returns a copy with specified fields overridden.
  NoteEntity copyWith({
    String? id,
    String? title,
    String? content,
    NoteContentType? contentType,
    bool? isPinned,
    bool? isFavorite,
    String? color,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? modifiedAt,
  }) {
    return NoteEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      contentType: contentType ?? this.contentType,
      isPinned: isPinned ?? this.isPinned,
      isFavorite: isFavorite ?? this.isFavorite,
      color: color ?? this.color,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
    );
  }

  /// Preview of the content, truncated to 100 characters.
  String get contentPreview {
    if (content.isEmpty) return 'Empty note';
    final text =
        content.length > 100 ? '${content.substring(0, 100)}…' : content;
    return text.replaceAll('\n', ' ');
  }

  static List<String> _parseTags(String? tagsStr) {
    if (tagsStr == null || tagsStr.isEmpty) return [];
    return tagsStr.split(',').where((t) => t.isNotEmpty).toList();
  }

  @override
  List<Object?> get props => [
        id,
        title,
        content,
        contentType,
        isPinned,
        isFavorite,
        color,
        tags,
        createdAt,
        modifiedAt,
      ];
}

/// Content type for notes.
enum NoteContentType {
  /// Plain text content.
  plain('plain', 'Plain Text'),

  /// Markdown content.
  markdown('markdown', 'Markdown'),

  /// Rich text content (Quill Delta JSON).
  richText('rich_text', 'Rich Text'),

  /// Checklist content.
  checklist('checklist', 'Checklist');

  const NoteContentType(this.value, this.label);

  /// The stored string value.
  final String value;

  /// Human-readable label.
  final String label;

  /// Parses a string value to a [NoteContentType].
  static NoteContentType fromString(String value) {
    return NoteContentType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => NoteContentType.plain,
    );
  }
}
