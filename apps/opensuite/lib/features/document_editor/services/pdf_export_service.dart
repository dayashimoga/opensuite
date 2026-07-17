import 'dart:convert';
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Service for exporting documents to PDF format.
///
/// Converts Quill Delta JSON into PDF pages using the `pdf` package.
/// Supports: paragraphs, headings, bold, italic, underline,
/// strikethrough, colors, alignment, lists, blockquotes, and code blocks.
class PdfExportService {
  PdfExportService._();

  /// Export Quill Delta JSON to PDF bytes.
  static Future<Uint8List> exportFromDelta({
    required String deltaJson,
    required String plainText,
    required String title,
  }) async {
    final pdf = pw.Document(
      creator: 'OpenSuite',
      title: title,
      author: 'OpenSuite User',
    );

    // Parse Delta operations
    List<dynamic> ops;
    try {
      ops = jsonDecode(deltaJson) as List<dynamic>;
    } catch (_) {
      ops = [
        {'insert': '$plainText\n'}
      ];
    }

    // Convert Delta ops to PDF widgets
    final widgets = _deltaOpsToWidgets(ops, title);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(72), // 1 inch margins
        header: (context) => pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 8),
          child: pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 10,
              color: PdfColor.fromHex('#666666'),
            ),
          ),
        ),
        footer: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(top: 8),
          child: pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: pw.TextStyle(
              fontSize: 9,
              color: PdfColor.fromHex('#999999'),
            ),
          ),
        ),
        build: (context) => widgets,
      ),
    );

    return pdf.save();
  }

  /// Export plain text to PDF bytes (fallback for non-Delta content).
  static Future<Uint8List> exportFromPlainText({
    required String text,
    required String title,
  }) async {
    final pdf = pw.Document(
      creator: 'OpenSuite',
      title: title,
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(72),
        build: (context) => [
          pw.Text(
            text,
            style: const pw.TextStyle(fontSize: 12),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  static List<pw.Widget> _deltaOpsToWidgets(List<dynamic> ops, String title) {
    final widgets = <pw.Widget>[];
    final currentSpans = <_RichSpan>[];
    Map<String, dynamic>? pendingBlockAttrs;

    for (final op in ops) {
      if (op is! Map<String, dynamic>) continue;
      final insert = op['insert'];
      final attrs = op['attributes'] as Map<String, dynamic>? ?? {};

      if (insert is String) {
        final lines = insert.split('\n');

        for (int i = 0; i < lines.length; i++) {
          if (lines[i].isNotEmpty) {
            currentSpans.add(_RichSpan(text: lines[i], attrs: attrs));
          }

          // Each newline = end of paragraph
          if (i < lines.length - 1) {
            widgets.add(_buildParagraphWidget(
                List.from(currentSpans), pendingBlockAttrs));
            currentSpans.clear();
            pendingBlockAttrs = null;
          }
        }

        // Block-level attrs come on the '\n' character
        if (insert == '\n' && attrs.isNotEmpty) {
          pendingBlockAttrs = attrs;
        }
      }
    }

    // Flush remaining
    if (currentSpans.isNotEmpty) {
      widgets.add(
          _buildParagraphWidget(List.from(currentSpans), pendingBlockAttrs));
    }

    return widgets;
  }

  static pw.Widget _buildParagraphWidget(
    List<_RichSpan> spans,
    Map<String, dynamic>? blockAttrs,
  ) {
    // Determine block type
    final isHeading = blockAttrs?.containsKey('header') == true;
    final headingLevel = isHeading ? (blockAttrs!['header'] as int?) ?? 1 : 0;
    final isList = blockAttrs?.containsKey('list') == true;
    final listType = isList ? blockAttrs!['list'] as String : '';
    final isBlockquote = blockAttrs?['blockquote'] == true;
    final isCodeBlock = blockAttrs?['code-block'] == true;
    final indent = blockAttrs?['indent'] as int? ?? 0;

    // Alignment
    pw.TextAlign textAlign = pw.TextAlign.left;
    if (blockAttrs?.containsKey('align') == true) {
      switch (blockAttrs!['align']) {
        case 'center':
          textAlign = pw.TextAlign.center;
        case 'right':
          textAlign = pw.TextAlign.right;
        case 'justify':
          textAlign = pw.TextAlign.justify;
      }
    }

    // Build text spans
    final textSpans = spans.map((span) {
      double fontSize = 12;
      pw.FontWeight fontWeight = pw.FontWeight.normal;
      pw.FontStyle fontStyle = pw.FontStyle.normal;
      PdfColor color = PdfColors.black;
      pw.TextDecoration? decoration;

      // Apply heading font size
      if (isHeading) {
        switch (headingLevel) {
          case 1:
            fontSize = 28;
            fontWeight = pw.FontWeight.bold;
          case 2:
            fontSize = 22;
            fontWeight = pw.FontWeight.bold;
          case 3:
            fontSize = 18;
            fontWeight = pw.FontWeight.bold;
          case 4:
            fontSize = 16;
            fontWeight = pw.FontWeight.bold;
          case 5:
            fontSize = 14;
            fontWeight = pw.FontWeight.bold;
          case 6:
            fontSize = 12;
            fontWeight = pw.FontWeight.bold;
        }
      }

      // Apply inline attributes
      if (span.attrs['bold'] == true) fontWeight = pw.FontWeight.bold;
      if (span.attrs['italic'] == true) fontStyle = pw.FontStyle.italic;
      if (span.attrs['underline'] == true) {
        decoration = pw.TextDecoration.underline;
      }
      if (span.attrs['strike'] == true) {
        decoration = pw.TextDecoration.lineThrough;
      }
      if (span.attrs.containsKey('color')) {
        try {
          color = PdfColor.fromHex(
              (span.attrs['color'] as String).replaceAll('#', ''));
        } catch (_) {}
      }
      if (span.attrs.containsKey('size')) {
        final sizeVal = span.attrs['size'];
        if (sizeVal is num) {
          fontSize = sizeVal.toDouble();
        } else if (sizeVal is String) {
          fontSize = double.tryParse(sizeVal.replaceAll('px', '')) ?? fontSize;
        }
      }

      return pw.TextSpan(
        text: span.text,
        style: pw.TextStyle(
          fontSize: fontSize,
          fontWeight: fontWeight,
          fontStyle: fontStyle,
          color: color,
          decoration: decoration,
        ),
      );
    }).toList();

    // Empty paragraph
    if (textSpans.isEmpty) {
      textSpans.add(pw.TextSpan(
        text: ' ',
        style: const pw.TextStyle(fontSize: 12),
      ));
    }

    // Build the paragraph widget
    pw.Widget paragraphWidget = pw.RichText(
      textAlign: textAlign,
      text: pw.TextSpan(children: textSpans),
    );

    // Apply list styling
    if (isList) {
      final bullet =
          listType == 'ordered' ? '•' : '•'; // Both use bullet for now
      paragraphWidget = pw.Padding(
        padding: pw.EdgeInsets.only(left: 20.0 + indent * 20.0),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(
              width: 16,
              child: pw.Text(
                bullet,
                style: const pw.TextStyle(fontSize: 12),
              ),
            ),
            pw.Expanded(child: paragraphWidget),
          ],
        ),
      );
    }

    // Apply blockquote styling
    if (isBlockquote) {
      paragraphWidget = pw.Container(
        padding: const pw.EdgeInsets.only(left: 16),
        decoration: const pw.BoxDecoration(
          border: pw.Border(
            left: pw.BorderSide(
              color: PdfColors.grey400,
              width: 3,
            ),
          ),
        ),
        child: paragraphWidget,
      );
    }

    // Apply code block styling
    if (isCodeBlock) {
      paragraphWidget = pw.Container(
        padding: const pw.EdgeInsets.all(8),
        decoration: pw.BoxDecoration(
          color: PdfColor.fromHex('#F5F5F5'),
          border: pw.Border.all(color: PdfColors.grey300),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
        ),
        child: paragraphWidget,
      );
    }

    // Apply indent
    if (indent > 0 && !isList) {
      paragraphWidget = pw.Padding(
        padding: pw.EdgeInsets.only(left: indent * 36.0),
        child: paragraphWidget,
      );
    }

    // Add spacing between paragraphs
    final bottomSpacing = isHeading ? 8.0 : 4.0;
    final topSpacing = isHeading && headingLevel <= 2 ? 12.0 : 0.0;

    return pw.Padding(
      padding: pw.EdgeInsets.only(top: topSpacing, bottom: bottomSpacing),
      child: paragraphWidget,
    );
  }
}

class _RichSpan {
  final String text;
  final Map<String, dynamic> attrs;

  const _RichSpan({required this.text, required this.attrs});
}
