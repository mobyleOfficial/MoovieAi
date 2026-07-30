---
name: new-usecase
description: Scaffold a new usecase in a feature's domain layer
---

# New UseCase Scaffold

Create a reusable business logic usecase following the MuuvieAi pattern.

## Usage

```bash
/new-usecase
```

## What You'll Be Asked

- **Feature name** — Which feature? (e.g., "movies", "reviews")
- **UseCase name** — What does it do? (e.g., "GetTrendingMovies", "SearchMovies")
- **Input type** — What parameter does it take? (e.g., "int" for page, "String" for query, "void" for none)
- **Output type** — What does it return? (e.g., "MovieListing", "List<Movie>")

## Generated Structure

```
muuvie/features/<feature>/domain/lib/usecases/
└── <use_case_name_snake_case>.dart
```

## Pattern

```dart
import 'package:core/core.dart';

import 'package:<feature>_domain/models/...dart';
import 'package:<feature>_domain/repositories/...dart';

class <UseCaseName> extends UseCase<InputType, Result<OutputType>> {
  final <Feature>Repository _repository;

  <UseCaseName>(this._repository);

  @override
  Future<Result<OutputType>> call([InputType? params]) async {
    return _repository.methodName(param: params);
  }
}
```

## Requirements

- One usecase per file
- Single public `call` method
- Extends `UseCase<InputType, OutputType>`
- Always returns `Result<T>` for error handling
- Use `@injectable` factory registration (not singleton)
- Inject repository contracts (domain layer), not implementations
