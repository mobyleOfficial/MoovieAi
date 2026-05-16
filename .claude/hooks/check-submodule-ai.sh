#!/bin/bash
# .claude/hooks/check-submodule-ai.sh
# Blocks `git commit` and `git push` if a submodule (moovie/, backend/) contains
# AI-tooling files. Enforces rules/AI_AGNOSTIC_SUBMODULES.md.
# Register as PreToolUse hook on the Bash tool in .claude/settings.json.

set -e

input=$(cat)
command=$(echo "$input" | jq -r '.tool_input.command // empty')

if [ -z "$command" ]; then
  exit 0
fi

# Match actual `git commit` or `git push` invocations (start-of-pipeline,
# chain-operator, env-var-prefix anchors).
COMMIT_PATTERN='(^|[;&|][[:space:]]*)([A-Z_][A-Za-z0-9_]*=[^[:space:]]+[[:space:]]+)*git[[:space:]]+(commit|push)'

if ! echo "$command" | grep -qE "$COMMIT_PATTERN"; then
  exit 0
fi

repo_root=$(git rev-parse --show-toplevel 2>/dev/null || pwd)

violations=""
for submodule in moovie backend; do
  sub_path="$repo_root/$submodule"
  [ -d "$sub_path" ] || continue

  # Forbidden AI-tooling paths inside a submodule
  while IFS= read -r found; do
    [ -n "$found" ] && violations+="  $submodule/$found"$'\n'
  done < <(
    cd "$sub_path" 2>/dev/null && {
      ls -d .claude 2>/dev/null
      ls CLAUDE.md 2>/dev/null
      ls .cursorrules 2>/dev/null
      ls -d .github/copilot-instructions.md 2>/dev/null
      ls AGENTS.md 2>/dev/null
      ls .agents/* 2>/dev/null
    }
  )
done

if [ -n "$violations" ]; then
  echo "❌ AI_AGNOSTIC_SUBMODULES rule violation: submodule contains AI-tooling files." >&2
  echo "$violations" >&2
  echo "" >&2
  echo "   Submodules must remain AI-agnostic. Move AI config to the meta-repo (.claude/, root CLAUDE.md, rules/, etc.)." >&2
  echo "   See rules/AI_AGNOSTIC_SUBMODULES.md." >&2
  exit 2
fi

exit 0
