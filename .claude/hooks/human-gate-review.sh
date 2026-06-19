#!/bin/bash
# .claude/hooks/human-gate-review.sh
# Human gate after the architect review stage.
# Define this as a Stop hook in the architect-review agent's frontmatter.
# Reads the active stage from .claude/task/pipeline-queue.json so paths stay
# in sync with the queue (no hard-coded .tasks/ paths).

set -e

input=$(cat)
queue_file=".claude/task/pipeline-queue.json"

if [ ! -f "$queue_file" ]; then
  echo "Blocked: pipeline queue not found at $queue_file" >&2
  exit 2
fi

# Pull the review file path and the spec path it gated from the queue
review_file=$(jq -r 'first(.stages[] | select(.name == "review" and .status == "in-progress") | .output) // empty' "$queue_file")
spec_file=$(jq -r 'first(.stages[] | select(.name == "spec") | .output) // empty' "$queue_file")

if [ -z "$review_file" ]; then
  # Architect-review ran outside the pipeline — nothing to gate on
  exit 0
fi

if [ ! -f "$review_file" ]; then
  echo "Blocked: architect-review did not produce $review_file" >&2
  exit 2
fi

decision=$(grep -E "^Decision:[[:space:]]+(APPROVED|REJECTED)" "$review_file" | awk '{print $2}' | head -n 1)

if [ "$decision" = "REJECTED" ]; then
  echo "Blocked: architect rejected the design" >&2
  echo "Review feedback in $review_file and revise the spec at $spec_file." >&2
  exit 2
fi

if [ "$decision" = "APPROVED" ]; then
  echo "Architect approved the design."
  echo ""
  echo "------------------------------------------------------------"
  echo "HUMAN GATE: review the approval before implementation starts"
  echo "------------------------------------------------------------"
  echo ""
  echo "  Spec   : $spec_file"
  echo "  Review : $review_file"
  echo ""
  echo "To proceed:  use the flutter-implementer-tester subagent on $spec_file"
  echo "To revise :  edit the spec, then re-run the architect-review subagent"
  echo ""
  exit 0
fi

echo "Blocked: review decision is missing or unrecognized" >&2
echo "Expected a line like 'Decision: APPROVED' or 'Decision: REJECTED' in $review_file." >&2
exit 2
