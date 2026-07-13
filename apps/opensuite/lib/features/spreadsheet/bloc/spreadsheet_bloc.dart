import 'dart:async';
import 'dart:convert';

import 'package:bloc_concurrency/bloc_concurrency.dart';

import 'package:equatable/equatable.dart';
import 'package:fileutility_core/fileutility_core.dart';
import 'package:fileutility_storage/fileutility_storage.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// --- Events ---

sealed class SpreadsheetEvent extends Equatable {
  const SpreadsheetEvent();
  @override
  List<Object?> get props => [];
}

class LoadSpreadsheets extends SpreadsheetEvent {
  const LoadSpreadsheets();
}

class SearchSpreadsheets extends SpreadsheetEvent {
  final String query;
  const SearchSpreadsheets(this.query);
  @override
  List<Object?> get props => [query];
}

class CreateSpreadsheet extends SpreadsheetEvent {
  final String title;
  const CreateSpreadsheet({this.title = 'Untitled Spreadsheet'});
  @override
  List<Object?> get props => [title];
}

class OpenSpreadsheet extends SpreadsheetEvent {
  final String id;
  const OpenSpreadsheet(this.id);
  @override
  List<Object?> get props => [id];
}

class UpdateCell extends SpreadsheetEvent {
  final CellPosition position;
  final String value;
  const UpdateCell(this.position, this.value);
  @override
  List<Object?> get props => [position, value];
}

class SelectCell extends SpreadsheetEvent {
  final CellPosition position;
  const SelectCell(this.position);
  @override
  List<Object?> get props => [position];
}

class SetCellRange extends SpreadsheetEvent {
  final CellRange range;
  const SetCellRange(this.range);
  @override
  List<Object?> get props => [range];
}

class FormatCells extends SpreadsheetEvent {
  final String formatType; // 'bold', 'italic', 'underline', etc.
  const FormatCells(this.formatType);
  @override
  List<Object?> get props => [formatType];
}

class SetTextColor extends SpreadsheetEvent {
  final String hexColor;
  const SetTextColor(this.hexColor);
  @override
  List<Object?> get props => [hexColor];
}

class SetBackgroundColor extends SpreadsheetEvent {
  final String hexColor;
  const SetBackgroundColor(this.hexColor);
  @override
  List<Object?> get props => [hexColor];
}

class SetFontFamily extends SpreadsheetEvent {
  final String fontFamily;
  const SetFontFamily(this.fontFamily);
  @override
  List<Object?> get props => [fontFamily];
}

class SetFontSize extends SpreadsheetEvent {
  final double size;
  const SetFontSize(this.size);
  @override
  List<Object?> get props => [size];
}

class SetNumberFormat extends SpreadsheetEvent {
  final NumberFormatType format;
  const SetNumberFormat(this.format);
  @override
  List<Object?> get props => [format];
}

class SetBorders extends SpreadsheetEvent {
  final CellBorders borders;
  const SetBorders(this.borders);
  @override
  List<Object?> get props => [borders];
}

// --- Row/Column Operations ---

class InsertRow extends SpreadsheetEvent {
  final int afterRow;
  const InsertRow(this.afterRow);
  @override
  List<Object?> get props => [afterRow];
}

class DeleteRow extends SpreadsheetEvent {
  final int row;
  const DeleteRow(this.row);
  @override
  List<Object?> get props => [row];
}

class InsertColumn extends SpreadsheetEvent {
  final int afterCol;
  const InsertColumn(this.afterCol);
  @override
  List<Object?> get props => [afterCol];
}

class DeleteColumn extends SpreadsheetEvent {
  final int col;
  const DeleteColumn(this.col);
  @override
  List<Object?> get props => [col];
}

class ResizeRow extends SpreadsheetEvent {
  final int row;
  final double height;
  const ResizeRow(this.row, this.height);
  @override
  List<Object?> get props => [row, height];
}

class ResizeColumn extends SpreadsheetEvent {
  final int col;
  final double width;
  const ResizeColumn(this.col, this.width);
  @override
  List<Object?> get props => [col, width];
}

class HideRows extends SpreadsheetEvent {
  final List<int> rows;
  const HideRows(this.rows);
  @override
  List<Object?> get props => [rows];
}

class UnhideRows extends SpreadsheetEvent {
  const UnhideRows();
}

class HideCols extends SpreadsheetEvent {
  final List<int> cols;
  const HideCols(this.cols);
  @override
  List<Object?> get props => [cols];
}

class UnhideCols extends SpreadsheetEvent {
  const UnhideCols();
}

// --- Clipboard ---

class CopySelection extends SpreadsheetEvent {
  const CopySelection();
}

class CutSelection extends SpreadsheetEvent {
  const CutSelection();
}

class PasteSelection extends SpreadsheetEvent {
  const PasteSelection();
}

class ClearSelection extends SpreadsheetEvent {
  const ClearSelection();
}

// --- Undo/Redo ---

class UndoSpreadsheet extends SpreadsheetEvent {
  const UndoSpreadsheet();
}

class RedoSpreadsheet extends SpreadsheetEvent {
  const RedoSpreadsheet();
}

// --- Find & Replace ---

class FindInSheet extends SpreadsheetEvent {
  final String query;
  const FindInSheet(this.query);
  @override
  List<Object?> get props => [query];
}

class ReplaceInSheet extends SpreadsheetEvent {
  final String query;
  final String replacement;
  final bool replaceAll;
  const ReplaceInSheet(this.query, this.replacement,
      {this.replaceAll = false});
  @override
  List<Object?> get props => [query, replacement, replaceAll];
}

class ClearFind extends SpreadsheetEvent {
  const ClearFind();
}

// --- Merge ---

class MergeCells extends SpreadsheetEvent {
  final CellRange range;
  const MergeCells(this.range);
  @override
  List<Object?> get props => [range];
}

class UnmergeCells extends SpreadsheetEvent {
  final CellPosition position;
  const UnmergeCells(this.position);
  @override
  List<Object?> get props => [position];
}

// --- Comments ---

class AddComment extends SpreadsheetEvent {
  final CellPosition position;
  final String text;
  const AddComment(this.position, this.text);
  @override
  List<Object?> get props => [position, text];
}

class RemoveComment extends SpreadsheetEvent {
  final CellPosition position;
  const RemoveComment(this.position);
  @override
  List<Object?> get props => [position];
}

// --- Hyperlinks ---

class AddHyperlink extends SpreadsheetEvent {
  final CellPosition position;
  final String url;
  const AddHyperlink(this.position, this.url);
  @override
  List<Object?> get props => [position, url];
}

// --- Sheet Management ---

class AddSheet extends SpreadsheetEvent {
  const AddSheet();
}

class SelectSheet extends SpreadsheetEvent {
  final int index;
  const SelectSheet(this.index);
  @override
  List<Object?> get props => [index];
}

class RenameSheet extends SpreadsheetEvent {
  final int index;
  final String name;
  const RenameSheet(this.index, this.name);
  @override
  List<Object?> get props => [index, name];
}

