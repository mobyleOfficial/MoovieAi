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

One test class per production class. File naming: `*Test.kt`. No test directory exists yet in `backend/`; create it as `backend/src/test/kotlin/org/mobyle/` before adding test files.

## Unit Tests

- Use case tests and mapper tests use plain JUnit 5 (no Ktor harness needed); `build.gradle.kts` already enables `useJUnitPlatform()`
- Use cases call `runBlocking` internally, so tests can call them synchronously without coroutine wrappers
- Mock injected repository/datasource dependencies via MockK (`val repository = mockk<MoviesRepository>()`) — add MockK to `build.gradle.kts` test deps (`testImplementation("io.mockk:mockk:<version>")`) before writing use-case tests
- Each public function gets at least 1 test covering the happy path and at least 1 covering the failure path (e.g. empty result, datasource exception)

Example use-case test shape:
```kotlin
class GetTrendingMoviesTest {
    private val repository = mockk<MoviesRepository>()
    private val useCase = GetTrendingMovies(repository)

    @Test
    fun `returns movie listing from repository`() {
        val expected = MovieListing(totalPages = 1, totalResults = 1, movies = listOf(/* fixture */))
        every { runBlocking { repository.getTrendingMovies(1) } } returns expected
        assertEquals(expected, useCase(1))
    }

    @Test
    fun `propagates repository exception`() {
        every { runBlocking { repository.getTrendingMovies(any()) } } throws RuntimeException("fail")
        assertThrows<RuntimeException> { useCase(1) }
    }
}
```

## Route Tests

Use Ktor's `testApplication { ... }` harness (provided by `ktor-server-tests:2.3.0`). Override Koin modules in the test application to inject test doubles:

```kotlin
@Test
fun `GET movies trending returns 200`() = testApplication {
    application {
        configureKoin() // install Koin
        configureRouting()
    }
    // Override dataModule with a test module before starting:
    // startKoin { modules(testDataModule) }
    val response = client.get("/movies/trending")
    assertEquals(HttpStatusCode.OK, response.status)
}
```

Inject test doubles by providing a test-only Koin module that replaces `dataModule` with mocked datasources. Keep route tests focused on HTTP contract (status codes, response shape) — not domain logic.

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
