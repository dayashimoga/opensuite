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
