# Skills

Custom Claude workflows and scaffolding skills for automation and repeated patterns in the MoovieAi ecosystem.

## Organization

Skills are organized into three categories:

### Common Skills (Both Frontend & Backend)

These skills are applicable to both the Flutter frontend and Kotlin backend:

- **`moovie-research-format`** — Standardized format for design docs, architecture decisions, and research documentation
- **`setting-up-linear-mcp`** — Configure Linear MCP at project level with workspace scoping and secure token storage
- **`verify-docs-before-pr`** — Documentation verification before PR creation

### Frontend Skills (Flutter/Dart)

Feature scaffolding skills for the Flutter frontend with Dart and BLoC pattern:

- **`/new-usecase`** — Scaffold a new usecase in a feature's domain layer (Dart)
- **`/new-datasource`** — Scaffold a remote or local datasource (contract + implementation)
- **`/new-repository`** — Scaffold a repository contract (domain) and implementation (data)
- **`/new-ui-module`** — Scaffold a complete UI module (state + bloc + screen)

**Path:** `skills/frontend/`

### Backend Skills (Kotlin/Ktor)

Feature scaffolding skills for the Ktor backend with Kotlin:

- **`/new-kotlin-usecase`** — Scaffold a new usecase in the backend domain layer
- **`/new-kotlin-datasource`** — Scaffold a datasource interface and TMDB HTTP client implementation
- **`/new-kotlin-repository`** — Scaffold a repository interface (domain) and implementation (data)
- **`/new-ktor-endpoint`** — Scaffold a new API endpoint with Ktor routing

**Path:** `skills/backend/`

## Usage

Invoke skills via `/skill-name` in Claude Code or use the Skill tool:

```bash
# Frontend
/new-usecase         # Dart usecase
/new-ui-module       # Flutter screen

# Backend
/new-kotlin-usecase  # Kotlin usecase
/new-ktor-endpoint   # Ktor API endpoint

# Common
/moovie-research-format
/verify-docs-before-pr
```

## Architecture Patterns

### Frontend (Dart/Flutter)

- **Error handling:** `Result<T>` sealed class (Success/Failure)
- **Async:** `Future<T>` + `Stream<T>`
- **UseCase:** Generic `UseCase<Params, Response>` base class
- **DI:** Injectable with code generation (GetIt)
- **State management:** BLoC/Cubit pattern

### Backend (Kotlin/Ktor)

- **Error handling:** Direct exceptions (no wrapper)
- **Async:** `suspend fun` coroutines
- **UseCase:** Concrete classes with `operator fun invoke()`
- **DI:** Koin with runtime module registration
- **HTTP client:** Ktor client with automatic serialization

## Key Differences

| Aspect | Frontend (Dart) | Backend (Kotlin) |
|--------|---|---|
| **Error** | `Result<T>` wrapper | Exceptions |
| **Async** | `Future<T>` | `suspend fun` |
| **UseCase Pattern** | Generic base class | Concrete classes |
| **Parameters** | Parameter classes | Function defaults |
| **DI** | Code generation (injectable) | Runtime (Koin) |
| **Singletons** | `@LazySingleton` | `single { }` |
| **Factories** | `@injectable` | `factory { }` |

## When to Use Each Skill

- **Use frontend skills** when adding features to the Flutter mobile app (movies, reviews, profile screens)
- **Use backend skills** when adding features to the Ktor API backend (new endpoints, repositories, datasources)
- **Use common skills** for cross-repo documentation, PR verification, and setup tasks

## Generated Code Quality

All scaffolding skills generate code that:
- ✅ Follows established architectural patterns
- ✅ Satisfies dependency injection setup
- ✅ Includes proper type safety and null handling
- ✅ Is ready for immediate integration (no post-generation fixes needed)

Simply answer the prompts, and the generated code is production-ready.
