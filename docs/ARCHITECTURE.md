# OpenSuite Architecture

## Overview

OpenSuite follows **Clean Architecture** principles with a modular monorepo structure, ensuring separation of concerns, testability, and scalability across all six target platforms.

## Layer Diagram

```
┌─────────────────────────────────────────────┐
│                  Presentation               │
│  (Flutter Widgets, Pages, BLoC)             │
├─────────────────────────────────────────────┤
│                  Domain                     │
│  (BLoC Events/States, Business Logic)       │
├─────────────────────────────────────────────┤
│                  Data                       │
│  (DAOs, Repositories, Storage Services)     │
├─────────────────────────────────────────────┤
│                Infrastructure               │
│  (SQLite, File System, Preferences)         │
└─────────────────────────────────────────────┘
```

## Package Architecture

### packages/core
- **Purpose**: Foundation layer with zero Flutter dependency (pure Dart)
- **Contains**: DI (get_it), logging, error handling (Result monad), configuration, feature flags, models, utility functions, constants
- **Depends on**: None (leaf package)

### packages/storage
- **Purpose**: Offline-first data persistence
- **Contains**: SQLite database (sqflite), DAOs (NoteDao, RecentFileDao), PreferencesService, FileStorageService
- **Depends on**: core

### packages/ui_kit
- **Purpose**: Design system and reusable UI components
- **Contains**: AppTheme (Material 3), color palette, typography (Inter + JetBrains Mono), spacing system, responsive builder, sidebar navigation, app scaffold, common widgets
- **Depends on**: core

### packages/l10n
- **Purpose**: Internationalization and string resources
- **Contains**: AppLocalizations (string constants), SupportedLocales
- **Depends on**: Flutter SDK only

### apps/opensuite
- **Purpose**: Main application assembling all packages
- **Contains**: Feature modules, routing (GoRouter), DI setup, platform-specific configuration
- **Depends on**: core, storage, ui_kit, l10n

## Feature Module Structure

Each feature follows a consistent internal structure:

```
features/<feature>/
├── bloc/              # BLoC (events, states, business logic)
├── pages/             # Page-level widgets
├── widgets/           # Feature-specific reusable widgets
└── models/            # Feature-specific models (if any)
```

## State Management

- **Pattern**: BLoC (Business Logic Component) via `flutter_bloc`
- **Events**: Sealed classes for type-safe event handling
- **States**: Equatable immutable state classes with `copyWith`
- **Global BLoCs**: SettingsBloc (provided at app root)
- **Feature BLoCs**: Created per-page via `BlocProvider`

## Routing

- **Library**: GoRouter with ShellRoute
- **Strategy**: Declarative routing with path-based navigation
- **Shell**: Shared navigation scaffold (sidebar on desktop, bottom nav on mobile)
- **Deep linking**: Supported via named routes and path parameters

## Dependency Injection

- **Library**: get_it (service locator)
- **Registration**: Lazy singletons for services, factory methods for BLoCs
- **Testing**: `resetServiceLocator()` for test isolation

## Data Flow

```
User Action → BLoC Event → BLoC Handler → DAO/Service → SQLite/FileSystem
     ↑                          ↓
     └──── UI Rebuild ← BLoC State
```

## Responsive Design

- **Mobile** (< 600px): Bottom navigation, single-column layout
- **Tablet** (600-1023px): Compact sidebar, two-column layout
- **Desktop** (≥ 1024px): Full sidebar, multi-panel layout

## Offline-First Strategy

All data is stored locally in SQLite. The architecture includes an abstraction layer for future cloud sync integration:
1. DAOs handle all persistence
2. A future SyncService layer will sit between BLoCs and DAOs
3. Conflict resolution will be last-write-wins with optional manual merge
