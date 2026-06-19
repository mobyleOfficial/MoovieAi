# Generic Agents Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Decouple the meta-repo's agents/commands/hooks from the `moovie` app so the same pipeline serves any Flutter submodule.

**Architecture:** Edit markdown agent/command prompts + one shell hook + docs. Tech-bound agents get a `flutter-` prefix. Hardcoded `moovie/` paths and the `mobyleOfficial/MoovieAi` repo slug are replaced with runtime resolution (`.gitmodules` + `gh repo view`). Backend references become optional. "Tests" are grep-based verification commands — no unit-test framework applies.

**Tech Stack:** Markdown agent specs, Bash hooks, `gh` CLI, git.

**Reference:** `docs/superpowers/specs/2026-06-19-generic-agents-design.md`

---

### Task 1: Generalize `pm-spec.md`

**Files:**
- Modify: `agents/pm-spec.md`

- [ ] **Step 1: Replace MoovieAi-ecosystem language**

In `description` (line 3) and body line 10, replace "the MoovieAi ecosystem (moovie frontend + backend)" / "MoovieAi ecosystem" with "the ecosystem". Replace "Identify cross-repo impact (frontend vs backend vs both)" with "Identify cross-repo impact (frontend vs backend vs both, if a backend exists)".

- [ ] **Step 2: Make backend/cross-repo sections optional**

In "Technical Notes" (lines 37-39) and "Cross-Repo Impact" (line 42), reframe backend bullets as conditional. Replace the `Frontend (moovie)` / `Backend (backend)` labels with `Frontend` / `Backend (if present)`. Replace "TMDB integration impact" with "external API integration impact".

- [ ] **Step 3: Neutralize the example**

In the Example Structure block (lines 54-93), replace the movie-search example with a generic one: `# Item Search Feature`, user stories about "items", endpoint `POST /api/items/search`, response `{ results: Item[], ... }`. Replace "proxies TMDB search API" with "proxies the upstream search API". Keep the same structure and section headings.

- [ ] **Step 4: Verify no moovie/TMDB references remain**

Run: `grep -niE "moovie|tmdb" agents/pm-spec.md`
Expected: no output.

- [ ] **Step 5: Commit**

```bash
git add agents/pm-spec.md
git commit -m "refactor(agents): make pm-spec project-agnostic"
```

---

### Task 2: Generalize `architect-review.md`

**Files:**
- Modify: `agents/architect-review.md`

- [ ] **Step 1: Drop hardcoded stack/app naming**

Line 16: replace "Assess compatibility with both frontend (Flutter/Dart) and backend (Kotlin/Ktor) stacks" with "Assess compatibility with the Flutter/Dart frontend and the backend (if one exists)". Line 18: replace "between moovie (frontend) and backend submodules" with "between the frontend and backend submodules (if present)".

- [ ] **Step 2: Make backend criteria conditional**

In "What to Review Against" (line 22) replace "Meta-repo structure, submodule setup" wording to drop the moovie-specific framing — keep "CLAUDE.md — Meta-repo structure, submodule setup, ecosystem-wide patterns". In Review Criteria line 29, replace "Kotlin/Ktor patterns (backend)" with "the backend stack (if present)". In Output Format line 43, replace "Does this touch both moovie and backend?" with "Does this touch both the frontend and a backend?".

- [ ] **Step 3: Verify**

Run: `grep -niE "moovie|kotlin|ktor" agents/architect-review.md`
Expected: no output.

- [ ] **Step 4: Commit**

```bash
git add agents/architect-review.md
git commit -m "refactor(agents): make architect-review project-agnostic"
```

---

### Task 3: Dynamic repo slug in `reviewer.md`

**Files:**
- Modify: `agents/reviewer.md`

- [ ] **Step 1: Add a repo-slug resolution preamble**

Under "Repository Context" (lines 17-24), replace the hardcoded `Repo: mobyleOfficial/MoovieAi` line with:

```markdown
- Repo: resolve once at start — `REPO=$(gh repo view --json nameWithOwner --jq .nameWithOwner)`. Use `$REPO` in every `gh api` call below. If `gh repo view` fails, stop and report; do not assume a slug.
```

Drop the moovie-specific audit-reference line (line 24) or generalize to "Project rules: `rules/`".

- [ ] **Step 2: Replace every hardcoded slug in commands**

Replace all occurrences of `mobyleOfficial/MoovieAi` (lines 44, 66, 174 and any other) with `$REPO` (in bash blocks) or `<repo>` (in prose/GraphQL `-f owner=` / `-f repo=` args become `-f owner="${REPO%/*}" -f repo="${REPO#*/}"`).

Run to enumerate before editing: `grep -n "mobyleOfficial/MoovieAi" agents/reviewer.md`

- [ ] **Step 3: Verify**

Run: `grep -nE "mobyleOfficial/MoovieAi|moovie" agents/reviewer.md`
Expected: no output.

- [ ] **Step 4: Commit**

```bash
git add agents/reviewer.md
git commit -m "refactor(agents): resolve repo slug dynamically in reviewer"
```

---

