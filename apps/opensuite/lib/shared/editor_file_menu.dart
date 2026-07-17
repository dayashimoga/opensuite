import 'package:flutter/material.dart';

/// Standardized file menu actions for all editor modules.
///
/// Provides a consistent overflow menu structure:
/// New, Open, Import, Save, Save As, Export, Share, Autosave toggle.
///
/// Usage:
/// ```dart
/// EditorFileMenu(
///   onNew: () => ...,
///   onSave: () => ...,
///   exportFormats: ['PDF', 'DOCX'],
///   onExport: (format) => ...,
/// )
/// ```
class EditorFileMenu extends StatelessWidget {
  final VoidCallback? onNew;
  final VoidCallback? onOpen;
  final VoidCallback? onImport;
  final VoidCallback? onSave;
  final VoidCallback? onSaveAs;
  final VoidCallback? onShare;
  final VoidCallback? onPrint;
  final List<String> exportFormats;
  final ValueChanged<String>? onExport;
  final bool autosaveEnabled;
  final ValueChanged<bool>? onAutosaveToggle;
  final List<PopupMenuEntry<String>> additionalItems;

  const EditorFileMenu({
    super.key,
    this.onNew,
    this.onOpen,
    this.onImport,
    this.onSave,
    this.onSaveAs,
    this.onShare,
    this.onPrint,
    this.exportFormats = const [],
    this.onExport,
    this.autosaveEnabled = true,
    this.onAutosaveToggle,
    this.additionalItems = const [],
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      tooltip: 'File Menu',
      onSelected: (value) {
        switch (value) {
          case 'new':
            onNew?.call();
          case 'open':
            onOpen?.call();
          case 'import':
            onImport?.call();
          case 'save':
            onSave?.call();
          case 'save_as':
            onSaveAs?.call();
          case 'share':
            onShare?.call();
          case 'print':
            onPrint?.call();
          case 'autosave':
            onAutosaveToggle?.call(!autosaveEnabled);
          default:
            if (value.startsWith('export_')) {
              onExport?.call(value.replaceFirst('export_', ''));
            }
        }
      },
      itemBuilder: (context) {
        final items = <PopupMenuEntry<String>>[];

        if (onNew != null) {
          items.add(const PopupMenuItem(
            value: 'new',
            child: ListTile(
              leading: Icon(Icons.add, size: 20),
              title: Text('New'),
              subtitle: Text('Ctrl+N', style: TextStyle(fontSize: 11)),
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ));
        }

        if (onOpen != null) {
          items.add(const PopupMenuItem(
            value: 'open',
            child: ListTile(
              leading: Icon(Icons.folder_open, size: 20),
              title: Text('Open'),
              subtitle: Text('Ctrl+O', style: TextStyle(fontSize: 11)),
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ));
        }

        if (onImport != null) {
          items.add(const PopupMenuItem(
            value: 'import',
            child: ListTile(
              leading: Icon(Icons.file_download, size: 20),
              title: Text('Import'),
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ));
        }

        if (onSave != null || onSaveAs != null) {
          items.add(const PopupMenuDivider());
        }

        if (onSave != null) {
          items.add(const PopupMenuItem(
            value: 'save',
            child: ListTile(
              leading: Icon(Icons.save, size: 20),
              title: Text('Save'),
              subtitle: Text('Ctrl+S', style: TextStyle(fontSize: 11)),
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ));
        }

        if (onSaveAs != null) {
          items.add(const PopupMenuItem(
            value: 'save_as',
            child: ListTile(
              leading: Icon(Icons.save_as, size: 20),
              title: Text('Save As'),
              subtitle:
                  Text('Ctrl+Shift+S', style: TextStyle(fontSize: 11)),
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ));
        }

        if (exportFormats.isNotEmpty) {
          items.add(const PopupMenuDivider());
          for (final format in exportFormats) {
            items.add(PopupMenuItem(
              value: 'export_$format',
              child: ListTile(
                leading: const Icon(Icons.file_upload, size: 20),
                title: Text('Export as $format'),
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ));
          }
        }

        if (onShare != null || onPrint != null) {
          items.add(const PopupMenuDivider());
        }

        if (onShare != null) {
          items.add(const PopupMenuItem(
            value: 'share',
            child: ListTile(
              leading: Icon(Icons.share, size: 20),
              title: Text('Share'),
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ));
        }

        if (onPrint != null) {
          items.add(const PopupMenuItem(
            value: 'print',
            child: ListTile(
              leading: Icon(Icons.print, size: 20),
              title: Text('Print'),
              subtitle: Text('Ctrl+P', style: TextStyle(fontSize: 11)),
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ));
        }

        if (onAutosaveToggle != null) {
          items.add(const PopupMenuDivider());
          items.add(PopupMenuItem(
            value: 'autosave',
            child: ListTile(
              leading: Icon(
                autosaveEnabled ? Icons.timer : Icons.timer_off,
                size: 20,
              ),
              title: Text(
                  autosaveEnabled ? 'Autosave On' : 'Autosave Off'),
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ));
        }

        items.addAll(additionalItems);

        return items;
      },
    );
  }
}
