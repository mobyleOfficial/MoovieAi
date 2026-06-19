# KanjiPro Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking. The `flutter-implementer-tester` agent and the `/new-datasource`, `/new-repository`, `/new-usecase`, `/new-ui-module` scaffolding commands produce the Clean-Architecture boilerplate — use them; this plan supplies the logic, tests, and wiring.

**Goal:** Offline Android+iOS kanji-learning app (JLPT N5–N1) with study flashcards, 3 multiple-choice quiz modes, and a per-level reinforcement scheduler with persistent hit counts.

**Architecture:** Full Clean Architecture multimodule monorepo mirroring moovie — path-dependency packages (`core/`, `features/<f>/{domain,data}`, `ui/<m>_ui`), BLoC/Cubit with sealed states, GetIt+injectable DI, auto_route, build_runner codegen, ObjectBox persistence, flutter_tts audio.

**Tech Stack:** Flutter (Dart ^3.11), flutter_bloc, get_it, injectable, auto_route, objectbox, json_serializable, flutter_tts, mocktail (tests).

**Work dir:** `kanjipro/` submodule (resolve as `<app>` = `kanjipro`). All commits in `kanjipro/` are single-author, no co-authors. No `CLAUDE.md`/`.claude/` in the submodule.

**Reference:** `docs/superpowers/specs/2026-06-19-kanjipro-app-design.md`

## Global Constraints

- Dart SDK `^3.11.4`; platforms Android + iOS only.
- Clean Architecture dep direction: `feature → data → domain`; domain is pure Dart, zero Flutter deps.
- Never import another feature's `data/` layer; cross-feature via `domain/` contracts.
- Repositories never try/catch — data sources own `Result<T>` mapping; repos only `.toDomain()`.
- Use cases: one per file, single public `call`, registered `@injectable` (factory).
- One class per file; `snake_case` filenames, `PascalCase` classes; no `dynamic`; `const`/`final`; arrow syntax for single-expression fns; descriptive names.
- Generated files (`*.g.dart`, `*.gr.dart`, `objectbox-model.json`, `objectbox.g.dart`) never hand-edited; run `dart run build_runner build --delete-conflicting-outputs`.
- All user-visible UI strings via `AppLocalizations` (en + pt ARB). Kanji meanings are data (English), not localized.
- Scheduler constants: `ACTIVE_POOL_SIZE = 10`, `MASTERY_TARGET = 10`, `REMINDER_WEIGHT = 0.10`.
- Dataset attribution: KANJIDIC2 is CC BY-SA 4.0 (EDRDG) — ship attribution in README + in-app About.
- Verify each task: `cd kanjipro && flutter analyze` and `flutter test` green before commit.

---

### Task 1: Multimodule skeleton + `core` package + tooling

**Files:**
- Modify: `kanjipro/pubspec.yaml` (root app deps + path deps + assets)
- Create: `kanjipro/core/pubspec.yaml`, `kanjipro/core/lib/core.dart`
- Create: `kanjipro/core/lib/src/usecase.dart`, `kanjipro/core/lib/src/result.dart`, `kanjipro/core/lib/src/failure.dart`
- Create: `kanjipro/analysis_options.yaml` (lint rules), `kanjipro/build.yaml`
- Test: `kanjipro/core/test/result_test.dart`

**Interfaces:**
- Produces: `abstract class UseCase<Params, Type> { Future<Type> call([Params params]); }`;
  `sealed class Result<T>` with `Success<T>(T data)` and `FailureResult<T>(Failure failure)`;
  `abstract class Failure { final String message; }` with `NotFoundFailure`, `DataFailure`.

- [ ] **Step 1: Define core contracts (test first)**

Create `kanjipro/core/test/result_test.dart`:
```dart
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Success holds data', () {
    const Result<int> r = Success(42);
    expect((r as Success<int>).data, 42);
  });

  test('FailureResult holds failure', () {
    const r = FailureResult<int>(DataFailure('boom'));
    expect((r as FailureResult<int>).failure.message, 'boom');
  });
}
```

- [ ] **Step 2: Create `core/lib/src/failure.dart`**
```dart
abstract class Failure {
  const Failure(this.message);
  final String message;
}

class NotFoundFailure extends Failure {
  const NotFoundFailure(super.message);
}

class DataFailure extends Failure {
  const DataFailure(super.message);
}
```

- [ ] **Step 3: Create `core/lib/src/result.dart`**
```dart
import 'failure.dart';

sealed class Result<T> {
  const Result();
}

class Success<T> extends Result<T> {
  const Success(this.data);
  final T data;
}

class FailureResult<T> extends Result<T> {
  const FailureResult(this.failure);
  final Failure failure;
}
```

- [ ] **Step 4: Create `core/lib/src/usecase.dart`**
```dart
abstract class UseCase<Params, Type> {
  Future<Type> call([Params params]);
}
```

- [ ] **Step 5: Create `core/lib/core.dart` barrel**
```dart
export 'src/failure.dart';
export 'src/result.dart';
export 'src/usecase.dart';
```

- [ ] **Step 6: Create `core/pubspec.yaml`**
```yaml
name: core
description: Shared base classes for KanjiPro.
publish_to: 'none'
version: 0.0.1
environment:
  sdk: ^3.11.4
dependencies:
  flutter:
    sdk: flutter
dev_dependencies:
  flutter_test:
    sdk: flutter
flutter:
```

- [ ] **Step 7: Set root `pubspec.yaml` deps, path deps, assets**

Set the root app `kanjipro/pubspec.yaml` dependencies block to include (exact versions resolved via `flutter pub get`):
```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
  core:
    path: core
  flutter_bloc: ^9.0.0
  get_it: ^8.0.0
  injectable: ^2.5.0
  auto_route: ^9.2.0
  objectbox: ^4.0.0
  objectbox_flutter_libs: ^4.0.0
  json_annotation: ^4.9.0
  flutter_tts: ^4.2.0
  intl: any

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0
  build_runner: ^2.4.0
  injectable_generator: ^2.6.0
  auto_route_generator: ^9.0.0
  json_serializable: ^6.8.0
  objectbox_generator: ^4.0.0
  mocktail: ^1.0.0

flutter:
  generate: true
  uses-material-design: true
  assets:
    - assets/data/
```

- [ ] **Step 8: Add `kanjipro/l10n.yaml`**
```yaml
arb-dir: ui/common/lib/l10n
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
output-class: AppLocalizations
synthetic-package: false
output-dir: ui/common/lib/l10n/gen
```

- [ ] **Step 9: Run pub get + tests**

Run: `cd kanjipro && flutter pub get && flutter test core`
Expected: `result_test.dart` 2 tests PASS.

- [ ] **Step 10: Commit**
```bash
cd kanjipro
git add core pubspec.yaml l10n.yaml analysis_options.yaml build.yaml
git commit -m "chore: add multimodule skeleton, core package, and tooling"
```

---

### Task 2: `ui/common` — theme, l10n (en+pt), TtsService

