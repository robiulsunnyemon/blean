import 'package:path/path.dart' as p;
import '../modifiers/pubspec_modifier.dart';
import '../modifiers/router_modifier.dart';
import '../templates/core_templates.dart';
import '../utils/file_helper.dart';
import '../utils/logger.dart';

/// Generates the base Clean Architecture `core/` folder, `app_router.dart`,
/// `injection_container.dart`, and updates `pubspec.yaml` dependencies.
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
