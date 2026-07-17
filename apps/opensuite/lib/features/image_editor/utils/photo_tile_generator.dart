import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class PaperFormat {
  final String name;
  final double widthMm;
  final double heightMm;
  const PaperFormat(this.name, this.widthMm, this.heightMm);
}

class PhotoFormat {
  final String name;
  final double widthMm;
  final double heightMm;
  const PhotoFormat(this.name, this.widthMm, this.heightMm);
}

class PhotoTileConfig {
  static const List<PaperFormat> paperFormats = [
    PaperFormat('A4 (210 × 297 mm)', 210, 297),
    PaperFormat('A3 (297 × 420 mm)', 297, 420),
    PaperFormat('B4 (250 × 353 mm)', 250, 353),
    PaperFormat('B5 (176 × 250 mm)', 176, 250),
    PaperFormat('Letter (8.5 × 11 in)', 215.9, 279.4),
    PaperFormat('Legal (8.5 × 14 in)', 215.9, 355.6),
  ];

  static const List<PhotoFormat> photoFormats = [
    PhotoFormat('Passport (35 × 45 mm)', 35, 45),
    PhotoFormat('Passport US/India (2 × 2 in)', 50.8, 50.8),
    PhotoFormat('Stamp Size (20 × 25 mm)', 20, 25),
    PhotoFormat('Schengen Visa (35 × 45 mm)', 35, 45),
    PhotoFormat('Postcard 4×6 in (102 × 152 mm)', 101.6, 152.4),
    PhotoFormat('Wallet (64 × 89 mm)', 63.5, 88.9),
  ];
}

class TileCalculation {
  final int cols;
  final int rows;
  final int totalTiles;
  final double marginMm;
  final double gapMm;

  TileCalculation({
    required this.cols,
    required this.rows,
    required this.totalTiles,
    required this.marginMm,
    required this.gapMm,
  });

  static TileCalculation calculate({
    required PaperFormat paper,
    required PhotoFormat photo,
    double marginMm = 5.0,
    double gapMm = 2.0,
  }) {
    final availW = paper.widthMm - (2 * marginMm);
    final availH = paper.heightMm - (2 * marginMm);

    final cols = (availW + gapMm) ~/ (photo.widthMm + gapMm);
    final rows = (availH + gapMm) ~/ (photo.heightMm + gapMm);

    final maxCols = cols > 0 ? cols : 1;
    final maxRows = rows > 0 ? rows : 1;

    return TileCalculation(
      cols: maxCols,
      rows: maxRows,
      totalTiles: maxCols * maxRows,
      marginMm: marginMm,
      gapMm: gapMm,
    );
  }
}

class PhotoTileGenerator {
  /// Renders a high-resolution printable sheet tiled with the given image bytes.
  static Future<Uint8List> generateTileSheet({
    required Uint8List sourceBytes,
    required PaperFormat paper,
    required PhotoFormat photo,
    double marginMm = 5.0,
    double gapMm = 2.0,
    bool drawCutLines = true,
  }) async {
    final codec = await ui.instantiateImageCodec(sourceBytes);
    final frame = await codec.getNextFrame();
    final sourceImage = frame.image;

    // 300 DPI Rendering Scale (1 mm = 11.811 pixels)
    const double pxPerMm = 11.811;

    final sheetW = (paper.widthMm * pxPerMm).toInt();
    final sheetH = (paper.heightMm * pxPerMm).toInt();

    final tile = TileCalculation.calculate(
      paper: paper,
      photo: photo,
      marginMm: marginMm,
      gapMm: gapMm,
    );

    final photoW = photo.widthMm * pxPerMm;
    final photoH = photo.heightMm * pxPerMm;
    final marginPx = marginMm * pxPerMm;
    final gapPx = gapMm * pxPerMm;

    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);

    // Draw white paper background
    canvas.drawRect(
      ui.Rect.fromLTWH(0, 0, sheetW.toDouble(), sheetH.toDouble()),
      ui.Paint()..color = Colors.white,
    );

    final tilePaint = ui.Paint()..filterQuality = ui.FilterQuality.high;
    final cutLinePaint = ui.Paint()
      ..color = Colors.grey.shade400
      ..strokeWidth = 1.5
      ..style = ui.PaintingStyle.stroke;

    final srcRect = ui.Rect.fromLTWH(
      0,
      0,
      sourceImage.width.toDouble(),
      sourceImage.height.toDouble(),
    );

    for (int r = 0; r < tile.rows; r++) {
      for (int c = 0; c < tile.cols; c++) {
        final x = marginPx + c * (photoW + gapPx);
        final y = marginPx + r * (photoH + gapPx);
        final dstRect = ui.Rect.fromLTWH(x, y, photoW, photoH);

        // Draw photo tile
        canvas.drawImageRect(sourceImage, srcRect, dstRect, tilePaint);

        // Draw optional cut lines around tile
        if (drawCutLines) {
          canvas.drawRect(dstRect, cutLinePaint);
        }
      }
    }

    final picture = recorder.endRecording();
    final sheetImage = await picture.toImage(sheetW, sheetH);
    final byteData =
        await sheetImage.toByteData(format: ui.ImageByteFormat.png);

    sourceImage.dispose();
    sheetImage.dispose();

    if (byteData == null) {
      throw Exception('Failed to generate photo tile sheet PNG');
    }

    return byteData.buffer.asUint8List();
  }
}
