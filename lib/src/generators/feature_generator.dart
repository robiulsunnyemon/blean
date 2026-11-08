import 'dart:io';
import 'package:path/path.dart' as p;
import '../modifiers/di_modifier.dart';
import '../modifiers/repository_modifier.dart';
import '../modifiers/router_modifier.dart';
import '../templates/data_templates.dart';
import '../templates/domain_templates.dart';
import '../templates/presentation_templates.dart';
import '../utils/file_helper.dart';
import '../utils/logger.dart';
import '../utils/string_case.dart';
import 'init_generator.dart';

/// Generates a full Clean Architecture feature or individual sub-components
/// (bloc, cubit, usecase, page).
class FeatureGenerator {
  static Future<void> generateFeature({
    required String projectDir,
    required String featureRawName,
    bool useCubit = false,
    bool includeLocal = true,
    bool overwrite = false,
  }) async {
    // Auto-initialize core, DI, router & main.dart if the user forgot to run `bclean init` first!
    final diFile = File(p.join(projectDir, 'lib', 'injection_container.dart'));
    final routerFile =
        File(p.join(projectDir, 'lib', 'core', 'router', 'app_router.dart'));
    if (!await diFile.exists() || !await routerFile.exists()) {
      CliLogger.info(
        'Core files not found. Auto-running `bclean init` first...',
      );
      await InitGenerator.generate(projectDir: projectDir);
    }

    final projectName = FileHelper.getProjectName(projectDir);
    final feature = StringCase(featureRawName);
    final snake = feature.snakeCase;
    final useCaseName = StringCase('get_$snake');

    CliLogger.info(
      'Creating feature "${feature.pascalCase}" (${useCubit ? 'Cubit' : 'BLoC'})...',
    );

    final featureDir = p.join(projectDir, 'lib', 'features', snake);

    final files = <String, String>{
      // Domain Layer
      p.join(featureDir, 'domain', 'entities', '${snake}_entity.dart'):
          DomainTemplates.entity(feature),
      p.join(featureDir, 'domain', 'repositories', '${snake}_repository.dart'):
          DomainTemplates.repositoryInterface(projectName, feature),
      p.join(featureDir, 'domain', 'usecases', 'get_${snake}_usecase.dart'):
          DomainTemplates.useCase(projectName, feature, useCaseName),

      // Data Layer
      p.join(featureDir, 'data', 'models', '${snake}_model.dart'):
          DataTemplates.model(projectName, feature),
      p.join(
        featureDir,
        'data',
        'datasources',
        '${snake}_remote_data_source.dart',
      ): DataTemplates.remoteDataSource(projectName, feature),
      if (includeLocal)
        p.join(
          featureDir,
          'data',
          'datasources',
          '${snake}_local_data_source.dart',
        ): DataTemplates.localDataSource(projectName, feature),
      p.join(
        featureDir,
        'data',
        'repositories',
        '${snake}_repository_impl.dart',
      ): DataTemplates.repositoryImpl(
        projectName,
        feature,
        includeLocal: includeLocal,
      ),

      // Presentation Layer
      if (useCubit) ...{
        p.join(featureDir, 'presentation', 'cubit', '${snake}_cubit.dart'):
            PresentationTemplates.cubit(projectName, feature, feature),
        p.join(featureDir, 'presentation', 'cubit', '${snake}_state.dart'):
            PresentationTemplates.blocState(feature, feature, isCubit: true),
      } else ...{
        p.join(featureDir, 'presentation', 'bloc', '${snake}_bloc.dart'):
            PresentationTemplates.bloc(projectName, feature, feature),
        p.join(featureDir, 'presentation', 'bloc', '${snake}_event.dart'):
            PresentationTemplates.blocEvent(feature),
        p.join(featureDir, 'presentation', 'bloc', '${snake}_state.dart'):
            PresentationTemplates.blocState(feature, feature),
      },
      p.join(featureDir, 'presentation', 'pages', '${snake}_page.dart'):
          PresentationTemplates.page(
        projectName,
        feature,
        useCubit: useCubit,
      ),
    };

    for (final entry in files.entries) {
      await FileHelper.writeFile(
        entry.key,
        entry.value,
        overwrite: overwrite,
        baseDir: projectDir,
      );
    }

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

    CliLogger.success('Feature "${feature.pascalCase}" created successfully!');
  }

