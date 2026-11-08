import 'dart:io';
import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import '../commands/create_command.dart';
import '../commands/generate_command.dart';
import '../commands/init_command.dart';
import '../utils/logger.dart';

const String packageVersion = '0.1.5';

class BcleanCommandRunner extends CommandRunner<int> {
  BcleanCommandRunner()
      : super(
          'bclean',
          'A get_cli-inspired Clean Architecture + BLoC/Cubit + dartz CLI for Flutter.',
        ) {
    argParser.addFlag(
      'version',
      abbr: 'v',
      negatable: false,
      help: 'Print the current version of bclean.',
    );

    addCommand(InitCommand());
    addCommand(CreateCommand());
    addCommand(GenerateCommand());
  }

  @override
  Future<int> run(Iterable<String> args) async {
    try {
      final topLevelResults = parse(args);
      return await runCommand(topLevelResults) ?? 0;
    } on FormatException catch (e) {
      CliLogger.error(e.message);
      stdout.writeln(usage);
      return 64;
    } on UsageException catch (e) {
      CliLogger.error(e.message);
      stdout.writeln(e.usage);
      return 64;
    } catch (e) {
      CliLogger.error(e.toString());
      return 1;
    }
  }

  @override
  Future<int?> runCommand(ArgResults topLevelResults) async {
    if (topLevelResults['version'] == true) {
      stdout.writeln('bclean version $packageVersion');
      return 0;
    }
    if (topLevelResults.command == null && topLevelResults.arguments.isEmpty) {
      printUsage();
      return 0;
    }
    return super.runCommand(topLevelResults);
  }
}
