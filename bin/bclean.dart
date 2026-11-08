import 'dart:io';
import 'package:bclean/bclean.dart';

Future<void> main(List<String> arguments) async {
  final runner = BcleanCommandRunner();
  final exitCode = await runner.run(arguments);
  exit(exitCode);
}
