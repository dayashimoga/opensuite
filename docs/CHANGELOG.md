# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.3.0+17] - 2026-07-20

### Fixed — Sprint 22: Spreadsheet Engine & UI Enhancements

- **Multi-Cell Selection**:
  - Grid-level pointer Listener calculating target cell offsets continuously during drag gestures for smooth range selection.
  - Shift + Click range expansion: holding Shift while clicking a cell extends the selection range from anchor cell to clicked cell.
  - Shift + Arrow keys range selection expansion in grid.
  - Row & Column header click selection for full-row and full-column operations.
- **Keyboard Navigation**:
  - `Tab` moves cell selection right (`col + 1`), `Shift + Tab` moves left (`col - 1`).
  - `Enter` moves cell selection down (`row + 1`), `Shift + Enter` moves up (`row - 1`).
  - Arrow keys navigate active grid cells when not editing.
- **Row & Column Operations**:
  - Added explicit options for "Insert Row Above" (`InsertRow(row - 1)`), "Insert Row Below" (`InsertRow(row)`), "Insert Column Left" (`InsertColumn(col - 1)`), and "Insert Column Right" (`InsertColumn(col)`).
  - Preserved `rowHeights`, `columnWidths`, `hiddenRows`, `hiddenCols`, and cell keys when inserting or deleting rows and columns.
- **Table Creation & Formatting**:
  - Enhanced `CreateTable` with blue header styling, white text, bold formatting, alternating row background colors (zebra striping), and visible cell borders (`CellBorders.all('#D0D5DD')`).
  - Added Table creation options to Ribbon bar (Home & Insert tabs) and Context Menu ("Format as Table").
- **Multi-Cell & Range Formatting**:
  - Updated `_applyFormatToSelection` in `SpreadsheetBloc` to format all cells within any active `selectedRange` (single cell, range, full row, full column).

## [2.2.0+16] - 2026-07-20

### Fixed — Sprint 21: Platform & Build Foundation

- **Flutter SDK Upgrade**: Upgraded from Flutter 3.27.4 to 3.44.6 (Dart 3.12.2) across all environments (local, CI, Docker)
- **flutter_quill v11 Migration**: Upgraded `flutter_quill` from ^10.8.5 to ^11.5.1, fixing:
  - `intl` version conflict with Flutter SDK's pinned `intl 0.20.2`
  - `quill_native_bridge_windows` GMEM_MOVEABLE compilation error (GitHub Actions CI)
  - API migration: `QuillEditorConfigurations` → `QuillEditorConfig`, `configurations:` → `config:`
- **22 Static Analysis Issues Resolved**: Fixed all deprecated APIs for Flutter 3.44 compatibility:
  - `DropdownButtonFormField.value` → `initialValue` (8 files)
  - `Matrix4.scale()` → `scaleByDouble()` / `scaleByVector3()` (2 files)
  - `RadioListTile.groupValue/onChanged` → `RadioGroup` wrapper (1 file)
  - `ReorderableListView.onReorder` → `onReorderItem` (2 files)
- **CI/CD Pipeline**: Updated all 7 GitHub Actions jobs to Flutter 3.44.6, added Developer Mode step for Windows builds, added iOS project auto-generation step
- **Docker**: Updated Flutter image from 3.27 to 3.44
- **Build Verification**: `flutter analyze` 0 issues, `dart format` clean, 240/240 tests passing, web release build successful

## [2.1.0+15] - 2026-07-17

### Added — Sprint 20: Presentation Animations Sidebar & Spreadsheet Range Selection fixes
- **Presentation Animations Panel**: Imported and wired `AnimationPanel` right-side sidebar toggle button in Presentation editor with events `AddAnimation`, `RemoveAnimation`, `UpdateAnimation`, `ReorderAnimations`. Added unit tests for all animation events with 100% test passing (240/240).
- **Spreadsheet Drag Selection**: Refactored drag selection to use a grid-level `Listener` that calculates targeted cells based on pointer positions, scroll offsets, and cell bounds, completely fixing range selections.
- **Spreadsheet Shift+Click Selection**: Enabled range extension using Shift + Click to select multiple cells seamlessly.
- **Presentation SlideTable rendering**: Deserialized JSON table elements dynamically on the slide canvas and wired double-tap cell editing callbacks back to PresentationBloc.
- **CellData isEmpty Fix**: Prevented silent cell deletion by updating `CellData.isEmpty` to verify formatting properties alongside `rawValue` checks.
- **Keyboard focus restoration**: Fixed keyboard event listeners by programmatically restoring focus to the spreadsheet grid after completing cell edits.

## [2.0.0+14] - 2026-07-17

