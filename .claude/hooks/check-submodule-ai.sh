#!/bin/bash
# .claude/hooks/check-submodule-ai.sh
# Blocks `git commit` and `git push` (in the meta-repo) when an operation
# actually involves a submodule that contains AI-tooling files. Enforces
# rules/AI_AGNOSTIC_SUBMODULES.md.
#
# Scoping: do not block every unrelated meta-repo commit. Only block if:
#   - the staged change set or the operation's pathspec includes
#     moovie/ or backend/, AND
#   - that submodule's TRACKED files include any AI-tooling path.
#
# Why tracked-only: a leftover .claude/ in a submodule working tree that
# isn't committed is not a rule violation — submodules must be AI-agnostic
# in their git history, not on every contributor's disk.

set -e

input=$(cat)
command=$(echo "$input" | jq -r '.tool_input.command // empty')

if [ -z "$command" ]; then
  exit 0
fi

# Anchor: actual `git commit` or `git push` invocation, not a quoted string.
COMMIT_PATTERN='(^|[;&|][[:space:]]*)([A-Z_][A-Za-z0-9_]*=[^[:space:]]+[[:space:]]+)*git[[:space:]]+(commit|push)'
if ! echo "$command" | grep -qE "$COMMIT_PATTERN"; then
  exit 0
fi

repo_root=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
cd "$repo_root" 2>/dev/null || exit 0

# Determine which submodules are involved in THIS operation.
# Sources of involvement:
#   1. Currently staged files (any path under moovie/ or backend/)
#   2. Currently unstaged-but-modified files (will be picked up by git add -A)
#   3. The current branch points at a submodule-only commit (rare; conservative)
involved=""
staged=$(git diff --cached --name-only 2>/dev/null || true)
unstaged=$(git diff --name-only 2>/dev/null || true)
combined=$(printf '%s\n%s\n' "$staged" "$unstaged")

for submodule in moovie backend; do
  if echo "$combined" | grep -qE "^${submodule}(/|$)"; then
    involved+="$submodule "
  fi
done

# If no submodule is involved in the operation, this hook has nothing to say.
if [ -z "$involved" ]; then
  exit 0
fi

violations=""
for submodule in $involved; do
  [ -d "$submodule" ] || continue

  # List TRACKED files inside the submodule that match AI-tooling paths.
  # ls-files is git-aware and only returns files in the submodule's index.
  tracked=$(git -C "$submodule" ls-files 2>/dev/null || true)
  matches=$(echo "$tracked" | grep -E '^(\.claude/|CLAUDE\.md$|\.cursorrules$|AGENTS\.md$|\.github/copilot-instructions\.md$)' || true)

  if [ -n "$matches" ]; then
    while IFS= read -r f; do
      [ -n "$f" ] && violations+="  $submodule/$f"$'\n'
    done <<< "$matches"
  fi
done

if [ -n "$violations" ]; then
  echo "❌ AI_AGNOSTIC_SUBMODULES rule violation: submodule contains AI-tooling files (tracked)." >&2
  echo "" >&2
  echo "$violations" >&2
  echo "" >&2
  echo "   Submodules must remain AI-agnostic. Move AI config to the meta-repo (.claude/, root CLAUDE.md, rules/, etc.)." >&2
  echo "   See rules/AI_AGNOSTIC_SUBMODULES.md." >&2
  exit 2
fi

exit 0
