## 0.1.0

- Initial release of `bclean` CLI.
- Added `bclean init` command to scaffold Clean Architecture `core/` layer (`failures.dart`, `exceptions.dart`, `usecase.dart` with `dartz`, `network_info.dart`), `app_router.dart`, `injection_container.dart` (`get_it`), and auto-add required dependencies in `pubspec.yaml`.
- Added `bclean create feature:<name>` command to generate full Domain, Data, and Presentation layers (`BLoC` or `Cubit` via `--cubit`) with automatic DI and Router registration.
- Added sub-component generators: `bclean create usecase:<name> on <feature>`, `bclean create bloc:<name> on <feature>`, `bclean create cubit:<name> on <feature>`, and `bclean create page:<name> on <feature>`.
- Added `bclean generate model on <feature> with <path/to/file.json>` to automatically generate Domain Entities (`Equatable`) and Data Models (`fromJson`, `toJson`, `copyWith`) from JSON files.
