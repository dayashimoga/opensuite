# OpenSuite Implementation Status

## Sprint 24 — Streamlined Single Menubar & Quick Formatting Toolbar (v2.5.0+19) ✅

### Verification Results
| Check | Status |
|-------|--------|
| `flutter analyze` | ✅ 0 issues |
| `dart format` | ✅ 0 files changed |
| `flutter test test/features/spreadsheet` | ✅ 38/38 passed |
| `flutter build web --release` | ✅ Built (`build/web` updated) |

### Key Improvements
- Eliminated redundant second tab row (`Home`, `Insert`, `Data`, `View`) underneath top Menubar
- Created unified Google Sheets / MS Excel top architecture: Top Menubar + Single-row Quick Action Formatting Bar
- Maximized vertical grid display area

## Sprint 23 — Presentation Engine & Spreadsheet Desktop Menubar (v2.4.0+18) ✅

### Verification Results
| Check | Status |
|-------|--------|
| `flutter analyze` | ✅ 0 issues |
| `dart format` | ✅ 0 files changed |
| `flutter test test/features/presentation` | ✅ 38/38 passed |
| `flutter test test/features/spreadsheet` | ✅ 38/38 passed |
| `flutter build web --release` | ✅ Built (`build/web` updated) |

### Features Completed
- Presentation Add Slide crash fix (`insertIndex` clamped safely)
- Presenter Mode fullscreen slideshow viewer with timer & keyboard controls
- Slide thumbnail drag-and-drop reordering with `ReorderableListView.builder`
- Speaker notes text panel
- Shape, table, chart, and icon element tools
- Google Sheets / MS Excel style Menubar (`File`, `Edit`, `View`, `Insert`, `Format`, `Data`, `Tools`, `Help`)

## Sprint 22 — Spreadsheet Engine & UI Enhancements (v2.3.0+17) ✅

### Verification Results
| Check | Status |
|-------|--------|
| `flutter analyze` | ✅ 0 issues |
| `dart format` | ✅ 0 files changed |
| `flutter test test/features/spreadsheet` | ✅ 38/38 passed |
| `flutter build web --release` | ✅ Built (`build/web` updated) |

### Features Completed
- Multi-cell drag selection with grid-level pointer Listener
- Shift + Click range expansion & Shift + Arrow key range expansion
- Tab / Shift+Tab and Enter / Shift+Enter cell navigation
- Insert Row Above / Below, Insert Column Left / Right, Delete Row / Column
- Table Creation & Zebra Striping with Grid Borders
- Multi-Cell, Range, Row, and Column formatting & background coloring

## Sprint 21 — Platform & Build Foundation (v2.2.0+16) ✅

### Build Environment
- **Flutter SDK**: 3.44.6 (Dart 3.12.2)
- **CI/CD**: GitHub Actions 7 jobs (analyze, test, build-web, build-android, build-linux, build-windows, build-ios)
- **Docker**: instrumentisto/flutter:3.44

### Verification Results
| Check | Status |
|-------|--------|
| `flutter analyze` | ✅ 0 issues |
| `dart format` | ✅ 0 files changed |
| `flutter test` | ✅ 240/240 passed |
| `flutter build web --release` | ✅ Built |
| `flutter build apk` | ⏳ CI-only (no Android SDK locally) |
| `flutter build windows` | ⏳ CI-only (no Visual Studio locally) |
| `flutter build linux` | ⏳ CI-only (Linux runner) |
| `flutter build ios` | ⏳ CI-only (macOS runner) |

### Key Fixes
- Resolved `flutter_quill` ^10.8.5 → ^11.5.1 (`intl` conflict, `quill_native_bridge_windows` GMEM_MOVEABLE)
- Fixed 22 deprecated API usages for Flutter 3.44 compatibility
- iOS project auto-generation in CI pipeline
- Developer Mode enablement for Windows CI builds

---

## Architectural Root Cause Analysis & Permanent System Fixes (v1.6.1+8) 🚀

### Root Causes Identified & Permanently Resolved

1. **State Management & UI Controller Decoupling**:
   - **Fix**: Replaced raw DAO calls and direct state mutations in `NoteEditorPage` with proper `BlocProvider<NotesBloc>` scoping and standard event dispatch.
   - **Fix**: Fixed key handling routing in `SpreadsheetEditorPage` to automatically stream printable keyboard characters to active selected cells and focus formula input node seamlessly.
   - **Fix**: Interactive canvas resize handles in `PresentationEditorPage` now bind `onPanUpdate` directly to `ResizeElement` events.
   - **Fix**: Wired `FileManagerBloc` `SortFiles` and `RenameFile` events to UI sort popup menus and interactive file tile rename dialogs.

