#!/bin/bash
# Validates that .claude/ config files use only portable, relative paths
# Blocks commits that violate LOCAL_CLAUDE_CONFIG.md rule

set -euo pipefail

RULE_FILE="rules/LOCAL_CLAUDE_CONFIG.md"
VIOLATIONS=0
ERROR_LOG=""

# Patterns forbidden in .claude/ files
FORBIDDEN_PATTERNS=(
  '~/'                                    # Global home path
  '/Users/'                               # Absolute user path (macOS)
  '/home/'                                # Absolute user path (Linux)
  '/root/'                                # Absolute root path
  '$HOME'                                 # Environment variable (should use relative)
)

# Files to check (JSON configs only — actual user config, not tools)
CONFIG_FILES=(.claude/settings.json .claude/settings.local.json)

for file in "${CONFIG_FILES[@]}"; do
  [ -f "$file" ] || continue

  line_num=0
  while IFS= read -r line; do
    line_num=$((line_num + 1))

    # Skip comments and empty lines
    [[ "$line" =~ ^[[:space:]]*# ]] && continue
    [[ -z "${line// }" ]] && continue

    for pattern in "${FORBIDDEN_PATTERNS[@]}"; do
      if [[ "$line" =~ $pattern ]]; then
        VIOLATIONS=$((VIOLATIONS + 1))
        ERROR_LOG+="$file:$line_num: Found forbidden path pattern '$pattern'"$'\n'
        ERROR_LOG+="  > $line"$'\n'
      fi
    done
  done < "$file"
done

if [ $VIOLATIONS -gt 0 ]; then
  echo "❌ LOCAL_CLAUDE_CONFIG.md violation(s) detected:" >&2
  echo "" >&2
  echo "$ERROR_LOG" >&2
  echo "See $RULE_FILE for details." >&2
  exit 1
fi

exit 0
