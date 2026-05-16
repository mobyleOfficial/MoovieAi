# MoovieAi

Meta-repository for the Moovie ecosystem. Central hub for shared resources, AI-assisted development, and automated repository management.

## Quick Start

Clone with submodules and run the bootstrap script:
```bash
git clone --recurse-submodules https://github.com/mobyleOfficial/MoovieAi
cd MoovieAi
./bootstrap.sh
```

The bootstrap initializes submodules, installs root + plugin npm dependencies, marks `.claude/hooks/*.sh` executable, and seeds `.claude/settings.local.json` from a template. Idempotent — safe to re-run.

After bootstrap, set `LINEAR_ACCESS_TOKEN` in `.claude/settings.local.json` (gitignored) before using the Linear MCP server. See [`.claude/skills/setting-up-linear-mcp/SKILL.md`](.claude/skills/setting-up-linear-mcp/SKILL.md).

## Structure

- **[moovie/](moovie)** — Flutter frontend (Android, iOS, Web)
- **[backend/](backend)** — Kotlin/Ktor API server
- **[research/](research)** — Design docs, API specs, architecture decisions
- **[plugins/](plugins)** — Claude Code MCP servers and tools
- **[rules/](rules)** — Linting, formatting, ecosystem policies
- **[.claude/skills/](.claude/skills)** — Project-level Claude Code skills (auto-discovered)
- **[agents/](agents)** — Custom Claude agents for specialized tasks

See [CLAUDE.md](CLAUDE.md) for architecture, conventions, and complete development guide.

## Claude Code Integration

This repo includes **Claude Code features** for streamlined development:

### Statusline Context Tracker

Real-time context usage monitoring in the status bar:
- Current model name
- Context window usage % (color-coded warnings)
- Session and weekly rate limit usage (Pro/Max plans)

Helps identify when to compact conversations. No setup needed.

### Repo Management Plugin

Automates repository operations:

```bash
# Available tools in Claude Code sessions:
- sync-submodule <name>     # Update submodule to latest remote
- create-feature-branch     # Create feature branch with auto-sync
- create-release-branch     # Create release branch with auto-sync
- open-pull-request         # Create PR (auto-targets develop or main)
- check-status              # Show which submodules are stale
```

**Setup:** Plugin is pre-registered in `.claude/settings.json`. No additional config needed.

## Linear MCP Integration

Connect Linear to Claude Code for issue management in development sessions.

**Setup:** Use skill `Skill("setting-up-linear-mcp")` for one-time configuration. Default project: MOO (Moovie).

## Frontend (Moovie)

**Tech:** Flutter, Dart, BLoC, Clean Architecture

```bash
cd moovie
bundle install              # Install Ruby dependencies (Fastlane)
flutter pub get             # Install Flutter dependencies
dart run build_runner build --delete-conflicting-outputs  # Code generation
bundle exec fastlane ios dev   # Run on iOS
bundle exec fastlane android dev  # Run on Android
```

See [moovie/README.md](moovie/README.md) for details.

## Backend (MoovieBackend)

**Tech:** Kotlin, Ktor, Koin, TMDB API

```bash
cd backend
export TMDB_API_KEY="your_bearer_token"
./gradlew run
```

Server runs on `http://localhost:8080`. See [backend/README.md](backend/README.md) for details.

## Ecosystem Conventions

- **Commits:** Conventional Commits format (`fix:`, `feat:`, `chore:`, `doc:`)
- **Branches:** `feature/*`, `release/*`, `fix/*`
- **PRs:** Auto-target `develop` (feature/fix) or `main` (release)
- **Authors:** Single author per commit — no Co-Authored-By trailers
- **Template:** Standardized PR template with Task, Summary, Changes, Technical Details, Testing

See [CLAUDE.md](CLAUDE.md) § Critical Rules for enforcement details.

## Research Documentation

All research docs follow a standardized format:

```
---
date: YYYY-MM-DD
author: Name
status: draft|approved|archived
---

# Title

## Executive Summary
## Problem Statement
## Options Evaluated
## Recommended Approach
## Next Steps
```

See [.claude/skills/moovie-research-format/](.claude/skills/moovie-research-format/SKILL.md) for full specification.

## Submodule Workflows

**Update to latest:**
```bash
git submodule update --remote
```

**Develop in a submodule:**
```bash
cd moovie  # or backend
git checkout main && git pull
cd ..
git add moovie
git commit -m "chore: update moovie reference"
git push
```

**Or use the plugin** (from Claude Code):
```
Create feature branch "auth-flow"
→ Auto-syncs submodules, creates feature/auth-flow, targets develop
```

## Contributing

1. Make changes in child repos (moovie/ or backend/)
2. Commit with Conventional Commits format
3. Open PR (manually or via Claude Code plugin)
4. Use standardized PR template
5. Update submodule references if needed

For Claude Code assisted work:
- Research docs: Use moovie-research-format skill
- Branch workflows: Use repo-management plugin
- Standardized tools already allowlisted (git, npm, flutter, bundle, fastlane, etc.)

## Permissions & Tooling

Pre-authorized (no prompts):
- **Git:** status, log, diff, branch, checkout, pull, fetch, add
- **npm:** install, run, test, ls, audit
- **Node:** node, npx
- **Mobile:** flutter, dart, bundle, fastlane, rbenv
- **Inspection:** ls, find, pwd, which

See `.claude/settings.json` for full allowlist.

## Resources

- **TMDB API:** https://developer.themoviedb.org/
- **Flutter:** https://flutter.dev/
- **Ktor:** https://ktor.io/
- **BLoC:** https://bloclibrary.dev/
- **Conventional Commits:** https://www.conventionalcommits.org/

## License

See LICENSE file in each repo.
