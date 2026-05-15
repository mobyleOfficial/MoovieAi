# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Purpose

MoovieAi is a **meta-repository** that serves as the central hub for the Moovie ecosystem. It contains:

- **Shared resources** for AI-assisted development (plugins, rules, skills)
- **Research and documentation** about the ecosystem
- **Git submodules** linking to child repositories (frontend and backend)

Child repositories do not need their own AI-specific documentation — they inherit guidance from this meta-repo.

---

## Repository Structure

```
MoovieAi/
├── moovie/           # Git submodule: Flutter frontend app
├── backend/          # Git submodule: Kotlin/Ktor backend
├── research/         # Research docs, analysis, design docs
├── plugins/          # Claude Code MCP plugins and servers
├── rules/            # Linting, formatting, ecosystem policies
├── skills/           # Custom Claude workflows (standardized documentation)
├── agents/           # Custom Claude agents for specialized tasks
└── CLAUDE.md         # This file
```

---

## Child Repositories

### Moovie (Flutter Frontend)

**Path:** `./moovie`  
**Tech Stack:** Flutter, Dart, BLoC, Clean Architecture  
**Platforms:** Android, iOS, Web  
**Key Features:**
- Multi-package monorepo with independently versioned feature packages
- Internationalization (English, Spanish, Portuguese)
- Light/dark theme support
- TMDB API integration via custom backend

**Setup:**
```bash
cd moovie
rbenv local 3.2.0
bundle install
flutter pub get
dart run build_runner build --delete-conflicting-outputs
bundle exec fastlane setup_ide
```

**Development:**
- Run: `bundle exec fastlane ios dev` or `bundle exec fastlane android dev`
- Tests: `flutter test`
- Code generation: `dart run build_runner build --delete-conflicting-outputs`
- Linting: `flutter analyze`

**Structure:**
- `lib/` — Main app code
- `features/` — Feature modules (BLoC pattern)
- `core/` — Shared utilities and base classes
- `ui/` — UI components and shared widgets
- `ios/` / `android/` — Platform-specific code
- `web/` — Web flavor
- `test/` — Integration and unit tests

---

### MoovieBackend (Kotlin/Ktor)

**Path:** `./backend`  
**Tech Stack:** Kotlin 2.0.20, Ktor 2.3.0, Koin 3.5.6  
**Database:** TMDB API integration  
**Deployment:** Docker, Gradle

**Setup:**
```bash
cd backend
export TMDB_API_KEY="your_bearer_token"
./gradlew run
```

**Development:**
- Run: `./gradlew run` (starts on `http://localhost:8080`)
- Build fat JAR: `./gradlew buildFatJar`
- Docker: `docker build -t moovie-backend . && docker run -p 8080:8080 -e TMDB_API_KEY="..." moovie-backend`

**Structure:**
- `src/` — Kotlin source code
- `build.gradle.kts` — Build configuration
- `Dockerfile` — Container configuration

---

## Working with Git Submodules

Submodules are frozen at specific commits. When cloning or pulling this repo:

```bash
# Clone with submodules
git clone --recurse-submodules https://github.com/mobyleOfficial/MoovieAi

# Or if already cloned, initialize submodules
git submodule update --init --recursive

# Update to latest remote commits
git submodule update --remote
```

**For development in a submodule:**
```bash
cd moovie  # or backend
git checkout main  # or your branch
git pull
cd ..
# Commit the submodule reference change
git add moovie
git commit -m "chore: update moovie submodule reference"
```

---

## Folder Usage

### `research/`
Design docs, architecture decisions, API specs, performance analysis, user research. Reference these when understanding system-wide decisions or context for features.

### `plugins/`
Claude Code MCP plugins and servers (e.g., repo-management). Register in `.claude/settings.json` to extend Claude's capabilities. Pre-registered and ready to use.

### `rules/`
Linting configurations, formatter rules, and architecture policies organized into three categories:

