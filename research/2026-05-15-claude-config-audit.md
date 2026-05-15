---
date: 2026-05-15
author: Claude Opus 4.7
status: approved
related:
  - 2026-05-14-api-versioning
tags: [claude-code, mcp, plugins, skills, config, devtools, security]
decisions:
  - Adopt Option 2 (all 5 phases)
  - Phase 2 skill layout: Layout A (.claude/skills/)
  - Linear token rotation deferred (risk accepted by maintainer 2026-05-15)
---

# Claude Code Configuration Audit & Reset Plan

## Executive Summary

This audit reviews the `.claude/`, `skills/`, `plugins/`, `rules/`, and `agents/` configuration of the MoovieAi meta-repo against three failure reports from the maintainer: (1) skills are not loading, (2) rules are being ignored, (3) plugin status is unverified. Root cause is a layered configuration mismatch: skills are placed in a non-standard directory shape, MCP servers are declared in two competing files with divergent relative paths, rules exist only as Markdown with one of four enforced by a hook, and no bootstrap script exists to make the repo reproducible after a fresh clone. **Recommendation:** Consolidate to a single MCP config at repo root, restructure `skills/` to match Claude Code's expected plugin-marketplace layout, expand hook coverage so each rule has an enforcement mechanism, and ship a `bootstrap.sh` that installs all dependencies (root `npm install`, plugin build, submodule init, hook permissions, settings.local.json template) in one command.

## Problem Statement

The MoovieAi meta-repo aims to be a portable "AI-assisted development hub" that any contributor can clone and use immediately. Today, after a fresh clone, the following fail or are unverifiable without manual debugging:

1. **Skills do not surface** in Claude Code's skill picker despite `extraKnownMarketplaces.local-skills` declaration in `.claude/settings.json` [Source: .claude/settings.json, lines 50-57].
2. **Three of four rule files are unenforced** — only `LOCAL_CLAUDE_CONFIG.md` is verified by `validate-config.sh`; `AI_AGNOSTIC_SUBMODULES`, `NO_COAUTHORS`, and `PYTHON_ENVS` rely on Claude reading CLAUDE.md and choosing to comply [Source: .claude/validate-config.sh, lines 11-22].
3. **MCP server config is duplicated** across `.claude/settings.json` and `.claude/.mcp.json` with conflicting relative paths (`../plugins/...` vs `./plugins/...`) [Source: .claude/settings.json line 5; .claude/.mcp.json line 5].
4. **No setup script** exists; a fresh clone produces a non-functional environment (root `package.json` missing from git, plugin needs `npm install` + build, no hook permission setup) [Source: git status output, "?? package.json"].
5. **Linear API token committed in plain text** in `.claude/settings.local.json` line 3 — file gitignored, but token now lives in conversation history of any session that reads it [Source: .claude/settings.local.json, line 3].

Scope: All Claude Code integration files in the repo root and `.claude/`. Out of scope: child submodule contents (per `AI_AGNOSTIC_SUBMODULES` rule).

Why now: The maintainer is unable to validate that ecosystem rules ship correctly to new clones, blocking onboarding of other contributors.

## Current State Inventory

### `.claude/` directory contents
| File | Purpose | Status |
|------|---------|--------|
| `settings.json` | Project-level Claude Code config | Committed, modified |
| `settings.local.json` | Personal overrides + secrets | Gitignored, contains Linear token |
| `.mcp.json` | MCP server registration (non-standard location) | Committed |
| `statusline.sh` | Context % statusline | Executable, working |
| `validate-config.sh` | UserPromptSubmit hook — portable path check | Executable, enforces 1 rule |
| `verify-docs.sh` | Manual pre-PR doc check | Executable, invoked via skill |

[Source: `ls -la .claude/`]

### Skills declared
| Path | Format | Loaded? |
|------|--------|---------|
| `skills/verify-docs-before-pr.md` | Flat `.md` with frontmatter | No — wrong location for flat-file skills |
| `skills/setting-up-linear-mcp/SKILL.md` | Subdir with SKILL.md | No — marketplace structure missing |
| `skills/moovie-research-format/SKILL.md` | Subdir with SKILL.md | No — marketplace structure missing |

