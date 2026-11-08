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
      'bclean init creates core layer, app_router, injection_container, and updates pubspec.yaml',
      () async {
    final code = await runner.run(['init', '-p', tempDir.path]);
    expect(code, 0);

    expect(
      File(p.join(tempDir.path, 'lib', 'core', 'error', 'failures.dart'))
          .existsSync(),
      isTrue,
    );
    expect(
      File(p.join(tempDir.path, 'lib', 'core', 'router', 'app_router.dart'))
          .existsSync(),
      isTrue,
    );
    expect(
      File(p.join(tempDir.path, 'lib', 'injection_container.dart')).existsSync(),
      isTrue,
    );

    final pubspecContent =
        File(p.join(tempDir.path, 'pubspec.yaml')).readAsStringSync();
    expect(pubspecContent, contains('flutter_bloc:'));
    expect(pubspecContent, contains('dartz:'));
    expect(pubspecContent, contains('equatable:'));
    expect(pubspecContent, contains('get_it:'));
  });

  test(
      'bclean create feature:user_auth creates full feature and updates DI & Router',
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
    expect(
      File(p.join(featureDir, 'domain', 'entities', 'user_auth_entity.dart'))
          .existsSync(),
      isTrue,
    );
    expect(
      File(p.join(
        featureDir,
        'data',
        'repositories',
        'user_auth_repository_impl.dart',
      )).readAsStringSync(),
      contains('Either<Failure, UserAuthEntity>'),
    );

    final diContent =
        File(p.join(tempDir.path, 'lib', 'injection_container.dart'))
            .readAsStringSync();
    expect(diContent, contains('UserAuthBloc'));
    expect(diContent, contains('GetUserAuthUseCase'));

    final routerContent =
        File(p.join(tempDir.path, 'lib', 'core', 'router', 'app_router.dart'))
            .readAsStringSync();
    expect(routerContent, contains("static const String userAuth = '/user-auth';"));
    expect(routerContent, contains('userAuth: (_) => const UserAuthPage(),'));
  });

  test(
      'bclean create usecase:login on user_auth wires Repository, RepositoryImpl, and DI',
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
      contains('Future<Either<Failure, UserAuthEntity>> login(String id) async'),
    );

    final diContent =
        File(p.join(tempDir.path, 'lib', 'injection_container.dart'))
            .readAsStringSync();
    expect(diContent, contains('LoginUseCase(sl())'));
  });

  test(
      'bclean generate model on user_auth with user_profile.json generates Entity & Model',
      () async {
    final jsonFile = File(p.join(tempDir.path, 'user_profile.json'));
    await jsonFile.writeAsString('''
{
  "id": "u_101",
  "full_name": "Rahim Uddin",
  "age": 28,
  "is_verified": true,
  "roles": ["admin", "editor"],
  "address": {
    "city": "Dhaka",
    "zip_code": 1207
  }
}
''');

    final code = await runner.run([
      'generate',
      'model',
      'on',
      'user_auth',
      'with',
      'user_profile.json',
      '-p',
      tempDir.path,
    ]);
    expect(code, 0);

    final featureDir = p.join(tempDir.path, 'lib', 'features', 'user_auth');
    final entityFile = File(
      p.join(featureDir, 'domain', 'entities', 'user_profile_entity.dart'),
    );
    final modelFile = File(
      p.join(featureDir, 'data', 'models', 'user_profile_model.dart'),
    );

    expect(entityFile.existsSync(), isTrue);
    expect(modelFile.existsSync(), isTrue);

    final entityContent = entityFile.readAsStringSync();
    expect(entityContent, contains('class UserProfileEntity extends Equatable'));
    expect(entityContent, contains('final AddressEntity address;'));
    expect(entityContent, contains('class AddressEntity extends Equatable'));

    final modelContent = modelFile.readAsStringSync();
    expect(
      modelContent,
      contains('class UserProfileModel extends UserProfileEntity'),
    );
    expect(modelContent, contains('factory UserProfileModel.fromJson'));
    expect(modelContent, contains('Map<String, dynamic> toJson()'));
    expect(modelContent, contains('UserProfileModel copyWith('));
    expect(modelContent, contains('class AddressModel extends AddressEntity'));
  });
}
