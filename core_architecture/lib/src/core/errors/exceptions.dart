// lib/src/core/errors/exceptions.dart

/// Base class for all exceptions
sealed class AppException implements Exception {
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

final class TimeoutException extends AppException {
  const TimeoutException({required super.message, super.code, super.data});
}

// ==================== Auth Exceptions ====================

final class AuthException extends AppException {
  const AuthException({required super.message, super.code, super.data});
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

final class StorageException extends AppException {
  const StorageException({required super.message, super.code, super.data});
}

// ==================== Cache Exceptions ====================

final class CacheException extends AppException {
  const CacheException({required super.message, super.code, super.data});
}

// ==================== Purchase Exceptions ====================

final class PurchaseException extends AppException {
  const PurchaseException({required super.message, super.code, super.data});
}
