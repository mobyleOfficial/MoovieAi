# Rules

Binding policies for work in this repo. Each rule is a single Markdown file. Rules override default Claude behavior and the `.claude/CLAUDE.md` defaults; they yield only to explicit user instructions.

## Project-wide Rules (hook-enforced)

These rules fire automatically on every applicable action.

| Rule | Hook | Trigger |
|------|------|---------|
| [LOCAL_CLAUDE_CONFIG](LOCAL_CLAUDE_CONFIG.md) | `.claude/validate-config.sh` | `UserPromptSubmit` — scans `.claude/settings*.json` + `.mcp.json` for non-portable paths |
| [NO_COAUTHORS](NO_COAUTHORS.md) | `.claude/hooks/check-coauthor.sh` | `PreToolUse` Bash — blocks `git commit` with `Co-Authored-By` trailers |
| [PYTHON_ENVS](PYTHON_ENVS.md) | `.claude/hooks/check-python-env.sh` | `PreToolUse` Bash — blocks `pip` / `uv` / `poetry` / `conda install` outside an active venv |
| [AI_AGNOSTIC_SUBMODULES](AI_AGNOSTIC_SUBMODULES.md) | `.claude/hooks/check-submodule-ai.sh` | `PreToolUse` Bash — blocks `git commit` / `git push` when submodule contains `.claude/`, `CLAUDE.md`, `.cursorrules`, copilot instructions, or `AGENTS.md` |
| [DOCS_UP_TO_DATE](DOCS_UP_TO_DATE.md) | `.claude/hooks/check-docs-sync.sh` | `PreToolUse` Bash — blocks `gh pr create` / `git push` when critical files change without a doc update |

## Flutter / Submodule-scoped Rules (per-agent enforcement)

These rules apply when working inside the `moovie/` submodule. They are enforced by the `implementer-tester` agent, whose `Stop` hook chain runs `flutter analyze` + `flutter test` + structural validators. Hook scripts live in `.claude/hooks/` but are not project-wide.

| Rule | Enforcement |
|------|-------------|
| [feature-architecture](feature-architecture.md) | `block-cross-feature-data-imports.sh` + `validate-module-structure.sh` |
| [feature-implementation](feature-implementation.md) | `validate-implementation.sh` (`flutter analyze` + tests) |
| [feature-testing](feature-testing.md) | `validate-implementation.sh` (`flutter test`) |
| [ui-architecture](ui-architecture.md) | `validate-module-structure.sh` |
| [localization](localization.md) | `validate-localization.sh` (ARB key parity) |
| [accessibility](accessibility.md) | `flutter analyze` lints + manual review (no shell hook — WCAG / contrast / 48dp checks are not shell-enforceable) |
| [variable-naming](variable-naming.md) | `flutter analyze` lints + manual review |

## Backend / Submodule-scoped Rules (per-agent enforcement)

These rules apply when working inside the `backend/` submodule. They are enforced by the `backend-implementer` agent and the `reviewers/architecture` sub-reviewer.

(Scope column added for backend rules to disambiguate submodule vs. subdirectory enforcement.)

| Rule | Scope | Enforcement |
|------|-------|-------------|
| [backend-architecture](backend-architecture.md) | `backend/` submodule | `backend-implementer` agent + reviewer architecture sub-reviewer |
| [backend-testing](backend-testing.md) | `backend/src/test/` | `backend-implementer` agent (test scaffolding) |

See [`.claude/hooks/README.md`](../.claude/hooks/README.md) for the full registration model.

## How to Add a Rule

1. Create `rules/<RULE_NAME>.md` with sections: `RULE`, `Why`, `What's Forbidden / Required`, `Enforcement`, `Exceptions`, `Common Mistakes`.
2. If hook-enforceable: write `.claude/hooks/<check-name>.sh` (must read JSON tool input from stdin, exit `2` to block).
3. Register the hook in `.claude/settings.json` under the appropriate event matcher.
4. Update this README's table.
5. Mention the rule under "Critical Rules" in root [`CLAUDE.md`](../CLAUDE.md).
6. Per [`DOCS_UP_TO_DATE`](DOCS_UP_TO_DATE.md): keep all of the above in the same PR.

## Per-Tool Lint Configurations

Per-language linting (`flutter analyze`, `dart format`, `eslint`, `ktlint`, etc.) lives inside the submodule that owns the language stack — not here. This directory is for meta-repo ecosystem policy only.
