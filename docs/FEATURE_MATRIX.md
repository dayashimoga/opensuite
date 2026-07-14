# OpenSuite — Feature Matrix

## Module Availability

| Module | Web | Android | iOS | Windows | macOS | Linux | Status |
|--------|-----|---------|-----|---------|-------|-------|--------|
| Notes | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | Production |
| File Manager | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | Production |
| Text Editor | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | Production |
| Document Editor | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | Needs Quill |
| Spreadsheet | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | Production |
| Presentation | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | Production |
| PDF Viewer | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | Production |
| Image Editor | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | Production |

## Shared Services (packages/core)

| Service | Status | Description |
|---------|--------|-------------|
| SaveManager<T> | ✅ v1.5.0 | Generic auto-save with debounce |
| ExportManager | ✅ v1.5.0 | Centralized export with codec registry |
| ImportManager | ✅ v1.5.0 | Unified import with format auto-detection |
| BackgroundTaskManager | ✅ v1.5.0 | Async task queue with progress/cancel |
| FileFormatRegistry | ✅ v1.5.0 | Format metadata (15+ formats) |
| ContextMenuBuilder | ✅ v1.5.0 | Reusable context menu framework |
| ImageProcessor | ✅ v1.5.0 | Real pixel manipulation (dart:ui) |
| CsvCodec / TsvCodec | ✅ v1.5.0 | Delimited text codecs |
| UndoRedoManager<T> | ✅ v1.0.0 | Shared undo/redo stack |
| ClipboardService | ✅ v1.0.0 | Shared clipboard |
| KeyboardShortcutService | ✅ v1.0.0 | Shortcut framework |
| InputSanitizer | ✅ v1.2.0 | Security input validation |
| FormulaEngine | ✅ v1.0.0 | 60+ spreadsheet functions |
| AppLogger | ✅ v1.0.0 | Structured logging |
| ErrorHandler | ✅ v1.0.0 | Result monad |

## Notes Features

| Feature | Status |
|---------|--------|
| Plain Text | ✅ |
| Markdown | ✅ |
| Rich Text | ✅ |
| Checklists | ✅ |
| Code Blocks | ✅ (via markdown) |
| Tables | ✅ (via markdown) |
| Search | ✅ |
| Pin/Favorite | ✅ |
| Color Tags | ✅ |
| Autosave | ✅ |
| Share | ✅ |

## File Manager Features

| Feature | Status |
|---------|--------|
| Recent Files | ✅ |
| Favorites | ✅ |
| Search | ✅ |
| List/Grid View | ✅ |
| File Metadata | ✅ |
| Delete | ✅ |
| Sort (name/date/size/type) | ✅ |
| Context Menu | ✅ |
| Local Directory Browse | ❌ Planned |
| Multi-Select | ❌ Planned |

## Document Editor Features

| Feature | Status | Notes |
|---------|--------|-------|
| Text Editing | ✅ | Plain TextField (needs flutter_quill) |
| Bold/Italic/Underline/Strikethrough | ⚠️ | Markdown syntax, not visual |
| Headings (H1–H3) | ⚠️ | Markdown syntax |
| Lists (ordered/unordered) | ⚠️ | Markdown syntax |
| Blockquotes | ⚠️ | Markdown syntax |
| Code Blocks | ⚠️ | Markdown syntax |
| Links | ⚠️ | Markdown syntax |
| Word/Char Count | ✅ | |
| Undo/Redo | ✅ | |
| Autosave | ✅ | |
| Share/Export | ✅ | TXT, Markdown |
| Open File | ✅ | |
| Keyboard Shortcuts | ✅ | |
| DOCX Import | ❌ | Planned |
| DOCX Export | ❌ | Planned |
| Images in Documents | ❌ | Planned |

## Spreadsheet Features

| Feature | Web | Android | Windows | Status |
|---------|-----|---------|---------|--------|
| Cell Editing (text/number/formula) | ✅ Fixed | ✅ | ✅ | v1.5.0 |
| Formula Engine (60+ functions) | ✅ | ✅ | ✅ | v1.0.0 |
| Formula Bar (real-time sync) | ✅ Fixed | ✅ | ✅ | v1.5.0 |
| Multi-Sheet Workbooks | ✅ | ✅ | ✅ | v1.0.0 |
| Cell Formatting (bold/italic/align/color) | ✅ | ✅ | ✅ | v1.0.0 |
| Column Sorting (asc/desc) | ✅ | ✅ | ✅ | v1.0.0 |
| Freeze Panes | ✅ | ✅ | ✅ | v1.0.0 |
| Virtual-Scrolling Grid | ✅ | ✅ | ✅ | v1.3.0 |
| Copy/Cut/Paste | ✅ Fixed | ✅ | ✅ | v1.5.0 |
| Insert/Delete Row/Col | ✅ Fixed | ✅ | ✅ | v1.5.0 |
| CSV Import | ✅ | ✅ | ✅ | v1.5.0 |
| CSV Export | ✅ | ✅ | ✅ | v1.5.0 |
| Fill Handle | ✅ | ✅ | ✅ | v1.5.0 |
| Right-Click Context Menu | ✅ Fixed | ✅ LongPress | ✅ | v1.5.0 |
| Keyboard Navigation (arrows/tab/enter) | ✅ Fixed | N/A | ✅ | v1.5.0 |
| Find & Replace | ✅ | ✅ | ✅ | v1.3.0 |
| Number Formats | ✅ | ✅ | ✅ | v1.0.0 |
| Comments | ✅ | ✅ | ✅ | v1.0.0 |
| Hyperlinks | ✅ | ✅ | ✅ | v1.0.0 |
| Autosave | ✅ | ✅ | ✅ | v1.0.0 |
| XLSX Import/Export | ❌ | ❌ | ❌ | Planned |
| Conditional Formatting | ❌ | ❌ | ❌ | Planned |
| Charts | ❌ | ❌ | ❌ | Planned |