[Source: `ls -la skills/`]

### Plugins declared
| Plugin | Path | Built? | Registered |
|--------|------|--------|-----------|
| `repo-management` | `plugins/repo-management/dist/index.js` | Yes (committed) | Twice — settings.json AND .mcp.json |

[Source: `ls plugins/repo-management/dist/`; `.claude/settings.json` lines 3-6; `.claude/.mcp.json` lines 3-6]

### Rules declared vs enforced
| Rule | File | Enforcement |
|------|------|-------------|
| `LOCAL_CLAUDE_CONFIG` | `rules/LOCAL_CLAUDE_CONFIG.md` | `validate-config.sh` via UserPromptSubmit hook |
| `AI_AGNOSTIC_SUBMODULES` | `rules/AI_AGNOSTIC_SUBMODULES.md` | None — relies on CLAUDE.md guidance |
| `NO_COAUTHORS` | `rules/NO_COAUTHORS.md` | None — relies on CLAUDE.md guidance |
| `PYTHON_ENVS` | `rules/PYTHON_ENVS.md` | None — relies on CLAUDE.md guidance |

[Source: `.claude/settings.json` lines 62-71; manual scan of `rules/` directory]

### Hooks declared
| Hook | Event | Command |
|------|-------|---------|
| `validate-config.sh` | `UserPromptSubmit` | Portable-path check on settings files |

[Source: `.claude/settings.json` lines 62-71]

## Issues Identified

### Issue 1 — Skills not surfacing in skill picker
**Symptom:** `Skill("moovie-research-format")` or `/verify-docs-before-pr` does not resolve to available skills.

**Root cause:** `extraKnownMarketplaces.local-skills` in `.claude/settings.json` points to `./skills`, which is a Claude Code **plugin marketplace** discovery mechanism, not a project-level skill loader. A plugin marketplace requires a `marketplace.json` at the root of the declared path that enumerates plugins, each of which then ships its own `skills/` subdirectory. The current `skills/` directory has no `marketplace.json` and is not structured as a plugin marketplace [Source: claude-code-plugin-marketplace conventions; absence of `skills/marketplace.json`].

**Impact:** All three custom skills (`verify-docs-before-pr`, `setting-up-linear-mcp`, `moovie-research-format`) are invisible to Claude Code, even though CLAUDE.md instructs Claude to invoke them.

### Issue 2 — Duplicate, conflicting MCP server registration
**Symptom:** Unclear which `repo-management` config Claude Code uses; `linear` MCP server is only in one of two files.

**Root cause:**
- `.claude/settings.json` declares `mcpServers.repo-management` with args `../plugins/repo-management/dist/index.js` (relative to `.claude/`, not repo root) [Source: .claude/settings.json line 5].
- `.claude/.mcp.json` declares `mcpServers.repo-management` with args `./plugins/repo-management/dist/index.js` (relative to repo root) [Source: .claude/.mcp.json line 5].
- Claude Code's documented MCP discovery is `.mcp.json` at **repo root**, not under `.claude/`.
- `linear` MCP exists only in `.claude/settings.json`, missing from `.claude/.mcp.json`.

**Impact:** Two competing configs. Path resolution is ambiguous. `repo-management` may launch from the wrong working directory. Linear MCP may not auto-load.

### Issue 3 — Rules without enforcement mechanism
**Symptom:** Rules referenced in CLAUDE.md are routinely ignored across sessions.

**Root cause:** Three of four rule files have no hook enforcement:
- `NO_COAUTHORS` — no pre-commit/commit-msg hook to strip `Co-Authored-By` trailers
- `AI_AGNOSTIC_SUBMODULES` — no hook checks submodules for `.claude/` or `CLAUDE.md` files
- `PYTHON_ENVS` — no hook intercepts global `pip install` commands

Claude reads CLAUDE.md and the rule files as context, but compliance depends entirely on the model remembering and following them — a soft enforcement that drifts across long sessions or context compaction.

