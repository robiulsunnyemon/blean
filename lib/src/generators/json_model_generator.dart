import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import '../utils/file_helper.dart';
import '../utils/logger.dart';
import '../utils/string_case.dart';
import 'feature_generator.dart';

class _FieldDef {
  final String jsonKey;
  final String fieldName;
  final String dartType;
  final String entityType;
  final bool isNestedObject;
  final bool isNestedList;
  final String? nestedClassPascal;

  const _FieldDef({
    required this.jsonKey,
    required this.fieldName,
    required this.dartType,
    required this.entityType,
    this.isNestedObject = false,
    this.isNestedList = false,
    this.nestedClassPascal,
  });
}

class _ClassDef {
  final StringCase className;
  final List<_FieldDef> fields;

  const _ClassDef({
    required this.className,
    required this.fields,
  });
}

/// Parses a JSON file and generates Clean Architecture Domain Entity
/// and Data Model (`fromJson`, `fromJsonList`, `toJson`, `copyWith`, `Equatable`).
class JsonModelGenerator {
  static Future<void> generateFromJsonFile({
    required String projectDir,
    required String featureRawName,
    required String jsonFilePath,
    String? customModelName,
    bool skipEntity = false,
    bool? forceList,
    bool overwrite = true,
  }) async {
    final file = File(
      p.isAbsolute(jsonFilePath)
          ? jsonFilePath
          : p.join(projectDir, jsonFilePath),
    );

    if (!await file.exists()) {
      throw FileSystemException('JSON file not found', file.path);
    }

    final rawContent = await file.readAsString();
    final dynamic decoded = jsonDecode(rawContent);

    Map<String, dynamic> rootMap;
    bool isJsonArray = false;
    if (decoded is Map<String, dynamic>) {
      rootMap = decoded;
    } else if (decoded is List &&
        decoded.isNotEmpty &&
        decoded.first is Map<String, dynamic>) {
      rootMap = decoded.first as Map<String, dynamic>;
      isJsonArray = true;
    } else {
      throw const FormatException(
        'JSON root must be an Object {} or a non-empty List of Objects [{}].',
      );
    }

    final isListMode = forceList ?? isJsonArray;
    final feature = StringCase(featureRawName);
    final featureDir = p.join(projectDir, 'lib', 'features', feature.snakeCase);

    final inferredRaw =
        customModelName ?? p.basenameWithoutExtension(file.path);
    var rootName = StringCase(inferredRaw);

    // Fix 6: If `--name` was not explicitly provided and the JSON filename is a
    // singular/plural variant of the feature name (e.g. `post.json` on feature `posts`),
    // automatically use the feature's name (`posts`) so existing feature imports stay in sync!
    if (customModelName == null &&
        rootName.snakeCase != feature.snakeCase &&
        ('${rootName.snakeCase}s' == feature.snakeCase ||
            rootName.snakeCase == '${feature.snakeCase}s')) {
      rootName = feature;
    }

    final projectName = FileHelper.getProjectName(projectDir);

    CliLogger.info(
      'Generating Model & Entity "${rootName.pascalCase}" (${isListMode ? 'JSON List' : 'Single Object'}) on feature "${feature.pascalCase}" from $jsonFilePath...',
    );

    final classes = <_ClassDef>[];
    _collectClasses(rootName, rootMap, classes);

    if (!skipEntity) {
      final entityPath = p.join(
        featureDir,
        'domain',
        'entities',
        '${rootName.snakeCase}_entity.dart',
      );
      final entityCode = _buildEntityFile(classes);
      await FileHelper.writeFile(
        entityPath,
        entityCode,
        overwrite: overwrite,
        baseDir: projectDir,
      );
    }

    final modelPath = p.join(
      featureDir,
      'data',
      'models',
      '${rootName.snakeCase}_model.dart',
    );
    final modelCode = _buildModelFile(
      projectName: projectName,
      feature: feature,
      rootName: rootName,
      classes: classes,
      extendsEntity: !skipEntity,
    );
    await FileHelper.writeFile(
      modelPath,
      modelCode,
      overwrite: overwrite,
      baseDir: projectDir,
    );

    // If the model name matches the feature name (e.g. `posts.json` or `post.json` on feature `posts`)
    // and the JSON root is a List (or `--list` was passed), automatically sync
    // the feature's DataSource, Repository, UseCase, BLoC/Cubit, and Page!
    if (!skipEntity &&
        rootName.snakeCase == feature.snakeCase &&
        (isListMode || forceList != null)) {
      await FeatureGenerator.syncFeatureListMode(
        projectDir: projectDir,
        feature: feature,
        isList: isListMode,
      );
    }

    CliLogger.success(
      'Generated ${rootName.pascalCase}Model${skipEntity ? '' : ' & ${rootName.pascalCase}Entity'} (${isListMode ? 'List Mode' : 'Single Item Mode'}) successfully!',
    );
  }

