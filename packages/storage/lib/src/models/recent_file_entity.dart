import 'package:equatable/equatable.dart';

/// Represents a recently opened file in the database.
class RecentFileEntity extends Equatable {
  /// Creates a [RecentFileEntity] instance.
  const RecentFileEntity({
    required this.id,
    required this.fileName,
    required this.filePath,
    required this.fileType,
    required this.lastOpenedAt,
    required this.createdAt,
    this.sizeBytes,
    this.isFavorite = false,
  });

  /// Creates a [RecentFileEntity] from a database row map.
  factory RecentFileEntity.fromMap(Map<String, dynamic> map) {
    return RecentFileEntity(
      id: map['id'] as String,
      fileName: map['file_name'] as String,
      filePath: map['file_path'] as String,
      fileType: map['file_type'] as String,
      sizeBytes: map['size_bytes'] as int?,
      isFavorite: (map['is_favorite'] as int?) == 1,
      lastOpenedAt: DateTime.parse(map['last_opened_at'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  /// Unique identifier.
  final String id;

  /// Display name of the file.
  final String fileName;

  /// Full file path.
  final String filePath;

  /// File type string (e.g., 'text', 'markdown', 'pdf').
  final String fileType;

  /// File size in bytes, if known.
  final int? sizeBytes;

  /// Whether this file is a favorite.
  final bool isFavorite;

  /// When the file was last opened.
  final DateTime lastOpenedAt;

  /// When this record was first created.
  final DateTime createdAt;

  /// Converts this entity to a database row map.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'file_name': fileName,
      'file_path': filePath,
      'file_type': fileType,
      'size_bytes': sizeBytes,
      'is_favorite': isFavorite ? 1 : 0,
      'last_opened_at': lastOpenedAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Returns a copy with the specified fields overridden.
  RecentFileEntity copyWith({
    String? id,
    String? fileName,
    String? filePath,
    String? fileType,
    int? sizeBytes,
    bool? isFavorite,
    DateTime? lastOpenedAt,
    DateTime? createdAt,
  }) {
    return RecentFileEntity(
      id: id ?? this.id,
      fileName: fileName ?? this.fileName,
      filePath: filePath ?? this.filePath,
      fileType: fileType ?? this.fileType,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      isFavorite: isFavorite ?? this.isFavorite,
      lastOpenedAt: lastOpenedAt ?? this.lastOpenedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id, fileName, filePath, fileType,
        sizeBytes, isFavorite, lastOpenedAt, createdAt,
      ];
}