### Added — Sprint 14: Document Editor Rich Text Engine
- **Rich Text Editor**: Replaced plain `TextField` with `flutter_quill` QuillEditor + full formatting toolbar (headings, bold, italic, underline, strike, colors, alignment, bullets, numbering)
- **DOCX Export/Import**: `DocxService` — full OOXML ZIP export with styles, headings, lists, tables; import with Delta JSON conversion
- **PDF Export**: `PdfExportService` — multi-page PDF generation with rich text formatting
- **Delta-based BLoC**: Rewrote `DocumentEditorBloc` for Quill Delta JSON serialization and Quill's built-in undo/redo

### Added — Sprint 15: Spreadsheet XLSX I/O + Charts + Conditional Formatting
- **XLSX Import/Export**: `XlsxService` using `excel` v4.x — cell values, formatting, merged cells, formulas, sheet names
- **Charts**: `SpreadsheetChart` widget (Bar, Line, Pie) using `fl_chart` with theme-aware colors
- **Conditional Formatting**: BLoC events/handlers + `ConditionalFormatDialog` rule builder UI
- **Chart Insert UI**: Bottom sheet dialog with chart type chips and live preview

### Added — Sprint 16: Presentation PPTX I/O + Tables + Animations
- **PPTX Export/Import**: `PptxService` — full OOXML ZIP serialization with text boxes, shapes, images, backgrounds
- **Presentation PDF Export**: `PresentationPdfService` — landscape PDF generation from slides
- **SlideTable model + widget**: Editable table element on slide canvas with add row/column, double-tap cell editing
- **SlideAnimation model + AnimationPanel**: Sidebar for managing element animations (fadeIn, slideLeft, zoomIn, bounce, etc.)
- **SlideMaster model**: Layout templates (title, titleContent, twoColumn, blank, etc.)

### Added — Sprint 17: Image Editor Layers + Drawing + Filters
- **Drawing Canvas**: Freehand drawing overlay with pen/eraser tool and stroke tracking
- **Text Overlay Tool**: Add text with font size, color, bold/italic controls
- **Shape Tool**: Rectangle, circle, triangle, line, arrow, star shape overlays
- **Layer Panel**: Sidebar with visibility toggle, opacity slider, reorder, merge
- **Filter Gallery**: Horizontal scrollable preset filters (grayscale, sepia, blur, sharpen, emboss, edge detect, etc.)
- **Batch Processing Dialog**: Multi-file operations with format, resize, filter, quality, watermark options
- **BLoC Events**: AddTextOverlay, AddDrawingPath, ApplyPresetFilter, AddWatermark with undo support

### Added — Sprint 18: PDF Merge/Split + Bookmarks + OCR Framework
- **PDF Manipulation**: `PdfManipulationService` — merge, split, extract, delete, watermark, rotate
- **Bookmark Panel**: Sidebar for PDF bookmark navigation with add/remove and hierarchical display
- **Signature Pad**: Touch/mouse signature capture widget with stroke tracking
- **Merge/Split Dialog**: Tabbed dialog for PDF split/extract/delete with page range and chip selectors
- **OCR Framework**: Pluggable `OcrEngine` interface with `StubOcrEngine` — ready for Tesseract/Google Vision/ML Kit

### Added — Sprint 19: Infrastructure + Polish
- **Docker**: Fixed volume mount dependency resolution — `pub get` for all packages before analyze/test
- **Dependency Fix**: Resolved `archive` version conflict (downgraded to ^3.6.1 for excel compatibility)
- **Models**: Added `SlideTable`, `SlideAnimation`, `SlideMaster` to presentation_models.dart

### Fixed
- `DocxService` paragraph block attributes mapping (headings not generated in DOCX)
- `DocumentEditorState.copyWith` nullability (current document not cleared on delete)
- `XlsxService` Excel v4.x API migration (TextSpan, spannedItems, ExcelColor)
- `SpreadsheetChart` fl_chart 0.69.x `axisSide` API compatibility
- `PptxService` XmlNode→XmlElement parent casting
- `RichDocumentEditorPage` missing imports (storage, quill_delta)
- Unit test seeding issues (FindInDocument empty query)

## [1.9.0+13] - 2026-07-16

