import 'dart:typed_data';

/// Supported export formats across all editors.
enum ExportFormat {
  // Text formats
  txt,
  markdown,
  html,
  json,

  // Document formats
  docx,
  rtf,
  odt,

  // Spreadsheet formats
  csv,
  xlsx,
  ods,
  tsv,

  // Presentation formats
  pptx,
  odp,

  // Image formats
  png,
  jpeg,
  webp,
  tiff,
  bmp,
  svg,

  // PDF
  pdf,
}

/// Result of an export operation.
class ExportResult {
  /// Whether the export succeeded.
  final bool success;

  /// The exported file bytes (if available).
  final Uint8List? bytes;

  /// The exported file name.
  final String? fileName;

  /// The MIME type of the exported content.
  final String? mimeType;

  /// Error message if export failed.
  final String? error;

  const ExportResult._({
    required this.success,
    this.bytes,
    this.fileName,
    this.mimeType,
    this.error,
  });

  /// Creates a successful export result.
  factory ExportResult.success({
    required Uint8List bytes,
    required String fileName,
    String? mimeType,
  }) {
    return ExportResult._(
      success: true,
      bytes: bytes,
      fileName: fileName,
      mimeType: mimeType,
    );
  }

  /// Creates a failed export result.
  factory ExportResult.failure(String error) {
    return ExportResult._(success: false, error: error);
  }
}

/// A codec that converts between an in-memory data model and a file format.
///
/// Implement this interface for each supported file format.
abstract class FormatCodec<T> {
  /// The format this codec handles.
  ExportFormat get format;

  /// Human-readable format name.
  String get displayName;

  /// File extension (without dot).
  String get extension;

  /// MIME type for this format.
  String get mimeType;

  /// Encodes [data] into file bytes.
  Future<Uint8List> encode(T data);

  /// Decodes file [bytes] into the data model.
  Future<T> decode(Uint8List bytes);

  /// Whether this codec supports encoding (export).
  bool get canEncode => true;

  /// Whether this codec supports decoding (import).
  bool get canDecode => true;
}

/// Manages export operations across all editors.
///
/// Provides a centralized registry of format codecs and handles
/// the export workflow: encode → save/share.
class ExportManager {
  ExportManager._();

  static final ExportManager _instance = ExportManager._();

  /// Singleton instance.
  static ExportManager get instance => _instance;

  /// Registered format codecs.
  final Map<ExportFormat, FormatCodec<dynamic>> _codecs = {};

  /// Registers a format codec.
  void registerCodec<T>(FormatCodec<T> codec) {
    _codecs[codec.format] = codec;
  }

  /// Unregisters a format codec.
  void unregisterCodec(ExportFormat format) {
    _codecs.remove(format);
  }

  /// Returns the codec for [format], or null if not registered.
  FormatCodec<T>? getCodec<T>(ExportFormat format) {
    final codec = _codecs[format];
    if (codec is FormatCodec<T>) return codec;
    return null;
  }

  /// Returns all registered formats that support encoding.
  List<ExportFormat> get exportableFormats => _codecs.entries
      .where((e) => e.value.canEncode)
      .map((e) => e.key)
      .toList();

  /// Returns all registered formats that support decoding.
  List<ExportFormat> get importableFormats => _codecs.entries
      .where((e) => e.value.canDecode)
      .map((e) => e.key)
      .toList();

  /// Exports [data] to the specified [format].
  ///
  /// Returns an [ExportResult] with the encoded bytes and metadata.
  Future<ExportResult> export<T>({
    required T data,
    required ExportFormat format,
    required String baseName,
  }) async {
    final codec = getCodec<T>(format);
    if (codec == null) {
      return ExportResult.failure(
        'No codec registered for format: ${format.name}',
      );
    }
    if (!codec.canEncode) {
      return ExportResult.failure(
        'Format ${format.name} does not support export',
      );
    }
    try {
      final bytes = await codec.encode(data);
      final fileName = '$baseName.${codec.extension}';
      return ExportResult.success(
        bytes: bytes,
        fileName: fileName,
        mimeType: codec.mimeType,
      );
    } catch (e) {
      return ExportResult.failure('Export failed: $e');
    }
  }

  /// Imports file [bytes] using the codec for [format].
  Future<T?> import<T>({
    required Uint8List bytes,
    required ExportFormat format,
  }) async {
    final codec = getCodec<T>(format);
    if (codec == null || !codec.canDecode) return null;
    try {
      return await codec.decode(bytes);
    } catch (_) {
      return null;
    }
  }

  /// Resolves the [ExportFormat] from a file extension string.
  ExportFormat? formatFromExtension(String ext) {
    final normalized = ext.toLowerCase().replaceAll('.', '');
    for (final format in ExportFormat.values) {
      if (format.name == normalized) return format;
    }
    // Handle aliases
    switch (normalized) {
      case 'jpg':
        return ExportFormat.jpeg;
      case 'md':
        return ExportFormat.markdown;
      case 'htm':
        return ExportFormat.html;
      default:
        return null;
    }
  }
}
