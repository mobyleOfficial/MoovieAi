# Generic Agents — Design

**Date:** 2026-06-19
**Branch:** `feature/generic-agents`
**Status:** Approved (pending spec review)

## Overview

The MoovieAi meta-repo's agents, commands, and supporting hooks are coupled to the
`moovie` app: hardcoded submodule paths (`moovie/features/**`), a hardcoded GitHub repo
(`mobyleOfficial/MoovieAi`), "MoovieAi ecosystem" language, and a fixed backend stack
(Kotlin/Ktor + TMDB). A second Flutter app will be added as another submodule and must
reuse the same pipeline. This work decouples the tooling so it serves **any Flutter
submodule** in the meta-repo, while keeping all Flutter/BLoC/Clean-Architecture knowledge
intact (both apps share that stack).

## Goals

- Agents and commands work across N Flutter submodules, not just `moovie/`.
- Tech-bound agents are named for their stack, not the app.
- Project-specific concepts (named app, backend stack, repo slug) are discovered at runtime
  or made optional — never hardcoded to `moovie`.
- No behavior change for the existing `moovie` pipeline.

## Non-Goals

- No change to the Flutter architecture rules themselves (`rules/feature-*.md`, etc.) — they
  already apply to any Flutter submodule.
- No new app scaffolding; this only touches the shared tooling.
- No change to the sub-reviewer prompts (already generic).

## Decisions

| # | Decision |
|---|----------|
| 1 | Rename **both** tech-bound agents to a stack prefix: `implementer-tester` → `flutter-implementer-tester`, `validator` → `flutter-validator`. |
| 2 | Resolve the target Flutter submodule **dynamically from `.gitmodules`**; the agent picks the target from the spec/feature context and asks if ambiguous. No hardcoded submodule names. |
| 3 | **Neutralize** movie-themed examples (`movies`/`Movie`/`GetMovies`) to generic ones (`items`/`Item`/`GetItems`) in commands and agent specs. |
| 4 | Backend references become **optional** ("if a backend exists"), stack-neutral — drop hardcoded Kotlin/Ktor/TMDB assumptions from generic agents. |
| 5 | Replace hardcoded repo slug `mobyleOfficial/MoovieAi` with a runtime lookup (`gh repo view --json nameWithOwner`). |

## Component Plan

### A. No change (already generic)
- `agents/reviewers/security.md`, `bug-finder.md`, `architecture.md` — pure role prompts, no app coupling.

### B. Rename + parameterize (tech-bound)
- `agents/implementer-tester.md` → **`agents/flutter-implementer-tester.md`**
  - Keep all Flutter/Dart/BLoC/Clean-Arch/DI/localization/accessibility content.
  - Replace every hardcoded `moovie/` path with the resolved target submodule (`<app>/features/**`, etc.).
  - Add a "Resolve target submodule" step: read `.gitmodules`, determine which Flutter app
    the spec targets, ask if ambiguous.
  - Neutralize examples.
- `agents/validator.md` → **`agents/flutter-validator.md`**
  - Same submodule parameterization.
  - Backend checklist section (§3) becomes conditional/optional.
  - Repo slug → `gh repo view` lookup.
  - Update the `reviewer` dispatch prompt to use the resolved repo, not `mobyleOfficial/MoovieAi`.

### C. Project-agnostic rewrite (drop moovie, backend optional)
- `agents/pm-spec.md` — "the ecosystem" instead of "MoovieAi ecosystem"; "Cross-Repo Impact"
  framed as "if a backend exists"; generic API example (no TMDB); neutralize examples.
- `agents/architect-review.md` — keep "Flutter frontend + optional backend" awareness; drop
  hardcoded moovie/Kotlin/Ktor naming; backend criteria conditional.
- `agents/reviewer.md` — replace all `mobyleOfficial/MoovieAi` occurrences with a repo-slug
  variable resolved once via `gh repo view --json nameWithOwner --jq .nameWithOwner`; drop
  the moovie-specific audit-reference line or generalize it.

### D. Commands (Flutter-specific, already path-relative)
- `commands/new-datasource.md`, `new-repository.md`, `new-usecase.md`, `new-ui-module.md` —
  neutralize movie-themed examples only. Paths already relative; no structural change.
- `commands/review-pr.md` — update any reference to renamed agents / hardcoded repo.

### E. Hooks
- `.claude/hooks/check-submodule-ai.sh` — replace `for submodule in moovie backend` with a
  list read dynamically from `.gitmodules`.
- Other hooks already use relative `features/` paths — verify, no change expected.

### F. Ripple — references to renamed agents + de-moovie docs
- `CLAUDE.md` — update agent names in pipeline/skills sections; generalize "moovie submodule"
  language to "the target Flutter submodule."
- `.claude/CLAUDE.md` — update pipeline-agent name list.
- `agents/README.md` — rename references, generalize pipeline prose.
- `.claude/settings.json` / `settings.local.json` — update if they register the renamed agents
  or hooks by name.

## Submodule Resolution (shared contract)

Agents that act on a Flutter submodule follow this resolution order:

1. If the spec/feature context names a target app, use it.
2. Else enumerate Flutter submodules from `.gitmodules` (a submodule is "Flutter" if it
   contains a `pubspec.yaml`).
3. If exactly one Flutter submodule exists, use it.
4. If multiple and the target is ambiguous, **stop and ask the user**.

This keeps `moovie` working unchanged today (single resolution) and supports the new app
without edits when it lands.

## Risks / Edge Cases

- **Renaming breaks references.** Mitigation: grep for `implementer-tester` / `validator` /
  `mobyleOfficial/MoovieAi` across the repo and update every hit; verify with a final grep
  showing zero stale references (outside this spec/changelog).
- **`gh repo view` unavailable / not in a gh-authed checkout.** Mitigation: agents already
  require `gh` for PR ops; if it fails, surface the error rather than falling back to a
  hardcoded slug.
- **`.gitmodules` parsing** must tolerate submodules without `pubspec.yaml` (e.g. backend).

## Verification

- `grep -rn "implementer-tester\|^.*validator\b" agents/ commands/ CLAUDE.md .claude/` shows
  only the new `flutter-*` names (plus this spec).
- `grep -rn "mobyleOfficial/MoovieAi" agents/ commands/` returns nothing.
- `grep -rn "moovie/" agents/ commands/` returns nothing (paths now resolved dynamically).
- Existing `moovie` pipeline still resolves to a single target (manual reasoning check against
  the resolution contract).
