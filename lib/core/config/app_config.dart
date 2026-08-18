/// Single source of truth for backend endpoints.
///
/// The host used to be duplicated in three places (auth service, tools screen,
/// profile screen); changing environments meant hunting for string literals.
/// Override at build time with:
///
/// ```sh
/// flutter run --dart-define=WM_BASE_URL=https://wm.example.com
/// ```
abstract final class AppConfig {
  static const String baseUrl = String.fromEnvironment(
    'WM_BASE_URL',
    defaultValue: 'http://10.224.81.171:8080',
  );

  static Uri get loginUri => Uri.parse('$baseUrl/auth/login');
  static Uri get validateTokenUri => Uri.parse('$baseUrl/auth/validate_token');
  static Uri get changeCredentialsUri =>
      Uri.parse('$baseUrl/user/change_credentials');

  /// Landing page shown on the "Jihozlar" tab.
  static Uri toolsUri({String? token}) => Uri.parse(
    '$baseUrl/exist.html',
  ).replace(queryParameters: {'token': ?token});
}
