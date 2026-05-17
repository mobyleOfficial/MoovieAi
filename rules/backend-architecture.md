# Backend Architecture Rule

Applies to: `backend/` submodule. Kotlin 2.0.20 + Ktor 2.3.0 + Koin 3.5.6 (per `build.gradle.kts`).

## Module Layout

Source root: `backend/src/main/kotlin/org/mobyle/`. Sub-packages:

- `org.mobyle/Main.kt` — entry point: `embeddedServer(Netty, ...)` + inline `configure*()` functions; no separate `Application.kt`
- `org.mobyle/routing/` — Route extension functions, one file per resource (e.g. `MoviesRouting.kt`, `ProfileRouting.kt`, `ActivitiesRouting.kt`)
- `org.mobyle/di/` — `appModule` (use-case bindings) + `Utils.kt` (the `injection<T>()` helper)
- `org.mobyle/model/` — Listing/wrapper response types serialized to JSON responses (e.g. `MovieListing`, `MovieReviewListing`)
- `org.mobyle/domain/model/` — Internal domain types (e.g. `Movie`, `MovieDetail`, `Genre`)
- `org.mobyle/domain/repository/` — Repository interfaces consumed by use cases
- `org.mobyle/domain/usecase/` — Use case classes; sub-packages by feature (`movies/`, `profile/`, `activities/`)
- `org.mobyle/data/repository/` — Repository implementations (delegate to `TmdbDataSource`)
- `org.mobyle/data/remote/` — `TmdbDataSource` interface, `TmdbDataSourceImpl`, and `Mappers.kt` (TMDB DTO → domain)
- `org.mobyle/data/remote/model/` — TMDB DTO types (`@Serializable` data classes with `@SerialName`)
- `org.mobyle/data/di/` — `dataModule`: `HttpClient`, `TmdbDataSource`, and repository `single {}` bindings

`backend/src/test/kotlin/org/mobyle/` mirrors `main/` exactly.

## Routing

- One routing file per top-level resource path; the function is an extension on `Route`
- All routes registered inside `configureRouting()` in `Main.kt` via `routing { getMoviesRouting(); ... }`
- Dependencies retrieved with the custom `injection<T>()` helper (defined in `di/Utils.kt`) rather than bare `by inject()`, due to a Ktor 2.x / Koin 3.x compatibility issue; do not change this pattern
- Each route validates inputs, calls a use case directly via `invoke`, and returns `call.respond(...)` with a typed body
- Minimal validation in route bodies (null-check path params, blank-check required query params); all domain logic lives in use cases and repositories

Example shape:
```kotlin
fun Route.getMoviesRouting() {
    val getMovieDetail by injection<GetMovieDetail>()

    get("/movies/{id}") {
        val movieId = call.parameters["id"]?.toIntOrNull()
        if (movieId == null) {
            call.respond(HttpStatusCode.BadRequest, "Invalid movie ID")
            return@get
        }
        call.respond(getMovieDetail(movieId))
    }
}
```

## Dependency Injection

- Two Koin modules installed in `Main.kt` → `configureKoin()`:
  - `dataModule` (`data/di/DataModule.kt`) — `single {}` bindings for `HttpClient`, `TmdbDataSource`, and all `*Repository` implementations
  - `appModule` (`di/AppModule.kt`) — `factory {}` bindings for every use case class; use cases receive repository via constructor
- Routes use `by injection<T>()` (the custom helper in `di/Utils.kt`), not `by inject()` directly
- TMDB API key read from `System.getenv("TMDB_API_KEY")` inside `dataModule`; throws `IllegalStateException` at startup if unset — never hard-coded
- No use of `ktor.application.conf` / `environment.config` — all secrets are environment variables

## Error Handling

- A single catch-all `StatusPages` block in `Main.kt` → `configureStatusPages()` maps every `Throwable` to HTTP 500 with a JSON body `{ "error": "Internal Server Error", "message": "<cause.message>" }`
- No domain-specific exceptions exist yet; the pattern to follow when introducing them:
  - Define named exception classes (e.g. `MovieNotFoundException`, `TmdbRateLimitedException`)
  - Add typed `exception<MovieNotFoundException> { call, _ -> call.respond(HttpStatusCode.NotFound, ...) }` handlers inside `StatusPages` — never `try/catch` inside route bodies
  - Rate-limit handling: catch HTTP 429 from TMDB → throw `TmdbRateLimitedException` with Retry-After value → `StatusPages` maps it to 503
- Input validation (missing/invalid params) is done inline in route bodies with early `return@get`; these do NOT go through `StatusPages`

## TMDB Integration

- Single `HttpClient(CIO)` registered as a Koin `single` in `dataModule`; Bearer token and base URL configured globally via `defaultRequest { url("https://api.themoviedb.org/3/"); headers.append(Authorization, "Bearer $apiKey") }`
- All TMDB HTTP calls are encapsulated in `TmdbDataSourceImpl`; use cases and repositories never call `HttpClient` directly
- TMDB DTOs live in `data/remote/model/TmdbResponses.kt` — all `@Serializable` with `@SerialName` for snake_case fields
- Mapper extension functions in `data/remote/Mappers.kt` convert TMDB DTOs to domain/model types; repositories call `.toDomain()` before returning results
- JSON deserialization uses `kotlinx.serialization` with `ignoreUnknownKeys = true` and `isLenient = true` to tolerate TMDB API changes
- Use case `invoke` functions use `runBlocking { repository.suspend_fun() }` rather than being `suspend` themselves — this is the current pattern; new use cases must follow it until the calling layer is made coroutine-aware
