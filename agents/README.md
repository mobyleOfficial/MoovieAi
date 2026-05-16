# Agents

Custom Claude agents for specialized tasks in the MoovieAi ecosystem. These form a feature development pipeline.

## Available Agents

### Feature Pipeline

- **pm-spec** — Product manager that writes feature specifications for the ecosystem
- **architect-review** — Technical architect that reviews specs for feasibility and ecosystem alignment
- **implementer-tester** — Flutter/Dart implementer that builds features in the moovie submodule with full test coverage
- **validator** — Strict read-only post-implementation reviewer. Catches issues before merge using a 10-section checklist (correctness, architecture, UI patterns, code quality, testing, localization, accessibility, security, performance).

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
