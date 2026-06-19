#!/bin/bash
# .claude/hooks/validate-module-structure.sh
# Validates that every feature/UI module has the required structure.
# Define this as a Stop hook in the flutter-implementer-tester agent's frontmatter.
# Mirrors the rules in .claude/rules/feature-architecture.md and ui-architecture.md.

set -e

input=$(cat)
errors=""

# Feature modules: features/<x>/{lib, domain, data} each with a pubspec + barrel
if [ -d "features" ]; then
  while IFS= read -r feature_dir; do
    name=$(basename "$feature_dir")

    [ ! -f "$feature_dir/pubspec.yaml" ]            && errors+="\n  - $feature_dir is missing pubspec.yaml"
    [ ! -f "$feature_dir/lib/$name.dart" ]          && errors+="\n  - $feature_dir is missing the barrel file lib/$name.dart"

    [ ! -f "$feature_dir/domain/pubspec.yaml" ]     && errors+="\n  - $feature_dir is missing domain/pubspec.yaml"
    [ ! -f "$feature_dir/domain/lib/domain.dart" ]  && errors+="\n  - $feature_dir is missing domain/lib/domain.dart"
    [ ! -d "$feature_dir/domain/lib/models" ]       && errors+="\n  - $feature_dir is missing domain/lib/models/"
    [ ! -d "$feature_dir/domain/lib/repositories" ] && errors+="\n  - $feature_dir is missing domain/lib/repositories/"
    [ ! -d "$feature_dir/domain/lib/usecases" ]     && errors+="\n  - $feature_dir is missing domain/lib/usecases/"

    [ ! -f "$feature_dir/data/pubspec.yaml" ]       && errors+="\n  - $feature_dir is missing data/pubspec.yaml"
    [ ! -f "$feature_dir/data/lib/data.dart" ]      && errors+="\n  - $feature_dir is missing data/lib/data.dart"
    [ ! -d "$feature_dir/data/lib/datasources" ]    && errors+="\n  - $feature_dir is missing data/lib/datasources/"
    [ ! -d "$feature_dir/data/lib/repositories" ]   && errors+="\n  - $feature_dir is missing data/lib/repositories/"
    [ ! -d "$feature_dir/data/lib/models" ]         && errors+="\n  - $feature_dir is missing data/lib/models/"
  done < <(find features -mindepth 1 -maxdepth 1 -type d)
fi

# UI packages: must have pubspec.yaml and lib/. Per-page subdirectories are
# expected to follow the bloc/screen/state convention, but this hook stays
# lenient to avoid false positives on legacy multi-page packages.
if [ -d "ui" ]; then
  while IFS= read -r ui_dir; do
    [ ! -f "$ui_dir/pubspec.yaml" ] && errors+="\n  - $ui_dir is missing pubspec.yaml"
    [ ! -d "$ui_dir/lib" ]          && errors+="\n  - $ui_dir is missing lib/"
  done < <(find ui -mindepth 1 -maxdepth 1 -type d)
fi

# File naming: dart files must be snake_case (no uppercase, no hyphens)
while IFS= read -r dart_file; do
  base=$(basename "$dart_file")
  if [[ "$base" =~ [A-Z] ]] || [[ "$base" =~ - ]]; then
    errors+="\n  - $dart_file: filenames must be snake_case"
  fi
done < <(find features ui lib test -type f -name "*.dart" 2>/dev/null | grep -vE "\.(g|gr|config)\.dart$")

if [ -n "$errors" ]; then
  echo "Blocked: module structure does not match .claude/rules/feature-architecture.md and ui-architecture.md" >&2
  printf "%b" "$errors" >&2
  echo "" >&2
  echo "Use the scaffolding skills to create new modules correctly:" >&2
  echo "  /new-datasource  /new-repository  /new-usecase  /new-ui-module" >&2
  exit 2
fi

exit 0
