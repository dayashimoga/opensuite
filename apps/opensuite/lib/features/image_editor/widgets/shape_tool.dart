import 'package:flutter/material.dart';

/// Shape overlay data.
class ShapeOverlayItem {
  final String id;

  /// 'rectangle', 'circle', 'line', 'arrow', 'triangle', 'star'
  final String shapeType;
  Offset position;
  Size size;
  Color fillColor;
  Color strokeColor;
  double strokeWidth;
  double rotation;

  ShapeOverlayItem({
    required this.id,
    this.shapeType = 'rectangle',
    this.position = Offset.zero,
    this.size = const Size(100, 80),
    this.fillColor = Colors.transparent,
    this.strokeColor = Colors.white,
    this.strokeWidth = 2.0,
    this.rotation = 0,
  });
}

/// Tool widget for adding shape overlays on images.
class ShapeTool extends StatefulWidget {
  final ValueChanged<ShapeOverlayItem>? onAdd;
  final List<ShapeOverlayItem> shapes;
  final ValueChanged<String>? onRemove;

  const ShapeTool({
    super.key,
    this.onAdd,
    this.shapes = const [],
    this.onRemove,
  });

  @override
  State<ShapeTool> createState() => _ShapeToolState();
}

class _ShapeToolState extends State<ShapeTool> {
  String _selectedShape = 'rectangle';
  Color _fillColor = Colors.transparent;
  final Color _strokeColor = Colors.white;
  double _strokeWidth = 2.0;

  static const _shapeTypes = [
    ('rectangle', Icons.rectangle_outlined, 'Rectangle'),
    ('circle', Icons.circle_outlined, 'Circle'),
    ('triangle', Icons.change_history, 'Triangle'),
    ('line', Icons.horizontal_rule, 'Line'),
    ('arrow', Icons.arrow_forward, 'Arrow'),
    ('star', Icons.star_outline, 'Star'),
  ];

  void _addShape() {
    widget.onAdd?.call(ShapeOverlayItem(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      shapeType: _selectedShape,
      position: const Offset(50, 50),
      fillColor: _fillColor,
      strokeColor: _strokeColor,
      strokeWidth: _strokeWidth,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        border: Border(top: BorderSide(color: theme.dividerColor)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Shape Tool', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: _shapeTypes.map((s) {
              final selected = _selectedShape == s.$1;
              return ChoiceChip(
                avatar: Icon(s.$2, size: 16),
                label: Text(s.$3, style: const TextStyle(fontSize: 11)),
                selected: selected,
                onSelected: (_) => setState(() => _selectedShape = s.$1),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text('Stroke: ${_strokeWidth.round()}',
                  style: const TextStyle(fontSize: 12)),
              Expanded(
                child: Slider(
                  value: _strokeWidth,
                  min: 1,
                  max: 10,
                  onChanged: (v) => setState(() => _strokeWidth = v),
                ),
              ),
            ],
          ),
          Row(
            children: [
              const Text('Fill:', style: TextStyle(fontSize: 12)),
              const SizedBox(width: 8),
              ...[
                Colors.transparent,
                Colors.red,
                Colors.blue,
                Colors.green,
                Colors.yellow
              ].map((c) => GestureDetector(
                    onTap: () => setState(() => _fillColor = c),
                    child: Container(
                      width: 22,
                      height: 22,
                      margin: const EdgeInsets.only(right: 4),
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _fillColor == c
                              ? theme.colorScheme.primary
                              : Colors.grey,
                          width: _fillColor == c ? 2 : 1,
                        ),
                      ),
                      child: c == Colors.transparent
                          ? const Icon(Icons.block, size: 14, color: Colors.grey)
                          : null,
                    ),
                  )),
            ],
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Shape'),
            onPressed: _addShape,
          ),
          if (widget.shapes.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...widget.shapes.map((s) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(_shapeTypes
                      .firstWhere((t) => t.$1 == s.shapeType,
                          orElse: () => _shapeTypes.first)
                      .$2),
                  title: Text(s.shapeType),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18),
                    onPressed: () => widget.onRemove?.call(s.id),
                  ),
                )),
          ],
        ],
      ),
    );
  }
}
