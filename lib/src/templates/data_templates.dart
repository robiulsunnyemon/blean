import '../utils/string_case.dart';

/// Templates for the Data layer (Models, DataSources, Repository Implementation).
class DataTemplates {
  static String model(String projectName, StringCase feature) {
    final pascal = feature.pascalCase;
    final snake = feature.snakeCase;
    return '''
import 'package:$projectName/features/$snake/domain/entities/${snake}_entity.dart';

class ${pascal}Model extends ${pascal}Entity {
  const ${pascal}Model({
    required super.id,
  });

  factory ${pascal}Model.fromJson(Map<String, dynamic> json) {
    return ${pascal}Model(
      id: json['id']?.toString() ?? '',
    );
  }

  static List<${pascal}Model> fromJsonList(List<dynamic> jsonList) {
    return jsonList
        .map((e) => ${pascal}Model.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
    };
  }
}
''';
  }

  static String remoteDataSource(
    String projectName,
    StringCase feature, {
    bool isList = false,
  }) {
    final pascal = feature.pascalCase;
    final snake = feature.snakeCase;
    final returnType = isList ? 'List<${pascal}Model>' : '${pascal}Model';
    final params = isList ? '' : 'String id';
    final placeholderReturn = isList
        ? '${pascal}Model.fromJsonList(const [])'
        : '${pascal}Model.fromJson(const {})';

    return '''
import 'package:$projectName/core/error/exceptions.dart';
import 'package:$projectName/features/$snake/data/models/${snake}_model.dart';

abstract class ${pascal}RemoteDataSource {
  Future<$returnType> get$pascal($params);
}

class ${pascal}RemoteDataSourceImpl implements ${pascal}RemoteDataSource {
  const ${pascal}RemoteDataSourceImpl();

  @override
  Future<$returnType> get$pascal($params) async {
    try {
      // TODO: Replace with actual API call (e.g., Dio / HttpClient)
      return $placeholderReturn;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
''';
  }

  static String localDataSource(
    String projectName,
    StringCase feature, {
    bool isList = false,
  }) {
    final pascal = feature.pascalCase;
    final snake = feature.snakeCase;
    final returnType = isList ? 'List<${pascal}Model>' : '${pascal}Model';
    final cacheParam =
        isList ? 'List<${pascal}Model> modelsToCache' : '${pascal}Model modelToCache';
    final placeholderReturn = isList
        ? '${pascal}Model.fromJsonList(const [])'
        : '${pascal}Model.fromJson(const {})';

    return '''
import 'package:$projectName/core/error/exceptions.dart';
import 'package:$projectName/features/$snake/data/models/${snake}_model.dart';

abstract class ${pascal}LocalDataSource {
  Future<$returnType> getLast$pascal();
  Future<void> cache$pascal($cacheParam);
}

class ${pascal}LocalDataSourceImpl implements ${pascal}LocalDataSource {
  const ${pascal}LocalDataSourceImpl();

  @override
  Future<$returnType> getLast$pascal() async {
    try {
      // TODO: Fetch from local storage (SharedPreferences / Hive / Isar)
      return $placeholderReturn;
    } catch (e) {
      throw CacheException(e.toString());
    }
  }

  @override
  Future<void> cache$pascal($cacheParam) async {
    // TODO: Save to local storage
  }
}
''';
  }

  static String repositoryImpl(
    String projectName,
    StringCase feature, {
    bool includeLocal = true,
    bool isList = false,
  }) {
    final pascal = feature.pascalCase;
    final snake = feature.snakeCase;
    final returnType = isList ? 'List<${pascal}Entity>' : '${pascal}Entity';
    final params = isList ? '' : 'String id';
    final callArgs = isList ? '' : 'id';

    final localImport = includeLocal
        ? "import 'package:$projectName/features/$snake/data/datasources/${snake}_local_data_source.dart';\n"
        : '';
    final localField = includeLocal
        ? '  final ${pascal}LocalDataSource localDataSource;\n'
        : '';
    final localCtorParam = includeLocal
        ? '    required this.localDataSource,\n'
        : '';
    final cacheCall = includeLocal
        ? '        await localDataSource.cache$pascal(remoteData);\n'
        : '';
    final offlineFallback = includeLocal
        ? '''      try {
        final localData = await localDataSource.getLast$pascal();
        return Right(localData);
      } on CacheException catch (e) {
        return Left(CacheFailure(e.message));
      }'''
        : '      return const Left(NetworkFailure());';

    return '''
import 'package:dartz/dartz.dart';
import 'package:$projectName/core/error/exceptions.dart';
import 'package:$projectName/core/error/failures.dart';
import 'package:$projectName/core/network/network_info.dart';
import 'package:$projectName/features/$snake/data/datasources/${snake}_remote_data_source.dart';
${localImport}import 'package:$projectName/features/$snake/domain/entities/${snake}_entity.dart';
import 'package:$projectName/features/$snake/domain/repositories/${snake}_repository.dart';

class ${pascal}RepositoryImpl implements ${pascal}Repository {
  final ${pascal}RemoteDataSource remoteDataSource;
$localField  final NetworkInfo networkInfo;

  const ${pascal}RepositoryImpl({
    required this.remoteDataSource,
$localCtorParam    required this.networkInfo,
  });

  @override
  Future<Either<Failure, $returnType>> get$pascal($params) async {
    if (await networkInfo.isConnected) {
      try {
        final remoteData = await remoteDataSource.get$pascal($callArgs);
$cacheCall        return Right(remoteData);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      }
    } else {
$offlineFallback
    }
  }
}
''';
  }
}
