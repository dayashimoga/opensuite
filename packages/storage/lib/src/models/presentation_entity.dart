import 'package:equatable/equatable.dart';

/// Represents a presentation stored in the database.
class PresentationEntity extends Equatable {
  final String id;
  final String title;
  final String content; // JSON-encoded slides
  final int slideCount;
  final String theme; // 'default', 'dark', 'corporate', 'creative'
  final bool isFavorite;
  final String? tags;
  final DateTime createdAt;
  final DateTime modifiedAt;

  const PresentationEntity({
    required this.id,
    required this.title,
    required this.content,
    this.slideCount = 1,
    this.theme = 'default',
    this.isFavorite = false,
    this.tags,
    required this.createdAt,
    required this.modifiedAt,
  });

  factory PresentationEntity.fromMap(Map<String, dynamic> map) {
    return PresentationEntity(
      id: map['id'] as String,
      title: map['title'] as String,
      content: map['content'] as String,
      slideCount: (map['slide_count'] as int?) ?? 1,
      theme: (map['theme'] as String?) ?? 'default',
      isFavorite: (map['is_favorite'] as int?) == 1,
      tags: map['tags'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      modifiedAt: DateTime.parse(map['modified_at'] as String),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'content': content,
        'slide_count': slideCount,
        'theme': theme,
        'is_favorite': isFavorite ? 1 : 0,
        'tags': tags,
        'created_at': createdAt.toIso8601String(),
        'modified_at': modifiedAt.toIso8601String(),
      };

  PresentationEntity copyWith({
    String? title,
    String? content,
    int? slideCount,
    String? theme,
    bool? isFavorite,
    String? tags,
    DateTime? modifiedAt,
  }) {
    return PresentationEntity(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
      slideCount: slideCount ?? this.slideCount,
      theme: theme ?? this.theme,
      isFavorite: isFavorite ?? this.isFavorite,
      tags: tags ?? this.tags,
      createdAt: createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
    );
  }

  @override
  List<Object?> get props => [id, title, slideCount, theme, isFavorite, modifiedAt];
}
