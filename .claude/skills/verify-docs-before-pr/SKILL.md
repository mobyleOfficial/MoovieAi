---
name: verify-docs-before-pr
description: Verify README.md and CLAUDE.md are updated when opening a PR
---

Check if documentation is in sync with code changes before creating a pull request.

Detects if critical files changed (config, plugins, skills, rules, dependencies) without corresponding README.md or CLAUDE.md updates.

Run this before `/open-pull-request` to catch out-of-sync docs.

## Usage

```
/verify-docs-before-pr
```

## What It Checks

- `.claude/` config changes
- `plugins/` modifications
- `skills/` additions
- `agents/` changes
- `rules/` updates
- `moovie/` or `backend/` structure changes
- Dependency updates (package.json, gradle, pubspec.yaml, Gemfile)

## Output

✓ **Pass** — Documentation is in sync. Safe to open PR.

⚠️ **Fail** — Documentation out of sync. Update README.md and/or CLAUDE.md before creating PR.

---

## Implementation

This skill wraps `.claude/verify-docs.sh`, which:
1. Compares current branch against main
2. Detects critical file changes
3. Verifies docs were updated
4. Reports violations with file list
