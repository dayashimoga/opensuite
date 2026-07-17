import 'package:flutter/material.dart';

/// Text overlay data for the image editor.
class TextOverlayItem {
  final String id;
  String text;
  Offset position;
  double fontSize;
  Color color;
  String fontFamily;
  bool isBold;
  bool isItalic;
  double rotation;

  TextOverlayItem({
    required this.id,
    this.text = 'Text',
    this.position = Offset.zero,
    this.fontSize = 24,
    this.color = Colors.white,
    this.fontFamily = 'Roboto',
    this.isBold = false,
    this.isItalic = false,
    this.rotation = 0,
  });
}

/// Tool widget for adding and editing text overlays on images.
class TextOverlayTool extends StatefulWidget {
  final List<TextOverlayItem> overlays;
  final ValueChanged<TextOverlayItem>? onAdd;
  final Function(String id, TextOverlayItem updated)? onUpdate;
  final ValueChanged<String>? onRemove;
  final String? selectedId;
  final ValueChanged<String>? onSelect;

  const TextOverlayTool({
    super.key,
    required this.overlays,
    this.onAdd,
    this.onUpdate,
    this.onRemove,
    this.selectedId,
    this.onSelect,
  });

  @override
  State<TextOverlayTool> createState() => _TextOverlayToolState();
}

class _TextOverlayToolState extends State<TextOverlayTool> {
  final _textController = TextEditingController();
  double _fontSize = 24;
  Color _color = Colors.white;
  bool _isBold = false;
  bool _isItalic = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _addOverlay() {
    if (_textController.text.isEmpty) return;
    widget.onAdd?.call(TextOverlayItem(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      text: _textController.text,
      position: const Offset(50, 50),
      fontSize: _fontSize,
      color: _color,
      isBold: _isBold,
      isItalic: _isItalic,
    ));
    _textController.clear();
  }

  static const _presetColors = [
    Colors.white,
    Colors.black,
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.yellow,
    Colors.orange,
    Colors.purple,
  ];

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
          Text('Text Overlay', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _textController,
                  decoration: const InputDecoration(
                    hintText: 'Enter text...',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                icon: const Icon(Icons.add),
                onPressed: _addOverlay,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text('Size: ${_fontSize.round()}',
                  style: const TextStyle(fontSize: 12)),
              Expanded(
                child: Slider(
                  value: _fontSize,
                  min: 8,
                  max: 120,
                  onChanged: (v) => setState(() => _fontSize = v),
                ),
              ),
              IconButton(
                icon: Icon(Icons.format_bold,
                    color: _isBold ? theme.colorScheme.primary : null),
                onPressed: () => setState(() => _isBold = !_isBold),
                iconSize: 20,
              ),
              IconButton(
                icon: Icon(Icons.format_italic,
                    color: _isItalic ? theme.colorScheme.primary : null),
                onPressed: () => setState(() => _isItalic = !_isItalic),
                iconSize: 20,
              ),
            ],
          ),
          Wrap(
            spacing: 4,
            children: _presetColors.map((c) {
              return GestureDetector(
                onTap: () => setState(() => _color = c),
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _color == c
                          ? theme.colorScheme.primary
                          : Colors.grey,
                      width: _color == c ? 2 : 1,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          if (widget.overlays.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Divider(),
            ...widget.overlays.map((o) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  selected: widget.selectedId == o.id,
                  title: Text(o.text,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text('${o.fontSize.round()}pt'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18),
                    onPressed: () => widget.onRemove?.call(o.id),
                  ),
                  onTap: () => widget.onSelect?.call(o.id),
                )),
          ],
        ],
      ),
    );
  }
}
