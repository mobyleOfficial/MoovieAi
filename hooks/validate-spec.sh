#!/bin/bash
# .claude/hooks/validate-spec.sh
# Validates that pm-spec produced a complete spec for the current pipeline stage.
# Define this as a Stop hook in the pm-spec agent's frontmatter.
# Reads the active stage from .claude/task/pipeline-queue.json.

set -e

input=$(cat)
queue_file=".claude/task/pipeline-queue.json"

if [ ! -f "$queue_file" ]; then
  # No active pipeline — nothing to validate
  exit 0
fi

# Find the spec output path for the current in-progress spec stage
spec_file=$(jq -r '.stages[] | select(.name == "spec" and .status == "in-progress") | .output' "$queue_file")

if [ -z "$spec_file" ] || [ "$spec_file" = "null" ]; then
  # No active spec stage — nothing to validate
  exit 0
fi

if [ ! -f "$spec_file" ]; then
  echo "Blocked: spec file was not created at $spec_file" >&2
  echo "The pm-spec agent must write the spec to this path." >&2
  exit 2
fi

# Required sections per .claude/agents/pm-spec.md template
REQUIRED_SECTIONS=(
  "## Overview"
  "## User Stories"
  "## Acceptance Criteria"
  "## Technical Notes"
  "## Out of Scope"
)

for section in "${REQUIRED_SECTIONS[@]}"; do
  if ! grep -qF "$section" "$spec_file"; then
    echo "Blocked: spec is missing required section: $section" >&2
    echo "File: $spec_file" >&2
    exit 2
  fi
done

# Acceptance Criteria must have substantive content (not just the heading)
criteria=$(awk '/^## Acceptance Criteria/{flag=1;next}/^## /{flag=0}flag' "$spec_file")
if [ "$(echo "$criteria" | wc -w)" -lt 15 ]; then
  echo "Blocked: Acceptance Criteria section is empty or too short (<15 words)" >&2
  echo "File: $spec_file" >&2
  exit 2
fi

# Flutter-specific: Technical Notes must identify affected modules
if ! grep -qiE "(features/|ui/|domain|data layer|repository|use case|bloc|cubit)" "$spec_file"; then
  echo "Blocked: Technical Notes must identify the affected modules" >&2
  echo "Mention at least one of: features/, ui/, domain, data, repository, use case, BLoC/Cubit." >&2
  exit 2
fi

exit 0
