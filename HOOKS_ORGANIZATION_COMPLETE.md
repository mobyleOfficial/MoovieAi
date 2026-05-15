# Hooks Organization - Complete ✅

## Summary

Successfully reorganized and expanded the hooks directory to match the skills and rules structure. Hooks are now organized into three categories with three new backend-specific hooks.

---

## Hooks Reorganization

### Before
```
hooks/
├── block-cross-feature-data-imports.sh
├── block-destructive-commands.sh
├── enforce-path-restrictions.sh
├── format-code.sh
├── human-gate-review.sh
├── pipeline-coordinator.sh
├── regenerate-generated-files.sh
├── validate-implementation.sh
├── validate-localization.sh
├── validate-module-structure.sh
├── validate-spec.sh
└── verify-di-registration.sh
```

### After
```
hooks/
├── README.md                            # Master documentation
├── common/                (5 hooks)     # Shared validation
│   ├── block-destructive-commands.sh
│   ├── enforce-path-restrictions.sh
│   ├── human-gate-review.sh
│   ├── pipeline-coordinator.sh
│   └── validate-spec.sh
├── frontend/              (7 hooks)     # Flutter/Dart validation
│   ├── block-cross-feature-data-imports.sh
│   ├── format-code.sh
│   ├── regenerate-generated-files.sh
│   ├── validate-implementation.sh
│   ├── validate-localization.sh
│   ├── validate-module-structure.sh
│   └── verify-di-registration.sh
└── backend/               (3 NEW hooks) # Kotlin/Ktor validation
    ├── verify-koin-di-registration.sh
    ├── validate-backend-structure.sh
    └── validate-kotlin-code.sh
```

---

## New Backend Hooks Created

### 1. **verify-koin-di-registration.sh** (95 lines)

Verifies that all new Kotlin components are properly registered in Koin DI modules.

**Checks:**
- New usecases are registered in AppModule
- New datasources/repositories are registered in DataModule
- Proper Koin module structure maintained

**Applied to:** Domain, data, and presentation layer changes
**Raises:** Error if DI registration missing

**Example Error:**
```
❌ Koin DI Registration Issues:
  - Usecase not registered in AppModule: GetTrendingMovies

Update Koin modules:
  - backend/src/main/kotlin/org/mobyle/data/di/DataModule.kt
  - backend/src/main/kotlin/org/mobyle/presentation/di/AppModule.kt
```

### 2. **validate-backend-structure.sh** (110 lines)

Validates backend follows clean architecture with proper layer separation.

**Checks:**
- Files are in correct domain/data/presentation directories
- Package names match directory structure
- File naming conventions (camelCase.kt or PascalCase.kt)
- One class per file (warns on multiple)
- Suspend functions used in data layer

**Applied to:** Kotlin file creation/edits
**Raises:** Error on structure violations, warning on style issues

**Example Error:**
```
❌ Backend Structure Issues:
File must be in domain/, data/, or presentation/ layer
File in domain/repository/ must declare package org.mobyle.domain.repository
```

### 3. **validate-kotlin-code.sh** (115 lines)

Validates Kotlin code follows backend-implementation.md patterns.

**Error Checks (blocking):**
- No `Thread.sleep()` in suspend functions (kills coroutine performance)
- `runBlocking` only in usecases (never in routing)
- No Result<T> wrappers in suspend functions (exceptions bubble up)
- No Future/CompletableFuture (use suspend fun instead)

**Warning Checks (informational):**
- Many mutable variables (prefer val)
- Callback-style functions (use suspend fun instead)
- URL string concatenation (use constants)
- Magic numbers (extract to constants)
- Single-letter variables (except i, j in loops)

**Applied to:** Kotlin implementation files
**Raises:** Error on violations, warning on style suggestions

**Example Error:**
```
❌ Kotlin Code Issues:
DO NOT use Thread.sleep() in suspend functions — use delay() or restructure
```

**Example Warning:**
```
⚠️  Kotlin Code Suggestions:
  - Magic number detected - extract to named constant (e.g., const val TIMEOUT_MS)
  - Single-letter variables found - use descriptive names (e.g., movieId not m)
```

---

## Hook Integration

Each hook is integrated into agents via frontmatter:

### Common Hooks
Applied to all agents and operations:
- `block-destructive-commands.sh` — PreToolUse on Bash (prevents rm -rf, reset --hard, etc.)
- `enforce-path-restrictions.sh` — PreToolUse on Edit/Write (validates portable paths)

### Frontend Hooks
Applied to implementer-tester agent:
- `format-code.sh` — PostToolUse on Edit/Write (runs dart format)
- `regenerate-generated-files.sh` — PostToolUse (runs build_runner)
- `verify-di-registration.sh` — Stop hook (validates GetIt registration)
- `validate-implementation.sh` — Stop hook (validates Dart patterns)
- `validate-module-structure.sh` — Stop hook (validates feature structure)
- `validate-localization.sh` — Stop hook (validates ARB files)
- `block-cross-feature-data-imports.sh` — PreToolUse on Edit (enforces boundaries)

### Backend Hooks
Applied to backend-implementer agent:
- `verify-koin-di-registration.sh` — Stop hook (validates Koin registration)
- `validate-backend-structure.sh` — Stop hook (validates clean architecture)
- `validate-kotlin-code.sh` — Stop hook (validates Kotlin patterns)

---

## Documentation

### Updated Files
- `CLAUDE.md` — Added hooks section with category breakdown
- `hooks/README.md` — Comprehensive documentation (350+ lines)

### Content of hooks/README.md

1. **Organization** — Describes three categories with purpose
2. **Hook Descriptions** — Each hook with checks and application points
3. **Hook Integration** — Shows how hooks connect to agents
4. **Execution Points** — Explains PreToolUse, PostToolUse, Stop hooks
5. **Writing New Hooks** — Template and guidelines
6. **Local Execution** — How to test hooks manually
7. **Common Patterns** — Code examples for common hook tasks

---

## Benefits of Organization

✅ **Clear Structure** — Developers know which hooks apply to their work
✅ **Consistent** — Mirrors skills and rules organization
✅ **Frontend Support** — 7 hooks validating Dart/Flutter patterns
✅ **Backend Support** — 3 new hooks validating Kotlin/Ktor patterns
✅ **Architecture Safety** — Prevents common mistakes before they cause runtime errors
✅ **Quality Enforcement** — Automated checks for code style and patterns

---

## Total Hooks: 15

- ✅ 5 common hooks (all development)
- ✅ 7 frontend hooks (Flutter/Dart)
- ✅ 3 backend hooks (Kotlin/Ktor) — NEW

---

## Ecosystem Complete 🎉

All directories now follow consistent organization:

```
Folder         | Common | Frontend | Backend | Total
---------------|--------|----------|---------|-------
skills/        |   3    |    4     |    4    |  11
rules/         |   5    |    6     |    3    |  14
hooks/         |   5    |    7     |    3    |  15
agents/        |        |    1     |    1    |   6*
               |        |          |
TOTAL          |  13    |   18     |   11    |  42+
```
*Shared agents + specialized agents

Each category (common, frontend, backend) has:
- ✅ Scaffolding skills for auto-generating code
- ✅ Architecture rules defining structure
- ✅ Implementation rules defining code style
- ✅ Testing rules defining test patterns
- ✅ Validation hooks preventing common mistakes
- ✅ Specialized agents for guided development
