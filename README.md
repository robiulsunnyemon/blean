# bclean 🚀

[![pub package](https://img.shields.io/pub/v/bclean.svg)](https://pub.dev/packages/bclean)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Dart 3](https://img.shields.io/badge/Dart-3.x-0175C2.svg)](https://dart.dev)

A fast, **`get_cli`-inspired CLI tool** for Flutter & Dart to scaffold **Clean Architecture** projects with **BLoC / Cubit** state management, **`get_it`** Dependency Injection, **`AppRouter`** navigation, and **`dartz`** (`Either<Failure, T>`) functional error handling.

---

## ✨ Key Features

- ⚡ **One-Command Project Setup (`bclean init`)**: Scaffolds `core/` (`failures`, `exceptions`, `usecase`, `network_info`, `app_router`), `injection_container.dart`, automatically configures `main.dart` with `await di.initDependencies()`, and adds required packages to `pubspec.yaml`.
- 🏗️ **Full Feature Scaffolding (`bclean create feature:<name>`)**: Generates all 3 Clean Architecture layers (**Domain**, **Data**, **Presentation**) in seconds.
- 🔌 **Zero-Boilerplate Auto-Wiring**:
  - Automatically registers BLoCs/Cubits, UseCases, Repositories, and DataSources in `lib/injection_container.dart`.
  - Automatically registers page routes in `lib/core/router/app_router.dart`.
  - Creating a new UseCase (`bclean create usecase:<name> on <feature>`) automatically injects the method contract into the Domain Repository, the `@override` implementation into the Data Repository, and registers it in GetIt!
- 🧬 **JSON to Clean Architecture (`bclean generate model`)**: Converts any JSON file (including nested objects and arrays) into both a **Domain Entity** (`Equatable`) and a **Data Model** (`fromJson`, `toJson`, `copyWith`).
- 🎛️ **Flexible State Management**: Supports both **BLoC** (default) and **Cubit** (`--cubit`).

---

## 📦 Installation

Activate `bclean` globally from `pub.dev`:

```bash
dart pub global activate bclean
```

Verify installation:

```bash
bclean --version
```

> **Note for Windows Users:** If `bclean` is not recognized in your terminal, ensure `%LOCALAPPDATA%\Pub\Cache\bin` (`C:\Users\<USERNAME>\AppData\Local\Pub\Cache\bin`) is added to your system `PATH`.

---

## 🚀 Quick Start (Step-by-Step User Guide)

### Step 1: Create a new Flutter project & initialize `bclean`

```bash
flutter create my_app
cd my_app

# Initialize Clean Architecture Core, DI, Router & main.dart
bclean init

# Fetch the newly added dependencies (flutter_bloc, dartz, equatable, get_it)
flutter pub get
```

What `bclean init` does automatically:
1. Adds `flutter_bloc`, `equatable`, `dartz`, and `get_it` to `pubspec.yaml`.
2. Creates `lib/core/error/failures.dart` & `exceptions.dart`.
3. Creates `lib/core/usecases/usecase.dart` (`UseCase<Type, Params>` & `NoParams`).
4. Creates `lib/core/network/network_info.dart`.
5. Creates `lib/core/router/app_router.dart`.
6. Creates `lib/injection_container.dart`.
7. Updates `lib/main.dart` with `await di.initDependencies()` and `AppRouter.routes` pre-configured!

---

### Step 2: Create your first Feature (`auth`)

```bash
bclean create feature:auth
```

This single command generates 11 files across **Domain**, **Data**, and **Presentation** layers, registers `AuthBloc`, `GetAuthUseCase`, `AuthRepository`, and DataSources inside `lib/injection_container.dart`, and sets `/auth` in `lib/core/router/app_router.dart`!

Now simply run your app:

```bash
flutter run
```

---

## 🛠️ Complete Command Reference

| Command | Alias | Description |
| :--- | :--- | :--- |
| `bclean init` | — | Initializes Clean Architecture `core/`, `injection_container.dart`, `app_router.dart`, `main.dart`, and `pubspec.yaml`. |
| `bclean create feature:<name>` | `bclean c feature:<name>` | Creates a complete feature (`Domain` + `Data` + `Presentation`) and wires DI & Routing. |
| `bclean create usecase:<name> on <feature>` | `bclean c usecase:<name> on <feature>` | Creates a UseCase and auto-updates the feature's `Repository`, `RepositoryImpl`, and `injection_container.dart`. |
| `bclean create bloc:<name> on <feature>` | `bclean c bloc:<name> on <feature>` | Creates a new BLoC (`_bloc.dart`, `_event.dart`, `_state.dart`) inside the target feature. |
| `bclean create cubit:<name> on <feature>` | `bclean c cubit:<name> on <feature>` | Creates a new Cubit (`_cubit.dart`, `_state.dart`) inside the target feature. |
| `bclean create page:<name> on <feature>` | `bclean c page:<name> on <feature>` | Creates a new Page inside the feature and registers its route in `AppRouter`. |
| `bclean generate model on <feature> with <json>` | `bclean g model on <feature> with <json>` | Generates Domain `Entity` and Data `Model` from a JSON file. |

---

## 📖 Detailed Usage Examples

### 1. Creating Features (BLoC vs Cubit)

```bash
# Default (BLoC + Remote & Local DataSources)
bclean create feature:user_auth

# Use Cubit instead of BLoC
bclean create feature:profile --cubit

# Skip LocalDataSource (Remote API only)
bclean create feature:orders --no-local
```

### 2. Adding a UseCase to an Existing Feature

```bash
bclean create usecase:login on auth
```

What happens behind the scenes:
- **Created:** `lib/features/auth/domain/usecases/login_usecase.dart` (`LoginUseCase` & `LoginParams`)
- **Updated:** `lib/features/auth/domain/repositories/auth_repository.dart` (adds `Future<Either<Failure, AuthEntity>> login(String id);`)
- **Updated:** `lib/features/auth/data/repositories/auth_repository_impl.dart` (adds `@override login(...)` implementation)
- **Updated:** `lib/injection_container.dart` (registers `sl.registerLazySingleton(() => LoginUseCase(sl()));`)

### 3. Adding Extra BLoCs, Cubits, or Pages to a Feature

```bash
# Add a new BLoC inside 'auth'
bclean create bloc:session on auth

# Add a new Cubit inside 'profile'
bclean create cubit:theme on profile

# Add a new Page inside 'auth' (auto-registered in AppRouter)
bclean create page:register on auth
```

Navigate to any generated page using `AppRouter`:

```dart
Navigator.pushNamed(context, AppRouter.register);
```

### 4. Generating Entity & Model from JSON

Suppose you have `assets/user_profile.json`:

```json
{
  "id": "u_101",
  "full_name": "Rahim Uddin",
  "age": 28,
  "is_verified": true,
  "roles": ["admin", "editor"],
  "address": {
    "city": "Dhaka",
    "zip_code": 1207
  }
}
```

Run:

```bash
bclean generate model on auth with assets/user_profile.json
```

**Options:**
- `--name <custom_name>`: Specify a custom class name (e.g., `--name auth_user`).
- `--skip-entity`: Generate only the Data Model without a Domain Entity.

This generates:
- `lib/features/auth/domain/entities/user_profile_entity.dart` (`UserProfileEntity` & nested `AddressEntity` extending `Equatable`)
- `lib/features/auth/data/models/user_profile_model.dart` (`UserProfileModel` & `AddressModel` with `fromJson`, `toJson`, and `copyWith`)

---

## 📂 Generated Project Architecture

```text
lib/
├── core/
│   ├── error/
│   │   ├── exceptions.dart
│   │   └── failures.dart
│   ├── network/
│   │   └── network_info.dart
│   ├── router/
│   │   └── app_router.dart
│   └── usecases/
│       └── usecase.dart
├── features/
│   └── auth/
│       ├── data/
│       │   ├── datasources/
│       │   │   ├── auth_local_data_source.dart
│       │   │   └── auth_remote_data_source.dart
│       │   ├── models/
│       │   │   └── auth_model.dart
│       │   └── repositories/
│       │       └── auth_repository_impl.dart
│       ├── domain/
│       │   ├── entities/
│       │   │   └── auth_entity.dart
│       │   ├── repositories/
│       │   │   └── auth_repository.dart
│       │   └── usecases/
│       │       └── get_auth_usecase.dart
│       └── presentation/
│           ├── bloc/
│           │   ├── auth_bloc.dart
│           │   ├── auth_event.dart
│           │   └── auth_state.dart
│           └── pages/
│               └── auth_page.dart
├── injection_container.dart
└── main.dart
```

---

## ⚙️ Optional Project Configuration (`pubspec.yaml`)

Avoid passing `--cubit` or `--no-local` every time by adding a `bclean:` section to your Flutter project's `pubspec.yaml`:

```yaml
bclean:
  state_management: cubit # 'bloc' (default) or 'cubit'
  include_local: false    # true (default) or false
```

---

## 🤝 Contributing & Issues

Contributions, issues, and feature requests are welcome!  
Feel free to check the [issues page](https://github.com/robiulsunnyemon/blean/issues).

## 📄 License

This project is licensed under the **MIT License** - see the [LICENSE](LICENSE) file for details.