class DeleteSheet extends SpreadsheetEvent {
  final int index;
  const DeleteSheet(this.index);
  @override
  List<Object?> get props => [index];
}

class DuplicateSheet extends SpreadsheetEvent {
  final int index;
  const DuplicateSheet(this.index);
  @override
  List<Object?> get props => [index];
}

class ReorderSheet extends SpreadsheetEvent {
  final int from;
  final int to;
  const ReorderSheet(this.from, this.to);
  @override
  List<Object?> get props => [from, to];
}

// --- Save/Delete/Favorites ---

class SaveSpreadsheet extends SpreadsheetEvent {
  const SaveSpreadsheet();
}

class AutoSaveSpreadsheet extends SpreadsheetEvent {
  const AutoSaveSpreadsheet();
}

class DeleteSpreadsheetEntry extends SpreadsheetEvent {
  final String id;
  const DeleteSpreadsheetEntry(this.id);
  @override
  List<Object?> get props => [id];
}

class ToggleSpreadsheetFavorite extends SpreadsheetEvent {
  final String id;
  const ToggleSpreadsheetFavorite(this.id);
  @override
  List<Object?> get props => [id];
}

class DuplicateSpreadsheetEntry extends SpreadsheetEvent {
  final String id;
  const DuplicateSpreadsheetEntry(this.id);
  @override
  List<Object?> get props => [id];
}

class SetFrozenPanes extends SpreadsheetEvent {
  final int rows;
  final int cols;
  const SetFrozenPanes(this.rows, this.cols);
  @override
  List<Object?> get props => [rows, cols];
}

class SortColumn extends SpreadsheetEvent {
  final int col;
  final bool ascending;
  const SortColumn(this.col, {this.ascending = true});
  @override
  List<Object?> get props => [col, ascending];
}

// --- State ---

enum SpreadsheetStatus {
  initial,
  loading,
  loaded,
  editing,
  saving,
  saved,
  error
}

class SpreadsheetState extends Equatable {
  final SpreadsheetStatus status;
  final List<SpreadsheetEntity> spreadsheets;
  final SpreadsheetEntity? currentSpreadsheet;
  final List<SheetData> sheets;
  final int activeSheetIndex;
  final CellPosition? selectedCell;
  final CellRange? selectedRange;
  final String cellEditValue;
  final String formulaBarValue;
  final bool hasUnsavedChanges;
  final String searchQuery;
  final String? errorMessage;
  final bool canUndo;
  final bool canRedo;

  // Find state
  final String findQuery;
  final List<CellPosition> findMatches;
  final int findMatchIndex;

  // Clipboard state
  final CellRange? clipboardRange;
  final bool isClipboardCut;

  const SpreadsheetState({
    this.status = SpreadsheetStatus.initial,
    this.spreadsheets = const [],
    this.currentSpreadsheet,
    this.sheets = const [],
    this.activeSheetIndex = 0,
    this.selectedCell,
    this.selectedRange,
    this.cellEditValue = '',
    this.formulaBarValue = '',
    this.hasUnsavedChanges = false,
    this.searchQuery = '',
    this.errorMessage,
    this.canUndo = false,
    this.canRedo = false,
    this.findQuery = '',
    this.findMatches = const [],
    this.findMatchIndex = -1,
    this.clipboardRange,
    this.isClipboardCut = false,
  });

  /// The currently active sheet.
  SheetData? get activeSheet =>
      activeSheetIndex < sheets.length ? sheets[activeSheetIndex] : null;

  SpreadsheetState copyWith({
    SpreadsheetStatus? status,
    List<SpreadsheetEntity>? spreadsheets,
    SpreadsheetEntity? currentSpreadsheet,
    List<SheetData>? sheets,
    int? activeSheetIndex,
    CellPosition? selectedCell,
    CellRange? selectedRange,
    String? cellEditValue,
    String? formulaBarValue,
    bool? hasUnsavedChanges,
    String? searchQuery,
    String? errorMessage,
    bool? canUndo,
    bool? canRedo,
    String? findQuery,
    List<CellPosition>? findMatches,
    int? findMatchIndex,
    CellRange? clipboardRange,
    bool? isClipboardCut,
  }) {
    return SpreadsheetState(
      status: status ?? this.status,
      spreadsheets: spreadsheets ?? this.spreadsheets,
      currentSpreadsheet: currentSpreadsheet ?? this.currentSpreadsheet,
      sheets: sheets ?? this.sheets,
      activeSheetIndex: activeSheetIndex ?? this.activeSheetIndex,
      selectedCell: selectedCell ?? this.selectedCell,
      selectedRange: selectedRange ?? this.selectedRange,
      cellEditValue: cellEditValue ?? this.cellEditValue,
      formulaBarValue: formulaBarValue ?? this.formulaBarValue,
      hasUnsavedChanges: hasUnsavedChanges ?? this.hasUnsavedChanges,
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: errorMessage ?? this.errorMessage,
      canUndo: canUndo ?? this.canUndo,
      canRedo: canRedo ?? this.canRedo,
      findQuery: findQuery ?? this.findQuery,
      findMatches: findMatches ?? this.findMatches,
      findMatchIndex: findMatchIndex ?? this.findMatchIndex,
      clipboardRange: clipboardRange ?? this.clipboardRange,
      isClipboardCut: isClipboardCut ?? this.isClipboardCut,
    );
  }

  @override
  List<Object?> get props => [
        status,
        spreadsheets,
        currentSpreadsheet,
        sheets,
        activeSheetIndex,
        selectedCell,
        selectedRange,
        cellEditValue,
        hasUnsavedChanges,
        searchQuery,
        errorMessage,
        canUndo,
        canRedo,
        findQuery,
        findMatches,
        findMatchIndex,
        clipboardRange,
        isClipboardCut,
      ];
}

// --- BLoC ---

class SpreadsheetBloc extends Bloc<SpreadsheetEvent, SpreadsheetState> {
  final SpreadsheetDao _dao;
  late final FormulaEngine _formulaEngine;
  Timer? _autoSaveTimer;
  final UndoRedoManager<List<SheetData>> _undoManager =
      UndoRedoManager(maxHistory: 100);

  // Internal clipboard for cell data
  Map<String, CellData>? _clipboardCells;

