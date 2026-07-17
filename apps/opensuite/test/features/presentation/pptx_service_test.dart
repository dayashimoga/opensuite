import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:fileutility_core/fileutility_core.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:opensuite/features/presentation/services/pptx_service.dart';

void main() {
  group('PptxService', () {
    group('exportToPptx', () {
      test('exports single slide with text element', () {
        final slides = [
          SlideData(
            id: 'slide1',
            backgroundColor: '#FFFFFF',
            elements: [
              const SlideElement(
                id: 'el1',
                type: 'text',
                content: 'Hello World',
                x: 0.1,
                y: 0.1,
                width: 0.4,
                height: 0.2,
                fontSize: 36,
                fontWeight: 'bold',
                textColor: '#000000',
              ),
            ],
          ),
        ];

        final bytes = PptxService.exportToPptx(
          slides: slides,
          title: 'Test Presentation',
        );

        expect(bytes, isA<Uint8List>());
        expect(bytes.length, greaterThan(0));

        // Verify it's a valid ZIP archive
        final archive = ZipDecoder().decodeBytes(bytes);
        expect(archive.files.length, greaterThan(0));

        // Verify required PPTX files
        final fileNames = archive.files.map((f) => f.name).toList();
        expect(fileNames, contains('[Content_Types].xml'));
        expect(fileNames, contains('ppt/presentation.xml'));
        expect(fileNames, contains('ppt/slides/slide1.xml'));
        expect(fileNames, contains('ppt/theme/theme1.xml'));
      });

      test('exports multiple slides', () {
        final slides = [
          SlideData(id: '1', elements: const []),
          SlideData(id: '2', elements: const []),
          SlideData(id: '3', elements: const []),
        ];

        final bytes = PptxService.exportToPptx(
          slides: slides,
          title: 'Multi',
        );

        final archive = ZipDecoder().decodeBytes(bytes);
        final slideFiles = archive.files
            .where((f) => f.name.startsWith('ppt/slides/slide'))
            .toList();
        expect(slideFiles.length, equals(3));
      });

      test('handles shape elements', () {
        final slides = [
          SlideData(
            id: 'slide1',
            elements: [
              const SlideElement(
                id: 'shape1',
                type: 'shape',
                shapeType: 'circle',
                fillColor: '#FF0000',
                x: 0.3,
                y: 0.3,
                width: 0.2,
                height: 0.2,
              ),
            ],
          ),
        ];

        final bytes = PptxService.exportToPptx(
          slides: slides,
          title: 'Shapes',
        );

        expect(bytes.length, greaterThan(0));

        // Verify slide XML contains the shape
        final archive = ZipDecoder().decodeBytes(bytes);
        final slideFile = archive.files
            .firstWhere((f) => f.name == 'ppt/slides/slide1.xml');
        final slideXml =
            utf8.decode(slideFile.content as List<int>);
        expect(slideXml, contains('ellipse'));
      });

      test('handles background colors', () {
        final slides = [
          SlideData(
            id: 'slide1',
            backgroundColor: '#336699',
            elements: const [],
          ),
        ];

        final bytes = PptxService.exportToPptx(
          slides: slides,
          title: 'BG Test',
        );

        final archive = ZipDecoder().decodeBytes(bytes);
        final slideFile = archive.files
            .firstWhere((f) => f.name == 'ppt/slides/slide1.xml');
        final slideXml =
            utf8.decode(slideFile.content as List<int>);
        expect(slideXml, contains('336699'));
      });
    });

    group('importFromPptx', () {
      test('imports PPTX bytes to SlideData list', () {
        // First export, then import round-trip
        final originalSlides = [
          SlideData(
            id: 'slide1',
            backgroundColor: '#FFFFFF',
            elements: [
              const SlideElement(
                id: 'text1',
                type: 'text',
                content: 'Test Content',
                fontSize: 28,
                x: 0.1,
                y: 0.1,
                width: 0.3,
                height: 0.2,
              ),
            ],
          ),
        ];

        final bytes = PptxService.exportToPptx(
          slides: originalSlides,
          title: 'Round Trip',
        );

        final imported = PptxService.importFromPptx(fileBytes: bytes);

        expect(imported.length, equals(1));
        expect(imported.first.elements.isNotEmpty, isTrue);
      });

      test('handles empty PPTX', () {
        final slides = [
          SlideData(id: 'empty', elements: const []),
        ];

        final bytes = PptxService.exportToPptx(
          slides: slides,
          title: 'Empty',
        );

        final imported = PptxService.importFromPptx(fileBytes: bytes);
        expect(imported.length, equals(1));
      });

      test('returns at least one slide for invalid data', () {
        // Create a minimal valid ZIP but no valid slide XML
        final archive = Archive();
        archive.addFile(ArchiveFile(
          'dummy.txt',
          0,
          utf8.encode('not a pptx'),
        ));
        final bytes = Uint8List.fromList(ZipEncoder().encode(archive)!);

        final imported = PptxService.importFromPptx(fileBytes: bytes);
        expect(imported.length, greaterThanOrEqualTo(1));
      });
    });
  });
}