## Presentation Features

| Feature | Status |
|---------|--------|
| Slide Canvas | ✅ |
| Text Boxes | ✅ |
| Shapes (rect/circle/triangle/arrow) | ✅ |
| Image Elements | ✅ (base64, file, URL) |
| Element Drag & Resize | ✅ |
| Element Rotate | ✅ v1.5.0 |
| Element Alignment (6 modes) | ✅ v1.5.0 |
| Element Duplication | ✅ v1.5.0 |
| Group/Ungroup Elements | ✅ v1.5.0 |
| Element Opacity | ✅ v1.5.0 |
| Speaker Notes | ✅ |
| Slide Transitions | ✅ |
| Full-Screen Presentation Mode | ✅ |
| Slide Thumbnails | ✅ |
| Duplicate/Delete/Reorder Slides | ✅ |
| Bring to Front/Send to Back | ✅ |
| Autosave | ✅ |
| Share | ✅ |
| PPTX Import/Export | ❌ Planned |
| Tables in Slides | ❌ Planned |

## PDF Viewer Features

| Feature | Status |
|---------|--------|
| Real PDF Rendering (pdfrx) | ✅ |
| Page Navigation | ✅ |
| Thumbnails Sidebar | ✅ |
| Zoom (25%–500%) | ✅ |
| Text Search with Highlights | ✅ |
| Annotations (highlight/underline/note/freehand) | ✅ |
| Annotation Persistence (SQLite) | ✅ v1.5.0 |
| Annotation Auto-Save | ✅ v1.5.0 |
| Annotation Mode Toggle | ✅ v1.5.0 |
| Page Rotation | ✅ |
| Page Range Selection | ✅ Fixed v1.5.0 |
| Share | ✅ |
| Open File | ✅ |
| PDF Merge | ❌ Planned |
| PDF Compress | ❌ Planned |
| Form Fill | ❌ Planned |

## Image Editor Features

| Feature | Status |
|---------|--------|
| Image Viewing (zoom/pan) | ✅ |
| Brightness/Contrast/Saturation | ✅ |
| Hue Adjustment | ✅ v1.5.0 |
| Exposure Adjustment | ✅ v1.5.0 |
| Crop (free/16:9/4:3/1:1) | ✅ Fixed v1.5.0 |
| Rotate (90°/-90°/free) | ✅ |
| Flip H/V | ✅ |
| Resize (presets) | ✅ |
| Undo/Redo | ✅ |
| Real Image Export (PNG) | ✅ Fixed v1.5.0 |
| Real Dimension Detection | ✅ v1.5.0 |
| Full-Fidelity Canvas | ✅ |
| Open File | ✅ |

## Text Editor Features

| Feature | Status |
|---------|--------|
| Plain Text Editing | ✅ |
| Markdown Editing | ✅ |
| Markdown Preview | ✅ |
| Find & Replace | ✅ |
| Word/Char/Line Count | ✅ |
| Autosave | ✅ |
| Configurable Font Size | ✅ |
| Undo/Redo | ✅ (native) |

## Settings Features

| Feature | Status |
|---------|--------|
| Theme (system/light/dark) | ✅ |
| High Contrast Mode (WCAG AAA) | ✅ |
| Language Selector (10 locales) | ✅ |
| Editor Font Size | ✅ |
| Autosave Toggle | ✅ |
| Autosave Interval | ✅ |
| About/Version Info | ✅ |

## General / Cross-Cutting Features

| Feature | Status |
|---------|--------|
| Offline-first | ✅ |
| Responsive UI (mobile/tablet/desktop) | ✅ |
| PWA | ✅ |
| Dark/Light/System/High-Contrast Theme | ✅ |
| Localization (10 languages) | ✅ |
| Accessibility (WCAG AAA themes) | ✅ |
| Version History (VersionDao) | ✅ |
| Security (InputSanitizer) | ✅ |
| Keyboard Shortcuts (all editors) | ✅ |
| Cross-platform SQLite (FFI + Web) | ✅ |
| Export Pipeline (ExportManager) | ✅ v1.5.0 |
| Import Pipeline (ImportManager) | ✅ v1.5.0 |
| Background Task Queue | ✅ v1.5.0 |
| File Format Registry | ✅ v1.5.0 |
