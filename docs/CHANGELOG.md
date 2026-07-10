# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
