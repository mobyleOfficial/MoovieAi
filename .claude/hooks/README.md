# .claude/hooks/

Shell hooks invoked by Claude Code. Two registration models:

## 1. Project-level hooks (auto-registered)

Wired into `.claude/settings.json` under the `hooks` block. Fire on every session, regardless of agent.

| Hook | Event | Behavior |
|------|-------|----------|
| `session-start.sh` | `SessionStart` | One-line summary of rules / skills / MCP servers |
| `block-destructive-commands.sh` | `PreToolUse` Bash | Blocks `rm -rf`, `git push --force`, `git reset --hard`, etc. |
| `check-coauthor.sh` | `PreToolUse` Bash | Blocks `git commit` containing `Co-Authored-By` trailers (enforces `rules/NO_COAUTHORS.md`) |
| `check-python-env.sh` | `PreToolUse` Bash | Blocks `pip` / `uv pip` / `poetry` / `conda install` outside an active virtualenv (enforces `rules/PYTHON_ENVS.md`) |
| `check-submodule-ai.sh` | `PreToolUse` Bash | Blocks `git commit` / `git push` when `moovie/` or `backend/` contains AI-tooling files (enforces `rules/AI_AGNOSTIC_SUBMODULES.md`) |
| `check-docs-sync.sh` | `PreToolUse` Bash | Blocks `gh pr create` / `git push` when critical files change without a doc update (enforces `rules/DOCS_UP_TO_DATE.md`) |
| `format-code.sh` | `PostToolUse` Edit\|Write | Runs `dart format` on `.dart` files (filters by extension internally) |

Plus `.claude/validate-config.sh` (one level up, `UserPromptSubmit` matcher) which enforces `rules/LOCAL_CLAUDE_CONFIG.md`.

## 2. Per-agent hooks (NOT auto-registered)

These hooks are designed to run as `Stop` or `PreToolUse` hooks scoped to specific pipeline agents (e.g. `pm-spec` → `validate-spec.sh`). Claude Code's current subagent frontmatter does **not** accept a `hooks:` field, so these are not wired automatically.

| Hook | Agent | Event | Purpose |
|------|-------|-------|---------|
| `validate-spec.sh` | `pm-spec` | Stop | Verify spec is complete before stage progression |
| `pipeline-coordinator.sh` | every pipeline agent | Stop | Advance pipeline queue, hand off to next agent |
| `human-gate-review.sh` | `architect-review` | Stop | Human approval gate after architect review |
| `validate-implementation.sh` | `implementer-tester` | Stop | `flutter analyze` + `flutter test`, block on errors |
| `validate-localization.sh` | `implementer-tester` | Stop | Enforce ARB key parity across `app_en.arb` / `app_es.arb` / `app_pt.arb` |
| `validate-module-structure.sh` | `implementer-tester` | Stop | Verify required feature/UI module file layout |
| `verify-di-registration.sh` | `implementer-tester` | Stop | Confirm `@module` files are wired into `injection.config.dart` |
| `regenerate-generated-files.sh` | `implementer-tester` | Stop | Run `build_runner` / `flutter gen-l10n` when source changes warrant |
| `enforce-path-restrictions.sh` | `implementer-tester` | PreToolUse Edit\|Write | Reject writes outside the agent's allowed paths |
| `block-cross-feature-data-imports.sh` | `implementer-tester` | PreToolUse Edit\|Write | Reject imports of another feature's `data/` layer (per `rules/feature-architecture.md`) |

**Until Claude Code supports per-agent hook registration**, each agent's documentation (`agents/<name>.md`) describes which hooks should run and the agent is expected to invoke them manually via `Bash` before returning. The pipeline-queue tracks stage state via `pipeline-coordinator.sh` which agents are instructed to invoke on completion.

## Pipeline State

Runtime state lives in `.claude/task/pipeline-queue.json` (gitignored). The empty starting state lives in `.claude/task/pipeline-queue.template.json` (committed). `bootstrap.sh` seeds the queue from the template on fresh clones.