### Fixed & Enhanced — Image Editor Interactive Crop, Pixel Resize & Multi-Tile Photo Generator
- **Interactive Free & Constrained Aspect Ratio Crop**: Implemented `_InteractiveCropBox` with 8 corner/edge drag handles, custom darkened overlay mask, aspect ratio preset chips (`Free`, `16:9`, `4:3`, `1:1`, `Passport 3.5:4.5`, `3:2`), and **Apply Crop** / **Reset** controls dispatching pixel-accurate cropping to `ImageEditorBloc`.
- **Numerical Pixel & Preset Resizing**: Added `Width` and `Height` px `TextField`s with auto aspect-ratio calculation, scale sliders (`25%` to `200%`), and preset buttons (`1080p`, `720p`, `50%`), coupled with responsive canvas scaling matching image dimensions.
- **Multi-Tile Photo Sheet Layout Generator**: Created `PhotoTileGenerator` supporting international paper size formats (`A4`, `A3`, `B4`, `B5`, `Letter`, `Legal`) and photo size standards (`Passport 35×45mm`, `US/India Passport 2×2in`, `Stamp 20×25mm`, `Schengen Visa`, `Postcard 4×6in`, `Wallet 64×89mm`). Automatically calculates max photo capacity per sheet (e.g. 35 tiles on A4) with cut outlines toggle and instant Blob file downloads (`FileDownloadUtils`).

## [1.8.0+12] - 2026-07-16

### Fixed & Enhanced — Presentation Canvas Direct Inline Editing, 8-Point Handles & Layout Templates
- **Presentation Direct Canvas Inline Text Editing**: Converted `_CanvasElement` to `StatefulWidget` so double-clicking any text box directly on the slide canvas opens a transparent, focused `TextField` with live typing, auto-wrap, and instant BLoC state updates (`UpdateElementContent`).
- **8-Point Control Points for Object Resizing**: Rendered 8 interactive resize handles (`Top-Left`, `Top-Right`, `Bottom-Left`, `Bottom-Right`, etc.) around selected slide elements for proportional 2D manipulation.
- **Slide Layout Template Selector Modal**: Integrated layout picker modal when clicking "Add Slide" to select pre-formatted slide archetypes (`Title Slide`, `Title & Content`, `Blank Slide`).
- **Package Core & Storage Dependency Pinning**: Added pinned `file_picker: ^9.2.1` and `csv: ^6.0.0` dependencies to `packages/core/pubspec.yaml`, ensuring isolated CI test runs (`flutter test --coverage`) pass cleanly without missing package errors.

## [1.7.1+10] - 2026-07-15

### Fixed & Enhanced — Web Spreadsheet Right-Click, Import/Export & Drag Selection
- **Web Browser Right-Click Context Menu Fix**: Suppressed default browser DOM context menu (`Back`, `Forward`, `Ask Gemini`) on Flutter Web via `BrowserContextMenu.disableContextMenu()` in `initState()`, leaving only the custom spreadsheet context menu visible on right-click.
- **Local Disk File Export & Download**: Created `FileDownloadUtils` in `packages/core` to instantly trigger browser Blob downloads (`html.AnchorElement`) on Web and native save dialogs on Desktop/Mobile for CSV and Excel exports.
- **Local File Import (CSV / XLSX / TSV / ODS)**: Integrated local file picker in AppBar overflow menu and Data ribbon tab to import CSV/Excel spreadsheets from disk into full editing state.
- **Drag Mouse Selection for Multi-Cell Ranges & Table Creation**: Converted `_VirtualSpreadsheetGrid` to StatefulWidget with interactive pointer drag range selection, full column header click selection, full row header click selection, top-left full sheet selection, and `CreateTable` event formatting.
- **Empty Cell & Range Color Filling**: Updated `_GridCell` background color rendering to use `Color.alphaBlend` over `baseBgColor`, allowing background fill colors on empty cells, multi-cell ranges, rows, and columns to render cleanly.

## [1.7.0+9] - 2026-07-14

### Fixed & Enhanced — Live Cloudflare Deployment Root Cause Fixes
- **LinePrefixUtils Framework**: Added `LinePrefixUtils` helper in `packages/core` to strip existing list/heading prefixes (`1. `, `- `, `- [ ] `, `> `, `# `) before applying new ones, completely fixing list prefix collisions (e.g. `1. - asdfasdf` in Screenshot 2). Supports multi-line selection formatting across documents & notes.
- **Presentation Shape Library Dropdown**: Replaced single rectangle shape icon button with a comprehensive Shape Library Popup Menu offering 8 vector geometric shapes (Rectangle, Circle, Triangle, Diamond, Star, Arrow, Line, Callout).
- **Image Editor Interactive Crop Box Canvas Overlay**: Rendered draggable/scalable crop outline box with corner handles directly on the image canvas matching live right-panel aspect ratio chips (`Free`, `16:9`, `4:3`, `1:1`, `Passport 2x2`).

## [1.6.1+8] - 2026-07-14

