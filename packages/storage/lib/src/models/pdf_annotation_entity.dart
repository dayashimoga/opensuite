import 'package:equatable/equatable.dart';

/// Entity representing a PDF annotation stored in the database.
class PdfAnnotationEntity extends Equatable {
  /// Unique identifier.
  final String id;

  /// Path of the PDF file this annotation belongs to.
  final String filePath;

  /// Page number (0-indexed).
  final int pageNumber;

  /// Annotation type: 'highlight', 'underline', 'note', 'freehand'.
  final String type;

  /// Text content (for sticky notes or highlighted text).
  final String content;

  /// Position and size (normalized 0–1 relative to page).
  final double x;
  final double y;
  final double width;
  final double height;

  /// Color hex string (e.g., '#FFFF00').
  final String? color;

  /// JSON-encoded stroke points for freehand annotations.
  final String? strokePoints;

  /// Timestamps.
  final DateTime createdAt;
  final DateTime modifiedAt;

  const PdfAnnotationEntity({
    required this.id,
    required this.filePath,
    required this.pageNumber,
    this.type = 'highlight',
    this.content = '',
    this.x = 0,
    this.y = 0,
    this.width = 0,
    this.height = 0,
    this.color,
    this.strokePoints,
    required this.createdAt,
    required this.modifiedAt,
  });

  /// Creates an entity from a database map.
  factory PdfAnnotationEntity.fromMap(Map<String, dynamic> map) {
    return PdfAnnotationEntity(
      id: map['id'] as String,
      filePath: map['file_path'] as String,
      pageNumber: map['page_number'] as int,
      type: map['type'] as String? ?? 'highlight',
      content: map['content'] as String? ?? '',
      x: (map['x'] as num?)?.toDouble() ?? 0,
      y: (map['y'] as num?)?.toDouble() ?? 0,
      width: (map['width'] as num?)?.toDouble() ?? 0,
      height: (map['height'] as num?)?.toDouble() ?? 0,
      color: map['color'] as String?,
      strokePoints: map['stroke_points'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      modifiedAt: DateTime.parse(map['modified_at'] as String),
    );
  }

  /// Converts entity to database map.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'file_path': filePath,
      'page_number': pageNumber,
      'type': type,
      'content': content,
      'x': x,
      'y': y,
      'width': width,
      'height': height,
      'color': color,
      'stroke_points': strokePoints,
      'created_at': createdAt.toIso8601String(),
      'modified_at': modifiedAt.toIso8601String(),
    };
  }

  PdfAnnotationEntity copyWith({
    String? id,
    String? filePath,
    int? pageNumber,
    String? type,
    String? content,
    double? x,
    double? y,
    double? width,
    double? height,
    String? color,
    String? strokePoints,
    DateTime? createdAt,
    DateTime? modifiedAt,
  }) {
    return PdfAnnotationEntity(
      id: id ?? this.id,
      filePath: filePath ?? this.filePath,
      pageNumber: pageNumber ?? this.pageNumber,
      type: type ?? this.type,
      content: content ?? this.content,
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      color: color ?? this.color,
      strokePoints: strokePoints ?? this.strokePoints,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        filePath,
        pageNumber,
        type,
        content,
        x,
        y,
        width,
        height,
        color,
        strokePoints,
        createdAt,
        modifiedAt,
      ];
}
