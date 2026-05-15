#!/bin/bash
# Verifies README.md and CLAUDE.md are updated when relevant code changes
# Triggered before PR creation to catch out-of-sync documentation

set -euo pipefail

# Get files changed in this branch vs main
CHANGED_FILES=$(git diff --name-only main...HEAD 2>/dev/null || git diff --name-only origin/main...HEAD 2>/dev/null || echo "")

if [ -z "$CHANGED_FILES" ]; then
  echo "No changes detected. Documentation check skipped."
  exit 0
fi

VIOLATIONS=0
DOCS_MODIFIED=0

# Check if docs were modified
if echo "$CHANGED_FILES" | grep -qE "^(README\.md|CLAUDE\.md)$"; then
  DOCS_MODIFIED=1
fi

# Patterns that should trigger doc updates
CRITICAL_CHANGES=(
  "^\.claude/"                          # Claude config + skills + hooks
  "^plugins/"                           # Plugin changes
  "^agents/"                            # Agents changes
  "^rules/"                             # Rules changes
  "^moovie/" "^backend/"                # Submodule structure changes
)

HAS_CRITICAL_CHANGE=0
for pattern in "${CRITICAL_CHANGES[@]}"; do
  if echo "$CHANGED_FILES" | grep -qE "$pattern"; then
    HAS_CRITICAL_CHANGE=1
    break
  fi
done

# Check for setup/dependency changes
if echo "$CHANGED_FILES" | grep -qE "(package\.json|gradle|pubspec\.yaml|Gemfile|\.env|docker)"; then
  HAS_CRITICAL_CHANGE=1
fi

if [ "$HAS_CRITICAL_CHANGE" -eq 1 ] && [ "$DOCS_MODIFIED" -eq 0 ]; then
  echo "⚠️  Documentation out of sync"
  echo ""
  echo "Critical files changed:"
  echo "$CHANGED_FILES" | grep -E "^\.claude/|^plugins/|^agents/|^rules/|^moovie/|^backend/|package\.json|gradle|pubspec\.yaml|Gemfile|\.env|docker" | sed 's/^/  - /'
  echo ""
  echo "README.md and/or CLAUDE.md should be updated."
  echo "Update docs before opening PR to keep team in sync."
  exit 1
fi

exit 0
