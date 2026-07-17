import 'dart:typed_data';

/// OCR engine interface — pluggable backend for text recognition.
///
/// Implementations can wrap:
/// - Google Cloud Vision API
/// - Tesseract.js (via web bridge)
/// - On-device ML Kit
/// - Azure Computer Vision
abstract class OcrEngine {
  /// Recognize text in an image.
  ///
  /// Returns recognized text or throws on failure.
  Future<OcrResult> recognizeText(Uint8List imageBytes);

  /// Whether this engine is configured and ready to use.
  bool get isConfigured;

  /// Display name of this engine.
  String get engineName;
}

/// Result of OCR text recognition.
class OcrResult {
  final String text;
  final double confidence;
  final List<OcrTextBlock> blocks;

  const OcrResult({
    required this.text,
    this.confidence = 0.0,
    this.blocks = const [],
  });
}

/// A block of recognized text with position information.
class OcrTextBlock {
  final String text;
  final double x;
  final double y;
  final double width;
  final double height;
  final double confidence;

  const OcrTextBlock({
    required this.text,
    this.x = 0,
    this.y = 0,
    this.width = 0,
    this.height = 0,
    this.confidence = 0,
  });
}

/// Stub OCR engine that returns a "not configured" message.
///
/// Replace with a real implementation by extending [OcrEngine].
class StubOcrEngine implements OcrEngine {
  @override
  String get engineName => 'Stub OCR';

  @override
  bool get isConfigured => false;

  @override
  Future<OcrResult> recognizeText(Uint8List imageBytes) async {
    return const OcrResult(
      text: 'OCR engine not configured. '
          'Please configure an OCR backend in Settings → OCR.',
      confidence: 0.0,
    );
  }
}

/// OCR service that manages the active OCR engine.
class OcrService {
  OcrEngine _engine;

  OcrService({OcrEngine? engine}) : _engine = engine ?? StubOcrEngine();

  /// Set the active OCR engine.
  void setEngine(OcrEngine engine) => _engine = engine;

  /// Get the active OCR engine.
  OcrEngine get engine => _engine;

  /// Whether an OCR engine is configured.
  bool get isConfigured => _engine.isConfigured;

  /// Recognize text from image bytes.
  Future<OcrResult> recognize(Uint8List imageBytes) =>
      _engine.recognizeText(imageBytes);
}