### Fixed — System Architecture & State Synchronization Root Causes
- **Notes BLoC Scoping**: Replaced direct DAO instantiation and manual BLoC instance closing in `NoteEditorPage` with top-level `BlocProvider<NotesBloc>` scoping and standard event dispatch.
- **Spreadsheet On-Cell Keyboard Typing**: Updated `_handleKeyEvent` in `SpreadsheetEditorPage` so pressing printable character keys when a cell is selected automatically focuses the formula bar input node and streams typed characters into active cell state.
- **Presentation Canvas Element Resizing**: Mapped `onPanUpdate` gestures on slide canvas resize handles directly to `ResizeElement` events.
- **File Manager Event Routing**: Bound file sorting options directly to `FileManagerBloc` `SortFiles` events and added interactive `RenameFile` dialogs to file tiles.

## [1.6.0+7] - 2026-07-14

### Added — Sprint 4: Document Editor Enhancements
- **Find & Replace**: Full find/replace implementation with case-insensitive matching, match counting, next/previous navigation, replace single, and replace all operations.
- **FindInDocument Event**: Searches document content and returns all match positions.
- **ReplaceInDocument Event**: Replaces single match at current index or all matches. Pushes undo state before modification.
- **NavigateFindMatch Event**: Cycles through match positions forward/backward with wrapping.
- **InsertAtCursor Event**: Inserts text at any position with undo support.
- **ToggleFindReplace Event**: Shows/hides find & replace bar, clears state on close.
- **_FindReplaceBar Widget**: Interactive find/replace bar with find field (shows match count), up/down navigation arrows, replace field, Replace and Replace All buttons.

### Added — Sprint 7: File Manager Enhancements
- **BrowseDirectory Event**: Lists contents of a local directory via `dart:io` (non-web). Returns `FileSystemItem` list with name, path, size, modified date, extension, and isDirectory flag. Hidden files are excluded. Directories sort first, then alphabetically.
- **RenameFile Event**: Renames both the database record and the actual file on disk (non-web).
- **CopyFile Event**: Copies a file to a destination path via `dart:io` (non-web).
- **MoveFile Event**: Moves/renames a file to a destination path via `dart:io` (non-web).
- **SortFiles Event**: Sorts file list by name, date, size, or type in ascending/descending order.
- **ToggleMultiSelect Event**: Toggles multi-select mode on/off, clears selections on toggle.
- **SelectFile Event**: Toggles a file's selection in multi-select mode.
- **ClearSelection Event**: Clears all selected file IDs.
- **PerformBulkDelete Event**: Deletes all selected files from the database in one operation.
- **FileSystemItem Model**: New Equatable model representing a file/directory from local browsing with name, path, isDirectory, sizeBytes, modifiedAt, and extension fields.

## [1.5.0+6] - 2026-07-14

### Added — Sprint 1: Shared Editor Foundation
- **SaveManager\<T\>**: Generic auto-save service with debounce, dirty-state tracking, and configurable delay. Replaces 5 duplicated `_scheduleAutoSave()` implementations across all editor BLoCs.
- **ExportManager**: Centralized export pipeline with format codec registry, MIME type resolution, and extension-based format detection. Supports pluggable `FormatCodec<T>` implementations.
- **ImportManager**: Unified import pipeline with file picking abstraction, format auto-detection, and parser dispatch via ExportManager's codec registry. Includes preset filters for documents, spreadsheets, presentations, images, and PDFs.
- **BackgroundTaskManager**: Async task queue with progress tracking (0-100%), cancellation tokens, and status stream for UI updates. Designed for long-running operations (file imports, exports, image processing).
- **FileFormatRegistry**: Central registry mapping file extensions and MIME types to format metadata. Initialized with 15+ format entries at app startup. Provides category-filtered format lists for UI dropdowns.
- **ContextMenuBuilder**: Reusable context menu framework with consistent styling, keyboard shortcut display, nested menus, destructive action styling, and preset item collections for text editing and file operations.
- **ImageProcessor**: Real image processing engine using `dart:ui` canvas rendering. Applies brightness, contrast, saturation, rotation, flip, crop, and resize to actual pixel data. Produces PNG byte output.
- **CsvCodec / TsvCodec**: Robust CSV/TSV codec for spreadsheet import/export with proper field quoting, escape handling, multi-line field support, and configurable delimiters.

### Added — Sprint 2: Spreadsheet Completion
- **CSV Import**: `ImportCsv` event parses CSV bytes into SheetData cells with automatic type detection (number vs text), auto-sizing grid dimensions, and DAO persistence.
- **CSV Export**: `ExportCsvFile` event converts current sheet to CSV bytes via CsvCodec.
- **Fill Handle**: `FillRange` event supports numeric sequence fill (auto-increment) and text fill (copy) across a target range.

