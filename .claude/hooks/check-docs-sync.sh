#!/bin/bash
# .claude/hooks/check-docs-sync.sh
# Blocks `gh pr create` and `git push` when critical files have changed
# without a corresponding doc update. Enforces rules/DOCS_UP_TO_DATE.md.
# Register as PreToolUse hook on the Bash tool in .claude/settings.json.

set -e

input=$(cat)
command=$(echo "$input" | jq -r '.tool_input.command // empty')

if [ -z "$command" ]; then
  exit 0
fi

# Match actual `gh pr create` or `git push` invocations: at start-of-pipeline,
# after a chain operator, or after env-var prefixes. Quoted occurrences inside
# echo/printf do not trigger.
PR_PATTERN='(^|[;&|][[:space:]]*)([A-Z_][A-Za-z0-9_]*=[^[:space:]]+[[:space:]]+)*gh[[:space:]]+pr[[:space:]]+create'
PUSH_PATTERN='(^|[;&|][[:space:]]*)([A-Z_][A-Za-z0-9_]*=[^[:space:]]+[[:space:]]+)*git[[:space:]]+push'

if ! echo "$command" | grep -qE "$PR_PATTERN" && ! echo "$command" | grep -qE "$PUSH_PATTERN"; then
  exit 0
fi

# Locate verify-docs.sh
repo_root=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
verify="$repo_root/.claude/verify-docs.sh"

if [ ! -x "$verify" ]; then
  # No verifier installed — let the operation through
  exit 0
fi

# Use mktemp so the path is unpredictable + per-user — avoids the
# symlink-clobber attack a predictable /tmp/<name>.$PID would enable.
tmpfile=$(mktemp -t check-docs-sync.XXXXXX) || exit 0
trap 'rm -f "$tmpfile"' EXIT

if ! "$verify" >"$tmpfile" 2>&1; then
  echo "❌ DOCS_UP_TO_DATE rule violation:" >&2
  cat "$tmpfile" >&2
  echo "" >&2
  echo "   Update README.md / CLAUDE.md / relevant subdir README in this branch before pushing or opening a PR." >&2
  echo "   See rules/DOCS_UP_TO_DATE.md." >&2
  exit 2
fi

exit 0
