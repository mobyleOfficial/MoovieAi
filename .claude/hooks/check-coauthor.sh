#!/bin/bash
# .claude/hooks/check-coauthor.sh
# Blocks `git commit` invocations that contain Co-Authored-By trailers.
# Enforces rules/NO_COAUTHORS.md across all sessions.
# Register as PreToolUse hook on the Bash tool in .claude/settings.json.

set -e

input=$(cat)
command=$(echo "$input" | jq -r '.tool_input.command // empty')

if [ -z "$command" ]; then
  exit 0
fi

# Match `git commit` as an actual invocation: at the start of the command,
# after a chain operator (`;`, `&&`, `||`), or after one or more env-var
# prefixes (`FOO=bar git commit`). Quoted occurrences inside echo/printf
# strings do not match because the preceding character is a quote, not a
# chain operator.
if ! echo "$command" | grep -qE '(^|[;&|][[:space:]]*)([A-Z_][A-Za-z0-9_]*=[^[:space:]]+[[:space:]]+)*git[[:space:]]+commit'; then
  exit 0
fi

# Look for Co-Authored-By trailers (case-insensitive; with or without hyphens)
if echo "$command" | grep -qiE 'Co[-]?Authored[-]?By'; then
  echo "❌ NO_COAUTHORS rule violation: commit message contains a Co-Authored-By trailer." >&2
  echo "   See rules/NO_COAUTHORS.md — single author per commit, always." >&2
  exit 2
fi

exit 0