**Impact:** Rules ship as documentation, not as gates. Violations slip through unless Claude proactively re-checks.

### Issue 4 — No reproducibility bootstrap
**Symptom:** A fresh `git clone --recurse-submodules` does not produce a working Claude Code environment.

**Root cause:** Missing setup automation. Required manual steps after clone:
1. `npm install` at repo root (linear-mcp dep)
2. `cd plugins/repo-management && npm install && npm run build`
3. `chmod +x .claude/*.sh` (if extraction stripped exec bits)
4. Generate or paste Linear token into `.claude/settings.local.json`
5. Verify submodules initialized (`git submodule status`)

Root `package.json` is **untracked** (`?? package.json` per `git status`) — a fresh clone will not even have the `linear-mcp` dependency declaration [Source: `git status -s`].

**Impact:** Onboarding requires tribal knowledge. The repo's stated goal ("portable AI dev hub") fails on first contact.

### Issue 5 — Secret leakage path
**Symptom:** Linear API token in `.claude/settings.local.json` is plain text.

**Root cause:** File is gitignored [Source: `.gitignore` line 51, "Local overrides"], so the token never reaches the remote. However, any conversation that reads this file ingests the token into chat history, transcripts, or telemetry. Current session has already done so.

**Impact:** Token exposure to external systems (LLM provider logs, screenshare, copy-paste). Token must be rotated.

### Issue 6 — Hook coverage gap
**Symptom:** Only `UserPromptSubmit` is hooked; no `SessionStart`, no `PreToolUse` for git commits, no `PostToolUse` for file edits.

**Root cause:** `.claude/settings.json` declares one hook entry [Source: .claude/settings.json lines 62-71]. CLAUDE.md says "Load Rules, Plugins, and Skills (Every Session)" — but no `SessionStart` hook emits the rule list or reminders. No `PreToolUse` matcher catches `git commit` to strip coauthors. No `PostToolUse` catches `pip install` outside a venv.

**Impact:** "Every session" guidance in CLAUDE.md is aspirational, not enforced.

### Issue 7 — Stale documentation in subdirectory READMEs
**Symptom:** `skills/README.md` and `agents/README.md` list example files that don't exist.

**Root cause:** READMEs were templated before implementation. Reference `feature-scaffold.md`, `ci-deployment.md`, `frontend-specialist.md`, etc. that were never created [Source: `skills/README.md`, `agents/README.md`].

**Impact:** Misleading for new contributors. Suggests features that are absent.

## Options Evaluated

### Option 1: Minimal patch — fix paths only
**Description:** Keep current structure. Fix MCP path bug, deduplicate config, leave skills/rules untouched.

**Pros:**
- Smallest diff
- Lowest risk of breakage [Analysis: only file path changes]

**Cons:**
- Skills still won't load (root cause unaddressed)
- Rules still unenforced
- No reproducibility for clones [Source: this audit, Issue 4]

**Verdict:** Rejected — does not solve stated problem (skills not loading, rules ignored).

### Option 2: Full restructure with bootstrap script (recommended)
**Description:** Restructure `skills/` as a proper plugin marketplace (or move to `.claude/skills/` flat layout), consolidate MCP config to single repo-root `.mcp.json`, add per-rule enforcement hooks, ship `bootstrap.sh` for clones.

**Pros:**
- Solves all five issues identified [Source: this audit]
- Makes repo's stated goal (portable AI hub) actually work
- Setup script enables team scaling — documented in README

**Cons:**
- Larger diff (~6–8 files touched, 1 new script)
- Risk of breaking maintainer's current session if hooks misfire [Analysis: mitigated by staged rollout]

**Verdict:** **Recommended.** Aligns with stated repo purpose.

### Option 3: Use upstream `superpowers` plugin marketplace instead
**Description:** Delete custom `skills/` directory. Adopt the public `superpowers` skill pack and let maintainer install via standard marketplace command. Keep only the truly Moovie-specific rules locally.

**Pros:**
- Zero maintenance burden for skill plumbing
- Skills already battle-tested by Anthropic [Source: superpowers skill catalog visible in this session]

