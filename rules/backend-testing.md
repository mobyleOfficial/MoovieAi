# Backend Testing Rule

Applies to: `backend/src/test/kotlin/`. Aligns with `rules/backend-architecture.md`.

## Test Structure

`backend/src/test/kotlin/org/mobyle/` mirrors `main/`:
- `routing/MoviesRoutingTest.kt` tests `routing/MoviesRouting.kt`
- `routing/ProfileRoutingTest.kt` tests `routing/ProfileRouting.kt`
- `routing/ActivitiesRoutingTest.kt` tests `routing/ActivitiesRouting.kt`
- `domain/usecase/movies/GetTrendingMoviesTest.kt` tests `domain/usecase/movies/GetTrendingMovies.kt`
- `data/remote/TmdbDataSourceImplTest.kt` tests `data/remote/TmdbDataSourceImpl.kt`
- `data/remote/MappersTest.kt` tests `data/remote/Mappers.kt`

One test class per production class. File naming: `*Test.kt`. The test tree is prescribed to mirror `main/` exactly; create `backend/src/test/kotlin/org/mobyle/` before adding test files (no `src/test/kotlin/` exists today).

## Unit Tests

- Use case tests and mapper tests use plain JUnit 5 (no Ktor harness needed); `build.gradle.kts` already enables `useJUnitPlatform()`
- Before writing unit tests, add an explicit `testImplementation(kotlin("test"))` (which brings `kotlin-test-junit5`) or an explicit JUnit Jupiter dep alongside MockK to avoid silent classpath gaps — `ktor-server-tests:2.3.0` provides transitives that may not resolve depending on Gradle classpath
- Use cases call `runBlocking` internally, so tests can call them synchronously without coroutine wrappers
- Mock injected repository/datasource dependencies via MockK (`val repository = mockk<MoviesRepository>()`) — add MockK to `build.gradle.kts` test deps (`testImplementation("io.mockk:mockk:1.13.13")  // or latest 1.13.x from Maven Central`) before writing use-case tests
- Each public function gets at least 1 test covering the happy path and at least 1 covering the failure path (e.g. empty result, datasource exception)

Example use-case test shape:
```kotlin
class GetTrendingMoviesTest {
    private val repository = mockk<MoviesRepository>()
    private val useCase = GetTrendingMovies(repository)

    @Test
    fun `returns movie listing from repository`() {
        val expected = MovieListing(totalPages = 1, totalResults = 1, movies = listOf(/* fixture */))
        coEvery { repository.getTrendingMovies(1) } returns expected
        assertEquals(expected, useCase(1))
    }

    @Test
    fun `propagates repository exception`() {
        coEvery { repository.getTrendingMovies(any()) } throws RuntimeException("fail")
        assertThrows<RuntimeException> { useCase(1) }
    }
}
```

Note: use `coEvery { ... }` (not `every { runBlocking { ... } }`) for suspend-function stubs — MockK throws `MockKException: Missing calls inside every { } block` with the `runBlocking` form. Because production use-case `invoke` functions call `runBlocking` internally, the test body itself does not need a coroutine wrapper.

## Route Tests

Use Ktor's `testApplication { ... }` harness (provided by `ktor-server-tests:2.3.0`). Because `configureKoin()` installs `dataModule` which throws `IllegalStateException` if `TMDB_API_KEY` is unset (lazily on first request), Koin must be replaced with a test module BEFORE `testApplication` starts — not inside `application { }`:

```kotlin
@Test
fun `GET trending movies returns 200`() {
    stopKoin()  // tear down any previously started Koin instance
    startKoin {
        modules(testDataModule)  // test module overriding dataModule; provides mocked TmdbDataSource
    }
    testApplication {
        // Do NOT call configureKoin() here — Koin is already running with test doubles
        application { configureRouting(); configureStatusPages() }
        val response = client.get("/movies/trending?page=1")
        assertEquals(HttpStatusCode.OK, response.status)
    }
}
```

Where `testDataModule` is a Koin module that binds `TmdbDataSource`, all `*Repository` implementations, and all use cases with MockK doubles (or in-memory stubs) so no real TMDB call is made. Keep route tests focused on HTTP contract (status codes, response shape) — not domain logic.

## TMDB Mocking

- Never call the real TMDB API in tests; all tests must pass with `TMDB_API_KEY` unset
- Mock `TmdbDataSource` via MockK; return DTO fixture instances constructed inline or loaded from `src/test/resources/tmdb/<endpoint>.json`
- For HTTP-level tests of `TmdbDataSourceImpl`, use Ktor's `MockEngine` with canned response bodies rather than a real `HttpClient(CIO)`:

```kotlin
val mockEngine = MockEngine { request ->
    respond(
        content = ByteReadChannel(File("src/test/resources/tmdb/trending.json").readText()),
        status = HttpStatusCode.OK,
        headers = headersOf(HttpHeaders.ContentType, "application/json")
    )
}
val client = HttpClient(mockEngine) { install(ContentNegotiation) { json() } }
val ds = TmdbDataSourceImpl(client)
```

- Rate-limit test: configure `MockEngine` to return HTTP 429; assert that the client or repository layer throws the appropriate exception (once `TmdbRateLimitedException` is introduced per `backend-architecture.md`)

## Coverage Expectations

- All route handlers: 1 happy-path + 1 error-path test (at minimum: missing/invalid param → 400, valid param → 200/201)
- All use case `invoke` functions: at least 1 unit test each (happy path + exception propagation)
- All `TmdbDataSourceImpl` methods: 1 success test + 1 rate-limit/error test
- All mapper extension functions in `Mappers.kt`: at least 1 round-trip test per domain type
- `./gradlew test` must pass (zero failures) before any PR opens

No numeric coverage percentage gate — gate is on the per-class expectations above.
