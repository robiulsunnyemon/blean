import '../utils/string_case.dart';

/// Templates for `bclean init` (Core layer, Dependency Injection, and main.dart).
class CoreTemplates {
  static String failures() => '''
import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;

  const Failure([this.message = 'An unexpected error occurred']);

  @override
  List<Object?> get props => [message];
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Server error occurred']);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Cache error occurred']);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No internet connection']);
}
''';

  static String exceptions() => '''
class ServerException implements Exception {
  final String message;
  const ServerException([this.message = 'Server exception occurred']);
}

class CacheException implements Exception {
  final String message;
  const CacheException([this.message = 'Cache exception occurred']);
}

class NetworkException implements Exception {
  final String message;
  const NetworkException([this.message = 'No internet connection']);
}
''';

  static String useCase(String projectName) => '''
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:$projectName/core/error/failures.dart';

abstract class UseCase<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}

class NoParams extends Equatable {
  const NoParams();

  @override
  List<Object?> get props => [];
}
''';

  static String networkInfo() => '''
abstract class NetworkInfo {
  Future<bool> get isConnected;
}

class NetworkInfoImpl implements NetworkInfo {
  @override
  Future<bool> get isConnected async {
    // TODO: Implement actual connectivity check (e.g., internet_connection_checker)
    return true;
  }
}
''';

  static String injectionContainer(String projectName) => '''
import 'package:get_it/get_it.dart';
import 'package:$projectName/core/network/network_info.dart';
// [BCLEAN_IMPORTS]

final sl = GetIt.instance;

Future<void> initDependencies() async {
  // Core
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl());

  // [BCLEAN_FEATURES]
}
''';

  static String mainDart(String projectName) {
    final appTitle = StringCase(projectName).titleCase;
    return '''
import 'package:flutter/material.dart';
import 'package:$projectName/core/router/app_router.dart';
import 'package:$projectName/injection_container.dart' as di;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await di.initDependencies();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '$appTitle',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      initialRoute: AppRouter.initial,
      routes: AppRouter.routes,
    );
  }
}
''';
  }
}
