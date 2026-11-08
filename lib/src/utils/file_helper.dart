import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';
import 'logger.dart';

class FileHelper {
  /// Writes [content] to [filePath], creating parent directories if needed.
  /// If [overwrite] is false and the file exists, skips writing and warns.
  static Future<bool> writeFile(
    String filePath,
    String content, {
    bool overwrite = false,
    String? baseDir,
  }) async {
    final file = File(filePath);
    final displayPath =
        baseDir != null ? p.relative(filePath, from: baseDir) : filePath;

    if (await file.exists() && !overwrite) {
      CliLogger.warn('Skipped (already exists): $displayPath');
      return false;
    }

    await file.parent.create(recursive: true);
    await file.writeAsString(content);
    CliLogger.created(displayPath);
    return true;
  }

  /// Reads the package `name` from `pubspec.yaml` in [projectDir].
  /// Returns `'app'` as fallback if `pubspec.yaml` is not found.
  static String getProjectName(String projectDir) {
    final pubspecFile = File(p.join(projectDir, 'pubspec.yaml'));
    if (!pubspecFile.existsSync()) {
      return 'app';
    }
    try {
      final doc = loadYaml(pubspecFile.readAsStringSync());
      if (doc is YamlMap && doc['name'] is String) {
        return doc['name'] as String;
      }
    } catch (_) {
      // Fallback if YAML is malformed
    }
    return 'app';
  }
}
