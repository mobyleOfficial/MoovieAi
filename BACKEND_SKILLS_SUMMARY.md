# Backend Skills Implementation - Summary

## Overview

Successfully replicated and adapted the frontend skills for the backend, organizing them into three categories: **common**, **frontend**, and **backend**.

## Skills Organization

### Directory Structure

```
skills/
├── README.md                           # Main skills documentation
├── common/                             # Shared across frontend & backend
│   ├── moovie-research-format/         # Design doc format
│   ├── setting-up-linear-mcp/          # Linear MCP setup
│   └── verify-docs-before-pr.md        # PR documentation verification
├── frontend/                           # Flutter/Dart specific
│   ├── README.md
│   ├── new-usecase.md                 # Dart usecase scaffold
│   ├── new-datasource.md              # Dart datasource scaffold
│   ├── new-repository.md              # Dart repository scaffold
│   └── new-ui-module.md               # Flutter BLoC scaffold
└── backend/                            # Kotlin/Ktor specific
    ├── new-kotlin-usecase.md          # Kotlin usecase scaffold
    ├── new-kotlin-datasource.md       # Ktor HTTP client scaffold
    ├── new-kotlin-repository.md       # Kotlin repository scaffold
    └── new-ktor-endpoint.md           # Ktor API routing scaffold
```

## Backend Skills Created

### 1. `/new-kotlin-usecase`
**Purpose:** Scaffold a new usecase in the Kotlin backend domain layer

**Key Features:**
- Generates concrete Kotlin classes (not abstract base classes)
- Uses `operator fun invoke()` for invocation
- Uses `runBlocking { }` to bridge suspend repository functions
- Parameters as function arguments with defaults (not parameter classes)
- Ready for Koin DI registration

**Example Generated Code:**
```kotlin
class GetTrendingMovies(private val repository: MoviesRepository) {
    operator fun invoke(page: Int): MovieListing = runBlocking {
        repository.getTrendingMovies(page)
    }
}
```

### 2. `/new-kotlin-datasource`
**Purpose:** Scaffold a Ktor HTTP client datasource

**Key Features:**
- Interface contract + implementation
- Uses Ktor `HttpClient` with async/await
- Returns response DTOs directly (not wrapped)
- Uses `@Serializable` and `@SerialName` for TMDB API mapping
- Automatic JSON serialization via Ktor
- Parameters as nullable function arguments with defaults

**Example Generated Code:**
```kotlin
interface TmdbDataSource {
    suspend fun getTrendingMovies(page: Int): TmdbMovieListResponse
}

class TmdbDataSourceImpl(private val httpClient: HttpClient) : TmdbDataSource {
    override suspend fun getTrendingMovies(page: Int): TmdbMovieListResponse {
        return httpClient.get("trending/movie/week") {
            parameter("page", page)
        }.body()
    }
}
```

### 3. `/new-kotlin-repository`
**Purpose:** Scaffold a repository interface and implementation

**Key Features:**
- Domain layer interface with suspend functions
- Data layer implementation with DTO mapping
- Uses extension functions for mapping (`toDomain()`)
- Simple delegation pattern from datasource to domain models
- Ready for Koin registration

**Example Generated Code:**
```kotlin
interface MoviesRepository {
    suspend fun getTrendingMovies(page: Int): MovieListing
}

class MoviesRepositoryImpl(private val tmdbDataSource: TmdbDataSource) : MoviesRepository {
    override suspend fun getTrendingMovies(page: Int): MovieListing {
        return tmdbDataSource.getTrendingMovies(page).toDomain()
    }
}
```

### 4. `/new-ktor-endpoint`
**Purpose:** Scaffold a Ktor API endpoint with routing and DI

**Key Features:**
- Extension function pattern for routing
- Lazy dependency injection via `by inject<T>()`
- Safe parameter parsing with `toIntOrNull()`
- Input validation before usecase invocation
- Automatic JSON response serialization
- Proper HTTP status codes (400, 404, 500)

**Example Generated Code:**
```kotlin
fun Route.getMoviesRouting() {
    val getTrendingMovies by inject<GetTrendingMovies>(GetTrendingMovies::class.java)

    get("/trending") {
        val page = call.parameters["page"]?.toIntOrNull() ?: 1
        call.respond(getTrendingMovies(page))
    }
}
```

## Key Architectural Differences

### Dart (Frontend) vs Kotlin (Backend)

| Aspect | Dart | Kotlin |
|--------|------|--------|
| **Error Handling** | `Result<T>` sealed class | Direct exceptions |
| **Async Model** | `Future<T>` / `Stream<T>` | `suspend fun` coroutines |
| **UseCase Base** | Generic abstract class | Concrete with operator `invoke()` |
| **Parameters** | Dedicated parameter classes | Function arguments with defaults |
| **DI Framework** | Injectable (code gen) | Koin (runtime) |
| **Singletons** | `@LazySingleton` | `single { }` |
| **Factories** | `@injectable` | `factory { }` |
| **Response DTOs** | Separate from domain | Separate from domain (same pattern) |
| **Mapping** | `toDomain()` extensions | `toDomain()` extensions |

## Usage Examples

### Adding a New Backend Feature

1. **Create the domain model:**
   ```kotlin
   // backend/src/main/kotlin/org/mobyle/domain/model/MyModel.kt
   ```

2. **Create the repository:**
   ```bash
   /new-kotlin-repository
   ```
   Answer: MyModels, TmdbDataSource, list methods

3. **Create the datasource:**
   ```bash
   /new-kotlin-datasource
   ```
   Answer: Tmdb, list HTTP methods

4. **Create use cases:**
   ```bash
   /new-kotlin-usecase
   ```
   Answer for each: UseCaseName, input type, output type, repository

5. **Create API endpoint:**
   ```bash
   /new-ktor-endpoint
   ```
   Answer: mymodels, HTTP methods, list usecases

6. **Register in DI:**
   - DataModule (datasource + repository)
   - AppModule (usecases)
   - Update `Application.kt` routing

### Adding a New Frontend Feature

The frontend workflow remains unchanged - use the existing `/new-usecase`, `/new-datasource`, `/new-repository`, `/new-ui-module` skills.

## Migration Path

**If transitioning from frontend to backend development:**

1. Familiar patterns:
   - ✅ Repositories with datasources
   - ✅ Mapping DTOs to domain models
   - ✅ Dependency injection
   - ✅ Use case pattern

2. Key differences to learn:
   - ❌ No Result<T> wrapper (use exceptions)
   - ❌ No Future/Stream (use suspend fun)
   - ❌ No parameter classes (use function arguments)
   - ❌ No generic usecase base class

## Integration with Existing Backend

All backend skills are designed to work with the existing Ktor/Kotlin architecture:

- **Datasources:** Use existing `TmdbDataSource` pattern
- **Repositories:** Follow `MoviesRepositoryImpl` pattern
- **UseCases:** Match `GetTrendingMovies` pattern
- **Routing:** Extend existing `MoviesRouting` pattern
- **DI:** Integrate with existing Koin modules

## Benefits

✅ **Consistency:** Both frontend and backend follow clean architecture
✅ **Productivity:** Code scaffolding saves time for new features
✅ **Quality:** Generated code follows best practices
✅ **Maintainability:** Standardized patterns across the entire ecosystem
✅ **Onboarding:** New developers can use skills to learn the codebase structure

## Next Steps

1. **Register backend skills** in `.claude/settings.json` local skills marketplace
2. **Train team members** on new backend workflow
3. **Update CI/CD** to validate backend code generation (optional)
4. **Document API contracts** for mobile app integration
