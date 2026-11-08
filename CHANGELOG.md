## 0.1.4

- **Real Internet Connectivity Check (`internet_connection_checker_plus`)**:
  - `bclean init` now adds `internet_connection_checker_plus` to `pubspec.yaml`, registers `InternetConnection` in `injection_container.dart`, and implements `NetworkInfoImpl.isConnected` using `connectionChecker.hasInternetAccess`.
- **Auto-Dispatch Initial Load Event in Pages**:
  - Generated Pages now automatically trigger `..add(const Load<Feature>Event(...))` (for BLoC) or `..load<Feature>(...)` (for Cubit) inside `BlocProvider`, so opening a page immediately loads data without staying stuck on the initial state.
- **Readable Entity Output (`stringify => true`)**:
  - Added `@override bool get stringify => true;` to all generated `Equatable` Entities and Models so `item.toString()` displays all field values cleanly in UI lists.
- **Full UseCase Auto-Wiring Across All Layers**:
  - `bclean create usecase:<name> on <feature>` now also injects the method signature and `@override` implementation into `<feature>_remote_data_source.dart` in addition to `Repository`, `RepositoryImpl`, and `injection_container.dart`.
- **Standalone BLoC/Cubit Auto-DI Registration**:
  - `bclean create bloc:<name> on <feature>` and `bclean create cubit:<name> on <feature>` now automatically register the new BLoC/Cubit in `lib/injection_container.dart`.
- **Smart Singular/Plural JSON Model Sync**:
  - `bclean generate model` automatically maps singular/plural JSON filenames (e.g., `post.json` on feature `posts`) to the feature's primary Entity and Model when `--name` is not specified.

## 0.1.3

- **Single Item & JSON List Support (`--list` / `-l`)**:
  - Added `--list` (`-l`) flag to `bclean create feature:<name>`, `bclean create usecase:<name>`, `bclean create bloc:<name>`, `bclean create cubit:<name>`, and `bclean create page:<name>` to generate `List<Entity>` return types, `NoParams` UseCases, and `ListView.builder` UI pages.
  - Added `static List<Model> fromJsonList(List<dynamic> jsonList)` to all generated Models alongside `factory Model.fromJson(Map<String, dynamic> json)`.
  - **Auto JSON List Detection in `bclean g model`**: When generating a model from a JSON file whose root is a JSON Array `[{...}]` and whose name matches the target feature (e.g., `bclean g model on posts with assets/posts.json`), `bclean` automatically upgrades the feature's DataSources, Repository, UseCase, BLoC/Cubit, and Page to `List<Entity>` mode.
  - Updated DataSource templates to use `Model.fromJson(const {})` and `Model.fromJsonList(const [])` placeholders so custom fields generated from JSON never break DataSource compilation.

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
