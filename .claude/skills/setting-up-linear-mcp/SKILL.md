---
name: setting-up-linear-mcp
description: Use when configuring Linear MCP for Claude Code, need to connect a workspace, or want to store the API token securely at project level
---

# Setting Up Linear MCP

Configure the Linear MCP server in this project with secure token storage.

## Overview

Linear MCP lets Claude Code read and manage Linear issues. This skill walks through project-level setup: server registration in `.mcp.json` at repo root, token storage in `.claude/settings.local.json` (gitignored).

## When to Use

- First-time Linear MCP setup in a project
- Adding Linear integration to a clone that does not yet have a token
- Rotating an exposed token

## Quick Steps

**1. Generate API Token**

Navigate to: `https://linear.app/<workspace-name>/settings/api`

Click **Create new** → copy token (looks like `lin_api_xxx...`).

**2. Verify `.mcp.json` at repo root**

The repo ships a `.mcp.json` at the root with the Linear server already declared:

```json
{
  "mcpServers": {
    "linear": {
      "command": "./.claude/bin/linear-mcp.sh"
    }
  }
}
```

The Linear server is launched through a small wrapper script at [`.claude/bin/linear-mcp.sh`](../../bin/linear-mcp.sh) that:

1. Reads `LINEAR_ACCESS_TOKEN` from the gitignored `.claude/settings.local.json` via `jq`.
2. Exports it into the child process environment.
3. Execs `node ./node_modules/linear-mcp/build/index.js`.

This avoids relying on `${VAR}` expansion inside `.mcp.json`'s `env` block, which Claude Code does not consistently honor — the child process would otherwise receive the literal string `"${LINEAR_ACCESS_TOKEN}"` and the server would silently authenticate with garbage, producing "Authentication required" on every call.

Requirements: `jq` (installed by `bootstrap.sh`'s `require jq` check) and the `linear-mcp` package (installed by `npm install` / `bootstrap.sh`). `linear-mcp` (dvcrn) ships no `bin` entry, which is why we exec `node` against `build/index.js` rather than `npx linear-mcp`.

No edit to `.mcp.json` needed on a clone. Token lives only in `.claude/settings.local.json` (next step).

**3. Set `LINEAR_ACCESS_TOKEN` in `.claude/settings.local.json`**

**If the file exists:** add the token to the `env` block (merge with existing values):

```json
{
  "env": {
    "LINEAR_ACCESS_TOKEN": "lin_api_xxx..."
  }
}
```

**If the file does not exist:** create it:

```json
{
  "env": {
    "LINEAR_ACCESS_TOKEN": "lin_api_xxx..."
  }
}
```

Paste the real token here. Never commit this file.

**4. Verify `.gitignore`**

`.gitignore` must list `.claude/settings.local.json`. If missing, add the line — otherwise the token will reach the remote on next commit.

**5. Restart Claude Code**

MCP servers register on session start. Force-restart if connecting immediately.

## Verify Connection

Ask Claude Code: "List my Linear issues" — Claude should surface issues from your workspace via the Linear MCP server.

## Default Project

This repo defaults to the `MOO` project in the `mobyle` workspace. The `linear-mcp` server has no project filter — `MOO` is convention only, not enforcement. When referencing issues in PRs or commits, use the `MOO-123` prefix; the server will return any issue the token has access to regardless of project.

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Token committed to git | Revoke at `https://linear.app/<workspace>/settings/api`, regenerate, store in `.claude/settings.local.json` only |
| Wrong package name | The package is `linear-mcp` (dvcrn), not `@linear/mcp`. Latter does not exist on npm |
| Wrong env var name | `linear-mcp` reads `LINEAR_ACCESS_TOKEN`, not `LINEAR_API_TOKEN`. Older docs may say the wrong name |
| Wrapper script not executable | `chmod +x .claude/bin/linear-mcp.sh` (or re-run `./bootstrap.sh`). Manifests as Claude Code reporting the MCP server failed to start |
| `jq` missing | The wrapper uses `jq` to read the token from `.claude/settings.local.json`. Install via your package manager (`brew install jq`, `apt install jq`) |
| Token missing from settings | Wrapper exits with `linear-mcp: .env.LINEAR_ACCESS_TOKEN missing from .claude/settings.local.json`. Add it under the `env` block |
| Settings not reloading | Restart Claude Code completely (not just a new tab) |

## Security Notes

- **API tokens are read-write credentials** — treat like passwords.
- Revoke immediately if exposed (committed to git, screenshot, chat transcript).
- `.claude/settings.local.json` is gitignored — never commit it.
- Team members each create their own token. Tokens are not shared.

## Next: Use Linear MCP

Once connected, Claude Code has Linear tools available. Ask about:
- Listing issues by status / assignee / label
- Creating or updating issues
- Looking up metadata for a specific issue

See `linear-mcp` (dvcrn) docs for the full tool reference.
