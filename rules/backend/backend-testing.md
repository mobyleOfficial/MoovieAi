---
description: Rules for testing Kotlin/Ktor backend features
globs: backend/src/test/kotlin/**/*.kt
---

# Backend Testing Rules

Testing patterns and requirements for Kotlin/Ktor backend code.

## Test Structure

### Test File Naming
```
src/test/kotlin/org/mobyle/
├── domain/usecase/
│   └── GetTrendingMoviesTest.kt          # Class + Test suffix
├── data/remote/
│   └── TmdbDataSourceImplTest.kt
├── data/repository/
│   └── MoviesRepositoryImplTest.kt
└── presentation/routing/
    └── MoviesRoutingTest.kt
```

### Test Class Structure
```kotlin
class GetTrendingMoviesTest {

    private lateinit var repository: MoviesRepository
    private lateinit var usecase: GetTrendingMovies

    @Before
    fun setup() {
        repository = mockk()
        usecase = GetTrendingMovies(repository)
    }

    @Test
    fun `should return movies for valid page number`() {
        // Given
        val page = 1
        val expected = MovieListing(emptyList(), 0, 0, 0)
        coEvery { repository.getTrendingMovies(page) } returns expected

        // When
        val result = usecase(page)

        // Then
        assertEquals(expected, result)
    }
}
```

## Testing Layers

### Domain Layer Tests (UseCases)

Test that usecases orchestrate repository calls correctly:
```kotlin
class GetTrendingMoviesTest {

    private val repository = mockk<MoviesRepository>()
    private val usecase = GetTrendingMovies(repository)

    @Test
    fun `should call repository with correct page number`() {
        val page = 2
        coEvery { repository.getTrendingMovies(page) } returns
            MovieListing(emptyList(), 0, 0, 0)

        usecase(page)

        coVerify { repository.getTrendingMovies(page) }
    }

    @Test
    fun `should return repository result directly`() {
        val expected = MovieListing(
            movies = listOf(Movie(id = 1, title = "Test")),
            totalResults = 1,
            totalPages = 1,
            page = 1
        )
        coEvery { repository.getTrendingMovies(any()) } returns expected

        val result = usecase(1)

        assertEquals(expected, result)
    }
}
```

### Data Layer Tests (Repositories)

Test that repositories map DTOs to domain models:
```kotlin
class MoviesRepositoryImplTest {

    private val datasource = mockk<TmdbDataSource>()
    private val repository = MoviesRepositoryImpl(datasource)

    @Test
    fun `should map datasource response to domain model`() {
        // Given
        val dtoResponse = TmdbMovieListResponse(
            page = 1,
            results = listOf(
                TmdbMovie(id = 1, title = "Movie 1")
            ),
            totalPages = 1,
            totalResults = 1
        )
        coEvery { datasource.getTrendingMovies(any()) } returns dtoResponse

        // When
        val result = repository.getTrendingMovies(1)

        // Then
        assertEquals(1, result.movies.size)
        assertEquals("Movie 1", result.movies[0].title)
    }

    @Test
    fun `should propagate datasource exceptions`() {
        coEvery { datasource.getTrendingMovies(any()) } throws
            IOException("Network error")

        assertFailsWith<IOException> {
            runBlocking { repository.getTrendingMovies(1) }
        }
    }
}
```

### Data Source Tests (HTTP Client)

Test that datasources correctly format HTTP requests:
```kotlin
class TmdbDataSourceImplTest {

    private val httpClient = mockk<HttpClient>()
    private val datasource = TmdbDataSourceImpl(httpClient)

    @Test
    fun `should request trending endpoint with page parameter`() {
        val response = mockk<HttpResponse>()
        coEvery { response.body<TmdbMovieListResponse>() } returns
            TmdbMovieListResponse()
        coEvery {
            httpClient.get("trending/movie/week", any())
        } returns response

        datasource.getTrendingMovies(page = 2)

        coVerify {
            httpClient.get("trending/movie/week", any())
        }
    }

    @Test
    fun `should include all optional parameters when provided`() {
        val response = mockk<HttpResponse>()
        coEvery { response.body<TmdbMovieListResponse>() } returns
            TmdbMovieListResponse()
        coEvery { httpClient.get(any(), any()) } returns response

        datasource.discoverMovies(
            page = 1,
            year = 2024,
            genres = "28,12",  // Action, Adventure
            language = "en"
        )

        coVerify {
            httpClient.get("discover/movie", any())
        }
    }
}
```

