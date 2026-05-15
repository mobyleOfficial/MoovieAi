#!/bin/bash
# .claude/hooks/block-cross-feature-data-imports.sh
# Blocks any file from importing another feature's data layer directly.
# Per .claude/rules/feature-architecture.md: "Never import from another
# feature's data/ layer directly — use the domain/ layer as the contract."
# Define this as a PreToolUse hook on the Edit and Write tools.

set -e

input=$(cat)
file_path=$(echo "$input" | jq -r '.tool_input.file_path // empty')
# Write provides `content`; Edit provides `new_string` (the snippet being inserted).
content=$(echo "$input" | jq -r '.tool_input.content // .tool_input.new_string // empty')

if [ -z "$file_path" ] || [ -z "$content" ]; then
  exit 0
fi

# Only enforce on .dart files
case "$file_path" in
  *.dart) ;;
  *) exit 0 ;;
esac

# Determine the owning feature, if any (path like features/<owner>/...)
owner=""
if [[ "$file_path" =~ features/([^/]+)/ ]]; then
  owner="${BASH_REMATCH[1]}"
fi

# Find every import of a *_data package in the inserted content
imports=$(echo "$content" | grep -oE "import[[:space:]]+['\"]package:[a-zA-Z0-9_]+_data/" || true)

if [ -z "$imports" ]; then
  exit 0
fi

violations=""
while IFS= read -r import_line; do
  pkg=$(echo "$import_line" | sed -E "s/.*package:([a-zA-Z0-9_]+)_data\/.*/\1/")
  # Self-imports inside the owning feature's data layer are allowed.
  if [ -n "$owner" ] && [ "$pkg" = "$owner" ] && [[ "$file_path" == *"/features/$owner/data/"* ]]; then
    continue
  fi
  # Same-feature barrel re-exports use `export`, not `import`, so any `import`
  # of <pkg>_data from outside features/<pkg>/data/ is a violation.
  violations+="\n  - $file_path imports package:${pkg}_data — depend on package:${pkg}_domain (or the feature's barrel) instead."
done <<< "$imports"

if [ -n "$violations" ]; then
  echo "Blocked: cross-feature data-layer imports are not allowed." >&2
  printf "%b" "$violations" >&2
  echo "" >&2
  echo "Rule: features/<x>/data/ is private. Cross-feature contracts go through features/<x>/domain/." >&2
  exit 2
fi

exit 0
