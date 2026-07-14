import 'export_manager.dart';

/// Registry entry for a supported file format.
class FileFormatEntry {
  /// The export format enum value.
  final ExportFormat format;

  /// Human-readable name (e.g., 'Microsoft Word Document').
  final String displayName;

  /// File extension without dot (e.g., 'docx').
  final String extension;

  /// MIME type (e.g., 'application/vnd.openxmlformats...').
  final String mimeType;

  /// Category for grouping (e.g., 'document', 'spreadsheet', 'image').
  final String category;

  /// Whether import is supported.
  final bool canImport;

  /// Whether export is supported.
  final bool canExport;

  /// Description of the format.
  final String description;

  const FileFormatEntry({
    required this.format,
    required this.displayName,
    required this.extension,
    required this.mimeType,
    required this.category,
    this.canImport = false,
    this.canExport = false,
    this.description = '',
  });
}

/// Central registry of all supported file formats.
///
/// Maps file extensions and MIME types to format metadata.
/// Used by ImportManager and ExportManager for format detection
/// and UI display (e.g., filter dropdowns, format pickers).
class FileFormatRegistry {
  FileFormatRegistry._();

  static final FileFormatRegistry _instance = FileFormatRegistry._();

  /// Singleton instance.
  static FileFormatRegistry get instance => _instance;

  final Map<ExportFormat, FileFormatEntry> _formats = {};

  /// Registers a file format entry.
  void register(FileFormatEntry entry) {
    _formats[entry.format] = entry;
  }

  /// Returns the entry for [format], or null.
  FileFormatEntry? getEntry(ExportFormat format) => _formats[format];

  /// Returns all registered formats.
  List<FileFormatEntry> get allFormats => _formats.values.toList();

  /// Returns formats filtered by [category].
  List<FileFormatEntry> getByCategory(String category) =>
      _formats.values.where((e) => e.category == category).toList();

  /// Returns formats that support import.
  List<FileFormatEntry> get importableFormats =>
      _formats.values.where((e) => e.canImport).toList();

  /// Returns formats that support export.
  List<FileFormatEntry> get exportableFormats =>
      _formats.values.where((e) => e.canExport).toList();

  /// Looks up a format by file extension (case-insensitive, without dot).
  FileFormatEntry? fromExtension(String ext) {
    final normalized = ext.toLowerCase().replaceAll('.', '');
    // Handle aliases
    final aliased = _extensionAliases[normalized] ?? normalized;
    return _formats.values.cast<FileFormatEntry?>().firstWhere(
          (e) => e!.extension == aliased,
          orElse: () => null,
        );
  }

  /// Looks up a format by MIME type.
  FileFormatEntry? fromMimeType(String mimeType) {
    return _formats.values.cast<FileFormatEntry?>().firstWhere(
          (e) => e!.mimeType == mimeType,
          orElse: () => null,
        );
  }

  /// Common extension aliases.
  static const _extensionAliases = {
    'jpg': 'jpeg',
    'htm': 'html',
    'md': 'markdown',
    'tif': 'tiff',
    'yml': 'yaml',
  };

