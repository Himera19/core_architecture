// lib/src/core/errors/failures.dart

/// Base class for all failures
sealed class Failure {
  final String message;
  final String? code;
  final dynamic data;

  const Failure({
    required this.message,
    this.code,
    this.data,
  });

  @override
  String toString() => 'Failure(message: $message, code: $code)';
}

// ==================== Network Failures ====================

final class NetworkFailure extends Failure {
  const NetworkFailure({
    required super.message,
    super.code,
    super.data,
  });
}

final class ServerFailure extends Failure {
  const ServerFailure({
    required super.message,
    super.code,
    super.data,
  });
}

final class TimeoutFailure extends Failure {
  const TimeoutFailure({
    required super.message,
    super.code,
    super.data,
  });
}

// ==================== Auth Failures ====================

final class AuthFailure extends Failure {
  const AuthFailure({
    required super.message,
    super.code,
    super.data,
  });
}

final class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure({
    required super.message,
    super.code,
    super.data,
  });
}

// ==================== Database Failures ====================

final class DatabaseFailure extends Failure {
  const DatabaseFailure({
    required super.message,
    super.code,
    super.data,
  });
}

// ==================== Validation Failures ====================

final class ValidationFailure extends Failure {
  const ValidationFailure({
    required super.message,
    super.code,
    super.data,
  });
}

// ==================== Storage Failures ====================

final class StorageFailure extends Failure {
  const StorageFailure({
    required super.message,
    super.code,
    super.data,
  });
}

// ==================== Cache Failures ====================

final class CacheFailure extends Failure {
  const CacheFailure({
    required super.message,
    super.code,
    super.data,
  });
}

// ==================== Unknown Failures ====================

final class UnknownFailure extends Failure {
  const UnknownFailure({
    required super.message,
    super.code,
    super.data,
  });
}
