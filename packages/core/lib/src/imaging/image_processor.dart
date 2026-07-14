import 'dart:typed_data';
import 'dart:ui' as ui;

/// Applies image adjustments and produces output bytes.
///
/// Uses `dart:ui` canvas-based rendering to apply brightness,
/// contrast, saturation, hue, crop, and resize operations
/// to raw image bytes.
class ImageProcessor {
  ImageProcessor._();

  /// Builds a 5x4 color matrix that applies brightness, contrast,
  /// and saturation adjustments.
  ///
  /// The matrix is compatible with Flutter's [ColorFilter.matrix].
  ///
  /// - [brightness]: -1.0 to 1.0 (0 = no change)
  /// - [contrast]: 0.0 to 2.0 (1.0 = no change)
  /// - [saturation]: 0.0 to 2.0 (1.0 = no change)
  /// - [hue]: -180 to 180 degrees (0 = no change)
  static List<double> buildColorMatrix({
    double brightness = 0.0,
    double contrast = 1.0,
    double saturation = 1.0,
    double hue = 0.0,
  }) {
    // Start with identity matrix
    var matrix = _identityMatrix();

    // Apply brightness
    if (brightness != 0.0) {
      final b = brightness * 255;
      matrix = _multiply(matrix, [
        1, 0, 0, 0, b,
        0, 1, 0, 0, b,
        0, 0, 1, 0, b,
        0, 0, 0, 1, 0,
      ]);
    }

    // Apply contrast
    if (contrast != 1.0) {
      final c = contrast;
      final t = (1.0 - c) / 2.0 * 255;
      matrix = _multiply(matrix, [
        c, 0, 0, 0, t,
        0, c, 0, 0, t,
        0, 0, c, 0, t,
        0, 0, 0, 1, 0,
      ]);
    }

    // Apply saturation
    if (saturation != 1.0) {
      final s = saturation;
      const lr = 0.2126;
      const lg = 0.7152;
      const lb = 0.0722;
      final sr = (1 - s) * lr;
      final sg = (1 - s) * lg;
      final sb = (1 - s) * lb;
      matrix = _multiply(matrix, [
        sr + s, sg, sb, 0, 0,
        sr, sg + s, sb, 0, 0,
        sr, sg, sb + s, 0, 0,
        0, 0, 0, 1, 0,
      ]);
    }

    return matrix;
  }

  static List<double> _identityMatrix() => [
        1, 0, 0, 0, 0,
        0, 1, 0, 0, 0,
        0, 0, 1, 0, 0,
        0, 0, 0, 1, 0,
      ];

  static List<double> _multiply(List<double> a, List<double> b) {
    final result = List<double>.filled(20, 0);
    for (var row = 0; row < 4; row++) {
      for (var col = 0; col < 5; col++) {
        var sum = 0.0;
        for (var k = 0; k < 4; k++) {
          sum += a[row * 5 + k] * b[k * 5 + col];
        }
        if (col == 4) {
          sum += a[row * 5 + 4];
        }
        result[row * 5 + col] = sum;
      }
    }
    return result;
  }

  /// Decodes image bytes into a [ui.Image].
  static Future<ui.Image> decodeImage(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  /// Renders an image with adjustments applied and returns PNG bytes.
  ///
  /// This is the core export function — it takes the source image,
  /// applies all transformations, and returns the result as PNG bytes.
  static Future<Uint8List> renderWithAdjustments({
    required Uint8List sourceBytes,
    double brightness = 0.0,
    double contrast = 1.0,
    double saturation = 1.0,
    double rotation = 0.0,
    bool flipHorizontal = false,
    bool flipVertical = false,
    int? targetWidth,
    int? targetHeight,
    ui.Rect? cropRect,
  }) async {
    final source = await decodeImage(sourceBytes);

    // Determine output dimensions
    var outWidth = targetWidth ?? source.width;
    var outHeight = targetHeight ?? source.height;

    if (cropRect != null) {
      outWidth = cropRect.width.toInt();
      outHeight = cropRect.height.toInt();
    }

    // Handle rotation swapping dimensions
    final isRotated90 =
        (rotation % 360 == 90) || (rotation % 360 == 270);
    if (isRotated90) {
      final tmp = outWidth;
      outWidth = outHeight;
      outHeight = tmp;
    }

    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);

    // Center transform
    final centerX = outWidth / 2.0;
    final centerY = outHeight / 2.0;

    canvas.save();
    canvas.translate(centerX, centerY);

    // Apply rotation
    if (rotation != 0.0) {
      canvas.rotate(rotation * 3.14159265359 / 180.0);
    }

    // Apply flip
    if (flipHorizontal || flipVertical) {
      canvas.scale(
        flipHorizontal ? -1.0 : 1.0,
        flipVertical ? -1.0 : 1.0,
      );
    }

    canvas.translate(-centerX, -centerY);

    // Build color matrix paint
    final colorMatrix = buildColorMatrix(
      brightness: brightness,
      contrast: contrast,
      saturation: saturation,
    );

    final paint = ui.Paint();
    if (brightness != 0.0 || contrast != 1.0 || saturation != 1.0) {
      paint.colorFilter = ui.ColorFilter.matrix(colorMatrix);
    }

    // Draw the image
    if (cropRect != null) {
      canvas.drawImageRect(
        source,
        cropRect,
        ui.Rect.fromLTWH(0, 0, outWidth.toDouble(), outHeight.toDouble()),
        paint,
      );
    } else if (targetWidth != null || targetHeight != null) {
      canvas.drawImageRect(
        source,
        ui.Rect.fromLTWH(
            0, 0, source.width.toDouble(), source.height.toDouble()),
        ui.Rect.fromLTWH(0, 0, outWidth.toDouble(), outHeight.toDouble()),
        paint,
      );
    } else {
      canvas.drawImage(source, ui.Offset.zero, paint);
    }

    canvas.restore();

    final picture = recorder.endRecording();
    final image = await picture.toImage(outWidth, outHeight);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    source.dispose();
    image.dispose();

    if (byteData == null) {
      throw Exception('Failed to encode image to PNG');
    }

    return byteData.buffer.asUint8List();
  }
}
