import 'package:flutter/widgets.dart';

/// Utility class for clean line prefix toggling and multi-line formatting
/// in text and markdown editors without prefix stacking collisions (e.g. "1. - ").
class LinePrefixUtils {
  LinePrefixUtils._();

  static final RegExp _existingPrefixRegex = RegExp(
    r'^(\s*)(-\s\[\s\]\s|-\s|\d+\.\s|>\s|#{1,6}\s)',
  );

  /// Applies a [prefix] to the line(s) containing the selection in [controller].
  ///
  /// If the line already starts with [prefix], the prefix is toggled off (removed).
  /// If the line starts with a different prefix, the existing prefix is replaced.
  /// If multiple lines are selected, applies to every line in the selection range.
  static String applyPrefix({
    required TextEditingController controller,
    required String prefix,
  }) {
    final text = controller.text;
    final sel = controller.selection;
    if (!sel.isValid) return text;

    final startOffset = sel.start < sel.end ? sel.start : sel.end;
    final endOffset = sel.start < sel.end ? sel.end : sel.start;

    // Expand to cover full line bounds
    int lineStart = startOffset;
    while (lineStart > 0 && text[lineStart - 1] != '\n') {
      lineStart--;
    }

    int lineEnd = endOffset;
    while (lineEnd < text.length && text[lineEnd] != '\n') {
      lineEnd++;
    }

    final fullSelectedLines = text.substring(lineStart, lineEnd);
    final lines = fullSelectedLines.split('\n');

    final updatedLines = <String>[];
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final targetPrefix = prefix == '1. ' ? '${i + 1}. ' : prefix;

      if (_existingPrefixRegex.hasMatch(line)) {
        final match = _existingPrefixRegex.firstMatch(line)!;
        final currentIndent = match.group(1) ?? '';
        final currentPrefix = match.group(2) ?? '';

        if (currentPrefix == targetPrefix) {
          // Toggle off: strip prefix
          updatedLines.add(line.substring(match.end));
        } else {
          // Replace prefix
          updatedLines
              .add('$currentIndent$targetPrefix${line.substring(match.end)}');
        }
      } else {
        // Prepend prefix
        updatedLines.add('$targetPrefix$line');
      }
    }

    final newLinesText = updatedLines.join('\n');
    final newText = text.replaceRange(lineStart, lineEnd, newLinesText);

    controller.text = newText;
    controller.selection = TextSelection(
      baseOffset: lineStart,
      extentOffset: lineStart + newLinesText.length,
    );

    return newText;
  }
}
