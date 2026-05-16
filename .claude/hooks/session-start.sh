#!/bin/bash
# .claude/hooks/session-start.sh
# Emits a brief summary at session start: rules, skills, MCP servers.
# Register as SessionStart hook in .claude/settings.json.
# Keep output short — every session opens with this.

set -eu

# Locate repo root so the hook works regardless of the session's cwd.
repo_root=$(git rev-parse --show-toplevel 2>/dev/null || pwd)

# Defensive: bail silently if this looks like the wrong repo.
[ -f "$repo_root/.mcp.json" ] || exit 0
[ -f "$repo_root/CLAUDE.md" ] || exit 0

shopt -s nullglob
rule_files=("$repo_root"/rules/*.md)
skill_dirs=("$repo_root"/.claude/skills/*/)
shopt -u nullglob

# Filter out README.md (directory readme, not a rule). Iterate without :-
# default expansion, which would otherwise inject an empty entry on an empty
# array and produce off-by-one counts + a leading bare comma in output.
filtered_rules=()
for f in "${rule_files[@]}"; do
  name=$(basename "$f" .md)
  [ "$name" = "README" ] && continue
  filtered_rules+=("$name")
done

rule_count=${#filtered_rules[@]}
skill_count=${#skill_dirs[@]}

mcp_count=0
if command -v jq >/dev/null 2>&1; then
  mcp_count=$(jq -r '.mcpServers | length' "$repo_root/.mcp.json" 2>/dev/null || echo 0)
fi

rule_names=""
if [ "$rule_count" -gt 0 ]; then
  rule_names=$(IFS=, ; echo "${filtered_rules[*]}" | sed 's/,/, /g')
fi

skill_names=""
for d in "${skill_dirs[@]}"; do
  name=$(basename "$d")
  skill_names="${skill_names:+$skill_names, }$name"
done

echo "MoovieAi session — ${rule_count} rules, ${skill_count} skills, ${mcp_count} MCP servers loaded."
[ -n "$rule_names" ] && echo "  Rules: $rule_names"
[ -n "$skill_names" ] && echo "  Skills: $skill_names"

exit 0
