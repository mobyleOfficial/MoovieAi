<<<<<<< HEAD:hooks/README.md
# Hooks

Pre-commit and tool-use validation hooks for the MoovieAi ecosystem. These are shell scripts that run at critical points in the development workflow to catch issues early.

## Organization

Hooks are organized into three categories:

### Common Hooks (Both Frontend & Backend)

Applied across all development:

- **`common/block-destructive-commands.sh`** — Prevents dangerous shell operations
  - Blocks: `rm -rf`, `git reset --hard`, `git push --force`, etc.
  - Applied to: All Bash tool calls in agents
  - Raises: Error on destructive attempt

- **`common/enforce-path-restrictions.sh`** — Ensures edits stay within allowed directories
  - Checks: `.claude/` config uses portable relative paths, no `~/` or absolute user paths
  - Applied to: Edit, Write tool calls
  - Raises: Error on path violation

- **`common/human-gate-review.sh`** — Requires human review at critical gates
  - Gates: Pre-merge validation, infrastructure changes
  - Applied to: Repository merge operations
  - Raises: Error if gate skipped

- **`common/pipeline-coordinator.sh`** — Manages feature development pipeline flow
  - Coordinates: Spec → Review → Implementation → Tests → Validation
  - Applied to: Agent handoffs between pipeline stages
  - Raises: Warning if pipeline order violated

- **`common/validate-spec.sh`** — Validates feature specifications before implementation
  - Checks: Spec has required sections, SMART goals, architecture notes
  - Applied to: New specs in `research/specs/`
  - Raises: Error on incomplete spec

### Frontend Hooks (Flutter/Dart)

Applied to moovie/ submodule development:

