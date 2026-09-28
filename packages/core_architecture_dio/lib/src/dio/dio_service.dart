// lib/src/dio/dio_service.dart

import 'dart:async';

import 'package:core_architecture/core_architecture.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'dio_config.dart';

/// Marks a request already retried after a token refresh, so a second 401 on
/// it ends the session instead of refreshing again.
const String _retriedKey = 'core_architecture_dio.retried';

/// Dio HTTP client service
///
/// Provides configured Dio instance with interceptors for:
/// - Request/response logging
/// - Authentication token injection, with one refresh-and-retry on a 401
/// - Error handling
///
/// Token endpoints (sign-in, sign-up, refresh) go through a second Dio that
/// carries no auth interceptor, so a refresh that itself gets a 401 cannot
/// trigger another refresh.
final class DioService {
  DioService._internal({
    required LoggerService logger,
    required StorageService storage,
    required String baseUrl,
    required DioConfig config,
  }) : _logger = logger,
       _storage = storage,
       _baseUrl = baseUrl,
       _config = config,
       _dio = Dio(),
       _authDio = Dio();

  static DioService? _instance;
  final LoggerService _logger;
  final StorageService _storage;
  final String _baseUrl;
  final DioConfig _config;
  final Dio _dio;
  final Dio _authDio;

  final StreamController<bool> _sessionChanges =
      StreamController<bool>.broadcast();

  /// The refresh in flight, shared by every request that got a 401 meanwhile —
  /// parallel refreshes would each rotate the refresh token and invalidate
  /// the others.
  Future<String?>? _refreshing;

  /// Initializes the service. [baseUrl] wins over [DioConfig.baseUrl], which
  /// wins over `API_BASE_URL` from `.env`.
  ///
  /// [storage] and [httpClientAdapter] exist for tests: the default storage is
  /// the platform keystore, which no test host has.
  static Future<void> initialize({
    String? baseUrl,
    DioConfig config = const DioConfig(),
    @visibleForTesting StorageService? storage,
    @visibleForTesting HttpClientAdapter? httpClientAdapter,
  }) async {
    // dotenv throws on any read before it has loaded, which would hide the
    // clearer error below when the app simply has no `.env`.
    final url =
        baseUrl ??
        config.baseUrl ??
        (dotenv.isInitialized ? dotenv.maybeGet('API_BASE_URL') : null);

    if (url == null || url.isEmpty) {
      throw const NetworkException(
        message: 'API_BASE_URL not found in .env or not provided',
      );
    }

    final logger = LoggerService();

    _instance = DioService._internal(
      logger: logger,
      storage: storage ?? SecureStorageService(),
      baseUrl: url,
      config: config,
    );

    _instance!._configure(httpClientAdapter);

    _instance!._logger.i(
      'Dio initialized. Base URL: ${_instance!._logger.maskSensitive(url, visibleStart: 8, visibleEnd: 4)}',
      tag: 'Dio',
    );
  }

  /// Get DioService instance
  static DioService get instance {
    if (_instance == null) {
      throw Exception(
        'DioService must be initialized first. Call DioService.initialize()',
      );
    }
    return _instance!;
  }

  /// Get raw Dio client (for advanced use cases)
  Dio get client => _dio;

  /// The configuration this service was initialized with.
  DioConfig get config => _config;

