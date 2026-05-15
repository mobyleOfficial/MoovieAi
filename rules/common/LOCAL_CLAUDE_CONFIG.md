# Local Claude Code Configuration Rule

**RULE:** All Claude Code configuration in `.claude/` MUST use portable, relative paths. No global (`~/`) or absolute user paths allowed.

## Why

- **Portability:** Any team member cloning the repo gets identical setup
- **Reproducibility:** No hardcoded user paths breaking on different machines
- **Version control:** Team can review and maintain config together
- **Consistency:** `.gitignore` handles secrets; `.claude/` stays portable

## What's Forbidden in `.claude/`

### ❌ Never Use Global Paths

```json
{
  "statusLine": {
    "command": "~/.claude/statusline.sh"  // ❌ Global path
  },
  "hooks": {
    "PreCompact": [{
      "hooks": [{
        "command": "/Users/edyuto/scripts/compact.sh"  // ❌ Absolute user path
      }]
    }]
  }
}
```

### ✅ Always Use Relative Paths

```json
{
  "statusLine": {
    "command": "./.claude/statusline.sh"  // ✅ Relative to project root
  },
  "mcpServers": {
    "local": {
      "command": "node",
      "args": ["../plugins/my-plugin/dist/index.js"]  // ✅ Relative to project root
    }
  }
}
```

## Enforcement

- Pre-commit hook scans `.claude/*.json` for forbidden patterns
- Blocks commits containing `~/` or `/Users/` in `.claude/` files
- Hook error message shows exact violations and locations
- Secrets go in `.claude/settings.local.json` (gitignored)

## Exceptions

None. All configs must be portable.

---

See also: [AI_AGNOSTIC_SUBMODULES.md](AI_AGNOSTIC_SUBMODULES.md), [NO_COAUTHORS.md](NO_COAUTHORS.md)