  SpreadsheetBloc({required SpreadsheetDao spreadsheetDao})
      : _dao = spreadsheetDao,
        super(const SpreadsheetState()) {
    _formulaEngine = FormulaEngine(
      cellResolver: _resolveCellValue,
      textResolver: _resolveCellText,
    );

    on<LoadSpreadsheets>(_onLoad);
    on<SearchSpreadsheets>(_onSearch, transformer: restartable());
    on<CreateSpreadsheet>(_onCreate);
    on<OpenSpreadsheet>(_onOpen);
    on<UpdateCell>(_onUpdateCell);
    on<SelectCell>(_onSelectCell);
    on<SetCellRange>(_onSetCellRange);
    on<FormatCells>(_onFormatCells);
    on<SetTextColor>(_onSetTextColor);
    on<SetBackgroundColor>(_onSetBackgroundColor);
    on<SetFontFamily>(_onSetFontFamily);
    on<SetFontSize>(_onSetFontSize);
    on<SetNumberFormat>(_onSetNumberFormat);
    on<SetBorders>(_onSetBorders);
    on<InsertRow>(_onInsertRow);
    on<DeleteRow>(_onDeleteRow);
    on<InsertColumn>(_onInsertColumn);
    on<DeleteColumn>(_onDeleteColumn);
    on<ResizeRow>(_onResizeRow);
    on<ResizeColumn>(_onResizeColumn);
    on<HideRows>(_onHideRows);
    on<UnhideRows>(_onUnhideRows);
    on<HideCols>(_onHideCols);
    on<UnhideCols>(_onUnhideCols);
    on<CopySelection>(_onCopy);
    on<CutSelection>(_onCut);
    on<PasteSelection>(_onPaste);
    on<ClearSelection>(_onClearSelection);
    on<UndoSpreadsheet>(_onUndo);
    on<RedoSpreadsheet>(_onRedo);
    on<FindInSheet>(_onFind);
    on<ReplaceInSheet>(_onReplace);
    on<ClearFind>(_onClearFind);
    on<MergeCells>(_onMergeCells);
    on<UnmergeCells>(_onUnmergeCells);
    on<AddComment>(_onAddComment);
    on<RemoveComment>(_onRemoveComment);
    on<AddHyperlink>(_onAddHyperlink);
    on<AddSheet>(_onAddSheet);
    on<SelectSheet>(_onSelectSheet);
    on<RenameSheet>(_onRenameSheet);
    on<DeleteSheet>(_onDeleteSheet);
    on<DuplicateSheet>(_onDuplicateSheet);
    on<ReorderSheet>(_onReorderSheet);
    on<SaveSpreadsheet>(_onSave);
    on<AutoSaveSpreadsheet>(_onAutoSave);
    on<DeleteSpreadsheetEntry>(_onDelete);
    on<ToggleSpreadsheetFavorite>(_onToggleFavorite);
    on<DuplicateSpreadsheetEntry>(_onDuplicate);
    on<SetFrozenPanes>(_onSetFrozenPanes);
    on<SortColumn>(_onSortColumn);
  }

  // --- Helpers ---

  void _pushUndo() {
    _undoManager.push(List<SheetData>.from(state.sheets));
  }

  void _emitWithUndo(Emitter<SpreadsheetState> emit,
      {required List<SheetData> sheets, bool markDirty = true}) {
    emit(state.copyWith(
      sheets: sheets,
      hasUnsavedChanges: markDirty ? true : state.hasUnsavedChanges,
      canUndo: _undoManager.canUndo,
      canRedo: _undoManager.canRedo,
    ));
    if (markDirty) _scheduleAutoSave();
  }

  SheetData _updateActiveSheet(SheetData updatedSheet) {
    return updatedSheet;
  }

  List<SheetData> _replaceActiveSheet(SheetData updatedSheet) {
    final newSheets = List<SheetData>.from(state.sheets);
    newSheets[state.activeSheetIndex] = _updateActiveSheet(updatedSheet);
    return newSheets;
  }

  /// Apply a formatting function to the selected cell or range.
  void _applyFormatToSelection(
    Emitter<SpreadsheetState> emit,
    CellData Function(CellData cell) transform,
  ) {
    if (state.activeSheet == null) return;
    _pushUndo();

    var sheet = state.activeSheet!;

    if (state.selectedRange != null && !state.selectedRange!.isSingleCell) {
      // Apply to range
      for (final pos in state.selectedRange!.positions) {
        final cell = sheet.getCell(pos);
        sheet = sheet.setCell(pos, transform(cell));
      }
    } else if (state.selectedCell != null) {
      // Apply to single cell
      final cell = sheet.getCell(state.selectedCell!);
      sheet = sheet.setCell(state.selectedCell!, transform(cell));
    } else {
      return;
    }

    _emitWithUndo(emit, sheets: _replaceActiveSheet(sheet));
  }

  double? _resolveCellValue(String ref) {
    if (state.activeSheet == null) return null;
    try {
      final pos = CellPosition.fromReference(ref);
      final cell = state.activeSheet!.getCell(pos);
      return double.tryParse(cell.displayValue);
    } catch (_) {
      return null;
    }
  }

  String _resolveCellText(String ref) {
    if (state.activeSheet == null) return '';
    try {
      final pos = CellPosition.fromReference(ref);
      return state.activeSheet!.getCell(pos).displayValue;
    } catch (_) {
      return '';
    }
  }

  String _formatDisplayValue(String rawValue, NumberFormatType format) {
    final numVal = double.tryParse(rawValue);
    if (numVal == null) return rawValue;

    switch (format) {
      case NumberFormatType.general:
        return rawValue;
      case NumberFormatType.number:
        return numVal.toStringAsFixed(0);
      case NumberFormatType.decimal:
        return numVal.toStringAsFixed(2);
      case NumberFormatType.currency:
        return '\$${numVal.toStringAsFixed(2)}';
      case NumberFormatType.percentage:
        return '${(numVal * 100).toStringAsFixed(1)}%';
      case NumberFormatType.scientific:
        return numVal.toStringAsExponential(2);
      case NumberFormatType.accounting:
        if (numVal < 0) {
          return '(\$${(-numVal).toStringAsFixed(2)})';
        }
        return '\$${numVal.toStringAsFixed(2)}';
      default:
        return rawValue;
    }
  }

  // --- Event Handlers ---

  Future<void> _onLoad(
      LoadSpreadsheets event, Emitter<SpreadsheetState> emit) async {
    emit(state.copyWith(status: SpreadsheetStatus.loading));
    try {
      final list = await _dao.getAllSpreadsheets();
      emit(
          state.copyWith(status: SpreadsheetStatus.loaded, spreadsheets: list));
    } catch (e) {
      emit(state.copyWith(status: SpreadsheetStatus.error, errorMessage: '$e'));
    }
  }

  Future<void> _onSearch(
      SearchSpreadsheets event, Emitter<SpreadsheetState> emit) async {
    emit(state.copyWith(searchQuery: event.query));
    try {
      final list = event.query.isEmpty
          ? await _dao.getAllSpreadsheets()
          : await _dao.searchSpreadsheets(event.query);
      emit(
          state.copyWith(status: SpreadsheetStatus.loaded, spreadsheets: list));
    } catch (e) {
      emit(state.copyWith(status: SpreadsheetStatus.error, errorMessage: '$e'));
    }
  }

