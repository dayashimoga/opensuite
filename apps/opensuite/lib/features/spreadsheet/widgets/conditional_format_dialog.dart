import 'package:flutter/material.dart';

/// Conditional format rule types.
enum ConditionalFormatType {
  greaterThan,
  lessThan,
  between,
  equalTo,
  textContains,
  duplicates,
  colorScale,
  dataBar,
  iconSet,
}

/// Visual format to apply when condition is met.
class ConditionalStyle {
  final Color? backgroundColor;
  final Color? textColor;
  final bool bold;
  final bool italic;

  const ConditionalStyle({
    this.backgroundColor,
    this.textColor,
    this.bold = false,
    this.italic = false,
  });
}

/// Dialog for creating conditional formatting rules on spreadsheet cells.
class ConditionalFormatDialog extends StatefulWidget {
  final String selectedRange;
  final ValueChanged<ConditionalFormatResult>? onApply;

  const ConditionalFormatDialog({
    super.key,
    required this.selectedRange,
    this.onApply,
  });

  @override
  State<ConditionalFormatDialog> createState() =>
      _ConditionalFormatDialogState();
}

class ConditionalFormatResult {
  final ConditionalFormatType type;
  final String range;
  final double? value1;
  final double? value2;
  final String? textValue;
  final ConditionalStyle style;

  const ConditionalFormatResult({
    required this.type,
    required this.range,
    this.value1,
    this.value2,
    this.textValue,
    required this.style,
  });
}

class _ConditionalFormatDialogState extends State<ConditionalFormatDialog> {
  ConditionalFormatType _type = ConditionalFormatType.greaterThan;
  final _value1Controller = TextEditingController();
  final _value2Controller = TextEditingController();
  final _textController = TextEditingController();
  Color _bgColor = Colors.green.shade100;
  final Color _textColor = Colors.black;
  bool _bold = false;
  bool _italic = false;

  @override
  void dispose() {
    _value1Controller.dispose();
    _value2Controller.dispose();
    _textController.dispose();
    super.dispose();
  }

  bool get _needsValue1 => [
        ConditionalFormatType.greaterThan,
        ConditionalFormatType.lessThan,
        ConditionalFormatType.between,
        ConditionalFormatType.equalTo,
      ].contains(_type);

  bool get _needsValue2 => _type == ConditionalFormatType.between;
  bool get _needsText => _type == ConditionalFormatType.textContains;

  static const _presetBgColors = [
    Colors.green,
    Colors.red,
    Colors.yellow,
    Colors.orange,
    Colors.blue,
    Colors.purple,
  ];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Conditional Formatting'),
      content: SizedBox(
        width: 380,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Range: ${widget.selectedRange}',
                  style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 12),
              DropdownButtonFormField<ConditionalFormatType>(
                value: _type,
                decoration: const InputDecoration(
                  labelText: 'Condition',
                  border: OutlineInputBorder(),
                ),
                items: ConditionalFormatType.values
                    .map((t) => DropdownMenuItem(
                          value: t,
                          child: Text(_typeLabel(t)),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _type = v!),
              ),
              if (_needsValue1) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _value1Controller,
                  decoration: InputDecoration(
                    labelText: _needsValue2 ? 'Min Value' : 'Value',
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
              if (_needsValue2) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _value2Controller,
                  decoration: const InputDecoration(
                    labelText: 'Max Value',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
              if (_needsText) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _textController,
                  decoration: const InputDecoration(
                    labelText: 'Text to match',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Text('Format Style',
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text('Background:', style: TextStyle(fontSize: 12)),
                  const SizedBox(width: 8),
                  ..._presetBgColors.map((c) => GestureDetector(
                        onTap: () => setState(() => _bgColor = c.shade100),
                        child: Container(
                          width: 24,
                          height: 24,
                          margin: const EdgeInsets.only(right: 4),
                          decoration: BoxDecoration(
                            color: c.shade100,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _bgColor == c.shade100 ? c : Colors.grey,
                              width: _bgColor == c.shade100 ? 2 : 1,
                            ),
                          ),
                        ),
                      )),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.format_bold,
                        color: _bold
                            ? Theme.of(context).colorScheme.primary
                            : null),
                    onPressed: () => setState(() => _bold = !_bold),
                  ),
                  IconButton(
                    icon: Icon(Icons.format_italic,
                        color: _italic
                            ? Theme.of(context).colorScheme.primary
                            : null),
                    onPressed: () => setState(() => _italic = !_italic),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _bgColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Preview: 42',
                  style: TextStyle(
                    color: _textColor,
                    fontWeight: _bold ? FontWeight.bold : FontWeight.normal,
                    fontStyle: _italic ? FontStyle.italic : FontStyle.normal,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            widget.onApply?.call(ConditionalFormatResult(
              type: _type,
              range: widget.selectedRange,
              value1: double.tryParse(_value1Controller.text),
              value2: double.tryParse(_value2Controller.text),
              textValue:
                  _textController.text.isEmpty ? null : _textController.text,
              style: ConditionalStyle(
                backgroundColor: _bgColor,
                textColor: _textColor,
                bold: _bold,
                italic: _italic,
              ),
            ));
            Navigator.pop(context);
          },
          child: const Text('Apply'),
        ),
      ],
    );
  }

  String _typeLabel(ConditionalFormatType type) {
    return switch (type) {
      ConditionalFormatType.greaterThan => 'Greater Than',
      ConditionalFormatType.lessThan => 'Less Than',
      ConditionalFormatType.between => 'Between',
      ConditionalFormatType.equalTo => 'Equal To',
      ConditionalFormatType.textContains => 'Text Contains',
      ConditionalFormatType.duplicates => 'Duplicate Values',
      ConditionalFormatType.colorScale => 'Color Scale',
      ConditionalFormatType.dataBar => 'Data Bar',
      ConditionalFormatType.iconSet => 'Icon Set',
    };
  }
}
