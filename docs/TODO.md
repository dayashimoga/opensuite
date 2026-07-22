# OpenSuite — TODO & Task Tracking

## Current Sprint — Sprint 29: Spreadsheet Autofill Handle, Cell Borders Engine, Merge/Unmerge & Formula Autocomplete (v3.0.0+24)

### 🔴 Critical
- [x] **Header Edge Resizing & Cursors**: Dedicated 6px resize handles on column/row headers with `SystemMouseCursors.resizeColumn` and `SystemMouseCursors.resizeRow` (Sprint 28).
- [x] **Select-All Corner Button**: Top-left corner box selects all cells (`SetCellRange(0, 0, rowCount - 1, colCount - 1)`) (Sprint 28).
- [ ] **Multi-Cell Keyboard Range Selection**: Shift + Arrow keys and Ctrl + Shift + Arrow keys range expansion.
- [ ] **Native Context Menu Override**: Prevent browser default right-click context menu popping over application context menu in web target.

### 🟠 High Priority
- [ ] **Spreadsheet Autofill Handle**: Interactive drag handle on bottom-right corner of cell range selection for auto-increment and series fill.
- [ ] **Spreadsheet Cell Borders Engine**: Visual rendering and BLoC formatting for cell borders (All, Outer, Inner, Top, Bottom, Left, Right).
- [ ] **Range Merge / Unmerge**: Merge selected cell range into single cell with top-left value preservation and unmerge capability.
- [ ] **Formula Autocomplete**: Real-time popover dropdown listing formula functions (SUM, AVERAGE, COUNT, VLOOKUP, IF...) while typing `=` in cell or formula bar.
- [ ] **Slide Layer Ordering & Grouping**: Bring forward, send backward, bring to front, send to back, group, and ungroup slide canvas elements.
- [ ] **Slide Transitions & Presentation PDF Export**: Animated transitions (fade, push, wipe, zoom) and export presentation to multi-page PDF.

### 🟡 Medium Priority
- [ ] **Column Filtering Dropdowns**: Column header dropdown menu with unique value checkboxes and text filter rules (Contains, Equals, Greater Than).
- [ ] **Slide Alignment Guides & Snap-To-Grid**: Visual drag alignment guides (center, edges) and snap-to-grid for slide canvas elements.
- [ ] **Document Rich Text Styles**: Expanded Quill editor styles for tables, block quotes, and code syntax highlighting.
- [ ] **File Manager Native Tree Browsing**: Local filesystem directory tree view and multi-file drag-select operations.

### 🟢 Low Priority
- [ ] **Dark / Light Theme Presets**: Expanded accent color themes and customizable UI density options.
- [ ] **Audio Annotations**: Voice notes attachment in PDF Viewer.

### 🔄 In Progress
- [ ] **Sprint 29 — Core Editing & Grid Interactions (v3.0.0+24)**: Implementing Autofill handle, Cell Borders toolbar picker, Range Merge/Unmerge, and Formula Autocomplete.

### ⛔ Blocked
- *None*

### ✅ Completed
- [x] **Sprint 28 (v2.9.0+23)**: Dedicated Column/Row edge resize handles with resize mouse cursors, Select-All corner button, unclipped `_NumberFormatPicker`, complete Google Sheets `Insert` menu dropdown.
- [x] **Sprint 27 (v2.8.0+22)**: Upgraded Android Gradle Plugin (AGP) from 8.3.0 to 8.9.1 and Gradle wrapper to 8.11.1-all for Flutter 3.44.6 release build compatibility.
- [x] **Sprint 26 (v2.7.0+21)**: Replaced `DropdownButtonFormField` widgets with `_FontFamilyPicker` & `_FontSizePicker`, 18 standard Google Sheets fonts, dynamic `GoogleFonts` cell rendering.
- [x] **Sprint 25 (v2.6.0+20)**: Upgraded Gradle wrapper to 8.7-all and hardened CI Android build step.
- [x] **Sprint 24 (v2.5.0+19)**: Eliminated duplicate menubar tab bar, single Google Sheets / MS Excel top Menubar + Quick Formatting Toolbar.
- [x] **Sprint 23 (v2.4.0+18)**: Presentation mode slideshow viewer, slide list reordering with `onReorderItem`, top Menubar text dropdowns.
- [x] **Sprint 22 (v2.3.0+17)**: Grid drag range selection, Shift+Click, Shift+Arrows, Enter/Tab navigation, Insert Row/Col.
- [x] **Sprint 20 (v2.1.0)**: Presentation Animations Sidebar, Spreadsheet drag selection grid listener, SlideTable rendering.
- [x] **Sprint 1-19**: Shared Editor Foundation, SaveManager, ExportManager, ImportManager, FormulaEngine, PDF pdfrx viewer, Image Editor canvas filters, Quill Document Editor, Version History.

### 📋 Backlog
- [ ] Real-time collaborative multi-user editing (WebSockets / CRDTs).
- [ ] Cloud Storage Provider Sync (Google Drive, OneDrive, S3).

---

## Detailed Historical Sprints Log (Preserved)

