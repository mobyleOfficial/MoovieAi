# Skills

Project-level Claude Code skills for the MoovieAi ecosystem. Each subdirectory holds a single skill with a `SKILL.md` describing it (frontmatter + body). Claude Code auto-discovers skills here when a session opens in this repo.

## Available Skills

- **`moovie-research-format`** — Standardized format for design docs, architecture decisions, and research documentation.
- **`setting-up-linear-mcp`** — Configure Linear MCP at project level with secure token storage.
- **`verify-docs-before-pr`** — Documentation verification before PR creation.

## Invocation

```text
Skill("skill-name")
```

For example, `Skill("moovie-research-format")` to start formatted research, or `Skill("verify-docs-before-pr")` before opening a PR.

## Scaffolding Workflows

Flutter scaffolding (new feature, datasource, repository, usecase, UI module) lives under [`commands/`](../../commands/) at the repo root and is invoked via slash commands (`/new-usecase`, `/new-datasource`, etc.) — not as skills. See [`agents/implementer-tester.md`](../../agents/implementer-tester.md) for pipeline usage.

## Adding a New Skill

1. Create `.claude/skills/<skill-name>/SKILL.md`.
2. Add frontmatter:
   ```yaml
   ---
   name: <skill-name>
   description: Use when ... (one-line summary)
   ---
   ```
3. Write the skill body (instructions, examples, common mistakes).
4. Claude Code picks it up on next session.
