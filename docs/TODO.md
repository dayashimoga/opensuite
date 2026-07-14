# OpenSuite — TODO

## Sprint 13: Architecture Overhaul & Gap Closure (v1.5.0) — IN PROGRESS

### ✅ Completed

#### Shared Editor Foundation (Sprint 1)
- [x] SaveManager<T> — generic auto-save with debounce and dirty-state tracking
- [x] ExportManager — centralized export pipeline with codec registry
- [x] ImportManager — unified import with format auto-detection
- [x] BackgroundTaskManager — async task queue with progress/cancellation
- [x] FileFormatRegistry — central format metadata registry (15+ formats)
- [x] ContextMenuBuilder — reusable context menu framework
- [x] ImageProcessor — real pixel manipulation via dart:ui canvas
- [x] CsvCodec / TsvCodec — robust delimited text codecs
- [x] Core barrel exports updated
- [x] AppModule DI wiring (FileFormatRegistry init, CSV/TSV codec registration)

#### Spreadsheet Fixes (Sprint 2)
- [x] CSV import (ImportCsv event + handler with type detection)
- [x] CSV export (ExportCsvFile event + handler)
- [x] Fill handle (FillRange event with numeric/text fill)
- [x] Web interactivity fix: explicit FocusNode for grid and formula bar
- [x] Web interactivity fix: KeyRepeatEvent handling for held-key navigation
- [x] Web interactivity fix: Listener.onPointerDown for right-click context menu
- [x] Web interactivity fix: focus return to grid after formula bar submit
- [x] Web interactivity fix: _isEditingActive() checks specific FocusNode

#### Presentation Editor (Sprint 3)
- [x] RotateElement event + handler
- [x] AlignElements event + handler (6 alignment modes)
- [x] DuplicateElement event + handler (with offset + unique ID)
- [x] GroupElements / UngroupElements events + handlers
- [x] SlideElement model: added groupId, opacity, id in copyWith

#### Image Editor Fixes (Sprint 5)
- [x] CropImage handler registered (was missing)
- [x] Real export via ImageProcessor (replaced fake Future.delayed)
- [x] SetHue / SetExposure events + handlers
- [x] Real image dimension detection on load
- [x] exportedBytes in state for downstream saving

#### PDF Module (Sprint 6)
- [x] PdfAnnotationDao wired for annotation persistence
- [x] SaveAnnotations / LoadAnnotations handlers
- [x] Auto-load annotations on PDF open
- [x] Auto-save annotations on add/remove/update
- [x] SetPageRange fix (was empty method body)
- [x] ToggleAnnotationMode event + handler
- [x] UpdateAnnotation event + handler
- [x] currentPageAnnotations helper

### 🔲 Remaining

#### Document & Notes Editor (Sprint 4)
- [ ] Replace plain TextField with flutter_quill for rich text editing
- [ ] Wire formatting toolbar to Quill operations (bold, italic, headings, lists)
- [ ] Image insertion in documents
- [ ] Find & replace in documents
- [ ] Notes: markdown rendering preview
- [ ] DOCX import via archive + XML parser
- [ ] DOCX export

#### Spreadsheet Remaining
- [ ] XLSX import/export via archive + XML
- [ ] Conditional formatting engine
- [ ] Charts via fl_chart integration
- [ ] Wire version history on save

#### Presentation Remaining
- [ ] PPTX import/export via archive + XML
- [ ] Tables in slides
- [ ] Animation timeline

#### File Manager (Sprint 7)
- [ ] Local directory browsing (platform-aware)
- [ ] File operations (copy, rename, delete, move)
- [ ] Multi-select mode
- [ ] Drag & drop support

#### Cross-Platform & DevOps
- [ ] CI/CD pipeline for Android APK build
- [ ] CI/CD pipeline for Windows MSIX build
- [ ] Docker-based test runner
- [ ] Performance profiling pass
- [ ] Full accessibility audit (Semantics, screen reader)

---

## Previous Sprints (Completed)

### Sprint 2: Document Editor (v1.0.0)
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

### Sprint 3: Spreadsheet (v1.0.0)
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

### Sprint 4: Presentation (v1.0.0)
- [x] Slide canvas with drag-and-drop elements
- [x] Theme system with predefined layouts
- [x] Text boxes, shapes (rectangle, circle, triangle, arrow)
- [x] Speaker notes
- [x] Full-screen presentation mode (keyboard nav: arrows, space, escape)
- [x] Slide transitions (none, fade, slide, zoom)
- [x] Slide panel with thumbnails
- [x] Duplicate/delete slides
- [x] Element move (drag) and resize

### Sprint 5: PDF Suite (v1.0.0)
- [x] PDF viewer page with canvas
- [x] Page navigation (prev/next/go-to)
- [x] Thumbnails sidebar
- [x] Zoom controls (25%-500%)
- [x] Text search dialog
- [x] Annotations (highlight, underline, sticky note, freehand)
- [x] Rotate pages
- [x] Page range selection (for split/extract)

### Sprint 6: Image Editor (v1.0.0)
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

### Sprint 7-12: Polish & Hardening (v1.1.0 — v1.3.2)
- [x] WCAG AAA high contrast themes
- [x] Version history (VersionEntity + VersionDao + DB v5)
- [x] InputSanitizer (XSS, SQL injection, path traversal)
- [x] Fix database PRAGMA crash
- [x] PDF real rendering via pdfrx
- [x] CI/CD pipeline (Cloudflare, Docker, GitHub Actions)
- [x] 100+ BLoC unit tests
- [x] Web build verification
- [x] Documents inline formatting
- [x] Slides image upload + canvas rendering
- [x] PDF text search highlights + thumbnail sidebar