### Added — Sprint 3: Presentation Editor
- **RotateElement**: Applies rotation delta to any slide element with modular arithmetic.
- **AlignElements**: Supports left/center/right/top/middle/bottom alignment of multiple selected elements using bounding box calculation.
- **DuplicateElement**: Clones an element with 2% positional offset and unique ID.
- **GroupElements / UngroupElements**: Assigns/clears shared `groupId` for multi-element grouping.
- **SlideElement Model**: Added `groupId` (String?) and `opacity` (double) fields with full serialization support. Added `id` parameter to `copyWith` for duplication.

### Added — Sprint 6: PDF Module
- **Annotation Persistence**: Wired `PdfAnnotationDao` into `PdfViewerBloc` for SQLite-based annotation persistence. Annotations auto-load on PDF open and auto-save on add/remove/update.
- **Annotation Mode Toggle**: `ToggleAnnotationMode` event cycles through highlight/underline/note/freehand/none modes.
- **UpdateAnnotation Event**: Allows modifying existing annotations in place.
- **currentPageAnnotations Helper**: State getter filtering annotations for the active page.
- **SetPageRange Fix**: Previously empty method body now stores start/end page for extract/split operations.

### Fixed — Sprint 2: Spreadsheet Web Interactivity
- **Focus Management**: Added explicit `FocusNode` for the grid (`_gridFocusNode`) and formula bar (`_formulaFocusNode`). Grid now properly regains focus after cell tap, ensuring keyboard events (arrow keys, Enter, Tab, Delete, Ctrl+shortcuts) work on Web.
- **Keyboard Handling**: Extended `_handleKeyEvent` to also respond to `KeyRepeatEvent` (not just `KeyDownEvent`), fixing held-key navigation on Web.
- **Right-Click Context Menu**: Replaced `onSecondaryTapDown` (unreliable on Web) with `Listener.onPointerDown` checking `event.buttons == 2` to intercept right-clicks before the browser context menu.
- **Formula Bar Focus Return**: After submitting a value in the formula bar, focus automatically returns to the grid for continued keyboard navigation.
- **_isEditingActive()**: Now checks the formula bar's specific FocusNode first and distinguishes grid focus from cell editor focus, fixing false-positive detection on Web.

### Fixed — Sprint 5: Image Editor Critical Bugs
- **CropImage Handler**: The `CropImage` event class existed since Sprint 1 but was **never registered** in the BLoC constructor. Now fully implemented with crop rectangle storage and dimension updates.
- **Real Export**: Replaced fake `Future.delayed(500ms)` export with actual `ImageProcessor.renderWithAdjustments()` that applies all adjustments (brightness, contrast, saturation, rotation, flip, crop, resize) to pixel data and produces real PNG bytes.
- **SetHue / SetExposure Events**: New adjustment events for hue (-180 to 180) and exposure (-1.0 to 1.0).
- **Real Dimension Detection**: `LoadImage` now decodes the image to detect actual width/height instead of hardcoding 1920x1080.
- **exportedBytes State**: Added `exportedBytes` field to state for downstream file saving/sharing.

### Changed
- **AppModule DI**: Now initializes `FileFormatRegistry` with default formats and registers CSV/TSV codecs with `ExportManager` at startup. Added `pdfViewerBloc` getter (with `PdfAnnotationDao` injection) and `imageEditorBloc` getter.
- **Core barrel file**: Exports all new Sprint 1 services, CSV codec, and ImageProcessor.
- Version bumped to 1.5.0+6

## [1.3.2+5] - 2026-07-13

### Added
- **PDF Text Searcher & Highlights**: Integrated `PdfTextSearcher` with the PDF view renderer `pagePaintCallbacks` to display real-time text query matches and highlight them on pages.
- **PDF Left Page Thumbnail Sidebar**: Added a collapsible thumbnail sidebar to PDF page viewer utilizing `PdfDocumentViewBuilder.file` and `PdfPageView` to allow page previews and direct click-to-navigation.
- **Slides Inline Text Field**: Added a text input field inside the contextual `_ElementFormatBar` when a text box is selected in Slides editor, letting users update element content in real-time.
- **Slides Image File Uploads**: Integrated local image selection using `FilePicker` and base64 encoding to data URLs inside Slides formatting bar, enabling users to upload and preview local image files.
- **Slides Image Canvas Rendering**: Added canvas image support in `_CanvasElement` to load and display base64 data URLs, local files, and network URLs with a broken image fallback.

### Fixed
- **Spreadsheet Keyboard & Input Focus**: Replaced the global keyboard shortcut interception with a custom `Focus.onKeyEvent` dispatcher that bubbles key presses when a text input is focused. This restores cell and formula bar editing, cursor navigation, delete, enter, and tab behaviors.
- **Spreadsheet Formula Bar real-time Sync**: Added an `onChanged` listener to the formula bar's `TextField` for real-time cell updates, and guarded the BLoC listener's controller assignment to prevent cursor jumping while typing.
- **Documents Formatting Toolbar**: Passed the editing controller to the `_FormattingToolbar` widget and implemented text selection wrapper and prefix formatting helpers in the UI.

