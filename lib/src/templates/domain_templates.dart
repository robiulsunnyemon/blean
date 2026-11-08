import '../utils/string_case.dart';

/// Templates for the Domain layer (Entities, Repository Interfaces, UseCases).
class DomainTemplates {
  static String entity(StringCase feature) {
    final pascal = feature.pascalCase;
    return '''
import 'package:equatable/equatable.dart';

class ${pascal}Entity extends Equatable {
  final String id;

  const ${pascal}Entity({
    required this.id,
  });

  @override
  bool get stringify => true;

  @override
  List<Object?> get props => [id];
}
''';
  }

  static String repositoryInterface(
    String projectName,
    StringCase feature, {
    bool isList = false,
  }) {
    final pascal = feature.pascalCase;
    final snake = feature.snakeCase;
    final returnType = isList ? 'List<${pascal}Entity>' : '${pascal}Entity';
    final params = isList ? '' : 'String id';

    return '''
import 'package:dartz/dartz.dart';
import 'package:$projectName/core/error/failures.dart';
import 'package:$projectName/features/$snake/domain/entities/${snake}_entity.dart';

abstract class ${pascal}Repository {
  Future<Either<Failure, $returnType>> get$pascal($params);
}
''';
  }

  static String useCase(
    String projectName,
    StringCase feature,
    StringCase useCaseName, {
    bool isList = false,
  }) {
    final featurePascal = feature.pascalCase;
    final featureSnake = feature.snakeCase;
    final useCasePascal = useCaseName.pascalCase;
    final useCaseCamel = useCaseName.camelCase;

    if (isList) {
      return '''
import 'package:dartz/dartz.dart';
import 'package:$projectName/core/error/failures.dart';
import 'package:$projectName/core/usecases/usecase.dart';
import 'package:$projectName/features/$featureSnake/domain/entities/${featureSnake}_entity.dart';
import 'package:$projectName/features/$featureSnake/domain/repositories/${featureSnake}_repository.dart';

class ${useCasePascal}UseCase implements UseCase<List<${featurePascal}Entity>, NoParams> {
  final ${featurePascal}Repository repository;

  const ${useCasePascal}UseCase(this.repository);

  @override
  Future<Either<Failure, List<${featurePascal}Entity>>> call(NoParams params) async {
    return await repository.$useCaseCamel();
  }
}
''';
    }

    return '''
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:$projectName/core/error/failures.dart';
import 'package:$projectName/core/usecases/usecase.dart';
import 'package:$projectName/features/$featureSnake/domain/entities/${featureSnake}_entity.dart';
import 'package:$projectName/features/$featureSnake/domain/repositories/${featureSnake}_repository.dart';

class ${useCasePascal}UseCase implements UseCase<${featurePascal}Entity, ${useCasePascal}Params> {
  final ${featurePascal}Repository repository;

  const ${useCasePascal}UseCase(this.repository);

  @override
  Future<Either<Failure, ${featurePascal}Entity>> call(${useCasePascal}Params params) async {
    return await repository.$useCaseCamel(params.id);
  }
}

class ${useCasePascal}Params extends Equatable {
  final String id;

  const ${useCasePascal}Params({required this.id});

  @override
  List<Object?> get props => [id];
}
''';
  }
}
