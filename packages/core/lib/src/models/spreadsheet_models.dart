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

  /// Whether the cell text is underlined.
  final bool isUnderline;

  /// Whether the cell text has strikethrough.
  final bool isStrikethrough;

  /// Font family name.
  final String fontFamily;

  /// Text color as hex string (e.g., '#FF0000').
  final String? textColor;

  /// Background color as hex string.
  final String? backgroundColor;

  /// Text alignment: 'left', 'center', 'right'.
  final String alignment;

  /// Font size in points.
  final double fontSize;

  /// Whether text wraps in the cell.
  final bool wrapText;

  /// Number format type for display.
  final NumberFormatType numberFormat;

  /// Border configuration.
  final CellBorders? borders;

  /// Cell comment (note).
  final CellComment? comment;

  /// Hyperlink URL.
  final String? hyperlink;

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
    this.isUnderline = false,
    this.isStrikethrough = false,
    this.fontFamily = 'Inter',
    this.textColor,
    this.backgroundColor,
    this.alignment = 'left',
    this.fontSize = 12.0,
    this.wrapText = false,
    this.numberFormat = NumberFormatType.general,
    this.borders,
    this.comment,
    this.hyperlink,
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
    bool? isUnderline,
    bool? isStrikethrough,
    String? fontFamily,
    String? textColor,
    String? backgroundColor,
    String? alignment,
    double? fontSize,
    bool? wrapText,
    NumberFormatType? numberFormat,
    CellBorders? borders,
    CellComment? comment,
    String? hyperlink,
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
      isUnderline: isUnderline ?? this.isUnderline,
      isStrikethrough: isStrikethrough ?? this.isStrikethrough,
      fontFamily: fontFamily ?? this.fontFamily,
      textColor: textColor ?? this.textColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      alignment: alignment ?? this.alignment,
      fontSize: fontSize ?? this.fontSize,
      wrapText: wrapText ?? this.wrapText,
      numberFormat: numberFormat ?? this.numberFormat,
      borders: borders ?? this.borders,
      comment: comment ?? this.comment,
      hyperlink: hyperlink ?? this.hyperlink,
      hasError: hasError ?? this.hasError,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  /// Returns a copy with the comment cleared.
  CellData clearComment() {
    return CellData(
      rawValue: rawValue,
      displayValue: displayValue,
      type: type,
      format: format,
      isBold: isBold,
      isItalic: isItalic,
      isUnderline: isUnderline,
      isStrikethrough: isStrikethrough,
      fontFamily: fontFamily,
      textColor: textColor,
      backgroundColor: backgroundColor,
      alignment: alignment,
      fontSize: fontSize,
      wrapText: wrapText,
      numberFormat: numberFormat,
      borders: borders,
      comment: null,
      hyperlink: hyperlink,
      hasError: hasError,
      errorMessage: errorMessage,
    );
  }

  /// Returns a copy with the hyperlink cleared.
  CellData clearHyperlink() {
    return CellData(
      rawValue: rawValue,
      displayValue: displayValue,
      type: type,
      format: format,
      isBold: isBold,
      isItalic: isItalic,
      isUnderline: isUnderline,
      isStrikethrough: isStrikethrough,
      fontFamily: fontFamily,
      textColor: textColor,
      backgroundColor: backgroundColor,
      alignment: alignment,
      fontSize: fontSize,
      wrapText: wrapText,
      numberFormat: numberFormat,
      borders: borders,
      comment: comment,
      hyperlink: null,
      hasError: hasError,
      errorMessage: errorMessage,
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
      if (isUnderline) 'isUnderline': true,
      if (isStrikethrough) 'isStrikethrough': true,
      if (fontFamily != 'Inter') 'fontFamily': fontFamily,
      if (textColor != null) 'textColor': textColor,
      if (backgroundColor != null) 'backgroundColor': backgroundColor,
      if (alignment != 'left') 'alignment': alignment,
      if (fontSize != 12.0) 'fontSize': fontSize,
      if (wrapText) 'wrapText': true,
      if (numberFormat != NumberFormatType.general)
        'numberFormat': numberFormat.name,
      if (borders != null) 'borders': borders!.toMap(),
      if (comment != null) 'comment': comment!.toMap(),
      if (hyperlink != null) 'hyperlink': hyperlink,
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
      isUnderline: (map['isUnderline'] as bool?) ?? false,
      isStrikethrough: (map['isStrikethrough'] as bool?) ?? false,
      fontFamily: (map['fontFamily'] as String?) ?? 'Inter',
      textColor: map['textColor'] as String?,
      backgroundColor: map['backgroundColor'] as String?,
      alignment: (map['alignment'] as String?) ?? 'left',
      fontSize: (map['fontSize'] as num?)?.toDouble() ?? 12.0,
      wrapText: (map['wrapText'] as bool?) ?? false,
      numberFormat: _parseNumberFormat(map['numberFormat'] as String?),
      borders: map['borders'] != null
          ? CellBorders.fromMap(map['borders'] as Map<String, dynamic>)
          : null,
      comment: map['comment'] != null
          ? CellComment.fromMap(map['comment'] as Map<String, dynamic>)
          : null,
      hyperlink: map['hyperlink'] as String?,
    );
  }

  static NumberFormatType _parseNumberFormat(String? value) {
    if (value == null) return NumberFormatType.general;
    return NumberFormatType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => NumberFormatType.general,
    );
  }

  @override
  List<Object?> get props => [
        rawValue,
        displayValue,
        type,
        isBold,
        isItalic,
        isUnderline,
        isStrikethrough,
        fontFamily,
        textColor,
        backgroundColor,
        alignment,
        fontSize,
        wrapText,
        numberFormat,
        borders,
        comment,
        hyperlink,
      ];
}

