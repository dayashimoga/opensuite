import 'package:fileutility_core/fileutility_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../di/app_module.dart';
import '../bloc/spreadsheet_bloc.dart';

/// Spreadsheet grid editor page.
///
/// Provides a virtual-scrolling grid, formula bar, formatting toolbar,
/// sheet tabs, and cell editing with formula evaluation.
class SpreadsheetEditorPage extends StatelessWidget {
  final String? spreadsheetId;
  const SpreadsheetEditorPage({super.key, this.spreadsheetId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SpreadsheetBloc>(
      create: (_) {
        final bloc = AppModule.spreadsheetBloc;
        if (spreadsheetId != null) {
          bloc.add(OpenSpreadsheet(spreadsheetId!));
        } else {
          bloc.add(const CreateSpreadsheet());
        }
        return bloc;
      },
      child: const _EditorContent(),
    );
  }
}

class _EditorContent extends StatefulWidget {
  const _EditorContent();

  @override
  State<_EditorContent> createState() => _EditorContentState();
}

class _EditorContentState extends State<_EditorContent> {
  final _formulaController = TextEditingController();
  final _cellEditController = TextEditingController();
  final _scrollController = ScrollController();
  final _horizontalScrollController = ScrollController();
  bool _isEditing = false;

  @override
  void dispose() {
    _formulaController.dispose();
    _cellEditController.dispose();
    _scrollController.dispose();
    _horizontalScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocConsumer<SpreadsheetBloc, SpreadsheetState>(
      listenWhen: (prev, curr) =>
          prev.selectedCell != curr.selectedCell ||
          prev.cellEditValue != curr.cellEditValue,
      listener: (context, state) {
        _formulaController.text = state.formulaBarValue;
        if (!_isEditing) {
          _cellEditController.text = state.cellEditValue;
        }
      },
      builder: (context, state) {
        if (state.status == SpreadsheetStatus.loading) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        final activeSheet = state.activeSheet;
        if (activeSheet == null) {
          return const Scaffold(body: Center(child: Text('No sheet data')));
        }

        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                if (state.hasUnsavedChanges) {
                  context.read<SpreadsheetBloc>().add(const SaveSpreadsheet());
                }
                context.go('/spreadsheets');
              },
            ),
            title: Text(state.currentSpreadsheet?.title ?? 'Spreadsheet'),
            actions: [
              // Formatting buttons
              IconButton(
                icon: const Icon(Icons.format_bold, size: 20),
                onPressed: () => context
                    .read<SpreadsheetBloc>()
                    .add(const FormatCells('bold')),
                tooltip: 'Bold',
              ),
              IconButton(
                icon: const Icon(Icons.format_italic, size: 20),
                onPressed: () => context
                    .read<SpreadsheetBloc>()
                    .add(const FormatCells('italic')),
                tooltip: 'Italic',
              ),
              const SizedBox(width: 4),
              // Save indicator
              if (state.status == SpreadsheetStatus.saving)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2)),
                )
              else if (state.hasUnsavedChanges)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.circle, size: 12, color: Colors.orange),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.cloud_done,
                      size: 18,
                      color: theme.colorScheme.primary.withValues(alpha: 0.6)),
                ),
              // Save button
              IconButton(
                icon: const Icon(Icons.save_outlined),
                onPressed: () => context
                    .read<SpreadsheetBloc>()
                    .add(const SaveSpreadsheet()),
                tooltip: 'Save',
              ),
            ],
          ),
          body: Column(
            children: [
              // Formula bar
              _FormulaBar(
                controller: _formulaController,
                cellRef: state.selectedCell?.reference ?? 'A1',
                onSubmitted: (value) {
                  if (state.selectedCell != null) {
                    context
                        .read<SpreadsheetBloc>()
                        .add(UpdateCell(state.selectedCell!, value));
                  }
                },
              ),

              // Grid
              Expanded(
                child: _SpreadsheetGrid(
                  sheet: activeSheet,
                  selectedCell: state.selectedCell,
                  onCellTap: (pos) {
                    context.read<SpreadsheetBloc>().add(SelectCell(pos));
                  },
                  onCellEdit: (pos, value) {
                    context.read<SpreadsheetBloc>().add(UpdateCell(pos, value));
                  },
                ),
              ),

              // Sheet tabs
              _SheetTabs(
                sheets: state.sheets,
                activeIndex: state.activeSheetIndex,
                onSelect: (i) =>
                    context.read<SpreadsheetBloc>().add(SelectSheet(i)),
                onAdd: () =>
                    context.read<SpreadsheetBloc>().add(const AddSheet()),
                onRename: (i, name) =>
                    context.read<SpreadsheetBloc>().add(RenameSheet(i, name)),
                onDelete: (i) =>
                    context.read<SpreadsheetBloc>().add(DeleteSheet(i)),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Formula bar showing cell reference and formula/value input.
class _FormulaBar extends StatelessWidget {
  final TextEditingController controller;
  final String cellRef;
  final ValueChanged<String> onSubmitted;

  const _FormulaBar({
    required this.controller,
    required this.cellRef,
    required this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 36,
      decoration: BoxDecoration(
        border: Border(
          bottom:
              BorderSide(color: theme.colorScheme.outlineVariant, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          // Cell reference
          Container(
            width: 60,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(
                    color: theme.colorScheme.outlineVariant, width: 0.5),
              ),
            ),
            child: Text(
              cellRef,
              style: theme.textTheme.labelMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          // Formula icon
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Icon(Icons.functions,
                size: 18, color: theme.colorScheme.onSurfaceVariant),
          ),
          // Formula input
          Expanded(
            child: TextField(
              controller: controller,
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 8),
                isDense: true,
              ),
              style:
                  theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
              onSubmitted: onSubmitted,
            ),
          ),
        ],
      ),
    );
  }
}

/// Virtual-scrolling spreadsheet grid widget.
class _SpreadsheetGrid extends StatelessWidget {
  final SheetData sheet;
  final CellPosition? selectedCell;
  final ValueChanged<CellPosition> onCellTap;
  final void Function(CellPosition, String) onCellEdit;

  const _SpreadsheetGrid({
    required this.sheet,
    required this.selectedCell,
    required this.onCellTap,
    required this.onCellEdit,
  });

  static const double _defaultColWidth = 100;
  static const double _defaultRowHeight = 32;
  static const double _headerWidth = 50;
  static const double _headerHeight = 28;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Show a reasonable viewport
    final visibleRows = 50;
    final visibleCols = sheet.colCount;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Column headers
            Row(
              children: [
                // Top-left corner
                Container(
                  width: _headerWidth,
                  height: _headerHeight,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    border: Border.all(
                        color: theme.colorScheme.outlineVariant, width: 0.5),
                  ),
                ),
                // Column letters
                for (var col = 0; col < visibleCols; col++)
                  Container(
                    width: sheet.columnWidths[col] ?? _defaultColWidth,
                    height: _headerHeight,
                    decoration: BoxDecoration(
                      color: selectedCell?.col == col
                          ? theme.colorScheme.primaryContainer
                          : theme.colorScheme.surfaceContainerHighest,
                      border: Border.all(
                          color: theme.colorScheme.outlineVariant, width: 0.5),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      CellPosition.columnToLetter(col),
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            // Data rows
            for (var row = 0; row < visibleRows; row++)
              Row(
                children: [
                  // Row number header
                  Container(
                    width: _headerWidth,
                    height: sheet.rowHeights[row] ?? _defaultRowHeight,
                    decoration: BoxDecoration(
                      color: selectedCell?.row == row
                          ? theme.colorScheme.primaryContainer
                          : theme.colorScheme.surfaceContainerHighest,
                      border: Border.all(
                          color: theme.colorScheme.outlineVariant, width: 0.5),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${row + 1}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  // Data cells
                  for (var col = 0; col < visibleCols; col++)
                    _GridCell(
                      position: CellPosition(row, col),
                      cell: sheet.getCell(CellPosition(row, col)),
                      isSelected:
                          selectedCell?.row == row && selectedCell?.col == col,
                      width: sheet.columnWidths[col] ?? _defaultColWidth,
                      height: sheet.rowHeights[row] ?? _defaultRowHeight,
                      onTap: () => onCellTap(CellPosition(row, col)),
                      onEdit: (value) =>
                          onCellEdit(CellPosition(row, col), value),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// Individual grid cell widget with tap-to-select and double-tap-to-edit.
class _GridCell extends StatefulWidget {
  final CellPosition position;
  final CellData cell;
  final bool isSelected;
  final double width;
  final double height;
  final VoidCallback onTap;
  final ValueChanged<String> onEdit;

  const _GridCell({
    required this.position,
    required this.cell,
    required this.isSelected,
    required this.width,
    required this.height,
    required this.onTap,
    required this.onEdit,
  });

  @override
  State<_GridCell> createState() => _GridCellState();
}

class _GridCellState extends State<_GridCell> {
  bool _isEditing = false;
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.cell.rawValue);
  }

  @override
  void didUpdateWidget(_GridCell old) {
    super.didUpdateWidget(old);
    if (!_isEditing) {
      _controller.text = widget.cell.rawValue;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cellBgColor = widget.cell.backgroundColor != null
        ? _parseColor(widget.cell.backgroundColor!)
        : null;

    return GestureDetector(
      onTap: () {
        widget.onTap();
        if (_isEditing) return;
      },
      onDoubleTap: () {
        setState(() => _isEditing = true);
        _controller.text = widget.cell.rawValue;
      },
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: widget.isSelected
              ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
              : cellBgColor,
          border: Border.all(
            color: widget.isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant,
            width: widget.isSelected ? 1.5 : 0.5,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        alignment: _getAlignment(widget.cell.alignment),
        child: _isEditing
            ? TextField(
                controller: _controller,
                autofocus: true,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  isDense: true,
                ),
                style: _getCellTextStyle(theme),
                onSubmitted: (value) {
                  widget.onEdit(value);
                  setState(() => _isEditing = false);
                },
                onTapOutside: (_) {
                  widget.onEdit(_controller.text);
                  setState(() => _isEditing = false);
                },
              )
            : Text(
                widget.cell.hasError
                    ? widget.cell.errorMessage ?? '#ERROR!'
                    : widget.cell.displayValue,
                style: _getCellTextStyle(theme).copyWith(
                  color: widget.cell.hasError ? Colors.red : null,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
      ),
    );
  }

  TextStyle _getCellTextStyle(ThemeData theme) {
    return theme.textTheme.bodySmall!.copyWith(
      fontWeight: widget.cell.isBold ? FontWeight.bold : FontWeight.normal,
      fontStyle: widget.cell.isItalic ? FontStyle.italic : FontStyle.normal,
      fontSize: widget.cell.fontSize,
      color: widget.cell.textColor != null
          ? _parseColor(widget.cell.textColor!)
          : null,
    );
  }

  Alignment _getAlignment(String alignment) {
    switch (alignment) {
      case 'center':
        return Alignment.center;
      case 'right':
        return Alignment.centerRight;
      default:
        return Alignment.centerLeft;
    }
  }

  Color? _parseColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return null;
    }
  }
}

/// Sheet tabs at the bottom of the spreadsheet.
class _SheetTabs extends StatelessWidget {
  final List<SheetData> sheets;
  final int activeIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onAdd;
  final void Function(int, String) onRename;
  final ValueChanged<int> onDelete;

  const _SheetTabs({
    required this.sheets,
    required this.activeIndex,
    required this.onSelect,
    required this.onAdd,
    required this.onRename,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          // Add sheet button
          IconButton(
            icon: const Icon(Icons.add, size: 18),
            onPressed: onAdd,
            tooltip: 'Add sheet',
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
          const SizedBox(width: 4),
          // Sheet tabs
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: sheets.length,
              itemBuilder: (context, index) {
                final isActive = index == activeIndex;
                return GestureDetector(
                  onTap: () => onSelect(index),
                  onLongPress: () => _showSheetMenu(context, index),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    margin: const EdgeInsets.only(right: 2),
                    decoration: BoxDecoration(
                      color: isActive
                          ? theme.colorScheme.surface
                          : Colors.transparent,
                      border: isActive
                          ? Border(
                              top: BorderSide(
                                color: theme.colorScheme.primary,
                                width: 2,
                              ),
                            )
                          : null,
                    ),
                    child: Text(
                      sheets[index].name,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight:
                            isActive ? FontWeight.w600 : FontWeight.normal,
                        color: isActive
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showSheetMenu(BuildContext context, int index) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Rename'),
            onTap: () {
              Navigator.pop(context);
              _showRenameDialog(context, index);
            },
          ),
          if (sheets.length > 1)
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                onDelete(index);
              },
            ),
        ],
      ),
    );
  }

  void _showRenameDialog(BuildContext context, int index) {
    final controller = TextEditingController(text: sheets[index].name);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Rename Sheet'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Sheet name'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              onRename(index, controller.text);
              Navigator.pop(context);
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }
}
