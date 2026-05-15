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

# Only inspect actual `git commit` invocations — match the first command in a
# pipeline/chain so quoted strings or echo'd examples don't trigger.
first_token=$(echo "$command" | awk '{print $1}' | awk -F'[|;&]' '{print $NF}')
first_arg=$(echo "$command" | awk '{print $2}')

if [ "$first_token" != "git" ] || [ "$first_arg" != "commit" ]; then
  exit 0
fi

if echo "$command" | grep -qiE 'Co-?Authored-?By'; then
  echo "❌ NO_COAUTHORS rule violation: commit message contains a Co-Authored-By trailer." >&2
  echo "   See rules/NO_COAUTHORS.md — single author per commit, always." >&2
  exit 2
fi

exit 0
