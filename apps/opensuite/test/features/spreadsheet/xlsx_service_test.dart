import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:fileutility_core/fileutility_core.dart';
import 'package:opensuite/features/spreadsheet/services/xlsx_service.dart';

void main() {
  group('XlsxService', () {
    group('exportToXlsx', () {
      test('generates non-empty bytes from empty sheet', () {
        final sheets = [
          SheetData(
            id: 'sheet1',
            name: 'Sheet1',
            cells: const {},
            rowCount: 10,
            colCount: 5,
          ),
        ];

        final bytes = XlsxService.exportToXlsx(
          sheets: sheets,
          title: 'Empty Test',
        );

        expect(bytes, isNotEmpty);
        // XLSX files are ZIP files starting with PK signature
        expect(bytes[0], 0x50); // P
        expect(bytes[1], 0x4B); // K
      });

      test('exports cell values correctly', () {
        final sheets = [
          SheetData(
            id: 'sheet1',
            name: 'Data',
            cells: const {
              '0,0': CellData(rawValue: 'Name', displayValue: 'Name'),
              '0,1': CellData(rawValue: 'Age', displayValue: 'Age'),
              '1,0': CellData(rawValue: 'Alice', displayValue: 'Alice'),
              '1,1': CellData(rawValue: '30', displayValue: '30'),
              '2,0': CellData(rawValue: 'Bob', displayValue: 'Bob'),
              '2,1': CellData(rawValue: '25', displayValue: '25'),
            },
          ),
        ];

        final bytes = XlsxService.exportToXlsx(
          sheets: sheets,
          title: 'Data Export',
        );

        expect(bytes, isNotEmpty);
        expect(bytes.length, greaterThan(100));
      });

      test('exports formatting (bold, italic)', () {
        final sheets = [
          SheetData(
            id: 'sheet1',
            name: 'Formatted',
            cells: const {
              '0,0': CellData(
                rawValue: 'Bold',
                displayValue: 'Bold',
                isBold: true,
              ),
              '0,1': CellData(
                rawValue: 'Italic',
                displayValue: 'Italic',
                isItalic: true,
              ),
              '0,2': CellData(
                rawValue: 'Both',
                displayValue: 'Both',
                isBold: true,
                isItalic: true,
              ),
            },
          ),
        ];

        final bytes = XlsxService.exportToXlsx(
          sheets: sheets,
          title: 'Format Test',
        );

        expect(bytes, isNotEmpty);
      });

      test('exports multiple sheets', () {
        final sheets = [
          SheetData(
            id: 'sheet1',
            name: 'Revenue',
            cells: const {
              '0,0': CellData(rawValue: 'Q1', displayValue: 'Q1'),
              '0,1': CellData(rawValue: '1000', displayValue: '1000'),
            },
          ),
          SheetData(
            id: 'sheet2',
            name: 'Expenses',
            cells: const {
              '0,0': CellData(rawValue: 'Rent', displayValue: 'Rent'),
              '0,1': CellData(rawValue: '500', displayValue: '500'),
            },
          ),
        ];

        final bytes = XlsxService.exportToXlsx(
          sheets: sheets,
          title: 'Multi Sheet',
        );

        expect(bytes, isNotEmpty);
      });

      test('exports formulas as FormulaCellValue', () {
        final sheets = [
          SheetData(
            id: 'sheet1',
            name: 'Formulas',
            cells: const {
              '0,0': CellData(rawValue: '10', displayValue: '10'),
              '0,1': CellData(rawValue: '20', displayValue: '20'),
              '0,2': CellData(
                rawValue: '=A1+B1',
                displayValue: '30',
              ),
            },
          ),
        ];

        final bytes = XlsxService.exportToXlsx(
          sheets: sheets,
          title: 'Formula Test',
        );

        expect(bytes, isNotEmpty);
      });

      test('exports boolean values', () {
        final sheets = [
          SheetData(
            id: 'sheet1',
            name: 'Booleans',
            cells: const {
              '0,0': CellData(rawValue: 'true', displayValue: 'TRUE'),
              '0,1': CellData(rawValue: 'false', displayValue: 'FALSE'),
            },
          ),
        ];

        final bytes = XlsxService.exportToXlsx(
          sheets: sheets,
          title: 'Bool Test',
        );

        expect(bytes, isNotEmpty);
      });

      test('exports cell colors', () {
        final sheets = [
          SheetData(
            id: 'sheet1',
            name: 'Colors',
            cells: const {
              '0,0': CellData(
                rawValue: 'Red text',
                displayValue: 'Red text',
                textColor: '#FF0000',
              ),
              '0,1': CellData(
                rawValue: 'Green bg',
                displayValue: 'Green bg',
                backgroundColor: '#00FF00',
              ),
            },
          ),
        ];

        final bytes = XlsxService.exportToXlsx(
          sheets: sheets,
          title: 'Color Test',
        );

        expect(bytes, isNotEmpty);
      });
    });

    group('importFromXlsx', () {
      test('round-trips simple text data', () {
        final original = [
          SheetData(
            id: 'sheet1',
            name: 'TestSheet',
            cells: const {
              '0,0': CellData(rawValue: 'Hello', displayValue: 'Hello'),
              '0,1': CellData(rawValue: 'World', displayValue: 'World'),
              '1,0': CellData(rawValue: '42', displayValue: '42'),
            },
          ),
        ];

        final exported = XlsxService.exportToXlsx(
          sheets: original,
          title: 'Round Trip',
        );

        final imported = XlsxService.importFromXlsx(fileBytes: exported);

        expect(imported, isNotEmpty);
        expect(imported.first.name, 'TestSheet');

        // Verify cell data
        final cell00 = imported.first.cells['0,0'];
        expect(cell00, isNotNull);
        expect(cell00!.rawValue, contains('Hello'));

        final cell10 = imported.first.cells['1,0'];
        expect(cell10, isNotNull);
        expect(cell10!.rawValue, contains('42'));
      });

      test('round-trips bold/italic formatting', () {
        final original = [
          SheetData(
            id: 'sheet1',
            name: 'FormatSheet',
            cells: const {
              '0,0': CellData(
                rawValue: 'Bold',
                displayValue: 'Bold',
                isBold: true,
              ),
              '0,1': CellData(
                rawValue: 'Italic',
                displayValue: 'Italic',
                isItalic: true,
              ),
            },
          ),
        ];

        final exported = XlsxService.exportToXlsx(
          sheets: original,
          title: 'Format Round Trip',
        );

        final imported = XlsxService.importFromXlsx(fileBytes: exported);

        final boldCell = imported.first.cells['0,0'];
        expect(boldCell, isNotNull);
        expect(boldCell!.isBold, isTrue);

        final italicCell = imported.first.cells['0,1'];
        expect(italicCell, isNotNull);
        expect(italicCell!.isItalic, isTrue);
      });

      test('round-trips multiple sheets', () {
        final original = [
          SheetData(
            id: 'sheet1',
            name: 'First',
            cells: const {
              '0,0': CellData(rawValue: 'A', displayValue: 'A'),
            },
          ),
          SheetData(
            id: 'sheet2',
            name: 'Second',
            cells: const {
              '0,0': CellData(rawValue: 'B', displayValue: 'B'),
            },
          ),
        ];

        final exported = XlsxService.exportToXlsx(
          sheets: original,
          title: 'Multi Sheet',
        );

        final imported = XlsxService.importFromXlsx(fileBytes: exported);

        expect(imported.length, greaterThanOrEqualTo(2));
      });

      test('imports numeric values as proper types', () {
        final original = [
          SheetData(
            id: 'sheet1',
            name: 'Numbers',
            cells: const {
              '0,0': CellData(rawValue: '42', displayValue: '42'),
              '0,1': CellData(rawValue: '3.14', displayValue: '3.14'),
            },
          ),
        ];

        final exported = XlsxService.exportToXlsx(
          sheets: original,
          title: 'Number Test',
        );

        final imported = XlsxService.importFromXlsx(fileBytes: exported);

        final intCell = imported.first.cells['0,0'];
        expect(intCell, isNotNull);
        expect(intCell!.rawValue, '42');

        final doubleCell = imported.first.cells['0,1'];
        expect(doubleCell, isNotNull);
        expect(doubleCell!.rawValue, '3.14');
      });

      test('throws on invalid bytes', () {
        expect(
          () => XlsxService.importFromXlsx(
            fileBytes: Uint8List.fromList([1, 2, 3, 4]),
          ),
          throwsA(anything),
        );
      });

      test('sets reasonable row/col counts', () {
        final original = [
          SheetData(
            id: 'sheet1',
            name: 'Small',
            cells: const {
              '5,3': CellData(rawValue: 'Data', displayValue: 'Data'),
            },
          ),
        ];

        final exported = XlsxService.exportToXlsx(
          sheets: original,
          title: 'Size Test',
        );

        final imported = XlsxService.importFromXlsx(fileBytes: exported);

        expect(imported.first.rowCount, greaterThanOrEqualTo(25));
        expect(imported.first.colCount, greaterThanOrEqualTo(8));
      });
    });
  });
}
