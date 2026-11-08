## 0.1.2

- **Default Starter Route**: `AppRouter.routes` now includes a default `'/'` starter route out-of-the-box so `MaterialApp` never throws an empty-routes assertion error if run before creating a feature.
- **Auto-Discovery & Auto-Init**:
  - Running `bclean create feature:<name>` before `bclean init` now automatically initializes `core/`, `injection_container.dart`, `app_router.dart`, and `main.dart`.
  - Running `bclean init` in a project that already has features inside `lib/features/` automatically discovers and registers all existing features in `injection_container.dart` and `app_router.dart`.

## 0.1.1

- **Auto `main.dart` Setup**: `bclean init` now automatically generates/updates `lib/main.dart` with `WidgetsFlutterBinding.ensureInitialized()`, `await di.initDependencies()`, and `AppRouter.routes` pre-configured so `GetIt` is always initialized before `runApp`.
- **Smart Initial Route**: `AppRouter.initial` automatically updates to the first created feature/page route so the app runs out-of-the-box without manual route edits.
- **Enhanced Documentation**: Expanded `README.md` with a step-by-step Quick Start guide, command reference table, architecture tree, and JSON-to-Model examples.

## 0.1.0

- Initial release of `bclean` CLI.
- Added `bclean init` command to scaffold Clean Architecture `core/` layer (`failures.dart`, `exceptions.dart`, `usecase.dart` with `dartz`, `network_info.dart`), `app_router.dart`, `injection_container.dart` (`get_it`), and auto-add required dependencies in `pubspec.yaml`.
- Added `bclean create feature:<name>` command to generate full Domain, Data, and Presentation layers (`BLoC` or `Cubit` via `--cubit`) with automatic DI and Router registration.
- Added sub-component generators: `bclean create usecase:<name> on <feature>`, `bclean create bloc:<name> on <feature>`, `bclean create cubit:<name> on <feature>`, and `bclean create page:<name> on <feature>`.
- Added `bclean generate model on <feature> with <path/to/file.json>` to automatically generate Domain Entities (`Equatable`) and Data Models (`fromJson`, `toJson`, `copyWith`) from JSON files.
