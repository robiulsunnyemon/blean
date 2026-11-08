import 'dart:io';
import 'package:args/command_runner.dart';
import '../generators/json_model_generator.dart';
import '../utils/logger.dart';

class GenerateCommand extends Command<int> {
  @override
  final String name = 'generate';

  @override
  List<String> get aliases => ['g'];

  @override
  final String description =
      'Generate Clean Architecture Entity & Model from a JSON file (get_cli style).\n'
      'Auto-detects whether the JSON root is a Single Object {} or a JSON List [{}].\n'
      'Examples:\n'
      '  bclean generate model on posts with assets/posts.json\n'
      '  bclean generate model on auth with assets/models/user.json\n'
      '  bclean generate model on product with assets/item.json --name product_detail\n'
      '  bclean generate model on auth with user.json --skip-entity';

  GenerateCommand() {
    argParser
      ..addOption(
        'on',
        help: 'Target feature name where Entity & Model will be placed.',
      )
      ..addOption(
        'with',
        help: 'Path to the source JSON file.',
      )
      ..addOption(
        'name',
        abbr: 'n',
        help: 'Custom model/entity base name (defaults to JSON filename).',
      )
      ..addFlag(
        'list',
        abbr: 'l',
        help:
            'Force List<Entity> mode (auto-detected if JSON root is an Array [...]).',
      )
      ..addFlag(
        'skip-entity',
        negatable: false,
        help: 'Generate only the Data Model without a Domain Entity.',
      )
      ..addOption(
        'path',
        abbr: 'p',
        help:
            'Target Flutter project directory (defaults to current directory).',
      )
      ..addFlag(
        'force',
        abbr: 'f',
        defaultsTo: true,
        help: 'Overwrite existing model/entity files.',
      );
  }

  @override
  Future<int> run() async {
    final rest = argResults?.rest ?? [];
    if (rest.isEmpty) {
      CliLogger.error(
        'Missing target to generate. Example: `bclean generate model on auth with user.json`',
      );
      printUsage();
      return 64;
    }

    final targetDir = argResults?['path'] as String? ?? Directory.current.path;
    final customName = argResults?['name'] as String?;
    final skipEntity = argResults?['skip-entity'] as bool? ?? false;
    final overwrite = argResults?['force'] as bool? ?? true;
    final forceList = (argResults?.wasParsed('list') ?? false)
        ? (argResults?['list'] as bool?)
        : null;

    String type = rest.first.toLowerCase();
    String? inlineName;
    if (type.contains(':')) {
      final parts = type.split(':');
      type = parts[0];
      inlineName = parts.sublist(1).join(':');
    }

    if (type != 'model') {
      CliLogger.error(
        'Unknown generate target "$type". Supported target: `model`.',
      );
      return 64;
    }

    String? featureName = argResults?['on'] as String?;
    String? jsonFilePath = argResults?['with'] as String?;

    // Parse get_cli positional keywords: `model on <feature> with <json_path>`
    for (var i = 1; i < rest.length; i++) {
      final token = rest[i].toLowerCase();
      if (token == 'on' && i + 1 < rest.length) {
        featureName = rest[i + 1];
        i++;
      } else if (token == 'with' && i + 1 < rest.length) {
        jsonFilePath = rest[i + 1];
        i++;
      }
    }

    if (featureName == null || featureName.trim().isEmpty) {
      CliLogger.error(
        'Missing feature name. Use `on <feature>`, e.g.: `bclean generate model on auth with user.json`',
      );
      return 64;
    }

    if (jsonFilePath == null || jsonFilePath.trim().isEmpty) {
      CliLogger.error(
        'Missing JSON file path. Use `with <path/to/file.json>`, e.g.: `bclean generate model on auth with user.json`',
      );
      return 64;
    }

    await JsonModelGenerator.generateFromJsonFile(
      projectDir: targetDir,
      featureRawName: featureName,
      jsonFilePath: jsonFilePath,
      customModelName: customName ?? inlineName,
      skipEntity: skipEntity,
      forceList: forceList,
      overwrite: overwrite,
    );

    return 0;
  }
}
