# bclean 🚀

[![pub package](https://img.shields.io/pub/v/bclean.svg)](https://pub.dev/packages/bclean)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Dart 3](https://img.shields.io/badge/Dart-3.x-0175C2.svg)](https://dart.dev)

A fast, **`get_cli`-inspired CLI tool** for Flutter & Dart to scaffold **Clean Architecture** projects with **BLoC / Cubit** state management, **`get_it`** Dependency Injection, **`AppRouter`** navigation, and **`dartz`** (`Either<Failure, T>`) functional error handling.

---

## ✨ Key Features

- ⚡ **One-Command Project Setup (`bclean init`)**: Scaffolds `core/` (`failures`, `exceptions`, `usecase`, `network_info`, `app_router`), `injection_container.dart`, automatically configures `main.dart` with `await di.initDependencies()`, and adds required packages to `pubspec.yaml`.
- 🏗️ **Full Feature Scaffolding (`bclean create feature:<name>`)**: Generates all 3 Clean Architecture layers (**Domain**, **Data**, **Presentation**) in seconds.
- 📋 **Single Item & JSON List Support (`--list` / Auto-Detect)**:
  - Supports both **Single Object (`Entity`)** and **List of Objects (`List<Entity>`)** across DataSources, Repositories, UseCases (`NoParams`), BLoC/Cubit States, and `ListView.builder` Pages.
  - Every generated Model includes both `fromJson(Map<String, dynamic>)` and `fromJsonList(List<dynamic>)`.
  - `bclean g model` automatically detects whether your JSON file root is a Single Object `{...}` or a JSON Array `[{...}]` and updates the feature layers accordingly!
- 🔌 **Zero-Boilerplate Auto-Wiring**:
  - Automatically registers BLoCs/Cubits, UseCases, Repositories, and DataSources in `lib/injection_container.dart`.
  - Automatically registers page routes in `lib/core/router/app_router.dart`.
  - Creating a new UseCase (`bclean create usecase:<name> on <feature>`) automatically injects the method contract into the Domain Repository, the `@override` implementation into the Data Repository, and registers it in GetIt!
- 🧬 **JSON to Clean Architecture (`bclean generate model`)**: Converts any JSON file (including nested objects and arrays) into both a **Domain Entity** (`Equatable`) and a **Data Model** (`fromJson`, `fromJsonList`, `toJson`, `copyWith`).
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

---

### Step 2: Create a Feature (Single Item vs List)

#### Option A: Single Item Feature (e.g. `auth`, `profile`)
```bash
bclean create feature:auth
```

#### Option B: List Feature (e.g. `posts`, `products`, `orders`)
Use `--list` (or `-l`) when the feature fetches a `List` of items:
```bash
bclean create feature:posts --list --no-local
```

Now simply run your app:

```bash
flutter run
```

---

## 🛠️ Complete Command Reference

| Command | Alias | Description |
| :--- | :--- | :--- |
| `bclean init` | — | Initializes Clean Architecture `core/`, `injection_container.dart`, `app_router.dart`, `main.dart`, and `pubspec.yaml`. |
| `bclean create feature:<name>` | `bclean c feature:<name>` | Creates a complete feature (`Domain` + `Data` + `Presentation`) and wires DI & Routing. Add `--list` (`-l`) for `List<Entity>`, `--cubit` (`-c`) for Cubit, or `--no-local` to skip LocalDataSource. |
| `bclean create usecase:<name> on <feature>` | `bclean c usecase:<name> on <feature>` | Creates a UseCase and auto-updates the feature's `Repository`, `RepositoryImpl`, and `injection_container.dart`. Add `--list` (`-l`) if it returns `List<Entity>`. |
| `bclean create bloc:<name> on <feature>` | `bclean c bloc:<name> on <feature>` | Creates a new BLoC (`_bloc.dart`, `_event.dart`, `_state.dart`) inside the target feature. |
| `bclean create cubit:<name> on <feature>` | `bclean c cubit:<name> on <feature>` | Creates a new Cubit (`_cubit.dart`, `_state.dart`) inside the target feature. |
| `bclean create page:<name> on <feature>` | `bclean c page:<name> on <feature>` | Creates a new Page inside the feature and registers its route in `AppRouter`. |
| `bclean generate model on <feature> with <json>` | `bclean g model on <feature> with <json>` | Generates Domain `Entity` and Data `Model` (`fromJson` + `fromJsonList`) from a JSON file and auto-syncs List/Single mode. |

---

## 📖 Handling Single JSON Object `{}` vs JSON List `[{}]`

In real-world APIs, some endpoints return a **Single JSON Object `{...}`** (e.g., `/user/1`) while others return a **JSON List `[{...}, {...}]`** (e.g., `/posts`). `bclean` handles both effortlessly:

### Scenario 1: JSON List Response (`assets/posts.json`)
Suppose `assets/posts.json` contains a JSON Array:
```json
[
  {
    "userId": 1,
    "id": 1,
    "title": "Clean Architecture with BLoC",
    "body": "Generated automatically using bclean CLI."
  }
]
```

Run:
```bash
# 1. Create the posts feature
bclean c feature:posts --no-local

# 2. Generate Entity & Model from assets/posts.json
bclean g model on posts with assets/posts.json
```

Because `assets/posts.json` starts with `[ ... ]`, `bclean` **automatically**:
1. Generates `PostsEntity` and `PostsModel` (with both `PostsModel.fromJson(...)` and `PostsModel.fromJsonList(...)`).
2. Upgrades `PostsRemoteDataSource`, `PostsRepository`, `PostsRepositoryImpl`, `GetPostsUseCase`, `PostsBloc` (`PostsLoaded(List<PostsEntity> data)`), and `PostsPage` (`ListView.builder`) to use **`List<PostsEntity>`**!

In your `PostsRemoteDataSourceImpl`, you can parse the API response list in one line:
```dart
final response = await dio.get('https://jsonplaceholder.typicode.com/posts');
return PostsModel.fromJsonList(response.data as List<dynamic>);
```

---

### Scenario 2: Single JSON Object Response (`assets/user_profile.json`)
Suppose `assets/user_profile.json` contains a single JSON Object:
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
bclean g model on auth with assets/user_profile.json
```

In your `AuthRemoteDataSourceImpl`, parse the single object in one line:
```dart
final response = await dio.get('https://api.example.com/profile');
return UserProfileModel.fromJson(response.data as Map<String, dynamic>);
```

---

### Scenario 3: Both List & Single Item inside the Same Feature
What if a `posts` feature needs **both** a list of all posts AND a single post by ID?

```bash
# 1. Create the feature in List mode (generates getPosts() -> List<PostsEntity>)
bclean c feature:posts --list --no-local

# 2. Add a second UseCase for fetching a single post by ID (generates getPostById(String id) -> PostsEntity)
bclean c usecase:get_post_by_id on posts
```

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
│   └── posts/
│       ├── data/
│       │   ├── datasources/
│       │   │   └── posts_remote_data_source.dart
│       │   ├── models/
│       │   │   └── posts_model.dart
│       │   └── repositories/
│       │       └── posts_repository_impl.dart
│       ├── domain/
│       │   ├── entities/
│       │   │   └── posts_entity.dart
│       │   ├── repositories/
│       │   │   └── posts_repository.dart
│       │   └── usecases/
│       │       └── get_posts_usecase.dart
│       └── presentation/
│           ├── bloc/
│           │   ├── posts_bloc.dart
│           │   ├── posts_event.dart
│           │   └── posts_state.dart
│           └── pages/
│               └── posts_page.dart
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