### Changed
- Version bumped to 1.3.2+5
- PDF Page Viewer `_ViewerContent` converted to a stateful widget to maintain controller, search, and UI state.
- Removed unused `dispose` calls on `PdfViewerController` in PDF viewer page.

## [1.3.1+4] - 2026-07-12

### Added
- **Conditional Database Initialization**: Added `sqflite_common_ffi` and `sqflite_common_ffi_web` to support running the SQLite layer on the Web (via IndexedDB persistent Wasm factory) and Desktop (via FFI). This resolves the `databaseFactory not initialized` error.
- **Full-Fidelity Canvas Rendering**: Enabled the image editor to load, display, and tweak real image files (via `Image.memory` and raw bytes extraction) in a cross-platform way, replacing the placeholder gray boxes.
- **End-To-End Document Import**: Connected the file pickers in the Spreadsheet, Document, and Presentation list pages to automatically parse the files, insert records into SQLite database tables, and redirect the user directly to the workspace editors.

### Changed
- Version bumped to 1.3.1+4
- PresentationListPage converted to StatefulWidget to manage creation and redirection states.

## [1.3.0+3] - 2026-07-11

### Added
- **Premium UI/UX Design**:
  - Staggered entrance animations (fade-in & slide-up) for module cards
  - Elevation & hover zoom transformations (1.02x scale) on desktop
  - Left accent border gradient stripes custom-themed by module
  - Vector navigation arrows appearing dynamically on hover
  - Full modular Grid layouts support for all 8 application modules
  - Navigation page switching transitions using `AnimatedSwitcher` inside navigation shell
- **Comprehensive BLoC Test Coverage**:
  - Added `spreadsheet_bloc_test.dart` (20+ tests covering Load, Search, Create, Open, Cell editing, Formula calculation, Sheets, Save/Delete, FrozenPanes)
  - Added `document_editor_bloc_test.dart` (15+ tests covering Load, Search, Create, Open, Content updates, Save, Delete, Toolbar, Undo/Redo)
  - Added `presentation_bloc_test.dart` (18+ tests covering Load, Create, Open, Slide operations, Canvas element CRUD, Save/Delete)
  - Added `pdf_viewer_bloc_test.dart` (12+ tests covering Load, Navigation range bounds, Zoom clamping, Sidebar toggle, Annotations CRUD, Rotation accumulation)
  - Added `text_editor_bloc_test.dart` (10+ tests covering Load, Create, Updates, Save, Search matches, Single/Global replace actions)
  - All 134 test suites pass successfully on local system and inside Docker context
- **CI/CD Hardening**:
  - Dependency caching via `actions/cache` across ubuntu and windows GitHub runners
  - Coverage-enabled package-level unit tests for foundational core libraries
  - New Native Windows target compilation check jobs

### Fixed
- **Deselection State Clearance**: Corrected copyWith null-coalescing issue in BLoC state; Presentation elements and highlights can now be fully deselected to null when clicking off-canvas

### Changed
- **Autosave & Search Performance**: Debounced search events via `restartable()` event transformers in BLoCs to reduce database queries while typing
- **Default Spreadsheet Row Limit**: Reduced default worksheet size from 100 to 50 rows for much faster creation and document loading performance
- Version bumped to 1.3.0+3

### Dependencies
- Added `bloc_concurrency: ^0.3.0` for stream transformers

## [1.2.0+2] - 2026-07-11

### Added
- **PDF real rendering**: Replaced placeholder gray box with pdfrx PdfViewer widget for actual PDF page rendering across all platforms
- **CSV export**: Spreadsheet data can now be exported as CSV via share_plus
- **Share across all modules**: Notes, Documents, Spreadsheets, Presentations, and PDF all have Share buttons
- **Open File in all list pages**: Documents, Spreadsheets, and Presentations list pages now have "Open File" button via file_picker for browsing existing files
- **Save feedback**: All editors (Notes, Documents, Spreadsheets, Presentations) now show "Saved ✓" SnackBar on successful save

### Fixed
- **Spreadsheet double-creation**: Added `_isCreating` debounce guard to prevent creating multiple spreadsheets when clicking FAB rapidly
- **Document double-creation**: Added `_isCreating` debounce guard to prevent creating multiple documents
- **Navigation after create**: Spreadsheet and Document creation now navigates directly to the editor after creation via BlocListener
- **PDF viewer blank page**: PdfViewerBloc no longer hardcodes `totalPages: 1`; uses pdfrx callback to set real page count

