# AI-Agnostic Submodules Rule

**RULE:** Child repositories (moovie, backend) MUST remain AI-agnostic. All AI-specific configuration, documentation, and integration belongs in the MoovieAi meta-repo only.

## Why

- **Clean separation:** Child repos focus on code, not tooling
- **Portability:** Submodules work with or without Claude Code
- **Single source of truth:** AI config lives in one place (meta-repo)
- **Team flexibility:** Developers can use any editor/workflow on submodules
- **Maintainability:** No duplicate AI setup across repos

## What's Forbidden in Submodules

### ❌ Never Add to moovie/ or backend/

```
CLAUDE.md           # No AI-specific guidance in child repos
GEMINI.md           # No LLM-specific config
.claude/            # No Claude Code settings
.copilot/           # No Copilot config
.cursorrules        # No Cursor rules
AI_SETUP.md         # No AI setup docs
```

### ❌ Never Reference in Documentation

```markdown
# In child repo README or docs:

"Use Claude Code to..."            # Wrong
"AI-assisted development..."       # Wrong
"Setting up Claude locally..."     # Wrong
"See CLAUDE.md for AI config"      # Wrong
```

### ❌ Never Add Co-authors

```bash
git commit -m "feat: auth flow

Co-Authored-By: Claude <claude@anthropic.com>"  # WRONG
```

Reason: Claude is a tool, not a contributor. Single human author always.
See [NO_COAUTHORS.md](NO_COAUTHORS.md).

## What Belongs in MoovieAi Meta-Repo

**All AI integration lives here:**
- `.claude/settings.json` — Claude Code config
- `CLAUDE.md` — AI guidance for this ecosystem
- `plugins/` — MCP servers
- `skills/` — AI workflows
- `agents/` — Specialized Claude agents
- Setup/onboarding docs for AI tools

## Checking Compliance

Before merging a PR in submodules, verify:
```bash
# Should return nothing
grep -r "claude\|Claude\|CLAUDE" moovie/
grep -r "claude\|Claude\|CLAUDE" backend/

# Should return nothing
ls -la moovie/.claude/
ls -la backend/.claude/
ls -la moovie/CLAUDE.md
ls -la backend/CLAUDE.md
```

## When a Submodule Needs AI Documentation

Example: "How do I run Moovie in Claude Code?"

**❌ Add to moovie/README.md:**
```markdown
## Claude Code Setup
(instructions here)
```

**✅ Add to MoovieAi CLAUDE.md instead:**
```markdown
### Moovie (Flutter Frontend)
...development guidance for Moovie...
```

Point child repo docs to meta-repo:
```markdown
# Moovie

For AI-assisted development guidance, see the parent repo: [MoovieAi CLAUDE.md](../../CLAUDE.md)
```

## Enforcement

- **PR reviews:** Catch CLAUDE.md, .claude/, Claude references in submodule PRs
- **CI/CD:** Optional: Lint rule to block CLAUDE.md in submodules
- **Team:** Explain this rule during onboarding

## Exception: Integration Tests

If a submodule integration test needs MCP/Claude context (rare):
- Create a test-specific `.claude/` directory
- Document why (comment in test)
- Keep it minimal

Example:
```bash
moovie/tests/ai-integration/.claude/settings.json  # Test-only config
```

Not production code — test setup only.

## No Exceptions

- "Just a quick CLAUDE.md" → No, belongs in meta-repo
- "We'll move it later" → Add it correctly now
- "Everyone uses Claude anyway" → Doesn't matter, keep repos clean
- "It's AI-generated code" → Code is code, doesn't need AI markers

**Submodules stay agnostic. Always.**