- **`frontend/block-cross-feature-data-imports.sh`** — Prevents breaking architecture rules
  - Blocks: Importing data layers from other features
  - Checks: Only domain imports allowed between features
  - Applied to: File imports in features/*/
  - Raises: Error on cross-feature data import

- **`frontend/format-code.sh`** — Auto-formats Dart code
  - Runs: `dart format` on edited files
  - Applied to: Edit and Write tool (post-use)
  - Raises: Warning on format failure (non-blocking)

- **`frontend/regenerate-generated-files.sh`** — Regenerates build_runner outputs
  - Runs: `dart run build_runner build --delete-conflicting-outputs`
  - Triggers: If .dart files in features or DI changes
  - Applied to: Completion of code generation
  - Raises: Error on build_runner failure

- **`frontend/validate-implementation.sh`** — Validates Dart code patterns
  - Checks: Result<T> usage, Future/Stream proper usage, GetIt registration
  - Applied to: domain/ and data/ layer files
  - Raises: Error on pattern violations

- **`frontend/validate-localization.sh`** — Validates ARB localization files
  - Checks: Keys exist in en.arb, es.arb, and pt.arb (bilingual requirement)
  - Applied to: Changes in l10n/*.arb files
  - Raises: Error on missing translations

- **`frontend/validate-module-structure.sh`** — Validates feature module structure
  - Checks: domain/ and data/ exist, barrel files correct, DI registration
  - Applied to: Feature module creation/changes
  - Raises: Error on structure violations

- **`frontend/verify-di-registration.sh`** — Verifies DI registration completeness
  - Checks: All @module classes wired into `injection.config.dart`
  - Applied to: Changes in lib/di/
  - Raises: Error if DI registration missing

### Backend Hooks (Kotlin/Ktor)

Applied to backend/ submodule development:

- **`backend/verify-koin-di-registration.sh`** — Verifies Koin DI registration
  - Checks: All usecases/datasources/repositories registered in Koin modules
  - Applied to: Domain, data, and presentation layer files
  - Raises: Error if DI registration missing

- **`backend/validate-backend-structure.sh`** — Validates clean architecture structure
  - Checks: Files in correct domain/data/presentation directories
  - Checks: Package names match directory structure
  - Checks: Suspend functions used in data layer
  - Applied to: Kotlin file creation/edits in backend/src/main/
  - Raises: Error on structure violations

- **`backend/validate-kotlin-code.sh`** — Validates Kotlin code patterns
  - Checks: No `Thread.sleep()` in suspend functions
  - Checks: `runBlocking` only in usecases
  - Checks: No Result<T> wrappers in suspend functions
  - Checks: No Future/CompletableFuture (use suspend fun)
  - Applied to: Kotlin implementation files
  - Raises: Error on pattern violations, warning on style issues

---

## Hook Integration with Agents

Each agent has hooks defined in its frontmatter:

### implementer-tester (Frontend)

```yaml
hooks:
  PostToolUse: [Edit, Write]      # format-code.sh, regenerate-generated-files.sh
  Stop: []                        # validate-implementation.sh, verify-di-registration.sh
  PreToolUse: [Bash]             # block-destructive-commands.sh
```

### backend-implementer (Backend)

```yaml
hooks:
  PostToolUse: [Edit, Write]      # No post-use for Kotlin (no auto-format in this setup)
  Stop: []                        # validate-kotlin-code.sh, validate-backend-structure.sh
  PreToolUse: [Bash]             # block-destructive-commands.sh
```

### All Agents

```yaml
hooks:
  PreToolUse: [Bash]              # block-destructive-commands.sh, enforce-path-restrictions.sh
```

---

## Hook Execution Points

### Pre-Tool-Use Hooks
Run BEFORE a tool executes:
- Check parameters for invalid/dangerous values
- Validate context (correct directory, permissions, etc.)
- Block execution if validation fails

### Post-Tool-Use Hooks
Run AFTER a tool completes:
- Auto-fix formatting or code generation
- Re-index or rebuild if needed
- Warn if optional cleanups couldn't run

### Stop Hooks
Run at agent completion (stop/gate):
- Final validation before merge
- Check all requirements met
- Block handoff if issues found

---

## Writing New Hooks

### Hook Template

```bash
#!/bin/bash
# hooks/<category>/<name>.sh
# <Description>
# Define as <hook_type> hook in <agent> frontmatter

set -e

input=$(cat)

# Extract from JSON input
file_path=$(echo "$input" | jq -r '.tool_input.file_path // empty' 2>/dev/null)
command=$(echo "$input" | jq -r '.tool_input.command // empty' 2>/dev/null)

if [ -z "$file_path" ]; then
  exit 0  # No-op if no relevant input
fi

errors=""

# Validation logic here

if [ -n "$errors" ]; then
  echo -e "❌ Error Title:$errors" >&2
  exit 1
fi

exit 0
```

### Hook Guidelines

- ✅ **Silent on success** — Exit 0, no output unless warning
- ✅ **Clear error messages** — Describe what's wrong and how to fix
- ✅ **Defensive checks** — Exit early if context doesn't apply
- ✅ **Idempotent** — Safe to run multiple times
- ❌ **Don't block on warnings** — Exit 0, output to stderr
- ❌ **Don't make assumptions** — Check directory structure, file existence

---

## Running Hooks Locally

### Manual Execution

```bash
# Test a hook with sample input
echo '{"tool": "Edit", "tool_input": {"file_path": "path/to/file.dart"}}' | \
  ./hooks/frontend/format-code.sh
```

### In CI/CD

Hooks run automatically in CI pipelines via GitHub Actions or similar. PRs must pass all hooks.

### In Agents

Hooks run automatically when agents are invoked. Agent frontmatter defines which hooks apply.

---

## Common Hook Patterns

### Check File Exists
```bash
if [ ! -f "$file_path" ]; then
  exit 0  # File doesn't exist, nothing to check
fi
```

### Extract Variable from Input
```bash
variable=$(echo "$input" | jq -r '.path.to.value // empty' 2>/dev/null)
if [ -z "$variable" ]; then
  exit 0  # No value provided
fi
```

### Search for Pattern in File
```bash
if grep -q "forbidden_pattern" "$file_path"; then
  errors="$errors\nError: forbidden_pattern found"
fi
```

### Report Multiple Errors
```bash
if [ -n "$errors" ]; then
  echo -e "❌ Title:$errors" >&2
  exit 1
fi
```

---

## Future Enhancements

Potential hooks to add:
- **Security scanning** — Check for common vulnerabilities
- **Performance analysis** — Warn on potential performance issues
- **Type coverage** — Ensure proper type annotations in Dart/Kotlin
- **Test coverage** — Warn if test coverage drops
- **Documentation** — Check for missing documentation
=======
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
| `check-submodule-ai.sh` | `PreToolUse` Bash | Blocks `git commit` / `git push` when the operation actually involves `moovie/` or `backend/` AND that submodule's *tracked* files include AI-tooling paths (enforces `rules/AI_AGNOSTIC_SUBMODULES.md`). No-op when the change set does not touch a submodule path. |
| `check-docs-sync.sh` | `PreToolUse` Bash | Blocks `gh pr create` / `git push` when critical files change vs the appropriate base branch without a corresponding doc update. Base branch is inferred from `HEAD`: `release/*` and `develop` target `main`, everything else targets `develop` (enforces `rules/DOCS_UP_TO_DATE.md`). |
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
>>>>>>> origin/dev:.claude/hooks/README.md
