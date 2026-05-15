---
name: new-ui-module
description: Scaffold a new UI module (state/bloc/screen) following the MoovieAi pattern
---

# New UI Module Scaffold

Create a complete UI module with state class, Cubit bloc, and screen widget.

## Usage

```bash
/new-ui-module
```

## What You'll Be Asked

- **UI module name** — Where? (e.g., "movies_ui", "profile", "reviews")
- **Screen name** — What's the screen? (e.g., "MovieDetail", "UserProfile", "SearchResults")
- **Dependencies** — What usecases/repositories? (comma-separated, e.g., "GetMovieDetail, GetSimilarMovies")

## Generated Structure

Each UI module contains exactly 3 files in its own directory:

```
moovie/ui/<module>/lib/<screen_name_snake_case>/
├── <screen_name_snake_case>_state.dart       (sealed class with states)
├── <screen_name_snake_case>_bloc.dart        (Cubit implementation)
└── <screen_name_snake_case>_screen.dart      (@RoutePage widget)
```

## State Pattern

```dart
// moovie/ui/<module>/lib/<screen_name_snake_case>/<screen_name_snake_case>_state.dart

import 'package:<feature>/...dart';

sealed class <ScreenName>State {
  const <ScreenName>State();
}

class <ScreenName>Loading extends <ScreenName>State {
  const <ScreenName>Loading();
}

class <ScreenName>Success extends <ScreenName>State {
  final DataModel data;

  const <ScreenName>Success(this.data);
}

class <ScreenName>Error extends <ScreenName>State {
  final String message;

  const <ScreenName>Error(this.message);
}
```

## Bloc Pattern

```dart
// moovie/ui/<module>/lib/<screen_name_snake_case>/<screen_name_snake_case>_bloc.dart

import 'package:core/core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:<feature>/...dart';
import '<screen_name_snake_case>_state.dart';

class <ScreenName>Cubit extends Cubit<<ScreenName>State> {
  final UseCase _usecase;

  <ScreenName>Cubit(this._usecase) : super(const <ScreenName>Loading()) {
    _fetch();
  }

  void reload() {
    emit(const <ScreenName>Loading());
    _fetch();
  }

  Future<void> _fetch() async {
    final result = await _usecase();

    switch (result) {
      case Success(:final data):
        emit(<ScreenName>Success(data));
      case Failure(:final error):
        emit(<ScreenName>Error(error.message));
    }
  }
}
```

## Screen Pattern

```dart
// moovie/ui/<module>/lib/<screen_name_snake_case>/<screen_name_snake_case>_screen.dart

import 'package:auto_route/auto_route.dart';
import 'package:common/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '<screen_name_snake_case>_bloc.dart';
import '<screen_name_snake_case>_state.dart';

@RoutePage()
class <ScreenName>Screen extends StatelessWidget {
  final <ScreenName>Cubit cubit;

  const <ScreenName>Screen({super.key, required this.cubit});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: cubit,
      child: BlocBuilder<<ScreenName>Cubit, <ScreenName>State>(
        builder: (context, state) => switch (state) {
          <ScreenName>Loading() => const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
          <ScreenName>Error(:final message) => Scaffold(
              appBar: AppBar(title: const Text('Error')),
              body: Center(child: Text(message)),
            ),
          <ScreenName>Success(:final data) => Scaffold(
              appBar: AppBar(title: const Text('Title')),
              body: Center(child: Text(data.toString())),
            ),
        },
      ),
    );
  }
}
```

## Requirements

- **Exactly 3 files** — state, bloc, screen (no exceptions)
- **State class** — sealed base class + concrete Loading/Success/Error states
- **Bloc class** — `Cubit<<ScreenName>State>`, starts in `Loading`
- **Screen class** — `@RoutePage()` widget, receives cubit in constructor
- **Use BlocBuilder** — with pattern matching on state
- File names and directory names use `snake_case`
- Class names use `PascalCase`
- Always include `const` constructors where possible