**Files:**
- Create: `kanjipro/ui/common/pubspec.yaml`, `kanjipro/ui/common/lib/common.dart`
- Create: `kanjipro/ui/common/lib/src/theme/app_theme.dart`
- Create: `kanjipro/ui/common/lib/src/tts/tts_service.dart`
- Create: `kanjipro/ui/common/lib/l10n/app_en.arb`, `app_pt.arb`
- Test: `kanjipro/ui/common/test/tts_service_test.dart`

**Interfaces:**
- Produces: `AppTheme.light()`, `AppTheme.dark()` → `ThemeData`;
  `abstract class TtsService { Future<bool> isJapaneseAvailable(); Future<void> speak(String text); }`
  and `class FlutterTtsService implements TtsService`.

- [ ] **Step 1: Write TtsService test (with a fake)**

Create `kanjipro/ui/common/test/tts_service_test.dart`:
```dart
import 'package:common/common.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeTts implements TtsService {
  _FakeTts(this._available);
  final bool _available;
  String? spoken;
  @override
  Future<bool> isJapaneseAvailable() async => _available;
  @override
  Future<void> speak(String text) async => spoken = text;
}

void main() {
  test('reports availability and records spoken text', () async {
    final tts = _FakeTts(true);
    expect(await tts.isJapaneseAvailable(), true);
    await tts.speak('にち');
    expect(tts.spoken, 'にち');
  });
}
```

- [ ] **Step 2: Create `tts_service.dart`**
```dart
import 'package:flutter_tts/flutter_tts.dart';

abstract class TtsService {
  Future<bool> isJapaneseAvailable();
  Future<void> speak(String text);
}

class FlutterTtsService implements TtsService {
  FlutterTtsService(this._tts);
  final FlutterTts _tts;
  static const _lang = 'ja-JP';

  @override
  Future<bool> isJapaneseAvailable() async {
    final available = await _tts.isLanguageAvailable(_lang);
    return available == true || available == 1;
  }

  @override
  Future<void> speak(String text) async {
    await _tts.setLanguage(_lang);
    await _tts.speak(text);
  }
}
```

- [ ] **Step 3: Create `app_theme.dart`** (light + dark from a seed color)
```dart
import 'package:flutter/material.dart';

abstract final class AppTheme {
  static ThemeData light() => ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFD32F2F)),
        useMaterial3: true,
      );

  static ThemeData dark() => ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFD32F2F),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      );
}
```

- [ ] **Step 4: Create ARB files**

`kanjipro/ui/common/lib/l10n/app_en.arb`:
```json
{
  "@@locale": "en",
  "appTitle": "KanjiPro",
  "@appTitle": {},
  "levelN5": "JLPT N5",
  "@levelN5": {},
  "study": "Study",
  "@study": {},
  "quiz": "Quiz",
  "@quiz": {},
  "modeOnReading": "On'yomi",
  "@modeOnReading": {},
  "modeKunReading": "Kun'yomi",
  "@modeKunReading": {},
  "modeMeaning": "Meaning",
  "@modeMeaning": {},
  "ttsUnavailable": "Japanese voice not installed. Install it in your device's text-to-speech settings.",
  "@ttsUnavailable": {},
  "correct": "Correct",
  "@correct": {},
  "wrong": "Wrong",
  "@wrong": {},
  "results": "Results",
  "@results": {}
}
```
`app_pt.arb`: same keys, Portuguese values (`appTitle`→"KanjiPro", `study`→"Estudar", `quiz`→"Quiz", `modeOnReading`→"On'yomi", `modeKunReading`→"Kun'yomi", `modeMeaning`→"Significado", `ttsUnavailable`→"Voz em japonês não instalada. Instale nas configurações de leitura de voz do dispositivo.", `correct`→"Certo", `wrong`→"Errado", `results`→"Resultados", `levelN5`→"JLPT N5").

- [ ] **Step 5: Create `common.dart` barrel + pubspec**

`kanjipro/ui/common/lib/common.dart`:
```dart
export 'l10n/gen/app_localizations.dart';
export 'src/theme/app_theme.dart';
export 'src/tts/tts_service.dart';
```
`kanjipro/ui/common/pubspec.yaml`: name `common`, sdk `^3.11.4`, deps `flutter`, `flutter_localizations` (sdk), `flutter_tts: ^4.2.0`, `intl: any`; dev `flutter_test`. Include `flutter: generate: true`.

- [ ] **Step 6: Gen l10n + test**

Run: `cd kanjipro && flutter gen-l10n && flutter test ui/common`
Expected: tts test PASS; `app_localizations.dart` generated under `ui/common/lib/l10n/gen/`.

- [ ] **Step 7: Commit**
```bash
cd kanjipro && git add ui/common && git commit -m "feat: add common ui package (theme, l10n, tts service)"
```

---

### Task 3: Dataset generation script → `assets/data/kanji.json`

**Files:**
- Create: `kanjipro/tool/generate_kanji_dataset.py`
- Create: `kanjipro/tool/requirements.txt`, `kanjipro/tool/README.md`
- Create (generated output, committed): `kanjipro/assets/data/kanji.json`
- Create: `kanjipro/assets/data/ATTRIBUTION.md`

**Interfaces:**
- Produces: `assets/data/kanji.json` — a JSON array; each item:
  `{"literal": "日", "jlpt": "n5", "on_readings": ["ニチ","ジツ"], "kun_readings": ["ひ","-び","-か"], "meanings": ["day","sun"], "stroke_count": 4}`.

- [ ] **Step 1: Create a project-local venv (PYTHON_ENVS rule)**

Run:
```bash
cd kanjipro/tool && python3 -m venv .venv && . .venv/bin/activate && pip install requests
```
`requirements.txt` content: `requests`. Add `kanjipro/tool/.venv/` to `kanjipro/.gitignore`.

- [ ] **Step 2: Write `generate_kanji_dataset.py`**
```python
#!/usr/bin/env python3
"""Generate assets/data/kanji.json from kanjiapi.dev (KANJIDIC2, CC BY-SA 4.0)."""
import json, pathlib, sys, time
import requests

API = "https://kanjiapi.dev/v1"
LEVELS = {"jlpt-5": "n5", "jlpt-4": "n4", "jlpt-3": "n3", "jlpt-2": "n2", "jlpt-1": "n1"}
OUT = pathlib.Path(__file__).resolve().parent.parent / "assets" / "data" / "kanji.json"

def fetch(path):
    r = requests.get(f"{API}/{path}", timeout=30)
    r.raise_for_status()
    return r.json()

def main():
    out = []
    seen = set()
    for grade, level in LEVELS.items():
        literals = fetch(f"kanji/{grade}")
        for lit in literals:
            if lit in seen:
                continue
            seen.add(lit)
            d = fetch(f"kanji/{lit}")
            out.append({
                "literal": d["kanji"],
                "jlpt": level,
                "on_readings": d.get("on_readings", []),
                "kun_readings": d.get("kun_readings", []),
                "meanings": d.get("meanings", []),
                "stroke_count": d.get("stroke_count", 0),
            })
            time.sleep(0.02)
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(json.dumps(out, ensure_ascii=False, indent=0))
    print(f"wrote {len(out)} kanji -> {OUT}", file=sys.stderr)

if __name__ == "__main__":
    main()
```

- [ ] **Step 3: Run the generator**