  Future<void> _onCreate(
      CreateSpreadsheet event, Emitter<SpreadsheetState> emit) async {
    final now = DateTime.now();
    const defaultSheet = SheetData(
      id: '1',
      name: 'Sheet1',
      rowCount: 50,
      colCount: 26,
    );

    final entity = SpreadsheetEntity(
      id: now.microsecondsSinceEpoch.toString(),
      title: event.title,
      content: jsonEncode([_sheetToJson(defaultSheet)]),
      sheetCount: 1,
      createdAt: now,
      modifiedAt: now,
    );

    try {
      await _dao.insertSpreadsheet(entity);
      _undoManager.clear();
      _undoManager.push([defaultSheet]);
      emit(state.copyWith(
        status: SpreadsheetStatus.editing,
        currentSpreadsheet: entity,
        sheets: [defaultSheet],
        activeSheetIndex: 0,
        selectedCell: const CellPosition(0, 0),
        hasUnsavedChanges: false,
        canUndo: false,
        canRedo: false,
      ));
    } catch (e) {
      emit(state.copyWith(status: SpreadsheetStatus.error, errorMessage: '$e'));
    }
  }

  Future<void> _onOpen(
      OpenSpreadsheet event, Emitter<SpreadsheetState> emit) async {
    emit(state.copyWith(status: SpreadsheetStatus.loading));
    try {
      final entity = await _dao.getSpreadsheet(event.id);
      if (entity == null) {
        emit(state.copyWith(
            status: SpreadsheetStatus.error, errorMessage: 'Not found'));
        return;
      }

      final sheetsJson = jsonDecode(entity.content) as List;
      final sheets = sheetsJson
          .map((s) => _sheetFromJson(s as Map<String, dynamic>))
          .toList();

      _undoManager.clear();
      _undoManager.push(List<SheetData>.from(sheets));

      emit(state.copyWith(
        status: SpreadsheetStatus.editing,
        currentSpreadsheet: entity,
        sheets: sheets,
        activeSheetIndex: 0,
        selectedCell: const CellPosition(0, 0),
        hasUnsavedChanges: false,
        canUndo: false,
        canRedo: false,
      ));
    } catch (e) {
      emit(state.copyWith(status: SpreadsheetStatus.error, errorMessage: '$e'));
    }
  }

  void _onUpdateCell(UpdateCell event, Emitter<SpreadsheetState> emit) {
    if (state.activeSheet == null) return;
    _pushUndo();

    var cellData = CellData(rawValue: event.value);

    // Evaluate formulas
    if (event.value.startsWith('=')) {
      final result = _formulaEngine.evaluate(event.value);
      cellData = CellData(
        rawValue: event.value,
        displayValue: result.displayValue,
        type: 'formula',
        hasError: result.isError,
        errorMessage: result.errorMessage,
      );
    } else {
      final numVal = double.tryParse(event.value);
      cellData = CellData(
        rawValue: event.value,
        displayValue: event.value,
        type: numVal != null ? 'number' : 'text',
        alignment: numVal != null ? 'right' : 'left',
      );
    }

    // Preserve existing formatting
    final existing = state.activeSheet!.getCell(event.position);
    if (!existing.isEmpty) {
      cellData = cellData.copyWith(
        isBold: existing.isBold,
        isItalic: existing.isItalic,
        isUnderline: existing.isUnderline,
        isStrikethrough: existing.isStrikethrough,
        fontFamily: existing.fontFamily,
        textColor: existing.textColor,
        backgroundColor: existing.backgroundColor,
        fontSize: existing.fontSize,
        numberFormat: existing.numberFormat,
        borders: existing.borders,
        comment: existing.comment,
        hyperlink: existing.hyperlink,
      );
    }

    // Apply number formatting
    if (cellData.numberFormat != NumberFormatType.general &&
        !cellData.hasError) {
      cellData = cellData.copyWith(
        displayValue:
            _formatDisplayValue(cellData.rawValue, cellData.numberFormat),
      );
    }

    final updatedSheet = state.activeSheet!.setCell(event.position, cellData);
    _emitWithUndo(emit, sheets: _replaceActiveSheet(updatedSheet));

    emit(state.copyWith(
      cellEditValue: event.value,
      formulaBarValue: event.value,
    ));
  }

  void _onSelectCell(SelectCell event, Emitter<SpreadsheetState> emit) {
    if (state.activeSheet == null) return;
    final cell = state.activeSheet!.getCell(event.position);
    emit(state.copyWith(
      selectedCell: event.position,
      selectedRange: CellRange(event.position, event.position),
      cellEditValue: cell.rawValue,
      formulaBarValue: cell.rawValue,
    ));
  }

  void _onSetCellRange(SetCellRange event, Emitter<SpreadsheetState> emit) {
    emit(state.copyWith(
      selectedRange: event.range,
      selectedCell: event.range.start,
    ));
  }

  void _onFormatCells(FormatCells event, Emitter<SpreadsheetState> emit) {
    switch (event.formatType) {
      case 'bold':
        _applyFormatToSelection(
            emit, (cell) => cell.copyWith(isBold: !cell.isBold));
      case 'italic':
        _applyFormatToSelection(
            emit, (cell) => cell.copyWith(isItalic: !cell.isItalic));
      case 'underline':
        _applyFormatToSelection(
            emit, (cell) => cell.copyWith(isUnderline: !cell.isUnderline));
      case 'strikethrough':
        _applyFormatToSelection(emit,
            (cell) => cell.copyWith(isStrikethrough: !cell.isStrikethrough));
      case 'alignLeft':
        _applyFormatToSelection(
            emit, (cell) => cell.copyWith(alignment: 'left'));
      case 'alignCenter':
        _applyFormatToSelection(
            emit, (cell) => cell.copyWith(alignment: 'center'));
      case 'alignRight':
        _applyFormatToSelection(
            emit, (cell) => cell.copyWith(alignment: 'right'));
      case 'wrapText':
        _applyFormatToSelection(
            emit, (cell) => cell.copyWith(wrapText: !cell.wrapText));
      default:
        return;
    }
  }

  void _onSetTextColor(SetTextColor event, Emitter<SpreadsheetState> emit) {
    _applyFormatToSelection(
        emit, (cell) => cell.copyWith(textColor: event.hexColor));
  }

  void _onSetBackgroundColor(
      SetBackgroundColor event, Emitter<SpreadsheetState> emit) {
    _applyFormatToSelection(
        emit, (cell) => cell.copyWith(backgroundColor: event.hexColor));
  }

  void _onSetFontFamily(SetFontFamily event, Emitter<SpreadsheetState> emit) {
    _applyFormatToSelection(
        emit, (cell) => cell.copyWith(fontFamily: event.fontFamily));
  }

  void _onSetFontSize(SetFontSize event, Emitter<SpreadsheetState> emit) {
    _applyFormatToSelection(
        emit, (cell) => cell.copyWith(fontSize: event.size));
  }

  void _onSetNumberFormat(
      SetNumberFormat event, Emitter<SpreadsheetState> emit) {
    _applyFormatToSelection(emit, (cell) {
      final newDisplay =
          _formatDisplayValue(cell.rawValue, event.format);
      return cell.copyWith(
        numberFormat: event.format,
        displayValue: newDisplay,
      );
    });
  }