/// Number format types for cell display.
enum NumberFormatType {
  /// General format (no formatting).
  general,

  /// Integer number (1,234).
  number,

  /// Decimal number (1,234.56).
  decimal,

  /// Currency ($1,234.56).
  currency,

  /// Percentage (12.34%).
  percentage,

  /// Date (2024-01-15).
  date,

  /// Time (14:30:00).
  time,

  /// DateTime (2024-01-15 14:30).
  dateTime,

  /// Scientific notation (1.23E+03).
  scientific,

  /// Accounting format.
  accounting,
}

/// Cell border configuration.
class CellBorders extends Equatable {
  final String? top;
  final String? bottom;
  final String? left;
  final String? right;

  const CellBorders({this.top, this.bottom, this.left, this.right});

  bool get hasAny =>
      top != null || bottom != null || left != null || right != null;

  Map<String, dynamic> toMap() => {
        if (top != null) 'top': top,
        if (bottom != null) 'bottom': bottom,
        if (left != null) 'left': left,
        if (right != null) 'right': right,
      };

  factory CellBorders.fromMap(Map<String, dynamic> map) => CellBorders(
        top: map['top'] as String?,
        bottom: map['bottom'] as String?,
        left: map['left'] as String?,
        right: map['right'] as String?,
      );

  factory CellBorders.all(String color) => CellBorders(
        top: color,
        bottom: color,
        left: color,
        right: color,
      );

  @override
  List<Object?> get props => [top, bottom, left, right];
}

/// Cell comment/note model.
class CellComment extends Equatable {
  final String text;
  final String author;
  final DateTime timestamp;

  const CellComment({
    required this.text,
    this.author = 'User',
    required this.timestamp,
  });

  Map<String, dynamic> toMap() => {
        'text': text,
        'author': author,
        'timestamp': timestamp.toIso8601String(),
      };

  factory CellComment.fromMap(Map<String, dynamic> map) => CellComment(
        text: map['text'] as String,
        author: (map['author'] as String?) ?? 'User',
        timestamp: DateTime.parse(map['timestamp'] as String),
      );

  @override
  List<Object?> get props => [text, author, timestamp];
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

  /// Normalized start (top-left).
  CellPosition get topLeft => CellPosition(
        start.row < end.row ? start.row : end.row,
        start.col < end.col ? start.col : end.col,
      );

