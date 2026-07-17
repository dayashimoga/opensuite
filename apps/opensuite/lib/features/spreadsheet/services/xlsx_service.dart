import 'dart:typed_data';

import 'package:excel/excel.dart' as xl;
import 'package:fileutility_core/fileutility_core.dart';

/// Service for importing and exporting XLSX (Excel) files.
///
/// Uses the `excel` Dart package for reading/writing .xlsx files.
/// Supports cell values, basic formatting (bold, italic, font color,
/// background color, font size, number format), merged cells,
/// and multiple sheets.
class XlsxService {
  XlsxService._();

  /// Export spreadsheet sheets to XLSX bytes.
  static Uint8List exportToXlsx({
    required List<SheetData> sheets,
    required String title,
  }) {
    final excel = xl.Excel.createExcel();

    // Remove default "Sheet1" if we're adding our own sheets
    final defaultSheetName = excel.getDefaultSheet();

    for (int i = 0; i < sheets.length; i++) {
      final sheetData = sheets[i];
      final sheetName = sheetData.name.isNotEmpty
          ? sheetData.name
          : 'Sheet${i + 1}';

      // Rename default sheet for first, add new sheets for rest
      if (i == 0 && defaultSheetName != null) {
        excel.rename(defaultSheetName, sheetName);
      } else {
        excel.copy(defaultSheetName ?? excel.tables.keys.first, sheetName);
      }

      final sheet = excel[sheetName];

      // Write cell data
      for (final entry in sheetData.cells.entries) {
        final parts = entry.key.split(',');
        if (parts.length != 2) continue;
        final rowIdx = int.tryParse(parts[0]);
        final colIdx = int.tryParse(parts[1]);
        if (rowIdx == null || colIdx == null) continue;

        final cellData = entry.value;
        final cellIndex = xl.CellIndex.indexByColumnRow(
          columnIndex: colIdx,
          rowIndex: rowIdx,
        );

        // Set cell value
        final rawValue = cellData.rawValue;
        if (rawValue.isNotEmpty) {
          // Determine cell value
          xl.CellValue cellValue;
          final numVal = double.tryParse(rawValue);
          if (numVal != null) {
            if (numVal == numVal.roundToDouble()) {
              cellValue = xl.IntCellValue(numVal.round());
            } else {
              cellValue = xl.DoubleCellValue(numVal);
            }
          } else if (rawValue.toLowerCase() == 'true' ||
              rawValue.toLowerCase() == 'false') {
            cellValue =
                xl.BoolCellValue(rawValue.toLowerCase() == 'true');
          } else if (rawValue.startsWith('=')) {
            cellValue =
                xl.FormulaCellValue(rawValue.substring(1));
          } else {
            cellValue = xl.TextCellValue(rawValue);
          }

          // Apply value and formatting in one call
          final cellStyle = _buildCellStyle(cellData);
          sheet.updateCell(cellIndex, cellValue,
              cellStyle: cellStyle);
        }
      }

      // Apply merged cells
      for (final merge in sheetData.mergedCells) {
        sheet.merge(
          xl.CellIndex.indexByColumnRow(
            columnIndex: merge.start.col,
            rowIndex: merge.start.row,
          ),
          xl.CellIndex.indexByColumnRow(
            columnIndex: merge.end.col,
            rowIndex: merge.end.row,
          ),
        );
      }
    }

    // Remove any extra default sheets
    if (sheets.isNotEmpty && defaultSheetName != null) {
      // If default sheet wasn't renamed, remove it
      final hasDefault = sheets.any((s) =>
          s.name == defaultSheetName ||
          (sheets.indexOf(s) == 0 && s.name.isEmpty));
      if (!hasDefault && excel.tables.containsKey(defaultSheetName)) {
        excel.delete(defaultSheetName);
      }
    }

    final bytes = excel.encode();
    return Uint8List.fromList(bytes!);
  }

