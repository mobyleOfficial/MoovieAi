---
name: setting-up-linear-mcp
description: Use when configuring Linear MCP for Claude Code, need to connect workspace-specific project, or want to store API token securely at project level
---

# Setting Up Linear MCP

Configure Linear MCP in Claude Code at the project level with workspace + project scoping and secure token storage.

## Overview

Linear MCP enables Claude Code to read/manage Linear issues in your workspace. This skill guides secure project-level configuration with workspace scoping — each project can have its own workspace + token without global installation conflicts.

## When to Use

- First-time Linear MCP setup in a project
- Adding Linear integration to existing Claude Code project
- Multiple workspaces, need project-specific defaults

## Quick Steps

**1. Generate API Token**

Navigate to: `https://linear.app/<workspace-name>/settings/api`

Click **Create new** → Copy token (looks like `lin_api_xxx...`)

**2. Update `.claude/settings.json`**

**If file exists:**
Open `.claude/settings.json` and add `linear` entry to `mcpServers` object + add env vars:
```json
{
  "mcpServers": {
    "existing-server": { ... },
    "linear": {
      "command": "npx",
      "args": ["@linear/mcp"],
      "env": {
        "LINEAR_WORKSPACE_ID": "workspace-slug",
        "LINEAR_PROJECT_ID": "PROJECT-KEY",
        "LINEAR_API_TOKEN": "${LINEAR_API_TOKEN}"
      }
    }
  },
  "env": {
    "LINEAR_WORKSPACE_ID": "workspace-slug",
    "LINEAR_PROJECT_ID": "PROJECT-KEY"
  },
  "permissions": { ... }
}
```

**If file doesn't exist:**
Create `.claude/settings.json`:
```json
{
  "mcpServers": {
    "linear": {
      "command": "npx",
      "args": ["@linear/mcp"],
      "env": {
        "LINEAR_WORKSPACE_ID": "workspace-slug",
        "LINEAR_PROJECT_ID": "PROJECT-KEY",
        "LINEAR_API_TOKEN": "${LINEAR_API_TOKEN}"
      }
    }
  },
  "env": {
    "LINEAR_WORKSPACE_ID": "workspace-slug",
    "LINEAR_PROJECT_ID": "PROJECT-KEY"
  }
}
```

Replace placeholders:
- `workspace-slug` — from Linear URL: `linear.app/[workspace-slug]/...`
- `PROJECT-KEY` — team key (MOO, ENG, PROJ, etc)
- `${LINEAR_API_TOKEN}` — token reference (don't hardcode actual value)

**3. Update `.claude/settings.local.json`**

**If file exists:**
Add to `env` object (merge with existing vars):
```json
{
  "env": {
    "EXISTING_VAR": "...",
    "LINEAR_API_TOKEN": "lin_api_xxx..."
  }
}
```

**If file doesn't exist:**
Create `.claude/settings.local.json`:
```json
{
  "env": {
    "LINEAR_API_TOKEN": "lin_api_xxx..."
  }
}
```

Paste your actual token here. Never commit this file.

**4. Verify `.gitignore`**

Ensure `.gitignore` contains:
```
.claude/settings.local.json
```

If missing, add it.

**5. Restart Claude Code**

Settings reload on session start. Force restart if connecting immediately.

## Verify Connection

Ask Claude Code: "List my Linear issues" — should see issues from `LINEAR_PROJECT_ID` project in `LINEAR_WORKSPACE_ID` workspace.

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Token committed to git | Revoke at https://linear.app/[workspace]/settings/api, regenerate, move to .local.json |
| Wrong workspace URL format | Use slug from URL path: `linear.app/mobyle/...` → `mobyle` |
| Forgot ${LINEAR_API_TOKEN} reference | Token env var won't load. Use `"${LINEAR_API_TOKEN}"` in mcpServers, actual value in .local.json |
| Settings not reloading | Restart Claude Code completely (not just new tab) |
| Multiple workspaces, can't switch | Each project gets its own .local.json + workspace scoping. No global override needed |

## Security Notes

- **API tokens are read-write credentials** — treat like passwords
- Revoke immediately if exposed (leaked in git, screenshot, chat)
- `.local.json` is gitignored — never committed
- Different project = different token/workspace possible
- Team members each create their own token (not shared)

## Next: Use Linear MCP

Once connected, Claude Code has Linear tools available. Ask about:
- Listing issues by status/assignee
- Creating/updating issues
- Finding specific Linear metadata

See Linear MCP docs for full tool reference.
