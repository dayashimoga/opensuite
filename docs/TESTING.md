# OpenSuite — Testing Guide

## Test Strategy

OpenSuite uses a comprehensive test pyramid:

```
         ╱╲
        ╱ E2E ╲         (Critical flows)
       ╱────────╲
      ╱ Integration╲    (Feature modules)
     ╱──────────────╲
    ╱   Widget Tests  ╲  (UI components)
   ╱────────────────────╲
  ╱      Unit Tests      ╲ (Logic, models)
 ╱────────────────────────╲
```

## Running Tests

### Via Docker (recommended)
```bash
# All tests
docker compose -f docker/docker-compose.yml run --rm test

# With coverage
docker compose -f docker/docker-compose.yml run --rm dev bash -c \
  "cd apps/opensuite && flutter test --coverage"
```

### Locally (if Flutter installed)
```bash
cd apps/opensuite
flutter test --coverage

# Specific test file
flutter test test/features/notes/bloc/notes_bloc_test.dart

# Package tests
cd ../../packages/core && flutter test
```

## Coverage Requirements

- **Target**: >90% line coverage
- **CI enforcement**: Tests must pass with coverage report
- **Exclusions**: Generated files (*.g.dart, *.freezed.dart)

## Test Organization

```
apps/opensuite/test/
├── features/
│   ├── notes/
│   │   └── bloc/notes_bloc_test.dart
│   ├── file_manager/
│   │   └── bloc/file_manager_bloc_test.dart
│   ├── text_editor/
│   │   └── bloc/text_editor_bloc_test.dart
│   └── settings/
│       └── bloc/settings_bloc_test.dart
└── helpers/
    └── test_helpers.dart

packages/core/test/
├── models/
│   └── file_type_test.dart
├── errors/
│   └── result_test.dart
└── utils/
    ├── string_utils_test.dart
    └── file_utils_test.dart
```

## Writing Tests

### BLoC Tests
```dart
blocTest<NotesBloc, NotesState>(
  'emits [loading, loaded] when LoadNotes is added',
  build: () => NotesBloc(noteDao: mockNoteDao),
  act: (bloc) => bloc.add(const LoadNotes()),
  expect: () => [
    const NotesState(status: NotesStatus.loading),
    NotesState(status: NotesStatus.loaded, notes: testNotes),
  ],
);
```

### Widget Tests
```dart
testWidgets('NoteCard displays title', (tester) async {
  await tester.pumpWidget(
    MaterialApp(home: NoteCard(note: testNote)),
  );
  expect(find.text('Test Note'), findsOneWidget);
});
```

## Libraries

| Library | Purpose |
|---------|---------|
| `flutter_test` | Widget and unit testing |
| `bloc_test` | BLoC testing utilities |
| `mocktail` | Mock generation |
