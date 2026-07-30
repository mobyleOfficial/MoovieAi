---
name: new-datasource
description: Scaffold a new remote or local datasource in a feature's data layer
---

# New DataSource Scaffold

Create a datasource contract and implementation for remote API or local storage operations.

## Usage

```bash
/new-datasource
```

## What You'll Be Asked

- **Feature name** — Which feature? (e.g., "movies", "reviews")
- **DataSource type** — Remote API or Local storage? (remote/local)
- **DataSource name** — What's the semantic name? (e.g., "Movies", "UserPreferences")
- **Methods** — What operations? (comma-separated, e.g., "getTrending, getDetail, search")

## Generated Structure

### Remote DataSource

```
muuvie/features/<feature>/data/lib/datasources/remote/
├── <feature>_remote_data_source.dart        (contract/interface)
└── <feature>_remote_data_source_impl.dart   (implementation)
```

### Local DataSource

```
muuvie/features/<feature>/data/lib/datasources/local/
├── <feature>_local_data_source.dart         (contract/interface)
└── <feature>_local_data_source_impl.dart    (implementation)
```

## Remote DataSource Pattern

```dart
// Contract
abstract interface class <Feature>RemoteDataSource {
  Future<Result<Model>> methodName({required Type param});
}

// Implementation
@injectable
class <Feature>RemoteDataSourceImpl implements <Feature>RemoteDataSource {
  final HttpClient _httpClient;

  <Feature>RemoteDataSourceImpl(@Named('tmdb') this._httpClient);

  @override
  Future<Result<Model>> methodName({required Type param}) => _httpClient.execute(
    path: '/endpoint',
    parser: (json) => RemoteModel.fromJson(json),
  );
}
```

## Local DataSource Pattern

```dart
// Contract
abstract interface class <Feature>LocalDataSource {
  Future<Result<Model>> methodName({required Type param});
  Stream<Result<Model>> watchMethodName({required Type param});
}

// Implementation
@injectable
class <Feature>LocalDataSourceImpl implements <Feature>LocalDataSource {
  final LocalClient _localClient;

  <Feature>LocalDataSourceImpl(this._localClient);

  @override
  Future<Result<Model>> methodName({required Type param}) => _localClient.execute(
    operation: () => _db.operation(),
  );

  @override
  Stream<Result<Model>> watchMethodName({required Type param}) =>
    _localClient.watch(
      operation: () => _db.watchOperation(),
    );
}
```

## Requirements

- Always return `Result<T>` (errors handled by HttpClient/LocalClient)
- Remote: use `@Named('tmdb')` for TMDB API client
- Local: implement both `Future` and `Stream` (for watching changes)
- Use `@injectable` registration
- Contract is `abstract interface class` (no implementation)
- Implementation uses `@injectable` decorator
