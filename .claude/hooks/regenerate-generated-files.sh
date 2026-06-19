#!/bin/bash
# .claude/hooks/regenerate-generated-files.sh
# Regenerates code-gen outputs when annotations or ARB files have changed.
# Define this as a Stop hook in the flutter-implementer-tester agent's frontmatter.
# Runs BEFORE validate-implementation.sh so analyze/test see fresh generated code.
#
# Triggers:
#   - Any *.dart change containing @RoutePage / @AutoRouterConfig    -> build_runner in that package
#   - Any *.dart change containing @module / @injectable / @Entity   -> build_runner in that package
#   - Any *.arb change in ui/common/lib/l10n/                        -> flutter gen-l10n at project root

set -e

input=$(cat)

if ! command -v git >/dev/null 2>&1; then
  exit 0
fi
if ! command -v flutter >/dev/null 2>&1; then
  exit 0
fi

# Files changed in the working tree (staged + unstaged + untracked)
changed=$(git status --porcelain 2>/dev/null | awk '{print $NF}')

if [ -z "$changed" ]; then
  exit 0
fi

declare -A packages_to_rebuild=()
regen_l10n=false

while IFS= read -r f; do
  [ -z "$f" ] && continue
  [ ! -f "$f" ] && continue

  case "$f" in
    *app_en.arb|*app_es.arb|*app_pt.arb)
      regen_l10n=true
      ;;
    *.dart)
      # Skip generated outputs
      case "$f" in
        *.g.dart|*.gr.dart|*app_localizations*) continue ;;
      esac
      if grep -qE "@(RoutePage|AutoRouterConfig|module|injectable|lazySingleton|singleton|LazySingleton|Singleton|Injectable|Entity)\\b" "$f"; then
        # Walk up to find the owning pubspec.yaml
        dir=$(dirname "$f")
        while [ "$dir" != "." ] && [ "$dir" != "/" ]; do
          if [ -f "$dir/pubspec.yaml" ]; then
            packages_to_rebuild["$dir"]=1
            break
          fi
          dir=$(dirname "$dir")
        done
      fi
      ;;
  esac
done <<< "$changed"

# Run build_runner in every affected package
for pkg in "${!packages_to_rebuild[@]}"; do
  echo "Regenerating code in $pkg ..."
  (cd "$pkg" && dart run build_runner build --delete-conflicting-outputs 2>&1 | tail -n 5) || {
    echo "Warning: build_runner failed in $pkg — implementer must fix before stopping" >&2
  }
done

if [ "$regen_l10n" = true ]; then
  echo "Regenerating localizations (flutter gen-l10n) ..."
  flutter gen-l10n 2>&1 | tail -n 5 || {
    echo "Warning: flutter gen-l10n failed — check ARB syntax" >&2
  }
fi

exit 0
