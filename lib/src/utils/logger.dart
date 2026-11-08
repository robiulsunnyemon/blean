import 'dart:io';

/// Lightweight colored console logger for CLI output.
class CliLogger {
  static const String _reset = '\x1B[0m';
  static const String _green = '\x1B[32m';
  static const String _cyan = '\x1B[36m';
  static const String _yellow = '\x1B[33m';
  static const String _red = '\x1B[31m';
  static const String _bold = '\x1B[1m';

  static void info(String message) {
    stdout.writeln('$_cyanℹ$_reset $message');
  }

  static void success(String message) {
    stdout.writeln('$_green✔$_reset $_bold$message$_reset');
  }

  static void created(String relativePath) {
    stdout.writeln('  ${_green}CREATE$_reset $relativePath');
  }

  static void modified(String relativePath) {
    stdout.writeln('  ${_yellow}UPDATE$_reset $relativePath');
  }

  static void warn(String message) {
    stdout.writeln('$_yellow⚠ $message$_reset');
  }

  static void error(String message) {
    stderr.writeln('$_red✖ Error: $message$_reset');
  }
}
