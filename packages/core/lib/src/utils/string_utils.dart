/// String utility functions used across the application.
class StringUtils {
  StringUtils._();

  /// Truncates a string to the specified length with an ellipsis.
  static String truncate(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength - 1)}…';
  }

  /// Capitalizes the first letter of a string.
  static String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  /// Converts a string to title case.
  static String toTitleCase(String text) {
    return text.split(' ').map(capitalize).join(' ');
  }

  /// Returns true if the string is null or empty after trimming.
  static bool isBlank(String? text) {
    return text == null || text.trim().isEmpty;
  }

  /// Returns true if the string is not null and not empty after trimming.
  static bool isNotBlank(String? text) {
    return !isBlank(text);
  }

  /// Generates a slug from a string (lowercase, hyphens, no special chars).
  static String slugify(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
        .replaceAll(RegExp(r'[\s-]+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
  }

  /// Counts the number of words in a string.
  static int wordCount(String text) {
    if (text.trim().isEmpty) return 0;
    return text.trim().split(RegExp(r'\s+')).length;
  }

  /// Counts the number of characters (excluding whitespace).
  static int charCount(String text) {
    return text.replaceAll(RegExp(r'\s'), '').length;
  }

  /// Returns a string with line numbers prepended to each line.
  static String withLineNumbers(String text) {
    final lines = text.split('\n');
    final padding = lines.length.toString().length;
    return lines
        .asMap()
        .entries
        .map((e) => '${(e.key + 1).toString().padLeft(padding)} │ ${e.value}')
        .join('\n');
  }
}
