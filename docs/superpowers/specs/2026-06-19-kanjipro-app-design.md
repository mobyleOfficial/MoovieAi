# KanjiPro — Design

**Date:** 2026-06-19
**Repo:** https://github.com/mobyleOfficial/KanjiPro (submodule `kanjipro/`)
**Branch context:** meta-repo `feature/generic-agents`
**Status:** Approved (pending spec review)

## Overview

KanjiPro is an offline kanji-learning app for Android + iOS, modeled on the (retired)
Hiragana Pro / Katakana Pro apps but adapted for kanji. Users pick a JLPT level (N5→N1),
study flashcards, and take multiple-choice quizzes in three recognition modes. A custom
reinforcement scheduler decides which kanji to show, driving mastery over repeated sessions.
Fully offline: kanji data ships as a bundled JSON asset; progress persists locally.

## Goals

- Learn kanji by JLPT level with three quiz modes: **kanji→on reading**, **kanji→kun reading**,
  **kanji→meaning**.
- Study/flashcard mode showing literal + on + kun + meaning, with optional TTS.
- A reinforcement scheduler with a per-level active pool and per-kanji hit counts.
- Persistent progress (hit counts, mastery) across sessions.
- Architecture consistent with the moovie ecosystem (Clean Architecture multimodule + BLoC),
  so the meta-repo's `flutter-*` agents and `rules/` apply unchanged.

## Non-Goals (MVP)

- No backend (offline only). Data layer designed so a backend could replace the local source later.
- No stroke-order / writing practice.
- No typed-input quizzes (multiple choice only).
- No accounts / cloud sync.
- No Portuguese kanji meanings (meanings are English from KANJIDIC2; only the app **UI** is en+pt).
- No classic SRS time-scheduling (the hit-count scheduler below replaces it).

## Decisions Summary

| Topic | Decision |
|-------|----------|
| Platforms | Android + iOS |
| Quiz modes | kanji→on, kanji→kun, kanji→meaning (multiple choice, 4 options) |
| Study | Flashcards showing literal + on + kun + meaning |
| Content | All JLPT N5–N1, grouped by level |
| Data | Bundled offline JSON (from kanjiapi.dev / KANJIDIC2) |
| Meanings / UI languages | Meanings English; UI localized en + pt |
| Architecture | Full Clean Architecture multimodule, mirroring moovie |
| Persistence | ObjectBox (per-kanji progress) |
| Audio | flutter_tts; detect Japanese voice, show guidance both platforms if missing (no native install intents) |
| Scheduler | Per-level active pool, difficulty-weighted selection (see below) |

## Reinforcement Scheduler (core mechanic)

Constants (tunable): `ACTIVE_POOL_SIZE = 10`, `MASTERY_TARGET = 10`, `REMINDER_WEIGHT ≈ 0.10`.

**Per-kanji state** (persisted), scoped to its JLPT level:
- `status`: `locked` (not yet introduced) | `learning` (in active pool) | `mastered` (reached target)
- `hitCount`: integer `0..MASTERY_TARGET`
- stats: `timesSeen`, `timesCorrect`, `timesWrong`, `lastSeenAt`

**Pool initialization (per level):** all kanji start `locked`. The first `ACTIVE_POOL_SIZE`
become `learning` (the active pool). Remaining stay `locked` until a slot opens.

**On answer:**
- **Correct:** `hitCount += 1` (cap `MASTERY_TARGET`).
  - If `hitCount == MASTERY_TARGET`: set `status = mastered`, remove from active pool, and
    promote the next `locked` kanji (lowest index / level order) to `learning` to refill the
    pool (if any `locked` remain).
- **Incorrect:** `hitCount -= 1` (floor `0`).
  - If the kanji was `mastered` (i.e. its count was at target before this miss): set
    `status = learning`, re-add to the active pool, and **boost it to reappear in the same
    session** (near-front of the selection queue).

**Selection (`SelectNextKanji` per level/session):**
- Candidate set = active `learning` pool, plus `mastered` kanji as low-probability reminders.
- Weight per learning kanji = `(MASTERY_TARGET - hitCount) + 1` → lower hitCount appears more
  often (struggling kanji repeat more). A just-missed (demoted) kanji gets an additional
  near-term boost.
