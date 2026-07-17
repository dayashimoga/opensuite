import 'package:fileutility_core/fileutility_core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SlideTable', () {
    test('creates with defaults', () {
      const table = SlideTable(id: 't1');
      expect(table.rows, 3);
      expect(table.columns, 3);
      expect(table.cells, isEmpty);
      expect(table.borderColor, '#333333');
      expect(table.borderWidth, 1.0);
      expect(table.headerColor, isNull);
    });

    test('getCell returns empty for missing key', () {
      const table = SlideTable(id: 't1', cells: {'0,0': 'Hello'});
      expect(table.getCell(0, 0), 'Hello');
      expect(table.getCell(1, 1), '');
    });

    test('copyWith preserves unchanged fields', () {
      const table = SlideTable(
        id: 't1',
        rows: 4,
        columns: 5,
        borderColor: '#FF0000',
      );
      final updated = table.copyWith(rows: 6);
      expect(updated.rows, 6);
      expect(updated.columns, 5);
      expect(updated.borderColor, '#FF0000');
      expect(updated.id, 't1');
    });

    test('toMap / fromMap round-trip', () {
      const table = SlideTable(
        id: 't1',
        rows: 2,
        columns: 3,
        cells: {'0,0': 'A', '1,2': 'B'},
        cellPadding: 12.0,
        headerColor: '#AABBCC',
      );
      final map = table.toMap();
      final restored = SlideTable.fromMap(map);
      expect(restored.id, 't1');
      expect(restored.rows, 2);
      expect(restored.columns, 3);
      expect(restored.getCell(0, 0), 'A');
      expect(restored.getCell(1, 2), 'B');
      expect(restored.cellPadding, 12.0);
      expect(restored.headerColor, '#AABBCC');
    });

    test('equatable equality', () {
      const a = SlideTable(id: 't1', rows: 3, columns: 3);
      const b = SlideTable(id: 't1', rows: 3, columns: 3);
      expect(a, equals(b));
    });
  });

  group('SlideAnimation', () {
    test('creates with defaults', () {
      const anim = SlideAnimation(id: 'a1', targetElementId: 'e1');
      expect(anim.type, 'fadeIn');
      expect(anim.durationMs, 500);
      expect(anim.delayMs, 0);
      expect(anim.trigger, 'onClick');
      expect(anim.order, 0);
    });

    test('copyWith changes specific fields', () {
      const anim = SlideAnimation(
        id: 'a1',
        targetElementId: 'e1',
        type: 'fadeIn',
        durationMs: 500,
      );
      final updated = anim.copyWith(type: 'zoomIn', durationMs: 1000);
      expect(updated.type, 'zoomIn');
      expect(updated.durationMs, 1000);
      expect(updated.targetElementId, 'e1');
      expect(updated.id, 'a1');
    });

    test('toMap / fromMap round-trip', () {
      const anim = SlideAnimation(
        id: 'a1',
        targetElementId: 'e1',
        type: 'bounce',
        durationMs: 750,
        delayMs: 200,
        trigger: 'afterPrevious',
        order: 3,
      );
      final map = anim.toMap();
      final restored = SlideAnimation.fromMap(map);
      expect(restored.id, 'a1');
      expect(restored.targetElementId, 'e1');
      expect(restored.type, 'bounce');
      expect(restored.durationMs, 750);
      expect(restored.delayMs, 200);
      expect(restored.trigger, 'afterPrevious');
      expect(restored.order, 3);
    });

    test('equatable equality', () {
      const a = SlideAnimation(id: 'a1', targetElementId: 'e1');
      const b = SlideAnimation(id: 'a1', targetElementId: 'e1');
      expect(a, equals(b));
    });
  });

  group('SlideMaster', () {
    test('creates with defaults', () {
      const master = SlideMaster(id: 'm1', name: 'Title');
      expect(master.layoutType, 'blank');
      expect(master.backgroundColor, '#FFFFFF');
      expect(master.placeholders, isEmpty);
    });

    test('toMap / fromMap round-trip', () {
      const master = SlideMaster(
        id: 'm1',
        name: 'Two Column',
        layoutType: 'twoColumn',
        backgroundColor: '#F0F0F0',
        backgroundImage: 'bg.png',
        placeholders: [
          SlideElement(
            id: 'p1',
            type: 'text',
            x: 0.05,
            y: 0.1,
            width: 0.4,
            height: 0.8,
          ),
        ],
      );
      final map = master.toMap();
      final restored = SlideMaster.fromMap(map);
      expect(restored.id, 'm1');
      expect(restored.name, 'Two Column');
      expect(restored.layoutType, 'twoColumn');
      expect(restored.backgroundColor, '#F0F0F0');
      expect(restored.backgroundImage, 'bg.png');
      expect(restored.placeholders.length, 1);
      expect(restored.placeholders.first.id, 'p1');
    });

    test('equatable equality', () {
      const a = SlideMaster(id: 'm1', name: 'Title');
      const b = SlideMaster(id: 'm1', name: 'Title');
      expect(a, equals(b));
    });
  });
}