**Common Rules (Both Frontend & Backend):**
- `common/AI_AGNOSTIC_SUBMODULES.md` — Child repos must remain AI-agnostic
- `common/LOCAL_CLAUDE_CONFIG.md` — Config must use portable relative paths
- `common/NO_COAUTHORS.md` — Never use Co-Authored-By trailers
- `common/PYTHON_ENVS.md` — All Python in local venv
- `common/variable-naming.md` — Naming conventions

**Frontend Rules (Flutter/Dart):**
- `frontend/feature-architecture.md` — Feature module structure
- `frontend/feature-implementation.md` — Dart code style
- `frontend/feature-testing.md` — Testing patterns
- `frontend/ui-architecture.md` — UI module structure
- `frontend/accessibility.md` — WCAG AA compliance
- `frontend/localization.md` — Multi-language support

**Backend Rules (Kotlin/Ktor):**
- `backend/backend-architecture.md` — Clean architecture
- `backend/backend-implementation.md` — Kotlin code style
- `backend/backend-testing.md` — Testing patterns

### `skills/`
Custom Claude workflows for scaffolding features and standardized documentation. Organized into three categories:

**Common Skills (Frontend & Backend):**
- `moovie-research-format` — Standardized format for design docs, architecture decisions, and research
- `setting-up-linear-mcp` — Configure Linear MCP at project level with workspace scoping
- `verify-docs-before-pr` — Documentation verification before PR creation

**Frontend Skills (Flutter/Dart):**
- `/new-usecase` — Scaffold a domain usecase with Result<T> error handling
- `/new-datasource` — Scaffold a remote/local datasource (Dio HTTP or local)
- `/new-repository` — Scaffold domain/data repository pair
- `/new-ui-module` — Scaffold a complete UI module (bloc/screen/state)

**Backend Skills (Kotlin/Ktor):**
- `/new-kotlin-usecase` — Scaffold a business logic usecase with operator invoke()
- `/new-kotlin-datasource` — Scaffold a Ktor HTTP client datasource
- `/new-kotlin-repository` — Scaffold domain/data repository pair with DTO mapping
- `/new-ktor-endpoint` — Scaffold an API endpoint with routing and DI

### `agents/`
Custom Claude agents for specialized tasks across the feature development pipeline:
- **pm-spec** — Writes feature specifications from requests
- **architect-review** — Reviews specs for feasibility and alignment
- **implementer-tester** — Implements Flutter/Dart features (moovie/)
- **backend-implementer** — Implements Kotlin/Ktor features (backend/)
- **code-reviewer** — Reviews code quality across both submodules
- **validator** — Final pre-merge validation

Register in `.claude/settings.json` or invoke via `/agent-name`. All agents inherit ecosystem conventions and pre-authorized tools.

### `hooks/`

Validation hooks for code quality and architecture compliance. Organized into three categories:

**Common Hooks (Both Frontend & Backend):**
- `common/block-destructive-commands.sh` — Prevents dangerous shell operations
- `common/enforce-path-restrictions.sh` — Ensures portable config paths
- `common/human-gate-review.sh` — Requires human review at critical gates
- `common/pipeline-coordinator.sh` — Manages feature development pipeline flow
- `common/validate-spec.sh` — Validates feature specifications

**Frontend Hooks (Flutter/Dart):**
- `frontend/block-cross-feature-data-imports.sh` — Enforces architecture boundaries
- `frontend/format-code.sh` — Auto-formats Dart code
- `frontend/regenerate-generated-files.sh` — Runs build_runner
- `frontend/validate-implementation.sh` — Validates Dart code patterns
- `frontend/validate-localization.sh` — Validates multi-language support
- `frontend/validate-module-structure.sh` — Validates feature structure
- `frontend/verify-di-registration.sh` — Verifies DI completeness

**Backend Hooks (Kotlin/Ktor):**
- `backend/verify-koin-di-registration.sh` — Verifies Koin module registration
- `backend/validate-backend-structure.sh` — Validates clean architecture
- `backend/validate-kotlin-code.sh` — Validates Kotlin patterns

Run automatically by agents via pre/post-tool-use and stop hooks. See [hooks/README.md](hooks/README.md) for details.