Run: `cd kanjipro/tool && . .venv/bin/activate && python generate_kanji_dataset.py`
Expected: `wrote NNNN kanji -> .../assets/data/kanji.json` (NNNN in the low thousands).

- [ ] **Step 4: Sanity-check the dataset**

Run:
```bash
cd kanjipro && python3 -c "import json;d=json.load(open('assets/data/kanji.json'));print(len(d));print(sorted({k['jlpt'] for k in d}));assert all(k['literal'] and k['jlpt'] for k in d)"
```
Expected: a count in the low thousands and `['n1','n2','n3','n4','n5']`.

- [ ] **Step 5: Write attribution**

`kanjipro/assets/data/ATTRIBUTION.md`: state the data derives from KANJIDIC2 / kanjiapi.dev, © Electronic Dictionary Research and Development Group, licensed **CC BY-SA 4.0**, with a link to https://www.edrdg.org/ and https://kanjiapi.dev. Add the same paragraph to `kanjipro/README.md` under a "Data & Attribution" heading.

- [ ] **Step 6: Commit**
```bash
cd kanjipro && git add tool assets/data .gitignore README.md
git commit -m "feat: add kanji dataset generator and bundled kanji.json (CC BY-SA)"
```

---

### Task 4: `kanji` feature — domain

**Files:**
- Create: `kanjipro/features/kanji/domain/lib/...` via `/new-usecase` then hand-edit
- Create: `JlptLevel`, `Kanji` models; `KanjiRepository` contract; `GetAllLevels`, `GetKanjiByLevel`
- Create: `kanjipro/features/kanji/domain/pubspec.yaml`, barrel `kanji_domain.dart`
- Test: `kanjipro/features/kanji/domain/test/usecases/*_test.dart`

**Interfaces:**
- Produces: `enum JlptLevel { n5, n4, n3, n2, n1 }` (with `String get id` → "n5"… and `static JlptLevel fromId(String)`);
  `class Kanji { final String literal; final List<String> onReadings, kunReadings, meanings; final JlptLevel jlptLevel; final int strokeCount; }`;
  `abstract class KanjiRepository { Future<Result<List<Kanji>>> getByLevel(JlptLevel level); Future<Result<List<JlptLevel>>> getLevels(); }`;
  `class GetKanjiByLevel extends UseCase<JlptLevel, Result<List<Kanji>>>`;
  `class GetAllLevels extends UseCase<void, Result<List<JlptLevel>>>`.

- [ ] **Step 1: Test `JlptLevel.fromId` + `GetKanjiByLevel`**

`kanjipro/features/kanji/domain/test/usecases/get_kanji_by_level_test.dart`:
```dart
import 'package:core/core.dart';
import 'package:kanji_domain/kanji_domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements KanjiRepository {}

void main() {
  test('fromId maps strings to levels', () {
    expect(JlptLevel.fromId('n5'), JlptLevel.n5);
    expect(JlptLevel.n1.id, 'n1');
  });

  test('GetKanjiByLevel delegates to repository', () async {
    final repo = _MockRepo();
    final kanji = [
      const Kanji(literal: '日', onReadings: ['ニチ'], kunReadings: ['ひ'],
          meanings: ['day'], jlptLevel: JlptLevel.n5, strokeCount: 4),
    ];
    when(() => repo.getByLevel(JlptLevel.n5))
        .thenAnswer((_) async => Success(kanji));
    final result = await GetKanjiByLevel(repo)(JlptLevel.n5);
    expect((result as Success<List<Kanji>>).data.single.literal, '日');
  });
}
```

- [ ] **Step 2: Create `JlptLevel`**
```dart
enum JlptLevel {
  n5, n4, n3, n2, n1;

  String get id => name;
  static JlptLevel fromId(String value) =>
      JlptLevel.values.firstWhere((level) => level.name == value);
}
```

- [ ] **Step 3: Create `Kanji`**
```dart
class Kanji {
  const Kanji({
    required this.literal,
    required this.onReadings,
    required this.kunReadings,
    required this.meanings,
    required this.jlptLevel,
    required this.strokeCount,
  });

  final String literal;
  final List<String> onReadings;
  final List<String> kunReadings;
  final List<String> meanings;
  final JlptLevel jlptLevel;
  final int strokeCount;
}
```

- [ ] **Step 4: Create `KanjiRepository`**
```dart
import 'package:core/core.dart';
import 'kanji.dart';
import 'jlpt_level.dart';

abstract class KanjiRepository {
  Future<Result<List<Kanji>>> getByLevel(JlptLevel level);
  Future<Result<List<JlptLevel>>> getLevels();
}
```

- [ ] **Step 5: Create use cases**

`get_kanji_by_level.dart`:
```dart
import 'package:core/core.dart';
import '../models/jlpt_level.dart';
import '../models/kanji.dart';
import '../repositories/kanji_repository.dart';

class GetKanjiByLevel extends UseCase<JlptLevel, Result<List<Kanji>>> {
  GetKanjiByLevel(this._repository);
  final KanjiRepository _repository;

  @override
  Future<Result<List<Kanji>>> call([JlptLevel? params]) =>
      _repository.getByLevel(params!);
}
```
`get_all_levels.dart`: analogous, `extends UseCase<void, Result<List<JlptLevel>>>`, calls `_repository.getLevels()`.

- [ ] **Step 6: Barrel + pubspec**

`kanji_domain.dart` exports models/repositories/usecases. `pubspec.yaml`: name `kanji_domain`, dep `core: {path: ../../../../core}`, dev `flutter_test`, `mocktail`. (Domain stays pure Dart — only `core` + flutter_test.)

- [ ] **Step 7: Run tests**

Run: `cd kanjipro && flutter test features/kanji/domain`
Expected: PASS.

- [ ] **Step 8: Commit**
```bash
cd kanjipro && git add features/kanji/domain
git commit -m "feat: add kanji domain (models, repository, use cases)"
```

---

### Task 5: `kanji` feature — data (JSON local source + repo)

**Files:**
- Create: `kanjipro/features/kanji/data/lib/models/kanji_model.dart`
- Create: `kanjipro/features/kanji/data/lib/datasources/kanji_local_data_source.dart`
- Create: `kanjipro/features/kanji/data/lib/repositories/kanji_repository_impl.dart`
- Create: `kanjipro/features/kanji/data/lib/di/kanji_data_module.dart`, barrel, pubspec
- Create: `kanjipro/features/kanji/lib/kanji.dart` (feature barrel)
- Test: `kanjipro/features/kanji/data/test/...`

**Interfaces:**
- Consumes: `Kanji`, `JlptLevel`, `KanjiRepository` (Task 4); `Result` (Task 1).
- Produces: `class KanjiLocalDataSource { Future<List<KanjiModel>> loadAll(); }` (reads
  `assets/data/kanji.json` via `rootBundle`); `KanjiModel.fromJson` + `.toDomain()`;
  `class KanjiRepositoryImpl implements KanjiRepository`.

