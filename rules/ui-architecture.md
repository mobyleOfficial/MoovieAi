---
description: Rules for structuring UI modules in the Flutter app
globs: ui/**/*.dart
---

# UI Module Architecture

UI modules live under `ui/`. This is a container directory — NOT a package. Only the sub-modules inside it are packages.

## UI Module Structure

Each UI module is a package that contains three files:

```
ui/<module_name>/
  pubspec.yaml                          # Package: <module_name>
  lib/
    <module_name>_bloc.dart             # BLoC for state management
    <module_name>_screen.dart           # Screen widget
    <module_name>_state.dart            # State class(es) for the BLoC
```

## File Responsibilities

- `<module_name>_state.dart` — sealed base class + `Loading`, `Success`, and `Error` concrete states.
- `<module_name>_bloc.dart` — Cubit extending `Cubit<<ModuleName>State>`, starts in `Loading`.
- `<module_name>_screen.dart` — `@RoutePage()` widget that provides the Cubit and reacts with `BlocBuilder`.

Use `/new-ui-module <name>` to scaffold a new module from the standard template.

## Rules

- Each UI module is its own package with its own `pubspec.yaml`.
- Every UI module must contain exactly three files (plus the barrel file): `<module_name>_bloc.dart`, `<module_name>_screen.dart`, and `<module_name>_state.dart`.
- Package naming: `<module_name>` matching the directory name.
- The main app adds the UI module as a path dependency (e.g., `home: path: ui/home`).
- The barrel file re-exports all three files.
- File names use `snake_case`. Class names use `PascalCase` (e.g., `HomeBloc`, `HomeScreen`, `HomeState`).