  void _onSetBorders(SetBorders event, Emitter<SpreadsheetState> emit) {
    _applyFormatToSelection(
        emit, (cell) => cell.copyWith(borders: event.borders));
  }

  // --- Row/Column Operations ---

  void _onInsertRow(InsertRow event, Emitter<SpreadsheetState> emit) {
    if (state.activeSheet == null) return;
    _pushUndo();

    final sheet = state.activeSheet!;
    final newCells = <String, CellData>{};

    // Shift all cells below the insertion point down by 1
    for (final entry in sheet.cells.entries) {
      final parts = entry.key.split(',');
      final r = int.parse(parts[0]);
      final c = int.parse(parts[1]);
      if (r > event.afterRow) {
        newCells['${r + 1},$c'] = entry.value;
      } else {
        newCells[entry.key] = entry.value;
      }
    }

    final updatedSheet = sheet.copyWith(
      cells: newCells,
      rowCount: sheet.rowCount + 1,
    );
    _emitWithUndo(emit, sheets: _replaceActiveSheet(updatedSheet));
  }

  void _onDeleteRow(DeleteRow event, Emitter<SpreadsheetState> emit) {
    if (state.activeSheet == null) return;
    _pushUndo();

    final sheet = state.activeSheet!;
    final newCells = <String, CellData>{};

    for (final entry in sheet.cells.entries) {
      final parts = entry.key.split(',');
      final r = int.parse(parts[0]);
      final c = int.parse(parts[1]);
      if (r == event.row) continue; // Skip deleted row
      if (r > event.row) {
        newCells['${r - 1},$c'] = entry.value;
      } else {
        newCells[entry.key] = entry.value;
      }
    }

    final updatedSheet = sheet.copyWith(
      cells: newCells,
      rowCount: sheet.rowCount > 1 ? sheet.rowCount - 1 : 1,
    );
    _emitWithUndo(emit, sheets: _replaceActiveSheet(updatedSheet));
  }

  void _onInsertColumn(InsertColumn event, Emitter<SpreadsheetState> emit) {
    if (state.activeSheet == null) return;
    _pushUndo();

    final sheet = state.activeSheet!;
    final newCells = <String, CellData>{};

    for (final entry in sheet.cells.entries) {
      final parts = entry.key.split(',');
      final r = int.parse(parts[0]);
      final c = int.parse(parts[1]);
      if (c > event.afterCol) {
        newCells['$r,${c + 1}'] = entry.value;
      } else {
        newCells[entry.key] = entry.value;
      }
    }

    final updatedSheet = sheet.copyWith(
      cells: newCells,
      colCount: sheet.colCount + 1,
    );
    _emitWithUndo(emit, sheets: _replaceActiveSheet(updatedSheet));
  }

  void _onDeleteColumn(DeleteColumn event, Emitter<SpreadsheetState> emit) {
    if (state.activeSheet == null) return;
    _pushUndo();

    final sheet = state.activeSheet!;
    final newCells = <String, CellData>{};

    for (final entry in sheet.cells.entries) {
      final parts = entry.key.split(',');
      final r = int.parse(parts[0]);
      final c = int.parse(parts[1]);
      if (c == event.col) continue;
      if (c > event.col) {
        newCells['$r,${c - 1}'] = entry.value;
      } else {
        newCells[entry.key] = entry.value;
      }
    }

    final updatedSheet = sheet.copyWith(
      cells: newCells,
      colCount: sheet.colCount > 1 ? sheet.colCount - 1 : 1,
    );
    _emitWithUndo(emit, sheets: _replaceActiveSheet(updatedSheet));
  }

  void _onResizeRow(ResizeRow event, Emitter<SpreadsheetState> emit) {
    if (state.activeSheet == null) return;
    final newHeights = Map<int, double>.from(state.activeSheet!.rowHeights);
    newHeights[event.row] = event.height;
    final updatedSheet = state.activeSheet!.copyWith(rowHeights: newHeights);
    final newSheets = _replaceActiveSheet(updatedSheet);
    emit(state.copyWith(sheets: newSheets, hasUnsavedChanges: true));
    _scheduleAutoSave();
  }

  void _onResizeColumn(ResizeColumn event, Emitter<SpreadsheetState> emit) {
    if (state.activeSheet == null) return;
    final newWidths = Map<int, double>.from(state.activeSheet!.columnWidths);
    newWidths[event.col] = event.width;
    final updatedSheet = state.activeSheet!.copyWith(columnWidths: newWidths);
    final newSheets = _replaceActiveSheet(updatedSheet);
    emit(state.copyWith(sheets: newSheets, hasUnsavedChanges: true));
    _scheduleAutoSave();
  }

  void _onHideRows(HideRows event, Emitter<SpreadsheetState> emit) {
    if (state.activeSheet == null) return;
    _pushUndo();
    final newHidden = Set<int>.from(state.activeSheet!.hiddenRows)
      ..addAll(event.rows);
    final updatedSheet = state.activeSheet!.copyWith(hiddenRows: newHidden);
    _emitWithUndo(emit, sheets: _replaceActiveSheet(updatedSheet));
  }

  void _onUnhideRows(UnhideRows event, Emitter<SpreadsheetState> emit) {
    if (state.activeSheet == null) return;
    _pushUndo();
    final updatedSheet = state.activeSheet!.copyWith(hiddenRows: {});
    _emitWithUndo(emit, sheets: _replaceActiveSheet(updatedSheet));
  }

  void _onHideCols(HideCols event, Emitter<SpreadsheetState> emit) {
    if (state.activeSheet == null) return;
    _pushUndo();
    final newHidden = Set<int>.from(state.activeSheet!.hiddenCols)
      ..addAll(event.cols);
    final updatedSheet = state.activeSheet!.copyWith(hiddenCols: newHidden);
    _emitWithUndo(emit, sheets: _replaceActiveSheet(updatedSheet));
  }

  void _onUnhideCols(UnhideCols event, Emitter<SpreadsheetState> emit) {
    if (state.activeSheet == null) return;
    _pushUndo();
    final updatedSheet = state.activeSheet!.copyWith(hiddenCols: {});
    _emitWithUndo(emit, sheets: _replaceActiveSheet(updatedSheet));
  }

  // --- Clipboard ---

  void _onCopy(CopySelection event, Emitter<SpreadsheetState> emit) {
    if (state.activeSheet == null) return;
    final range = state.selectedRange ??
        (state.selectedCell != null
            ? CellRange(state.selectedCell!, state.selectedCell!)
            : null);
    if (range == null) return;

    _clipboardCells = {};
    final tl = range.topLeft;
    final br = range.bottomRight;

    for (final pos in range.positions) {
      final cell = state.activeSheet!.getCell(pos);
      if (!cell.isEmpty) {
        final relKey = '${pos.row - tl.row},${pos.col - tl.col}';
        _clipboardCells![relKey] = cell;
      }
    }

    // Also copy plain text to system clipboard
    final textLines = <String>[];
    for (var r = tl.row; r <= br.row; r++) {
      final rowCells = <String>[];
      for (var c = tl.col; c <= br.col; c++) {
        rowCells.add(state.activeSheet!.getCell(CellPosition(r, c)).displayValue);
      }
      textLines.add(rowCells.join('\t'));
    }
    ClipboardService.copy(textLines.join('\n'),
        type: ClipboardContentType.cells);

    emit(state.copyWith(
      clipboardRange: range,
      isClipboardCut: false,
    ));
  }

