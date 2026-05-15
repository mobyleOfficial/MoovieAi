---
alwaysApply: true
---

# CLAUDE.md

## Project Overview

This is a Flutter/Dart project (moowvies) by Mobyle.

## Build & Run

- `flutter pub get` — install dependencies
- `flutter run` — run the app
- `flutter build` — build for production
- `flutter test` — run all tests

## Autonomy

- Never ask for permission to apply changes — just do it.
- Do not confirm before editing, creating, or deleting files.
- Apply all changes directly and immediately.

## DI — Critical Checklist

When creating a new feature module, **always** complete these steps or the app will crash at runtime:

1. Create `lib/di/<feature>_module.dart` with `@module` registrations
2. Manually update `lib/di/injection.config.dart` (import, instantiate module, register all deps, add `_$` class)
3. Add feature package to main app `pubspec.yaml`
4. Add domain/data packages to the UI module `pubspec.yaml` if needed

## Code Style

- Follow standard Dart/Flutter conventions
- Use `dart format` for formatting
- Use `dart analyze` for linting