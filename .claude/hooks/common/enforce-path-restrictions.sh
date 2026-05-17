#!/bin/bash
# .claude/hooks/enforce-path-restrictions.sh
# Enforces file path restrictions for subagents via PreToolUse hook.
# Define this as a PreToolUse hook in the agent's frontmatter.
# Uses tool_input.file_path from the hook JSON input.

set -e

input=$(cat)
file_path=$(echo "$input" | jq -r '.tool_input.file_path // empty')

if [ -z "$file_path" ]; then
  exit 0  # No file path, nothing to check
fi

# Define allowed path patterns (customize per agent)
# Multimodule Flutter project: features/<feature>/{domain,data}, ui/<module>, lib/ (main app)
ALLOWED_PATTERNS=(
  "features/**"
  "ui/**"
  "lib/**"
  "test/**"
  "pubspec.yaml"
  "analysis_options.yaml"
  "l10n.yaml"
)

# Block sensitive paths and generated files (must be regenerated via build_runner, never hand-edited)
BLOCKED_PATTERNS=(
  ".env"
  ".env.*"
  "secrets/**"
  "**/*.g.dart"
  "**/*.gr.dart"
  "**/objectbox-model.json"
  "**/app_localizations*.dart"
  "android/**"
  "ios/**"
  "macos/**"
  "windows/**"
  "linux/**"
  "web/**"
  ".dart_tool/**"
  "build/**"
)

# Check blocked patterns first
for pattern in "${BLOCKED_PATTERNS[@]}"; do
  if [[ "$file_path" == $pattern ]]; then
    echo "Blocked: access to $file_path is not allowed" >&2
    exit 2  # Exit 2 = block the tool call
  fi
done

# Check if file_path matches any allowed pattern
shopt -s globstar nullglob
allowed=false
for pattern in "${ALLOWED_PATTERNS[@]}"; do
  if [[ "$file_path" == $pattern ]]; then
    allowed=true
    break
  fi
done

if [ "$allowed" = false ]; then
  echo "Permission denied: $file_path is not in the allowed paths" >&2
  exit 2
fi

exit 0