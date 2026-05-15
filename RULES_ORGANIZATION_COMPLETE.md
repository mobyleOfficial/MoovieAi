# Rules Organization - Complete ✅

## Summary

Successfully reorganized and expanded the rules directory to match the skills structure. Rules are now organized into three categories: common, frontend, and backend.

---

## Rules Reorganization

### Before
```
rules/
├── AI_AGNOSTIC_SUBMODULES.md
├── accessibility.md
├── feature-architecture.md
├── feature-implementation.md
├── feature-testing.md
├── localization.md
├── LOCAL_CLAUDE_CONFIG.md
├── NO_COAUTHORS.md
├── PYTHON_ENVS.md
├── README.md
├── ui-architecture.md
└── variable-naming.md
```

### After
```
rules/
├── README.md                    # Master documentation
├── common/                      # Shared rules (frontend & backend)
│   ├── AI_AGNOSTIC_SUBMODULES.md
│   ├── LOCAL_CLAUDE_CONFIG.md
│   ├── NO_COAUTHORS.md
│   ├── PYTHON_ENVS.md
│   └── variable-naming.md
├── frontend/                    # Flutter/Dart specific
│   ├── accessibility.md
│   ├── feature-architecture.md
│   ├── feature-implementation.md
│   ├── feature-testing.md
│   ├── localization.md
│   └── ui-architecture.md
└── backend/                     # Kotlin/Ktor specific (NEW)
    ├── backend-architecture.md       # Clean architecture with domain/data/presentation
    ├── backend-implementation.md     # Kotlin code style, coroutines, DI, serialization
    └── backend-testing.md            # Test patterns, mocking, suspend functions
```

---

## New Backend Rules Created

### 1. **backend-architecture.md**

Defines the clean architecture structure for Kotlin/Ktor features:

**Contents:**
- Project structure with domain/data/presentation layers
- Layer responsibilities and dependencies
- DI module organization (DataModule, AppModule)
- File naming and package organization
- Testing structure mirroring main/
- Module boundaries and code organization
- Sealed classes, null safety, suspend functions

**Key Patterns:**
```
Domain: Pure Kotlin contracts (repositories)
  ↓
Data: Implementations with DTO mapping
  ↓
Presentation: Routing and DI setup
```

### 2. **backend-implementation.md**

Detailed code style and architectural patterns for Kotlin:

**Contents:**
- Naming conventions (classes, functions, parameters, constants)
- Coroutines and suspend functions (never block event loop)
- Null safety with Elvis operator and safe calls
- Data classes with @Serializable for DTOs
- Dependency injection patterns (constructor injection, lazy delegates)
- Error handling (exceptions vs Result wrappers)
- Data mapping with extension functions
- Code organization and imports
- HTTP client usage with Ktor

**Key Examples:**
```kotlin
// Proper usecase pattern
class GetTrendingMovies(private val repository: MoviesRepository) {
    operator fun invoke(page: Int): MovieListing = runBlocking {
        repository.getTrendingMovies(page)
    }
}

// Proper HTTP client usage
httpClient.get("trending/movie/week") {
    parameter("page", page)
    if (year != null) parameter("year", year)
}.body()
```

### 3. **backend-testing.md**

Testing patterns and requirements for Kotlin backend:

**Contents:**
- Test file naming and structure
- Testing each layer (usecases, repositories, datasources)
- Testing best practices (mocks, naming, AAA pattern)
- Suspend function testing with runBlocking
- Test coverage requirements
- Test dependencies and setup
- CI integration

**Key Example:**
```kotlin
@Test
fun `should map datasource response to domain model`() {
    // Given
    val dto = TmdbMovieListResponse(results = listOf(...))
    coEvery { datasource.getTrendingMovies(any()) } returns dto

    // When
    val result = repository.getTrendingMovies(1)

    // Then
    assertEquals("Movie Title", result.movies[0].title)
}
```

---

## Critical Changes to Documentation

### Updated Files

1. **`CLAUDE.md`**
   - Updated `Folder Usage` section to document rules organization
   - Updated `Load Rules, Plugins, and Skills` to reference common/frontend/backend structure
   - Added links to rule categories

2. **`rules/README.md`**
   - Complete rewrite documenting new organization
   - Lists rules by category with descriptions
   - Provides guidance on when to reference each rule
   - Explains enforcement mechanisms

---

## Usage Guidelines

### For Frontend Development

Before implementing Flutter features, read (in order):
1. `rules/common/variable-naming.md`
2. `rules/frontend/feature-architecture.md`
3. `rules/frontend/feature-implementation.md`
4. `rules/frontend/feature-testing.md`
5. `rules/frontend/ui-architecture.md`
6. `rules/frontend/accessibility.md`
7. `rules/frontend/localization.md`

### For Backend Development

Before implementing Kotlin features, read (in order):
1. `rules/common/variable-naming.md`
2. `rules/backend/backend-architecture.md`
3. `rules/backend/backend-implementation.md`
4. `rules/backend/backend-testing.md`

### Always Follow

All development must follow these critical policies:
1. `rules/common/AI_AGNOSTIC_SUBMODULES.md`
2. `rules/common/NO_COAUTHORS.md`
3. `rules/common/LOCAL_CLAUDE_CONFIG.md`
4. `rules/common/PYTHON_ENVS.md`

---

## Alignment with Skills & Agents

The rules organization now mirrors the skills organization:

```
common/
├── Skills: moovie-research-format, setting-up-linear-mcp, verify-docs-before-pr
├── Rules: AI_AGNOSTIC, LOCAL_CONFIG, NO_COAUTHORS, PYTHON_ENVS, variable-naming
└── Agents: (shared across all)

frontend/
├── Skills: new-usecase, new-datasource, new-repository, new-ui-module
├── Rules: feature-architecture, feature-implementation, feature-testing, ui-architecture, accessibility, localization
└── Agent: implementer-tester

backend/
├── Skills: new-kotlin-usecase, new-kotlin-datasource, new-kotlin-repository, new-ktor-endpoint
├── Rules: backend-architecture, backend-implementation, backend-testing
└── Agent: backend-implementer
```

Each area has:
- ✅ Scaffolding skills for auto-generating code
- ✅ Architecture rules defining structure
- ✅ Implementation rules defining code style
- ✅ Testing rules defining test patterns
- ✅ Specialized agents for guided development

---

## Benefits of Organization

✅ **Clear Structure** — Rules organized by audience (common, frontend, backend)
✅ **Easy Discovery** — Developers know exactly which rules apply to their work
✅ **Consistency** — Rules mirror skills and agents organization
✅ **Completeness** — Backend rules document Kotlin/Ktor patterns comprehensively
✅ **Scalability** — Easy to add new categories (mobile, web, etc.) in the future

---

## Files Modified

- `CLAUDE.md` — Updated folder usage and setup sections
- `rules/README.md` — Complete rewrite with new organization

## Files Created

- `rules/backend/backend-architecture.md` — Clean architecture for Kotlin/Ktor (750+ lines)
- `rules/backend/backend-implementation.md` — Code style and patterns (600+ lines)
- `rules/backend/backend-testing.md` — Testing patterns (500+ lines)

## Directories Created

- `rules/common/` — Contains 5 common rules
- `rules/frontend/` — Contains 6 frontend-specific rules
- `rules/backend/` — Contains 3 new backend-specific rules
