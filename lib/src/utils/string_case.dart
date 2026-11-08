/// Utility class to convert feature/component names between cases
/// (snake_case, PascalCase, camelCase, Title Case).
class StringCase {
  final String original;
  late final List<String> _words;

  StringCase(this.original) {
    _words = _splitIntoWords(original.trim());
  }

  List<String> _splitIntoWords(String input) {
    if (input.isEmpty) return [];
    final normalized = input
        .replaceAllMapped(
          RegExp(r'([a-z0-9])([A-Z])'),
          (m) => '${m[1]}_${m[2]}',
        )
        .replaceAll(RegExp(r'[-\s]+'), '_');
    return normalized
        .split('_')
        .where((w) => w.isNotEmpty)
        .map((w) => w.toLowerCase())
        .toList();
  }

  /// e.g. `user_profile`
  String get snakeCase => _words.join('_');

  /// e.g. `UserProfile`
  String get pascalCase =>
      _words.map((w) => w[0].toUpperCase() + w.substring(1)).join();

  /// e.g. `userProfile`
  String get camelCase {
    if (_words.isEmpty) return '';
    final first = _words.first;
    final rest =
        _words.skip(1).map((w) => w[0].toUpperCase() + w.substring(1)).join();
    return '$first$rest';
  }

  /// e.g. `User Profile`
  String get titleCase =>
      _words.map((w) => w[0].toUpperCase() + w.substring(1)).join(' ');
}
