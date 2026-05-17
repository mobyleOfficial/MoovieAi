# Agents

Custom Claude agents for specialized tasks in the MoovieAi ecosystem. These form a feature development pipeline.

## Available Agents

### Feature Pipeline

- **pm-spec** — Product manager that writes feature specifications for the ecosystem
- **architect-review** — Technical architect that reviews specs for feasibility and ecosystem alignment
- **implementer-tester** — Flutter/Dart implementer that builds features in the moovie submodule with full test coverage
- **validator** — Strict read-only post-implementation reviewer. Catches issues before merge using a 10-section checklist (correctness, architecture, UI patterns, code quality, testing, localization, accessibility, security, performance). Writes a comprehensive local report to `research/reviews/<feature>-code-review.md`; if an open PR exists for the current branch, also delegates to the `reviewer` agent to post inline PR comments.
- **ultimate-developer** — Autonomous end-to-end orchestrator. Brainstorms with the user once at kickoff; then drives spec → plan → impl phases via review-and-iterate loops on GitHub PRs and merges autonomously. Reuses every other pipeline agent in audit-only mode. Invoke via `/ultimate-feature`.
- **researcher** — Per-topic research sub-agent. Receives a `path` + `topic` + `type` from `ultimate-developer` during plan phase and produces one research markdown file using `WebSearch` + `WebFetch`.
- **backend-implementer** — Kotlin/Ktor mirror of `implementer-tester`. Implements features in the `backend/` submodule per `rules/backend-architecture.md` + `rules/backend-testing.md`.

### PR Review

- **reviewer** — Orchestrates a multi-pass GitHub PR review. Dispatches three specialized sub-reviewers in parallel (security / bug-finder / architecture), validates findings, deduplicates, and posts inline comments. Re-review aware: marks resolved threads and only posts net-new findings. Invoke via `/review-pr <N>`.

Sub-reviewer prompts live in [`reviewers/`](reviewers/).

## Pipeline Usage

Feature development follows this pipeline:

1. **pm-spec** — Convert feature request → formal spec in `research/specs/`
2. **architect-review** — Review spec for feasibility → approval/rejection in `research/reviews/`
3. **implementer-tester** — Implement approved spec in `moovie/` submodule with tests
4. **validator** — Read-only validation against spec + ecosystem rules → report in `research/reviews/<feature>-code-review.md`. Blocks merge on critical issues.

Each agent has specific tool allowlists and responsibilities defined in its metadata. All agents understand the MoovieAi ecosystem structure and can work across the moovie and backend submodules.

See [CLAUDE.md](../CLAUDE.md) for ecosystem-wide guidance.

## Audit-Only Mode

`ultimate-developer` dispatches `reviewer`, `validator`, and `architect-review` in **audit-only mode** (literal string `mode: "audit-only"` in the prompt body). In audit-only mode these agents return STRICT JSON findings and do not write to GitHub. `ultimate-developer` owns all PR replies and thread resolutions. Humans invoking `/review-pr` directly get the default (non-audit-only) behavior.
