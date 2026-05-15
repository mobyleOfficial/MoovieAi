#!/bin/bash
# .claude/hooks/validate-localization.sh
# Enforces ARB key parity across app_en.arb / app_es.arb / app_pt.arb.
# Define this as a Stop hook in the implementer-tester agent's frontmatter.
# Every translatable key (i.e. not starting with @) in the English template
# must also exist in the Spanish and Portuguese ARB files.

set -e

input=$(cat)
l10n_dir="ui/common/lib/l10n"
en_arb="$l10n_dir/app_en.arb"
es_arb="$l10n_dir/app_es.arb"
pt_arb="$l10n_dir/app_pt.arb"

if [ ! -f "$en_arb" ]; then
  # No localization in this project — nothing to check
  exit 0
fi

# Extract translatable keys (skip @-prefixed metadata and the @@locale key)
en_keys=$(jq -r 'keys[]' "$en_arb" | grep -v '^@' | sort -u)

if [ -z "$en_keys" ]; then
  exit 0
fi

missing_summary=""

for locale_file in "$es_arb" "$pt_arb"; do
  if [ ! -f "$locale_file" ]; then
    echo "Blocked: missing translation file $locale_file" >&2
    exit 2
  fi

  locale_keys=$(jq -r 'keys[]' "$locale_file" | grep -v '^@' | sort -u)
  missing=$(comm -23 <(echo "$en_keys") <(echo "$locale_keys") || true)

  if [ -n "$missing" ]; then
    missing_summary+="\n  $locale_file is missing:\n"
    while IFS= read -r key; do
      missing_summary+="    - $key\n"
    done <<< "$missing"
  fi
done

if [ -n "$missing_summary" ]; then
  echo "Blocked: ARB key parity broken — every key in app_en.arb must be translated in app_es.arb and app_pt.arb" >&2
  printf "%b" "$missing_summary" >&2
  echo "" >&2
  echo "After adding the missing translations, run: flutter gen-l10n" >&2
  exit 2
fi

exit 0