  static void _collectClasses(
    StringCase className,
    Map<String, dynamic> map,
    List<_ClassDef> outClasses,
  ) {
    final fields = <_FieldDef>[];
    final nestedToProcess = <MapEntry<StringCase, Map<String, dynamic>>>[];

    for (final entry in map.entries) {
      final key = entry.key;
      final value = entry.value;
      final fieldCase = StringCase(key);
      final fieldName = fieldCase.camelCase;

      if (value is Map<String, dynamic>) {
        final nestedName = StringCase(key);
        fields.add(
          _FieldDef(
            jsonKey: key,
            fieldName: fieldName,
            dartType: '${nestedName.pascalCase}Model',
            entityType: '${nestedName.pascalCase}Entity',
            isNestedObject: true,
            nestedClassPascal: nestedName.pascalCase,
          ),
        );
        nestedToProcess.add(MapEntry(nestedName, value));
      } else if (value is List) {
        if (value.isNotEmpty && value.first is Map<String, dynamic>) {
          final singularKey = key.endsWith('s') && key.length > 1
              ? key.substring(0, key.length - 1)
              : '${key}_item';
          final nestedName = StringCase(singularKey);
          fields.add(
            _FieldDef(
              jsonKey: key,
              fieldName: fieldName,
              dartType: 'List<${nestedName.pascalCase}Model>',
              entityType: 'List<${nestedName.pascalCase}Entity>',
              isNestedList: true,
              nestedClassPascal: nestedName.pascalCase,
            ),
          );
          nestedToProcess.add(
            MapEntry(nestedName, value.first as Map<String, dynamic>),
          );
        } else {
          final itemType =
              value.isNotEmpty ? _primitiveType(value.first) : 'dynamic';
          fields.add(
            _FieldDef(
              jsonKey: key,
              fieldName: fieldName,
              dartType: 'List<$itemType>',
              entityType: 'List<$itemType>',
            ),
          );
        }
      } else {
        final type = _primitiveType(value);
        fields.add(
          _FieldDef(
            jsonKey: key,
            fieldName: fieldName,
            dartType: type,
            entityType: type,
          ),
        );
      }
    }

    outClasses.add(_ClassDef(className: className, fields: fields));

    for (final nested in nestedToProcess) {
      final alreadyExists = outClasses.any(
        (c) => c.className.pascalCase == nested.key.pascalCase,
      );
      if (!alreadyExists) {
        _collectClasses(nested.key, nested.value, outClasses);
      }
    }
  }

  static String _primitiveType(dynamic value) {
    if (value is int) return 'int';
    if (value is double) return 'double';
    if (value is bool) return 'bool';
    if (value is String) return 'String';
    return 'dynamic';
  }

  static String _buildEntityFile(List<_ClassDef> classes) {
    final buffer = StringBuffer();
    buffer.writeln("import 'package:equatable/equatable.dart';");
    buffer.writeln();

    for (var i = 0; i < classes.length; i++) {
      final cls = classes[i];
      final pascal = cls.className.pascalCase;

      buffer.writeln('class ${pascal}Entity extends Equatable {');
      for (final f in cls.fields) {
        buffer.writeln('  final ${f.entityType} ${f.fieldName};');
      }
      buffer.writeln();
      buffer.writeln('  const ${pascal}Entity({');
      for (final f in cls.fields) {
        buffer.writeln('    required this.${f.fieldName},');
      }
      buffer.writeln('  });');
      buffer.writeln();
      buffer.writeln('  @override');
      buffer.writeln('  bool get stringify => true;');
      buffer.writeln();
      final propsList = cls.fields.map((f) => f.fieldName).join(', ');
      buffer.writeln('  @override');
      buffer.writeln('  List<Object?> get props => [$propsList];');
      buffer.writeln('}');
      if (i < classes.length - 1) {
        buffer.writeln();
      }
    }

    return buffer.toString();
  }

