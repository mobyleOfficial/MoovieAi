# .claude/CLAUDE.md

Claude/tooling-specific behavior for the MoovieAi meta-repo.

> **Scope:** this file governs *how* Claude operates in this repo — tool choices, hook expectations, subagent dispatch, output formatting. For *what* the project is (architecture, conventions, build/run commands), see the root [`CLAUDE.md`](../CLAUDE.md). Both files load each session.

## Tool Preferences

- Prefer `Read` / `Edit` / `Write` / `MultiEdit` over shell equivalents (`cat`, `sed`, `awk`, `echo > file`). Reserve `Bash` for actual shell operations.
- Use the `repo-management` MCP server for branch/PR/submodule operations when available. Falls back to raw `git` / `gh` if the server is not connected.
- Use the `linear` MCP server for issue operations. Requires `LINEAR_ACCESS_TOKEN` in `.claude/settings.local.json` (gitignored).
- For broad codebase exploration (3+ queries), spawn the `Explore` subagent. For single lookups, use `Grep` / `Glob` directly.

## Hook Expectations

Project-level hooks defined in `.claude/settings.json`:

| Event | Hook | Behavior |
|-------|------|----------|
| `SessionStart` | `.claude/hooks/session-start.sh` | One-line summary of rules / skills / MCP servers |
| `UserPromptSubmit` | `.claude/validate-config.sh` | Blocks if `.claude/settings*.json` or `.mcp.json` contain non-portable paths |
| `PreToolUse` Bash | `.claude/hooks/block-destructive-commands.sh` | Blocks `rm -rf`, `git push --force`, `git reset --hard`, etc. |
| `PreToolUse` Bash | `.claude/hooks/check-coauthor.sh` | Blocks `git commit` containing `Co-Authored-By` trailers |
| `PreToolUse` Bash | `.claude/hooks/check-python-env.sh` | Blocks `pip` / `uv pip` / `poetry` / `conda install` outside an active virtualenv |
| `PreToolUse` Bash | `.claude/hooks/check-submodule-ai.sh` | Blocks `git commit` / `git push` when submodule contains AI-tooling files |
| `PreToolUse` Bash | `.claude/hooks/check-docs-sync.sh` | Blocks `gh pr create` / `git push` when critical files change without a doc update |
| `PostToolUse` Edit/Write | `.claude/hooks/format-code.sh` | Runs `dart format` on `.dart` files (no-op on others) |

Per-agent hooks (defined in pipeline-agent frontmatter): `validate-spec.sh`, `validate-implementation.sh`, `validate-localization.sh`, `validate-module-structure.sh`, `verify-di-registration.sh`, `regenerate-generated-files.sh`, `pipeline-coordinator.sh`, `human-gate-review.sh`, `enforce-path-restrictions.sh`, `block-cross-feature-data-imports.sh`. All live in `.claude/hooks/`.

## Subagent Dispatch

- **`Explore`** — read-only codebase search. Use when locating files/symbols across the repo (3+ queries).
- **`Plan`** — implementation strategy for multi-step tasks.
- **`general-purpose`** — open-ended research or multi-step work.
- **`claude-code-guide`** — questions about Claude Code (CLI, Agent SDK, Anthropic API).
- Pipeline agents (`pm-spec`, `architect-review`, `flutter-implementer-tester`, `flutter-validator`) — for the feature-development pipeline. Invoked via `/agents/<name>.md` flow.

Spawning a subagent costs more than reading files inline. Spawn only when the task spans multiple files / multiple search angles, when context window protection matters, or when an explicit agent type fits the task.

## Output Formatting

- Default to terse responses. Match length to the question — a one-line question gets a one-line answer.
- No trailing summaries unless the user requests them.
- Emojis only if the user explicitly asks.
- When citing code locations, use `path:line` so the user can navigate.
- For destructive or irreversible actions, surface what will happen and confirm. Do not assume previous approval extends to new actions.

## Safe-Action Defaults

- Always confirm before: deleting branches, force-pushing, dropping data, rewriting shared history, removing files outside the working tree, modifying CI/CD.
- Never use `--no-verify` to skip hooks unless the user explicitly requests it.
- Never use `git commit --amend` to retroactively change a published commit. Create a new commit instead.
- Single-author commits only — no `Co-Authored-By` trailers (enforced by hook + rule `NO_COAUTHORS`).

## Skill Autoload

The following skills should be invoked proactively when their trigger fits:

- `Skill("verify-docs-before-pr")` — before opening any PR, run this to confirm docs are in sync with code changes.
- `Skill("moovie-research-format")` — when writing or editing research docs in `research/`.
- `Skill("setting-up-linear-mcp")` — when configuring Linear MCP for the first time or rotating tokens.

Auto-discovered from `.claude/skills/<name>/SKILL.md`. No manual registration.

## When in Doubt

Defer to the root [`CLAUDE.md`](../CLAUDE.md) for ecosystem context, and to [`rules/`](../rules/) for binding policies. Rules override this file when they conflict.