### Task 4: Rename + parameterize implementer-tester → `flutter-implementer-tester`

**Files:**
- Rename: `agents/implementer-tester.md` → `agents/flutter-implementer-tester.md`
- Modify: the renamed file

- [ ] **Step 1: Rename via git**

```bash
git mv agents/implementer-tester.md agents/flutter-implementer-tester.md
```

- [ ] **Step 2: Update frontmatter**

In the renamed file: `name: implementer-tester` → `name: flutter-implementer-tester`. In `description`, replace "in the moovie submodule" with "in the target Flutter submodule".

- [ ] **Step 3: Add a "Resolve Target Submodule" section**

Insert after "## Context: MoovieAi Ecosystem" (retitle that heading to "## Context: The Ecosystem"):

```markdown
## Resolve Target Submodule (first step, every run)

Work happens inside one Flutter submodule. Resolve `<app>` before touching files:

1. If the spec/feature request names a target app, use it.
2. Else list submodules from `.gitmodules` and keep those containing a `pubspec.yaml` (Flutter apps).
3. If exactly one Flutter submodule exists, use it.
4. If multiple exist and the target is ambiguous, STOP and ask the user.

All `moovie/...` paths below are written as `<app>/...` — substitute the resolved submodule.
```

- [ ] **Step 4: Parameterize every `moovie/` path**

Replace all `moovie/` occurrences with `<app>/` throughout (Project Structure, Allowed Paths, DI checklist, Localization, Testing sections). Replace "the **moovie** (Flutter/Dart) submodule" / "moovie/ — Flutter frontend (where you work)" with "the target Flutter submodule (`<app>/`)".

Run to enumerate: `grep -n "moovie" agents/flutter-implementer-tester.md`

- [ ] **Step 5: Neutralize examples**

Replace movie-themed identifiers in examples (`domainMovies` → `domainItems`, etc.) with generic equivalents. Keep Dart/Flutter syntax intact.

- [ ] **Step 6: Verify**

Run: `grep -niE "moovie|implementer-tester" agents/flutter-implementer-tester.md`
Expected: only `flutter-implementer-tester` (the new name) matches; no bare `moovie` or `implementer-tester`.

- [ ] **Step 7: Commit**

```bash
git add -A agents/
git commit -m "refactor(agents): rename implementer-tester to flutter-implementer-tester and parameterize submodule"
```

---

### Task 5: Rename + parameterize validator → `flutter-validator`

**Files:**
- Rename: `agents/validator.md` → `agents/flutter-validator.md`
- Modify: the renamed file

- [ ] **Step 1: Rename via git**

```bash
git mv agents/validator.md agents/flutter-validator.md
```

- [ ] **Step 2: Update frontmatter**

`name: validator` → `name: flutter-validator`. In `description`, replace "across moovie and backend submodules" with "across the project's Flutter submodule(s) and an optional backend".

- [ ] **Step 3: Parameterize paths + make backend optional**

Replace `moovie/` with `<app>/` and `(moovie/)` section labels with `(Flutter)`. Add the same "Resolve Target Submodule" note as Task 4 Step 3 near the top of the body. Retitle "## Context: MoovieAi Ecosystem" → "## Context: The Ecosystem"; in its bullet list mark backend as "if present". Make checklist section "### 3. Architecture Compliance (backend/)" conditional: prefix with "(Only if the change touches a backend.)".

- [ ] **Step 4: Dynamic repo slug in PR-mode + reviewer dispatch**

In the Detection bash block and the `Task({...})` dispatch prompt (line ~186), replace `mobyleOfficial/MoovieAi` with a resolved `$REPO` (add the same `REPO=$(gh repo view --json nameWithOwner --jq .nameWithOwner)` line) / `<repo>` in the dispatch prose. Update the dispatch `subagent_type: "reviewer"` prompt text accordingly.

- [ ] **Step 5: Verify**

Run: `grep -niE "moovie|mobyleOfficial/MoovieAi|\bvalidator\b" agents/flutter-validator.md`
Expected: only `flutter-validator` matches; no bare `moovie`, slug, or bare `validator`.

- [ ] **Step 6: Commit**

```bash
git add -A agents/
git commit -m "refactor(agents): rename validator to flutter-validator and parameterize submodule"
```

---

### Task 6: Neutralize command examples + fix review-pr refs

**Files:**
- Modify: `commands/new-usecase.md`, `commands/new-datasource.md`, `commands/new-repository.md`, `commands/new-ui-module.md`, `commands/review-pr.md`

- [ ] **Step 1: Neutralize movie examples in new-* commands**

In each `new-*.md`, replace illustrative movie identifiers with generic ones: `movies`/`movie_detail` → `items`/`item_detail`; `get_movies`/`fetch_trending` → `get_items`/`fetch_featured`; `List<Movie>`/`Movie`/`GetMovies` → `List<Item>`/`Item`/`GetItems`; `MovieFilter` → `ItemFilter`. Keep all Dart structure, paths, and `package:core`/`package:common` imports unchanged.

- [ ] **Step 2: Dynamic repo slug in review-pr.md**

