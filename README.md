# MoovieAi

Meta-repository for the Moovie ecosystem. Central hub for shared resources, AI-assisted development, and submodule management.

## Quick Start

Clone with submodules:
```bash
git clone --recurse-submodules https://github.com/mobyleOfficial/MoovieAi
cd MoovieAi
```

## What's Here

- **[moovie/](moovie)** — Flutter frontend (Android, iOS, Web)
- **[backend/](backend)** — Kotlin/Ktor API server
- **[research/](research)** — Design docs, API specs, architecture decisions
- **[plugins/](plugins)** — Claude Code extensions
- **[rules/](rules)** — Linting, formatting, AI guidelines
- **[skills/](skills)** — Custom Claude workflows

See [CLAUDE.md](CLAUDE.md) for ecosystem architecture and development workflows.

## Frontend (Moovie)

**Tech:** Flutter, Dart, BLoC, Clean Architecture

```bash
cd moovie
bundle install
flutter pub get
dart run build_runner build --delete-conflicting-outputs
bundle exec fastlane ios dev  # or android dev
```

See [moovie/README.md](moovie/README.md) for details.

## Backend (MoovieBackend)

**Tech:** Kotlin, Ktor, Koin, TMDB API

```bash
cd backend
export TMDB_API_KEY="your_bearer_token"
./gradlew run
```

Server runs on `http://localhost:8080`. See [backend/README.md](backend/README.md) for details.

## Working with Submodules

Update to latest:
```bash
git submodule update --remote
```

Develop in a submodule:
```bash
cd moovie  # or backend
git checkout main
git pull
cd ..
git add moovie
git commit -m "chore: update moovie reference"
git push
```

## Contributing

1. Make changes in child repos (moovie/ or backend/)
2. Commit and push in child repo
3. Update submodule reference in MoovieAi: `git add moovie`, `git commit`, `git push`
4. Add research docs, rules, or skills as needed

## Resources

- **TMDB API:** https://developer.themoviedb.org/
- **Flutter:** https://flutter.dev/
- **Ktor:** https://ktor.io/
- **BLoC:** https://bloclibrary.dev/

## License

See LICENSE file in each repo.
