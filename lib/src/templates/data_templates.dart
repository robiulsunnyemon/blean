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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
    };
  }
}
''';
  }

  static String remoteDataSource(String projectName, StringCase feature) {
    final pascal = feature.pascalCase;
    final snake = feature.snakeCase;
    return '''
import 'package:$projectName/core/error/exceptions.dart';
import 'package:$projectName/features/$snake/data/models/${snake}_model.dart';

abstract class ${pascal}RemoteDataSource {
  Future<${pascal}Model> get$pascal(String id);
}

class ${pascal}RemoteDataSourceImpl implements ${pascal}RemoteDataSource {
  const ${pascal}RemoteDataSourceImpl();

  @override
  Future<${pascal}Model> get$pascal(String id) async {
    try {
      // TODO: Replace with actual API call (e.g., Dio / HttpClient)
      return ${pascal}Model(id: id);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
''';
  }

  static String localDataSource(String projectName, StringCase feature) {
    final pascal = feature.pascalCase;
    final snake = feature.snakeCase;
    return '''
import 'package:$projectName/core/error/exceptions.dart';
import 'package:$projectName/features/$snake/data/models/${snake}_model.dart';

abstract class ${pascal}LocalDataSource {
  Future<${pascal}Model> getLast$pascal();
  Future<void> cache$pascal(${pascal}Model modelToCache);
}

class ${pascal}LocalDataSourceImpl implements ${pascal}LocalDataSource {
  const ${pascal}LocalDataSourceImpl();

  @override
  Future<${pascal}Model> getLast$pascal() async {
    try {
      // TODO: Fetch from local storage (SharedPreferences / Hive / Isar)
      return const ${pascal}Model(id: 'cached_id');
    } catch (e) {
      throw CacheException(e.toString());
    }
  }

  @override
  Future<void> cache$pascal(${pascal}Model modelToCache) async {
    // TODO: Save to local storage
  }
}
''';
  }

  static String repositoryImpl(
    String projectName,
    StringCase feature, {
    bool includeLocal = true,
  }) {
    final pascal = feature.pascalCase;
    final snake = feature.snakeCase;

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
  Future<Either<Failure, ${pascal}Entity>> get$pascal(String id) async {
    if (await networkInfo.isConnected) {
      try {
        final remoteData = await remoteDataSource.get$pascal(id);
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
