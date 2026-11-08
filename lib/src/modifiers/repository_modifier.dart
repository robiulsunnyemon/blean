import 'dart:io';
import 'package:path/path.dart' as p;
import '../utils/logger.dart';
import '../utils/string_case.dart';

/// Updates Domain Repository Interface, Data Repository Implementation, and DI
/// when a new UseCase is created via `bclean create usecase:<name> on <feature>`.
class RepositoryModifier {
  static Future<void> injectUseCase({
    required String projectDir,
    required String projectName,
    required StringCase feature,
    required StringCase useCase,
  }) async {
    final featurePascal = feature.pascalCase;
    final featureSnake = feature.snakeCase;
    final methodCamel = useCase.camelCase;
    final useCasePascal = useCase.pascalCase;
    final useCaseSnake = useCase.snakeCase;

    final featureDir = p.join(projectDir, 'lib', 'features', featureSnake);

    // 1. Update Domain Repository Interface
    final repoInterfacePath = p.join(
      featureDir,
      'domain',
      'repositories',
      '${featureSnake}_repository.dart',
    );
    final repoInterfaceFile = File(repoInterfacePath);
    if (await repoInterfaceFile.exists()) {
      var content = await repoInterfaceFile.readAsString();
      final methodSignature =
          'Future<Either<Failure, ${featurePascal}Entity>> $methodCamel(String id);';
      if (!content.contains('$methodCamel(')) {
        final lastBrace = content.lastIndexOf('}');
        if (lastBrace != -1) {
          content =
              '${content.substring(0, lastBrace)}  $methodSignature\n}\n';
          await repoInterfaceFile.writeAsString(content);
          CliLogger.modified(
            p.relative(repoInterfacePath, from: projectDir),
          );
        }
      }
    }

    // 2. Update Data Repository Implementation
    final repoImplPath = p.join(
      featureDir,
      'data',
      'repositories',
      '${featureSnake}_repository_impl.dart',
    );
    final repoImplFile = File(repoImplPath);
    if (await repoImplFile.exists()) {
      var content = await repoImplFile.readAsString();
      if (!content.contains('Future<Either<Failure, ${featurePascal}Entity>> $methodCamel(')) {
        final lastBrace = content.lastIndexOf('}');
        if (lastBrace != -1) {
          final methodImpl = '''

  @override
  Future<Either<Failure, ${featurePascal}Entity>> $methodCamel(String id) async {
    if (await networkInfo.isConnected) {
      try {
        final remoteData = await remoteDataSource.get$featurePascal(id);
        return Right(remoteData);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      }
    } else {
      return const Left(NetworkFailure());
    }
  }
}
''';
          content = content.substring(0, lastBrace).trimRight() + methodImpl;
          await repoImplFile.writeAsString(content);
          CliLogger.modified(p.relative(repoImplPath, from: projectDir));
        }
      }
    }

    // 3. Register UseCase in injection_container.dart
    final diPath = p.join(projectDir, 'lib', 'injection_container.dart');
    final diFile = File(diPath);
    if (await diFile.exists()) {
      var diContent = await diFile.readAsString();
      final importLine =
          "import 'package:$projectName/features/$featureSnake/domain/usecases/${useCaseSnake}_usecase.dart';";
      final registrationLine =
          '  sl.registerLazySingleton(() => ${useCasePascal}UseCase(sl()));';

      var updated = false;
      if (!diContent.contains(importLine) &&
          diContent.contains('// [BCLEAN_IMPORTS]')) {
        diContent = diContent.replaceFirst(
          '// [BCLEAN_IMPORTS]',
          '$importLine\n// [BCLEAN_IMPORTS]',
        );
        updated = true;
      }

      if (!diContent.contains('${useCasePascal}UseCase(') &&
          diContent.contains('// [BCLEAN_FEATURES]')) {
        diContent = diContent.replaceFirst(
          '// [BCLEAN_FEATURES]',
          '$registrationLine\n  // [BCLEAN_FEATURES]',
        );
        updated = true;
      }

      if (updated) {
        await diFile.writeAsString(diContent);
        CliLogger.modified(p.relative(diPath, from: projectDir));
      }
    }
  }
}
