/// Single source of truth for backend endpoints.
///
/// Override the host at build time with:
///
/// ```sh
/// flutter run --dart-define=WM_BASE_URL=https://wm.example.com
/// ```
abstract final class AppConfig {
  static const String baseUrl = String.fromEnvironment(
    'WM_BASE_URL',
    defaultValue: 'http://10.82.64.171:8080',
  );

  /// Builds a backend URL. [path] starts with a slash.
  static Uri endpoint(String path, [Map<String, String>? query]) {
    final uri = Uri.parse('$baseUrl$path');
    return query == null ? uri : uri.replace(queryParameters: query);
  }

  static Uri get loginUri => endpoint('/auth/login');
  static Uri get refreshUri => endpoint('/auth/refresh');
  static Uri get logoutUri => endpoint('/auth/logout');
  static Uri get validateTokenUri => endpoint('/auth/validate_token');
  static Uri get changeCredentialsUri => endpoint('/user/change_credentials');
}
