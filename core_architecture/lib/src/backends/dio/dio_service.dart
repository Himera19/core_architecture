// lib/src/backends/dio/dio_service.dart

import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../core/logging/logger_service.dart';
import '../../services/storage_service.dart';
import '../../services/secure_storage_service.dart';

/// Dio HTTP client service
///
/// Provides configured Dio instance with interceptors for:
/// - Request/response logging
/// - Authentication token injection
/// - Error handling
final class DioService {
  DioService._internal({
    required LoggerService logger,
    required StorageService storage,
    required String baseUrl,
    Dio? dio,
  })  : _logger = logger,
        _storage = storage,
        _baseUrl = baseUrl,
        _dio = dio ?? Dio();

  static DioService? _instance;
  final LoggerService _logger;
  final StorageService _storage;
  final String _baseUrl;
  final Dio _dio;

  static Future<void> initialize({String? baseUrl}) async {
    final url = baseUrl ?? dotenv.env['API_BASE_URL'];

    if (url == null || url.isEmpty) {
      throw const NetworkException(
        message: 'API_BASE_URL not found in .env or not provided',
      );
    }

    final logger = LoggerService();
    // Import SecureStorageService properly
    final storage = SecureStorageService();

    _instance = DioService._internal(
      logger: logger,
      storage: storage,
      baseUrl: url,
    );

    await _instance!._configure();

    _instance!._logger.i(
      'Dio initialized. Base URL: ${_instance!._logger.maskSensitive(url, visibleStart: 8, visibleEnd: 4)}',
      tag: 'Dio',
    );
  }

  /// Get DioService instance
  static DioService get instance {
    if (_instance == null) {
      throw Exception(
          'DioService must be initialized first. Call DioService.initialize()');
    }
    return _instance!;
  }

  /// Get raw Dio client (for advanced use cases)
  Dio get client => _dio;

  /// Configure Dio with interceptors
  Future<void> _configure() async {
    _dio.options = BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    // Add interceptors
    _dio.interceptors.add(_createLoggingInterceptor());
    _dio.interceptors.add(await _createAuthInterceptor());
    _dio.interceptors.add(_createErrorInterceptor());
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
  Future<Interceptor> _createAuthInterceptor() async {
    return InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Get access token from storage
        final token = await _storage.read(key: 'access_token');

        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }

        handler.next(options);
      },
      onError: (error, handler) async {
        // Handle 401 Unauthorized - try to refresh token
        if (error.response?.statusCode == 401) {
          try {
            final refreshToken = await _storage.read(key: 'refresh_token');

            if (refreshToken != null) {
              // Attempt to refresh the token
              final newToken = await _refreshToken(refreshToken);

              if (newToken != null) {
                // Retry the request with new token
                error.requestOptions.headers['Authorization'] =
                    'Bearer $newToken';
                final response = await _dio.fetch(error.requestOptions);
                return handler.resolve(response);
              }
            }
          } catch (e) {
            _logger.e('Token refresh failed', error: e, tag: 'Dio');
          }
        }

        handler.next(error);
      },
    );
  }

  /// Error handling interceptor
  Interceptor _createErrorInterceptor() {
    return InterceptorsWrapper(
      onError: (error, handler) {
        final failure = _handleDioError(error);
        handler.reject(
          DioException(
            requestOptions: error.requestOptions,
            error: failure,
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
        if (statusCode == 401) {
          return UnauthorizedFailure(
            message: 'Unauthorized',
            code: statusCode.toString(),
            data: error.response?.data,
          );
        } else if (statusCode != null && statusCode >= 500) {
          return ServerFailure(
            message: 'Server error',
            code: statusCode.toString(),
            data: error.response?.data,
          );
        } else {
          return NetworkFailure(
            message: error.response?.data?['message'] ?? 'Request failed',
            code: statusCode?.toString(),
            data: error.response?.data,
          );
        }

      case DioExceptionType.cancel:
        return NetworkFailure(message: 'Request cancelled');

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

  /// Refresh authentication token
  Future<String?> _refreshToken(String refreshToken) async {
    try {
      final response = await _dio.post(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
      );

      final newAccessToken = response.data['access_token'] as String?;
      final newRefreshToken = response.data['refresh_token'] as String?;

      if (newAccessToken != null) {
        await _storage.write(key: 'access_token', value: newAccessToken);
      }
      if (newRefreshToken != null) {
        await _storage.write(key: 'refresh_token', value: newRefreshToken);
      }

      return newAccessToken;
    } catch (e) {
      _logger.e('Token refresh failed', error: e, tag: 'Dio');
      await _storage.delete(key: 'access_token');
      await _storage.delete(key: 'refresh_token');
      return null;
    }
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
