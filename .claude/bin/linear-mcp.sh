#!/usr/bin/env bash
# Launches linear-mcp with LINEAR_ACCESS_TOKEN sourced from the gitignored
# .claude/settings.local.json. Avoids relying on ${VAR} expansion inside
# .mcp.json's env block, which is not consistently honored by Claude Code.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SETTINGS_FILE="$REPO_ROOT/.claude/settings.local.json"
SERVER_ENTRY="$REPO_ROOT/node_modules/linear-mcp/build/index.js"

if [[ ! -f "$SETTINGS_FILE" ]]; then
  echo "linear-mcp: $SETTINGS_FILE not found. Run Skill('setting-up-linear-mcp') to configure the token." >&2
  exit 1
fi

if [[ ! -f "$SERVER_ENTRY" ]]; then
  echo "linear-mcp: $SERVER_ENTRY not found. Run 'npm install' at the repo root." >&2
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "linear-mcp: 'jq' is required to read the token from $SETTINGS_FILE." >&2
  exit 1
fi

TOKEN="$(jq -r '.env.LINEAR_ACCESS_TOKEN // empty' "$SETTINGS_FILE")"

if [[ -z "$TOKEN" ]]; then
  echo "linear-mcp: .env.LINEAR_ACCESS_TOKEN missing from $SETTINGS_FILE. Run Skill('setting-up-linear-mcp')." >&2
  exit 1
fi

export LINEAR_ACCESS_TOKEN="$TOKEN"
exec node "$SERVER_ENTRY"