- [ ] **Step 1: Test `KanjiModel.fromJson`/`toDomain`**
```dart
// features/kanji/data/test/models/kanji_model_test.dart
import 'package:kanji_data/kanji_data.dart';
import 'package:kanji_domain/kanji_domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses json and maps to domain', () {
    final model = KanjiModel.fromJson(const {
      'literal': '日', 'jlpt': 'n5',
      'on_readings': ['ニチ'], 'kun_readings': ['ひ'],
      'meanings': ['day'], 'stroke_count': 4,
    });
    final kanji = model.toDomain();
    expect(kanji.literal, '日');
    expect(kanji.jlptLevel, JlptLevel.n5);
    expect(kanji.onReadings, ['ニチ']);
  });
}
```

- [ ] **Step 2: Create `KanjiModel`** (`json_serializable`)
```dart
import 'package:json_annotation/json_annotation.dart';
import 'package:kanji_domain/kanji_domain.dart';
part 'kanji_model.g.dart';

@JsonSerializable()
class KanjiModel {
  KanjiModel({
    required this.literal,
    required this.jlpt,
    required this.onReadings,
    required this.kunReadings,
    required this.meanings,
    required this.strokeCount,
  });

  final String literal;
  final String jlpt;
  @JsonKey(name: 'on_readings')
  final List<String> onReadings;
  @JsonKey(name: 'kun_readings')
  final List<String> kunReadings;
  final List<String> meanings;
  @JsonKey(name: 'stroke_count')
  final int strokeCount;

  factory KanjiModel.fromJson(Map<String, dynamic> json) =>
      _$KanjiModelFromJson(json);

  Kanji toDomain() => Kanji(
        literal: literal,
        onReadings: onReadings,
        kunReadings: kunReadings,
        meanings: meanings,
        jlptLevel: JlptLevel.fromId(jlpt),
        strokeCount: strokeCount,
      );
}
```

- [ ] **Step 3: Create `KanjiLocalDataSource`**
```dart
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/kanji_model.dart';

class KanjiLocalDataSource {
  const KanjiLocalDataSource();
  static const _assetPath = 'assets/data/kanji.json';

  Future<List<KanjiModel>> loadAll() async {
    final raw = await rootBundle.loadString(_assetPath);
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((item) => KanjiModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
```

- [ ] **Step 4: Test repository mapping (mock data source)**
```dart
// features/kanji/data/test/repositories/kanji_repository_impl_test.dart
import 'package:core/core.dart';
import 'package:kanji_data/kanji_data.dart';
import 'package:kanji_domain/kanji_domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockSource extends Mock implements KanjiLocalDataSource {}

void main() {
  test('getByLevel returns only that level, mapped to domain', () async {
    final source = _MockSource();
    when(source.loadAll).thenAnswer((_) async => [
          KanjiModel(literal: '日', jlpt: 'n5', onReadings: ['ニチ'],
              kunReadings: ['ひ'], meanings: ['day'], strokeCount: 4),
          KanjiModel(literal: '一', jlpt: 'n4', onReadings: ['イチ'],
              kunReadings: ['ひと'], meanings: ['one'], strokeCount: 1),
        ]);
    final repo = KanjiRepositoryImpl(source);
    final result = await repo.getByLevel(JlptLevel.n5);
    final data = (result as Success<List<Kanji>>).data;
    expect(data.length, 1);
    expect(data.single.literal, '日');
  });
}
```

- [ ] **Step 5: Create `KanjiRepositoryImpl`** (caches loaded list; no try/catch — source maps errors)
```dart
import 'package:core/core.dart';
import 'package:kanji_domain/kanji_domain.dart';
import '../datasources/kanji_local_data_source.dart';

class KanjiRepositoryImpl implements KanjiRepository {
  KanjiRepositoryImpl(this._source);
  final KanjiLocalDataSource _source;
  List<Kanji>? _cache;

  Future<List<Kanji>> _all() async =>
      _cache ??= (await _source.loadAll()).map((m) => m.toDomain()).toList();

  @override
  Future<Result<List<Kanji>>> getByLevel(JlptLevel level) async {
    final all = await _all();
    return Success(all.where((k) => k.jlptLevel == level).toList());
  }

  @override
  Future<Result<List<JlptLevel>>> getLevels() async =>
      const Success(JlptLevel.values);
}
```

- [ ] **Step 6: DI module + barrels + pubspec + build_runner**

`di/kanji_data_module.dart` with `@module` providing `KanjiLocalDataSource` and `KanjiRepository` (→ `KanjiRepositoryImpl`). `kanji_data.dart` barrel exports models/datasources/repositories. `features/kanji/lib/kanji.dart` re-exports `kanji_domain` + `kanji_data`. `pubspec.yaml` deps: `core`, `kanji_domain` (path), `json_annotation`, `injectable`; dev: `build_runner`, `json_serializable`, `flutter_test`, `mocktail`.
Run: `cd kanjipro && dart run build_runner build --delete-conflicting-outputs`

- [ ] **Step 7: Run tests**

Run: `cd kanjipro && flutter test features/kanji`
Expected: model + repository tests PASS.

- [ ] **Step 8: Commit**
```bash
cd kanjipro && git add features/kanji
git commit -m "feat: add kanji data layer (json source, model, repository)"
```

---

### Task 6: `progress` feature — domain models + reinforcement scheduler

**Files:**
- Create: `kanjipro/features/progress/domain/lib/models/` — `kanji_progress.dart`, `progress_status.dart`, `level_progress.dart`
- Create: `repositories/progress_repository.dart`
- Create: `usecases/` — `select_next_kanji.dart`, `record_answer.dart`, `get_level_progress.dart`, `ensure_pool_initialized.dart`
- Create: barrel `progress_domain.dart`, pubspec
- Test: `kanjipro/features/progress/domain/test/usecases/*_test.dart`

**Interfaces:**
- Consumes: `JlptLevel`, `Kanji` (Task 4); `Result`, `UseCase` (Task 1).
- Produces:
  - `enum ProgressStatus { locked, learning, mastered }`
  - `class KanjiProgress { final String literal; final JlptLevel level; final ProgressStatus status; final int hitCount; final int timesSeen, timesCorrect, timesWrong; final DateTime? lastSeenAt; KanjiProgress copyWith({...}); }`
  - `class LevelProgress { final JlptLevel level; final int mastered, learning, locked, total; double get percent; }`
  - `abstract class ProgressRepository { Future<List<KanjiProgress>> forLevel(JlptLevel); Future<void> upsert(KanjiProgress); Future<void> upsertAll(List<KanjiProgress>); }`
  - `class SelectNextKanji` — pure weighted picker over a `List<KanjiProgress>` given a `Random` (injectable seed for tests). Signature: `String? call(SelectParams params)` where `SelectParams { List<KanjiProgress> pool; String? lastShown; Random random; }`. Returns the chosen `literal` or null if pool empty.
  - `class RecordAnswer` — applies the hit-count rules and returns the **mutated pool** (`List<KanjiProgress>`), persisting via repo. Signature `Future<List<KanjiProgress>> call(RecordParams params)` where `RecordParams { List<KanjiProgress> pool; String literal; bool correct; }`.
  - constants in `progress_domain.dart`: `const kActivePoolSize = 10; const kMasteryTarget = 10; const kReminderWeight = 0.10;`