  /// Normalized end (bottom-right).
  CellPosition get bottomRight => CellPosition(
        start.row > end.row ? start.row : end.row,
        start.col > end.col ? start.col : end.col,
      );

  /// Number of rows in this range.
  int get rowCount => (end.row - start.row).abs() + 1;

  /// Number of columns in this range.
  int get colCount => (end.col - start.col).abs() + 1;

  /// Total cell count.
  int get cellCount => rowCount * colCount;

  /// Whether this is a single-cell range.
  bool get isSingleCell => start == end;

  /// Whether [position] is within this range.
  bool contains(CellPosition position) {
    final tl = topLeft;
    final br = bottomRight;
    return position.row >= tl.row &&
        position.row <= br.row &&
        position.col >= tl.col &&
        position.col <= br.col;
  }

  /// Iterates over all positions in this range.
  Iterable<CellPosition> get positions sync* {
    final tl = topLeft;
    final br = bottomRight;
    for (var r = tl.row; r <= br.row; r++) {
      for (var c = tl.col; c <= br.col; c++) {
        yield CellPosition(r, c);
      }
    }
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

  /// Set of hidden row indices.
  final Set<int> hiddenRows;

  /// Set of hidden column indices.
  final Set<int> hiddenCols;

  /// Merged cell ranges (stored as 'startRow,startCol:endRow,endCol' keys).
  final List<CellRange> mergedCells;

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
    this.hiddenRows = const {},
    this.hiddenCols = const {},
    this.mergedCells = const [],
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
      hiddenRows: hiddenRows,
      hiddenCols: hiddenCols,
      mergedCells: mergedCells,
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
    Set<int>? hiddenRows,
    Set<int>? hiddenCols,
    List<CellRange>? mergedCells,
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
      hiddenRows: hiddenRows ?? this.hiddenRows,
      hiddenCols: hiddenCols ?? this.hiddenCols,
      mergedCells: mergedCells ?? this.mergedCells,
    );
  }

  @override
  List<Object?> get props =>
      [id, name, cells, rowCount, colCount, frozenRows, frozenCols];
}

/// Conditional formatting rule.
class ConditionalFormat extends Equatable {
  /// The cell range this rule applies to.
  final CellRange range;

  /// Rule type: 'greaterThan', 'lessThan', 'equalTo', 'between',
  /// 'containsText', 'notContainsText', 'isEmpty', 'isNotEmpty'.
  final String ruleType;

  /// Primary value for comparison.
  final String value;

  /// Secondary value (for 'between' rule).
  final String? value2;

  /// Background color to apply when rule matches.
  final String? backgroundColor;

  /// Text color to apply when rule matches.
  final String? textColor;

  /// Whether to bold text when rule matches.
  final bool bold;

  const ConditionalFormat({
    required this.range,
    required this.ruleType,
    required this.value,
    this.value2,
    this.backgroundColor,
    this.textColor,
    this.bold = false,
  });

  Map<String, dynamic> toMap() => {
        'range': {
          'startRow': range.start.row,
          'startCol': range.start.col,
          'endRow': range.end.row,
          'endCol': range.end.col,
        },
        'ruleType': ruleType,
        'value': value,
        if (value2 != null) 'value2': value2,
        if (backgroundColor != null) 'backgroundColor': backgroundColor,
        if (textColor != null) 'textColor': textColor,
        if (bold) 'bold': true,
      };

  factory ConditionalFormat.fromMap(Map<String, dynamic> map) {
    final rangeMap = map['range'] as Map<String, dynamic>;
    return ConditionalFormat(
      range: CellRange(
        CellPosition(rangeMap['startRow'] as int, rangeMap['startCol'] as int),
        CellPosition(rangeMap['endRow'] as int, rangeMap['endCol'] as int),
      ),
      ruleType: map['ruleType'] as String,
      value: map['value'] as String,
      value2: map['value2'] as String?,
      backgroundColor: map['backgroundColor'] as String?,
      textColor: map['textColor'] as String?,
      bold: (map['bold'] as bool?) ?? false,
    );
  }

  @override
  List<Object?> get props =>
      [range, ruleType, value, value2, backgroundColor, textColor, bold];
}
