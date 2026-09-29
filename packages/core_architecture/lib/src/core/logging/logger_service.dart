// lib/src/core/logging/logger_service.dart

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// Centralized logging service with production filter.
///
/// The HTTP helpers — [logRequest], [logResponse], [logError] — pass
/// everything through [redact] first, so passwords, tokens, API keys and
/// cookies never reach the console, in headers, bodies or query strings.
final class LoggerService {
  LoggerService._internal({LogOutput? output})
    : _logger = Logger(
        filter: _ProductionFilter(),
        printer: PrettyPrinter(
          methodCount: 0,
          lineLength: 100,
          dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
        ),
        output: output,
      );

  static final LoggerService _instance = LoggerService._internal();
  factory LoggerService() => _instance;

  /// A separate instance writing to [output], for tests that read what was
  /// logged.
  @visibleForTesting
  factory LoggerService.withOutput(LogOutput output) =>
      LoggerService._internal(output: output);

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

  // ==================== Redaction ====================

  /// Key fragments that mark a value as secret. A key matches when, lowercased
  /// and with `-` / `_` removed, it contains one of these — so `password`,
  /// `newPassword`, `access_token`, `X-Api-Key` and `Set-Cookie` all match.
  static const Set<String> _sensitiveFragments = {
    'password',
    'passwd',
    'secret',
    'token',
    'authorization',
    'cookie',
    'apikey',
    'credential',
    'signature',
  };

  /// Keys that must match exactly, because as fragments they would catch
  /// ordinary words (`pin` in `shipping`, `otp` in `footprint`).
  static const Set<String> _sensitiveExactKeys = {
    'otp',
    'pin',
    'cvv',
    'cvc',
    'ssn',
  };

  static final Set<String> _extraSensitiveKeys = {};

  /// Adds app-specific keys to redact, matched the same way as the built-in
  /// fragments: `LoggerService.addSensitiveKeys(['iban', 'national_id'])`.
  static void addSensitiveKeys(Iterable<String> keys) =>
      _extraSensitiveKeys.addAll(keys.map(_normalizeKey));

  static String _normalizeKey(String key) =>
      key.toLowerCase().replaceAll(RegExp('[-_]'), '');

  /// Whether a value stored under [key] is masked by [redact].
  static bool isSensitiveKey(String key) {
    final normalized = _normalizeKey(key);
    return _sensitiveExactKeys.contains(normalized) ||
        _sensitiveFragments.any(normalized.contains) ||
        _extraSensitiveKeys.any(normalized.contains);
  }

  /// A copy of [value] with every sensitive entry masked, at any depth.
  ///
  /// Maps and lists are walked; a string that holds a JSON object or array is
  /// decoded, redacted and re-encoded. Everything else comes back unchanged.
  Object? redact(Object? value) {
    if (value is Map) {
      return {
        for (final entry in value.entries)
          entry.key: isSensitiveKey('${entry.key}')
              ? _maskSecret(entry.value)
              : redact(entry.value),
      };
    }
    if (value is List) return [for (final item in value) redact(item)];
    if (value is String) {
      final trimmed = value.trimLeft();
      if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
        try {
          return jsonEncode(redact(jsonDecode(value)));
        } on FormatException {
          return value;
        }
      }
    }
    return value;
  }

  /// [url] with the values of sensitive query parameters masked.
  String redactUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasQuery) return url;
    final params = uri.queryParametersAll;
    if (!params.keys.any(isSensitiveKey)) return url;

    return uri
        .replace(
          queryParameters: {
            for (final entry in params.entries)
              entry.key: isSensitiveKey(entry.key)
                  ? [for (final v in entry.value) _maskSecret(v) as String]
                  : entry.value,
          },
        )
        .toString();
  }

  /// Keeps an auth scheme (`Bearer`, `Basic`, …) and the last four characters
  /// of a long secret, enough to tell two tokens apart while debugging.
  Object _maskSecret(Object? value) {
    if (value == null) return '****';
    if (value is! String) return '****';

    final scheme = RegExp(r'^(\w+)\s+(\S+)$').firstMatch(value);
    if (scheme != null) return '${scheme[1]} ${_maskSecret(scheme[2])}';

    return value.length >= 12
        ? maskSensitive(value, visibleStart: 0, visibleEnd: 4)
        : '****';
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
    i('$method ${redactUrl(url)}', tag: 'HTTP');
    if (headers != null && headers.isNotEmpty) {
      i('Headers: ${redact(headers)}', tag: 'HTTP');
    }
    if (body != null) {
      i('Body: ${redact(body)}', tag: 'HTTP');
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
    i('$statusCode ${redactUrl(url)}', tag: 'HTTP');
    if (data != null) {
      // Redacted before truncating, so a cut can never split a secret out of
      // the key that marks it.
      final dataString = redact(data).toString();
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
    e(
      'URL: ${redactUrl(url)}',
      error: error,
      stackTrace: stackTrace,
      tag: 'HTTP',
    );
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