**Cons:**
- Loses ecosystem-specific skills (`moovie-research-format`, `setting-up-linear-mcp` are Moovie-specific) [Source: skill purpose statements]
- Doesn't solve MCP duplication or hook gaps

**Verdict:** Rejected as primary path. Useful complement — superpowers can live alongside custom Moovie skills.

## Recommended Approach

**Adopt Option 2 with a five-phase implementation.** Phases are ordered so each is verifiable in isolation; later phases assume earlier phases land cleanly.

### Phase 1 — MCP consolidation (low risk)
1. Move `.claude/.mcp.json` to repo root as `.mcp.json`.
2. Add `linear` server entry to root `.mcp.json`.
3. Remove `mcpServers` block from `.claude/settings.json`.
4. Verify paths: all relative to repo root (`./plugins/...`).
5. Reload Claude Code and confirm both servers respond.

### Phase 2 — Skill restructure
Pick one of two layouts:

**Layout A — Project-level skills (simplest):**
- Move `skills/<name>/SKILL.md` and `skills/<name>.md` into `.claude/skills/<name>/SKILL.md` (single SKILL.md per skill with frontmatter).
- Delete `extraKnownMarketplaces.local-skills` from settings.
- Claude Code auto-loads `.claude/skills/*/SKILL.md` per project [Source: Claude Code skill discovery convention].

**Layout B — Plugin marketplace (more work, supports versioning):**
- Add `skills/marketplace.json` declaring each skill as a plugin.
- Each subdirectory needs `plugin.json` manifest.
- Keep `extraKnownMarketplaces.local-skills` declaration.

**Recommendation: Layout A** — simpler, fewer files, no marketplace overhead. Versioning is a non-need for in-repo skills.

### Phase 3 — Rule enforcement hooks
Add hooks to `.claude/settings.json`:

```json
"hooks": {
  "UserPromptSubmit": [
    { "matcher": ".*", "hooks": [{ "type": "command", "command": "./.claude/validate-config.sh" }] }
  ],
  "PreToolUse": [
    {
      "matcher": "Bash",
      "hooks": [{ "type": "command", "command": "./.claude/check-coauthor.sh" }]
    },
    {
      "matcher": "Bash",
      "hooks": [{ "type": "command", "command": "./.claude/check-python-env.sh" }]
    }
  ],
  "SessionStart": [
    { "matcher": ".*", "hooks": [{ "type": "command", "command": "./.claude/session-start.sh" }] }
  ]
}
```

New scripts needed:
- `check-coauthor.sh` — Scan `git commit -m` invocations for `Co-Authored-By`; block if present.
- `check-python-env.sh` — Scan `pip install` invocations; block if `VIRTUAL_ENV` is unset.
- `session-start.sh` — Emit one-line summary: rule list + skill list + MCP status, so each session opens with explicit context.

### Phase 4 — Bootstrap script
Create `bootstrap.sh` at repo root:

```bash
#!/usr/bin/env bash
set -euo pipefail

# 1. Initialize submodules
git submodule update --init --recursive

# 2. Root deps (linear-mcp)
npm install

# 3. Plugin deps + build
( cd plugins/repo-management && npm install && npm run build )

# 4. Make hooks executable
chmod +x .claude/*.sh

# 5. Template settings.local.json if missing
if [ ! -f .claude/settings.local.json ]; then
  cp .claude/settings.local.template.json .claude/settings.local.json
  echo "Edit .claude/settings.local.json to add your Linear token."
fi

echo "Bootstrap complete. Open Claude Code in this directory."
```

Companion file `.claude/settings.local.template.json`:
```json
{
  "env": { "LINEAR_ACCESS_TOKEN": "" }
}
```

Commit `package.json` and `package-lock.json` to the repo (currently untracked).

### Phase 5 — Doc cleanup
- Update `skills/README.md` to list only real skills.
- Update `agents/README.md` to either list real agents or mark as placeholder.
- Update root `README.md` to instruct: `./bootstrap.sh` as first step after clone.
- Update `CLAUDE.md` to reflect new skill location and bootstrap step.

## Implementation Plan

