import 'dart:io';
import 'package:bclean/bclean.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  late Directory tempDir;
  late BcleanCommandRunner runner;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('bclean_test_');
    await File(p.join(tempDir.path, 'pubspec.yaml')).writeAsString('''
name: demo_shop
description: Demo project
version: 1.0.0

dependencies:
  flutter:
    sdk: flutter
''');
    runner = BcleanCommandRunner();
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('StringCase converts names accurately', () {
    final sc = StringCase('user_profile');
    expect(sc.snakeCase, 'user_profile');
    expect(sc.pascalCase, 'UserProfile');
    expect(sc.camelCase, 'userProfile');
    expect(sc.titleCase, 'User Profile');
  });

  test(
      'bclean init creates core layer with InternetConnection, app_router, injection_container, and updates pubspec.yaml',
      () async {
    final code = await runner.run(['init', '-p', tempDir.path]);
    expect(code, 0);

    expect(
      File(p.join(tempDir.path, 'lib', 'core', 'error', 'failures.dart'))
          .existsSync(),
      isTrue,
    );
    final networkInfoContent = File(
      p.join(tempDir.path, 'lib', 'core', 'network', 'network_info.dart'),
    ).readAsStringSync();
    expect(
      networkInfoContent,
      contains('connectionChecker.hasInternetAccess'),
    );

    final diContent =
        File(p.join(tempDir.path, 'lib', 'injection_container.dart'))
            .readAsStringSync();
    expect(
      diContent,
      contains(
          'sl.registerLazySingleton<InternetConnection>(() => InternetConnection());'),
    );

    final mainContent =
        File(p.join(tempDir.path, 'lib', 'main.dart')).readAsStringSync();
    expect(mainContent, contains('await di.initDependencies();'));
    expect(mainContent, contains('routes: AppRouter.routes,'));

    final pubspecContent =
        File(p.join(tempDir.path, 'pubspec.yaml')).readAsStringSync();
    expect(pubspecContent, contains('flutter_bloc:'));
    expect(pubspecContent, contains('dartz:'));
    expect(pubspecContent, contains('equatable:'));
    expect(pubspecContent, contains('get_it:'));
    expect(pubspecContent, contains('internet_connection_checker_plus:'));
  });

  test(
      'bclean create feature:user_auth creates full feature, stringify entity, auto-dispatches LoadEvent, and updates DI & Router',
      () async {
    await runner.run(['init', '-p', tempDir.path]);
    final code = await runner.run([
      'create',
      'feature:user_auth',
      '-p',
      tempDir.path,
    ]);
    expect(code, 0);

    final featureDir = p.join(tempDir.path, 'lib', 'features', 'user_auth');
    final entityContent = File(
      p.join(featureDir, 'domain', 'entities', 'user_auth_entity.dart'),
    ).readAsStringSync();
    expect(entityContent, contains('bool get stringify => true;'));

    final pageContent = File(
      p.join(featureDir, 'presentation', 'pages', 'user_auth_page.dart'),
    ).readAsStringSync();
    expect(
      pageContent,
      contains(
          "create: (_) => sl<UserAuthBloc>()..add(const LoadUserAuthEvent('1')),"),
    );

    final diContent =
        File(p.join(tempDir.path, 'lib', 'injection_container.dart'))
            .readAsStringSync();
    expect(diContent, contains('UserAuthBloc'));
    expect(diContent, contains('GetUserAuthUseCase'));
  });

  test(
      'bclean create usecase:login on user_auth wires Repository, RemoteDataSource, RepositoryImpl, and DI',
      () async {
    await runner.run(['init', '-p', tempDir.path]);
    await runner.run(['create', 'feature:user_auth', '-p', tempDir.path]);

    final code = await runner.run([
      'create',
      'usecase:login',
      'on',
      'user_auth',
      '-p',
      tempDir.path,
    ]);
    expect(code, 0);

    final featureDir = p.join(tempDir.path, 'lib', 'features', 'user_auth');
    final repoInterface = File(
      p.join(featureDir, 'domain', 'repositories', 'user_auth_repository.dart'),
    ).readAsStringSync();
    expect(
      repoInterface,
      contains('Future<Either<Failure, UserAuthEntity>> login(String id);'),
    );

    final remoteDs = File(
      p.join(
        featureDir,
        'data',
        'datasources',
        'user_auth_remote_data_source.dart',
      ),
    ).readAsStringSync();
    expect(remoteDs, contains('Future<UserAuthModel> login(String id);'));
    expect(remoteDs, contains('Future<UserAuthModel> login(String id) async'));

    final repoImpl = File(
      p.join(
        featureDir,
        'data',
        'repositories',
        'user_auth_repository_impl.dart',
      ),
    ).readAsStringSync();
    expect(
      repoImpl,
      contains('final remoteData = await remoteDataSource.login(id);'),
    );

    final diContent =
        File(p.join(tempDir.path, 'lib', 'injection_container.dart'))
            .readAsStringSync();
    expect(diContent, contains('LoginUseCase(sl())'));
  });

  test('bclean create bloc:session on user_auth registers SessionBloc in DI',
      () async {
    await runner.run(['create', 'feature:user_auth', '-p', tempDir.path]);
    final code = await runner.run([
      'create',
      'bloc:session',
      'on',
      'user_auth',
      '-p',
      tempDir.path,
    ]);
    expect(code, 0);

    final diContent =
        File(p.join(tempDir.path, 'lib', 'injection_container.dart'))
            .readAsStringSync();
    expect(diContent, contains('SessionBloc('));
  });

  test(
      'bclean generate model with singular JSON filename post.json on plural feature posts syncs PostsEntity & List mode',
      () async {
    await runner.run([
      'c',
      'feature:posts',
      '--no-local',
      '-p',
      tempDir.path,
    ]);

    final jsonFile = File(p.join(tempDir.path, 'post.json'));
    await jsonFile.writeAsString('''
[
  {
    "userId": 1,
    "id": 1,
    "title": "Hello BLoC",
    "body": "Clean Architecture List"
  }
]
''');

    final code = await runner.run([
      'g',
      'model',
      'on',
      'posts',
      'with',
      'post.json',
      '-p',
      tempDir.path,
    ]);
    expect(code, 0);

    final featureDir = p.join(tempDir.path, 'lib', 'features', 'posts');
    final entityContent = File(
      p.join(featureDir, 'domain', 'entities', 'posts_entity.dart'),
    ).readAsStringSync();
    expect(entityContent, contains('class PostsEntity extends Equatable'));
    expect(entityContent, contains('bool get stringify => true;'));

    final pageContent = File(
      p.join(featureDir, 'presentation', 'pages', 'posts_page.dart'),
    ).readAsStringSync();
    expect(
      pageContent,
      contains('create: (_) => sl<PostsBloc>()..add(const LoadPostsEvent()),'),
    );
    expect(pageContent, contains('ListView.builder'));
  });
}