### Changed
- Version bumped to 1.2.0+2
- PdfViewerBloc: added SetTotalPages and ClosePdf events, uses pdfrx for rendering
- SpreadsheetListPage: converted to StatefulWidget with creation guard
- DocumentListPage: converted to StatefulWidget with creation guard
- PresentationEditorPage: BlocBuilder → BlocConsumer for save feedback
- DocumentEditorPage: BlocConsumer listener enhanced for save feedback

### Dependencies
- Added `pdfrx: ^1.0.0` — cross-platform PDF rendering
- Added `csv: ^6.0.0` — CSV serialization/deserialization

## [1.1.0] - 2026-07-11

### Fixed
- **Database crash on Android**: `PRAGMA journal_mode = WAL` now uses `rawQuery()` instead of `execute()` which crashed on sqflite native driver
- **GoRouter navigation**: Document and Spreadsheet list pages now use `context.go()` instead of `Navigator.pushNamed()` which didn't work with GoRouter
- **Image Editor layout crash on mobile**: Replaced fixed 3-column Row with responsive layout (vertical on mobile, horizontal on desktop)
- **PDF Viewer thumbnail sidebar**: Hidden on mobile to prevent layout overflow

### Changed
- **Navigation redesigned**: Bottom nav reduced from 10 to 5 items on mobile (Home, Notes, Docs, Tools, Settings). Desktop retains full 10-item sidebar
- **Home page**: Removed all "Coming Soon" placeholders — Documents, Spreadsheets, and PDF now navigate to their working feature pages
- **Image Editor**: "Open Image" button now opens system file picker via `file_picker` package
- **PDF Viewer**: "Open PDF" button now opens system file picker for PDF files

### Added
- 54 unit tests across 5 test files:
  - `notes_bloc_test.dart` (13 tests)
  - `file_manager_bloc_test.dart` (9 tests)
  - `image_editor_bloc_test.dart` (15 tests)
  - `settings_bloc_test.dart` (11 tests)
  - `app_test.dart` (6 smoke tests)
- Model tests for NoteEntity and RecentFileEntity (fromMap, toMap, roundtrip, copyWith)
- Mobile tool bar widget for Image Editor responsive layout
- `_MobileToolBar` horizontal chip-based tool selector

### CI/CD
- Cloudflare Pages project auto-creation (`wrangler pages project create`)
- Node.js 22 via `setup-node@v4` (fixes deprecation warning)
- Direct Wrangler v3 install replaces deprecated `wrangler-action@v3`
- Consolidated `flutter pub get` with for-loop across all packages

## [1.0.0] - 2026-07-08

### Added

#### Architecture & Infrastructure
- Monorepo structure with 4 shared packages and 1 app
- Clean Architecture with BLoC pattern, Result monad, DI via get_it
- Material 3 theming with custom color palette (dark/light/system)
- Responsive layout system (mobile/tablet/desktop)
- SQLite database with WAL mode, indexes, and migration support
- GitHub Actions CI/CD (analyze, test, build, deploy)
- Docker configuration for development, testing, and builds
- PWA manifest with branded loading screen
- Setup scripts for Linux/macOS and Windows

#### Notes Module
- Create, read, update, delete notes
- Plain text, Markdown, Rich text, and Checklist content types
- Pin and favorite notes
- Search notes by title and content
- Grid layout with pinned/unpinned sections
- Note color tags
- Content preview on cards
- Autosave with timer

#### File Manager Module
- Recent files tracking with auto-trim
- Favorite files
- Search files by name
- List and grid view modes
- File type detection with colored icons
- File metadata display (type, size, timestamp)
- Clear recents (preserving favorites)

#### Text Editor Module
- Plain text and Markdown editing
- Markdown preview mode
- Find & Replace with match count
- Replace and Replace All
- Word, character, and line count
- Autosave with timer
- Configurable font size from settings
- Document title editing

#### Settings
- Theme mode (system/light/dark)
- Editor font size (10-24px)
- Line numbers toggle
- Word wrap toggle
- Autosave enable/disable
- Autosave interval selection
- About section with version and license

#### Documentation
- README with setup guide and architecture overview
- ARCHITECTURE.md with layer diagrams and design decisions
- IMPLEMENTATION.md with full completion checklist
- FEATURE_MATRIX.md with platform and feature status
- PROJECT_STATUS.md with sprint metrics
- CHANGELOG.md (this file)
- DEPLOYMENT.md with Cloudflare Pages setup
- SECURITY.md with security policies
- CONTRIBUTING.md with contribution guide
- MIT License

## [1.1.0] - 2026-07-09

### Added

