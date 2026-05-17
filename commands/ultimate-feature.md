---
description: Build a feature end-to-end autonomously — spec, plan, implementation with multi-pass review loops on each phase's PR.
argument-hint: "<feature request as plain text>"
---

# /ultimate-feature

Dispatches the `ultimate-developer` agent with the user's feature request.

The agent will:
1. Brainstorm with you (kickoff — the only user touchpoint)
2. Ask for target branch, scope, and slug
3. Write spec → open PR → review loop → merge
4. Plan with research → open PR → review loop → merge
5. Implement → open PR → review loop → merge
6. Bump submodule refs if cross-repo

After kickoff, the agent makes all decisions autonomously until merge or escalation. See `agents/ultimate-developer.md` for the full contract.

Invoke `Task(ultimate-developer, prompt="<user's request>")`.
