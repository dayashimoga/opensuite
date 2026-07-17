import 'package:flutter/material.dart';

/// Data for a single drawing stroke.
class DrawingStroke {
  final List<Offset> points;
  final Color color;
  final double width;
  final bool isEraser;

  const DrawingStroke({
    required this.points,
    this.color = Colors.black,
    this.width = 3.0,
    this.isEraser = false,
  });
}

/// Freehand drawing canvas overlay for the image editor.
class DrawingCanvas extends StatefulWidget {
  final Size canvasSize;
  final Color penColor;
  final double penWidth;
  final bool isEraser;
  final bool enabled;
  final List<DrawingStroke> existingStrokes;
  final ValueChanged<List<DrawingStroke>>? onStrokesChanged;

  const DrawingCanvas({
    super.key,
    required this.canvasSize,
    this.penColor = Colors.black,
    this.penWidth = 3.0,
    this.isEraser = false,
    this.enabled = true,
    this.existingStrokes = const [],
    this.onStrokesChanged,
  });

  @override
  State<DrawingCanvas> createState() => _DrawingCanvasState();
}

class _DrawingCanvasState extends State<DrawingCanvas> {
  late List<DrawingStroke> _strokes;
  List<Offset> _currentPoints = [];

  @override
  void initState() {
    super.initState();
    _strokes = List.from(widget.existingStrokes);
  }

  @override
  void didUpdateWidget(covariant DrawingCanvas old) {
    super.didUpdateWidget(old);
    if (old.existingStrokes != widget.existingStrokes) {
      _strokes = List.from(widget.existingStrokes);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: widget.enabled
          ? (d) => setState(() => _currentPoints = [d.localPosition])
          : null,
      onPanUpdate: widget.enabled
          ? (d) => setState(() => _currentPoints.add(d.localPosition))
          : null,
      onPanEnd: widget.enabled
          ? (_) {
              if (_currentPoints.isNotEmpty) {
                setState(() {
                  _strokes.add(DrawingStroke(
                    points: List.from(_currentPoints),
                    color: widget.penColor,
                    width: widget.penWidth,
                    isEraser: widget.isEraser,
                  ));
                  _currentPoints = [];
                });
                widget.onStrokesChanged?.call(_strokes);
              }
            }
          : null,
      child: CustomPaint(
        size: widget.canvasSize,
        painter: _DrawingPainter(
          strokes: _strokes,
          currentPoints: _currentPoints,
          currentColor: widget.penColor,
          currentWidth: widget.penWidth,
          isEraser: widget.isEraser,
        ),
      ),
    );
  }
}

class _DrawingPainter extends CustomPainter {
  final List<DrawingStroke> strokes;
  final List<Offset> currentPoints;
  final Color currentColor;
  final double currentWidth;
  final bool isEraser;

  _DrawingPainter({
    required this.strokes,
    required this.currentPoints,
    required this.currentColor,
    required this.currentWidth,
    required this.isEraser,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      _drawStroke(
          canvas, stroke.points, stroke.color, stroke.width, stroke.isEraser);
    }
    if (currentPoints.isNotEmpty) {
      _drawStroke(canvas, currentPoints, currentColor, currentWidth, isEraser);
    }
  }

  void _drawStroke(Canvas canvas, List<Offset> points, Color color,
      double width, bool eraser) {
    if (points.length < 2) return;
    final paint = Paint()
      ..color = eraser ? Colors.white : color
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..blendMode = eraser ? BlendMode.clear : BlendMode.srcOver;
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _DrawingPainter old) => true;
}