---

## Sprint 13 — Architecture Overhaul & Gap Closure (v1.5.0) 🔧

### Shared Services Created (packages/core)

#### SaveManager<T> (`services/save_manager.dart`)
- Generic auto-save with configurable debounce (default 5s)
- Dirty-state tracking, manual save, dispose cleanup
- Replaces 5 duplicated `_scheduleAutoSave()` + `Timer` patterns

#### ExportManager (`services/export_manager.dart`)
- Singleton export pipeline with `FormatCodec<T>` registry
- `registerCodec()` / `encode()` / `decode()` API
- Extension-based format detection via `formatFromExtension()`
- Defines `ExportFormat` enum (17 formats: txt, md, html, docx, csv, tsv, xlsx, pptx, pdf, png, jpeg, webp, svg, tiff, bmp, json, xml)

#### ImportManager (`services/import_manager.dart`)
- Unified import with `file_picker` integration
- Preset file type filters (documents, spreadsheets, presentations, images, PDFs)
- Format auto-detection from extension
- Parser dispatch via ExportManager's codec registry

#### BackgroundTaskManager (`services/background_task_manager.dart`)
- Singleton async task queue
- `BackgroundTask<T>` with status (pending/running/completed/failed/cancelled)
- Progress tracking (0.0–1.0), cancellation tokens
- `taskUpdates` stream for UI progress bars
- Used for file imports, exports, image processing

#### FileFormatRegistry (`services/file_format_registry.dart`)
- Maps extensions + MIME types → `FileFormatEntry` metadata
- 15+ formats registered at startup via `initializeDefaults()`
- Category filtering (document/spreadsheet/presentation/image/pdf)
- Import/export capability flags per format
- Extension alias resolution (jpg→jpeg, htm→html, md→markdown)

#### ContextMenuBuilder (`services/context_menu_builder.dart`)
- Static `show()` method with position, items, max-width
- `ContextMenuItem` with id, label, icon, shortcut, destructive flag, children
- Preset builders: `textEditingItems()`, `fileOperationItems()`
- Theme-aware styling (destructive = error color)

#### ImageProcessor (`imaging/image_processor.dart`)
- `buildColorMatrix()` — 5x4 color matrix for brightness/contrast/saturation
- `decodeImage()` — Uint8List → dart:ui Image
- `renderWithAdjustments()` — full pipeline: decode → canvas → transform → encode PNG
- Supports: brightness, contrast, saturation, rotation, flip, crop, resize
- Replaces fake `Future.delayed(500ms)` export

#### CsvCodec / TsvCodec (`formats/csv_codec.dart`)
- Implements `FormatCodec<List<List<String>>>`
- RFC 4180-compliant parsing (quoted fields, escaped quotes, multi-line)
- Configurable delimiter, qualifier, line separator
- TsvCodec extends CsvCodec with `\t` delimiter

### Critical Bug Fixes

#### Image Editor — CropImage Handler Missing
- **Root Cause**: `CropImage` event class was defined but `on<CropImage>()` was never called in constructor
- **Fix**: Registered handler, implemented crop rect storage, dimension updates

#### Image Editor — Fake Export
- **Root Cause**: `_onExport()` used `Future.delayed(500ms)` instead of real processing
- **Fix**: Replaced with `ImageProcessor.renderWithAdjustments()` producing real PNG bytes
- Added `exportedBytes` to state for downstream saving

#### Image Editor — Hardcoded Dimensions
- **Root Cause**: `LoadImage` always set 1920x1080 regardless of actual image
- **Fix**: Decodes image to detect real width/height

#### PDF Viewer — Empty SetPageRange
- **Root Cause**: `_onSetPageRange()` had empty method body
- **Fix**: Now stores clamped start/end page for extract/split operations

#### PDF Viewer — No Annotation Persistence
- **Root Cause**: `PdfAnnotationDao` existed but was never wired into `PdfViewerBloc`
- **Fix**: Wired via `AppModule`, auto-load on open, auto-save on add/remove/update

