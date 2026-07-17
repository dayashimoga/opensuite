import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:opensuite/features/document_editor/services/pdf_export_service.dart';

void main() {
  group('PdfExportService', () {
    group('exportFromDelta', () {
      test('generates valid PDF bytes from simple text', () async {
        final bytes = await PdfExportService.exportFromDelta(
          deltaJson: jsonEncode([
            {'insert': 'Hello World\n'}
          ]),
          plainText: 'Hello World',
          title: 'Test PDF',
        );

        expect(bytes, isNotEmpty);
        // PDF files start with %PDF
        expect(String.fromCharCodes(bytes.take(4)), '%PDF');
      });

      test('generates PDF from formatted text', () async {
        final bytes = await PdfExportService.exportFromDelta(
          deltaJson: jsonEncode([
            {
              'insert': 'Bold Text',
              'attributes': {'bold': true}
            },
            {'insert': '\n'},
            {
              'insert': 'Italic Text',
              'attributes': {'italic': true}
            },
            {'insert': '\n'},
          ]),
          plainText: 'Bold Text\nItalic Text',
          title: 'Formatted PDF',
        );

        expect(bytes, isNotEmpty);
        expect(String.fromCharCodes(bytes.take(4)), '%PDF');
      });

      test('generates PDF from headings', () async {
        final bytes = await PdfExportService.exportFromDelta(
          deltaJson: jsonEncode([
            {'insert': 'Main Title'},
            {
              'insert': '\n',
              'attributes': {'header': 1}
            },
            {'insert': 'Subtitle'},
            {
              'insert': '\n',
              'attributes': {'header': 2}
            },
            {'insert': 'Body text\n'},
          ]),
          plainText: 'Main Title\nSubtitle\nBody text',
          title: 'Headings PDF',
        );

        expect(bytes, isNotEmpty);
        expect(bytes.length, greaterThan(100));
      });

      test('generates PDF from lists', () async {
        final bytes = await PdfExportService.exportFromDelta(
          deltaJson: jsonEncode([
            {'insert': 'Item 1'},
            {
              'insert': '\n',
              'attributes': {'list': 'bullet'}
            },
            {'insert': 'Item 2'},
            {
              'insert': '\n',
              'attributes': {'list': 'bullet'}
            },
            {'insert': 'Step 1'},
            {
              'insert': '\n',
              'attributes': {'list': 'ordered'}
            },
          ]),
          plainText: 'Item 1\nItem 2\nStep 1',
          title: 'Lists PDF',
        );

        expect(bytes, isNotEmpty);
      });

      test('handles empty document', () async {
        final bytes = await PdfExportService.exportFromDelta(
          deltaJson: jsonEncode([
            {'insert': '\n'}
          ]),
          plainText: '',
          title: 'Empty PDF',
        );

        expect(bytes, isNotEmpty);
        expect(String.fromCharCodes(bytes.take(4)), '%PDF');
      });

      test('handles invalid delta JSON gracefully', () async {
        final bytes = await PdfExportService.exportFromDelta(
          deltaJson: 'invalid json',
          plainText: 'Fallback text',
          title: 'Fallback PDF',
        );

        expect(bytes, isNotEmpty);
        expect(String.fromCharCodes(bytes.take(4)), '%PDF');
      });

      test('generates PDF with color text', () async {
        final bytes = await PdfExportService.exportFromDelta(
          deltaJson: jsonEncode([
            {
              'insert': 'Red text',
              'attributes': {'color': '#FF0000'}
            },
            {'insert': '\n'},
          ]),
          plainText: 'Red text',
          title: 'Color PDF',
        );

        expect(bytes, isNotEmpty);
      });

      test('generates PDF with alignment', () async {
        final bytes = await PdfExportService.exportFromDelta(
          deltaJson: jsonEncode([
            {'insert': 'Centered text'},
            {
              'insert': '\n',
              'attributes': {'align': 'center'}
            },
          ]),
          plainText: 'Centered text',
          title: 'Aligned PDF',
        );

        expect(bytes, isNotEmpty);
      });
    });

    group('exportFromPlainText', () {
      test('generates PDF from plain text', () async {
        final bytes = await PdfExportService.exportFromPlainText(
          text: 'Simple plain text content for testing.',
          title: 'Plain Text PDF',
        );

        expect(bytes, isNotEmpty);
        expect(String.fromCharCodes(bytes.take(4)), '%PDF');
      });

      test('handles multiline text', () async {
        final bytes = await PdfExportService.exportFromPlainText(
          text: 'Line 1\nLine 2\nLine 3\n\nParagraph 2',
          title: 'Multiline PDF',
        );

        expect(bytes, isNotEmpty);
      });
    });
  });
}
