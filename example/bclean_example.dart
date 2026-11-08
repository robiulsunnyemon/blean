import 'dart:io';
import 'package:bclean/bclean.dart';
import 'package:path/path.dart' as p;

/// Demonstrates using `bclean` programmatically (or via CLI commands)
/// to scaffold a Clean Architecture + BLoC + dartz project.
Future<void> main() async {
  final tempProject = await Directory.systemTemp.createTemp('bclean_demo_');
  final runner = BcleanCommandRunner();

  try {
    // Create a mock pubspec.yaml for the demo Flutter project
    await File(p.join(tempProject.path, 'pubspec.yaml')).writeAsString('''
name: my_clean_app
description: A sample Flutter project using bclean.
version: 1.0.0

dependencies:
  flutter:
    sdk: flutter
''');

    // 1. Initialize Clean Architecture core, router, and DI container
    await runner.run(['init', '--path', tempProject.path]);

    // 2. Create a full 'auth' feature (Domain, Data, Presentation BLoC)
    await runner.run([
      'create',
      'feature:auth',
      '--path',
      tempProject.path,
    ]);

    // 3. Add a 'login' UseCase to the 'auth' feature
    await runner.run([
      'create',
      'usecase:login',
      'on',
      'auth',
      '--path',
      tempProject.path,
    ]);

    // 4. Generate Entity & Model from a JSON file
    final sampleJson = File(p.join(tempProject.path, 'user_profile.json'));
    await sampleJson.writeAsString('''
{
  "id": "usr_01",
  "name": "Tanvir Ahmed",
  "email": "tanvir@example.com",
  "is_active": true
}
''');

    await runner.run([
      'generate',
      'model',
      'on',
      'auth',
      'with',
      'user_profile.json',
      '--path',
      tempProject.path,
    ]);

    stdout.writeln(
        '\nDemo project successfully generated at: ${tempProject.path}');
  } finally {
    if (await tempProject.exists()) {
      await tempProject.delete(recursive: true);
    }
  }
}