#### Spreadsheet — Web Interactivity Broken
- **Root Cause**: Multiple focus management issues specific to Flutter Web
- **Fixes**:
  1. Added `_gridFocusNode` and `_formulaFocusNode` for explicit focus control
  2. `onCellTap` now calls `_gridFocusNode.requestFocus()` to ensure keyboard events work
  3. `_handleKeyEvent` accepts `KeyRepeatEvent` (not just `KeyDownEvent`)
  4. `_isEditingActive()` checks formula bar FocusNode specifically
  5. Replaced `onSecondaryTapDown` with `Listener.onPointerDown` for right-click
  6. Formula bar returns focus to grid after submit

### Presentation Editor Additions
- `RotateElement`: rotation delta with modular arithmetic
- `AlignElements`: 6-mode alignment (left/center/right/top/middle/bottom)
- `DuplicateElement`: clone with offset + unique ID
- `GroupElements` / `UngroupElements`: shared groupId assignment/clearing
- `SlideElement` model: added `groupId`, `opacity`, `id` in `copyWith`

### AppModule DI Updates
- Registers `PdfAnnotationDao` as lazy singleton
- Initializes `FileFormatRegistry.instance.initializeDefaults()` at startup
- Registers `CsvCodec` and `TsvCodec` with `ExportManager`
- Added `pdfViewerBloc` getter (with `PdfAnnotationDao` injection)
- Added `imageEditorBloc` getter


## Sprint 1 — Foundation & Core Modules ✅

### Completed

#### Monorepo Structure
- [x] Root configuration (analysis_options, melos, .gitignore)
- [x] Package directory structure (core, storage, ui_kit, l10n)
- [x] App directory structure (apps/opensuite)
- [x] Docker configuration
- [x] CI/CD pipelines (GitHub Actions)
- [x] Setup scripts (bash + PowerShell)

#### packages/core
- [x] AppConfig with environment-aware settings
- [x] EnvironmentConfig manager
- [x] FeatureFlags for module toggles
- [x] ServiceLocator (get_it-based DI)
- [x] AppError with error codes (Equatable)
- [x] ErrorHandler with centralized logging
- [x] Result<T> sealed union for functional error handling
- [x] AppLogger wrapping logger package
- [x] FileType enum with extension/MIME detection
- [x] DocumentMetadata model
- [x] AppDateUtils (formatting, relative time)
- [x] FileUtils (extension, validation, sanitization)
- [x] StringUtils (truncate, word count, slug)
- [x] AppConstants (centralized magic values)

#### packages/storage
- [x] DatabaseProvider with SQLite setup and WAL mode
- [x] Schema: notes, recent_files, text_documents tables with indexes
- [x] NoteEntity with serialization and content type enum
- [x] RecentFileEntity with serialization
- [x] NoteDao — full CRUD, search, pin, favorite, count
- [x] RecentFileDao — record opened, favorites, search, auto-trim
- [x] PreferencesService — typed key-value storage in SQLite
- [x] PreferenceKeys constants
- [x] FileStorageService — read/write/copy/move/delete/list

#### packages/ui_kit
- [x] AppColors — curated HSL-derived palette (light + dark)
- [x] AppTypography — Inter + JetBrains Mono type scale
- [x] AppSpacing — 4-point grid spacing constants
- [x] AppTheme — Full Material 3 light and dark themes
- [x] ScreenSize enum with breakpoint detection
- [x] ResponsiveBuilder — adaptive layout widget
- [x] ResponsiveVisibility — conditional display by screen size
- [x] AppScaffold — responsive scaffold (sidebar/bottom nav)
- [x] SidebarNavigation — desktop nav with compact mode
- [x] EmptyState — reusable empty state placeholder
- [x] AppSearchBar — styled search with debounce
- [x] AppLoadingIndicator — loading spinner with message
- [x] ConfirmationDialog — destructive action confirmation

#### packages/l10n
- [x] SupportedLocales (10 languages configured)
- [x] AppLocalizations — 100+ UI strings organized by feature

#### apps/opensuite
- [x] main.dart — initialization sequence
- [x] app.dart — MaterialApp.router with theme/routing
- [x] AppModule — DI registration for all services and BLoC factories
- [x] AppRouter — GoRouter with ShellRoute and nested feature routes
- [x] ShellPage — responsive navigation shell

#### Feature: Home
- [x] Dashboard with welcome header
- [x] Quick action chips (new note, new document, browse)
- [x] Module cards grid with descriptions and "coming soon" badges

