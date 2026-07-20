import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart' as fp;
import 'package:fileutility_core/fileutility_core.dart';
import 'package:fileutility_ui_kit/fileutility_ui_kit.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../di/app_module.dart';
import '../bloc/spreadsheet_bloc.dart';
import '../widgets/spreadsheet_chart.dart';

/// Spreadsheet grid editor page.
///
/// Provides a virtual-scrolling grid, ribbon toolbar, formula bar,
/// context menus, sheet tabs, and full cell editing with formula evaluation.
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
  final _verticalController = ScrollController();
  final _horizontalController = ScrollController();
  final _findController = TextEditingController();
  final _replaceController = TextEditingController();
  final _gridFocusNode = FocusNode(debugLabel: 'SpreadsheetGrid');
  final _formulaFocusNode = FocusNode(debugLabel: 'FormulaBar');
  bool _showFindBar = false;

  String _selectedFont = 'Inter';
  double _selectedFontSize = 12.0;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      BrowserContextMenu.disableContextMenu();
    }
  }

  @override
  void dispose() {
    if (kIsWeb) {
      BrowserContextMenu.enableContextMenu();
    }
    _formulaController.dispose();
    _cellEditController.dispose();
    _verticalController.dispose();
    _horizontalController.dispose();
    _findController.dispose();
    _replaceController.dispose();
    _gridFocusNode.dispose();
    _formulaFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocConsumer<SpreadsheetBloc, SpreadsheetState>(
      listenWhen: (prev, curr) =>
          prev.selectedCell != curr.selectedCell ||
          prev.cellEditValue != curr.cellEditValue ||
          prev.status != curr.status,
      listener: (context, state) {
        if (state.formulaBarValue != _formulaController.text) {
          _formulaController.text = state.formulaBarValue;
        }
        if (state.cellEditValue != _cellEditController.text) {
          _cellEditController.text = state.cellEditValue;
        }

        // Update font info from selected cell
        if (state.selectedCell != null && state.activeSheet != null) {
          final cell = state.activeSheet!.getCell(state.selectedCell!);
          _selectedFont = cell.fontFamily;
          _selectedFontSize = cell.fontSize;
        }

        if (state.status == SpreadsheetStatus.saved) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Saved ✓'),
              duration: Duration(seconds: 1),
            ),
          );
        }
        if (state.status == SpreadsheetStatus.exported &&
            state.exportedBytes != null) {
          FileDownloadUtils.downloadBytes(
            bytes: state.exportedBytes!,
            fileName: state.exportedFileName ?? 'spreadsheet.xlsx',
            mimeType: state.exportedMimeType ??
                'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
          ).then((_) {
            if (context.mounted) {
              context
                  .read<SpreadsheetBloc>()
                  .add(const ClearExportedSpreadsheet());
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Downloaded: ${state.exportedFileName}'),
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          });
        }
        if (state.status == SpreadsheetStatus.error &&
            state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: theme.colorScheme.error,
            ),
          );
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

        return Focus(
          focusNode: _gridFocusNode,
          autofocus: true,
          onKeyEvent: (node, event) => _handleKeyEvent(event, state),
          child: Scaffold(
            appBar: _buildAppBar(context, state, theme),
            body: Column(
              children: [
                // Ribbon toolbar
                _buildRibbon(context, state, theme),

                // Formula bar
                _FormulaBar(
                  controller: _formulaController,
                  focusNode: _formulaFocusNode,
                  cellRef: state.selectedCell?.reference ?? 'A1',
                  onSubmitted: (value) {
                    if (state.selectedCell != null) {
                      context
                          .read<SpreadsheetBloc>()
                          .add(UpdateCell(state.selectedCell!, value));
                    }
                    // Return focus to grid after formula bar submit
                    _gridFocusNode.requestFocus();
                  },
                  onChanged: (value) {
                    if (state.selectedCell != null) {
                      context
                          .read<SpreadsheetBloc>()
                          .add(UpdateCell(state.selectedCell!, value));
                    }
                  },
                ),

                // Find & Replace bar
                if (_showFindBar) _buildFindBar(context, state, theme),

                // Grid
                Expanded(
                  child: _VirtualSpreadsheetGrid(
                    sheet: activeSheet,
                    selectedCell: state.selectedCell,
                    selectedRange: state.selectedRange,
                    findMatches: state.findMatches,
                    verticalController: _verticalController,
                    horizontalController: _horizontalController,
                    onCellTap: (pos) {
                      // Shift+Click extends selection range
                      if (HardwareKeyboard.instance.isShiftPressed &&
                          state.selectedCell != null) {
                        context.read<SpreadsheetBloc>().add(
                            SetCellRange(CellRange(state.selectedCell!, pos)));
                      } else {
                        context.read<SpreadsheetBloc>().add(SelectCell(pos));
                      }
                      // Ensure grid has focus for keyboard events on web
                      _gridFocusNode.requestFocus();
                    },
                    onCellEdit: (pos, value) {
                      context
                          .read<SpreadsheetBloc>()
                          .add(UpdateCell(pos, value));
                    },
                    onRangeSelect: (range) {
                      context.read<SpreadsheetBloc>().add(SetCellRange(range));
                    },
                    onContextMenu: (pos, offset) {
                      _showCellContextMenu(context, pos, offset);
                    },
                    onColumnResize: (col, width) {
                      context
                          .read<SpreadsheetBloc>()
                          .add(ResizeColumn(col, width));
                    },
                    onEditComplete: () => _gridFocusNode.requestFocus(),
                  ),
                ),

                // Status bar
                _StatusBar(state: state),

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
                  onDuplicate: (i) =>
                      context.read<SpreadsheetBloc>().add(DuplicateSheet(i)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  AppBar _buildAppBar(
      BuildContext context, SpreadsheetState state, ThemeData theme) {
    return AppBar(
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
        // Undo/Redo
        IconButton(
          icon: const Icon(Icons.undo, size: 20),
          onPressed: state.canUndo
              ? () =>
                  context.read<SpreadsheetBloc>().add(const UndoSpreadsheet())
              : null,
          tooltip: 'Undo (Ctrl+Z)',
        ),
        IconButton(
          icon: const Icon(Icons.redo, size: 20),
          onPressed: state.canRedo
              ? () =>
                  context.read<SpreadsheetBloc>().add(const RedoSpreadsheet())
              : null,
          tooltip: 'Redo (Ctrl+Y)',
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
          onPressed: () =>
              context.read<SpreadsheetBloc>().add(const SaveSpreadsheet()),
          tooltip: 'Save (Ctrl+S)',
        ),
        // Overflow menu
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          itemBuilder: (_) => [
            const PopupMenuItem(
              value: 'import_file',
              child: Row(children: [
                Icon(Icons.file_open, size: 20),
                SizedBox(width: 8),
                Text('Import CSV / Excel'),
              ]),
            ),
            const PopupMenuItem(
              value: 'create_table',
              child: Row(children: [
                Icon(Icons.table_chart, size: 20),
                SizedBox(width: 8),
                Text('Create Table'),
              ]),
            ),
            const PopupMenuItem(
              value: 'export_csv',
              child: Row(children: [
                Icon(Icons.download, size: 20),
                SizedBox(width: 8),
                Text('Export as CSV'),
              ]),
            ),
            const PopupMenuItem(
              value: 'export_xlsx',
              child: Row(children: [
                Icon(Icons.table_view, size: 20),
                SizedBox(width: 8),
                Text('Export as XLSX'),
              ]),
            ),
            const PopupMenuItem(
              value: 'insert_chart',
              child: Row(children: [
                Icon(Icons.bar_chart, size: 20),
                SizedBox(width: 8),
                Text('Insert Chart'),
              ]),
            ),
            const PopupMenuItem(
              value: 'share',
              child: Row(children: [
                Icon(Icons.share, size: 20),
                SizedBox(width: 8),
                Text('Share'),
              ]),
            ),
          ],
          onSelected: (value) {
            switch (value) {
              case 'import_file':
                _importLocalFile(context);
              case 'create_table':
                context.read<SpreadsheetBloc>().add(const CreateTable());
              case 'export_csv':
                _exportCsv(context, state);
              case 'export_xlsx':
                context.read<SpreadsheetBloc>().add(const ExportXlsxFile());
              case 'insert_chart':
                _showChartDialog(context, state);
              case 'share':
                _shareSpreadsheet(context, state);
            }
          },
        ),
      ],
    );
  }

  Widget _buildRibbon(
      BuildContext context, SpreadsheetState state, ThemeData theme) {
    return ToolbarRibbon(
      tabs: [
        RibbonTab(label: 'Home', groups: [
          // Font group
          RibbonGroup(label: 'Font', children: [
            SizedBox(
              width: 100,
              height: 28,
              child: DropdownButtonFormField<String>(
                initialValue: _selectedFont,
                isDense: true,
                isExpanded: true,
                decoration: InputDecoration(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: BorderSide(
                        color: theme.colorScheme.outlineVariant, width: 0.5),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: BorderSide(
                        color: theme.colorScheme.outlineVariant, width: 0.5),
                  ),
                ),
                style: theme.textTheme.bodySmall,
                items: const [
                  DropdownMenuItem(value: 'Inter', child: Text('Inter')),
                  DropdownMenuItem(value: 'Roboto', child: Text('Roboto')),
                  DropdownMenuItem(
                      value: 'monospace', child: Text('Monospace')),
                  DropdownMenuItem(value: 'serif', child: Text('Serif')),
                ],
                onChanged: (v) {
                  if (v != null) {
                    setState(() => _selectedFont = v);
                    context.read<SpreadsheetBloc>().add(SetFontFamily(v));
                  }
                },
              ),
            ),
            const SizedBox(width: 4),
            SizedBox(
              width: 56,
              height: 28,
              child: DropdownButtonFormField<double>(
                initialValue: _selectedFontSize,
                isDense: true,
                isExpanded: true,
                decoration: InputDecoration(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: BorderSide(
                        color: theme.colorScheme.outlineVariant, width: 0.5),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: BorderSide(
                        color: theme.colorScheme.outlineVariant, width: 0.5),
                  ),
                ),
                style: theme.textTheme.bodySmall,
                items: const [
                  DropdownMenuItem(value: 8.0, child: Text('8')),
                  DropdownMenuItem(value: 10.0, child: Text('10')),
                  DropdownMenuItem(value: 11.0, child: Text('11')),
                  DropdownMenuItem(value: 12.0, child: Text('12')),
                  DropdownMenuItem(value: 14.0, child: Text('14')),
                  DropdownMenuItem(value: 16.0, child: Text('16')),
                  DropdownMenuItem(value: 18.0, child: Text('18')),
                  DropdownMenuItem(value: 20.0, child: Text('20')),
                  DropdownMenuItem(value: 24.0, child: Text('24')),
                ],
                onChanged: (v) {
                  if (v != null) {
                    setState(() => _selectedFontSize = v);
                    context.read<SpreadsheetBloc>().add(SetFontSize(v));
                  }
                },
              ),
            ),
            const SizedBox(width: 4),
            RibbonButton(
              icon: Icons.format_bold,
              tooltip: 'Bold (Ctrl+B)',
              isActive: _isCellBold(state),
              onPressed: () => context
                  .read<SpreadsheetBloc>()
                  .add(const FormatCells('bold')),
            ),
            RibbonButton(
              icon: Icons.format_italic,
              tooltip: 'Italic (Ctrl+I)',
              isActive: _isCellItalic(state),
              onPressed: () => context
                  .read<SpreadsheetBloc>()
                  .add(const FormatCells('italic')),
            ),
            RibbonButton(
              icon: Icons.format_underlined,
              tooltip: 'Underline (Ctrl+U)',
              isActive: _isCellUnderline(state),
              onPressed: () => context
                  .read<SpreadsheetBloc>()
                  .add(const FormatCells('underline')),
            ),
            RibbonButton(
              icon: Icons.strikethrough_s,
              tooltip: 'Strikethrough',
              isActive: _isCellStrikethrough(state),
              onPressed: () => context
                  .read<SpreadsheetBloc>()
                  .add(const FormatCells('strikethrough')),
            ),
          ]),
          // Color group
          RibbonGroup(label: 'Colors', children: [
            _ColorPickerButton(
              icon: Icons.format_color_text,
              tooltip: 'Text Color',
              currentColor: _getCellTextColor(state),
              onColorSelected: (color) =>
                  context.read<SpreadsheetBloc>().add(SetTextColor(color)),
            ),
            _ColorPickerButton(
              icon: Icons.format_color_fill,
              tooltip: 'Fill Color',
              currentColor: _getCellBgColor(state),
              onColorSelected: (color) => context
                  .read<SpreadsheetBloc>()
                  .add(SetBackgroundColor(color)),
            ),
          ]),
          // Alignment group
          RibbonGroup(label: 'Alignment', children: [
            RibbonButton(
              icon: Icons.format_align_left,
              tooltip: 'Align Left',
              isActive: _getCellAlignment(state) == 'left',
              onPressed: () => context
                  .read<SpreadsheetBloc>()
                  .add(const FormatCells('alignLeft')),
            ),
            RibbonButton(
              icon: Icons.format_align_center,
              tooltip: 'Align Center',
              isActive: _getCellAlignment(state) == 'center',
              onPressed: () => context
                  .read<SpreadsheetBloc>()
                  .add(const FormatCells('alignCenter')),
            ),
            RibbonButton(
              icon: Icons.format_align_right,
              tooltip: 'Align Right',
              isActive: _getCellAlignment(state) == 'right',
              onPressed: () => context
                  .read<SpreadsheetBloc>()
                  .add(const FormatCells('alignRight')),
            ),
            RibbonButton(
              icon: Icons.wrap_text,
              tooltip: 'Wrap Text',
              isActive: _isCellWrapText(state),
              onPressed: () => context
                  .read<SpreadsheetBloc>()
                  .add(const FormatCells('wrapText')),
            ),
          ]),
          // Number format group
          RibbonGroup(label: 'Number', children: [
            SizedBox(
              width: 100,
              height: 28,
              child: DropdownButtonFormField<NumberFormatType>(
                initialValue: _getCellNumberFormat(state),
                isDense: true,
                isExpanded: true,
                decoration: InputDecoration(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: BorderSide(
                        color: theme.colorScheme.outlineVariant, width: 0.5),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: BorderSide(
                        color: theme.colorScheme.outlineVariant, width: 0.5),
                  ),
                ),
                style: theme.textTheme.bodySmall,
                items: const [
                  DropdownMenuItem(
                      value: NumberFormatType.general, child: Text('General')),
                  DropdownMenuItem(
                      value: NumberFormatType.number, child: Text('Number')),
                  DropdownMenuItem(
                      value: NumberFormatType.decimal, child: Text('Decimal')),
                  DropdownMenuItem(
                      value: NumberFormatType.currency,
                      child: Text('Currency')),
                  DropdownMenuItem(
                      value: NumberFormatType.percentage,
                      child: Text('Percent')),
                  DropdownMenuItem(
                      value: NumberFormatType.scientific,
                      child: Text('Scientific')),
                ],
                onChanged: (v) {
                  if (v != null) {
                    context.read<SpreadsheetBloc>().add(SetNumberFormat(v));
                  }
                },
              ),
            ),
          ]),
          // Cell operations group
          RibbonGroup(label: 'Cells', children: [
            RibbonButton(
              icon: Icons.merge_type,
              tooltip: 'Merge Cells',
              onPressed: state.selectedRange != null &&
                      !state.selectedRange!.isSingleCell
                  ? () => context
                      .read<SpreadsheetBloc>()
                      .add(MergeCells(state.selectedRange!))
                  : null,
            ),
            RibbonButton(
              icon: Icons.border_all,
              tooltip: 'Borders',
              onPressed: () => context.read<SpreadsheetBloc>().add(
                    SetBorders(CellBorders.all('#000000')),
                  ),
            ),
          ]),
        ]),
        RibbonTab(label: 'Insert', groups: [
          RibbonGroup(label: 'Rows & Columns', children: [
            RibbonButton(
              icon: Icons.table_rows,
              tooltip: 'Insert Row Below',
              onPressed: () {
                final row = state.selectedCell?.row ?? 0;
                context.read<SpreadsheetBloc>().add(InsertRow(row));
              },
            ),
            RibbonButton(
              icon: Icons.view_column,
              tooltip: 'Insert Column Right',
              onPressed: () {
                final col = state.selectedCell?.col ?? 0;
                context.read<SpreadsheetBloc>().add(InsertColumn(col));
              },
            ),
            RibbonButton(
              icon: Icons.delete_sweep,
              tooltip: 'Delete Row',
              onPressed: () {
                final row = state.selectedCell?.row ?? 0;
                context.read<SpreadsheetBloc>().add(DeleteRow(row));
              },
            ),
            RibbonButton(
              icon: Icons.remove_circle_outline,
              tooltip: 'Delete Column',
              onPressed: () {
                final col = state.selectedCell?.col ?? 0;
                context.read<SpreadsheetBloc>().add(DeleteColumn(col));
              },
            ),
          ]),
          RibbonGroup(label: 'Content', children: [
            RibbonButton(
              icon: Icons.comment,
              tooltip: 'Add Comment',
              onPressed: () => _showAddCommentDialog(context, state),
            ),
            RibbonButton(
              icon: Icons.link,
              tooltip: 'Add Hyperlink',
              onPressed: () => _showAddHyperlinkDialog(context, state),
            ),
          ]),
        ]),
        RibbonTab(label: 'Data', groups: [
          RibbonGroup(label: 'Sort', children: [
            RibbonButton(
              icon: Icons.arrow_upward,
              tooltip: 'Sort A→Z',
              onPressed: () {
                if (state.selectedCell != null) {
                  context.read<SpreadsheetBloc>().add(
                      SortColumn(state.selectedCell!.col, ascending: true));
                }
              },
            ),
            RibbonButton(
              icon: Icons.arrow_downward,
              tooltip: 'Sort Z→A',
              onPressed: () {
                if (state.selectedCell != null) {
                  context.read<SpreadsheetBloc>().add(
                      SortColumn(state.selectedCell!.col, ascending: false));
                }
              },
            ),
          ]),
          RibbonGroup(label: 'Find', children: [
            RibbonButton(
              icon: Icons.search,
              tooltip: 'Find & Replace (Ctrl+F)',
              onPressed: () => setState(() => _showFindBar = !_showFindBar),
            ),
          ]),
        ]),
        RibbonTab(label: 'View', groups: [
          RibbonGroup(label: 'Freeze', children: [
            RibbonButton(
              icon: Icons.push_pin_outlined,
              tooltip: 'Freeze Panes',
              onPressed: () => _showFreezeDialog(context, state),
            ),
          ]),
          RibbonGroup(label: 'Visibility', children: [
            RibbonButton(
              icon: Icons.visibility_off,
              tooltip: 'Hide Selected Rows',
              onPressed: state.selectedCell != null
                  ? () => context
                      .read<SpreadsheetBloc>()
                      .add(HideRows([state.selectedCell!.row]))
                  : null,
            ),
            RibbonButton(
              icon: Icons.visibility,
              tooltip: 'Unhide All Rows',
              onPressed: () =>
                  context.read<SpreadsheetBloc>().add(const UnhideRows()),
            ),
          ]),
        ]),
      ],
    );
  }

  Widget _buildFindBar(
      BuildContext context, SpreadsheetState state, ThemeData theme) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        border: Border(
          bottom:
              BorderSide(color: theme.colorScheme.outlineVariant, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _findController,
              decoration: const InputDecoration(
                hintText: 'Find...',
                border: InputBorder.none,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                isDense: true,
              ),
              style: theme.textTheme.bodySmall,
              onChanged: (query) =>
                  context.read<SpreadsheetBloc>().add(FindInSheet(query)),
            ),
          ),
          if (state.findMatches.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                '${state.findMatchIndex + 1}/${state.findMatches.length}',
                style: theme.textTheme.labelSmall,
              ),
            ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _replaceController,
              decoration: const InputDecoration(
                hintText: 'Replace...',
                border: InputBorder.none,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                isDense: true,
              ),
              style: theme.textTheme.bodySmall,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.find_replace, size: 18),
            tooltip: 'Replace',
            onPressed: () => context.read<SpreadsheetBloc>().add(
                ReplaceInSheet(_findController.text, _replaceController.text)),
            iconSize: 18,
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
          IconButton(
            icon: const Icon(Icons.find_replace_outlined, size: 18),
            tooltip: 'Replace All',
            onPressed: () => context.read<SpreadsheetBloc>().add(ReplaceInSheet(
                _findController.text, _replaceController.text,
                replaceAll: true)),
            iconSize: 18,
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: () {
              setState(() => _showFindBar = false);
              context.read<SpreadsheetBloc>().add(const ClearFind());
            },
            iconSize: 18,
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }

  // --- Cell state helpers ---

  bool _isCellBold(SpreadsheetState state) {
    if (state.selectedCell == null || state.activeSheet == null) return false;
    return state.activeSheet!.getCell(state.selectedCell!).isBold;
  }

  bool _isCellItalic(SpreadsheetState state) {
    if (state.selectedCell == null || state.activeSheet == null) return false;
    return state.activeSheet!.getCell(state.selectedCell!).isItalic;
  }

  bool _isCellUnderline(SpreadsheetState state) {
    if (state.selectedCell == null || state.activeSheet == null) return false;
    return state.activeSheet!.getCell(state.selectedCell!).isUnderline;
  }

  bool _isCellStrikethrough(SpreadsheetState state) {
    if (state.selectedCell == null || state.activeSheet == null) return false;
    return state.activeSheet!.getCell(state.selectedCell!).isStrikethrough;
  }

  bool _isCellWrapText(SpreadsheetState state) {
    if (state.selectedCell == null || state.activeSheet == null) return false;
    return state.activeSheet!.getCell(state.selectedCell!).wrapText;
  }

  String _getCellAlignment(SpreadsheetState state) {
    if (state.selectedCell == null || state.activeSheet == null) return 'left';
    return state.activeSheet!.getCell(state.selectedCell!).alignment;
  }

  String? _getCellTextColor(SpreadsheetState state) {
    if (state.selectedCell == null || state.activeSheet == null) return null;
    return state.activeSheet!.getCell(state.selectedCell!).textColor;
  }

  String? _getCellBgColor(SpreadsheetState state) {
    if (state.selectedCell == null || state.activeSheet == null) return null;
    return state.activeSheet!.getCell(state.selectedCell!).backgroundColor;
  }

  NumberFormatType _getCellNumberFormat(SpreadsheetState state) {
    if (state.selectedCell == null || state.activeSheet == null) {
      return NumberFormatType.general;
    }
    return state.activeSheet!.getCell(state.selectedCell!).numberFormat;
  }

  // --- Shortcuts & Focus Handling ---

  bool _isEditingActive() {
    // Check if formula bar or a cell editor has focus.
    // On web, FocusManager.instance.primaryFocus may not match widget type
    // reliably, so we check our known focus node instead.
    if (_formulaFocusNode.hasFocus) return true;
    final focus = FocusManager.instance.primaryFocus;
    if (focus == null) return false;
    // Check if focus is within a cell editor (not our grid focus node)
    if (focus == _gridFocusNode) return false;
    final widget = focus.context?.widget;
    return widget is EditableText;
  }

  KeyEventResult _handleKeyEvent(KeyEvent event, SpreadsheetState state) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    if (_isEditingActive()) return KeyEventResult.ignored;

    final key = event.logicalKey;
    final isControlPressed = HardwareKeyboard.instance.isControlPressed;

    if (isControlPressed) {
      if (key == LogicalKeyboardKey.keyS) {
        context.read<SpreadsheetBloc>().add(const SaveSpreadsheet());
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.keyB) {
        context.read<SpreadsheetBloc>().add(const FormatCells('bold'));
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.keyI) {
        context.read<SpreadsheetBloc>().add(const FormatCells('italic'));
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.keyU) {
        context.read<SpreadsheetBloc>().add(const FormatCells('underline'));
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.keyZ) {
        context.read<SpreadsheetBloc>().add(const UndoSpreadsheet());
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.keyY) {
        context.read<SpreadsheetBloc>().add(const RedoSpreadsheet());
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.keyC) {
        context.read<SpreadsheetBloc>().add(const CopySelection());
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.keyX) {
        context.read<SpreadsheetBloc>().add(const CutSelection());
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.keyV) {
        context.read<SpreadsheetBloc>().add(const PasteSelection());
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.keyF) {
        setState(() => _showFindBar = !_showFindBar);
        return KeyEventResult.handled;
      }
    }

    if (key == LogicalKeyboardKey.delete) {
      context.read<SpreadsheetBloc>().add(const ClearSelection());
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowDown) {
      _navigateCell(context, state, 1, 0);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowUp) {
      _navigateCell(context, state, -1, 0);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowRight) {
      _navigateCell(context, state, 0, 1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowLeft) {
      _navigateCell(context, state, 0, -1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.tab) {
      _navigateCell(context, state, 0, 1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.enter) {
      _navigateCell(context, state, 1, 0);
      return KeyEventResult.handled;
    }

    // Direct typing into selected cell: when a printable key is pressed without Control/Alt/Meta
    if (event.character != null &&
        event.character!.isNotEmpty &&
        !HardwareKeyboard.instance.isAltPressed &&
        !HardwareKeyboard.instance.isMetaPressed) {
      final char = event.character!;
      if (char.codeUnitAt(0) >= 32 && char.codeUnitAt(0) != 127) {
        _formulaController.text = char;
        _formulaController.selection = TextSelection.fromPosition(
          TextPosition(offset: char.length),
        );
        _formulaFocusNode.requestFocus();
        if (state.selectedCell != null) {
          context
              .read<SpreadsheetBloc>()
              .add(UpdateCell(state.selectedCell!, char));
        }
        return KeyEventResult.handled;
      }
    }

    return KeyEventResult.ignored;
  }

  void _navigateCell(
      BuildContext context, SpreadsheetState state, int dRow, int dCol) {
    if (state.selectedCell == null || state.activeSheet == null) return;
    final newRow = (state.selectedCell!.row + dRow)
        .clamp(0, state.activeSheet!.rowCount - 1);
    final newCol = (state.selectedCell!.col + dCol)
        .clamp(0, state.activeSheet!.colCount - 1);
    context
        .read<SpreadsheetBloc>()
        .add(SelectCell(CellPosition(newRow, newCol)));
  }

  // --- Context Menu ---

  void _showCellContextMenu(
      BuildContext context, CellPosition pos, Offset globalPosition) {
    final bloc = context.read<SpreadsheetBloc>();
    final theme = Theme.of(context);
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;

    showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromLTWH(globalPosition.dx, globalPosition.dy, 0, 0),
        Offset.zero & overlay.size,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: 8,
      color: theme.colorScheme.surfaceContainer,
      items: [
        _contextItem(Icons.content_cut, 'Cut', 'Ctrl+X', 'cut'),
        _contextItem(Icons.content_copy, 'Copy', 'Ctrl+C', 'copy'),
        _contextItem(Icons.content_paste, 'Paste', 'Ctrl+V', 'paste'),
        const PopupMenuItem<String>(
          enabled: false,
          height: 9,
          padding: EdgeInsets.zero,
          child: Divider(height: 1),
        ),
        _contextItem(Icons.table_rows, 'Insert Row Below', null, 'insertRow'),
        _contextItem(
            Icons.view_column, 'Insert Column Right', null, 'insertCol'),
        _contextItem(Icons.delete_sweep, 'Delete Row', null, 'deleteRow'),
        _contextItem(
            Icons.remove_circle_outline, 'Delete Column', null, 'deleteCol'),
        const PopupMenuItem<String>(
          enabled: false,
          height: 9,
          padding: EdgeInsets.zero,
          child: Divider(height: 1),
        ),
        _contextItem(Icons.comment, 'Add Comment', null, 'comment'),
        _contextItem(Icons.link, 'Add Hyperlink', null, 'hyperlink'),
        _contextItem(Icons.sort, 'Sort A→Z', null, 'sortAsc'),
        _contextItem(Icons.sort, 'Sort Z→A', null, 'sortDesc'),
      ],
    ).then((value) {
      if (value == null) return;
      switch (value) {
        case 'cut':
          bloc.add(const CutSelection());
        case 'copy':
          bloc.add(const CopySelection());
        case 'paste':
          bloc.add(const PasteSelection());
        case 'insertRow':
          bloc.add(InsertRow(pos.row));
        case 'insertCol':
          bloc.add(InsertColumn(pos.col));
        case 'deleteRow':
          bloc.add(DeleteRow(pos.row));
        case 'deleteCol':
          bloc.add(DeleteColumn(pos.col));
        case 'comment':
          if (context.mounted) _showAddCommentDialog(context, bloc.state);
        case 'hyperlink':
          if (context.mounted) _showAddHyperlinkDialog(context, bloc.state);
        case 'sortAsc':
          bloc.add(SortColumn(pos.col, ascending: true));
        case 'sortDesc':
          bloc.add(SortColumn(pos.col, ascending: false));
      }
    });
  }

  PopupMenuItem<String> _contextItem(
      IconData icon, String label, String? shortcut, String value) {
    return PopupMenuItem<String>(
      value: value,
      height: 36,
      child: Row(
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
          if (shortcut != null) ...[
            const SizedBox(width: 16),
            Text(shortcut,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
          ],
        ],
      ),
    );
  }

  // --- Dialogs ---

  void _showFreezeDialog(BuildContext context, SpreadsheetState state) {
    final rowController = TextEditingController(
        text: state.activeSheet?.frozenRows.toString() ?? '0');
    final colController = TextEditingController(
        text: state.activeSheet?.frozenCols.toString() ?? '0');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Freeze Panes'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: rowController,
              decoration: const InputDecoration(labelText: 'Frozen rows'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: colController,
              decoration: const InputDecoration(labelText: 'Frozen columns'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final rows = int.tryParse(rowController.text) ?? 0;
              final cols = int.tryParse(colController.text) ?? 0;
              context.read<SpreadsheetBloc>().add(SetFrozenPanes(rows, cols));
              Navigator.pop(context);
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _showAddCommentDialog(BuildContext context, SpreadsheetState state) {
    if (state.selectedCell == null) return;
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Comment'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Enter comment...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                context
                    .read<SpreadsheetBloc>()
                    .add(AddComment(state.selectedCell!, controller.text));
              }
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showAddHyperlinkDialog(BuildContext context, SpreadsheetState state) {
    if (state.selectedCell == null) return;
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Hyperlink'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'https://...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                context
                    .read<SpreadsheetBloc>()
                    .add(AddHyperlink(state.selectedCell!, controller.text));
              }
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _importLocalFile(BuildContext context) async {
    final result = await fp.FilePicker.platform.pickFiles(
      type: fp.FileType.custom,
      allowedExtensions: ['csv', 'tsv', 'xlsx', 'xls', 'ods', 'txt'],
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      final file = result.files.single;
      if (file.bytes != null && context.mounted) {
        final ext = file.extension?.toLowerCase() ?? '';
        if (ext == 'xlsx' || ext == 'xls') {
          context.read<SpreadsheetBloc>().add(
                ImportXlsx(file.bytes!, fileName: file.name),
              );
        } else {
          context.read<SpreadsheetBloc>().add(
                ImportCsv(file.bytes!, fileName: file.name),
              );
        }
      }
    }
  }

  Future<void> _exportCsv(BuildContext context, SpreadsheetState state) async {
    final sheet = state.activeSheet;
    if (sheet == null) return;

    int maxRow = 0;
    int maxCol = 0;
    for (final key in sheet.cells.keys) {
      final parts = key.split(',');
      final r = int.parse(parts[0]);
      final c = int.parse(parts[1]);
      if (r > maxRow) maxRow = r;
      if (c > maxCol) maxCol = c;
    }

    final rows = <List<String>>[];
    for (int r = 0; r <= maxRow; r++) {
      final row = <String>[];
      for (int c = 0; c <= maxCol; c++) {
        final cell = sheet.getCell(CellPosition(r, c));
        row.add(cell.displayValue);
      }
      rows.add(row);
    }

    final csv = const ListToCsvConverter().convert(rows);
    final title = state.currentSpreadsheet?.title ?? 'spreadsheet';
    final fileName = '$title.csv';
    final bytes = Uint8List.fromList(csv.codeUnits);

    await FileDownloadUtils.downloadBytes(
      bytes: bytes,
      fileName: fileName,
      mimeType: 'text/csv',
    );
  }

  void _shareSpreadsheet(BuildContext context, SpreadsheetState state) {
    final title = state.currentSpreadsheet?.title ?? 'Spreadsheet';
    final sheetInfo =
        '${state.sheets.length} sheet${state.sheets.length > 1 ? "s" : ""}';
    int cellCount = 0;
    for (final sheet in state.sheets) {
      cellCount += sheet.cells.length;
    }
    Share.share(
      '$title\n$sheetInfo, $cellCount cells with data',
      subject: title,
    );
  }

  void _showChartDialog(BuildContext context, SpreadsheetState state) {
    if (state.activeSheet == null) return;
    final sheet = state.activeSheet!;

    // Use selected range or default to data-filled area
    CellRange dataRange;
    if (state.selectedRange != null) {
      dataRange = state.selectedRange!;
    } else {
      // Auto-detect data range
      int maxRow = 0;
      int maxCol = 0;
      for (final key in sheet.cells.keys) {
        final parts = key.split(',');
        if (parts.length == 2) {
          final r = int.tryParse(parts[0]) ?? 0;
          final c = int.tryParse(parts[1]) ?? 0;
          if (r > maxRow) maxRow = r;
          if (c > maxCol) maxCol = c;
        }
      }
      dataRange = CellRange(
        const CellPosition(0, 0),
        CellPosition(maxRow, maxCol),
      );
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
        maxWidth: 600,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => _ChartBottomSheet(
        sheet: sheet,
        dataRange: dataRange,
      ),
    );
  }
}

/// Bottom sheet for selecting and previewing charts.
class _ChartBottomSheet extends StatefulWidget {
  final SheetData sheet;
  final CellRange dataRange;

  const _ChartBottomSheet({
    required this.sheet,
    required this.dataRange,
  });

  @override
  State<_ChartBottomSheet> createState() => _ChartBottomSheetState();
}

class _ChartBottomSheetState extends State<_ChartBottomSheet> {
  SpreadsheetChartType _chartType = SpreadsheetChartType.bar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.bar_chart, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text('Insert Chart',
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Chart type chips
          Wrap(
            spacing: 8,
            children: SpreadsheetChartType.values.map((type) {
              final label = switch (type) {
                SpreadsheetChartType.bar => 'Bar',
                SpreadsheetChartType.line => 'Line',
                SpreadsheetChartType.pie => 'Pie',
              };
              final icon = switch (type) {
                SpreadsheetChartType.bar => Icons.bar_chart,
                SpreadsheetChartType.line => Icons.show_chart,
                SpreadsheetChartType.pie => Icons.pie_chart,
              };
              return ChoiceChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 16),
                    const SizedBox(width: 4),
                    Text(label),
                  ],
                ),
                selected: _chartType == type,
                onSelected: (sel) {
                  if (sel) setState(() => _chartType = type);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 8),

          // Range info
          Text(
            'Data range: ${widget.dataRange.topLeft.reference}:${widget.dataRange.bottomRight.reference}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 16),

          // Chart preview
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant,
                  width: 0.5,
                ),
              ),
              child: SpreadsheetChart(
                sheet: widget.sheet,
                dataRange: widget.dataRange,
                chartType: _chartType,
                title: 'Chart Preview',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ColorPickerButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final String? currentColor;
  final ValueChanged<String> onColorSelected;

  const _ColorPickerButton({
    required this.icon,
    required this.tooltip,
    required this.currentColor,
    required this.onColorSelected,
  });

  static const _colors = [
    '#000000',
    '#434343',
    '#666666',
    '#999999',
    '#CCCCCC',
    '#FFFFFF',
    '#FF0000',
    '#FF6600',
    '#FFCC00',
    '#33CC33',
    '#3399FF',
    '#6633CC',
    '#CC0066',
    '#FF3399',
    '#FF9933',
    '#99CC00',
    '#00CCCC',
    '#3366FF',
  ];

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: tooltip,
      onSelected: onColorSelected,
      itemBuilder: (_) => [
        PopupMenuItem<String>(
          enabled: false,
          child: Wrap(
            spacing: 4,
            runSpacing: 4,
            children: _colors
                .map((c) => GestureDetector(
                      onTap: () {
                        Navigator.pop(context, c);
                        onColorSelected(c);
                      },
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: _parseColor(c),
                          border: Border.all(
                              color: Colors.grey.shade400, width: 0.5),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ))
                .toList(),
          ),
        ),
      ],
      child: SizedBox(
        width: 32,
        height: 32,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18),
            Container(
              width: 16,
              height: 3,
              color: currentColor != null
                  ? _parseColor(currentColor!)
                  : Colors.black,
            ),
          ],
        ),
      ),
    );
  }

  Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return Colors.black;
    }
  }
}

