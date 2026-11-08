# bclean

A fast, `get_cli`-inspired CLI tool for Flutter & Dart to scaffold **Clean Architecture** projects with **BLoC / Cubit** state management and **dartz** (`Either<Failure, T>`) functional error handling.

## Installation (Local Development)

Activate globally from this directory:

```bash
dart pub global activate --source path .
```

## Commands & Usage

### 1. Initialize Clean Architecture Core (`bclean init`)
Generates:
- `lib/core/error/failures.dart` & `exceptions.dart`
- `lib/core/usecases/usecase.dart` (with `dartz` `Either<Failure, Type>`)
- `lib/core/network/network_info.dart`
- `lib/core/router/app_router.dart`
- `lib/injection_container.dart` (`get_it`)
- Automatically adds `flutter_bloc`, `equatable`, `dartz`, and `get_it` to `pubspec.yaml`.

```bash
bclean init
```

### 2. Create a Full Feature (`bclean create feature:<name>`)
Generates Entity, Repository Interface, UseCase, Model, Remote & Local DataSources, Repository Implementation, BLoC (Event + State) or Cubit, Page, and **auto-registers** everything in `injection_container.dart` and `app_router.dart`:

```bash
bclean create feature:auth
```

#### Options:
- Use **Cubit** instead of BLoC:
  ```bash
  bclean create feature:profile --cubit
  ```
- Skip `LocalDataSource`:
  ```bash
  bclean create feature:orders --no-local
  ```

### 3. Create Sub-Components inside an Existing Feature
- **UseCase** (Also auto-adds method to Domain `Repository`, Data `RepositoryImpl`, and `injection_container.dart`!):
  ```bash
  bclean create usecase:login on auth
  ```
- **BLoC / Cubit**:
  ```bash
  bclean create bloc:session on auth
  bclean create cubit:theme on settings
  ```
- **Page** (Also auto-registers route in `app_router.dart`):
  ```bash
  bclean create page:register on auth
  ```

### 4. Generate Domain Entity & Data Model from JSON (`bclean generate model`)
Parses any JSON file (including nested objects and arrays) and generates both the **Domain Entity** (`Equatable`) and **Data Model** (`fromJson`, `toJson`, `copyWith`):

```bash
bclean generate model on auth with assets/models/user_profile.json
```

Options:
- Custom model name: `--name custom_user`
- Generate only Data Model without Domain Entity: `--skip-entity`

### 5. Optional Project Configuration in `pubspec.yaml`
You can configure project-wide defaults in your Flutter project's `pubspec.yaml`:

```yaml
bclean:
  state_management: bloc # or cubit
  include_local: true
```