#### Feature: Notes
- [x] NotesBloc — load, search, create, update, delete, pin, favorite
- [x] NotesPage — grid layout with pinned/unpinned sections, search, FAB
- [x] NoteCard — color, pin indicator, content type badge, preview, timestamp
- [x] NotePopupMenu — pin, favorite, delete with confirmation
- [x] NoteEditorPage — title + content editing, content type selector
- [x] Autosave timer, word count status bar, modified indicator

#### Feature: File Manager
- [x] FileManagerBloc — recent files, favorites, search, view modes
- [x] FileManagerPage — list/grid toggle, recent/favorites tabs, search
- [x] FileListTile — icon, metadata, favorite toggle, context menu
- [x] FileGridCard — icon-centric card view
- [x] Clear recents with confirmation (preserves favorites)

#### Feature: Text Editor
- [x] TextEditorBloc — document CRUD, content tracking, find/replace, preview toggle
- [x] DocumentListPage — document list with empty state
- [x] TextEditorPage — full editor with toolbar and status bar
- [x] Title editing in app bar
- [x] Text/Markdown mode toggle
- [x] Markdown preview toggle
- [x] Find & Replace bar with match count
- [x] Replace / Replace All
- [x] Status bar (file type, lines, words, chars, save state)
- [x] Autosave timer
- [x] Font size from settings

#### Feature: Settings
- [x] SettingsBloc — persisted theme, font size, line numbers, word wrap, autosave
- [x] SettingsPage — appearance, editor, autosave, about sections
- [x] Theme selector (system/light/dark segmented button)
- [x] Font size slider
- [x] Autosave interval dropdown
- [x] App info with version and repository link

#### Infrastructure
- [x] Dockerfile with Flutter SDK
- [x] docker-compose.yml — dev, test, lint, format, build services
- [x] GitHub Actions CI — analyze, test, build (web/android/linux), deploy
- [x] PWA manifest and branded loading screen
- [x] Setup scripts for Linux/macOS and Windows

#### Documentation
- [x] README.md
- [x] ARCHITECTURE.md
- [x] IMPLEMENTATION.md (this file)
- [x] LICENSE (MIT)

---

## Sprint 2 — Rich Document Editor ✅

- [x] DocumentMetadata model
- [x] DocumentEntity with serialization
- [x] DocumentDao (CRUD, search, favorites, word count)
- [x] DB v2 migration (documents table with indexes)
- [x] DocumentEditorBloc (CRUD, autosave, undo/redo, formatting, search/replace)
- [x] RichDocumentListPage (grid layout, search, favorites, empty state)
- [x] RichDocumentEditorPage (WYSIWYG toolbar: bold/italic/underline/strikethrough/headings/lists/quote/code/link)
- [x] Word/character count status bar
- [x] Document statistics dialog
- [x] DI registration, router integration, shell navigation

---

## Sprint 3 — Spreadsheet ✅

- [x] SpreadsheetModels (CellData, SheetData, CellPosition, CellStyle)
- [x] FormulaEngine (60+ functions: SUM, AVERAGE, MIN, MAX, COUNT, ROUND, ABS, SQRT, POWER, PI, LEN, UPPER, LOWER, TRIM, CONCATENATE, LEFT, RIGHT, MID, IF, AND, OR, NOT, MEDIAN, and more)
- [x] SpreadsheetEntity with JSON serialization
- [x] SpreadsheetDao (CRUD, search, favorites)
- [x] DB v3 migration (spreadsheets table)
- [x] SpreadsheetBloc (CRUD, cell editing, formula evaluation, sorting, autosave, multi-sheet)
- [x] SpreadsheetListPage (grid view, search, favorites, empty state)
- [x] SpreadsheetEditorPage (grid, formula bar, sheet tabs, column headers)
- [x] DI registration, router integration, shell navigation

---

## Sprint 4 — Presentation ✅

- [x] SlideElement and SlideData models with JSON serialization
- [x] PresentationEntity with slide count tracking
- [x] PresentationDao (CRUD, search, favorites)
- [x] DB v4 migration (presentations table)
- [x] PresentationBloc (slide management, element positioning, speaker notes, transitions)
- [x] PresentationListPage (grid, search, favorites, duplicate)
- [x] PresentationEditorPage (canvas, slide panel, speaker notes, shape tools)
- [x] Full-screen presentation mode (keyboard: arrows, space, escape)
- [x] Slide transitions (none, fade, slide, zoom)
- [x] Element drag-to-move and resize
- [x] DI registration, router integration, shell navigation