- [ ] **Step 1: Test `RecordAnswer` — promotion + pool refill**
```dart
// features/progress/domain/test/usecases/record_answer_test.dart
import 'package:kanji_domain/kanji_domain.dart';
import 'package:progress_domain/progress_domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements ProgressRepository {}

KanjiProgress p(String l, ProgressStatus s, int h) => KanjiProgress(
    literal: l, level: JlptLevel.n5, status: s, hitCount: h,
    timesSeen: 0, timesCorrect: 0, timesWrong: 0, lastSeenAt: null);

void main() {
  setUpAll(() => registerFallbackValue(p('x', ProgressStatus.locked, 0)));

  test('correct at target-1 masters kanji and promotes a locked one', () async {
    final repo = _MockRepo();
    when(() => repo.upsertAll(any())).thenAnswer((_) async {});
    final pool = [
      p('A', ProgressStatus.learning, kMasteryTarget - 1),
      p('B', ProgressStatus.locked, 0),
    ];
    final out = await RecordAnswer(repo)(
        RecordParams(pool: pool, literal: 'A', correct: true));
    final a = out.firstWhere((e) => e.literal == 'A');
    final b = out.firstWhere((e) => e.literal == 'B');
    expect(a.status, ProgressStatus.mastered);
    expect(a.hitCount, kMasteryTarget);
    expect(b.status, ProgressStatus.learning); // refilled
  });

  test('incorrect on mastered demotes and clamps, increments wrong', () async {
    final repo = _MockRepo();
    when(() => repo.upsertAll(any())).thenAnswer((_) async {});
    final pool = [p('A', ProgressStatus.mastered, kMasteryTarget)];
    final out = await RecordAnswer(repo)(
        RecordParams(pool: pool, literal: 'A', correct: false));
    final a = out.single;
    expect(a.status, ProgressStatus.learning);
    expect(a.hitCount, kMasteryTarget - 1);
    expect(a.timesWrong, 1);
  });

  test('incorrect floors hitCount at 0', () async {
    final repo = _MockRepo();
    when(() => repo.upsertAll(any())).thenAnswer((_) async {});
    final pool = [p('A', ProgressStatus.learning, 0)];
    final out = await RecordAnswer(repo)(
        RecordParams(pool: pool, literal: 'A', correct: false));
    expect(out.single.hitCount, 0);
  });
}
```

- [ ] **Step 2: Create models** (`progress_status.dart`, `kanji_progress.dart` with `copyWith`, `level_progress.dart` with `percent => total == 0 ? 0 : mastered / total`).

- [ ] **Step 3: Create `ProgressRepository` contract.**

- [ ] **Step 4: Implement `RecordAnswer`** to satisfy the test:
```dart
import 'package:core/core.dart';
import '../models/kanji_progress.dart';
import '../models/progress_status.dart';
import '../repositories/progress_repository.dart';
import '../constants.dart';

class RecordParams {
  const RecordParams({required this.pool, required this.literal, required this.correct});
  final List<KanjiProgress> pool;
  final String literal;
  final bool correct;
}

class RecordAnswer extends UseCase<RecordParams, List<KanjiProgress>> {
  RecordAnswer(this._repository);
  final ProgressRepository _repository;

  @override
  Future<List<KanjiProgress>> call([RecordParams? params]) async {
    final p = params!;
    final result = [...p.pool];
    final i = result.indexWhere((e) => e.literal == p.literal);
    var target = result[i];
    final wasMastered = target.status == ProgressStatus.mastered;

    if (p.correct) {
      final next = (target.hitCount + 1).clamp(0, kMasteryTarget);
      target = target.copyWith(
        hitCount: next,
        timesSeen: target.timesSeen + 1,
        timesCorrect: target.timesCorrect + 1,
        status: next >= kMasteryTarget ? ProgressStatus.mastered : ProgressStatus.learning,
        lastSeenAt: DateTime.now(),
      );
      result[i] = target;
      if (target.status == ProgressStatus.mastered) {
        final lockedIdx = result.indexWhere((e) => e.status == ProgressStatus.locked);
        if (lockedIdx != -1) {
          result[lockedIdx] = result[lockedIdx].copyWith(status: ProgressStatus.learning);
        }
      }
    } else {
      final next = (target.hitCount - 1).clamp(0, kMasteryTarget);
      target = target.copyWith(
        hitCount: next,
        timesSeen: target.timesSeen + 1,
        timesWrong: target.timesWrong + 1,
        status: ProgressStatus.learning, // miss always (re)enters learning
        lastSeenAt: DateTime.now(),
      );
      result[i] = target;
      // wasMastered demotion is implicit: status set to learning above.
    }

    await _repository.upsertAll(result);
    return result;
  }
}
```
Put constants in `features/progress/domain/lib/constants.dart` and export from the barrel.

- [ ] **Step 5: Run RecordAnswer tests**

Run: `cd kanjipro && flutter test features/progress/domain/test/usecases/record_answer_test.dart`
Expected: 3 PASS.

- [ ] **Step 6: Test `SelectNextKanji` — weighting + reminders (seeded Random)**
```dart
// features/progress/domain/test/usecases/select_next_kanji_test.dart
import 'dart:math';
import 'package:kanji_domain/kanji_domain.dart';
import 'package:progress_domain/progress_domain.dart';
import 'package:flutter_test/flutter_test.dart';

KanjiProgress p(String l, ProgressStatus s, int h) => KanjiProgress(
    literal: l, level: JlptLevel.n5, status: s, hitCount: h,
    timesSeen: 0, timesCorrect: 0, timesWrong: 0, lastSeenAt: null);

void main() {
  test('only mastered + learning are eligible, never locked', () {
    final pool = [
      p('L', ProgressStatus.locked, 0),
      p('A', ProgressStatus.learning, 2),
    ];
    final picks = {
      for (var i = 0; i < 50; i++)
        SelectNextKanji()(SelectParams(pool: pool, lastShown: null, random: Random(i)))
    };
    expect(picks, isNot(contains('L')));
    expect(picks, contains('A'));
  });

  test('lower hitCount is favored over higher across many draws', () {
    final pool = [
      p('LOW', ProgressStatus.learning, 0),
      p('HIGH', ProgressStatus.learning, kMasteryTarget - 1),
    ];
    var low = 0;
    for (var i = 0; i < 400; i++) {
      if (SelectNextKanji()(SelectParams(pool: pool, lastShown: null, random: Random(i))) == 'LOW') {
        low++;
      }
    }
    expect(low, greaterThan(200)); // weighted toward LOW
  });

  test('returns null for empty/all-locked pool', () {
    expect(
      SelectNextKanji()(SelectParams(
          pool: [p('L', ProgressStatus.locked, 0)], lastShown: null, random: Random(1))),
      isNull,
    );
  });
}
```

