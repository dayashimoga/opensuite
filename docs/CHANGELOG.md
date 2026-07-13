# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