- Mastered kanji collectively contribute `REMINDER_WEIGHT` of selections (reminders).
- Weighted-random pick; avoid immediately repeating the exact previous kanji unless it was
  just missed (the demotion/boost case explicitly *wants* a quick repeat).

**Level completion:** when all kanji in a level are `mastered`, the level shows 100%;
sessions then draw only mastered reminders (so review continues at low intensity).

## Module Layout (mirrors moovie)

```
kanjipro/
├── core/                              # base: UseCase<P,R>, Result<T>, failures, theme tokens
├── features/
│   ├── kanji/
│   │   ├── domain/lib/                # Kanji model, KanjiRepository, GetKanjiByLevel, GetAllLevels
│   │   ├── data/lib/                  # KanjiLocalDataSource (JSON asset), KanjiModel.toDomain(), repo impl, di
│   │   └── lib/kanji.dart             # barrel
│   ├── quiz/
│   │   ├── domain/lib/                # QuizMode, QuizQuestion, GenerateQuiz, GradeAnswer
│   │   └── lib/quiz.dart
│   └── progress/
│       ├── domain/lib/                # KanjiProgress, LevelProgress, scheduler usecases (below)
│       ├── data/lib/                  # ObjectBox entity + datasource, repo impl, di
│       └── lib/progress.dart
├── ui/
│   ├── common/lib/                    # theme (light/dark), shared widgets, TtsService, l10n (app_en.arb, app_pt.arb)
│   ├── home_ui/lib/                   # level selection (N5..N1) with progress %
│   ├── study_ui/lib/                  # flashcards: literal + on + kun + meaning + TTS
│   └── quiz_ui/lib/                   # mode select → MC quiz → results
├── lib/
│   ├── di/                            # injectable config + per-feature modules
│   ├── routes/                        # auto_route config
│   ├── config/                        # flavor config
│   └── main*.dart                     # flavors
├── assets/data/kanji.json             # bundled dataset (all N5–N1)
└── test/                              # mirrors lib/ structure
```

State management: BLoC/Cubit per UI module, sealed `Loading`/`Success`/`Error` states (moovie pattern).
DI: GetIt + injectable; use cases registered as factories. Routing: auto_route. Codegen: build_runner
(json_serializable, injectable, auto_route, objectbox).

## Domain Models

- `JlptLevel` — enum `n5,n4,n3,n2,n1`.
- `Kanji` — `literal`, `onReadings: List<String>`, `kunReadings: List<String>`,
  `meanings: List<String>`, `jlptLevel: JlptLevel`, `strokeCount: int`.
- `QuizMode` — enum `onReading | kunReading | meaning`.
- `QuizQuestion` — `kanji: Kanji`, `mode: QuizMode`, `options: List<String>` (4), `correctIndex: int`.
- `KanjiProgress` — `literal`, `jlptLevel`, `status`, `hitCount`, `timesSeen`,
  `timesCorrect`, `timesWrong`, `lastSeenAt`.
- `LevelProgress` — `level`, `masteredCount`, `learningCount`, `lockedCount`, `total`, `percent`.

## Key Use Cases

- `GetAllLevels()` → list of levels with `LevelProgress`.
- `GetKanjiByLevel(level)` → `List<Kanji>`.
- `GenerateQuiz(level, mode)` → builds a `QuizQuestion`: target chosen by `SelectNextKanji`;
  correct answer from the target's readings/meaning; 3 unique distractors of the same answer-type
  sampled from the same level; options shuffled.
- `SelectNextKanji(level)` → scheduler weighted pick (see algorithm).
- `RecordAnswer(literal, level, correct)` → applies hit-count delta + promote/demote/refill,
  persists, returns updated `KanjiProgress`.
- `GetLevelProgress(level)` → aggregates progress for the home screen.

## Data Pipeline (dataset generation)

- A Python script (in a project-local venv per `rules/PYTHON_ENVS.md`) fetches from
  **kanjiapi.dev** (or parses **KANJIDIC2**) and writes `kanjipro/assets/data/kanji.json`.
