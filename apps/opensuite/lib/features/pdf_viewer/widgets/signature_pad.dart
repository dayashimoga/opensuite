import 'package:flutter/material.dart';

/// Touch/mouse signature capture widget.
///
/// Captures drawn signatures and provides the result as a list of
/// [Offset] points that can be rendered to an image.
class SignaturePad extends StatefulWidget {
  final Color penColor;
  final double penWidth;
  final Color backgroundColor;
  final ValueChanged<List<List<Offset>>>? onChanged;

  const SignaturePad({
    super.key,
    this.penColor = Colors.black,
    this.penWidth = 2.0,
    this.backgroundColor = Colors.white,
    this.onChanged,
  });

  @override
  State<SignaturePad> createState() => _SignaturePadState();
}

class _SignaturePadState extends State<SignaturePad> {
  final List<List<Offset>> _strokes = [];
  List<Offset> _currentStroke = [];

  void clear() {
    setState(() {
      _strokes.clear();
      _currentStroke = [];
    });
    widget.onChanged?.call(_strokes);
  }

  bool get isEmpty => _strokes.isEmpty && _currentStroke.isEmpty;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 200,
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            border: Border.all(color: Theme.of(context).dividerColor),
            borderRadius: BorderRadius.circular(8),
          ),
          child: GestureDetector(
            onPanStart: (details) {
              setState(() {
                _currentStroke = [details.localPosition];
              });
            },
            onPanUpdate: (details) {
              setState(() {
                _currentStroke.add(details.localPosition);
              });
            },
            onPanEnd: (_) {
              setState(() {
                if (_currentStroke.isNotEmpty) {
                  _strokes.add(List.from(_currentStroke));
                }
                _currentStroke = [];
              });
              widget.onChanged?.call(_strokes);
            },
            child: CustomPaint(
              size: Size.infinite,
              painter: _SignaturePainter(
                strokes: _strokes,
                currentStroke: _currentStroke,
                penColor: widget.penColor,
                penWidth: widget.penWidth,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton.icon(
              icon: const Icon(Icons.clear, size: 18),
              label: const Text('Clear'),
              onPressed: clear,
            ),
          ],
        ),
      ],
    );
  }
}

class _SignaturePainter extends CustomPainter {
  final List<List<Offset>> strokes;
  final List<Offset> currentStroke;
  final Color penColor;
  final double penWidth;

  _SignaturePainter({
    required this.strokes,
    required this.currentStroke,
    required this.penColor,
    required this.penWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = penColor
      ..strokeWidth = penWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (final stroke in strokes) {
      if (stroke.length < 2) continue;
      final path = Path()..moveTo(stroke.first.dx, stroke.first.dy);
      for (int i = 1; i < stroke.length; i++) {
        path.lineTo(stroke[i].dx, stroke[i].dy);
      }
      canvas.drawPath(path, paint);
    }

    if (currentStroke.length >= 2) {
      final path = Path()
        ..moveTo(currentStroke.first.dx, currentStroke.first.dy);
      for (int i = 1; i < currentStroke.length; i++) {
        path.lineTo(currentStroke[i].dx, currentStroke[i].dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter old) => true;
}
