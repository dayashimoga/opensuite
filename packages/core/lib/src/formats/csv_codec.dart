import 'dart:convert';
import 'dart:typed_data';

import '../services/export_manager.dart';

/// CSV codec for spreadsheet data import/export.
///
/// Handles CSV parsing with proper quoting, escaping, and encoding.
/// Supports configurable delimiters (comma, tab, semicolon).
class CsvCodec extends FormatCodec<List<List<String>>> {
  /// The field delimiter character.
  final String delimiter;

  /// The text qualifier character.
  final String qualifier;

  /// The line separator.
  final String lineSeparator;

  /// Creates a CSV codec with the given settings.
  CsvCodec({
    this.delimiter = ',',
    this.qualifier = '"',
    this.lineSeparator = '\r\n',
  });

  @override
  ExportFormat get format => ExportFormat.csv;

  @override
  String get displayName => 'CSV';

  @override
  String get extension => 'csv';

  @override
  String get mimeType => 'text/csv';

  @override
  Future<Uint8List> encode(List<List<String>> data) async {
    final buffer = StringBuffer();

    for (var rowIdx = 0; rowIdx < data.length; rowIdx++) {
      final row = data[rowIdx];
      for (var colIdx = 0; colIdx < row.length; colIdx++) {
        if (colIdx > 0) buffer.write(delimiter);
        buffer.write(_encodeField(row[colIdx]));
      }
      if (rowIdx < data.length - 1) {
        buffer.write(lineSeparator);
      }
    }

    return Uint8List.fromList(utf8.encode(buffer.toString()));
  }

  @override
  Future<List<List<String>>> decode(Uint8List bytes) async {
    final text = utf8.decode(bytes, allowMalformed: true);
    return _parse(text);
  }

  /// Encodes a single field, quoting if necessary.
  String _encodeField(String field) {
    if (field.contains(delimiter) ||
        field.contains(qualifier) ||
        field.contains('\n') ||
        field.contains('\r')) {
      // Escape qualifier by doubling it
      final escaped = field.replaceAll(qualifier, '$qualifier$qualifier');
      return '$qualifier$escaped$qualifier';
    }
    return field;
  }

  /// Parses CSV text into a 2D list of strings.
  List<List<String>> _parse(String text) {
    final rows = <List<String>>[];
    final currentRow = <String>[];
    final field = StringBuffer();
    var inQuotes = false;
    var i = 0;

    while (i < text.length) {
      final char = text[i];

      if (inQuotes) {
        if (char == qualifier[0]) {
          // Check for escaped qualifier (doubled)
          if (i + 1 < text.length && text[i + 1] == qualifier[0]) {
            field.write(qualifier);
            i += 2;
            continue;
          } else {
            // End of quoted field
            inQuotes = false;
            i++;
            continue;
          }
        } else {
          field.write(char);
          i++;
        }
      } else {
        if (char == qualifier[0] && field.isEmpty) {
          // Start of quoted field
          inQuotes = true;
          i++;
        } else if (char == delimiter[0]) {
          // End of field
          currentRow.add(field.toString());
          field.clear();
          i++;
        } else if (char == '\r') {
          // Line ending (CR or CRLF)
          currentRow.add(field.toString());
          field.clear();
          rows.add(List<String>.from(currentRow));
          currentRow.clear();
          if (i + 1 < text.length && text[i + 1] == '\n') {
            i += 2;
          } else {
            i++;
          }
        } else if (char == '\n') {
          // Line ending (LF)
          currentRow.add(field.toString());
          field.clear();
          rows.add(List<String>.from(currentRow));
          currentRow.clear();
          i++;
        } else {
          field.write(char);
          i++;
        }
      }
    }

    // Handle last field/row
    if (field.isNotEmpty || currentRow.isNotEmpty) {
      currentRow.add(field.toString());
      rows.add(currentRow);
    }

    return rows;
  }
}

/// TSV codec (Tab-Separated Values).
class TsvCodec extends CsvCodec {
  TsvCodec() : super(delimiter: '\t');

  @override
  ExportFormat get format => ExportFormat.tsv;

  @override
  String get displayName => 'TSV';

  @override
  String get extension => 'tsv';

  @override
  String get mimeType => 'text/tab-separated-values';
}