---

## Sprint 5 — PDF Viewer ✅

- [x] PdfViewerBloc (page nav, zoom, thumbnails, annotations, rotation, search, page range)
- [x] PdfAnnotation model (highlight, underline, note, freehand with stroke points)
- [x] PdfViewerPage (canvas, toolbar, thumbnail sidebar, annotation overlay, page nav bar)
- [x] Zoom controls (25%–500% with interactive viewer)
- [x] Annotation tools popup (highlight, underline, sticky note, freehand draw)
- [x] Text search dialog
- [x] Page rotation
- [x] Router integration, shell navigation (PDF tab)

---

## Sprint 6 — Image Editor ✅

- [x] ImageEditorBloc (adjustments, rotate, flip, resize, undo/redo, export)
- [x] ImageAdjustments model (brightness, contrast, saturation, rotation, flip)
- [x] ImageEditorPage (canvas, tool sidebar, adjustments panel, status bar)
- [x] InteractiveViewer with zoom/pan
- [x] Color matrix rendering pipeline (brightness/contrast/saturation)
- [x] Tool sidebar (Adjust, Crop, Rotate, Resize)
- [x] Rotate (90°/-90°/free slider), flip H/V
- [x] Crop presets (free, 16:9, 4:3, 1:1)
- [x] Resize presets (50%, 75%, 1080p, 720p)
- [x] Full undo/redo stack with reset
- [x] Export to PNG/JPEG/WebP
- [x] Router integration, shell navigation (Images tab)

---

## Sprint 7 — Polish & Accessibility ✅

### Accessibility
- [x] WCAG AAA high contrast light theme (7:1 contrast ratio)
- [x] WCAG AAA high contrast dark theme
- [x] High contrast mode toggle (Settings > Accessibility)
- [x] Bold text weights in high contrast mode
- [x] Thick borders (2px) and focus indicators (3px)
- [x] Semantic high contrast color palette

### Localization
- [x] Language selector dialog (Settings > Accessibility)
- [x] 10 locales wired to MaterialApp
- [x] Persisted locale preference
- [x] Immediate locale switching

### Version History
- [x] VersionEntity model (content snapshots, version numbers, labels)
- [x] VersionDao (create, list, get, delete, prune, storage tracking)
- [x] document_versions table (DB v5 migration with indexes)
- [x] DI registration

### Security
- [x] InputSanitizer (XSS prevention, SQL injection protection, path traversal blocking)
- [x] HTML entity encoding
- [x] File name validation
- [x] Content size validation
- [x] Exported from core barrel

### Testing
- [x] Formula engine test suite (30+ test cases)
- [x] Input sanitizer test suite (20+ test cases)
- [x] Core test suite maintained (40+ test cases)

---

## Sprint 9 — Production Enhancement (v1.2.0) ✅

### PDF Viewer — Real Rendering
- [x] pdfrx dependency for cross-platform PDF rendering (Android, iOS, Web, Windows, Linux, macOS)
- [x] PdfViewerBloc refactored: SetTotalPages event from widget callback, ClosePdf event
- [x] PdfViewerPage rewritten with PdfViewer.file() widget for real page rendering
- [x] PDF file picker integration (Open PDF button)
- [x] PDF share via share_plus
- [x] Page navigation bar with go-to-page dialog
- [x] Zoom controls in AppBar

### Spreadsheet — Debounce & Share
- [x] Creation debounce guard (_isCreating flag) prevents duplicate creates
- [x] BlocListener navigates to editor after creation
- [x] Save feedback (SnackBar "Saved ✓")
- [x] Error feedback (SnackBar with error message)
- [x] csv dependency for CSV export
- [x] Export as CSV via share_plus
- [x] Share spreadsheet summary
- [x] Open File button (file_picker for xlsx/xls/csv/ods)
- [x] Loading indicator on FAB during creation

### Document Editor — Share & Feedback
- [x] Creation debounce guard prevents duplicate creates
- [x] BlocListener navigates to editor after creation
- [x] Save feedback (SnackBar "Saved ✓")
- [x] Export as TXT/Markdown via share_plus
- [x] Share document content
- [x] Open File button (file_picker for docx/doc/txt/md/rtf/odt)