  /// Configure Dio with interceptors
  void _configure(HttpClientAdapter? adapter) {
    final options = BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: _config.connectTimeout,
      receiveTimeout: _config.receiveTimeout,
      sendTimeout: _config.sendTimeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        ..._config.headers,
      },
    );

    for (final dio in [_dio, _authDio]) {
      dio.options = options;
      if (adapter != null) dio.httpClientAdapter = adapter;
      dio.interceptors.add(_createLoggingInterceptor());
    }

    _dio.interceptors.add(_createAuthInterceptor());

    for (final dio in [_dio, _authDio]) {
      dio.interceptors.add(_createErrorInterceptor());
    }
  }

  /// Logging interceptor
  Interceptor _createLoggingInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) {
        _logger.logRequest(
          method: options.method,
          url: options.uri.toString(),
          headers: options.headers,
          body: options.data,
        );
        handler.next(options);
      },
      onResponse: (response, handler) {
        _logger.logResponse(
          statusCode: response.statusCode ?? 0,
          url: response.requestOptions.uri.toString(),
          data: response.data,
        );
        handler.next(response);
      },
      onError: (error, handler) {
        _logger.logError(
          url: error.requestOptions.uri.toString(),
          error: error.message ?? 'Unknown error',
          stackTrace: error.stackTrace,
        );
        handler.next(error);
      },
    );
  }

  /// Auth token interceptor
  Interceptor _createAuthInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: StorageConstants.accessToken);

        if (token != null) {
          options.headers['Authorization'] = '${_config.auth.tokenType} $token';
        }

        handler.next(options);
      },
      onError: (error, handler) async {
        final request = error.requestOptions;
        final sentToken = request.headers.containsKey('Authorization');

        if (error.response?.statusCode != 401 || !sentToken) {
          return handler.next(error);
        }

        if (request.extra[_retriedKey] != true) {
          final newToken = await _refreshAccessToken();

          if (newToken != null) {
            request.extra[_retriedKey] = true;
            try {
              // Back through the interceptors, which put the new token on.
              return handler.resolve(await _dio.fetch(request));
            } on DioException catch (retryError) {
              return handler.next(retryError);
            }
          }
        }

        // No refresh token, the refresh failed, or the retry got a 401 too.
        await _endSession();
        handler.next(error);
      },
    );
  }

  /// Error handling interceptor
  Interceptor _createErrorInterceptor() {
    return InterceptorsWrapper(
      onError: (error, handler) {
        // Already converted — a retried request passes through twice.
        if (error.error is Failure) return handler.next(error);

        handler.next(
          DioException(
            requestOptions: error.requestOptions,
            response: error.response,
            error: _handleDioError(error),
            type: error.type,
          ),
        );
      },
    );
  }

  /// Convert Dio errors to Failures
  Failure _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return TimeoutFailure(
          message: 'Request timeout',
          data: error.response?.data,
        );

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final data = error.response?.data;
        if (statusCode == 401) {
          return UnauthorizedFailure(
            message: _messageFrom(data) ?? 'Unauthorized',
            code: statusCode.toString(),
            data: data,
          );
        } else if (statusCode != null && statusCode >= 500) {
          return ServerFailure(
            message: _messageFrom(data) ?? 'Server error',
            code: statusCode.toString(),
            data: data,
          );
        } else {
          return NetworkFailure(
            message: _messageFrom(data) ?? 'Request failed',
            code: statusCode?.toString(),
            data: data,
          );
        }

      case DioExceptionType.cancel:
        return const NetworkFailure(message: 'Request cancelled');

      case DioExceptionType.connectionError:
        return NetworkFailure(
          message: 'No internet connection',
          data: error.error,
        );

      default:
        return UnknownFailure(
          message: error.message ?? 'Unknown error occurred',
          data: error.error,
        );
    }
  }

  /// The `message` of a JSON error body. Anything else — a plain-text or HTML
  /// body, a message that is not a string — gives null.
  static String? _messageFrom(Object? data) {
    if (data is Map && data['message'] is String) {
      return data['message'] as String;
    }
    return null;
  }

  // ==================== Session ====================

  /// Emits `true` when tokens are stored by a sign-in or sign-up, and `false`
  /// when they are dropped — by [signOut], or because a 401 could not be
  /// recovered by a refresh.
  Stream<bool> get sessionChanges => _sessionChanges.stream;

  /// Whether an access token is stored.
  Future<bool> hasSession() =>
      _storage.containsKey(key: StorageConstants.accessToken);

  /// Signs in against [DioAuthConfig.loginPath] and stores the tokens.
  ///
  /// Returns the whole response body, for apps that read a user out of it.
  /// Throws a [Failure] — [UnauthorizedFailure] for rejected credentials.
  Future<Map<String, dynamic>> signIn({
    required String identifier,
    required String password,
  }) {
    final auth = _config.auth;
    return _authenticate(auth.loginPath, {
      auth.identifierField: identifier,
      auth.passwordField: password,
    });
  }

  /// Signs up against [DioAuthConfig.registerPath]. [data] is merged into the
  /// body. Tokens in the response are stored; an API that answers sign-up
  /// without them (email confirmation first) leaves the user signed out.
  Future<Map<String, dynamic>> signUp({
    required String identifier,
    required String password,
    Map<String, dynamic> data = const {},
  }) {
    final auth = _config.auth;
    final path = auth.registerPath;
    if (path == null) {
      throw const AuthFailure(message: 'Sign-up is not configured');
    }
    return _authenticate(path, {
      ...data,
      auth.identifierField: identifier,
      auth.passwordField: password,
    }, requireTokens: false);
  }

  /// Asks [DioAuthConfig.passwordResetPath] to send a reset message.
  Future<void> requestPasswordReset(String identifier) async {
    final auth = _config.auth;
    final path = auth.passwordResetPath;
    if (path == null) {
      throw const AuthFailure(message: 'Password reset is not configured');
    }
    await _unwrap(
      () => _authDio.post<void>(path, data: {auth.identifierField: identifier}),
    );
  }

  /// Tells [DioAuthConfig.logoutPath] (when set) and drops the tokens. The
  /// tokens are dropped even when the server call fails.
  Future<void> signOut() async {
    final path = _config.auth.logoutPath;
    if (path != null) {
      try {
        await _dio.post<void>(path);
      } catch (e) {
        _logger.w('Logout request failed, signing out locally', tag: 'Dio');
      }
    }
    await _endSession();
  }

  /// Stores tokens obtained some other way — an OAuth redirect, a magic link —
  /// and reports the session as started.
  Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
  }) async {
    await _storage.write(key: StorageConstants.accessToken, value: accessToken);
    if (refreshToken != null) {
      await _storage.write(
        key: StorageConstants.refreshToken,
        value: refreshToken,
      );
    }
    _sessionChanges.add(true);
  }

  Future<Map<String, dynamic>> _authenticate(
    String path,
    Map<String, dynamic> body, {
    bool requireTokens = true,
  }) async {
    final response = await _unwrap(
      () => _authDio.post<Map<String, dynamic>>(path, data: body),
    );
    final data = response.data ?? const <String, dynamic>{};
    final auth = _config.auth;
    final accessToken = _readPath(data, auth.accessTokenField);

    if (accessToken == null) {
      if (!requireTokens) return data;
      throw AuthFailure(
        message:
            'No access token at "${auth.accessTokenField}" in the response',
        data: data,
      );
    }

    await saveTokens(
      accessToken: accessToken,
      refreshToken: _readPath(data, auth.refreshTokenField),
    );
    return data;
  }

  Future<String?> _refreshAccessToken() =>
      _refreshing ??= _refresh().whenComplete(() => _refreshing = null);

  Future<String?> _refresh() async {
    final auth = _config.auth;
    final path = auth.refreshPath;
    if (path == null) return null;

    final refreshToken = await _storage.read(
      key: StorageConstants.refreshToken,
    );
    if (refreshToken == null) return null;

    try {
      final response = await _authDio.post<Map<String, dynamic>>(
        path,
        data: {auth.refreshRequestField: refreshToken},
      );
      final data = response.data;
      final accessToken = _readPath(data, auth.accessTokenField);
      if (accessToken == null) return null;

      await _storage.write(
        key: StorageConstants.accessToken,
        value: accessToken,
      );
      final newRefreshToken = _readPath(data, auth.refreshTokenField);
      if (newRefreshToken != null) {
        await _storage.write(
          key: StorageConstants.refreshToken,
          value: newRefreshToken,
        );
      }
      return accessToken;
    } catch (e) {
      _logger.e('Token refresh failed', error: e, tag: 'Dio');
      return null;
    }
  }

  Future<void> _endSession() async {
    await _storage.delete(key: StorageConstants.accessToken);
    await _storage.delete(key: StorageConstants.refreshToken);
    _sessionChanges.add(false);
  }

  /// Rethrows the [Failure] the error interceptor attached, the way
  /// `DioCrudClient` does, so auth calls and CRUD calls throw the same types.
  static Future<Response<T>> _unwrap<T>(
    Future<Response<T>> Function() request,
  ) async {
    try {
      return await request();
    } on DioException catch (e) {
      final failure = e.error;
      if (failure is Failure) throw failure;
      rethrow;
    }
  }

  /// The string at a dotted [path] in [json], or null.
  static String? _readPath(Object? json, String path) {
    Object? value = json;
    for (final key in path.split('.')) {
      if (value is! Map) return null;
      value = value[key];
    }
    return value is String ? value : null;
  }

  // ==================== HTTP Methods ====================

  /// GET request
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.get<T>(
      path,
      queryParameters: queryParameters,
      options: options,
    );
  }

  /// POST request
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.post<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  /// PUT request
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.put<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  /// PATCH request
  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.patch<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  /// DELETE request
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.delete<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }
}
