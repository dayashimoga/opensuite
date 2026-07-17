import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:opensuite/features/pdf_viewer/services/pdf_manipulation_service.dart';

/// Helper to generate a simple test PDF with given page count.
Future<Uint8List> _generateTestPdf(int pages) async {
  final doc = pw.Document();
  for (int i = 0; i < pages; i++) {
    doc.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (context) =>
          pw.Center(child: pw.Text('Page ${i + 1}')),
    ));
  }
  return doc.save();
}

void main() {
  group('PdfManipulationService', () {
    group('mergePdfs', () {
      test('returns original when single PDF given', () async {
        final pdf = await _generateTestPdf(2);
        final result = await PdfManipulationService.mergePdfs([pdf]);
        expect(result, equals(pdf));
      });

      test('merges multiple PDFs', () async {
        final pdf1 = await _generateTestPdf(2);
        final pdf2 = await _generateTestPdf(3);

        final merged =
            await PdfManipulationService.mergePdfs([pdf1, pdf2]);

        expect(merged, isA<Uint8List>());
        expect(merged.length, greaterThan(0));
      });

      test('throws on empty list', () {
        expect(
          () => PdfManipulationService.mergePdfs([]),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('splitPdf', () {
      test('splits PDF into individual pages', () async {
        final pdf = await _generateTestPdf(3);
        final pages = await PdfManipulationService.splitPdf(pdf);
        expect(pages.length, greaterThanOrEqualTo(1));
        for (final page in pages) {
          expect(page, isA<Uint8List>());
          expect(page.length, greaterThan(0));
        }
      });
    });

    group('extractPages', () {
      test('extracts specific pages', () async {
        final pdf = await _generateTestPdf(5);
        final result =
            await PdfManipulationService.extractPages(pdf, [0, 2]);
        expect(result, isA<Uint8List>());
        expect(result.length, greaterThan(0));
      });
    });

    group('deletePages', () {
      test('deletes specified pages', () async {
        final pdf = await _generateTestPdf(3);
        final result =
            await PdfManipulationService.deletePages(pdf, [1]);
        expect(result, isA<Uint8List>());
        expect(result.length, greaterThan(0));
      });
    });

    group('addWatermark', () {
      test('adds watermark text', () async {
        final pdf = await _generateTestPdf(2);
        final result = await PdfManipulationService.addWatermark(
          pdf,
          'CONFIDENTIAL',
        );
        expect(result, isA<Uint8List>());
        expect(result.length, greaterThan(0));
      });
    });

    group('generateBlankPdf', () {
      test('generates blank PDF with specified pages', () async {
        final pdf =
            await PdfManipulationService.generateBlankPdf(pages: 5);
        expect(pdf, isA<Uint8List>());
        expect(pdf.length, greaterThan(0));
      });
    });
  });
}
