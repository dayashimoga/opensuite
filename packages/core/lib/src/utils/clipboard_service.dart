import 'package:flutter/services.dart';

/// Cross-platform clipboard abstraction for productivity suite operations.
///
/// Handles text-based clipboard operations (copy, cut, paste) using
/// Flutter's built-in [Clipboard] which works across all platforms.
class ClipboardService {
  /// The current clipboard content (in-app cache for cell/element data).
  static String? _internalContent;

  /// The type of content currently on the clipboard.
  static ClipboardContentType _contentType = ClipboardContentType.text;

  /// Whether the last clipboard operation was a cut (vs copy).
  static bool _isCut = false;

  /// Copies text to the system clipboard and internal cache.
  static Future<void> copy(String text,
      {ClipboardContentType type = ClipboardContentType.text}) async {
    _internalContent = text;
    _contentType = type;
    _isCut = false;
    await Clipboard.setData(ClipboardData(text: text));
  }

  /// Cuts text to the clipboard (same as copy but flags for removal).
  static Future<void> cut(String text,
      {ClipboardContentType type = ClipboardContentType.text}) async {
    _internalContent = text;
    _contentType = type;
    _isCut = true;
    await Clipboard.setData(ClipboardData(text: text));
  }

  /// Reads text from the system clipboard.
  static Future<String?> paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    return data?.text;
  }

  /// Gets the internal clipboard content (for structured data like cell ranges).
  static String? get internalContent => _internalContent;

  /// Gets the content type on the clipboard.
  static ClipboardContentType get contentType => _contentType;

  /// Whether the clipboard content was cut (should be removed from source).
  static bool get wasCut => _isCut;

  /// Clears the internal clipboard cache.
  static void clear() {
    _internalContent = null;
    _contentType = ClipboardContentType.text;
    _isCut = false;
  }

  /// Checks if clipboard has content.
  static Future<bool> hasContent() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    return data?.text?.isNotEmpty == true || _internalContent != null;
  }
}

/// Types of content that can be stored on the clipboard.
enum ClipboardContentType {
  /// Plain text content.
  text,

  /// Spreadsheet cell range (JSON-encoded cells).
  cells,

  /// Presentation element(s) (JSON-encoded).
  elements,

  /// Image data reference.
  image,
}