### Sprint 28: Header Resizing, Select-All Corner & Complete Insert Suite (v2.9.0+23)
- [x] Dedicated 6px right-edge resize handle on column headers with `SystemMouseCursors.resizeColumn`.
- [x] Dedicated 6px bottom-edge resize handle on row headers with `SystemMouseCursors.resizeRow`.
- [x] Select-All top-left corner box selecting full sheet grid (`SetCellRange(0, 0, rowCount - 1, colCount - 1)`).
- [x] `_NumberFormatPicker` (`PopupMenuButton<NumberFormatType>`) eliminating text clipping.
- [x] Google Sheets `Insert` menu dropdown (Rows, Columns, Sheet, Chart, Functions, Comment, Link, Checkbox, Dropdown).

### Sprint 27: AGP 8.9.1 Upgrade & Android Build Fix (v2.8.0+22)
- [x] Upgraded Android Gradle Plugin (AGP) version from 8.3.0 to 8.9.1 in `settings.gradle`.
- [x] Upgraded Gradle wrapper to 8.11.1-all in `gradle-wrapper.properties`.
- [x] Added `--no-tree-shake-icons` to Android build step in CI workflow.

### Sprint 26: Spreadsheet Font Engine & Toolbar Alignment Fixes (v2.7.0+21)
- [x] Replaced `DropdownButtonFormField` widgets with `_FontFamilyPicker` & `_FontSizePicker`.
- [x] Added 18 standard Google Sheets / Excel font families and 16 font sizes.
- [x] Updated `_getCellTextStyle` to apply `GoogleFonts.getFont(family)` dynamically.
- [x] Synchronized active font family and font size on cell selection.

### Sprint 25: Android Build Fix & Gradle 8.7 Upgrade (v2.6.0+20)
- [x] Upgraded `distributionUrl` in `gradle-wrapper.properties` to `gradle-8.7-all.zip`.
- [x] Added `--android-skip-build-dependency-validation` flag to `ci.yml`.

### Sprint 24: Streamlined Single Menubar & Quick Formatting Toolbar (v2.5.0+19)
- [x] Removed duplicate second tab row (`Home`, `Insert`, `Data`, `View`).
- [x] Created single-row Quick Access Formatting Toolbar (`_buildQuickFormattingToolbar`).
- [x] Top Menubar text dropdowns (`File`, `Edit`, `View`, `Insert`, `Format`, `Data`, `Tools`, `Help`).

### Sprint 23: Presentation Engine & Spreadsheet Desktop Menubar (v2.4.0+18)
- [x] Built Presenter Mode fullscreen slideshow viewer (`_PresentationModeView`).
- [x] Updated slide list thumbnails to `ReorderableListView.builder` using `onReorderItem`.
- [x] Sanitized `_onAddSlide` insert index clamping to prevent out of bounds RangeError crashes.

### Sprint 22: Spreadsheet Engine Core Interactivity (v2.3.0+17)
- [x] Grid drag range selection via pointer movement.
- [x] Shift+Click range extension.
- [x] Keyboard navigation (Tab, Shift+Tab, Enter, Shift+Enter, Arrows).
- [x] Insert Row Above/Below & Col Left/Right.

### Sprint 20: Presentation Animations Sidebar (v2.1.0)
- [x] Wired `AnimationPanel` right-side sidebar toggle button in Presentation editor.
- [x] Refactored drag selection to grid-level `Listener`.
- [x] Deserialized JSON table elements dynamically on slide canvas.

### Sprint 1: Shared Editor Foundation (v1.5.0)
- [x] SaveManager<T> generic auto-save with debounce.
- [x] ExportManager centralized export pipeline.
- [x] ImportManager unified import.
- [x] BackgroundTaskManager async queue.
- [x] FileFormatRegistry format metadata.
- [x] ImageProcessor real pixel manipulation (dart:ui).
- [x] CsvCodec / TsvCodec delimited text codecs.

### Sprint 2: Document Editor (v1.0.0)
- [x] Rich text editor with formatting toolbar.
- [x] Document persistence (DocumentDao + DocumentEntity).
- [x] Keyboard shortcuts framework.
- [x] Document CRUD (create, open, save, delete, duplicate).

### Sprint 3: Spreadsheet (v1.0.0)
- [x] Custom grid widget with virtual scrolling.
- [x] Cell editing (text, number, date, formula).
- [x] Formula engine (60+ functions).
- [x] Cell formatting (bold, italic, colors, alignment).
- [x] Multiple sheets (add, rename, delete, switch).

### Sprint 4: Presentation (v1.0.0)
- [x] Slide canvas with drag-and-drop elements.
- [x] Theme system with predefined layouts.
- [x] Text boxes, shapes, speaker notes, full-screen presentation mode.

### Sprint 5: PDF Suite (v1.0.0)
- [x] PDF viewer page with canvas & pdfrx integration.
- [x] Page navigation, zoom controls, text search dialog, annotations.

### Sprint 6: Image Editor (v1.0.0)
- [x] Image crop, rotate, resize, filters, flip, color matrix rendering.
