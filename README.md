# OpenSuite

**Open-source cross-platform Office & Productivity Suite**

[![CI](https://github.com/user/opensuite/actions/workflows/ci.yml/badge.svg)](https://github.com/user/opensuite/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

OpenSuite is a production-ready, open-source productivity suite built with Flutter, supporting Web (PWA), Android, iOS, Windows, macOS, and Linux from a single codebase.

## Features

### Available Now (Sprint 1)
- 📝 **Notes** — Create and organize notes with plain text, markdown, checklists, and rich text
- 📁 **File Manager** — Browse, search, and manage files with recent history and favorites
- ✏️ **Text Editor** — Edit text and markdown files with live preview, find & replace, and autosave
- 🎨 **Themes** — Dark, light, and system theme support with Material 3 design
- ⚙️ **Settings** — Configurable editor, autosave, and appearance preferences
- 📱 **Responsive** — Adaptive layout for mobile, tablet, and desktop

### Coming Soon
- 📄 Document Editor (DOCX, ODT, RTF)
- 📊 Spreadsheet (XLSX, CSV, ODS)
- 📽️ Presentations (PPTX, ODP)
- 📕 PDF Viewer & Editor
- 🖼️ Image Viewer & Editor

## Quick Start

### Prerequisites
- [Docker](https://docs.docker.com/get-docker/) (required)
- [Git](https://git-scm.com/) (required)

### Setup

```bash
# Clone the repository
git clone https://github.com/user/opensuite.git
cd opensuite

# Run setup (Linux/macOS)
chmod +x scripts/setup.sh
./scripts/setup.sh

# Run setup (Windows PowerShell)
.\scripts\setup.ps1
```

### Development Commands

```bash
# Run tests
docker compose -f docker/docker-compose.yml run --rm test

# Run linting
docker compose -f docker/docker-compose.yml run --rm lint

# Check formatting
docker compose -f docker/docker-compose.yml run --rm format

# Build for web
docker compose -f docker/docker-compose.yml run --rm build-web

# Build Android APK
docker compose -f docker/docker-compose.yml run --rm build-android

# Interactive development shell
docker compose -f docker/docker-compose.yml run --rm dev
```

### If Flutter is installed locally

```bash
cd apps/opensuite
flutter pub get
flutter run -d chrome    # Web
flutter run -d windows   # Windows
flutter run               # Default device
```

## Architecture

```
opensuite/
├── apps/opensuite/          # Main Flutter application
│   ├── lib/
│   │   ├── features/        # Feature modules (notes, editor, files, settings)
│   │   ├── router/           # GoRouter configuration
│   │   └── di/               # Dependency injection
│   └── web/                  # PWA configuration
├── packages/
│   ├── core/                 # DI, logging, errors, config, models
│   ├── storage/              # SQLite, preferences, file storage
│   ├── ui_kit/               # Design system, themes, responsive widgets
│   └── l10n/                 # Localization strings
├── docker/                   # Docker configuration
├── .github/workflows/        # CI/CD pipelines
├── scripts/                  # Setup and build scripts
└── docs/                     # Documentation
```

### Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Flutter 3.x (stable) |
| Language | Dart 3.x |
| State Management | flutter_bloc |
| Routing | go_router |
| DI | get_it |
| Database | sqflite (SQLite) |
| Theming | Material 3 + Google Fonts |
| CI/CD | GitHub Actions |
| Deployment | Cloudflare Pages |
| Containerization | Docker |

## Documentation

- [Architecture](docs/ARCHITECTURE.md)
- [Requirements](docs/REQUIREMENTS.md)
- [Implementation](docs/IMPLEMENTATION.md)
- [Deployment](docs/DEPLOYMENT.md)
- [Contributing](docs/CONTRIBUTING.md)
- [Security](docs/SECURITY.md)
- [Changelog](docs/CHANGELOG.md)

## License

MIT License — see [LICENSE](LICENSE) for details.
