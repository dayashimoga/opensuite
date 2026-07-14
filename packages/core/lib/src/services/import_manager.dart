import 'dart:typed_data';

import 'export_manager.dart';

/// Result of a file pick operation.
class PickedFile {
  /// The file name (with extension).
  final String name;

  /// The file extension (lowercase, without dot).
  final String extension;

  /// The raw file bytes.
  final Uint8List bytes;

  /// The original file path (may be null on web).
  final String? path;

  /// The detected export format (if recognized).
  final ExportFormat? format;

  const PickedFile({
    required this.name,
    required this.extension,
    required this.bytes,
    this.path,
    this.format,
  });
}

/// Result of an import operation.
class ImportResult<T> {
  /// Whether the import succeeded.
  final bool success;

  /// The imported data (if successful).
  final T? data;

  /// The source file name.
  final String? fileName;

  /// Error message if import failed.
  final String? error;

  const ImportResult._({
    required this.success,
    this.data,
    this.fileName,
    this.error,
  });

  factory ImportResult.success(T data, {String? fileName}) {
    return ImportResult._(success: true, data: data, fileName: fileName);
  }

  factory ImportResult.failure(String error) {
    return ImportResult._(success: false, error: error);
  }
}

/// File type filter for the file picker.
class ImportFilter {
  /// Display label for the filter group.
  final String label;

  /// Allowed file extensions (without dots).
  final List<String> extensions;

  const ImportFilter({required this.label, required this.extensions});

  /// Common import filters.
  static const documents = ImportFilter(
    label: 'Documents',
    extensions: ['docx', 'doc', 'txt', 'md', 'rtf', 'odt', 'html', 'htm'],
  );

  static const spreadsheets = ImportFilter(
    label: 'Spreadsheets',
    extensions: ['xlsx', 'xls', 'csv', 'tsv', 'ods'],
  );

  static const presentations = ImportFilter(
    label: 'Presentations',
    extensions: ['pptx', 'ppt', 'odp'],
  );

  static const images = ImportFilter(
    label: 'Images',
    extensions: [
      'png',
      'jpg',
      'jpeg',
      'gif',
      'bmp',
      'webp',
      'tiff',
      'tif',
      'svg',
    ],
  );

  static const pdfs = ImportFilter(
    label: 'PDF Files',
    extensions: ['pdf'],
  );

  static const all = ImportFilter(
    label: 'All Supported',
    extensions: [
      'docx',
      'doc',
      'txt',
      'md',
      'rtf',
      'xlsx',
      'xls',
      'csv',
      'pptx',
      'ppt',
      'pdf',
      'png',
      'jpg',
      'jpeg',
      'gif',
      'bmp',
      'webp',
      'tiff',
      'svg',
    ],
  );
}

/// Manages import operations across all editors.
///
/// Provides file picking abstraction, format detection, and
/// parser dispatch via the [ExportManager]'s codec registry.
class ImportManager {
  ImportManager._();

  static final ImportManager _instance = ImportManager._();

  /// Singleton instance.
  static ImportManager get instance => _instance;

  /// Reference to the export manager for codec lookup.
  ExportManager get _exportManager => ExportManager.instance;

  /// Detects the [ExportFormat] from a file name.
  ExportFormat? detectFormat(String fileName) {
    final dotIndex = fileName.lastIndexOf('.');
    if (dotIndex < 0) return null;
    final ext = fileName.substring(dotIndex + 1);
    return _exportManager.formatFromExtension(ext);
  }

  /// Imports a [PickedFile] using the appropriate codec.
  ///
  /// If [format] is null, it will be auto-detected from the file name.
  Future<ImportResult<T>> importFile<T>(
    PickedFile file, {
    ExportFormat? format,
  }) async {
    final resolvedFormat = format ?? file.format ?? detectFormat(file.name);
    if (resolvedFormat == null) {
      return ImportResult.failure(
        'Unsupported file format: ${file.extension}',
      );
    }

    final data = await _exportManager.import<T>(
      bytes: file.bytes,
      format: resolvedFormat,
    );

    if (data == null) {
      return ImportResult.failure(
        'Failed to parse file as ${resolvedFormat.name}',
      );
    }

    return ImportResult.success(data, fileName: file.name);
  }

  /// Returns the list of importable format extensions.
  List<String> get importableExtensions {
    return _exportManager.importableFormats
        .map((f) {
          final codec = _exportManager.getCodec(f);
          return codec?.extension ?? f.name;
        })
        .toList();
  }
}