### Presentation — Share & Feedback
- [x] BlocConsumer with save feedback (SnackBar "Saved ✓")
- [x] Share presentation summary via share_plus
- [x] Open File button (file_picker for pptx/ppt/odp)

### Notes — Share & Feedback
- [x] Save feedback (SnackBar "Saved ✓")
- [x] Share note (title + content) via share_plus

### Cross-Module
- [x] Version bumped to 1.2.0+2
- [x] All list pages have "Open File" button for browsing existing files
- [x] All editors have Share button
- [x] All save operations show visual confirmation

---

## Sprint 10 — Production Optimization & UI/UX (v1.3.0) ✅

### Performance & Event Debouncing
- [x] added `bloc_concurrency` dependency
- [x] `restartable()` transformer added on search events in `SpreadsheetBloc`, `DocumentEditorBloc`, and `NotesBloc` to debounce rapid typing queries
- [x] Default spreadsheet row count optimized from 100 to 50 for faster workbook initialization
- [x] Removed double state emission from `_onDeleteElement` in `PresentationBloc` and supported deselect/null via constructor emission

### UI/UX Design Enhancements
- [x] Reusable `AnimatedModuleCard` widget with:
  - Slide-up and fade-in staggered entrance animation (80ms cascade)
  - Desktop hover scale effect (1.02x zoom) and elevated drop-shadows
  - Accent-colored left border gradient stripe matching module theme
  - Clean vector arrow trailing navigation indicator on hover
- [x] Dashboards (Home Page) redesigned with:
  - Clean modular grid structure (4 columns on desktop, 2 on tablet/mobile)
  - Staggered animated cards for all 8 modules (Notes, Files, Text Editor, Documents, Spreadsheets, PDF, Presentations, Image Editor)
  - Quick action chips for New Note, New Document, New Sheet, New Slides, and Browse Files
  - Dynamic gradient-themed header greeting
- [x] Page navigation page-swaps optimized with smooth fade-in transitions using `AnimatedSwitcher` within `ShellPage` (for both mobile bottom navigation and desktop sidebar navigation)

### CI/CD Hardening
- [x] Caching of pub cache dependencies using `actions/cache` across both linux and windows runners
- [x] Run coverage-enabled unit test suites on both root package and app module level
- [x] Brand new `build-windows` jobs on GitHub actions runner to ensure native compile targets succeed

### Comprehensive Test Suite
- [x] Added `spreadsheet_bloc_test.dart` (Load, Search, Create, Open, Cell operations, Format, Sheet actions, Save, Delete, FrozenPanes)
- [x] Added `document_editor_bloc_test.dart` (Load, Search, Create, Open, Title/Content updates, Save cycle, Delete, Formatting, Toolbar toggles, Undo/Redo)
- [x] Added `presentation_bloc_test.dart` (Load, Create, Open, Slide management, Element actions, Save cycle)
- [x] Added `pdf_viewer_bloc_test.dart` (LoadPdf, Page navigation, Zoom clamps, Thumbnails toggle, Annotations add/remove, Page rotation accumulation)
- [x] Added `text_editor_bloc_test.dart` (Load, Create, Updates, Save to storage, Search matches, Single/All replace operations)
- [x] 100% test coverage pass for all 134 suite test cases

---

## Sprint 11 — Cross-Platform Production Hardening & Full-Fidelity UI (v1.3.1) ✅

### Web & Desktop SQLite Factory Support
- [x] Added `sqflite_common_ffi` and `sqflite_common_ffi_web` dependencies to `fileutility_storage`.
- [x] Implemented a conditionally imported `initializeDatabaseFactory()` configuration to seamlessly bootstrap the correct database factory:
  - `databaseFactoryFfiWeb` on Web browsers (IndexedDB persistent layer).
  - `sqfliteFfiInit` and `databaseFactoryFfi` on Desktop (Windows, Linux, macOS).
  - Standard native handler fallback on Mobile platforms.
- [x] Rebuilt Docker build environments to align test/lint/run dependencies.

### Full-Fidelity Image Canvas
- [x] Extended `ImageEditorBloc` to receive and store `imageBytes` (Uint8List).
- [x] Leveraged `XFile` from `cross_file` to read files asynchronously in a platform-independent way.
- [x] Updated canvas UI to load real images via `Image.memory()` inside the `ColorFiltered` matrix pipeline, allowing brightness, contrast, and saturation tweaks to apply in real-time.
- [x] Configured `FilePicker` inside editor to request `withData: true` so image bytes are read correctly on Web browsers.
- [x] Corrected `image_editor_bloc_test.dart` to supply mock bytes, keeping the unit tests fully offline-first.

