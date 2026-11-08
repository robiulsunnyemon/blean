# bclean Example

## CLI Walkthrough

1. **Activate `bclean` globally:**
   ```bash
   dart pub global activate bclean
   ```

2. **Initialize Clean Architecture inside a Flutter project:**
   ```bash
   bclean init
   ```

3. **Create a new Feature (`auth`):**
   ```bash
   bclean create feature:auth
   ```

4. **Create an additional UseCase (`login`) inside `auth`:**
   ```bash
   bclean create usecase:login on auth
   ```

5. **Generate `Entity` and `Model` from a JSON file:**
   ```bash
   bclean generate model on auth with assets/user_profile.json
   ```

## Programmatic Example

Run the included Dart example directly:

```bash
dart run example/bclean_example.dart
```
