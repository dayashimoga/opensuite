# Contributing to OpenSuite

Thank you for your interest in contributing to OpenSuite!

## Development Setup

### Prerequisites
- Docker (required)
- Git

### Getting Started

```bash
git clone https://github.com/user/opensuite.git
cd opensuite

# Linux/macOS
chmod +x scripts/setup.sh && ./scripts/setup.sh

# Windows
.\scripts\setup.ps1
```

## Code Style

- Follow the Dart [style guide](https://dart.dev/guides/language/effective-dart/style)
- Use `dart format` for consistent formatting
- All code must pass `flutter analyze` with zero warnings
- Write documentation comments for all public APIs
- Prefer `const` constructors where possible
- Use `sealed` classes for BLoC events
- Use `Equatable` for states and entities
- Follow the existing file/folder structure

## Git Workflow

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/my-feature`
3. Make your changes
4. Run tests: `docker compose -f docker/docker-compose.yml run --rm test`
5. Run lint: `docker compose -f docker/docker-compose.yml run --rm lint`
6. Commit with conventional commits: `feat:`, `fix:`, `docs:`, `refactor:`, `test:`
7. Push and create a Pull Request

## Pull Request Guidelines

- Describe what the change does and why
- Reference any related issues
- Ensure CI passes
- Add tests for new functionality
- Update documentation if behavior changes
- Keep PRs focused — one feature per PR

## Architecture Guidelines

- New features go in `apps/opensuite/lib/features/<feature>/`
- Shared logic goes in the appropriate package (core, storage, ui_kit, l10n)
- Follow Clean Architecture layers: Presentation → Domain → Data
- Use BLoC for state management (not setState, Provider, etc.)
- Use the Result<T> type for operations that can fail
- Register services via the service locator, not direct instantiation

## Testing

- Unit tests for all BLoCs, DAOs, and services
- Widget tests for pages and complex widgets
- Integration tests for critical user flows
- Target: >90% code coverage
- All tests must pass before merging

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