### End-To-End Document Import Workflows
- [x] Replaced list page Snackbars with complete, automated creation and redirect workflows.
- [x] Converted `PresentationListPage` to a `StatefulWidget` with a transition listener.
- [x] Wired file pickers in `SpreadsheetListPage`, `DocumentListPage`, and `PresentationListPage` to import files into SQLite database records and redirect users directly to the editor.

---

## Sprint 12 — Critical Bug Fixes & Interaction Polish (v1.3.2) ✅

### Documents
- [x] **Actual Toolbar Formatting**: Implemented selection-based formatting wrap and prefix handlers inside `_FormattingToolbar` UI widget that modify the controller text directly and fire `UpdateDocumentContent` BLoC events in real-time.

### Spreadsheet
- [x] **Focus and Keyboard Navigation restoration**: Replaced parent CallbackShortcuts with a custom `Focus.onKeyEvent` dispatcher that bubbles keys (ignores shortcuts) when standard text fields (cells, formula bar) are focused. Restored arrow keys, delete, enter, and tab behaviors.
- [x] **Real-time Formula Bar updates**: Added `onChanged` to formula bar field to update cell values in real-time, and added cursor jump-avoidance logic in BLoC listener to keep cursor position intact while typing.

### Slides (Presentation)
- [x] **Inline Text editing**: Converted `_ElementFormatBar` to a `StatefulWidget` with a text input field that updates slide element text content via `UpdateElement` event in real-time.
- [x] **Image File uploading**: Connected the Slide formatting toolbar to local image selection via `FilePicker` and encoded raw bytes into base64 Data URLs.
- [x] **Slide Canvas Image rendering**: Upgraded `_CanvasElement` to render base64 Data URLs, local file paths, and network URLs with automatic fallback.

### PDF Viewer
- [x] **PDF Zoom Synchronization**: Wired `PdfViewerController` to `PdfViewer.file` and synchronized BLoC zoom events with the controller zoom ratio dynamically.
- [x] **Left Thumbnail Sidebar**: Integrated `PdfDocumentViewBuilder.file` and `PdfPageView` inside a collapsible sidebar row.
- [x] **Text Search highlights**: Integrated `PdfTextSearcher` with the page paint callbacks to search and highlight text occurrences, display match index progress, and support next/prev navigation.

### Quality Control
- [x] Static analysis (lint) checks pass clean with 0 issues
- [x] 100% test coverage pass for all 134 suite test cases in Docker
- [x] Production web build succeeded

---

## Sprint 20 — Critical Bug Fixes & Feature Wiring (v2.1.0) ✅

### Presentation — Crash Fixes
- [x] **Fix "Add Slide" crash**: Captured BLoC reference before `Navigator.pop()` in `_showAddSlideLayoutDialog` — previously, `context.read<PresentationBloc>()` was called after the dialog was popped from the navigator, referencing a potentially dismounted widget tree.
- [x] **Wire Insert Table**: Added "Insert Table" toolbar button that creates a `SlideElement(type: 'table')` with JSON-encoded cell data.
- [x] **Table Canvas Rendering**: Added `'table'` case to `_CanvasElement._buildContent()` that deserializes JSON content into a `SlideTable` model and renders via `SlideTableWidget` with bidirectional serialization.

### Spreadsheet — Multi-Cell Selection
- [x] **Grid-Level Drag Selection**: Replaced per-cell `onPanUpdate` (which only reported its own position) with a grid-level `Listener` that tracks `onPointerMove` during drag and calculates the target cell from pointer coordinates using scroll offsets and column/row dimensions.
- [x] **Pointer-to-Cell Mapping**: Added `_cellFromGlobalOffset()` helper that converts global pointer coordinates to `CellPosition` accounting for header dimensions, horizontal scroll offset, vertical scroll offset, hidden columns, and custom column widths.
- [x] **Shift+Click Range Extension**: Added `HardwareKeyboard.instance.isShiftPressed` check in `onCellTap` to extend selection from current cell to clicked cell via `SetCellRange`.

### Quality Control
- [x] Static analysis: 0 issues
- [x] All 236 test cases pass (100%)
- [x] `dart format` clean (0 changes)