  void _onCut(CutSelection event, Emitter<SpreadsheetState> emit) {
    _onCopy(const CopySelection(), emit);
    emit(state.copyWith(isClipboardCut: true));
  }

  void _onPaste(PasteSelection event, Emitter<SpreadsheetState> emit) {
    if (state.activeSheet == null || state.selectedCell == null) return;
    if (_clipboardCells == null || _clipboardCells!.isEmpty) return;
    _pushUndo();

    var sheet = state.activeSheet!;
    final startRow = state.selectedCell!.row;
    final startCol = state.selectedCell!.col;

    for (final entry in _clipboardCells!.entries) {
      final parts = entry.key.split(',');
      final relR = int.parse(parts[0]);
      final relC = int.parse(parts[1]);
      final targetPos = CellPosition(startRow + relR, startCol + relC);
      if (targetPos.row < sheet.rowCount && targetPos.col < sheet.colCount) {
        sheet = sheet.setCell(targetPos, entry.value);
      }
    }

    // If cut, clear source cells
    if (state.isClipboardCut && state.clipboardRange != null) {
      for (final pos in state.clipboardRange!.positions) {
        sheet = sheet.setCell(pos, const CellData());
      }
      _clipboardCells = null;
    }

    _emitWithUndo(emit, sheets: _replaceActiveSheet(sheet));
    emit(state.copyWith(isClipboardCut: false));
  }

  void _onClearSelection(ClearSelection event, Emitter<SpreadsheetState> emit) {
    if (state.activeSheet == null) return;
    _pushUndo();

    var sheet = state.activeSheet!;
    final range = state.selectedRange ??
        (state.selectedCell != null
            ? CellRange(state.selectedCell!, state.selectedCell!)
            : null);
    if (range == null) return;

    for (final pos in range.positions) {
      sheet = sheet.setCell(pos, const CellData());
    }

    _emitWithUndo(emit, sheets: _replaceActiveSheet(sheet));
  }

  // --- Undo/Redo ---

  void _onUndo(UndoSpreadsheet event, Emitter<SpreadsheetState> emit) {
    final previous = _undoManager.undo();
    if (previous != null) {
      emit(state.copyWith(
        sheets: previous,
        hasUnsavedChanges: true,
        canUndo: _undoManager.canUndo,
        canRedo: _undoManager.canRedo,
      ));
      _scheduleAutoSave();
    }
  }

  void _onRedo(RedoSpreadsheet event, Emitter<SpreadsheetState> emit) {
    final next = _undoManager.redo();
    if (next != null) {
      emit(state.copyWith(
        sheets: next,
        hasUnsavedChanges: true,
        canUndo: _undoManager.canUndo,
        canRedo: _undoManager.canRedo,
      ));
      _scheduleAutoSave();
    }
  }

  // --- Find & Replace ---

  void _onFind(FindInSheet event, Emitter<SpreadsheetState> emit) {
    if (state.activeSheet == null || event.query.isEmpty) {
      emit(state.copyWith(
        findQuery: event.query,
        findMatches: const [],
        findMatchIndex: -1,
      ));
      return;
    }

    final matches = <CellPosition>[];
    final query = event.query.toLowerCase();

    for (final entry in state.activeSheet!.cells.entries) {
      if (entry.value.displayValue.toLowerCase().contains(query) ||
          entry.value.rawValue.toLowerCase().contains(query)) {
        final parts = entry.key.split(',');
        matches.add(CellPosition(int.parse(parts[0]), int.parse(parts[1])));
      }
    }

    emit(state.copyWith(
      findQuery: event.query,
      findMatches: matches,
      findMatchIndex: matches.isNotEmpty ? 0 : -1,
      selectedCell: matches.isNotEmpty ? matches.first : state.selectedCell,
    ));
  }

  void _onReplace(ReplaceInSheet event, Emitter<SpreadsheetState> emit) {
    if (state.activeSheet == null) return;
    _pushUndo();

    var sheet = state.activeSheet!;
    final query = event.query.toLowerCase();

    if (event.replaceAll) {
      // Replace all occurrences
      for (final entry in Map<String, CellData>.from(sheet.cells).entries) {
        if (entry.value.rawValue.toLowerCase().contains(query)) {
          final newValue = entry.value.rawValue.replaceAll(
            RegExp(RegExp.escape(event.query), caseSensitive: false),
            event.replacement,
          );
          final parts = entry.key.split(',');
          final pos = CellPosition(int.parse(parts[0]), int.parse(parts[1]));
          sheet = sheet.setCell(
            pos,
            entry.value.copyWith(
              rawValue: newValue,
              displayValue: newValue,
            ),
          );
        }
      }
    } else {
      // Replace current match
      if (state.findMatchIndex >= 0 &&
          state.findMatchIndex < state.findMatches.length) {
        final pos = state.findMatches[state.findMatchIndex];
        final cell = sheet.getCell(pos);
        final newValue = cell.rawValue.replaceFirst(
          RegExp(RegExp.escape(event.query), caseSensitive: false),
          event.replacement,
        );
        sheet = sheet.setCell(
          pos,
          cell.copyWith(rawValue: newValue, displayValue: newValue),
        );
      }
    }

    final newSheets = _replaceActiveSheet(sheet);
    _emitWithUndo(emit, sheets: newSheets);
    // Re-run find to update matches
    add(FindInSheet(event.query));
  }

  void _onClearFind(ClearFind event, Emitter<SpreadsheetState> emit) {
    emit(state.copyWith(
      findQuery: '',
      findMatches: const [],
      findMatchIndex: -1,
    ));
  }

  // --- Merge ---

  void _onMergeCells(MergeCells event, Emitter<SpreadsheetState> emit) {
    if (state.activeSheet == null) return;
    _pushUndo();

    var sheet = state.activeSheet!;
    final tl = event.range.topLeft;

    // Merge: keep top-left cell value, clear others
    final topLeftCell = sheet.getCell(tl);
    for (final pos in event.range.positions) {
      if (pos != tl) {
        sheet = sheet.setCell(pos, const CellData());
      }
    }

    // Store merge info
    final mergedCells = List<CellRange>.from(sheet.mergedCells)
      ..add(event.range);
    sheet = sheet.copyWith(mergedCells: mergedCells);

    // Ensure top-left cell has content
    if (topLeftCell.isEmpty) {
      sheet = sheet.setCell(tl, const CellData(rawValue: ' ', displayValue: ' '));
    }

    _emitWithUndo(emit, sheets: _replaceActiveSheet(sheet));
  }

