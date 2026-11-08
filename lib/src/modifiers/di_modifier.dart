import 'dart:io';
import 'package:path/path.dart' as p;
import '../utils/logger.dart';
import '../utils/string_case.dart';

/// Modifies `lib/injection_container.dart` to automatically register newly
/// created features (BLoC/Cubit, UseCases, Repository, DataSources).
class DiModifier {
  static const String _importMarker = '// [BCLEAN_IMPORTS]';
  static const String _featureMarker = '// [BCLEAN_FEATURES]';

  static Future<void> registerFeature({
    required String projectDir,
    required String projectName,
    required StringCase feature,
    required bool useCubit,
    required bool includeLocal,
  }) async {
    final diPath = p.join(projectDir, 'lib', 'injection_container.dart');
    final diFile = File(diPath);

    if (!await diFile.exists()) {
      CliLogger.warn(
        'lib/injection_container.dart not found. Run `bclean init` first to enable auto-DI registration.',
      );
      return;
    }

    var content = await diFile.readAsString();
    final pascal = feature.pascalCase;
    final snake = feature.snakeCase;
    final stateClass = useCubit ? '${pascal}Cubit' : '${pascal}Bloc';
    final stateFolder = useCubit ? 'cubit' : 'bloc';
    final stateFile = useCubit ? '${snake}_cubit.dart' : '${snake}_bloc.dart';

    // Avoid duplicate registration
    if (content.contains('registerFactory(() => $stateClass(')) {
      return;
    }

    final localImport = includeLocal
        ? "import 'package:$projectName/features/$snake/data/datasources/${snake}_local_data_source.dart';\n"
        : '';

    final newImports = '''
import 'package:$projectName/features/$snake/data/datasources/${snake}_remote_data_source.dart';
${localImport}import 'package:$projectName/features/$snake/data/repositories/${snake}_repository_impl.dart';
import 'package:$projectName/features/$snake/domain/repositories/${snake}_repository.dart';
import 'package:$projectName/features/$snake/domain/usecases/get_${snake}_usecase.dart';
import 'package:$projectName/features/$snake/presentation/$stateFolder/$stateFile';
$_importMarker''';

    final localRepoArg = includeLocal ? '      localDataSource: sl(),\n' : '';
    final localDsRegistration = includeLocal
        ? '\n  sl.registerLazySingleton<${pascal}LocalDataSource>(\n    () => const ${pascal}LocalDataSourceImpl(),\n  );'
        : '';

    final newRegistrations = '''
// Feature - ${feature.titleCase}
  // Bloc / Cubit
  sl.registerFactory(
    () => $stateClass(
      get${pascal}UseCase: sl(),
    ),
  );

  // UseCases
  sl.registerLazySingleton(() => Get${pascal}UseCase(sl()));

  // Repository
  sl.registerLazySingleton<${pascal}Repository>(
    () => ${pascal}RepositoryImpl(
      remoteDataSource: sl(),
$localRepoArg      networkInfo: sl(),
    ),
  );

  // DataSources
  sl.registerLazySingleton<${pascal}RemoteDataSource>(
    () => const ${pascal}RemoteDataSourceImpl(),
  );$localDsRegistration

  $_featureMarker''';

    if (content.contains(_importMarker) && content.contains(_featureMarker)) {
      content = content
          .replaceFirst(_importMarker, newImports)
          .replaceFirst(_featureMarker, newRegistrations);
      await diFile.writeAsString(content);
      CliLogger.modified(p.relative(diPath, from: projectDir));
    } else {
      CliLogger.warn(
        'Markers not found in lib/injection_container.dart. Skipping auto-DI registration.',
      );
    }
  }
}