- [ ] **Step 7: Implement `SelectNextKanji`**
```dart
import 'dart:math';
import '../models/kanji_progress.dart';
import '../models/progress_status.dart';
import '../constants.dart';

class SelectParams {
  const SelectParams({required this.pool, required this.lastShown, required this.random});
  final List<KanjiProgress> pool;
  final String? lastShown;
  final Random random;
}

class SelectNextKanji {
  String? call(SelectParams params) {
    final learning =
        params.pool.where((e) => e.status == ProgressStatus.learning).toList();
    final mastered =
        params.pool.where((e) => e.status == ProgressStatus.mastered).toList();
    if (learning.isEmpty && mastered.isEmpty) return null;

    // Reminder branch: with REMINDER_WEIGHT probability, pick a mastered one.
    if (mastered.isNotEmpty &&
        (learning.isEmpty || params.random.nextDouble() < kReminderWeight)) {
      return mastered[params.random.nextInt(mastered.length)].literal;
    }

    // Difficulty-weighted pick among learning: weight = (target - hitCount) + 1.
    final weights = <int>[];
    var total = 0;
    for (final e in learning) {
      final w = (kMasteryTarget - e.hitCount) + 1;
      weights.add(w);
      total += w;
    }
    var roll = params.random.nextInt(total);
    for (var i = 0; i < learning.length; i++) {
      roll -= weights[i];
      if (roll < 0) {
        final pick = learning[i].literal;
        // avoid immediate repeat unless it's the only learning option
        if (pick == params.lastShown && learning.length > 1) {
          return learning[(i + 1) % learning.length].literal;
        }
        return pick;
      }
    }
    return learning.last.literal;
  }
}
```

- [ ] **Step 8: Implement `EnsurePoolInitialized` + `GetLevelProgress`**

`EnsurePoolInitialized` (`EnsureParams { JlptLevel level; List<Kanji> levelKanji; }`): loads existing progress via repo; for any kanji with no record, create `locked`; then promote up to `kActivePoolSize` (in level order) to `learning` if fewer than that are currently `learning`/`mastered`; `upsertAll`; return the pool. `GetLevelProgress` aggregates counts into `LevelProgress`. Add a focused test for `EnsurePoolInitialized` (empty repo → first 10 become learning, rest locked).

- [ ] **Step 9: Barrel + pubspec, run all domain tests**

`progress_domain.dart` exports models/repositories/usecases/constants. pubspec deps: `core`, `kanji_domain` (path); dev `flutter_test`, `mocktail`.
Run: `cd kanjipro && flutter test features/progress/domain`
Expected: all PASS.

- [ ] **Step 10: Commit**
```bash
cd kanjipro && git add features/progress/domain
git commit -m "feat: add progress domain with reinforcement scheduler use cases"
```

---

### Task 7: `progress` feature — data (ObjectBox persistence)

**Files:**
- Create: `kanjipro/features/progress/data/lib/entities/kanji_progress_entity.dart`
- Create: `datasources/progress_local_data_source.dart`, `repositories/progress_repository_impl.dart`
- Create: `di/progress_data_module.dart`, barrels, pubspec, `features/progress/lib/progress.dart`
- Test: `kanjipro/features/progress/data/test/...`

**Interfaces:**
- Consumes: `KanjiProgress`, `ProgressStatus`, `ProgressRepository`, `JlptLevel` (Tasks 4, 6).
- Produces: `@Entity() class KanjiProgressEntity` (id int, `@Unique() literal`, `levelId` String, `statusIndex` int, `hitCount`, stats, `lastSeenMs` int?) with `toDomain()`/`fromDomain()`; `class ProgressLocalDataSource` wrapping a `Box<KanjiProgressEntity>`; `class ProgressRepositoryImpl implements ProgressRepository`.

- [ ] **Step 1: Test entity ↔ domain mapping** (pure, no ObjectBox runtime)
```dart
// features/progress/data/test/entities/kanji_progress_entity_test.dart
import 'package:kanji_domain/kanji_domain.dart';
import 'package:progress_domain/progress_domain.dart';
import 'package:progress_data/progress_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('round-trips domain <-> entity', () {
    final domain = KanjiProgress(
      literal: '日', level: JlptLevel.n5, status: ProgressStatus.learning,
      hitCount: 3, timesSeen: 5, timesCorrect: 4, timesWrong: 1, lastSeenAt: null);
    final entity = KanjiProgressEntity.fromDomain(domain);
    final back = entity.toDomain();
    expect(back.literal, '日');
    expect(back.level, JlptLevel.n5);
    expect(back.status, ProgressStatus.learning);
    expect(back.hitCount, 3);
    expect(back.timesCorrect, 4);
  });
}
```

- [ ] **Step 2: Create `KanjiProgressEntity`**
```dart
import 'package:objectbox/objectbox.dart';
import 'package:kanji_domain/kanji_domain.dart';
import 'package:progress_domain/progress_domain.dart';

@Entity()
class KanjiProgressEntity {
  KanjiProgressEntity({
    this.id = 0,
    required this.literal,
    required this.levelId,
    required this.statusIndex,
    required this.hitCount,
    required this.timesSeen,
    required this.timesCorrect,
    required this.timesWrong,
    this.lastSeenMs,
  });

  @Id()
  int id;
  @Unique()
  String literal;
  String levelId;
  int statusIndex;
  int hitCount;
  int timesSeen;
  int timesCorrect;
  int timesWrong;
  int? lastSeenMs;

  factory KanjiProgressEntity.fromDomain(KanjiProgress p) => KanjiProgressEntity(
        literal: p.literal,
        levelId: p.level.id,
        statusIndex: p.status.index,
        hitCount: p.hitCount,
        timesSeen: p.timesSeen,
        timesCorrect: p.timesCorrect,
        timesWrong: p.timesWrong,
        lastSeenMs: p.lastSeenAt?.millisecondsSinceEpoch,
      );

  KanjiProgress toDomain() => KanjiProgress(
        literal: literal,
        level: JlptLevel.fromId(levelId),
        status: ProgressStatus.values[statusIndex],
        hitCount: hitCount,
        timesSeen: timesSeen,
        timesCorrect: timesCorrect,
        timesWrong: timesWrong,
        lastSeenAt: lastSeenMs == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(lastSeenMs!),
      );
}
```

- [ ] **Step 3: Create data source + repository impl**

`ProgressLocalDataSource` holds a `Box<KanjiProgressEntity>`; methods `List<KanjiProgressEntity> forLevel(String levelId)` (query `levelId.equals`), `void putAll(List<KanjiProgressEntity>)`, `void put(KanjiProgressEntity)` — preserving existing `id` by looking up via the `literal` unique index before put. `ProgressRepositoryImpl` maps domain↔entity and delegates. (No try/catch; ObjectBox throws are surfaced.)

- [ ] **Step 4: ObjectBox init + DI module + build_runner**

`di/progress_data_module.dart`: `@module` async provider for `Store` (open via generated `openStore()`), `Box<KanjiProgressEntity>`, `ProgressLocalDataSource`, and `ProgressRepository`. Barrel `progress_data.dart` exports entities/datasources/repositories. `features/progress/lib/progress.dart` re-exports `progress_domain` + `progress_data`. pubspec deps: `core`, `kanji_domain`, `progress_domain`, `objectbox`, `objectbox_flutter_libs`, `injectable`; dev `build_runner`, `objectbox_generator`, `flutter_test`.
Run: `cd kanjipro && dart run build_runner build --delete-conflicting-outputs` (generates `objectbox.g.dart` + `objectbox-model.json`).

- [ ] **Step 5: Run tests**

Run: `cd kanjipro && flutter test features/progress/data`
Expected: mapping test PASS.

