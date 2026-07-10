import 'package:equatable/equatable.dart';

import 'file_type.dart';

/// Metadata associated with a document or file in the application.
///
/// Used across all modules to track file information, timestamps,
/// and user-facing display properties.
class DocumentMetadata extends Equatable {
  /// Creates a [DocumentMetadata] instance.
  const DocumentMetadata({
    required this.id,
    required this.title,
    required this.fileType,
    required this.createdAt,
    required this.modifiedAt,
    this.filePath,
    this.sizeBytes,
    this.isFavorite = false,
    this.tags = const [],
  });

  /// Unique identifier for this document.
  final String id;

  /// Display title of the document.
  final String title;

  /// The file type of the document.
  final FileType fileType;

  /// When the document was first created.
  final DateTime createdAt;

  /// When the document was last modified.
  final DateTime modifiedAt;

  /// Optional file system path.
  final String? filePath;

  /// File size in bytes, if known.
  final int? sizeBytes;

  /// Whether this document is marked as a favorite.
  final bool isFavorite;

  /// User-assigned tags.
  final List<String> tags;

  /// Human-readable file size string.
  String get formattedSize {
    if (sizeBytes == null) return 'Unknown';
    final bytes = sizeBytes!;
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Returns a copy with the specified fields overridden.
  DocumentMetadata copyWith({
    String? id,
    String? title,
    FileType? fileType,
    DateTime? createdAt,
    DateTime? modifiedAt,
    String? filePath,
    int? sizeBytes,
    bool? isFavorite,
    List<String>? tags,
  }) {
    return DocumentMetadata(
      id: id ?? this.id,
      title: title ?? this.title,
      fileType: fileType ?? this.fileType,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      filePath: filePath ?? this.filePath,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      isFavorite: isFavorite ?? this.isFavorite,
      tags: tags ?? this.tags,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        fileType,
        createdAt,
        modifiedAt,
        filePath,
        sizeBytes,
        isFavorite,
        tags,
      ];
}