- Per entry: `literal`, `jlpt` (5..1 → mapped to N5..N1), `on_readings`, `kun_readings`,
  `meanings` (English), `stroke_count`.
- Only kanji with a JLPT level are included. Kanji missing an on **or** kun reading are kept,
  but are **excluded from that specific quiz mode** at quiz-generation time (still used for the
  other modes and meaning).
- **Attribution:** KANJIDIC2 is **CC BY-SA 4.0** (EDRDG). Ship attribution in-app (an About
  screen entry) and in the kanjipro README. The generation script and its source notes live in
  `kanjipro/tool/` (script) but the LICENSE/attribution text is committed with the data.

## Quiz / Edge Cases

- Distractors must be unique and differ from the correct answer; if a level has too few
  distractor candidates of a type, draw from adjacent levels as fallback.
- A kanji with no readings for the selected mode is never chosen as the target for that mode.
- TTS: `TtsService.isJapaneseAvailable()` gates the speak button. If unavailable, show guidance
  text (both platforms) — Android: install a Japanese voice via system TTS settings; iOS:
  Settings → Accessibility → Spoken Content → Voices. Never crash; degrade silently.
- Empty/locked level: if progress data is absent, initialize the pool on first entry.

## Persistence

- ObjectBox box of `KanjiProgressEntity` keyed by `(literal)` (literal is globally unique; level
  stored as a field). Read/written through `ProgressLocalDataSource` → `ProgressRepository`.
- Generated ObjectBox files (`objectbox-model.json`, `*.g.dart`) are build artifacts; never
  hand-edited (consistent with moovie rules).

## Testing

Mirror `lib/` under `test/`:
- Scheduler: promotion at target, demotion + same-session boost, pool refill from locked,
  weighting favors low hitCount, reminder selection of mastered.
- `GenerateQuiz`: 4 unique options, correct index valid, mode-specific answer source, distractor
  fallback when scarce.
- `RecordAnswer`: hit-count clamping (0..target), stats increment, status transitions.
- Data: `KanjiModel` JSON parse + `toDomain()`; dataset loads and is non-empty.
- Mock repositories/data sources; no real I/O. `flutter analyze` + `flutter test` green.

## Localization

- App UI strings in `ui/common/lib/l10n/app_en.arb` + `app_pt.arb`; access via `AppLocalizations`.
- Kanji meanings are data (English), not localized.

## AI-Agnostic Submodule

Per `rules/AI_AGNOSTIC_SUBMODULES.md`, the `kanjipro/` repo contains **no** `CLAUDE.md` or
`.claude/`. All AI/design artifacts (this spec, the plan) live in the meta-repo under
`docs/superpowers/`. Commits in `kanjipro/` are single-author (no co-authors).

## Implementation Sequencing (de-risk via vertical slice)

1. Multimodule skeleton + tooling (bloc, get_it, injectable, auto_route, objectbox,
   json_serializable, flutter_tts) + pubspec path wiring + DI + l10n + theme.
2. Dataset script → `assets/data/kanji.json` (all N5–N1).
3. `kanji` feature domain/data + tests.
4. `home_ui` (level list with progress).
5. `study_ui` (flashcards + TtsService).
6. `progress` feature (ObjectBox) + scheduler use cases + tests.
7. `quiz` feature domain + `quiz_ui` (3 modes, MC, results) wired to scheduler + tests.

**Vertical-slice recommendation:** wire N5 + study + one quiz mode end-to-end (steps 1–6 for N5,
one mode in step 7) before fanning out to all modes/levels. Dataset is generated full N5–N1
regardless; only UI/mode breadth is staged.

## Risks

- **Dataset quality/licensing:** kanjiapi.dev/KANJIDIC2 coverage and JLPT mapping vary; verify
  counts per level and ship correct CC BY-SA attribution.
- **Scheduler correctness:** the promote/demote/refill transitions are the trickiest logic;
  covered by focused unit tests.
- **Multimodule setup cost:** mirroring moovie's package graph is heavier than a single module;
  front-loaded in step 1.
- **TTS variability:** device voices differ; mitigated by detection + graceful guidance.