  void _onUnmergeCells(UnmergeCells event, Emitter<SpreadsheetState> emit) {
    if (state.activeSheet == null) return;
    _pushUndo();

    final mergedCells = List<CellRange>.from(state.activeSheet!.mergedCells);
    mergedCells
        .removeWhere((range) => range.contains(event.position));
    final sheet = state.activeSheet!.copyWith(mergedCells: mergedCells);

    _emitWithUndo(emit, sheets: _replaceActiveSheet(sheet));
  }

  // --- Comments ---

  void _onAddComment(AddComment event, Emitter<SpreadsheetState> emit) {
    if (state.activeSheet == null) return;
    _pushUndo();

    final cell = state.activeSheet!.getCell(event.position);
    final comment = CellComment(
      text: event.text,
      timestamp: DateTime.now(),
    );
    final updated = cell.isEmpty
        ? CellData(
            rawValue: cell.rawValue.isEmpty ? ' ' : cell.rawValue,
            displayValue:
                cell.displayValue.isEmpty ? ' ' : cell.displayValue,
            comment: comment,
          )
        : cell.copyWith(comment: comment);

    final sheet = state.activeSheet!.setCell(event.position, updated);
    _emitWithUndo(emit, sheets: _replaceActiveSheet(sheet));
  }

  void _onRemoveComment(RemoveComment event, Emitter<SpreadsheetState> emit) {
    if (state.activeSheet == null) return;
    _pushUndo();

    final cell = state.activeSheet!.getCell(event.position);
    final updated = cell.clearComment();
    final sheet = state.activeSheet!.setCell(event.position, updated);
    _emitWithUndo(emit, sheets: _replaceActiveSheet(sheet));
  }

  // --- Hyperlinks ---

  void _onAddHyperlink(AddHyperlink event, Emitter<SpreadsheetState> emit) {
    if (state.activeSheet == null) return;
    _pushUndo();

    final cell = state.activeSheet!.getCell(event.position);
    final updated = cell.copyWith(hyperlink: event.url);
    final sheet = state.activeSheet!.setCell(event.position, updated);
    _emitWithUndo(emit, sheets: _replaceActiveSheet(sheet));
  }

  // --- Sheet Management ---

  void _onAddSheet(AddSheet event, Emitter<SpreadsheetState> emit) {
    _pushUndo();
    final newSheet = SheetData(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: 'Sheet${state.sheets.length + 1}',
      rowCount: 50,
      colCount: 26,
    );
    final newSheets = [...state.sheets, newSheet];
    _emitWithUndo(emit, sheets: newSheets);
    emit(state.copyWith(activeSheetIndex: newSheets.length - 1));
  }

  void _onSelectSheet(SelectSheet event, Emitter<SpreadsheetState> emit) {
    if (event.index >= 0 && event.index < state.sheets.length) {
      emit(state.copyWith(
        activeSheetIndex: event.index,
        selectedCell: const CellPosition(0, 0),
        selectedRange: const CellRange(CellPosition(0, 0), CellPosition(0, 0)),
      ));
    }
  }

  void _onRenameSheet(RenameSheet event, Emitter<SpreadsheetState> emit) {
    if (event.index >= 0 && event.index < state.sheets.length) {
      _pushUndo();
      final newSheets = List<SheetData>.from(state.sheets);
      newSheets[event.index] =
          newSheets[event.index].copyWith(name: event.name);
      _emitWithUndo(emit, sheets: newSheets);
    }
  }

  void _onDeleteSheet(DeleteSheet event, Emitter<SpreadsheetState> emit) {
    if (state.sheets.length <= 1) return;
    _pushUndo();
    final newSheets = List<SheetData>.from(state.sheets)..removeAt(event.index);
    final newIndex = state.activeSheetIndex >= newSheets.length
        ? newSheets.length - 1
        : state.activeSheetIndex;
    _emitWithUndo(emit, sheets: newSheets);
    emit(state.copyWith(activeSheetIndex: newIndex));
  }

  void _onDuplicateSheet(
      DuplicateSheet event, Emitter<SpreadsheetState> emit) {
    if (event.index >= 0 && event.index < state.sheets.length) {
      _pushUndo();
      final original = state.sheets[event.index];
      final duplicate = SheetData(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: '${original.name} (Copy)',
        cells: Map<String, CellData>.from(original.cells),
        rowCount: original.rowCount,
        colCount: original.colCount,
        frozenRows: original.frozenRows,
        frozenCols: original.frozenCols,
        columnWidths: Map<int, double>.from(original.columnWidths),
        rowHeights: Map<int, double>.from(original.rowHeights),
      );
      final newSheets = List<SheetData>.from(state.sheets)
        ..insert(event.index + 1, duplicate);
      _emitWithUndo(emit, sheets: newSheets);
      emit(state.copyWith(activeSheetIndex: event.index + 1));
    }
  }

  void _onReorderSheet(ReorderSheet event, Emitter<SpreadsheetState> emit) {
    _pushUndo();
    final newSheets = List<SheetData>.from(state.sheets);
    final sheet = newSheets.removeAt(event.from);
    newSheets.insert(event.to, sheet);
    _emitWithUndo(emit, sheets: newSheets);

    // Adjust active index
    var newIndex = state.activeSheetIndex;
    if (state.activeSheetIndex == event.from) {
      newIndex = event.to;
    } else if (event.from < state.activeSheetIndex &&
        event.to >= state.activeSheetIndex) {
      newIndex--;
    } else if (event.from > state.activeSheetIndex &&
        event.to <= state.activeSheetIndex) {
      newIndex++;
    }
    emit(state.copyWith(activeSheetIndex: newIndex));
  }

  // --- Save/Delete ---

  Future<void> _onSave(
      SaveSpreadsheet event, Emitter<SpreadsheetState> emit) async {
    if (state.currentSpreadsheet == null) return;
    emit(state.copyWith(status: SpreadsheetStatus.saving));
    try {
      final content = jsonEncode(state.sheets.map(_sheetToJson).toList());
      final updated = state.currentSpreadsheet!.copyWith(
        content: content,
        sheetCount: state.sheets.length,
        modifiedAt: DateTime.now(),
      );
      await _dao.updateSpreadsheet(updated);
      emit(state.copyWith(
        status: SpreadsheetStatus.saved,
        currentSpreadsheet: updated,
        hasUnsavedChanges: false,
      ));
      await Future.delayed(const Duration(milliseconds: 500));
      emit(state.copyWith(status: SpreadsheetStatus.editing));
    } catch (e) {
      emit(state.copyWith(status: SpreadsheetStatus.error, errorMessage: '$e'));
    }
  }