- [ ] **Step 6: Commit**
```bash
cd kanjipro && git add features/progress
git commit -m "feat: add progress data layer (objectbox persistence)"
```

---

### Task 8: `quiz` feature — domain (GenerateQuiz, GradeAnswer)

**Files:**
- Create: `kanjipro/features/quiz/domain/lib/models/` — `quiz_mode.dart`, `quiz_question.dart`
- Create: `usecases/generate_quiz.dart`, `usecases/grade_answer.dart`, barrel, pubspec, `features/quiz/lib/quiz.dart`
- Test: `kanjipro/features/quiz/domain/test/usecases/*_test.dart`

**Interfaces:**
- Consumes: `Kanji`, `JlptLevel` (Task 4); `KanjiProgress`, `SelectNextKanji`, `SelectParams` (Task 6).
- Produces:
  - `enum QuizMode { onReading, kunReading, meaning }` with `List<String> answersOf(Kanji k)` (onReadings / kunReadings / meanings).
  - `class QuizQuestion { final Kanji kanji; final QuizMode mode; final List<String> options; final int correctIndex; }`
  - `class GenerateQuiz` — `GenerateQuiz(SelectNextKanji)`, signature `QuizQuestion? call(GenerateParams)` where `GenerateParams { List<Kanji> levelKanji; List<KanjiProgress> pool; QuizMode mode; String? lastShown; Random random; }`. Picks target via `SelectNextKanji`; if target lacks answers for the mode, retries with remaining eligible; builds 4 unique options (1 correct + 3 distractors sampled from other kanji's answers of the same mode, falling back to any kanji if scarce); shuffles; sets `correctIndex`.
  - `class GradeAnswer` — `bool call(GradeParams)` where `GradeParams { QuizQuestion question; int selectedIndex; }` → `selectedIndex == correctIndex`.

- [ ] **Step 1: Test `GradeAnswer` + `QuizMode.answersOf`**
```dart
// features/quiz/domain/test/usecases/grade_answer_test.dart
import 'package:kanji_domain/kanji_domain.dart';
import 'package:quiz_domain/quiz_domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const k = Kanji(literal: '日', onReadings: ['ニチ'], kunReadings: ['ひ'],
      meanings: ['day'], jlptLevel: JlptLevel.n5, strokeCount: 4);

  test('answersOf returns mode-specific answers', () {
    expect(QuizMode.onReading.answersOf(k), ['ニチ']);
    expect(QuizMode.meaning.answersOf(k), ['day']);
  });

  test('GradeAnswer compares selected vs correct index', () {
    final q = QuizQuestion(kanji: k, mode: QuizMode.meaning,
        options: const ['day', 'one', 'water', 'fire'], correctIndex: 0);
    expect(GradeAnswer()(GradeParams(question: q, selectedIndex: 0)), true);
    expect(GradeAnswer()(GradeParams(question: q, selectedIndex: 2)), false);
  });
}
```

- [ ] **Step 2: Create models** (`quiz_mode.dart` with `answersOf`, `quiz_question.dart`).

- [ ] **Step 3: Implement `GradeAnswer`** (arrow): `bool call(GradeParams p) => p.selectedIndex == p.question.correctIndex;`

- [ ] **Step 4: Test `GenerateQuiz` — 4 unique options incl. correct**
```dart
// features/quiz/domain/test/usecases/generate_quiz_test.dart
import 'dart:math';
import 'package:kanji_domain/kanji_domain.dart';
import 'package:progress_domain/progress_domain.dart';
import 'package:quiz_domain/quiz_domain.dart';
import 'package:flutter_test/flutter_test.dart';

Kanji k(String lit, String meaning) => Kanji(literal: lit, onReadings: ['オ$lit'],
    kunReadings: ['ku$lit'], meanings: [meaning], jlptLevel: JlptLevel.n5, strokeCount: 1);
KanjiProgress prog(String l) => KanjiProgress(literal: l, level: JlptLevel.n5,
    status: ProgressStatus.learning, hitCount: 0, timesSeen: 0, timesCorrect: 0,
    timesWrong: 0, lastSeenAt: null);

void main() {
  test('builds a 4-option meaning question with the correct answer present', () {
    final kanji = [k('日','day'), k('一','one'), k('水','water'), k('火','fire'), k('木','tree')];
    final pool = kanji.map((e) => prog(e.literal)).toList();
    final q = GenerateQuiz(SelectNextKanji())(GenerateParams(
      levelKanji: kanji, pool: pool, mode: QuizMode.meaning,
      lastShown: null, random: Random(7)))!;
    expect(q.options.length, 4);
    expect(q.options.toSet().length, 4); // unique
    expect(q.options[q.correctIndex], q.kanji.meanings.first);
  });
}
```

- [ ] **Step 5: Implement `GenerateQuiz`** to satisfy the test (target via `SelectNextKanji`; skip targets with empty `answersOf`; distractors unique, same mode, fallback to any kanji; shuffle with the provided `Random`; compute `correctIndex`). Keep it a single focused class.

- [ ] **Step 6: Barrel + pubspec, run tests**

`quiz_domain.dart` exports models/usecases. pubspec deps: `core`, `kanji_domain`, `progress_domain`; dev `flutter_test`. `features/quiz/lib/quiz.dart` re-exports `quiz_domain`.
Run: `cd kanjipro && flutter test features/quiz`
Expected: all PASS.

- [ ] **Step 7: Commit**
```bash
cd kanjipro && git add features/quiz
git commit -m "feat: add quiz domain (generate + grade use cases)"
```

---

### Task 9: App shell — DI, routes, theme, flavors, main

**Files:**
- Create: `kanjipro/lib/di/injection.dart` (+ generated `injection.config.dart`)
- Create: `kanjipro/lib/routes/app_router.dart` (+ generated `app_router.gr.dart`)
- Create: `kanjipro/lib/app.dart`, `kanjipro/lib/main.dart` (replace default), `main_dev.dart`
- Modify: `kanjipro/pubspec.yaml` (add all feature + ui path deps)
- Test: `kanjipro/test/di_test.dart` (smoke: `configureDependencies()` resolves repositories)

**Interfaces:**
- Consumes: every feature/ui package barrel.
- Produces: `final getIt = GetIt.instance;` + `@InjectableInit() Future<void> configureDependencies()`; `AppRouter` with routes `HomeRoute`, `StudyRoute(level)`, `QuizRoute(level, mode)`, `ResultsRoute(...)` (added as UI lands).

- [ ] **Step 1: Add path deps** for `core`, `common`, `kanji`, `progress`, `quiz`, and the ui modules to root pubspec; `flutter pub get`.

- [ ] **Step 2: Create `injection.dart`** with `@InjectableInit()` and async init (ObjectBox module is async). Run `dart run build_runner build --delete-conflicting-outputs`.

- [ ] **Step 3: Create `app_router.dart`** (auto_route) with the `HomeRoute` initial; regenerate.

- [ ] **Step 4: Create `app.dart` + `main.dart`**

`KanjiProApp` is a `MaterialApp.router` using `AppTheme.light()/dark()`, `AppLocalizations` delegates, `themeMode: ThemeMode.system`, `routerConfig: getIt<AppRouter>().config()`. `main.dart`: `WidgetsFlutterBinding.ensureInitialized(); await configureDependencies(); runApp(const KanjiProApp());`.

- [ ] **Step 5: DI smoke test**
```dart
// test/di_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:kanji_pro/di/injection.dart';
import 'package:kanji_domain/kanji_domain.dart';

void main() {
  testWidgets('DI resolves KanjiRepository', (tester) async {
    await configureDependencies();
    expect(getIt.isRegistered<KanjiRepository>(), true);
  });
}
```
Run: `cd kanjipro && flutter test test/di_test.dart` → PASS. (If ObjectBox store init fails under test, guard the smoke test to the non-ObjectBox deps and note it.)

- [ ] **Step 6: Commit**
```bash
cd kanjipro && git add lib pubspec.yaml test/di_test.dart
git commit -m "feat: add app shell (di, routing, theme, flavors)"
```

---

### Task 10: `home_ui` — level selection with progress

**Files:**
- Create: `kanjipro/ui/home_ui/lib/...` via `/new-ui-module home` then edit
- Create: `home_state.dart`, `home_bloc.dart` (Cubit), `home_screen.dart`, barrel, pubspec
- Test: `kanjipro/ui/home_ui/test/home_bloc_test.dart`

**Interfaces:**
- Consumes: `GetAllLevels`, `GetLevelProgress`, `JlptLevel`, `LevelProgress`.
- Produces: `HomeRoute`; `HomeCubit` exposing `sealed HomeState { Loading, Success(List<LevelProgress>), Error }`.

- [ ] **Step 1: Test `HomeCubit` emits Success with level progress** (mock use cases, `bloc_test` or manual). Provide concrete test asserting `Loading → Success` with the mocked list.
- [ ] **Step 2: Create state (sealed), cubit (starts Loading, loads levels+progress), screen (`@RoutePage`, `BlocBuilder`, list of level cards showing `percent`).**
- [ ] **Step 3: Wire `HomeRoute` into `AppRouter`; register cubit + use cases in DI; build_runner.**
- [ ] **Step 4: Run `flutter test ui/home_ui` → PASS; `flutter analyze`.**
- [ ] **Step 5: Commit** `feat: add home ui (level selection)`.

---

### Task 11: `study_ui` — flashcards + TTS

**Files:**
- Create: `kanjipro/ui/study_ui/lib/...` (`study_state.dart`, `study_bloc.dart`, `study_screen.dart`, barrel, pubspec)
- Test: `kanjipro/ui/study_ui/test/study_bloc_test.dart`

**Interfaces:**
- Consumes: `GetKanjiByLevel`, `Kanji`, `JlptLevel`, `TtsService`.
- Produces: `StudyRoute(level)`; `StudyCubit` with `sealed StudyState { Loading, Success(List<Kanji>), Error }`; screen renders a swipeable flashcard (literal big; on, kun, meaning rows; speak button calling `TtsService.speak(first on/kun reading)`, disabled + `ttsUnavailable` hint when `isJapaneseAvailable()` is false).

- [ ] **Step 1: Test `StudyCubit` Loading→Success(list)** with mock `GetKanjiByLevel`.
- [ ] **Step 2: Create state, cubit, screen (flashcard UI + TTS button with availability gate).**
- [ ] **Step 3: Wire `StudyRoute`; DI; build_runner.**
- [ ] **Step 4: `flutter test ui/study_ui` PASS; `flutter analyze`.**
- [ ] **Step 5: Commit** `feat: add study ui (flashcards with tts)`.

---

### Task 12: `quiz_ui` — mode select → MC quiz → results, wired to scheduler

**Files:**
- Create: `kanjipro/ui/quiz_ui/lib/...` (`quiz_state.dart`, `quiz_bloc.dart`, `quiz_screen.dart`, `quiz_mode_select_screen.dart`, `results_screen.dart`, barrel, pubspec)
- Test: `kanjipro/ui/quiz_ui/test/quiz_bloc_test.dart`

**Interfaces:**
- Consumes: `GetKanjiByLevel`, `EnsurePoolInitialized`, `GenerateQuiz`, `GradeAnswer`, `RecordAnswer`, `QuizMode`, `QuizQuestion`, `JlptLevel`.
- Produces: `QuizModeSelectRoute(level)`, `QuizRoute(level, mode)`, `ResultsRoute(level, total, correct)`; `QuizCubit` driving: init pool → generate question → on answer `GradeAnswer` + `RecordAnswer` (updates in-memory pool) → next question; tracks session totals; ends to results after a session length (e.g. 10 questions) or user exit.

- [ ] **Step 1: Test the cubit happy path** — given mocked use cases, `answer(index)` records and advances to a new `QuizQuestion`; correct/incorrect counters update. Use a seeded `Random` injected into the cubit so generation is deterministic.
- [ ] **Step 2: Create state (`sealed QuizState { Loading, Question(QuizQuestion, answered?, lastCorrect?), Finished(total, correct), Error }`), cubit (holds `pool`, `random`, `lastShown`, session counters; methods `start`, `answer`, `next`), mode-select screen, quiz screen (4 option buttons; show correct/wrong feedback then advance), results screen.**
- [ ] **Step 3: Wire routes; register cubit + all use cases (inject a `Random()` provider) in DI; build_runner.**
- [ ] **Step 4: `flutter test ui/quiz_ui` PASS; full `flutter analyze` + `flutter test` green across the app.**
- [ ] **Step 5: Commit** `feat: add quiz ui (modes, multiple choice, results)`.

---

### Task 13: Vertical-slice smoke + docs

**Files:**
- Modify: `kanjipro/README.md` (features, setup, data attribution, screenshots placeholder)
- Test: `kanjipro/test/app_smoke_test.dart`

- [ ] **Step 1: App smoke test** — `testWidgets` pumps `KanjiProApp` after `configureDependencies()`, expects the home screen to render level cards (mock or real asset). Keep resilient to ObjectBox in test (use an in-memory store or skip-tag if unavailable).
- [ ] **Step 2: Update `kanjipro/README.md`** — what the app is, supported platforms, `flutter pub get` + `dart run build_runner build` + `flutter run`, and the CC BY-SA data attribution.
- [ ] **Step 3: Final verification** — `cd kanjipro && flutter analyze && flutter test` all green.
- [ ] **Step 4: Update spec status** — set `Status: Implemented` in `docs/superpowers/specs/2026-06-19-kanjipro-app-design.md` (meta-repo commit).
- [ ] **Step 5: Commit** (kanjipro) `docs: document KanjiPro app and add smoke test`; then in the meta-repo, `git add kanjipro` to record the submodule pointer and commit `chore: update kanjipro submodule pointer`.

---

## Notes for Implementers

- Use the `/new-datasource`, `/new-repository`, `/new-usecase`, `/new-ui-module` commands for
  module skeletons; this plan supplies the package names, logic, and tests to fill in.
- Per-package `flutter test <path>` keeps cycles fast; run the full suite before each commit.
- ObjectBox requires `dart run build_runner build` before first compile and after entity changes.
- If a test needs ObjectBox at runtime and the test environment lacks native libs, prefer testing
  the repository against a mocked data source (as in Task 7 Step 1) rather than opening a Store.