In `commands/review-pr.md` line 17, replace "on mobyleOfficial/MoovieAi" with "on the current repository (resolve via `gh repo view --json nameWithOwner`)".

- [ ] **Step 3: Verify**

Run: `grep -niE "movie|mobyleOfficial/MoovieAi" commands/`
Expected: no output.

- [ ] **Step 4: Commit**

```bash
git add commands/
git commit -m "refactor(commands): neutralize movie examples and dynamic repo slug"
```

---

### Task 7: Dynamic submodule list in `check-submodule-ai.sh`

**Files:**
- Modify: `.claude/hooks/check-submodule-ai.sh`

- [ ] **Step 1: Read submodules from `.gitmodules`**

Replace the hardcoded loop header `for submodule in moovie backend; do` (line 55) with a dynamic enumeration:

```bash
# Enumerate submodule paths from .gitmodules (fallback to none if file absent)
submodules=$(git config -f .gitmodules --get-regexp '^submodule\..*\.path$' 2>/dev/null | awk '{print $2}')
for submodule in $submodules; do
```

Update the comment on lines 9 and 36 to say "any configured submodule" instead of "moovie/ or backend/".

- [ ] **Step 2: Verify script still parses**

Run: `bash -n .claude/hooks/check-submodule-ai.sh && echo OK`
Expected: `OK`.

- [ ] **Step 3: Verify enumeration works in this repo**

Run: `git config -f .gitmodules --get-regexp '^submodule\..*\.path$' | awk '{print $2}'`
Expected: lists `moovie` and `backend` (current submodules).

- [ ] **Step 4: Commit**

```bash
git add .claude/hooks/check-submodule-ai.sh
git commit -m "refactor(hooks): enumerate submodules dynamically in check-submodule-ai"
```

---

### Task 8: Ripple — update docs/agent-name references

**Files:**
- Modify: `CLAUDE.md`, `.claude/CLAUDE.md`, `agents/README.md`

- [ ] **Step 1: CLAUDE.md**

Line 301: `[agents/implementer-tester.md](agents/implementer-tester.md)` → `[agents/flutter-implementer-tester.md](agents/flutter-implementer-tester.md)`. Search the file for other "moovie submodule" pipeline phrasing tied to implementation and generalize to "the target Flutter submodule" where it describes the agent pipeline (do NOT change the moovie submodule setup/build sections — those legitimately describe the moovie app).

- [ ] **Step 2: .claude/CLAUDE.md**

Line 37: update the pipeline-agent list to `(\`pm-spec\`, \`architect-review\`, \`flutter-implementer-tester\`, \`flutter-validator\`)`.

- [ ] **Step 3: agents/README.md**

Replace `implementer-tester` → `flutter-implementer-tester` and `validator` → `flutter-validator` in the agent list and Pipeline Usage section (lines 11-12, 27). Generalize "in the moovie submodule" / "across the moovie and backend submodules" to "in the target Flutter submodule" / "across the project's Flutter submodule(s) and optional backend". Keep "MoovieAi ecosystem" framing in README intro only if accurate, else "the ecosystem".

- [ ] **Step 4: Verify renamed agents have no stale references repo-wide**

Run:
```bash
grep -rnE "\bimplementer-tester\b" . --include=*.md --include=*.sh --include=*.json | grep -v flutter-implementer-tester | grep -v docs/superpowers
grep -rnE "\bvalidator\b" . --include=*.md --include=*.sh --include=*.json | grep -v flutter-validator | grep -v docs/superpowers
```
Expected: no output from either.

- [ ] **Step 5: Commit**

```bash
git add CLAUDE.md .claude/CLAUDE.md agents/README.md
git commit -m "doc: update references to renamed flutter agents"
```

---

### Task 9: Final verification sweep

**Files:** none (verification only)

- [ ] **Step 1: No hardcoded repo slug in agents/commands**

Run: `grep -rn "mobyleOfficial/MoovieAi" agents/ commands/`
Expected: no output.

- [ ] **Step 2: No hardcoded `moovie/` path in agents/commands**

Run: `grep -rn "moovie/" agents/ commands/`
Expected: no output.

- [ ] **Step 3: No stale agent names**

Run:
```bash
grep -rnE "\b(implementer-tester|validator)\b" agents/ commands/ CLAUDE.md .claude/CLAUDE.md | grep -vE "flutter-(implementer-tester|validator)"
```
Expected: no output.

- [ ] **Step 4: Confirm renamed agent files exist with correct frontmatter names**

Run: `grep -h "^name:" agents/flutter-implementer-tester.md agents/flutter-validator.md`
Expected:
```
name: flutter-implementer-tester
name: flutter-validator
```

- [ ] **Step 5: Update the spec status**

In `docs/superpowers/specs/2026-06-19-generic-agents-design.md`, change `Status: Approved (pending spec review)` to `Status: Implemented`.

- [ ] **Step 6: Commit**

```bash
git add docs/superpowers/specs/2026-06-19-generic-agents-design.md
git commit -m "doc: mark generic-agents spec implemented"
```
