// lib/src/dio/dio_config.dart

/// Configuration for [DioService].
///
/// Every field has a default, so `const DioConfig()` works against an API
/// that follows the conventions below; override only what your API does
/// differently:
///
/// ```dart
/// await DioCoreExtension.initialize(
///   config: const DioConfig(
///     receiveTimeout: Duration(seconds: 60),
///     auth: DioAuthConfig(
///       loginPath: '/v1/sessions',
///       accessTokenField: 'data.token',
///     ),
///   ),
/// );
/// ```
class DioConfig {
  /// Base URL for every request. `API_BASE_URL` from `.env` is used when null.
  final String? baseUrl;

  final Duration connectTimeout;
  final Duration receiveTimeout;
  final Duration sendTimeout;

  /// Sent with every request, on top of the JSON `Content-Type` and `Accept`.
  final Map<String, String> headers;

  final DioAuthConfig auth;

  const DioConfig({
    this.baseUrl,
    this.connectTimeout = const Duration(seconds: 30),
    this.receiveTimeout = const Duration(seconds: 30),
    this.sendTimeout = const Duration(seconds: 30),
    this.headers = const {},
    this.auth = const DioAuthConfig(),
  });
}

/// How [DioService] talks to your API's token endpoints.
///
/// Response fields are read by dotted path, so an API that nests its tokens
/// (`{"data": {"access_token": "…"}}`) is configured with
/// `accessTokenField: 'data.access_token'`.
class DioAuthConfig {
  /// `POST`ed `{identifierField: …, passwordField: …}` by `DioService.signIn`.
  final String loginPath;

  /// `POST`ed the same body plus any extra fields by `DioService.signUp`.
  /// Null when the API has no self sign-up.
  final String? registerPath;

  /// `POST`ed `{refreshRequestField: <refresh token>}` when a request gets a
  /// 401. Null turns refreshing off: a 401 then ends the session.
  final String? refreshPath;

  /// `POST`ed by `DioService.signOut` before the tokens are dropped. Null when
  /// the API keeps no server-side session; a failure here never blocks sign-out.
  final String? logoutPath;

  /// `POST`ed `{identifierField: …}` by `DioService.requestPasswordReset`.
  final String? passwordResetPath;

  final String identifierField;
  final String passwordField;

  /// Dotted path to the access token in login, register and refresh responses.
  final String accessTokenField;

  /// Dotted path to the refresh token in the same responses. A response without
  /// one keeps the refresh token already stored.
  final String refreshTokenField;

  /// Body field the refresh token is sent in.
  final String refreshRequestField;

  /// Scheme in front of the access token in the `Authorization` header.
  final String tokenType;

  const DioAuthConfig({
    this.loginPath = '/auth/login',
    this.registerPath = '/auth/register',
    this.refreshPath = '/auth/refresh',
    this.logoutPath,
    this.passwordResetPath,
    this.identifierField = 'email',
    this.passwordField = 'password',
    this.accessTokenField = 'access_token',
    this.refreshTokenField = 'refresh_token',
    this.refreshRequestField = 'refresh_token',
    this.tokenType = 'Bearer',
  });
}
