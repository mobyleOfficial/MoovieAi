# Skills

Custom Claude workflows and scaffolding skills for automation and repeated patterns in the MoovieAi ecosystem.

## Feature Scaffolding Skills

These skills generate boilerplate code following established patterns in the moovie Flutter app:

- **`/new-usecase`** — Scaffold a new usecase in a feature's domain layer
- **`/new-datasource`** — Scaffold a remote or local datasource (contract + implementation)
- **`/new-repository`** — Scaffold a repository contract (domain) and implementation (data)
- **`/new-ui-module`** — Scaffold a complete UI module (state + bloc + screen)

## Ecosystem Skills

- **`moovie-research-format`** — Standardized format for design docs, architecture decisions, and research documentation
- **`setting-up-linear-mcp`** — Configure Linear MCP at project level with workspace scoping and secure token storage
- **`verify-docs-before-pr`** — Documentation verification before PR creation

## Usage

Invoke skills via `/skill-name` in Claude Code or use the Skill tool:

```dart
await skill('new-usecase');
```

When using scaffolding skills, follow the prompts to specify feature name, component name, and dependencies. The generated code already satisfies architecture rules and patterns.
