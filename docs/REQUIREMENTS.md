# OpenSuite — Requirements

## Product Requirements

See the master requirements document for full details. This file summarizes the key requirements and their implementation status.

## Functional Requirements

### FR-1: Document Editor
Support DOCX, ODT, RTF, TXT, Markdown with rich formatting, tables, lists, images, headers/footers, hyperlinks, page setup, spell checking, find & replace, undo/redo, autosave, export, print.
- **Status**: TXT and Markdown implemented (Sprint 1). DOCX/ODT/RTF planned for Sprint 2.

### FR-2: Spreadsheet
Support XLSX, CSV, ODS with multiple sheets, formulas, charts, sorting, filtering, conditional formatting, freeze panes, cell formatting, import/export.
- **Status**: Planned for Sprint 3.

### FR-3: Presentation
Support PPTX, ODP with themes, layouts, images, tables, speaker notes, full-screen presentation, export, print.
- **Status**: Planned for Sprint 4.

### FR-4: PDF
Open, view, search, annotate, highlight, draw, merge, split, rotate, compress, extract pages, fill forms, digital signatures, password protection, print, export.
- **Status**: Planned for Sprint 5.

### FR-5: Notes
Plain text, rich text, markdown, checklists, code blocks, tables, images.
- **Status**: ✅ Implemented (Sprint 1). Images planned for Sprint 2.

### FR-6: File Manager
Browse, search, drag & drop, recent files, favorites, metadata, rename, copy, move, delete, import, export.
- **Status**: ✅ Partially implemented (Sprint 1). Drag & drop, rename/copy/move, import/export planned for Sprint 2.

### FR-7: Image Viewer/Editor
View, crop, rotate, resize, convert, export.
- **Status**: Planned for Sprint 6.

## Non-Functional Requirements

### NFR-1: Cross-Platform
Single codebase targeting Web (PWA), Android, iOS, Windows, macOS, Linux.
- **Status**: ✅ Architecture supports all 6 platforms. CI builds Web, Android, Linux.

### NFR-2: Offline-First
All functionality must work without internet connectivity.
- **Status**: ✅ Implemented via SQLite local storage.

### NFR-3: Performance
Fast startup, lazy loading, memory efficiency, smooth animations.
- **Status**: ✅ Architecture designed for performance. Profiling planned for Sprint 7.

### NFR-4: Accessibility
WCAG AA compliance.
- **Status**: Foundation in place (semantic widgets, Material 3). Full audit planned for Sprint 7.

### NFR-5: Security
Secure storage, input validation, dependency scanning.
- **Status**: ✅ Input validation implemented. Security audit planned for Sprint 7.

### NFR-6: Responsive UI
Adaptive layouts for mobile, tablet, and desktop.
- **Status**: ✅ Implemented via ResponsiveBuilder with 3 breakpoints.
