import 'package:equatable/equatable.dart';

/// Represents a single cell in a spreadsheet.
class CellData extends Equatable {
  /// The raw value entered by the user (text, number, or formula).
  final String rawValue;

  /// The computed/display value after formula evaluation.
  final String displayValue;

  /// Cell data type: 'text', 'number', 'date', 'formula', 'boolean'.
  final String type;

  /// Cell format string (e.g., '#,##0.00', 'yyyy-MM-dd').
  final String? format;

  /// Whether the cell text is bold.
  final bool isBold;

  /// Whether the cell text is italic.
  final bool isItalic;

  /// Text color as hex string (e.g., '#FF0000').
  final String? textColor;

  /// Background color as hex string.
  final String? backgroundColor;

  /// Text alignment: 'left', 'center', 'right'.
  final String alignment;

  /// Font size in points.
  final double fontSize;

  /// Whether this cell has a formula error.
  final bool hasError;

  /// Error message if [hasError] is true.
  final String? errorMessage;

  /// Creates a [CellData].
  const CellData({
    this.rawValue = '',
    this.displayValue = '',
    this.type = 'text',
    this.format,
    this.isBold = false,
    this.isItalic = false,
    this.textColor,
    this.backgroundColor,
    this.alignment = 'left',
    this.fontSize = 12.0,
    this.hasError = false,
    this.errorMessage,
  });

  /// Whether this cell is empty.
  bool get isEmpty => rawValue.isEmpty;

  /// Whether this cell contains a formula.
  bool get isFormula => rawValue.startsWith('=');

