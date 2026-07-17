import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opensuite/features/document_editor/services/docx_service.dart';

void main() {
  group('DocxService', () {
    group('exportFromDelta', () {
      test('exports valid ZIP archive with required OOXML parts', () {
        final bytes = DocxService.exportFromDelta(
          deltaJson: jsonEncode([
            {'insert': 'Hello World\n'}
          ]),
          plainText: 'Hello World',
          title: 'Test Doc',
        );

        expect(bytes, isNotEmpty);

        // Verify it's a valid ZIP
        final archive = ZipDecoder().decodeBytes(bytes);
        final fileNames = archive.map((f) => f.name).toSet();

        expect(fileNames, contains('[Content_Types].xml'));
        expect(fileNames, contains('_rels/.rels'));
        expect(fileNames, contains('word/document.xml'));
        expect(fileNames, contains('word/styles.xml'));
        expect(fileNames, contains('word/settings.xml'));
        expect(fileNames, contains('word/_rels/document.xml.rels'));
        expect(fileNames, contains('docProps/core.xml'));
        expect(fileNames, contains('docProps/app.xml'));
      });

      test('document.xml contains text content', () {
        final bytes = DocxService.exportFromDelta(
          deltaJson: jsonEncode([
            {'insert': 'Test paragraph content\n'}
          ]),
          plainText: 'Test paragraph content',
          title: 'Title',
        );

        final archive = ZipDecoder().decodeBytes(bytes);
        final docFile =
            archive.firstWhere((f) => f.name == 'word/document.xml');
        final docXml = utf8.decode(docFile.content as List<int>);

        expect(docXml, contains('Test paragraph content'));
        expect(docXml, contains('w:document'));
        expect(docXml, contains('w:body'));
        expect(docXml, contains('w:p'));
      });

      test('exports bold/italic formatting as run properties', () {
        final bytes = DocxService.exportFromDelta(
          deltaJson: jsonEncode([
            {
              'insert': 'Bold text',
              'attributes': {'bold': true}
            },
            {'insert': '\n'},
          ]),
          plainText: 'Bold text',
          title: 'Format Test',
        );

        final archive = ZipDecoder().decodeBytes(bytes);
        final docFile =
            archive.firstWhere((f) => f.name == 'word/document.xml');
        final docXml = utf8.decode(docFile.content as List<int>);

        expect(docXml, contains('<w:b/>'));
        expect(docXml, contains('Bold text'));
      });

      test('exports heading as paragraph style', () {
        final bytes = DocxService.exportFromDelta(
          deltaJson: jsonEncode([
            {'insert': 'My Heading'},
            {
              'insert': '\n',
              'attributes': {'header': 1}
            },
          ]),
          plainText: 'My Heading',
          title: 'Heading Test',
        );

        final archive = ZipDecoder().decodeBytes(bytes);
        final docFile =
            archive.firstWhere((f) => f.name == 'word/document.xml');
        final docXml = utf8.decode(docFile.content as List<int>);

        expect(docXml, contains('Heading1'));
        expect(docXml, contains('My Heading'));
      });

      test('core.xml contains document title', () {
        final bytes = DocxService.exportFromDelta(
          deltaJson: jsonEncode([
            {'insert': '\n'}
          ]),
          plainText: '',
          title: 'Document Title Test',
        );

        final archive = ZipDecoder().decodeBytes(bytes);
        final coreFile =
            archive.firstWhere((f) => f.name == 'docProps/core.xml');
        final coreXml = utf8.decode(coreFile.content as List<int>);

        expect(coreXml, contains('Document Title Test'));
        expect(coreXml, contains('OpenSuite'));
      });

      test('escapes XML special characters', () {
        final bytes = DocxService.exportFromDelta(
          deltaJson: jsonEncode([
            {'insert': 'A < B & C > D\n'}
          ]),
          plainText: 'A < B & C > D',
          title: 'Escape Test',
        );

        final archive = ZipDecoder().decodeBytes(bytes);
        final docFile =
            archive.firstWhere((f) => f.name == 'word/document.xml');
        final docXml = utf8.decode(docFile.content as List<int>);

        expect(docXml, contains('&lt;'));
        expect(docXml, contains('&amp;'));
        expect(docXml, contains('&gt;'));
      });

      test('handles invalid delta JSON gracefully', () {
        final bytes = DocxService.exportFromDelta(
          deltaJson: 'not valid json',
          plainText: 'Fallback text',
          title: 'Fallback',
        );

        expect(bytes, isNotEmpty);
        final archive = ZipDecoder().decodeBytes(bytes);
        final docFile =
            archive.firstWhere((f) => f.name == 'word/document.xml');
        final docXml = utf8.decode(docFile.content as List<int>);

        expect(docXml, contains('Fallback text'));
      });
    });

    group('importToDocument', () {
      test('round-trips simple text through export/import', () {
        final originalDelta = jsonEncode([
          {'insert': 'Hello World\n'}
        ]);

        final exported = DocxService.exportFromDelta(
          deltaJson: originalDelta,
          plainText: 'Hello World',
          title: 'Round Trip',
        );

        final imported = DocxService.importToDocument(
          fileBytes: exported,
          fileName: 'round_trip.docx',
        );

        expect(imported['title'], isNotEmpty);
        expect(imported['deltaJson'], isNotNull);
        expect(imported['plainText'], contains('Hello World'));

        // Verify Delta JSON is valid
        final deltaOps = jsonDecode(imported['deltaJson']!) as List<dynamic>;
        expect(deltaOps, isNotEmpty);
      });

      test('round-trips formatted text', () {
        final formattedDelta = jsonEncode([
          {
            'insert': 'Bold',
            'attributes': {'bold': true}
          },
          {'insert': ' and '},
          {
            'insert': 'italic',
            'attributes': {'italic': true}
          },
          {'insert': '\n'},
        ]);

        final exported = DocxService.exportFromDelta(
          deltaJson: formattedDelta,
          plainText: 'Bold and italic',
          title: 'Format Round Trip',
        );

        final imported = DocxService.importToDocument(
          fileBytes: exported,
          fileName: 'format_test.docx',
        );

        final deltaOps = jsonDecode(imported['deltaJson']!) as List<dynamic>;

        // Find bold operation
        final boldOp = deltaOps.firstWhere(
          (op) =>
              op is Map &&
              (op['attributes'] as Map?)?.containsKey('bold') == true,
          orElse: () => null,
        );
        expect(boldOp, isNotNull, reason: 'Should preserve bold formatting');

        // Find italic operation
        final italicOp = deltaOps.firstWhere(
          (op) =>
              op is Map &&
              (op['attributes'] as Map?)?.containsKey('italic') == true,
          orElse: () => null,
        );
        expect(italicOp, isNotNull,
            reason: 'Should preserve italic formatting');
      });

      test('extracts title from core.xml', () {
        final exported = DocxService.exportFromDelta(
          deltaJson: jsonEncode([
            {'insert': '\n'}
          ]),
          plainText: '',
          title: 'My Special Title',
        );

        final imported = DocxService.importToDocument(
          fileBytes: exported,
          fileName: 'test.docx',
        );

        expect(imported['title'], 'My Special Title');
      });

      test('throws on invalid ZIP', () {
        expect(
          () => DocxService.importToDocument(
            fileBytes: Uint8List.fromList([1, 2, 3, 4]),
            fileName: 'invalid.docx',
          ),
          throwsA(isA<Exception>()),
        );
      });
    });
  });
}
