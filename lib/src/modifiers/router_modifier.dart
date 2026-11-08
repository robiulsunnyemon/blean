import 'dart:io';
import 'package:path/path.dart' as p;
import '../utils/logger.dart';
import '../utils/string_case.dart';

/// Automatically registers newly created Feature/Page routes into
/// `lib/core/router/app_router.dart`.
class RouterModifier {
  static const String _importMarker = '// [BCLEAN_ROUTE_IMPORTS]';
  static const String _routeConstMarker = '// [BCLEAN_ROUTE_CONSTANTS]';
  static const String _routeMapMarker = '// [BCLEAN_ROUTE_MAP]';

  static String appRouterTemplate() => '''
import 'package:flutter/material.dart';
$_importMarker

class AppRouter {
  const AppRouter._();

  static const String initial = '/';
  $_routeConstMarker

  static Map<String, WidgetBuilder> get routes => {
        $_routeMapMarker
      };
}
''';

  static Future<void> registerRoute({
    required String projectDir,
    required String projectName,
    required StringCase feature,
    StringCase? pageName,
  }) async {
    final routerPath = p.join(projectDir, 'lib', 'core', 'router', 'app_router.dart');
    final routerFile = File(routerPath);
    if (!await routerFile.exists()) {
      return;
    }

    final page = pageName ?? feature;
    final featureSnake = feature.snakeCase;
    final pageSnake = page.snakeCase;
    final pagePascal = page.pascalCase;
    final pageCamel = page.camelCase;
    final routePath = '/${pageSnake.replaceAll('_', '-')}';

    var content = await routerFile.readAsString();
    final importLine =
        "import 'package:$projectName/features/$featureSnake/presentation/pages/${pageSnake}_page.dart';";

    if (content.contains('${pagePascal}Page(')) {
      return;
    }

    if (content.contains(_importMarker) &&
        content.contains(_routeConstMarker) &&
        content.contains(_routeMapMarker)) {
      content = content
          .replaceFirst(_importMarker, '$importLine\n$_importMarker')
          .replaceFirst(
            _routeConstMarker,
            "static const String $pageCamel = '$routePath';\n  $_routeConstMarker",
          )
          .replaceFirst(
            _routeMapMarker,
            "$pageCamel: (_) => const ${pagePascal}Page(),\n        $_routeMapMarker",
          );

      await routerFile.writeAsString(content);
      CliLogger.modified(p.relative(routerPath, from: projectDir));
    }
  }
}
