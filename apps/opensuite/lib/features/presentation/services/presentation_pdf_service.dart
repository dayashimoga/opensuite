import 'dart:typed_data';

import 'package:fileutility_core/fileutility_core.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Service for exporting presentations as PDF.
///
/// Renders each slide to a landscape PDF page with elements
/// positioned according to their normalized coordinates.
class PresentationPdfService {
  PresentationPdfService._();

  /// Export slides to PDF bytes.
  static Future<Uint8List> exportToPdf({
    required List<SlideData> slides,
    required String title,
  }) async {
    final pdf = pw.Document(
      title: title,
      author: 'OpenSuite',
      creator: 'OpenSuite Presentation',
    );

    for (final slide in slides) {
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.standard.landscape,
          margin: pw.EdgeInsets.zero,
          build: (context) => _buildSlidePage(context, slide),
        ),
      );
    }

    return pdf.save();
  }

  static pw.Widget _buildSlidePage(pw.Context context, SlideData slide) {
    final pageWidth = PdfPageFormat.standard.landscape.width;
    final pageHeight = PdfPageFormat.standard.landscape.height;

    // Background
    final bgColor = _parseColor(slide.backgroundColor);

    final children = <pw.Widget>[];

    // Render each element
    for (final el in slide.elements) {
      final x = el.x * pageWidth;
      final y = el.y * pageHeight;
      final w = el.width * pageWidth;
      final h = el.height * pageHeight;

      pw.Widget? widget;

      switch (el.type) {
        case 'text':
          widget = _buildTextWidget(el, w, h);
        case 'shape':
          widget = _buildShapeWidget(el, w, h);
        default:
          widget = _buildTextWidget(el, w, h);
      }

      children.add(
        pw.Positioned(
          left: x,
          top: y,
          child: pw.SizedBox(width: w, height: h, child: widget),
        ),
      );
    }

    return pw.Container(
      width: pageWidth,
      height: pageHeight,
      color: bgColor,
      child: pw.Stack(children: children),
    );
  }

  static pw.Widget _buildTextWidget(SlideElement el, double w, double h) {
    final textColor = _parseColor(el.textColor);
    final fontSize = el.fontSize * 0.75; // pt to PDF units approximation
    final isBold = el.fontWeight == 'bold';
    final align = switch (el.textAlign) {
      'center' => pw.TextAlign.center,
      'right' => pw.TextAlign.right,
      _ => pw.TextAlign.left,
    };

    final fillColor = el.fillColor != null ? _parseColor(el.fillColor!) : null;

    return pw.Container(
      width: w,
      height: h,
      color: fillColor,
      padding: const pw.EdgeInsets.all(4),
      child: pw.Center(
        child: pw.Text(
          el.content,
          textAlign: align,
          style: pw.TextStyle(
            color: textColor,
            fontSize: fontSize,
            fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
      ),
    );
  }

  static pw.Widget _buildShapeWidget(SlideElement el, double w, double h) {
    final fillColor =
        el.fillColor != null ? _parseColor(el.fillColor!) : PdfColors.grey300;

    if (el.shapeType == 'circle') {
      return pw.Center(
        child: pw.Container(
          width: w < h ? w : h,
          height: w < h ? w : h,
          decoration: pw.BoxDecoration(
            color: fillColor,
            shape: pw.BoxShape.circle,
          ),
        ),
      );
    }

    return pw.Container(
      width: w,
      height: h,
      decoration: pw.BoxDecoration(
        color: fillColor,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2)),
      ),
    );
  }

  static PdfColor _parseColor(String hex) {
    final clean = hex.replaceFirst('#', '');
    if (clean.length == 6) {
      final value = int.tryParse(clean, radix: 16) ?? 0x000000;
      return PdfColor.fromInt(0xFF000000 | value);
    }
    return PdfColors.black;
  }
}