// --- Formula Bar ---

class _FormulaBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String cellRef;
  final ValueChanged<String> onSubmitted;
  final ValueChanged<String>? onChanged;

  const _FormulaBar({
    required this.controller,
    this.focusNode,
    required this.cellRef,
    required this.onSubmitted,
    this.onChanged,
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Icon(Icons.functions,
                size: 18, color: theme.colorScheme.onSurfaceVariant),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 8),
                isDense: true,
              ),
              style:
                  theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
              onSubmitted: onSubmitted,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

// --- Virtual Spreadsheet Grid ---

class _VirtualSpreadsheetGrid extends StatefulWidget {
  final SheetData sheet;
  final CellPosition? selectedCell;
  final CellRange? selectedRange;
  final List<CellPosition> findMatches;
  final ScrollController verticalController;
  final ScrollController horizontalController;
  final ValueChanged<CellPosition> onCellTap;
  final void Function(CellPosition, String) onCellEdit;
  final ValueChanged<CellRange> onRangeSelect;
  final void Function(CellPosition, Offset) onContextMenu;
  final void Function(int col, double width) onColumnResize;
  final VoidCallback onEditComplete;

  const _VirtualSpreadsheetGrid({
    required this.sheet,
    required this.selectedCell,
    required this.selectedRange,
    required this.findMatches,
    required this.verticalController,
    required this.horizontalController,
    required this.onCellTap,
    required this.onCellEdit,
    required this.onRangeSelect,
    required this.onContextMenu,
    required this.onColumnResize,
    required this.onEditComplete,
  });