  /// Creates a copy with optional overrides.
  CellData copyWith({
    String? rawValue,
    String? displayValue,
    String? type,
    String? format,
    bool? isBold,
    bool? isItalic,
    String? textColor,
    String? backgroundColor,
    String? alignment,
    double? fontSize,
    bool? hasError,
    String? errorMessage,
  }) {
    return CellData(
      rawValue: rawValue ?? this.rawValue,
      displayValue: displayValue ?? this.displayValue,
      type: type ?? this.type,
      format: format ?? this.format,
      isBold: isBold ?? this.isBold,
      isItalic: isItalic ?? this.isItalic,
      textColor: textColor ?? this.textColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      alignment: alignment ?? this.alignment,
      fontSize: fontSize ?? this.fontSize,
      hasError: hasError ?? this.hasError,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  /// Converts to a JSON-compatible map.
  Map<String, dynamic> toMap() {
    return {
      'rawValue': rawValue,
      'displayValue': displayValue,
      'type': type,
      if (format != null) 'format': format,
      if (isBold) 'isBold': true,
      if (isItalic) 'isItalic': true,
      if (textColor != null) 'textColor': textColor,
      if (backgroundColor != null) 'backgroundColor': backgroundColor,
      if (alignment != 'left') 'alignment': alignment,
      if (fontSize != 12.0) 'fontSize': fontSize,
    };
  }

  /// Creates from a JSON-compatible map.
  factory CellData.fromMap(Map<String, dynamic> map) {
    return CellData(
      rawValue: (map['rawValue'] as String?) ?? '',
      displayValue: (map['displayValue'] as String?) ?? '',
      type: (map['type'] as String?) ?? 'text',
      format: map['format'] as String?,
      isBold: (map['isBold'] as bool?) ?? false,
      isItalic: (map['isItalic'] as bool?) ?? false,
      textColor: map['textColor'] as String?,
      backgroundColor: map['backgroundColor'] as String?,
      alignment: (map['alignment'] as String?) ?? 'left',
      fontSize: (map['fontSize'] as num?)?.toDouble() ?? 12.0,
    );
  }

  @override
  List<Object?> get props => [
        rawValue,
        displayValue,
        type,
        isBold,
        isItalic,
        textColor,
        backgroundColor,
        alignment,
        fontSize
      ];
}

/// Represents a cell position in the spreadsheet grid.
class CellPosition extends Equatable {
  /// Zero-based row index.
  final int row;

  /// Zero-based column index.
  final int col;

  const CellPosition(this.row, this.col);

  /// Returns the cell reference string (e.g., 'A1', 'B3').
  String get reference {
    final colLetter = columnToLetter(col);
    return '$colLetter${row + 1}';
  }

  /// Converts a zero-based column index to letter(s) (A, B, ..., Z, AA, AB...).
  static String columnToLetter(int col) {
    var result = '';
    var c = col;
    while (c >= 0) {
      result = String.fromCharCode(65 + (c % 26)) + result;
      c = (c ~/ 26) - 1;
    }
    return result;
  }

  /// Parses a cell reference string (e.g., 'A1') into a [CellPosition].
  factory CellPosition.fromReference(String ref) {
    final match = RegExp(r'^([A-Z]+)(\d+)$').firstMatch(ref.toUpperCase());
    if (match == null) throw FormatException('Invalid cell reference: $ref');

    final colStr = match.group(1)!;
    final rowStr = match.group(2)!;

    var col = 0;
    for (var i = 0; i < colStr.length; i++) {
      col = col * 26 + (colStr.codeUnitAt(i) - 64);
    }
    col -= 1; // Convert to zero-based

    return CellPosition(int.parse(rowStr) - 1, col);
  }

  @override
  List<Object?> get props => [row, col];
}

/// Represents a range of cells (e.g., A1:C3).
class CellRange extends Equatable {
  final CellPosition start;
  final CellPosition end;

  const CellRange(this.start, this.end);

  /// Number of rows in this range.
  int get rowCount => (end.row - start.row).abs() + 1;

  /// Number of columns in this range.
  int get colCount => (end.col - start.col).abs() + 1;

  /// Whether [position] is within this range.
  bool contains(CellPosition position) {
    return position.row >= start.row &&
        position.row <= end.row &&
        position.col >= start.col &&
        position.col <= end.col;
  }

  @override
  List<Object?> get props => [start, end];
}

/// Represents a single sheet within a spreadsheet workbook.
class SheetData extends Equatable {
  /// Unique sheet identifier.
  final String id;

  /// Sheet display name (e.g., 'Sheet1').
  final String name;

  /// Cell data indexed by 'row,col' string key.
  final Map<String, CellData> cells;

  /// Number of rows (expands as needed).
  final int rowCount;

  /// Number of columns (expands as needed).
  final int colCount;

  /// Frozen row count (rows above this are fixed).
  final int frozenRows;

  /// Frozen column count (columns left of this are fixed).
  final int frozenCols;

  /// Custom column widths by column index.
  final Map<int, double> columnWidths;

  /// Custom row heights by row index.
  final Map<int, double> rowHeights;

  const SheetData({
    required this.id,
    required this.name,
    this.cells = const {},
    this.rowCount = 100,
    this.colCount = 26,
    this.frozenRows = 0,
    this.frozenCols = 0,
    this.columnWidths = const {},
    this.rowHeights = const {},
  });

  /// Gets cell data at [position], returning empty cell if not set.
  CellData getCell(CellPosition position) {
    return cells['${position.row},${position.col}'] ?? const CellData();
  }

  /// Returns a copy with the cell at [position] updated.
  SheetData setCell(CellPosition position, CellData cell) {
    final newCells = Map<String, CellData>.from(cells);
    if (cell.isEmpty) {
      newCells.remove('${position.row},${position.col}');
    } else {
      newCells['${position.row},${position.col}'] = cell;
    }
    return SheetData(
      id: id,
      name: name,
      cells: newCells,
      rowCount: rowCount,
      colCount: colCount,
      frozenRows: frozenRows,
      frozenCols: frozenCols,
      columnWidths: columnWidths,
      rowHeights: rowHeights,
    );
  }

  SheetData copyWith({
    String? name,
    Map<String, CellData>? cells,
    int? rowCount,
    int? colCount,
    int? frozenRows,
    int? frozenCols,
    Map<int, double>? columnWidths,
    Map<int, double>? rowHeights,
  }) {
    return SheetData(
      id: id,
      name: name ?? this.name,
      cells: cells ?? this.cells,
      rowCount: rowCount ?? this.rowCount,
      colCount: colCount ?? this.colCount,
      frozenRows: frozenRows ?? this.frozenRows,
      frozenCols: frozenCols ?? this.frozenCols,
      columnWidths: columnWidths ?? this.columnWidths,
      rowHeights: rowHeights ?? this.rowHeights,
    );
  }

  @override
  List<Object?> get props =>
      [id, name, cells, rowCount, colCount, frozenRows, frozenCols];
}
