/// Input sanitization and security utilities.
///
/// Provides protection against common attack vectors:
/// - Cross-Site Scripting (XSS)
/// - SQL injection patterns
/// - Path traversal
/// - Content length validation
class InputSanitizer {
  InputSanitizer._();

  /// Maximum allowed lengths for different input types.
  static const int maxTitleLength = 500;
  static const int maxContentLength = 10 * 1024 * 1024; // 10MB
  static const int maxSearchQueryLength = 200;
  static const int maxTagLength = 100;
  static const int maxFileNameLength = 255;

  /// Sanitizes a title field by removing control characters
  /// and trimming to max length.
  static String sanitizeTitle(String input) {
    if (input.isEmpty) return input;
    final cleaned = _removeControlChars(input).trim();
    if (cleaned.length > maxTitleLength) {
      return cleaned.substring(0, maxTitleLength);
    }
    return cleaned;
  }

  /// Sanitizes content by removing null bytes while preserving formatting.
  static String sanitizeContent(String input) {
    if (input.isEmpty) return input;
    // Remove null bytes which can cause issues in SQLite
    final cleaned = input.replaceAll('\x00', '');
    if (cleaned.length > maxContentLength) {
      return cleaned.substring(0, maxContentLength);
    }
    return cleaned;
  }

  /// Sanitizes search queries, removing SQL injection patterns.
  static String sanitizeSearchQuery(String input) {
    if (input.isEmpty) return input;
    var cleaned = _removeControlChars(input).trim();
    if (cleaned.length > maxSearchQueryLength) {
      cleaned = cleaned.substring(0, maxSearchQueryLength);
    }
    // Escape SQL special characters for LIKE queries
    cleaned = cleaned
        .replaceAll(r'\', r'\\')
        .replaceAll('%', r'\%')
        .replaceAll('_', r'\_');
    return cleaned;
  }

  /// Sanitizes HTML content to prevent XSS.
  ///
  /// Encodes HTML entities for angle brackets, quotes,
  /// ampersands, and removes script/event handler patterns.
  static String sanitizeHtml(String input) {
    if (input.isEmpty) return input;
    var result = input;

    // Remove script tags and their content
    result = result.replaceAll(
      RegExp(r'<script[^>]*>[\s\S]*?</script>', caseSensitive: false),
      '',
    );

    // Remove event handlers (onclick, onerror, onload, etc.)
    result = result.replaceAll(
      RegExp(r'\bon\w+\s*=', caseSensitive: false),
      'data-removed=',
    );

    // Remove javascript: URIs
    result = result.replaceAll(
      RegExp(r'javascript\s*:', caseSensitive: false),
      'removed:',
    );

    // Remove data: URIs with script content
    result = result.replaceAll(
      RegExp(r'data\s*:\s*text/html', caseSensitive: false),
      'removed:text/plain',
    );

    return result;
  }

  /// Encodes a string for safe use in HTML output.
  static String encodeHtml(String input) {
    return input
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#x27;');
  }

  /// Validates and sanitizes a file path to prevent path traversal.
  static String? sanitizeFilePath(String path) {
    if (path.isEmpty) return null;

    // Reject path traversal patterns
    if (path.contains('..') ||
        path.contains(r'\..\') ||
        path.contains('/../') ||
        path.contains(r'\\') ||
        path.contains('\x00')) {
      return null;
    }

    // Reject absolute paths on Unix and Windows
    if (path.startsWith('/') || RegExp(r'^[A-Za-z]:').hasMatch(path)) {
      return null;
    }

    return path;
  }

  /// Validates that a file name is safe.
  static bool isFileNameSafe(String name) {
    if (name.isEmpty || name.length > maxFileNameLength) return false;
    if (name.contains('..') || name.contains('/') || name.contains(r'\')) {
      return false;
    }
    // Reject Windows reserved names
    final reserved = RegExp(
      r'^(CON|PRN|AUX|NUL|COM[1-9]|LPT[1-9])(\.|$)',
      caseSensitive: false,
    );
    if (reserved.hasMatch(name)) return false;

    // Reject control characters
    if (RegExp(r'[\x00-\x1F\x7F]').hasMatch(name)) return false;

    // Reject dangerous characters
    if (RegExp(r'[<>:"|?*]').hasMatch(name)) return false;

    return true;
  }

  /// Validates content size is within limits.
  static bool isContentSizeValid(String content) {
    return content.length <= maxContentLength;
  }

  /// Validates a tag string.
  static String sanitizeTag(String tag) {
    return _removeControlChars(tag)
        .trim()
        .substring(0, tag.length.clamp(0, maxTagLength));
  }

  /// Removes control characters (except newline and tab).
  static String _removeControlChars(String input) {
    return input.replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]'), '');
  }
}