  Future<void> _onAutoSave(
      AutoSaveSpreadsheet event, Emitter<SpreadsheetState> emit) async {
    if (state.currentSpreadsheet == null || !state.hasUnsavedChanges) return;
    try {
      final content = jsonEncode(state.sheets.map(_sheetToJson).toList());
      final updated = state.currentSpreadsheet!.copyWith(
        content: content,
        sheetCount: state.sheets.length,
        modifiedAt: DateTime.now(),
      );
      await _dao.updateSpreadsheet(updated);
      emit(state.copyWith(
          currentSpreadsheet: updated, hasUnsavedChanges: false));
    } catch (_) {}
  }

  Future<void> _onDelete(
      DeleteSpreadsheetEntry event, Emitter<SpreadsheetState> emit) async {
    try {
      await _dao.deleteSpreadsheet(event.id);
      final updated =
          state.spreadsheets.where((s) => s.id != event.id).toList();
      emit(state.copyWith(spreadsheets: updated));
    } catch (e) {
      emit(state.copyWith(status: SpreadsheetStatus.error, errorMessage: '$e'));
    }
  }

  Future<void> _onToggleFavorite(
      ToggleSpreadsheetFavorite event, Emitter<SpreadsheetState> emit) async {
    try {
      await _dao.toggleFavorite(event.id);
      add(const LoadSpreadsheets());
    } catch (e) {
      emit(state.copyWith(status: SpreadsheetStatus.error, errorMessage: '$e'));
    }
  }

  Future<void> _onDuplicate(
      DuplicateSpreadsheetEntry event, Emitter<SpreadsheetState> emit) async {
    try {
      await _dao.duplicateSpreadsheet(event.id);
      add(const LoadSpreadsheets());
    } catch (e) {
      emit(state.copyWith(status: SpreadsheetStatus.error, errorMessage: '$e'));
    }
  }

  void _onSetFrozenPanes(
      SetFrozenPanes event, Emitter<SpreadsheetState> emit) {
    if (state.activeSheet == null) return;
    _pushUndo();
    final updatedSheet = state.activeSheet!.copyWith(
      frozenRows: event.rows,
      frozenCols: event.cols,
    );
    _emitWithUndo(emit, sheets: _replaceActiveSheet(updatedSheet));
  }

  void _onSortColumn(SortColumn event, Emitter<SpreadsheetState> emit) {
    if (state.activeSheet == null) return;
    _pushUndo();
    final sheet = state.activeSheet!;

    // Collect rows with data in this column
    final rowsWithData = <int, CellData>{};
    for (final entry in sheet.cells.entries) {
      final parts = entry.key.split(',');
      if (int.parse(parts[1]) == event.col) {
        rowsWithData[int.parse(parts[0])] = entry.value;
      }
    }

    if (rowsWithData.isEmpty) return;

    final sortedRows = rowsWithData.entries.toList()
      ..sort((a, b) {
        final aNum = double.tryParse(a.value.displayValue);
        final bNum = double.tryParse(b.value.displayValue);
        int cmp;
        if (aNum != null && bNum != null) {
          cmp = aNum.compareTo(bNum);
        } else {
          cmp = a.value.displayValue.compareTo(b.value.displayValue);
        }
        return event.ascending ? cmp : -cmp;
      });

    // Rebuild cells with sorted order
    final newCells = Map<String, CellData>.from(sheet.cells);
    final rowIndices = rowsWithData.keys.toList()..sort();

    for (var colIdx = 0; colIdx < sheet.colCount; colIdx++) {
      final colCells = <CellData>[];
      for (final rowIdx in rowIndices) {
        colCells.add(sheet.cells['$rowIdx,$colIdx'] ?? const CellData());
      }

      final sortedCells = <CellData>[];
      for (final entry in sortedRows) {
        final originalRow = entry.key;
        final idx = rowIndices.indexOf(originalRow);
        sortedCells.add(colCells[idx]);
      }

      for (var i = 0; i < rowIndices.length; i++) {
        final key = '${rowIndices[i]},$colIdx';
        if (sortedCells[i].isEmpty) {
          newCells.remove(key);
        } else {
          newCells[key] = sortedCells[i];
        }
      }
    }

    final updatedSheet = sheet.copyWith(cells: newCells);
    _emitWithUndo(emit, sheets: _replaceActiveSheet(updatedSheet));
  }

  void _scheduleAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(seconds: 5), () {
      add(const AutoSaveSpreadsheet());
    });
  }

  // --- Serialization helpers ---

  Map<String, dynamic> _sheetToJson(SheetData sheet) {
    final cellsMap = <String, Map<String, dynamic>>{};
    for (final entry in sheet.cells.entries) {
      cellsMap[entry.key] = entry.value.toMap();
    }
    return {
      'id': sheet.id,
      'name': sheet.name,
      'cells': cellsMap,
      'rowCount': sheet.rowCount,
      'colCount': sheet.colCount,
      'frozenRows': sheet.frozenRows,
      'frozenCols': sheet.frozenCols,
      if (sheet.hiddenRows.isNotEmpty)
        'hiddenRows': sheet.hiddenRows.toList(),
      if (sheet.hiddenCols.isNotEmpty)
        'hiddenCols': sheet.hiddenCols.toList(),
      if (sheet.mergedCells.isNotEmpty)
        'mergedCells': sheet.mergedCells
            .map((r) => {
                  'sr': r.start.row,
                  'sc': r.start.col,
                  'er': r.end.row,
                  'ec': r.end.col,
                })
            .toList(),
    };
  }

  SheetData _sheetFromJson(Map<String, dynamic> json) {
    final cellsRaw = json['cells'] as Map<String, dynamic>? ?? {};
    final cells = <String, CellData>{};
    for (final entry in cellsRaw.entries) {
      cells[entry.key] =
          CellData.fromMap(entry.value as Map<String, dynamic>);
    }

    final hiddenRows = <int>{};
    if (json['hiddenRows'] != null) {
      for (final r in json['hiddenRows'] as List) {
        hiddenRows.add(r as int);
      }
    }

    final hiddenCols = <int>{};
    if (json['hiddenCols'] != null) {
      for (final c in json['hiddenCols'] as List) {
        hiddenCols.add(c as int);
      }
    }

    final mergedCells = <CellRange>[];
    if (json['mergedCells'] != null) {
      for (final m in json['mergedCells'] as List) {
        final mc = m as Map<String, dynamic>;
        mergedCells.add(CellRange(
          CellPosition(mc['sr'] as int, mc['sc'] as int),
          CellPosition(mc['er'] as int, mc['ec'] as int),
        ));
      }
    }

    return SheetData(
      id: json['id'] as String,
      name: json['name'] as String,
      cells: cells,
      rowCount: (json['rowCount'] as int?) ?? 100,
      colCount: (json['colCount'] as int?) ?? 26,
      frozenRows: (json['frozenRows'] as int?) ?? 0,
      frozenCols: (json['frozenCols'] as int?) ?? 0,
      hiddenRows: hiddenRows,
      hiddenCols: hiddenCols,
      mergedCells: mergedCells,
    );
  }

  @override
  Future<void> close() {
    _autoSaveTimer?.cancel();
    return super.close();
  }
}
