/// Shared source name cleaning utility to avoid duplication across widgets.
class SourceHelper {
  /// Cleans a source string: removes email addresses, capitalizes first letter,
  /// and truncates long names.
  static String cleanSource(String? source) {
    if (source == null || source.isEmpty) return 'News';
    String cleaned = source;
    if (cleaned.contains('@')) {
      if (cleaned.contains('(') && cleaned.contains(')')) {
        final start = cleaned.indexOf('(') + 1;
        final end = cleaned.lastIndexOf(')');
        if (end > start) {
          cleaned = cleaned.substring(start, end);
        } else {
          cleaned = cleaned.split('@').first;
        }
      } else {
        cleaned = cleaned.split('@').first;
      }
    }
    if (cleaned.isNotEmpty) {
      cleaned = cleaned[0].toUpperCase() + cleaned.substring(1);
    }
    return cleaned.length > 20 ? '${cleaned.substring(0, 17)}...' : cleaned;
  }
}