---

## Key Architecture Patterns

### Frontend (Moovie)
- **State Management:** BLoC pattern for clean separation of business logic
- **Structure:** Feature-based packages with core utilities
- **Routing:** Code-generated (build_runner)
- **Dependency Injection:** GetIt or manual injection per feature
- **Testing:** Unit tests in feature packages, integration tests in root

### Backend (MoovieBackend)
- **Framework:** Ktor for lightweight, composable HTTP routing
- **DI:** Koin modules for clean dependency management
- **Serialization:** Kotlinx for JSON (no reflection overhead)
- **API Integration:** TMDB API with custom wrapper endpoints

### Communication
- Frontend calls backend at configurable endpoint
- Backend proxies TMDB API and applies business logic
- Shared error handling and HTTP status conventions

---

## Development Workflows

### Adding a Feature
1. **Frontend:** Create feature package in `moovie/features/`
2. **Backend:** Add endpoint in `backend/src/`
3. **Documentation:** Update research/ with API contract if complex
4. **Testing:** Write tests in respective repos

### Making Cross-Repo Changes
1. Update backend first
2. Update frontend to consume new API
3. Commit both submodule references in MoovieAi

### Debugging Integration Issues
- Check `moovie/secrets/.env` for correct backend URL
- Verify `TMDB_API_KEY` in backend environment
- Review backend logs: `./gradlew run` (verbose output)
- Check frontend logs: Flutter DevTools or `flutter logs`

---

## Common Commands Across the Ecosystem

**Moovie (Flutter):**
```bash
cd moovie
flutter pub get                                    # Install dependencies
dart run build_runner build --delete-conflicting-outputs  # Code generation
flutter test                                       # Run tests
flutter analyze                                    # Lint
bundle exec fastlane ios dev                      # Run on iOS
bundle exec fastlane android dev                  # Run on Android
```

**MoovieBackend (Kotlin):**
```bash
cd backend
./gradlew run                                      # Run locally
./gradlew buildFatJar                              # Build production jar
./gradlew test                                     # Run tests
```

---

## Resources

- **TMDB API Docs:** https://developer.themoviedb.org/docs
- **Flutter Docs:** https://flutter.dev/docs
- **Ktor Docs:** https://ktor.io/docs
- **BLoC Pattern:** https://bloclibrary.dev/

---

## Critical Rules

**AI-Agnostic Submodules:** Child repos (moovie, backend) MUST remain AI-agnostic. No CLAUDE.md, .claude/, or AI-specific references in submodules. All AI integration lives in this meta-repo. Single human author per commit (no Claude co-authors). See [rules/AI_AGNOSTIC_SUBMODULES.md](rules/AI_AGNOSTIC_SUBMODULES.md).

**No Coauthors:** Never use `Co-Authored-By` trailers in commits, PR descriptions, or issues in any child repository. Single author per commit always. See [rules/NO_COAUTHORS.md](rules/NO_COAUTHORS.md).

**Python Environments:** All Python dependencies MUST be installed in a local, project-specific Python environment. Never install globally. See [rules/PYTHON_ENVS.md](rules/PYTHON_ENVS.md).

**Local Claude Config:** All `.claude/` configuration MUST use portable, relative paths. No global (`~/`) or absolute user paths. Enables config reuse across team. Validated on every prompt. See [rules/LOCAL_CLAUDE_CONFIG.md](rules/LOCAL_CLAUDE_CONFIG.md).

## Conventions

### Commit Messages
All commits across child repos follow Conventional Commits format:
- `fix:` — bug fixes
- `feat:` — new features
- `chore:` — maintenance, dependency updates, tooling
- `doc:` — documentation

Example: `fix: correct auth token expiry logic`

### Branch Naming
- **Feature branches:** `feature/<description>` (target: `develop`)
- **Release branches:** `release/<version>` (target: `main`)
- **Bugfix branches:** `fix/<description>` (target: `develop`)

