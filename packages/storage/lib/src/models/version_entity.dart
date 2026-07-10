import 'package:equatable/equatable.dart';

/// Represents a version snapshot of a document.
class VersionEntity extends Equatable {
  /// Unique identifier for this version.
  final String id;

  /// The document ID this version belongs to.
  final String documentId;

  /// The type of document: 'note', 'document', 'spreadsheet', 'presentation'.
  final String documentType;

  /// The full content snapshot at this version.
  final String content;

  /// The title at the time of this version.
  final String title;

  /// The version number (1, 2, 3...).
  final int versionNumber;

  /// Size of the content in bytes.
  final int contentSize;

  /// When this version was created.
  final DateTime createdAt;

  /// Optional label for this version (e.g., 'Before reformatting').
  final String? label;

  const VersionEntity({
    required this.id,
    required this.documentId,
    required this.documentType,
    required this.content,
    required this.title,
    required this.versionNumber,
    required this.contentSize,
    required this.createdAt,
    this.label,
  });

  /// Creates a [VersionEntity] from a database row.
  factory VersionEntity.fromMap(Map<String, dynamic> map) {
    return VersionEntity(
      id: map['id'] as String,
      documentId: map['document_id'] as String,
      documentType: map['document_type'] as String,
      content: map['content'] as String,
      title: map['title'] as String,
      versionNumber: map['version_number'] as int,
      contentSize: map['content_size'] as int,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      label: map['label'] as String?,
    );
  }

  /// Converts to a database-storable map.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'document_id': documentId,
      'document_type': documentType,
      'content': content,
      'title': title,
      'version_number': versionNumber,
      'content_size': contentSize,
      'created_at': createdAt.millisecondsSinceEpoch,
      'label': label,
    };
  }

  @override
  List<Object?> get props => [id, documentId, documentType, versionNumber];
}
