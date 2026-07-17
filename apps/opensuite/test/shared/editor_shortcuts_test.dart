import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opensuite/shared/editor_shortcuts.dart';

void main() {
  group('EditorShortcuts.build', () {
    test('returns empty map when no callbacks provided', () {
      final bindings = EditorShortcuts.build();
      expect(bindings, isEmpty);
    });

    test('includes only provided callbacks', () {
      int saveCount = 0;
      int undoCount = 0;
      final bindings = EditorShortcuts.build(
        onSave: () => saveCount++,
        onUndo: () => undoCount++,
      );
      // Ctrl+S + Ctrl+Z = 2 entries
      expect(bindings.length, 2);
    });

    test('redo maps both Ctrl+Y and Ctrl+Shift+Z', () {
      int redoCount = 0;
      final bindings = EditorShortcuts.build(onRedo: () => redoCount++);
      // Ctrl+Y and Ctrl+Shift+Z
      expect(bindings.length, 2);
    });

    test('all shortcuts produce correct bindings count', () {
      final bindings = EditorShortcuts.build(
        onNew: () {},
        onOpen: () {},
        onSave: () {},
        onSaveAs: () {},
        onUndo: () {},
        onRedo: () {},
        onFind: () {},
        onFindReplace: () {},
        onPrint: () {},
        onDelete: () {},
        onCut: () {},
        onCopy: () {},
        onPaste: () {},
        onSelectAll: () {},
        onEscape: () {},
      );
      // 15 callbacks but redo adds 2 entries = 16
      expect(bindings.length, 16);
    });

    test('callbacks are invocable', () {
      int count = 0;
      final bindings = EditorShortcuts.build(onSave: () => count++);
      bindings.values.first();
      expect(count, 1);
    });
  });

  group('EditorShortcuts.wrap', () {
    testWidgets('wraps child with CallbackShortcuts', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EditorShortcuts.wrap(
              onSave: () {},
              child: const Text('Editor'),
            ),
          ),
        ),
      );
      expect(find.text('Editor'), findsOneWidget);
      expect(find.byType(CallbackShortcuts), findsOneWidget);
      expect(find.byType(Focus), findsWidgets);
    });

    testWidgets('returns bare child when no shortcuts', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EditorShortcuts.wrap(child: const Text('Plain')),
          ),
        ),
      );
      expect(find.text('Plain'), findsOneWidget);
      expect(find.byType(CallbackShortcuts), findsNothing);
    });
  });
}