  static String _buildModelFile({
    required String projectName,
    required StringCase feature,
    required StringCase rootName,
    required List<_ClassDef> classes,
    required bool extendsEntity,
  }) {
    final buffer = StringBuffer();
    if (extendsEntity) {
      buffer.writeln(
        "import 'package:$projectName/features/${feature.snakeCase}/domain/entities/${rootName.snakeCase}_entity.dart';",
      );
    } else {
      buffer.writeln("import 'package:equatable/equatable.dart';");
    }
    buffer.writeln();

    for (var i = 0; i < classes.length; i++) {
      final cls = classes[i];
      final pascal = cls.className.pascalCase;
      final superClass = extendsEntity ? '${pascal}Entity' : 'Equatable';

      buffer.writeln('class ${pascal}Model extends $superClass {');
      if (!extendsEntity) {
        for (final f in cls.fields) {
          buffer.writeln('  final ${f.dartType} ${f.fieldName};');
        }
        buffer.writeln();
      }

      // Constructor
      buffer.writeln('  const ${pascal}Model({');
      for (final f in cls.fields) {
        if (extendsEntity) {
          buffer.writeln('    required super.${f.fieldName},');
        } else {
          buffer.writeln('    required this.${f.fieldName},');
        }
      }
      buffer.writeln('  });');
      buffer.writeln();

      // fromJson (Single Object)
      buffer.writeln(
        '  factory ${pascal}Model.fromJson(Map<String, dynamic> json) {',
      );
      buffer.writeln('    return ${pascal}Model(');
      for (final f in cls.fields) {
        buffer.writeln(
          '      ${f.fieldName}: ${_fromJsonExpression(f)},',
        );
      }
      buffer.writeln('    );');
      buffer.writeln('  }');
      buffer.writeln();

      // fromJsonList (JSON List / Array)
      buffer.writeln(
        '  static List<${pascal}Model> fromJsonList(List<dynamic> jsonList) {',
      );
      buffer.writeln('    return jsonList');
      buffer.writeln(
        '        .map((e) => ${pascal}Model.fromJson(e as Map<String, dynamic>))',
      );
      buffer.writeln('        .toList();');
      buffer.writeln('  }');
      buffer.writeln();

      // toJson
      buffer.writeln('  Map<String, dynamic> toJson() {');
      buffer.writeln('    return {');
      for (final f in cls.fields) {
        buffer.writeln(
          "      '${f.jsonKey}': ${_toJsonExpression(f, extendsEntity)},",
        );
      }
      buffer.writeln('    };');
      buffer.writeln('  }');
      buffer.writeln();

      // copyWith
      buffer.writeln('  ${pascal}Model copyWith({');
      for (final f in cls.fields) {
        final paramType = extendsEntity ? f.entityType : f.dartType;
        buffer.writeln('    $paramType? ${f.fieldName},');
      }
      buffer.writeln('  }) {');
      buffer.writeln('    return ${pascal}Model(');
      for (final f in cls.fields) {
        buffer.writeln(
          '      ${f.fieldName}: ${f.fieldName} ?? this.${f.fieldName},',
        );
      }
      buffer.writeln('    );');
      buffer.writeln('  }');

      if (!extendsEntity) {
        final propsList = cls.fields.map((f) => f.fieldName).join(', ');
        buffer.writeln();
        buffer.writeln('  @override');
        buffer.writeln('  bool get stringify => true;');
        buffer.writeln();
        buffer.writeln('  @override');
        buffer.writeln('  List<Object?> get props => [$propsList];');
      }

      buffer.writeln('}');
      if (i < classes.length - 1) {
        buffer.writeln();
      }
    }

    return buffer.toString();
  }

  static String _fromJsonExpression(_FieldDef f) {
    final raw = "json['${f.jsonKey}']";
    if (f.isNestedObject) {
      return "${f.nestedClassPascal}Model.fromJson(($raw as Map<String, dynamic>?) ?? const {})";
    }
    if (f.isNestedList) {
      return "($raw as List<dynamic>?)?.map((e) => ${f.nestedClassPascal}Model.fromJson(e as Map<String, dynamic>)).toList() ?? const []";
    }
    switch (f.dartType) {
      case 'int':
        return '($raw as num?)?.toInt() ?? 0';
      case 'double':
        return '($raw as num?)?.toDouble() ?? 0.0';
      case 'bool':
        return '($raw as bool?) ?? false';
      case 'String':
        return "$raw?.toString() ?? ''";
      case 'List<String>':
        return "($raw as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const []";
      case 'List<int>':
        return "($raw as List<dynamic>?)?.map((e) => (e as num).toInt()).toList() ?? const []";
      case 'List<double>':
        return "($raw as List<dynamic>?)?.map((e) => (e as num).toDouble()).toList() ?? const []";
      case 'List<bool>':
        return "($raw as List<dynamic>?)?.map((e) => e as bool).toList() ?? const []";
      default:
        if (f.dartType.startsWith('List<')) {
          return '($raw as List<dynamic>?) ?? const []';
        }
        return raw;
    }
  }

  static String _toJsonExpression(_FieldDef f, bool extendsEntity) {
    if (f.isNestedObject) {
      if (extendsEntity) {
        return '(${f.fieldName} as ${f.nestedClassPascal}Model).toJson()';
      }
      return '${f.fieldName}.toJson()';
    }
    if (f.isNestedList) {
      if (extendsEntity) {
        return '${f.fieldName}.map((e) => (e as ${f.nestedClassPascal}Model).toJson()).toList()';
      }
      return '${f.fieldName}.map((e) => e.toJson()).toList()';
    }
    return f.fieldName;
  }
}