### Pull Requests
- Feature/bugfix PRs target `develop`
- Release PRs target `main`
- Use Conventional Commits format in PR title
- No coauthors in PR descriptions
- **Before opening PR:** Run `verify-docs-before-pr` skill to ensure README.md/CLAUDE.md are updated if code changes affect docs

### Submodule Operations
Handled by `repo-management` MCP server:
- `sync-submodule <name>` — update to latest remote
- `create-feature-branch <name>` — sync first, then create `feature/<name>`
- `create-release-branch <version>` — sync first, then create `release/<version>`
- `open-pull-request` — auto-detects branch type, targets correct base branch
- `check-status` — show stale/dirty submodules

---

## Setup for New Sessions

### Context Tracking (Statusline)

The project includes a **context usage statusline** showing:
- Model name
- Context usage % (color-coded: green <70%, yellow 70-89%, red 90%+)
- Session & weekly rate limit usage (Pro/Max plans)

Displays automatically in the bottom right. Helps identify when to compact conversations. No setup needed — included in `.claude/settings.json`.

### Load Rules, Plugins, and Skills (Every Session)

At the start of each session, load these resources:

**1. Rules** — Organizational policies and architecture patterns:
- **Critical policies (all development):**
  - [`rules/common/LOCAL_CLAUDE_CONFIG.md`](rules/common/LOCAL_CLAUDE_CONFIG.md) — portable relative paths in `.claude/` config
  - [`rules/common/AI_AGNOSTIC_SUBMODULES.md`](rules/common/AI_AGNOSTIC_SUBMODULES.md) — child repos must remain AI-agnostic
  - [`rules/common/NO_COAUTHORS.md`](rules/common/NO_COAUTHORS.md) — single author per commit always
  - [`rules/common/PYTHON_ENVS.md`](rules/common/PYTHON_ENVS.md) — local Python venv required
- **Frontend-specific:** `rules/frontend/` (architecture, testing, UI, accessibility, localization)
- **Backend-specific:** `rules/backend/` (architecture, implementation, testing)

**2. Plugins** — MCP servers available in this project:
- `repo-management` — Manage submodules, branches, PRs (configured in `.mcp.json`)
- `linear` — Linear workspace integration (configured in `.mcp.json`)

**3. Skills** — Custom Claude workflows:
- **Common:** `setting-up-linear-mcp`, `moovie-research-format`, `verify-docs-before-pr`
- **Frontend:** `/new-usecase`, `/new-datasource`, `/new-repository`, `/new-ui-module`
- **Backend:** `/new-kotlin-usecase`, `/new-kotlin-datasource`, `/new-kotlin-repository`, `/new-ktor-endpoint`
- All skills auto-discoverable via `local-skills` marketplace in `.claude/settings.json`

**4. Agents** — Specialized Claude workflows for feature development pipeline:
- Use `/implementer-tester` for Flutter/Dart feature implementation
- Use `/backend-implementer` for Kotlin/Ktor backend feature implementation
- Use `/architect-review` for spec feasibility review
- Use `/code-reviewer` for code quality validation

These resources are binding for all work in this repo. Obey rules before suggesting code.

### Linear MCP (First Time)

If you don't have Linear MCP configured:
1. Use skill: `setting-up-linear-mcp`
2. Generate API token: https://linear.app/mobyle/settings/api
3. Update `.claude/settings.json` + `.claude/settings.local.json`
4. Restart Claude Code

Default project: MOO (Moovie). Token stored securely in `.local.json` (gitignored).

---

## Notes for Claude Instances

When working in child repos (moovie or backend):
- Refer back to this CLAUDE.md for ecosystem context
- Check `research/` for design decisions that affect your changes
- Use plugins/ and skills/ resources for repeated tasks
- Update submodule references in the meta-repo after merging changes
- **Follow NO_COAUTHORS rule strictly** — single author on all commits
- If adding new shared resources, document them here

When using Linear in Claude Code:
- Linear MCP defaults to MOO project (Moovie)
- Create issue references: `MOO-123`, `MOO-456`
- Link issues in PRs via description: "Closes MOO-123"
