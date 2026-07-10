import 'package:path/path.dart' as p;

import '../models/file_type.dart';

/// File-related utility functions.
class FileUtils {
  FileUtils._();

  /// Returns the file extension from a path (including dot, lowercase).
  static String getExtension(String path) {
    return p.extension(path).toLowerCase();
  }

  /// Returns the filename without extension from a path.
  static String getBaseName(String path) {
    return p.basenameWithoutExtension(path);
  }

  /// Returns the filename with extension from a path.
  static String getFileName(String path) {
    return p.basename(path);
  }

  /// Returns the directory portion of a path.
  static String getDirectory(String path) {
    return p.dirname(path);
  }

  /// Detects the [FileType] from a file path.
  static FileType detectType(String path) {
    return FileType.fromPath(path);
  }

  /// Generates a unique filename by appending a counter if needed.
  ///
  /// Example: "document.txt" becomes "document (1).txt" if the original exists.
  static String generateUniqueName(String baseName, Set<String> existingNames) {
    if (!existingNames.contains(baseName)) {
      return baseName;
    }

    final nameWithoutExt = p.basenameWithoutExtension(baseName);
    final ext = p.extension(baseName);
    var counter = 1;

    while (existingNames.contains('$nameWithoutExt ($counter)$ext')) {
      counter++;
    }

    return '$nameWithoutExt ($counter)$ext';
  }

  /// Validates that a filename contains only safe characters.
  static bool isValidFileName(String name) {
    if (name.isEmpty || name.length > 255) return false;

    // Check for invalid characters
    final invalidChars = RegExp(r'[<>:"/\\|?*\x00-\x1f]');
    if (invalidChars.hasMatch(name)) return false;

    // Check for reserved names (Windows)
    final reserved = {
      'CON',
      'PRN',
      'AUX',
      'NUL',
      'COM1',
      'COM2',
      'COM3',
      'COM4',
      'COM5',
      'COM6',
      'COM7',
      'COM8',
      'COM9',
      'LPT1',
      'LPT2',
      'LPT3',
      'LPT4',
      'LPT5',
      'LPT6',
      'LPT7',
      'LPT8',
      'LPT9',
    };
    final nameUpper = p.basenameWithoutExtension(name).toUpperCase();
    if (reserved.contains(nameUpper)) return false;

    return true;
  }

  /// Sanitizes a filename by replacing invalid characters.
  static String sanitizeFileName(String name) {
    return name
        .replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1f]'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .trim();
  }

  /// Formats a file size in bytes to a human-readable string.
  static String formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