  /// Initializes the registry with all known formats.
  ///
  /// Call once at app startup. The [canImport] and [canExport] flags
  /// reflect whether a codec is actually registered, not just whether
  /// the format is conceptually supported.
  void initializeDefaults() {
    // --- Documents ---
    register(const FileFormatEntry(
      format: ExportFormat.txt,
      displayName: 'Plain Text',
      extension: 'txt',
      mimeType: 'text/plain',
      category: 'document',
      canImport: true,
      canExport: true,
      description: 'Plain text file with no formatting',
    ));
    register(const FileFormatEntry(
      format: ExportFormat.markdown,
      displayName: 'Markdown',
      extension: 'md',
      mimeType: 'text/markdown',
      category: 'document',
      canImport: true,
      canExport: true,
      description: 'Markdown-formatted text document',
    ));
    register(const FileFormatEntry(
      format: ExportFormat.html,
      displayName: 'HTML',
      extension: 'html',
      mimeType: 'text/html',
      category: 'document',
      canImport: true,
      canExport: true,
      description: 'HyperText Markup Language document',
    ));
    register(const FileFormatEntry(
      format: ExportFormat.docx,
      displayName: 'Microsoft Word',
      extension: 'docx',
      mimeType:
          'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      category: 'document',
      canImport: false, // Not yet implemented
      canExport: false,
      description: 'Microsoft Word document (OOXML)',
    ));

    // --- Spreadsheets ---
    register(const FileFormatEntry(
      format: ExportFormat.csv,
      displayName: 'CSV',
      extension: 'csv',
      mimeType: 'text/csv',
      category: 'spreadsheet',
      canImport: true,
      canExport: true,
      description: 'Comma-separated values',
    ));
    register(const FileFormatEntry(
      format: ExportFormat.tsv,
      displayName: 'TSV',
      extension: 'tsv',
      mimeType: 'text/tab-separated-values',
      category: 'spreadsheet',
      canImport: true,
      canExport: true,
      description: 'Tab-separated values',
    ));
    register(const FileFormatEntry(
      format: ExportFormat.xlsx,
      displayName: 'Microsoft Excel',
      extension: 'xlsx',
      mimeType:
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      category: 'spreadsheet',
      canImport: false,
      canExport: false,
      description: 'Microsoft Excel workbook (OOXML)',
    ));

    // --- Presentations ---
    register(const FileFormatEntry(
      format: ExportFormat.pptx,
      displayName: 'Microsoft PowerPoint',
      extension: 'pptx',
      mimeType:
          'application/vnd.openxmlformats-officedocument.presentationml.presentation',
      category: 'presentation',
      canImport: false,
      canExport: false,
      description: 'Microsoft PowerPoint presentation (OOXML)',
    ));

    // --- Images ---
    register(const FileFormatEntry(
      format: ExportFormat.png,
      displayName: 'PNG',
      extension: 'png',
      mimeType: 'image/png',
      category: 'image',
      canImport: true,
      canExport: true,
      description: 'Portable Network Graphics',
    ));
    register(const FileFormatEntry(
      format: ExportFormat.jpeg,
      displayName: 'JPEG',
      extension: 'jpeg',
      mimeType: 'image/jpeg',
      category: 'image',
      canImport: true,
      canExport: true,
      description: 'Joint Photographic Experts Group',
    ));
    register(const FileFormatEntry(
      format: ExportFormat.webp,
      displayName: 'WebP',
      extension: 'webp',
      mimeType: 'image/webp',
      category: 'image',
      canImport: true,
      canExport: true,
      description: 'WebP image format',
    ));
    register(const FileFormatEntry(
      format: ExportFormat.svg,
      displayName: 'SVG',
      extension: 'svg',
      mimeType: 'image/svg+xml',
      category: 'image',
      canImport: true,
      canExport: false,
      description: 'Scalable Vector Graphics',
    ));
    register(const FileFormatEntry(
      format: ExportFormat.tiff,
      displayName: 'TIFF',
      extension: 'tiff',
      mimeType: 'image/tiff',
      category: 'image',
      canImport: true,
      canExport: false,
      description: 'Tagged Image File Format',
    ));
    register(const FileFormatEntry(
      format: ExportFormat.bmp,
      displayName: 'BMP',
      extension: 'bmp',
      mimeType: 'image/bmp',
      category: 'image',
      canImport: true,
      canExport: false,
      description: 'Bitmap image',
    ));

    // --- PDF ---
    register(const FileFormatEntry(
      format: ExportFormat.pdf,
      displayName: 'PDF',
      extension: 'pdf',
      mimeType: 'application/pdf',
      category: 'pdf',
      canImport: true,
      canExport: true,
      description: 'Portable Document Format',
    ));
  }
}