  static const double _defaultColWidth = 100;
  static const double _defaultRowHeight = 32;
  static const double _headerWidth = 50;
  static const double _headerHeight = 28;

  @override
  State<_VirtualSpreadsheetGrid> createState() =>
      _VirtualSpreadsheetGridState();
}

class _VirtualSpreadsheetGridState extends State<_VirtualSpreadsheetGrid> {
  CellPosition? _dragStartCell;
  bool _isDragging = false;
  final GlobalKey _gridKey = GlobalKey();

  void _handleCellDragStart(CellPosition pos) {
    _dragStartCell = pos;
    _isDragging = true;
    widget.onCellTap(pos);
  }

  void _handleCellDragUpdate(CellPosition pos) {
    if (_dragStartCell != null) {
      widget.onRangeSelect(CellRange(_dragStartCell!, pos));
    }
  }

  /// Calculate which cell a global pointer offset falls on.
  CellPosition? _cellFromGlobalOffset(Offset global) {
    final box = _gridKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return null;
    final local = box.globalToLocal(global);

    // Account for horizontal scroll
    final hScroll = widget.horizontalController.hasClients
        ? widget.horizontalController.offset
        : 0.0;
    final xInGrid = local.dx + hScroll;

    // Account for header row height and vertical scroll
    final headerH = _VirtualSpreadsheetGrid._headerHeight;
    final vScroll = widget.verticalController.hasClients
        ? widget.verticalController.offset
        : 0.0;
    final yInGrid = local.dy - headerH + vScroll;

    if (yInGrid < 0 || xInGrid < _VirtualSpreadsheetGrid._headerWidth) {
      return null;
    }

    // Determine column
    double acc = _VirtualSpreadsheetGrid._headerWidth;
    int col = 0;
    for (int c = 0; c < widget.sheet.colCount; c++) {
      if (widget.sheet.hiddenCols.contains(c)) continue;
      final w = widget.sheet.columnWidths[c] ??
          _VirtualSpreadsheetGrid._defaultColWidth;
      if (xInGrid < acc + w) {
        col = c;
        break;
      }
      acc += w;
      col = c;
    }

    // Determine row
    int row = (yInGrid / _VirtualSpreadsheetGrid._defaultRowHeight).floor();
    row = row.clamp(0, widget.sheet.rowCount - 1);

    return CellPosition(row, col);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visibleCols = widget.sheet.colCount;

    double totalWidth = _VirtualSpreadsheetGrid._headerWidth;
    for (int c = 0; c < visibleCols; c++) {
      if (!widget.sheet.hiddenCols.contains(c)) {
        totalWidth += widget.sheet.columnWidths[c] ??
            _VirtualSpreadsheetGrid._defaultColWidth;
      }
    }

    return Listener(
      onPointerMove: (event) {
        if (_isDragging && _dragStartCell != null) {
          final pos = _cellFromGlobalOffset(event.position);
          if (pos != null) {
            _handleCellDragUpdate(pos);
          }
        }
      },
      onPointerUp: (_) {
        _isDragging = false;
      },
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        controller: widget.horizontalController,
        child: SizedBox(
          width: totalWidth,
          child: Column(
            key: _gridKey,
            children: [
              _buildColumnHeaders(theme, visibleCols),
              Expanded(
                child: ListView.builder(
                  controller: widget.verticalController,
                  itemCount: widget.sheet.rowCount,
                  itemExtent: _VirtualSpreadsheetGrid._defaultRowHeight,
                  itemBuilder: (context, row) {
                    if (widget.sheet.hiddenRows.contains(row)) {
                      return const SizedBox.shrink();
                    }
                    return _buildDataRow(theme, row, visibleCols);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildColumnHeaders(ThemeData theme, int visibleCols) {
    return SizedBox(
      height: _VirtualSpreadsheetGrid._headerHeight,
      child: Row(
        children: [
          GestureDetector(
            onTap: () => widget.onRangeSelect(CellRange(
              const CellPosition(0, 0),
              CellPosition(
                  widget.sheet.rowCount - 1, widget.sheet.colCount - 1),
            )),
            child: Container(
              width: _VirtualSpreadsheetGrid._headerWidth,
              height: _VirtualSpreadsheetGrid._headerHeight,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                border: Border.all(
                    color: theme.colorScheme.outlineVariant, width: 0.5),
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.select_all, size: 14),
            ),
          ),
          for (var col = 0; col < visibleCols; col++)
            if (!widget.sheet.hiddenCols.contains(col))
              GestureDetector(
                onTap: () => widget.onRangeSelect(CellRange(
                  CellPosition(0, col),
                  CellPosition(widget.sheet.rowCount - 1, col),
                )),
                onHorizontalDragUpdate: (details) {
                  final currentWidth = widget.sheet.columnWidths[col] ??
                      _VirtualSpreadsheetGrid._defaultColWidth;
                  final newWidth =
                      (currentWidth + details.delta.dx).clamp(40.0, 400.0);
                  widget.onColumnResize(col, newWidth);
                },
                child: Container(
                  width: widget.sheet.columnWidths[col] ??
                      _VirtualSpreadsheetGrid._defaultColWidth,
                  height: _VirtualSpreadsheetGrid._headerHeight,
                  decoration: BoxDecoration(
                    color: widget.selectedCell?.col == col
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
              ),
        ],
      ),
    );
  }

  Widget _buildDataRow(ThemeData theme, int row, int visibleCols) {
    final rowHeight = widget.sheet.rowHeights[row] ??
        _VirtualSpreadsheetGrid._defaultRowHeight;
    return SizedBox(
      height: rowHeight,
      child: Row(
        children: [
          GestureDetector(
            onTap: () => widget.onRangeSelect(CellRange(
              CellPosition(row, 0),
              CellPosition(row, widget.sheet.colCount - 1),
            )),
            child: Container(
              width: _VirtualSpreadsheetGrid._headerWidth,
              height: rowHeight,
              decoration: BoxDecoration(
                color: widget.selectedCell?.row == row
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
          ),
          for (var col = 0; col < visibleCols; col++)
            if (!widget.sheet.hiddenCols.contains(col))
              _GridCell(
                position: CellPosition(row, col),
                cell: widget.sheet.getCell(CellPosition(row, col)),
                isSelected: widget.selectedCell?.row == row &&
                    widget.selectedCell?.col == col,
                isInRange:
                    widget.selectedRange?.contains(CellPosition(row, col)) ??
                        false,
                isSearchMatch:
                    widget.findMatches.contains(CellPosition(row, col)),
                width: widget.sheet.columnWidths[col] ??
                    _VirtualSpreadsheetGrid._defaultColWidth,
                height: rowHeight,
                onTap: () => _handleCellDragStart(CellPosition(row, col)),
                onDragUpdate: (pos) => _handleCellDragUpdate(pos),
                onEdit: (value) =>
                    widget.onCellEdit(CellPosition(row, col), value),
                onContextMenu: (offset) =>
                    widget.onContextMenu(CellPosition(row, col), offset),
                onEditComplete: widget.onEditComplete,
              ),
        ],
      ),
    );
  }
}

// --- Grid Cell ---

class _GridCell extends StatefulWidget {
  final CellPosition position;
  final CellData cell;
  final bool isSelected;
  final bool isInRange;
  final bool isSearchMatch;
  final double width;
  final double height;
  final VoidCallback onTap;
  final ValueChanged<CellPosition> onDragUpdate;
  final ValueChanged<String> onEdit;
  final ValueChanged<Offset> onContextMenu;
  final VoidCallback onEditComplete;

  const _GridCell({
    required this.position,
    required this.cell,
    required this.isSelected,
    required this.isInRange,
    required this.isSearchMatch,
    required this.width,
    required this.height,
    required this.onTap,
    required this.onDragUpdate,
    required this.onEdit,
    required this.onContextMenu,
    required this.onEditComplete,
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

    final baseBgColor = cellBgColor ?? Colors.transparent;
    Color? bgColor = baseBgColor;
    if (widget.isSearchMatch) {
      bgColor =
          Color.alphaBlend(Colors.amber.withValues(alpha: 0.4), baseBgColor);
    } else if (widget.isSelected) {
      bgColor = Color.alphaBlend(
          theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
          baseBgColor);
    } else if (widget.isInRange) {
      bgColor = Color.alphaBlend(
          theme.colorScheme.primaryContainer.withValues(alpha: 0.2),
          baseBgColor);
    }

    return Listener(
      // Prevent browser context menu on web and trigger our custom one
      onPointerDown: (event) {
        if (event.buttons == 2) {
          // Right-click
          widget.onTap();
          widget.onContextMenu(event.position);
        }
      },
      child: GestureDetector(
        onTap: () {
          widget.onTap();
          if (_isEditing) return;
        },
        onPanStart: (_) {
          widget.onTap();
        },
        onPanUpdate: (_) {
          widget.onDragUpdate(widget.position);
        },
        onDoubleTap: () {
          setState(() => _isEditing = true);
          _controller.text = widget.cell.rawValue;
        },
        onLongPressStart: (details) {
          widget.onTap();
          widget.onContextMenu(details.globalPosition);
        },
        child: Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: bgColor,
            border: Border.all(
              color: widget.isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outlineVariant,
              width: widget.isSelected ? 2.0 : 0.5,
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
                    widget.onEditComplete();
                  },
                  onTapOutside: (_) {
                    widget.onEdit(_controller.text);
                    setState(() => _isEditing = false);
                    widget.onEditComplete();
                  },
                )
              : _buildCellContent(theme),
        ),
      ),
    );
  }

  Widget _buildCellContent(ThemeData theme) {
    final displayText = widget.cell.hasError
        ? widget.cell.errorMessage ?? '#ERROR!'
        : widget.cell.displayValue;

    // Show comment indicator
    final hasComment = widget.cell.comment != null;
    // Show hyperlink indicator
    final hasLink = widget.cell.hyperlink != null;

    return Stack(
      children: [
        Positioned.fill(
          child: Align(
            alignment: _getAlignment(widget.cell.alignment),
            child: Text(
              displayText,
              style: _getCellTextStyle(theme).copyWith(
                color: widget.cell.hasError
                    ? Colors.red
                    : hasLink
                        ? Colors.blue
                        : null,
                decoration: hasLink
                    ? TextDecoration.underline
                    : widget.cell.isStrikethrough
                        ? TextDecoration.lineThrough
                        : widget.cell.isUnderline
                            ? TextDecoration.underline
                            : null,
              ),
              maxLines: widget.cell.wrapText ? null : 1,
              overflow: widget.cell.wrapText ? null : TextOverflow.ellipsis,
            ),
          ),
        ),
        if (hasComment)
          Positioned(
            top: 0,
            right: 0,
            child: CustomPaint(
              size: const Size(8, 8),
              painter: _CommentIndicatorPainter(),
            ),
          ),
      ],
    );
  }

  TextStyle _getCellTextStyle(ThemeData theme) {
    return theme.textTheme.bodySmall!.copyWith(
      fontWeight: widget.cell.isBold ? FontWeight.bold : FontWeight.normal,
      fontStyle: widget.cell.isItalic ? FontStyle.italic : FontStyle.normal,
      fontSize: widget.cell.fontSize,
      fontFamily: widget.cell.fontFamily,
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

class _CommentIndicatorPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.orange;
    canvas.drawPath(
      Path()
        ..moveTo(size.width, 0)
        ..lineTo(size.width, size.height)
        ..lineTo(0, 0)
        ..close(),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// --- Status Bar ---

class _StatusBar extends StatelessWidget {
  final SpreadsheetState state;

  const _StatusBar({required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sheet = state.activeSheet;
    if (sheet == null) return const SizedBox.shrink();

    // Calculate selection statistics
    String stats = '';
    if (state.selectedRange != null && !state.selectedRange!.isSingleCell) {
      double sum = 0;
      int count = 0;
      int numCount = 0;

      for (final pos in state.selectedRange!.positions) {
        final cell = sheet.getCell(pos);
        if (!cell.isEmpty) {
          count++;
          final num = double.tryParse(cell.displayValue);
          if (num != null) {
            sum += num;
            numCount++;
          }
        }
      }

      if (numCount > 0) {
        final avg = sum / numCount;
        stats =
            'SUM: ${sum.toStringAsFixed(2)}  |  AVG: ${avg.toStringAsFixed(2)}  |  COUNT: $count';
      } else {
        stats = 'COUNT: $count';
      }
    }

    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Text(
            '${sheet.cells.length} cells',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          if (stats.isNotEmpty)
            Text(
              stats,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }
}

// --- Sheet Tabs ---

class _SheetTabs extends StatelessWidget {
  final List<SheetData> sheets;
  final int activeIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onAdd;
  final void Function(int, String) onRename;
  final ValueChanged<int> onDelete;
  final ValueChanged<int> onDuplicate;

  const _SheetTabs({
    required this.sheets,
    required this.activeIndex,
    required this.onSelect,
    required this.onAdd,
    required this.onRename,
    required this.onDelete,
    required this.onDuplicate,
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
          IconButton(
            icon: const Icon(Icons.add, size: 18),
            onPressed: onAdd,
            tooltip: 'Add sheet',
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: sheets.length,
              itemBuilder: (context, index) {
                final isActive = index == activeIndex;
                return GestureDetector(
                  onTap: () => onSelect(index),
                  onLongPress: () => _showSheetMenu(context, index),
                  onSecondaryTap: () => _showSheetMenu(context, index),
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
          ListTile(
            leading: const Icon(Icons.copy),
            title: const Text('Duplicate'),
            onTap: () {
              Navigator.pop(context);
              onDuplicate(index);
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