  /// Import an XLSX file into a list of SheetData objects.
  static List<SheetData> importFromXlsx({
    required Uint8List fileBytes,
  }) {
    final excel = xl.Excel.decodeBytes(fileBytes);
    final result = <SheetData>[];

    for (final tableName in excel.tables.keys) {
      final table = excel.tables[tableName]!;
      final cells = <String, CellData>{};
      int maxRow = 0;
      int maxCol = 0;

      for (int rowIdx = 0; rowIdx < table.maxRows; rowIdx++) {
        final row = table.row(rowIdx);
        for (int colIdx = 0; colIdx < row.length; colIdx++) {
          final xlCell = row[colIdx];
          if (xlCell == null || xlCell.value == null) continue;

          final key = '$rowIdx,$colIdx';

          String rawValue;
          String displayValue;

          switch (xlCell.value) {
            case xl.IntCellValue(value: final v):
              rawValue = v.toString();
              displayValue = v.toString();
            case xl.DoubleCellValue(value: final v):
              rawValue = v.toString();
              displayValue = v.toStringAsFixed(
                  v == v.roundToDouble() ? 0 : 2);
            case xl.TextCellValue(value: final v):
              rawValue = v.toString();
              displayValue = v.toString();
            case xl.BoolCellValue(value: final v):
              rawValue = v.toString();
              displayValue = v ? 'TRUE' : 'FALSE';
            case xl.FormulaCellValue(formula: final f):
              rawValue = '=$f';
              displayValue = '=$f';
            case xl.DateCellValue():
              rawValue = xlCell.value.toString();
              displayValue = xlCell.value.toString();
            case xl.DateTimeCellValue():
              rawValue = xlCell.value.toString();
              displayValue = xlCell.value.toString();
            case xl.TimeCellValue():
              rawValue = xlCell.value.toString();
              displayValue = xlCell.value.toString();
            default:
              rawValue = xlCell.value.toString();
              displayValue = xlCell.value.toString();
          }

          // Extract formatting
          bool isBold = false;
          bool isItalic = false;
          bool isUnderline = false;
          String? textColor;
          String? bgColor;
          String? fontFamily;
          double? fontSize;

          if (xlCell.cellStyle != null) {
            final style = xlCell.cellStyle!;
            isBold = style.isBold;
            isItalic = style.isItalic;
            isUnderline = style.underline != xl.Underline.None;

            if (style.fontColor != xl.ExcelColor.black) {
              textColor = _excelColorToHex(style.fontColor);
            }
            if (style.backgroundColor != xl.ExcelColor.none) {
              bgColor = _excelColorToHex(style.backgroundColor);
            }
            if (style.fontFamily != null) {
              fontFamily = style.fontFamily;
            }
            if (style.fontSize != null) {
              fontSize = style.fontSize!.toDouble();
            }
          }

          cells[key] = CellData(
            rawValue: rawValue,
            displayValue: displayValue,
            isBold: isBold,
            isItalic: isItalic,
            isUnderline: isUnderline,
            textColor: textColor,
            backgroundColor: bgColor,
            fontFamily: fontFamily ?? 'Inter',
            fontSize: fontSize ?? 12.0,
          );

          if (rowIdx > maxRow) maxRow = rowIdx;
          if (colIdx > maxCol) maxCol = colIdx;
        }
      }

      // Extract merged cells
      final mergedCells = <CellRange>[];
      for (final merge in table.spannedItems) {
        // spannedItems are strings like 'A1:C3'
        try {
          final parts = merge.toString().split(':');
          if (parts.length == 2) {
            final start = CellPosition.fromReference(parts[0]);
            final end = CellPosition.fromReference(parts[1]);
            mergedCells.add(CellRange(start, end));
          }
        } catch (_) {
          // Skip unparseable merge ranges
        }
      }

      result.add(SheetData(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: tableName,
        cells: cells,
        rowCount: (maxRow + 20).clamp(50, 10000),
        colCount: (maxCol + 5).clamp(26, 1000),
        mergedCells: mergedCells,
      ));
    }

    return result;
  }

  /// Build an Excel CellStyle from CellData formatting.
  static xl.CellStyle? _buildCellStyle(CellData cellData) {
    if (!cellData.isBold &&
        !cellData.isItalic &&
        !cellData.isUnderline &&
        cellData.textColor == null &&
        cellData.backgroundColor == null) {
      return null;
    }

    return xl.CellStyle(
      bold: cellData.isBold,
      italic: cellData.isItalic,
      underline: cellData.isUnderline
          ? xl.Underline.Single
          : xl.Underline.None,
      fontColorHex: cellData.textColor != null
          ? _hexToExcelColor(cellData.textColor!) ?? xl.ExcelColor.black
          : xl.ExcelColor.black,
      backgroundColorHex: cellData.backgroundColor != null
          ? _hexToExcelColor(cellData.backgroundColor!) ?? xl.ExcelColor.none
          : xl.ExcelColor.none,
      fontSize: cellData.fontSize.round(),
      fontFamily: cellData.fontFamily,
    );
  }

  static String? _excelColorToHex(xl.ExcelColor color) {
    try {
      final hexStr = color.colorHex;
      if (hexStr.length >= 6) {
        return '#${hexStr.substring(hexStr.length - 6)}';
      }
    } catch (_) {}
    return null;
  }

  static xl.ExcelColor? _hexToExcelColor(String hex) {
    try {
      final clean = hex.replaceAll('#', '');
      return xl.ExcelColor.fromHexString('FF$clean');
    } catch (_) {
      return null;
    }
  }
}