#### Rich Document Editor (Sprint 2)
- WYSIWYG formatting toolbar (bold, italic, underline, strikethrough, headings, lists, quote, code, link)
- Document persistence (DocumentDao + DocumentEntity + DB v2 migration)
- Keyboard shortcuts framework (KeyboardShortcutService)
- Document CRUD (create, open, save, delete, duplicate)
- Undo/Redo with history stack
- Autosave with configurable delay
- Document search and favorites
- Word/character count status bar
- Document statistics dialog

#### Spreadsheet (Sprint 3)
- Custom grid widget with virtual scrolling
- Cell editing (text, number, date, formula)
- Formula engine with 60+ functions (math, stats, text, date, logical, financial)
- Formula bar with function autocomplete
- Sheet tabs (multi-sheet workbooks)
- Column/row sorting
- Spreadsheet persistence (SpreadsheetDao + SpreadsheetEntity + DB v3)
- Spreadsheet CRUD (create, open, save, delete, duplicate, favorites)

#### Presentation (Sprint 4)
- Slide canvas with drag-to-move/resize elements
- Text boxes and shapes (rectangle, circle, triangle, arrow)
- Speaker notes panel
- Full-screen presentation mode with keyboard navigation
- Slide transitions (none, fade, slide, zoom)
- Slide panel with thumbnails, duplicate/delete slides
- Presentation persistence (PresentationDao + PresentationEntity + DB v4)
- Presentation CRUD (create, open, save, delete, duplicate, favorites)

#### PDF Viewer (Sprint 5)
- PDF viewer page with interactive canvas
- Page navigation (prev/next/go-to-page)
- Thumbnails sidebar with page previews
- Zoom controls (25%–500%)
- Text search dialog
- Annotation tools (highlight, underline, sticky note, freehand)
- Annotation overlay rendering
- Page rotation

#### Image Editor (Sprint 6)
- Image viewing with InteractiveViewer (zoom/pan)
- Tool sidebar (Adjust, Crop, Rotate, Resize)
- Adjustment sliders (brightness, contrast, saturation)
- Rotate (90°, -90°, free rotation slider)
- Flip horizontal/vertical
- Crop presets (free, 16:9, 4:3, 1:1)
- Resize presets (50%, 75%, 1080p, 720p)
- Full undo/redo stack with reset
- Color matrix rendering pipeline
- Export to PNG/JPEG/WebP
- Status bar with image info and edit state

## [1.2.0] - 2026-07-10

### Added

#### Accessibility & High Contrast (Sprint 7)
- WCAG AAA compliant high contrast light theme (7:1 contrast ratio)
- WCAG AAA compliant high contrast dark theme
- High contrast mode toggle in Settings > Accessibility
- Bold text weight across all styles in high contrast mode
- Thick borders (2px) and large focus indicators (3px) in high contrast themes
- Semantic color palette (hcPrimary, hcError, hcSuccess, hcWarning)

#### Localization (Sprint 7)
- Language selector dialog in Settings > Accessibility
- 10 supported locales wired to MaterialApp (en-US, en-GB, es, fr, de, ja, zh-CN, ko, pt-BR, hi)
- Persisted locale preference via PreferencesService
- Locale switching takes effect immediately without restart

#### Version History (Sprint 7)
- VersionEntity model with content snapshots, version numbering, labels
- VersionDao with full CRUD (create, list, get, delete, prune)
- document_versions table (DB v5 migration)
- Version count and storage tracking
- Auto-pruning to keep latest N versions
- Registered in DI module

#### Security (Sprint 7)
- InputSanitizer utility class with real protection against:
  - Cross-Site Scripting (XSS): script tag removal, event handler stripping, javascript: URI blocking
  - SQL injection: LIKE wildcard escaping for search queries
  - Path traversal: reject .., absolute paths, null bytes
  - Content validation: max length enforcement, control character removal
- HTML entity encoding for safe output rendering
- File name validation (Windows reserved names, dangerous characters)
- Comprehensive security test suite (input_sanitizer_test.dart)

#### Testing (Sprint 7)
- Formula engine test suite (arithmetic, math/text/logical functions, cell references, edge cases)
- Input sanitizer test suite (XSS, SQL injection, path traversal, file names, content validation)
- Existing core tests preserved and passing

### Changed
- Settings BLoC: added ToggleHighContrast and ChangeLocale events
- Settings state: added highContrastMode and localeCode fields
- App root: theme switches between standard and high contrast based on setting
- App root: locale driven by settings with all 10 supported locales
- Database version bumped from 4 to 5 (document_versions migration)
- Navigation: 10-tab sidebar (Home, Notes, Documents, Sheets, Slides, PDF, Images, Files, Editor, Settings)
