import 'dart:io';
import 'package:args/command_runner.dart';
import '../generators/init_generator.dart';

class InitCommand extends Command<int> {
  @override
  final String name = 'init';

  @override
  final String description =
      'Initialize Clean Architecture core folder and injection_container.dart.';

  InitCommand() {
    argParser
      ..addOption(
        'path',
        abbr: 'p',
        help:
            'Target Flutter project directory (defaults to current directory).',
      )
      ..addFlag(
        'force',
        abbr: 'f',
        negatable: false,
        help: 'Overwrite existing files if they already exist.',
      );
  }

  @override
  Future<int> run() async {
    final targetDir = argResults?['path'] as String? ?? Directory.current.path;
    final overwrite = argResults?['force'] as bool? ?? false;

    await InitGenerator.generate(
      projectDir: targetDir,
      overwrite: overwrite,
    );
    return 0;
  }
}
