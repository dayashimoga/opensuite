import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:opensuite/features/pdf_viewer/services/ocr_service.dart';

void main() {
  group('StubOcrEngine', () {
    late StubOcrEngine engine;

    setUp(() {
      engine = StubOcrEngine();
    });

    test('engineName returns Stub OCR', () {
      expect(engine.engineName, 'Stub OCR');
    });

    test('isConfigured returns false', () {
      expect(engine.isConfigured, false);
    });

    test('recognizeText returns not configured message', () async {
      final result = await engine.recognizeText(Uint8List(0));
      expect(result.text, contains('not configured'));
      expect(result.confidence, 0.0);
      expect(result.blocks, isEmpty);
    });
  });

  group('OcrService', () {
    late OcrService service;

    setUp(() {
      service = OcrService();
    });

    test('defaults to StubOcrEngine', () {
      expect(service.engine, isA<StubOcrEngine>());
      expect(service.isConfigured, false);
    });

    test('setEngine replaces the engine', () {
      final custom = _MockOcrEngine();
      service.setEngine(custom);
      expect(service.engine, same(custom));
      expect(service.isConfigured, true);
    });

    test('recognize delegates to active engine', () async {
      final result = await service.recognize(Uint8List(0));
      expect(result.text, contains('not configured'));
    });

    test('recognize with custom engine returns custom result', () async {
      service.setEngine(_MockOcrEngine());
      final result = await service.recognize(Uint8List.fromList([1, 2, 3]));
      expect(result.text, 'Mock OCR result');
      expect(result.confidence, 0.95);
    });
  });

  group('OcrResult', () {
    test('creates with defaults', () {
      const result = OcrResult(text: 'hello');
      expect(result.text, 'hello');
      expect(result.confidence, 0.0);
      expect(result.blocks, isEmpty);
    });

    test('creates with blocks', () {
      const result = OcrResult(
        text: 'hello world',
        confidence: 0.9,
        blocks: [
          OcrTextBlock(text: 'hello', x: 10, y: 20, width: 50, height: 15),
          OcrTextBlock(text: 'world', x: 70, y: 20, width: 50, height: 15),
        ],
      );
      expect(result.blocks.length, 2);
      expect(result.blocks.first.text, 'hello');
      expect(result.blocks.first.x, 10);
    });
  });
}

class _MockOcrEngine implements OcrEngine {
  @override
  String get engineName => 'Mock';

  @override
  bool get isConfigured => true;

  @override
  Future<OcrResult> recognizeText(Uint8List imageBytes) async {
    return const OcrResult(
      text: 'Mock OCR result',
      confidence: 0.95,
      blocks: [OcrTextBlock(text: 'Mock OCR result')],
    );
  }
}
