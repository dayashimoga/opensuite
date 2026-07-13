# OpenSuite — TODO

## Sprint 2: Document Editor
- [x] Rich text editor with formatting toolbar (BLoC + Page)
- [x] Document persistence (DocumentDao + DocumentEntity + DB migration)
- [x] Keyboard shortcuts framework (KeyboardShortcutService)
- [x] Document CRUD (create, open, save, delete, duplicate)
- [x] Undo/Redo with history stack
- [x] Autosave with configurable delay
- [x] Document search and favorites
- [x] Formatting toolbar (bold, italic, underline, strikethrough, headings, lists, quote, code, link)
- [x] Word/character count status bar
- [x] Document statistics dialog
- [x] Navigation integration (6-tab nav with Documents)
- [ ] DOCX import via custom OOXML parser
- [ ] DOCX export
- [ ] RTF support
- [ ] ODT support (basic)
- [ ] Tables in documents
- [ ] Images in documents
- [ ] Headers & footers
- [ ] Page setup (margins, orientation, size)
- [ ] Spell checking integration
- [ ] Print support
- [ ] File manager: import/export
- [ ] File manager: drag & drop
- [ ] File manager: rename/copy/move operations

## Sprint 3: Spreadsheet
- [x] Custom grid widget with virtual scrolling
- [x] Cell editing (text, number, date, formula)
- [x] Formula engine (60+ functions: math, stats, text, date, logical, financial)
- [x] Cell formatting (bold, italic, colors, alignment)
- [x] Multiple sheets (add, rename, delete, switch)
- [x] Sorting by column (ascending/descending)
- [x] Freeze panes (frozen rows/cols)
- [x] Spreadsheet persistence (SpreadsheetDao + SpreadsheetEntity + DB v3)
- [x] Spreadsheet CRUD (create, open, save, delete, duplicate, favorites)
- [x] Formula bar with cell reference
- [x] Sheet tabs with rename/delete
- [x] Autosave
- [x] Navigation integration (7-tab nav with Sheets)
- [ ] Conditional formatting
- [ ] Charts via fl_chart
- [ ] XLSX import/export
- [ ] CSV import/export
- [ ] ODS support (basic)

## Sprint 4: Presentation
- [x] Slide canvas with drag-and-drop elements
- [x] Theme system with predefined layouts
- [x] Text boxes, shapes (rectangle, circle, triangle, arrow)
- [x] Speaker notes
- [x] Full-screen presentation mode (keyboard nav: arrows, space, escape)
- [x] Slide transitions (none, fade, slide, zoom)
- [x] Slide panel with thumbnails
- [x] Duplicate/delete slides
- [x] Element move (drag) and resize
- [x] Presentation persistence (PresentationDao + DB v4)
- [x] Presentation CRUD (create, open, save, delete, duplicate, favorites)
- [x] Navigation integration (10-tab nav with Slides)
- [ ] Tables in slides
- [ ] PPTX import/export
- [ ] ODP support (basic)

## Sprint 5: PDF Suite
- [x] PDF viewer page with canvas
- [x] Page navigation (prev/next/go-to)
- [x] Thumbnails sidebar
- [x] Zoom controls (25%-500%)
- [x] Text search dialog
- [x] Annotations (highlight, underline, sticky note, freehand)
- [x] Rotate pages
- [x] Page range selection (for split/extract)
- [x] Annotation overlay rendering
- [x] Navigation integration (PDF tab)
- [ ] Merge multiple PDFs
- [ ] Compress PDF
- [ ] Fill PDF forms
- [ ] Digital signatures
- [ ] Password protection
- [ ] Print

## Sprint 6: Image Editor
- [x] Image viewing (zoom, pan via InteractiveViewer)
- [x] Crop tool (free, 16:9, 4:3, 1:1 presets)
- [x] Rotate (90°, -90°, free rotation slider)
- [x] Resize with presets (50%, 75%, 1080p, 720p)
- [x] Basic filters (brightness, contrast, saturation sliders)
- [x] Flip horizontal/vertical
- [x] Undo/redo stack
- [x] Reset all edits
- [x] Color matrix rendering
- [x] Format conversion (JPEG, PNG, WebP export)
- [x] Tool sidebar (Adjust, Crop, Rotate, Resize)
- [x] Status bar with image info
- [x] Navigation integration (Images tab)

## Sprint 7: Polish & Accessibility
- [x] WCAG AAA high contrast light theme (7:1 contrast ratio)
- [x] WCAG AAA high contrast dark theme
- [x] High contrast mode toggle in Settings > Accessibility
- [x] Language selector dialog (10 locales wired)
- [x] Persisted locale preference with immediate switching
- [x] Version history (VersionEntity + VersionDao + DB v5 migration)
- [x] InputSanitizer (XSS, SQL injection, path traversal, content validation)
- [x] Security test suite (18 tests)
- [x] Core test suite maintained (42 tests)
- [ ] Full screen reader support (Semantics audit)
- [ ] Complete keyboard navigation audit
- [ ] Performance profiling and optimization
- [ ] Rust FFI modules (performance-critical operations)
- [ ] End-to-end test suite (widget tests)

