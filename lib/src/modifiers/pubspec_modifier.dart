import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';
import '../utils/logger.dart';

class BcleanConfig {
  final bool useCubit;
  final bool includeLocal;

  const BcleanConfig({
    this.useCubit = false,
    this.includeLocal = true,
  });
}

/// Reads `bclean:` config from `pubspec.yaml` and automatically adds required
/// Clean Architecture + BLoC dependencies (`flutter_bloc`, `equatable`, `dartz`, `get_it`).
class PubspecModifier {
  static const Map<String, String> requiredDependencies = {
    'flutter_bloc': '^8.1.5',
    'equatable': '^2.0.5',
    'dartz': '^0.10.1',
    'get_it': '^7.7.0',
  };

  /// Reads optional `bclean:` block from target project's `pubspec.yaml`.
  static BcleanConfig readConfig(String projectDir) {
    final pubspecFile = File(p.join(projectDir, 'pubspec.yaml'));
    if (!pubspecFile.existsSync()) {
      return const BcleanConfig();
    }
    try {
      final doc = loadYaml(pubspecFile.readAsStringSync());
      if (doc is YamlMap && doc['bclean'] is YamlMap) {
        final cfg = doc['bclean'] as YamlMap;
        final stateMgmt = cfg['state_management']?.toString().toLowerCase();
        final useCubit =
            (cfg['use_cubit'] == true) || (stateMgmt == 'cubit');
        final includeLocal = cfg['include_local'] is bool
            ? cfg['include_local'] as bool
            : true;
        return BcleanConfig(
          useCubit: useCubit,
          includeLocal: includeLocal,
        );
      }
    } catch (_) {
      // Fallback to defaults
    }
    return const BcleanConfig();
  }

  /// Ensures `flutter_bloc`, `equatable`, `dartz`, and `get_it` exist in `pubspec.yaml`.
  static Future<List<String>> ensureDependencies(String projectDir) async {
    final pubspecPath = p.join(projectDir, 'pubspec.yaml');
    final pubspecFile = File(pubspecPath);
    if (!await pubspecFile.exists()) {
      CliLogger.warn('pubspec.yaml not found in $projectDir.');
      return [];
    }

    var content = await pubspecFile.readAsString();
    YamlMap? doc;
    try {
      final parsed = loadYaml(content);
      if (parsed is YamlMap) {
        doc = parsed;
      }
    } catch (_) {
      return [];
    }

    final existingDeps = <String>{};
    if (doc != null && doc['dependencies'] is YamlMap) {
      final depsMap = doc['dependencies'] as YamlMap;
      for (final key in depsMap.keys) {
        existingDeps.add(key.toString());
      }
    }

    final missing = <String, String>{};
    for (final entry in requiredDependencies.entries) {
      if (!existingDeps.contains(entry.key)) {
        missing[entry.key] = entry.value;
      }
    }

    if (missing.isEmpty) {
      return [];
    }

    final linesToAdd = missing.entries
        .map((e) => '  ${e.key}: ${e.value}')
        .join('\n');

    final depHeaderRegex = RegExp(r'^dependencies:\s*$', multiLine: true);
    if (depHeaderRegex.hasMatch(content)) {
      content = content.replaceFirstMapped(
        depHeaderRegex,
        (m) => '${m.group(0)}\n$linesToAdd',
      );
    } else {
      content = '$content\ndependencies:\n$linesToAdd\n';
    }

    await pubspecFile.writeAsString(content);
    CliLogger.modified(p.relative(pubspecPath, from: projectDir));
    return missing.keys.toList();
  }
}
