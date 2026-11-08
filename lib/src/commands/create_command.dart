import 'dart:io';
import 'package:args/command_runner.dart';
import '../generators/feature_generator.dart';
import '../modifiers/pubspec_modifier.dart';
import '../utils/logger.dart';

class CreateCommand extends Command<int> {
  @override
  final String name = 'create';

  @override
  List<String> get aliases => ['c'];

  @override
  final String description =
      'Create a new Clean Architecture feature or sub-component (get_cli style).\n'
      'Examples:\n'
      '  bclean create feature:auth\n'
      '  bclean create feature:posts --list --no-local\n'
      '  bclean create feature:profile --cubit\n'
      '  bclean create usecase:get_all_posts on posts --list\n'
      '  bclean create bloc:session on auth\n'
      '  bclean create page:register on auth';

  CreateCommand() {
    argParser
      ..addFlag(
        'cubit',
        abbr: 'c',
        negatable: false,
        help: 'Use Cubit instead of BLoC for presentation state management.',
      )
      ..addFlag(
        'list',
        abbr: 'l',
        negatable: false,
        help:
            'Generate feature/usecase/bloc/page for a List of items (List<Entity>).',
      )
      ..addFlag(
        'local',
        defaultsTo: true,
        help: 'Include LocalDataSource in Data layer (use --no-local to skip).',
      )
      ..addOption(
        'on',
        help:
            'Target feature name when creating a usecase, bloc, cubit, or page.',
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
        negatable: false,
        help: 'Overwrite existing files.',
      );
  }

  @override
  Future<int> run() async {
    final rest = argResults?.rest ?? [];
    if (rest.isEmpty) {
      CliLogger.error(
        'Missing target to create. Example: `bclean create feature:auth`',
      );
      printUsage();
      return 64;
    }

    final targetDir = argResults?['path'] as String? ?? Directory.current.path;
    final config = PubspecModifier.readConfig(targetDir);

    final cubitFlag = argResults?['cubit'] as bool? ?? false;
    final useCubit = cubitFlag || config.useCubit;
    final isList = argResults?['list'] as bool? ?? false;

    final localWasParsed = argResults?.wasParsed('local') ?? false;
    final includeLocal = localWasParsed
        ? (argResults?['local'] as bool? ?? true)
        : config.includeLocal;

    final overwrite = argResults?['force'] as bool? ?? false;

    // Parse get_cli style `type:name` or space-separated `type name`
    String type;
    String entityName;
    int nextIndex = 1;

    final firstArg = rest.first;
    if (firstArg.contains(':')) {
      final parts = firstArg.split(':');
      type = parts[0].toLowerCase();
      entityName = parts.sublist(1).join(':');
    } else {
      type = firstArg.toLowerCase();
      if (rest.length < 2) {
        CliLogger.error(
          'Missing name for "$type". Example: `bclean create $type:auth`',
        );
        return 64;
      }
      entityName = rest[1];
      nextIndex = 2;
    }

    if (entityName.trim().isEmpty) {
      CliLogger.error('Name cannot be empty.');
      return 64;
    }

    // Parse optional `on <feature>` from positional arguments or `--on` option
    String? onFeature = argResults?['on'] as String?;
    if (onFeature == null && rest.length >= nextIndex + 2) {
      if (rest[nextIndex].toLowerCase() == 'on') {
        onFeature = rest[nextIndex + 1];
      }
    }

    switch (type) {
      case 'feature':
        await FeatureGenerator.generateFeature(
          projectDir: targetDir,
          featureRawName: entityName,
          useCubit: useCubit,
          includeLocal: includeLocal,
          isList: isList,
          overwrite: overwrite,
        );
        return 0;

      case 'usecase':
        final targetFeature = onFeature ?? entityName;
        if (onFeature == null) {
          CliLogger.warn(
            'No feature specified with `on <feature>`. Defaulting to feature "$targetFeature".',
          );
        }
        await FeatureGenerator.generateUseCase(
          projectDir: targetDir,
          featureRawName: targetFeature,
          useCaseRawName: entityName,
          isList: isList,
          overwrite: overwrite,
        );
        return 0;

      case 'bloc':
      case 'cubit':
        final targetFeature = onFeature ?? entityName;
        await FeatureGenerator.generateBloc(
          projectDir: targetDir,
          featureRawName: targetFeature,
          blocRawName: entityName,
          useCubit: type == 'cubit' || useCubit,
          isList: isList,
          overwrite: overwrite,
        );
        return 0;

      case 'page':
        final targetFeature = onFeature ?? entityName;
        await FeatureGenerator.generatePage(
          projectDir: targetDir,
          featureRawName: targetFeature,
          pageRawName: entityName,
          useCubit: useCubit,
          isList: isList,
          overwrite: overwrite,
        );
        return 0;

      default:
        CliLogger.error(
          'Unknown create type "$type". Supported types: feature, usecase, bloc, cubit, page.',
        );
        return 64;
    }
  }
}