## Sprint 8: Production Stabilization (v1.1.0)
- [x] Fix database PRAGMA crash (rawQuery for journal_mode)
- [x] Remove all "Coming Soon" placeholders (Documents, Spreadsheets, PDF)
- [x] Fix GoRouter navigation (Documents, Spreadsheets list pages)
- [x] Image Editor responsive layout (mobile vertical, desktop horizontal)
- [x] Wire file_picker to Image Editor "Open Image"
- [x] Wire file_picker to PDF Viewer "Open PDF"
- [x] PDF Viewer responsive thumbnail sidebar (hidden on mobile)
- [x] Navigation redesign: 10→5 items on mobile bottom nav
- [x] CI/CD: Cloudflare auto-create project
- [x] CI/CD: Node.js 22 + Wrangler v3 direct install
- [x] CI/CD: Consolidated flutter pub get
- [x] BLoC unit tests: NotesBloc (13 tests)
- [x] BLoC unit tests: FileManagerBloc (9 tests)
- [x] BLoC unit tests: ImageEditorBloc (15 tests)
- [x] BLoC unit tests: SettingsBloc (11 tests)
- [x] Smoke tests: app_test.dart (6 tests)
- [x] Model tests: NoteEntity, RecentFileEntity
- [x] CHANGELOG.md updated
- [ ] DOCX import via custom OOXML parser
- [ ] XLSX import/export
- [ ] PPTX import/export
- [ ] PDF merge, compress, form fill
- [ ] Chart support (fl_chart integration)

## Sprint 9: Production Enhancement (v1.2.0+2)
- [x] PDF real rendering via pdfrx (replaces placeholder)
- [x] PDF share via share_plus
- [x] PDF file picker integration
- [x] Spreadsheet creation debounce (prevents duplicate creates)
- [x] Spreadsheet save feedback (SnackBar)
- [x] Spreadsheet CSV export via share_plus
- [x] Spreadsheet Open File button (xlsx/xls/csv/ods)
- [x] Document creation debounce
- [x] Document save feedback
- [x] Document share/export (TXT/Markdown)
- [x] Document Open File button (docx/doc/txt/md/rtf/odt)
- [x] Presentation save feedback (SnackBar)
- [x] Presentation share via share_plus
- [x] Presentation Open File button (pptx/ppt/odp)
- [x] Notes save feedback
- [x] Notes share via share_plus
- [x] Navigation after create (Spreadsheet, Document)
- [x] IMPLEMENTATION.md updated
- [x] CHANGELOG.md updated
- [x] TODO.md updated
- [x] flutter analyze: all clean
- [x] dart format: all clean
- [x] flutter test: all passing
- [x] Web build verification

## Sprint 10: Optimization & UX Premium (v1.3.0)
- [x] Add search event debounce using `restartable()` in BLoC
- [x] Optimize default spreadsheet grid sizes (100 -> 50)
- [x] Reusable staggered animated card widget (`AnimatedModuleCard`)
- [x] Redesigned dashboard home page with modular grid and staggered layout
- [x] Add quick action chips for spreadsheet and presentation modules
- [x] Navigation page transitions using `AnimatedSwitcher`
- [x] Harden CI pipeline (caching, multi-package tests, windows build)
- [x] Comprehensive BLoC test suites covering remaining untested components
- [x] 100% test coverage pass locally and in Docker
- [x] Release build verification

## Sprint 11: Production Hardening & Full-Fidelity (v1.3.1)
- [x] Add sqflite_common_ffi & sqflite_common_ffi_web dependencies
- [x] Implement conditional database initialization (Web, Windows, Linux, Mobile)
- [x] Support raw bytes loading inside ImageEditorBloc for Web
- [x] Load actual image via Image.memory inside canvas inside ColorFiltered
- [x] Convert list pages to StatefulWidget and hook file imports to bloc redirects
- [x] Rebuild Docker images to compile new dependencies
- [x] 100% test coverage pass locally and in Docker
- [x] Web build verification

## Sprint 12: Critical Bug Fixes & Interaction Polish (v1.3.2)
- [x] Documents: Actual inline text formatting application using wrap/prefix helpers in UI toolbar
- [x] Spreadsheet: Customized Focus onKeyEvent handling to prevent shortcut interception during cell editing
- [x] Spreadsheet: Real-time formula bar sync with cursor jump prevention logic
- [x] Slides: Content editing TextField inside contextual _ElementFormatBar
- [x] Slides: Local image upload support converting picked files to base64 Data URLs
- [x] Slides: Render base64, file-path, and network images inside slide canvas
- [x] PDF Viewer: Sync PdfViewerController scale/page changes with PDF BLoC zoom/current page state
- [x] PDF Viewer: Left-side sidebar collapsible page thumbnail panel
- [x] PDF Viewer: Real-time search highlights and index search bar navigation with PdfTextSearcher
- [x] 100% test coverage pass locally and in Docker
- [x] Web build verification


