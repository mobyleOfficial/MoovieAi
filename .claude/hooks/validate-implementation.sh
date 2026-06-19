#!/bin/bash
# .claude/hooks/validate-implementation.sh
# Validates that flutter-implementer-tester left the Flutter project in a healthy state.
# Define this as a Stop hook in the flutter-implementer-tester agent's frontmatter.
# Runs `flutter analyze` and `flutter test` — blocks on any error.

set -e

input=$(cat)

# Skip validation gracefully if flutter is not on PATH (e.g. agent ran in a
# sandbox without the SDK). The agent should have flagged this in its output.
if ! command -v flutter >/dev/null 2>&1; then
  echo "Warning: flutter not on PATH — skipping analyze/test validation" >&2
  exit 0
fi

analyze_log=$(mktemp)
test_log=$(mktemp)
trap 'rm -f "$analyze_log" "$test_log"' EXIT

# 1. Static analysis — must have zero errors (info/warning are allowed)
if ! flutter analyze --no-pub > "$analyze_log" 2>&1; then
  if grep -qE "^\s*error\s+-" "$analyze_log"; then
    echo "Blocked: flutter analyze reported errors" >&2
    grep -E "^\s*error\s+-" "$analyze_log" | head -n 30 >&2
    exit 2
  fi
fi

# 2. Unit + widget tests — all must pass
if ! flutter test --no-pub > "$test_log" 2>&1; then
  echo "Blocked: flutter test failed" >&2
  tail -n 40 "$test_log" >&2
  exit 2
fi

# 3. Sanity check: generated files were not hand-edited (build_runner outputs)
#    Look at git status — any *.g.dart / *.gr.dart / app_localizations* changes
#    must come from regeneration, not manual edits.
if command -v git >/dev/null 2>&1; then
  hand_edited=$(git diff --name-only HEAD 2>/dev/null | \
    grep -E "(\.g\.dart|\.gr\.dart|app_localizations.*\.dart|objectbox-model\.json)$" || true)
  if [ -n "$hand_edited" ]; then
    echo "Warning: generated files appear in the diff — make sure they came from build_runner / flutter gen-l10n, not hand edits:" >&2
    echo "$hand_edited" >&2
  fi
fi

exit 0
