---
description: Rules for structuring backend features in Kotlin/Ktor
globs: backend/src/main/kotlin/**/*.kt
---

# Backend Architecture

The Kotlin/Ktor backend follows clean architecture with strict layer separation. All new features MUST follow this structure.

## Project Structure

```
backend/src/main/kotlin/org/mobyle/
├── domain/
│   ├── model/          — Domain models (pure Kotlin, no dependencies)
│   ├── repository/     — Repository contracts (interface only)
│   └── usecase/        — Business logic usecases
├── data/
│   ├── remote/         — HTTP datasources (Ktor client implementations)
│   ├── repository/     — Repository implementations (DTO → domain mapping)
│   ├── di/             — Data layer Koin modules
│   └── model/          — Data transfer objects (@Serializable DTOs)
├── presentation/
│   ├── routing/        — Ktor API endpoints and route extensions
│   └── di/             — Presentation layer Koin modules
└── Application.kt      — Ktor app configuration, routing setup

backend/src/test/kotlin/org/mobyle/
└── Mirrors main/ structure for unit tests
```

## Layer Responsibilities

### Domain Layer (`domain/`)
- **Pure Kotlin** — No external dependencies, no Ktor, no serialization
- **Contracts** — Repository interfaces define what data operations are available
- **Models** — Business entities with domain-relevant properties only
- **UseCases** — Orchestrate business logic, use repositories
- **No side effects** — No HTTP calls, no database access directly

### Data Layer (`data/`)
- **Implementations** — Concrete repository implementations
- **DataSources** — HTTP clients, local storage, external service calls
- **Mapping** — Convert DTOs to domain models via extension functions
- **No business logic** — Only coordinate data sources and map results

### Presentation Layer (`presentation/`)
- **Routing** — Ktor route handlers and endpoint definitions
- **DI Setup** — Koin module configuration for usecases
- **Request/Response** — HTTP parameter extraction and response serialization
- **Validation** — Input validation before usecase invocation

## Dependency Direction

```
Presentation (routing) ──> Domain (usecases, models)
                      └──> Data (repositories)
        └────────────────> Data ──> Domain
```

- Domain has zero dependencies on Data or Presentation
- Data depends on Domain for contracts and models
- Presentation uses Domain for usecases, Data for modules
- **No circular dependencies allowed**
- **No cross-layer imports** except dependency direction above

## DI Module Organization

### DataModule (`data/di/`)
Registers all data layer components:
```kotlin
val dataModule = module {
    single<TmdbDataSource> { TmdbDataSourceImpl(httpClient = get()) }
    single<MoviesRepository> { MoviesRepositoryImpl(datasource = get()) }
    // ... more data sources and repositories
}
```

### AppModule (`presentation/di/`)
Registers presentation layer (usecases):
```kotlin
val appModule = module {
    factory { GetTrendingMovies(repository = get()) }
    factory { GetMovieDetail(repository = get()) }
    // ... more usecases
}
```

Both modules loaded in `Application.kt`:
```kotlin
startKoin {
    modules(dataModule, appModule)
}
```

## File Organization Rules

### Naming
- **Files:** `camelCase.kt` (e.g., `getTrendingMovies.kt`)
- **Classes:** `PascalCase` (e.g., `GetTrendingMovies`)
- **Functions:** `camelCase` (e.g., `getTrendingMovies()`)
- **Constants:** `UPPER_SNAKE_CASE` (e.g., `BASE_URL`)
- **Private members:** prefix with `_`

### One Class Per File
```
src/main/kotlin/org/mobyle/domain/usecase/GetTrendingMovies.kt
  └── class GetTrendingMovies(...)

src/main/kotlin/org/mobyle/domain/repository/MoviesRepository.kt
  └── interface MoviesRepository
```

### Package Structure
- Must match directory structure: `src/main/kotlin/org/mobyle/domain/usecase/` → `package org.mobyle.domain.usecase`
- Use fully qualified package names (no root imports like `package mobyle`)

## Import Organization

Within each file, organize imports in this order:
1. `package` declaration
2. Standard library imports (`java.*`, `kotlin.*`)
3. Third-party imports (`io.ktor.*`, `org.koin.*`, `kotlinx.serialization.*`)
4. Internal imports (`org.mobyle.*`)

## Testing Structure

Mirror `src/main/` structure under `src/test/`:
```
src/test/kotlin/org/mobyle/
├── domain/
│   └── usecase/
│       └── GetTrendingMoviesTest.kt
├── data/
│   ├── remote/
│   │   └── TmdbDataSourceImplTest.kt
│   └── repository/
│       └── MoviesRepositoryImplTest.kt
└── presentation/
    └── routing/
        └── MoviesRoutingTest.kt
```

## Module Boundaries

Features are isolated by domain concern, not by layer. All feature-related code (domain, data, usecases) stays together.

**BAD:** Mixing `movies` domain with `reviews` data
**GOOD:** Keep all movie-related code in one place across layers

## Sealed Classes and Enums

For error handling and type safety:
```kotlin
sealed class Result<out T> {
    data class Success<T>(val data: T) : Result<T>()
    data class Failure(val exception: Exception) : Result<Nothing>()
}

enum class MovieGenre {
    ACTION, DRAMA, COMEDY
}
```

## No Magic Strings/Numbers

All configuration values and constants must be extracted:
```kotlin
// Bad
httpClient.get("https://api.themoviedb.org/3/trending/movie/week")

// Good
private const val TMDB_BASE_URL = "https://api.themoviedb.org/3"
private const val TRENDING_ENDPOINT = "trending/movie/week"

httpClient.get("$TMDB_BASE_URL/$TRENDING_ENDPOINT")
```

## Null Safety

Always use Kotlin's null safety:
```kotlin
// Use nullable types when value may not exist
val releaseDate: String? = movie.releaseDate

// Use Elvis operator for defaults
val page = call.parameters["page"]?.toIntOrNull() ?: 1

// Use safe calls and null coalescing
val title = movie?.title ?: "Unknown"
```

## Suspend Functions and Coroutines

All async operations use `suspend fun`:
```kotlin
// Good
suspend fun getTrendingMovies(page: Int): MovieListing

// Bad
fun getTrendingMovies(page: Int): Deferred<MovieListing>
fun getTrendingMovies(page: Int): CompletableFuture<MovieListing>
```

Never block coroutines. Use `runBlocking` only for bridging in usecases:
```kotlin
class GetTrendingMovies(private val repository: MoviesRepository) {
    operator fun invoke(page: Int): MovieListing = runBlocking {
        repository.getTrendingMovies(page)
    }
}
```
