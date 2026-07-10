import 'dart:async';
import 'dart:convert';

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

class FormatCells extends SpreadsheetEvent {
  final String formatType; // 'bold', 'italic', 'alignLeft', etc.
  const FormatCells(this.formatType);
  @override
  List<Object?> get props => [formatType];
}

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

enum SpreadsheetStatus { initial, loading, loaded, editing, saving, saved, error }

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
    );
  }

  @override
  List<Object?> get props => [status, spreadsheets, currentSpreadsheet,
    sheets, activeSheetIndex, selectedCell, cellEditValue,
    hasUnsavedChanges, searchQuery, errorMessage];
}

// --- BLoC ---

class SpreadsheetBloc extends Bloc<SpreadsheetEvent, SpreadsheetState> {
  final SpreadsheetDao _dao;
  late final FormulaEngine _formulaEngine;
  Timer? _autoSaveTimer;

  SpreadsheetBloc({required SpreadsheetDao spreadsheetDao})
      : _dao = spreadsheetDao,
        super(const SpreadsheetState()) {
    _formulaEngine = FormulaEngine(
      cellResolver: _resolveCellValue,
      textResolver: _resolveCellText,
    );

    on<LoadSpreadsheets>(_onLoad);
    on<SearchSpreadsheets>(_onSearch);
    on<CreateSpreadsheet>(_onCreate);
    on<OpenSpreadsheet>(_onOpen);
    on<UpdateCell>(_onUpdateCell);
    on<SelectCell>(_onSelectCell);
    on<FormatCells>(_onFormatCells);
    on<AddSheet>(_onAddSheet);
    on<SelectSheet>(_onSelectSheet);
    on<RenameSheet>(_onRenameSheet);
    on<DeleteSheet>(_onDeleteSheet);
    on<SaveSpreadsheet>(_onSave);
    on<AutoSaveSpreadsheet>(_onAutoSave);
    on<DeleteSpreadsheetEntry>(_onDelete);
    on<ToggleSpreadsheetFavorite>(_onToggleFavorite);
    on<DuplicateSpreadsheetEntry>(_onDuplicate);
    on<SetFrozenPanes>(_onSetFrozenPanes);
    on<SortColumn>(_onSortColumn);
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

  Future<void> _onLoad(LoadSpreadsheets event, Emitter<SpreadsheetState> emit) async {
    emit(state.copyWith(status: SpreadsheetStatus.loading));
    try {
      final list = await _dao.getAllSpreadsheets();
      emit(state.copyWith(status: SpreadsheetStatus.loaded, spreadsheets: list));
    } catch (e) {
      emit(state.copyWith(status: SpreadsheetStatus.error, errorMessage: '$e'));
    }
  }

  Future<void> _onSearch(SearchSpreadsheets event, Emitter<SpreadsheetState> emit) async {
    emit(state.copyWith(searchQuery: event.query));
    try {
      final list = event.query.isEmpty
          ? await _dao.getAllSpreadsheets()
          : await _dao.searchSpreadsheets(event.query);
      emit(state.copyWith(status: SpreadsheetStatus.loaded, spreadsheets: list));
    } catch (e) {
      emit(state.copyWith(status: SpreadsheetStatus.error, errorMessage: '$e'));
    }
  }

  Future<void> _onCreate(CreateSpreadsheet event, Emitter<SpreadsheetState> emit) async {
    final now = DateTime.now();
    final defaultSheet = SheetData(
      id: '1',
      name: 'Sheet1',
      rowCount: 100,
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
      emit(state.copyWith(
        status: SpreadsheetStatus.editing,
        currentSpreadsheet: entity,
        sheets: [defaultSheet],
        activeSheetIndex: 0,
        selectedCell: const CellPosition(0, 0),
        hasUnsavedChanges: false,
      ));
    } catch (e) {
      emit(state.copyWith(status: SpreadsheetStatus.error, errorMessage: '$e'));
    }
  }

  Future<void> _onOpen(OpenSpreadsheet event, Emitter<SpreadsheetState> emit) async {
    emit(state.copyWith(status: SpreadsheetStatus.loading));
    try {
      final entity = await _dao.getSpreadsheet(event.id);
      if (entity == null) {
        emit(state.copyWith(status: SpreadsheetStatus.error, errorMessage: 'Not found'));
        return;
      }

      final sheetsJson = jsonDecode(entity.content) as List;
      final sheets = sheetsJson.map((s) => _sheetFromJson(s as Map<String, dynamic>)).toList();

      emit(state.copyWith(
        status: SpreadsheetStatus.editing,
        currentSpreadsheet: entity,
        sheets: sheets,
        activeSheetIndex: 0,
        selectedCell: const CellPosition(0, 0),
        hasUnsavedChanges: false,
      ));
    } catch (e) {
      emit(state.copyWith(status: SpreadsheetStatus.error, errorMessage: '$e'));
    }
  }

  void _onUpdateCell(UpdateCell event, Emitter<SpreadsheetState> emit) {
    if (state.activeSheet == null) return;

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
        textColor: existing.textColor,
        backgroundColor: existing.backgroundColor,
        fontSize: existing.fontSize,
      );
    }

