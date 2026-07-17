import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opensuite/shared/editor_file_menu.dart';

void main() {
  group('EditorFileMenu', () {
    testWidgets('renders menu button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(
              actions: [
                EditorFileMenu(
                  onSave: () {},
                  onNew: () {},
                ),
              ],
            ),
          ),
        ),
      );
      expect(find.byIcon(Icons.more_vert), findsOneWidget);
    });

    testWidgets('opens menu with standard items', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(
              actions: [
                EditorFileMenu(
                  onNew: () {},
                  onOpen: () {},
                  onSave: () {},
                  onSaveAs: () {},
                  onShare: () {},
                  exportFormats: const ['PDF', 'DOCX'],
                  onExport: (_) {},
                ),
              ],
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      expect(find.text('New'), findsOneWidget);
      expect(find.text('Open'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);
      expect(find.text('Save As'), findsOneWidget);
      expect(find.text('Share'), findsOneWidget);
      expect(find.text('Export as PDF'), findsOneWidget);
      expect(find.text('Export as DOCX'), findsOneWidget);
    });

    testWidgets('calls onNew when tapped', (tester) async {
      int newCount = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(
              actions: [
                EditorFileMenu(onNew: () => newCount++),
              ],
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('New'));
      await tester.pumpAndSettle();
      expect(newCount, 1);
    });

    testWidgets('calls onExport with format', (tester) async {
      String? exportedFormat;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(
              actions: [
                EditorFileMenu(
                  exportFormats: const ['PDF'],
                  onExport: (f) => exportedFormat = f,
                ),
              ],
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Export as PDF'));
      await tester.pumpAndSettle();
      expect(exportedFormat, 'PDF');
    });

    testWidgets('shows autosave toggle', (tester) async {
      bool autosave = true;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(
              actions: [
                EditorFileMenu(
                  autosaveEnabled: autosave,
                  onAutosaveToggle: (v) => autosave = v,
                ),
              ],
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      expect(find.text('Autosave On'), findsOneWidget);
    });

    testWidgets('only shows provided actions', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(
              actions: [
                EditorFileMenu(onSave: () {}),
              ],
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      expect(find.text('Save'), findsOneWidget);
      expect(find.text('New'), findsNothing);
      expect(find.text('Open'), findsNothing);
      expect(find.text('Share'), findsNothing);
    });

    testWidgets('shows print with shortcut', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(
              actions: [
                EditorFileMenu(onPrint: () {}),
              ],
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      expect(find.text('Print'), findsOneWidget);
      expect(find.text('Ctrl+P'), findsOneWidget);
    });
  });
}
