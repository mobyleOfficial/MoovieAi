# Agents

Custom Claude agents for specialized tasks in the MoovieAi ecosystem. These form a feature development pipeline.

## Available Agents

- **pm-spec** — Product manager that writes feature specifications for the ecosystem
- **architect-review** — Technical architect that reviews specs for feasibility and ecosystem alignment
- **implementer-tester** — Flutter/Dart implementer that builds features in the moovie submodule with full test coverage
- **code-reviewer** — Code review specialist that validates code quality across moovie and backend submodules
- **validator** — Strict read-only validator that catches issues before merge

## Pipeline Usage

Feature development follows this pipeline:

1. **pm-spec** — Convert feature request → formal spec in `research/specs/`
2. **architect-review** — Review spec for feasibility → approval/rejection in `research/reviews/`
3. **implementer-tester** — Implement approved spec in `moovie/` submodule with tests
4. **code-reviewer** — Review implementation for quality and correctness
5. **validator** — Final validation before merge

Each agent has specific tool allowlists and responsibilities defined in its metadata. All agents understand the MoovieAi ecosystem structure and can work across the moovie and backend submodules.

See [CLAUDE.md](../CLAUDE.md) for ecosystem-wide guidance.
