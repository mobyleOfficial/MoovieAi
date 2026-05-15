#!/bin/bash
# .claude/hooks/session-start.sh
# Emits a brief summary at session start: rules, skills, MCP servers.
# Register as SessionStart hook in .claude/settings.json.
# Keep output short — every session opens with this.

set -e

# Skip if not in MoovieAi repo (defensive)
if [ ! -f .mcp.json ] || [ ! -f CLAUDE.md ]; then
  exit 0
fi

rule_count=$(ls rules/*.md 2>/dev/null | wc -l | tr -d ' ')
skill_count=$(ls -d .claude/skills/*/ 2>/dev/null | wc -l | tr -d ' ')
mcp_count=$(jq -r '.mcpServers | length' .mcp.json 2>/dev/null || echo 0)

echo "MoovieAi session — ${rule_count} rules, ${skill_count} skills, ${mcp_count} MCP servers loaded."
echo "  Rules: $(ls rules/*.md 2>/dev/null | xargs -n1 basename | sed 's/.md//' | paste -sd, -)"
echo "  Skills: $(ls -d .claude/skills/*/ 2>/dev/null | xargs -n1 basename | paste -sd, -)"

exit 0