  static Future<void> generateUseCase({
    required String projectDir,
    required String featureRawName,
    required String useCaseRawName,
    bool overwrite = false,
  }) async {
    final projectName = FileHelper.getProjectName(projectDir);
    final feature = StringCase(featureRawName);
    final useCase = StringCase(useCaseRawName);

    final filePath = p.join(
      projectDir,
      'lib',
      'features',
      feature.snakeCase,
      'domain',
      'usecases',
      '${useCase.snakeCase}_usecase.dart',
    );

    await FileHelper.writeFile(
      filePath,
      DomainTemplates.useCase(projectName, feature, useCase),
      overwrite: overwrite,
      baseDir: projectDir,
    );

    await RepositoryModifier.injectUseCase(
      projectDir: projectDir,
      projectName: projectName,
      feature: feature,
      useCase: useCase,
    );

    CliLogger.success(
      'UseCase "${useCase.pascalCase}UseCase" created and wired in feature "${feature.pascalCase}"!',
    );
  }

  static Future<void> generateBloc({
    required String projectDir,
    required String featureRawName,
    required String blocRawName,
    bool useCubit = false,
    bool overwrite = false,
  }) async {
    final projectName = FileHelper.getProjectName(projectDir);
    final feature = StringCase(featureRawName);
    final bloc = StringCase(blocRawName);
    final featureDir = p.join(projectDir, 'lib', 'features', feature.snakeCase);

    if (useCubit) {
      await FileHelper.writeFile(
        p.join(featureDir, 'presentation', 'cubit', '${bloc.snakeCase}_cubit.dart'),
        PresentationTemplates.cubit(projectName, feature, bloc),
        overwrite: overwrite,
        baseDir: projectDir,
      );
      await FileHelper.writeFile(
        p.join(featureDir, 'presentation', 'cubit', '${bloc.snakeCase}_state.dart'),
        PresentationTemplates.blocState(feature, bloc, isCubit: true),
        overwrite: overwrite,
        baseDir: projectDir,
      );
      CliLogger.success(
        'Cubit "${bloc.pascalCase}Cubit" created in feature "${feature.pascalCase}"!',
      );
    } else {
      await FileHelper.writeFile(
        p.join(featureDir, 'presentation', 'bloc', '${bloc.snakeCase}_bloc.dart'),
        PresentationTemplates.bloc(projectName, feature, bloc),
        overwrite: overwrite,
        baseDir: projectDir,
      );
      await FileHelper.writeFile(
        p.join(featureDir, 'presentation', 'bloc', '${bloc.snakeCase}_event.dart'),
        PresentationTemplates.blocEvent(bloc),
        overwrite: overwrite,
        baseDir: projectDir,
      );
      await FileHelper.writeFile(
        p.join(featureDir, 'presentation', 'bloc', '${bloc.snakeCase}_state.dart'),
        PresentationTemplates.blocState(feature, bloc),
        overwrite: overwrite,
        baseDir: projectDir,
      );
      CliLogger.success(
        'BLoC "${bloc.pascalCase}Bloc" created in feature "${feature.pascalCase}"!',
      );
    }
  }

  static Future<void> generatePage({
    required String projectDir,
    required String featureRawName,
    required String pageRawName,
    bool useCubit = false,
    bool overwrite = false,
  }) async {
    final projectName = FileHelper.getProjectName(projectDir);
    final feature = StringCase(featureRawName);
    final page = StringCase(pageRawName);
    final featureDir = p.join(projectDir, 'lib', 'features', feature.snakeCase);

    await FileHelper.writeFile(
      p.join(featureDir, 'presentation', 'pages', '${page.snakeCase}_page.dart'),
      PresentationTemplates.page(
        projectName,
        page,
        useCubit: useCubit,
      ),
      overwrite: overwrite,
      baseDir: projectDir,
    );

    await RouterModifier.registerRoute(
      projectDir: projectDir,
      projectName: projectName,
      feature: feature,
      pageName: page,
    );

    CliLogger.success(
      'Page "${page.pascalCase}Page" created in feature "${feature.pascalCase}"!',
    );
  }
}
