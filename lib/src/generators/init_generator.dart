import 'dart:io';
import 'package:path/path.dart' as p;
import '../modifiers/di_modifier.dart';
import '../modifiers/pubspec_modifier.dart';
import '../modifiers/router_modifier.dart';
import '../templates/core_templates.dart';
import '../utils/file_helper.dart';
import '../utils/logger.dart';
import '../utils/string_case.dart';

/// Generates the base Clean Architecture `core/` folder, `app_router.dart`,
/// `injection_container.dart`, `main.dart`, and updates `pubspec.yaml` dependencies.
class InitGenerator {
  static Future<void> generate({
    required String projectDir,
    bool overwrite = false,
    bool addPackages = true,
  }) async {
    final projectName = FileHelper.getProjectName(projectDir);
    CliLogger.info(
      'Initializing BLoC Clean Architecture (with dartz) in "$projectName"...',
    );

    final files = <String, String>{
      p.join(projectDir, 'lib', 'core', 'error', 'failures.dart'):
          CoreTemplates.failures(),
      p.join(projectDir, 'lib', 'core', 'error', 'exceptions.dart'):
          CoreTemplates.exceptions(),
      p.join(projectDir, 'lib', 'core', 'usecases', 'usecase.dart'):
          CoreTemplates.useCase(projectName),
      p.join(projectDir, 'lib', 'core', 'network', 'network_info.dart'):
          CoreTemplates.networkInfo(),
      p.join(projectDir, 'lib', 'core', 'router', 'app_router.dart'):
          RouterModifier.appRouterTemplate(),
      p.join(projectDir, 'lib', 'injection_container.dart'):
          CoreTemplates.injectionContainer(projectName),
    };

    for (final entry in files.entries) {
      await FileHelper.writeFile(
        entry.key,
        entry.value,
        overwrite: overwrite,
        baseDir: projectDir,
      );
    }

    // Always write/update main.dart during `bclean init` so DI (`initDependencies()`)
    // and `AppRouter` are automatically wired up just like `get_cli`.
    await FileHelper.writeFile(
      p.join(projectDir, 'lib', 'main.dart'),
      CoreTemplates.mainDart(projectName),
      overwrite: true,
      baseDir: projectDir,
    );

    // Auto-discover any existing features in `lib/features/` (in case the user
    // created features before running `bclean init`) and register them in DI & Router!
    final featuresDir = Directory(p.join(projectDir, 'lib', 'features'));
    if (await featuresDir.exists()) {
      final entities = await featuresDir.list().toList();
      for (final entity in entities) {
        if (entity is Directory) {
          final featureName = p.basename(entity.path);
          final feature = StringCase(featureName);
          final snake = feature.snakeCase;
          final useCubit = File(
            p.join(entity.path, 'presentation', 'cubit', '${snake}_cubit.dart'),
          ).existsSync();
          final includeLocal = File(
            p.join(
              entity.path,
              'data',
              'datasources',
              '${snake}_local_data_source.dart',
            ),
          ).existsSync();

          await DiModifier.registerFeature(
            projectDir: projectDir,
            projectName: projectName,
            feature: feature,
            useCubit: useCubit,
            includeLocal: includeLocal,
          );
          await RouterModifier.registerRoute(
            projectDir: projectDir,
            projectName: projectName,
            feature: feature,
          );
        }
      }
    }

    if (addPackages) {
      final added = await PubspecModifier.ensureDependencies(projectDir);
      if (added.isNotEmpty) {
        CliLogger.info(
          'Added dependencies to pubspec.yaml: ${added.join(', ')}',
        );
      }
    }

    CliLogger.success(
      'Clean Architecture Core initialized! Run `flutter pub get` to fetch packages.',
    );
  }
}
