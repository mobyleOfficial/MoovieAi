---
name: new-repository
description: Scaffold a new repository contract (domain) and implementation (data)
---

# New Repository Scaffold

Create a repository contract in the domain layer and its implementation in the data layer.

## Usage

```bash
/new-repository
```

## What You'll Be Asked

- **Feature name** — Which feature? (e.g., "movies", "reviews")
- **Repository name** — What's the semantic name? (e.g., "Movies", "UserProfile")
- **Methods** — What operations? (comma-separated, e.g., "getTrending, getDetail, search")

## Generated Structure

```
muuvie/features/<feature>/
├── domain/lib/repositories/
│   └── <feature>_repository.dart           (contract - pure domain)
└── data/lib/repositories/
    └── <feature>_repository_impl.dart      (implementation - uses datasources)
```

## Domain Repository Pattern

```dart
// muuvie/features/<feature>/domain/lib/repositories/<feature>_repository.dart

abstract interface class <Feature>Repository {
  Future<Result<DomainModel>> methodName({required Type param});
}
```

## Data Repository Implementation Pattern

```dart
// muuvie/features/<feature>/data/lib/repositories/<feature>_repository_impl.dart

import 'package:core/core.dart';
import 'package:injectable/injectable.dart';
import 'package:<feature>_domain/domain.dart';
import 'package:<feature>_data/datasources/remote/<feature>_remote_data_source.dart';

@LazySingleton(as: <Feature>Repository)
class <Feature>RepositoryImpl implements <Feature>Repository {
  final <Feature>RemoteDataSource _dataSource;

  <Feature>RepositoryImpl(this._dataSource);

  @override
  Future<Result<DomainModel>> methodName({required Type param}) async {
    final result = await _dataSource.methodName(param: param);

    return switch (result) {
      Success(:final data) => Success(data.toDomain()),
      Failure(:final error) => Failure(error),
    };
  }
}
```

## Requirements

- **Domain contract** — Pure Dart, no external dependencies, abstract interface only
- **Implementation** — Uses `@LazySingleton(as: InterfaceName)` registration
- **Never try/catch** — Data sources return `Result<T>`, repository just transforms data
- **Data mapping** — Use `.toDomain()` to convert data models → domain models
- Inject datasources via constructor, not service locator
- One repository per feature (even if multiple datasources feed into it)
