// Utilities for interpreting QR payloads as browsable URLs.

/// Returns a normalized [Uri] if [raw] can be loaded in a WebView (http/https).
///
/// Accepts:
/// - Full URLs with `http:` or `https:` schemes.
/// - Common QR payloads without a scheme (e.g. `example.com/path`) by assuming `https:`.
Uri? parseBrowsableUrl(String? raw) {
  if (raw == null) return null;
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return null;

  final direct = Uri.tryParse(trimmed);
  if (direct != null &&
      direct.hasScheme &&
      (direct.scheme == 'http' || direct.scheme == 'https') &&
      direct.host.isNotEmpty) {
    return direct;
  }

  if (!trimmed.contains('://')) {
    final guessed = Uri.tryParse('https://$trimmed');
    if (guessed != null && guessed.host.isNotEmpty) {
      return guessed;
    }
  }

  return null;
}
