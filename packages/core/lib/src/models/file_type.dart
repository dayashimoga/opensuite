/// Supported file types in the application.
///
/// Each file type has associated extensions, MIME types, and display metadata
/// used throughout the UI and file handling logic.
enum FileType {
  /// Plain text file.
  text(
    extensions: ['.txt'],
    mimeTypes: ['text/plain'],
    label: 'Text',
    icon: 'description',
  ),

  /// Markdown file.
  markdown(
    extensions: ['.md', '.markdown', '.mdown'],
    mimeTypes: ['text/markdown'],
    label: 'Markdown',
    icon: 'article',
  ),

  /// Rich Text Format file.
  rtf(
    extensions: ['.rtf'],
    mimeTypes: ['application/rtf', 'text/rtf'],
    label: 'Rich Text',
    icon: 'text_format',
  ),

  /// Microsoft Word document.
  docx(
    extensions: ['.docx'],
    mimeTypes: [
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    ],
    label: 'Word Document',
    icon: 'description',
  ),

  /// OpenDocument Text.
  odt(
    extensions: ['.odt'],
    mimeTypes: ['application/vnd.oasis.opendocument.text'],
    label: 'OpenDocument Text',
    icon: 'description',
  ),

  /// Microsoft Excel spreadsheet.
  xlsx(
    extensions: ['.xlsx'],
    mimeTypes: [
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    ],
    label: 'Excel Spreadsheet',
    icon: 'table_chart',
  ),

  /// Comma-separated values.
  csv(
    extensions: ['.csv'],
    mimeTypes: ['text/csv'],
    label: 'CSV',
    icon: 'table_chart',
  ),

  /// OpenDocument Spreadsheet.
  ods(
    extensions: ['.ods'],
    mimeTypes: ['application/vnd.oasis.opendocument.spreadsheet'],
    label: 'OpenDocument Spreadsheet',
    icon: 'table_chart',
  ),

  /// Microsoft PowerPoint presentation.
  pptx(
    extensions: ['.pptx'],
    mimeTypes: [
      'application/vnd.openxmlformats-officedocument.presentationml.presentation',
    ],
    label: 'PowerPoint Presentation',
    icon: 'slideshow',
  ),

  /// OpenDocument Presentation.
  odp(
    extensions: ['.odp'],
    mimeTypes: ['application/vnd.oasis.opendocument.presentation'],
    label: 'OpenDocument Presentation',
    icon: 'slideshow',
  ),

  /// PDF document.
  pdf(
    extensions: ['.pdf'],
    mimeTypes: ['application/pdf'],
    label: 'PDF Document',
    icon: 'picture_as_pdf',
  ),

  /// JPEG image.
  jpeg(
    extensions: ['.jpg', '.jpeg'],
    mimeTypes: ['image/jpeg'],
    label: 'JPEG Image',
    icon: 'image',
  ),

  /// PNG image.
  png(
    extensions: ['.png'],
    mimeTypes: ['image/png'],
    label: 'PNG Image',
    icon: 'image',
  ),

  /// WebP image.
  webp(
    extensions: ['.webp'],
    mimeTypes: ['image/webp'],
    label: 'WebP Image',
    icon: 'image',
  ),

  /// SVG image.
  svg(
    extensions: ['.svg'],
    mimeTypes: ['image/svg+xml'],
    label: 'SVG Image',
    icon: 'image',
  ),

  /// Unknown or unsupported file type.
  unknown(
    extensions: [],
    mimeTypes: [],
    label: 'Unknown',
    icon: 'insert_drive_file',
  );

  const FileType({
    required this.extensions,
    required this.mimeTypes,
    required this.label,
    required this.icon,
  });

  /// File extensions associated with this type (including dot).
  final List<String> extensions;

  /// MIME types associated with this type.
  final List<String> mimeTypes;

  /// Human-readable label for display.
  final String label;

  /// Material icon name for display.
  final String icon;

  /// Detects the file type from a file path or name.
  static FileType fromPath(String path) {
    final lowerPath = path.toLowerCase();
    for (final type in FileType.values) {
      for (final ext in type.extensions) {
        if (lowerPath.endsWith(ext)) {
          return type;
        }
      }
    }
    return FileType.unknown;
  }

  /// Detects the file type from a MIME type string.
  static FileType fromMimeType(String mimeType) {
    final lowerMime = mimeType.toLowerCase();
    for (final type in FileType.values) {
      if (type.mimeTypes.contains(lowerMime)) {
        return type;
      }
    }
    return FileType.unknown;
  }

  /// Whether this type is an image format.
  bool get isImage =>
      this == FileType.jpeg ||
      this == FileType.png ||
      this == FileType.webp ||
      this == FileType.svg;

  /// Whether this type is a document format.
  bool get isDocument =>
      this == FileType.text ||
      this == FileType.markdown ||
      this == FileType.rtf ||
      this == FileType.docx ||
      this == FileType.odt;

  /// Whether this type is a spreadsheet format.
  bool get isSpreadsheet =>
      this == FileType.xlsx ||
      this == FileType.csv ||
      this == FileType.ods;

  /// Whether this type is a presentation format.
  bool get isPresentation =>
      this == FileType.pptx || this == FileType.odp;

  /// The primary extension (first in the list) or empty string.
  String get primaryExtension =>
      extensions.isNotEmpty ? extensions.first : '';
}
