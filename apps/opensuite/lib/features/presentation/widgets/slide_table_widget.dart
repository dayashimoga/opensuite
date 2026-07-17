import 'package:fileutility_core/fileutility_core.dart';
import 'package:flutter/material.dart';

/// Editable table element on a slide canvas.
class SlideTableWidget extends StatefulWidget {
  final SlideTable table;
  final bool isSelected;
  final ValueChanged<SlideTable>? onChanged;

  const SlideTableWidget({
    super.key,
    required this.table,
    this.isSelected = false,
    this.onChanged,
  });

  @override
  State<SlideTableWidget> createState() => _SlideTableWidgetState();
}

class _SlideTableWidgetState extends State<SlideTableWidget> {
  late SlideTable _table;

  @override
  void initState() {
    super.initState();
    _table = widget.table;
  }

  @override
  void didUpdateWidget(covariant SlideTableWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.table != widget.table) _table = widget.table;
  }

  Color _parseColor(String hex) {
    final h = hex.replaceFirst('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }

  void _editCell(int row, int col) {
    final controller = TextEditingController(text: _table.getCell(row, col));
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Cell ($row, $col)'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Enter cell content',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final cells = Map<String, String>.from(_table.cells);
              cells['$row,$col'] = controller.text;
              final updated = _table.copyWith(cells: cells);
              setState(() => _table = updated);
              widget.onChanged?.call(updated);
              Navigator.pop(ctx);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _addRow() {
    final updated = _table.copyWith(rows: _table.rows + 1);
    setState(() => _table = updated);
    widget.onChanged?.call(updated);
  }

  void _addColumn() {
    final updated = _table.copyWith(columns: _table.columns + 1);
    setState(() => _table = updated);
    widget.onChanged?.call(updated);
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = _parseColor(_table.borderColor);
    final headerColor = _table.headerColor != null
        ? _parseColor(_table.headerColor!)
        : Theme.of(context).colorScheme.primaryContainer;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Table(
          border: TableBorder.all(
            color: borderColor,
            width: _table.borderWidth,
          ),
          children: List.generate(_table.rows, (row) {
            return TableRow(
              decoration: row == 0 ? BoxDecoration(color: headerColor) : null,
              children: List.generate(_table.columns, (col) {
                return GestureDetector(
                  onDoubleTap: () => _editCell(row, col),
                  child: Padding(
                    padding: EdgeInsets.all(_table.cellPadding),
                    child: Text(
                      _table.getCell(row, col),
                      style: TextStyle(
                        fontWeight:
                            row == 0 ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12,
                      ),
                    ),
                  ),
                );
              }),
            );
          }),
        ),
        if (widget.isSelected)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, size: 16),
                  tooltip: 'Add Row',
                  onPressed: _addRow,
                ),
                IconButton(
                  icon: const Icon(Icons.view_column_outlined, size: 16),
                  tooltip: 'Add Column',
                  onPressed: _addColumn,
                ),
              ],
            ),
          ),
      ],
    );
  }
}
