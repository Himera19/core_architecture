// lib/src/core/errors/exceptions.dart

/// Base class for all exceptions.
///
/// Extend this class to add project-specific exception types.
abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic data;

  const AppException({required this.message, this.code, this.data});

  @override
  String toString() => 'AppException(message: $message, code: $code)';
}

// ==================== Network Exceptions ====================

final class NetworkException extends AppException {
  const NetworkException({required super.message, super.code, super.data});
}

final class ServerException extends AppException {
  const ServerException({required super.message, super.code, super.data});
}

/// Collides with `dart:async`'s TimeoutException, which `Future.timeout()`
/// throws — hence the `Request` prefix.
final class RequestTimeoutException extends AppException {
  const RequestTimeoutException({required super.message, super.code, super.data});
}

// ==================== Auth Exceptions ====================

/// Named to avoid colliding with the Supabase SDK's AuthException.
final class AuthenticationException extends AppException {
  const AuthenticationException({required super.message, super.code, super.data});
}

final class UnauthorizedException extends AppException {
  const UnauthorizedException({required super.message, super.code, super.data});
}

// ==================== Database Exceptions ====================

final class DatabaseException extends AppException {
  const DatabaseException({required super.message, super.code, super.data});
}

// ==================== Validation Exceptions ====================

final class ValidationException extends AppException {
  const ValidationException({required super.message, super.code, super.data});
}

// ==================== Storage Exceptions ====================

/// Local key-value storage, not a remote object store. Named to avoid
/// colliding with the Supabase SDK's StorageException.
final class LocalStorageException extends AppException {
  const LocalStorageException({required super.message, super.code, super.data});
}

// ==================== Cache Exceptions ====================

final class CacheException extends AppException {
  const CacheException({required super.message, super.code, super.data});
}
