// lib/src/core/logging/logger_service.dart

import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// Centralized logging service with production filter
final class LoggerService {
  LoggerService._internal()
    : _logger = Logger(
        filter: _ProductionFilter(),
        printer: PrettyPrinter(
          methodCount: 0,
          lineLength: 100,
          dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
        ),
      );

  static final LoggerService _instance = LoggerService._internal();
  factory LoggerService() => _instance;

  final Logger _logger;

  // ==================== Logging Methods ====================

  /// Debug log
  void d(String message, {String? tag}) =>
      _logger.d(_formatMessage(message, tag));

  /// Info log
  void i(String message, {String? tag}) =>
      _logger.i(_formatMessage(message, tag));

  /// Warning log
  void w(String message, {String? tag}) =>
      _logger.w(_formatMessage(message, tag));

  /// Error log
  void e(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    String? tag,
  }) => _logger.e(
    _formatMessage(message, tag),
    error: error,
    stackTrace: stackTrace,
  );

  /// Fatal log
  void fatal(String message, {String? tag}) =>
      _logger.f(_formatMessage(message, tag));

  // ==================== Utility Methods ====================

  /// Mask sensitive data
  String maskSensitive(
    String value, {
    int visibleStart = 2,
    int visibleEnd = 2,
  }) {
    if (value.isEmpty) return '****';
    if (value.length <= visibleStart + visibleEnd) return '*' * value.length;

    final start = value.substring(0, visibleStart);
    final end = value.substring(value.length - visibleEnd);
    final masked = '*' * (value.length - visibleStart - visibleEnd);

    return '$start$masked$end';
  }

  /// Format message with tag
  String _formatMessage(String message, String? tag) {
    return tag != null ? '[$tag] $message' : message;
  }

  /// Log network request
  void logRequest({
    required String method,
    required String url,
    Map<String, dynamic>? headers,
    dynamic body,
  }) {
    i('=========== REQUEST ===========', tag: 'HTTP');
    i('$method $url', tag: 'HTTP');
    if (headers != null && headers.isNotEmpty) {
      i('Headers: $headers', tag: 'HTTP');
    }
    if (body != null) {
      i('Body: $body', tag: 'HTTP');
    }
    i('===============================', tag: 'HTTP');
  }

  /// Log network response
  void logResponse({
    required int statusCode,
    required String url,
    dynamic data,
  }) {
    i('=========== RESPONSE ==========', tag: 'HTTP');
    i('$statusCode $url', tag: 'HTTP');
    if (data != null) {
      final dataString = data.toString();
      if (dataString.length > 500) {
        i('Body: ${dataString.substring(0, 500)}... (truncated)', tag: 'HTTP');
      } else {
        i('Body: $dataString', tag: 'HTTP');
      }
    }
    i('===============================', tag: 'HTTP');
  }

  /// Log network error
  void logError({
    required String url,
    required String error,
    StackTrace? stackTrace,
  }) {
    e('=========== ERROR =============', tag: 'HTTP');
    e('URL: $url', error: error, stackTrace: stackTrace, tag: 'HTTP');
    e('===============================', tag: 'HTTP');
  }
}

/// Production filter - only logs warnings and errors in release mode
final class _ProductionFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) {
    if (kReleaseMode) {
      return event.level.index >= Level.warning.index;
    }
    return true;
  }
}