    final updatedSheet = state.activeSheet!.setCell(event.position, cellData);
    final newSheets = List<SheetData>.from(state.sheets);
    newSheets[state.activeSheetIndex] = updatedSheet;

    emit(state.copyWith(
      sheets: newSheets,
      hasUnsavedChanges: true,
      cellEditValue: event.value,
      formulaBarValue: event.value,
    ));
    _scheduleAutoSave();
  }

  void _onSelectCell(SelectCell event, Emitter<SpreadsheetState> emit) {
    if (state.activeSheet == null) return;
    final cell = state.activeSheet!.getCell(event.position);
    emit(state.copyWith(
      selectedCell: event.position,
      cellEditValue: cell.rawValue,
      formulaBarValue: cell.rawValue,
    ));
  }

  void _onFormatCells(FormatCells event, Emitter<SpreadsheetState> emit) {
    if (state.activeSheet == null || state.selectedCell == null) return;

    final cell = state.activeSheet!.getCell(state.selectedCell!);
    CellData updated;

    switch (event.formatType) {
      case 'bold':
        updated = cell.copyWith(isBold: !cell.isBold);
      case 'italic':
        updated = cell.copyWith(isItalic: !cell.isItalic);
      case 'alignLeft':
        updated = cell.copyWith(alignment: 'left');
      case 'alignCenter':
        updated = cell.copyWith(alignment: 'center');
      case 'alignRight':
        updated = cell.copyWith(alignment: 'right');
      default:
        return;
    }

    final updatedSheet = state.activeSheet!.setCell(state.selectedCell!, updated);
    final newSheets = List<SheetData>.from(state.sheets);
    newSheets[state.activeSheetIndex] = updatedSheet;

    emit(state.copyWith(sheets: newSheets, hasUnsavedChanges: true));
    _scheduleAutoSave();
  }

  void _onAddSheet(AddSheet event, Emitter<SpreadsheetState> emit) {
    final newSheet = SheetData(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: 'Sheet${state.sheets.length + 1}',
      rowCount: 100,
      colCount: 26,
    );
    final newSheets = [...state.sheets, newSheet];
    emit(state.copyWith(
      sheets: newSheets,
      activeSheetIndex: newSheets.length - 1,
      hasUnsavedChanges: true,
    ));
    _scheduleAutoSave();
  }

  void _onSelectSheet(SelectSheet event, Emitter<SpreadsheetState> emit) {
    if (event.index >= 0 && event.index < state.sheets.length) {
      emit(state.copyWith(
        activeSheetIndex: event.index,
        selectedCell: const CellPosition(0, 0),
      ));
    }
  }

  void _onRenameSheet(RenameSheet event, Emitter<SpreadsheetState> emit) {
    if (event.index >= 0 && event.index < state.sheets.length) {
      final newSheets = List<SheetData>.from(state.sheets);
      newSheets[event.index] = newSheets[event.index].copyWith(name: event.name);
      emit(state.copyWith(sheets: newSheets, hasUnsavedChanges: true));
      _scheduleAutoSave();
    }
  }

  void _onDeleteSheet(DeleteSheet event, Emitter<SpreadsheetState> emit) {
    if (state.sheets.length <= 1) return; // Must keep at least one sheet
    final newSheets = List<SheetData>.from(state.sheets)..removeAt(event.index);
    final newIndex = state.activeSheetIndex >= newSheets.length
        ? newSheets.length - 1
        : state.activeSheetIndex;
    emit(state.copyWith(
      sheets: newSheets,
      activeSheetIndex: newIndex,
      hasUnsavedChanges: true,
    ));
    _scheduleAutoSave();
  }

  Future<void> _onSave(SaveSpreadsheet event, Emitter<SpreadsheetState> emit) async {
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

  Future<void> _onAutoSave(AutoSaveSpreadsheet event, Emitter<SpreadsheetState> emit) async {
    if (state.currentSpreadsheet == null || !state.hasUnsavedChanges) return;
    try {
      final content = jsonEncode(state.sheets.map(_sheetToJson).toList());
      final updated = state.currentSpreadsheet!.copyWith(
        content: content,
        sheetCount: state.sheets.length,
        modifiedAt: DateTime.now(),
      );
      await _dao.updateSpreadsheet(updated);
      emit(state.copyWith(currentSpreadsheet: updated, hasUnsavedChanges: false));
    } catch (_) {}
  }

  Future<void> _onDelete(DeleteSpreadsheetEntry event, Emitter<SpreadsheetState> emit) async {
    try {
      await _dao.deleteSpreadsheet(event.id);
      final updated = state.spreadsheets.where((s) => s.id != event.id).toList();
      emit(state.copyWith(spreadsheets: updated));
    } catch (e) {
      emit(state.copyWith(status: SpreadsheetStatus.error, errorMessage: '$e'));
    }
  }

  Future<void> _onToggleFavorite(ToggleSpreadsheetFavorite event, Emitter<SpreadsheetState> emit) async {
    try {
      await _dao.toggleFavorite(event.id);
      add(const LoadSpreadsheets());
    } catch (e) {
      emit(state.copyWith(status: SpreadsheetStatus.error, errorMessage: '$e'));
    }
  }

  Future<void> _onDuplicate(DuplicateSpreadsheetEntry event, Emitter<SpreadsheetState> emit) async {
    try {
      await _dao.duplicateSpreadsheet(event.id);
      add(const LoadSpreadsheets());
    } catch (e) {
      emit(state.copyWith(status: SpreadsheetStatus.error, errorMessage: '$e'));
    }
  }

  void _onSetFrozenPanes(SetFrozenPanes event, Emitter<SpreadsheetState> emit) {
    if (state.activeSheet == null) return;
    final updatedSheet = state.activeSheet!.copyWith(
      frozenRows: event.rows,
      frozenCols: event.cols,
    );
    final newSheets = List<SheetData>.from(state.sheets);
    newSheets[state.activeSheetIndex] = updatedSheet;
    emit(state.copyWith(sheets: newSheets, hasUnsavedChanges: true));
    _scheduleAutoSave();
  }

  void _onSortColumn(SortColumn event, Emitter<SpreadsheetState> emit) {
    if (state.activeSheet == null) return;
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

    // For each column, rearrange by the sorted order
    for (var colIdx = 0; colIdx < sheet.colCount; colIdx++) {
      final colCells = <CellData>[];
      for (final rowIdx in rowIndices) {
        colCells.add(sheet.cells['$rowIdx,$colIdx'] ?? const CellData());
      }

      // Reorder based on sort
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
    final newSheets = List<SheetData>.from(state.sheets);
    newSheets[state.activeSheetIndex] = updatedSheet;
    emit(state.copyWith(sheets: newSheets, hasUnsavedChanges: true));
    _scheduleAutoSave();
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
    };
  }

  SheetData _sheetFromJson(Map<String, dynamic> json) {
    final cellsRaw = json['cells'] as Map<String, dynamic>? ?? {};
    final cells = <String, CellData>{};
    for (final entry in cellsRaw.entries) {
      cells[entry.key] = CellData.fromMap(entry.value as Map<String, dynamic>);
    }
    return SheetData(
      id: json['id'] as String,
      name: json['name'] as String,
      cells: cells,
      rowCount: (json['rowCount'] as int?) ?? 100,
      colCount: (json['colCount'] as int?) ?? 26,
      frozenRows: (json['frozenRows'] as int?) ?? 0,
      frozenCols: (json['frozenCols'] as int?) ?? 0,
    );
  }

  @override
  Future<void> close() {
    _autoSaveTimer?.cancel();
    return super.close();
  }
}