## Testing Best Practices

### Use Mock Framework
```kotlin
// Good - using mockk for Kotlin
import io.mockk.mockk
import io.mockk.coEvery
import io.mockk.coVerify

val repository = mockk<MoviesRepository>()
coEvery { repository.getTrendingMovies(any()) } returns MovieListing(...)
coVerify { repository.getTrendingMovies(1) }

// Bad - manual mocks (error-prone)
class FakeRepository : MoviesRepository {
    override suspend fun getTrendingMovies(page: Int): MovieListing = ...
}
```

### Test Names Describe Behavior
```kotlin
// Good - describes what is being tested and expected outcome
fun `should return empty list when no movies available`() { }
fun `should throw exception when network fails`() { }
fun `should map DTO to domain model correctly`() { }
fun `should include sort parameter only when provided`() { }

// Bad - vague or implementation-focused names
fun `test getTrendingMovies`() { }
fun `test method1`() { }
fun `test response parsing`() { }
```

### Arrange-Act-Assert Pattern
```kotlin
@Test
fun `should return movies sorted by popularity`() {
    // Arrange - set up test data
    val movies = listOf(
        Movie(id = 1, title = "Popular", voteAverage = 9.0),
        Movie(id = 2, title = "Less Popular", voteAverage = 5.0)
    )
    coEvery { repository.getTrendingMovies(1) } returns
        MovieListing(movies = movies, totalResults = 2, totalPages = 1, page = 1)

    // Act - perform the action
    val result = usecase(1)

    // Then - assert the outcome
    assertEquals("Popular", result.movies[0].title)
    assertEquals("Less Popular", result.movies[1].title)
}
```

### Test Edge Cases
```kotlin
@Test
fun `should handle empty results`() {
    coEvery { datasource.getTrendingMovies(any()) } returns
        TmdbMovieListResponse(results = emptyList())

    val result = repository.getTrendingMovies(1)

    assertTrue(result.movies.isEmpty())
    assertEquals(0, result.totalResults)
}

@Test
fun `should handle null optional fields`() {
    val movie = TmdbMovie(
        id = 1,
        title = "Test",
        posterPath = null,      // Optional field
        releaseDate = null      // Optional field
    )

    val domainMovie = movie.toDomain()

    assertEquals(1, domainMovie.id)
    assertNull(domainMovie.posterPath)
}
```

## Suspend Function Testing

### Test Suspend Functions with runBlocking
```kotlin
@Test
fun `should fetch and return movies`() = runBlocking {
    coEvery { datasource.getTrendingMovies(1) } returns
        TmdbMovieListResponse(
            results = listOf(TmdbMovie(id = 1, title = "Test"))
        )

    val result = repository.getTrendingMovies(1)

    assertEquals(1, result.movies.size)
}
```

Or use `coRunBlocking` from kotlinx-coroutines-test:
```kotlin
@Test
fun `should handle coroutine exceptions`() = runBlocking {
    coEvery { datasource.getTrendingMovies(any()) } throws
        Exception("Network error")

    assertFailsWith<Exception> {
        repository.getTrendingMovies(1)
    }
}
```

## Coverage Requirements

### Required Test Coverage
- **All public usecases** — At least 1 test per public method
- **All repository implementations** — Test mapping and datasource delegation
- **Error cases** — Test exception handling and validation
- **Edge cases** — Empty lists, null values, boundary conditions

### Optional Test Coverage
- **DataSource HTTP calls** — Only if custom logic beyond Ktor client
- **Serialization** — If custom JSON mapping beyond @Serializable
- **Routing** — Integration tests with mock DI if critical

## Test Dependencies

### Required in build.gradle.kts
```kotlin
testImplementation("io.mockk:mockk:1.13.0")
testImplementation("org.jetbrains.kotlinx:kotlinx-coroutines-test:1.7.0")
testImplementation("junit:junit:4.13.2")
testImplementation("org.assertj:assertj-core:3.23.0")
```

### Example Test Setup
```kotlin
import io.mockk.mockk
import io.mockk.coEvery
import io.mockk.coVerify
import kotlinx.coroutines.runBlocking
import org.junit.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith

class UsecaseTest {
    private val repository = mockk<Repository>()

    @Test
    fun test() = runBlocking {
        // test code
    }
}
```

## Continuous Integration

### Run Tests Locally Before Push
```bash
./gradlew test
```

### CI Will Run
```bash
./gradlew clean test
```

All tests must pass before PR merge. Failing tests block merge.