| Phase | Files Touched | Verifiable via |
|-------|---------------|----------------|
| 1 — MCP consolidation | `.claude/settings.json`, `.claude/.mcp.json` → `.mcp.json` | Claude Code MCP server status |
| 2 — Skill restructure | `skills/**` → `.claude/skills/**`, `.claude/settings.json` | `/skill` picker lists 3 skills |
| 3 — Rule hooks | 3 new `.claude/*.sh`, `.claude/settings.json` | Hook fires on `git commit` with coauthor → blocks |
| 4 — Bootstrap script | new `bootstrap.sh`, new `.claude/settings.local.template.json`, track `package.json`, `package-lock.json` | Fresh clone + `./bootstrap.sh` → functional Claude Code |
| 5 — Doc cleanup | `README.md`, `CLAUDE.md`, `skills/README.md`, `agents/README.md` | Manual read-through |

Estimated effort: 2–3 hours focused work. No code changes to submodules.

### Success criteria
- [ ] Fresh clone followed by `./bootstrap.sh` produces a Claude Code session where:
  - All 3 custom skills appear in skill picker.
  - `repo-management` and `linear` MCP servers both connect.
  - `git commit -m "x\n\nCo-Authored-By: y"` is blocked by hook.
  - `pip install` outside a venv is blocked by hook.
  - `SessionStart` echoes rule + skill + MCP summary.
- [ ] `validate-config.sh` continues to pass on all settings files.
- [ ] Linear token is never committed; template uses empty string.

### Known risks
- **Hook chaining cost.** Multiple `PreToolUse` hooks add latency per Bash call. Mitigate by keeping each script <50ms; use early exits when matcher doesn't apply.
- **`SessionStart` noise.** If output is verbose, every session opens with a wall of text. Keep to ≤3 lines.
- **Submodule rule conflict.** `AI_AGNOSTIC_SUBMODULES` says no `.claude/` in submodules. Bootstrap script must not touch submodule directories.

## Alternative Approaches (not chosen)

- **Option 1 (minimal patch):** Rejected because it leaves skills broken — the maintainer's primary complaint.
- **Option 3 (superpowers-only):** Rejected as sole strategy because ecosystem-specific skills must live in-repo. Acceptable as a complement: install `superpowers` on top of the custom Moovie skill set.
- **Globally installed Claude config:** Rejected — violates `LOCAL_CLAUDE_CONFIG.md` rule [Source: rules/LOCAL_CLAUDE_CONFIG.md].

## Next Steps / Action Items

- [ ] **Rotate Linear API token.** Owner: maintainer. By: immediately. Token in `settings.local.json` is in session history.
- [ ] **Approve plan.** Owner: maintainer. By: before Phase 1 starts.
- [ ] **Execute Phase 1 (MCP consolidation).** Owner: Claude. By: same session. Dependency: approval.
- [ ] **Execute Phase 2 (skill restructure).** Owner: Claude. By: same session.
- [ ] **Execute Phase 3 (rule hooks).** Owner: Claude. By: same session.
- [ ] **Execute Phase 4 (bootstrap script).** Owner: Claude. By: same session.
- [ ] **Execute Phase 5 (doc cleanup).** Owner: Claude. By: same session.
- [ ] **Verify on fresh clone.** Owner: maintainer. By: after merge. Dependency: all phases complete.
- [ ] **Run `/ultrareview` against this branch.** Owner: maintainer. By: post-implementation. Use this doc as the briefing.

### Decision gate
**Resolved 2026-05-15** by maintainer:
- Option 2 approved, all 5 phases authorized.
- Phase 2 skill layout: **Layout A** (`.claude/skills/<name>/SKILL.md`). Reasoning: single-repo distribution scope, sibling Mobyle repos are submodules under `AI_AGNOSTIC_SUBMODULES` rule — no external skill consumers.
- Linear token rotation: **deferred, risk accepted.** Token remains in session history. Re-flag if shared in future external context.

Next gate: maintainer runs `/ultrareview` against the branch hosting this doc. This audit serves as the briefing. Implementation begins after `/ultrareview` results are reviewed.
