// lib/src/core/errors/failures.dart
import 'package:purchases_flutter/purchases_flutter.dart';

/// Base class for all failures
sealed class Failure {
  final String message;
  final String? code;
  final dynamic data;

  const Failure({required this.message, this.code, this.data});

  @override
  String toString() => 'Failure(message: $message, code: $code)';
}

// ==================== Network Failures ====================

final class NetworkFailure extends Failure {
  const NetworkFailure({required super.message, super.code, super.data});
}

final class ServerFailure extends Failure {
  const ServerFailure({required super.message, super.code, super.data});
}

final class TimeoutFailure extends Failure {
  const TimeoutFailure({required super.message, super.code, super.data});
}

// ==================== Auth Failures ====================

final class AuthFailure extends Failure {
  const AuthFailure({required super.message, super.code, super.data});
}

final class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure({required super.message, super.code, super.data});
}

// ==================== Database Failures ====================

final class DatabaseFailure extends Failure {
  const DatabaseFailure({required super.message, super.code, super.data});
}

// ==================== Validation Failures ====================

final class ValidationFailure extends Failure {
  const ValidationFailure({required super.message, super.code, super.data});
}

// ==================== Storage Failures ====================

final class StorageFailure extends Failure {
  const StorageFailure({required super.message, super.code, super.data});
}

// ==================== Cache Failures ====================

final class CacheFailure extends Failure {
  const CacheFailure({required super.message, super.code, super.data});
}

// ==================== Unknown Failures ====================

final class UnknownFailure extends Failure {
  const UnknownFailure({required super.message, super.code, super.data});
}

// ==================== Purchase Failures ====================

final class PurchaseFailure extends Failure {
  const PurchaseFailure({required super.message, super.code, super.data});

  factory PurchaseFailure.fromError(dynamic error) {
    return PurchaseFailure(
      message: _getUserFriendlyMessage(error),
      data: error,
    );
  }

  static String _getUserFriendlyMessage(dynamic error) {
    if (error is PurchasesErrorCode) {
      return _parsePurchasesErrorCode(error);
    }

    final errorString = error.toString().toLowerCase();

    // User cancelled the purchase
    if (errorString.contains('cancel') ||
        errorString.contains('user cancelled') ||
        errorString.contains('user canceled')) {
      return 'Satın alma iptal edildi';
    }

    // No offerings/products available
    if (errorString.contains('no offerings') ||
        errorString.contains('no products') ||
        errorString.contains('product not found') ||
        errorString.contains('offerings not found')) {
      return 'Ürün bulunamadı. Lütfen daha sonra tekrar deneyin.';
    }

    // Network errors
    if (errorString.contains('network') ||
        errorString.contains('internet') ||
        errorString.contains('connection')) {
      return 'İnternet bağlantısı hatası. Lütfen bağlantınızı kontrol edin.';
    }

    // Store account issues
    if (errorString.contains('not signed in') ||
        errorString.contains('no account') ||
        errorString.contains('sign in required') ||
        errorString.contains('authentication required')) {
      return 'Mağaza hesabınıza giriş yapmanız gerekiyor';
    }

    // Payment issues
    if (errorString.contains('payment') || errorString.contains('billing')) {
      return 'Ödeme işlemi başarısız oldu';
    }

    // Already purchased
    if (errorString.contains('already') || errorString.contains('owned')) {
      return 'Bu ürün zaten satın alınmış';
    }

    // Generic error
    return 'Satın alma işlemi başarısız oldu';
  }

  static String _parsePurchasesErrorCode(PurchasesErrorCode errorCode) {
    switch (errorCode) {
      case PurchasesErrorCode.purchaseCancelledError:
        return 'Satın alma iptal edildi';
      case PurchasesErrorCode.storeProblemError:
        return 'Mağaza hatası. Lütfen daha sonra tekrar deneyin.';
      case PurchasesErrorCode.purchaseNotAllowedError:
        return 'Satın alma izni verilmedi';
      case PurchasesErrorCode.purchaseInvalidError:
        return 'Geçersiz satın alma';
      case PurchasesErrorCode.productNotAvailableForPurchaseError:
        return 'Ürün satın alıma uygun değil';
      case PurchasesErrorCode.productAlreadyPurchasedError:
        return 'Bu ürün zaten satın alınmış';
      case PurchasesErrorCode.networkError:
        return 'İnternet bağlantısı hatası';
      case PurchasesErrorCode.invalidCredentialsError:
        return 'Geçersiz kimlik bilgileri';
      case PurchasesErrorCode.unexpectedBackendResponseError:
        return 'Sunucu hatası. Lütfen daha sonra tekrar deneyin.';
      case PurchasesErrorCode.invalidReceiptError:
        return 'Geçersiz satın alma fişi';
      case PurchasesErrorCode.missingReceiptFileError:
        return 'Satın alma fişi bulunamadı';
      case PurchasesErrorCode.receiptAlreadyInUseError:
        return 'Bu satın alma fişi zaten kullanımda';
      case PurchasesErrorCode.invalidAppUserIdError:
        return 'Geçersiz kullanıcı kimliği';
      case PurchasesErrorCode.operationAlreadyInProgressError:
        return 'Bir işlem zaten devam ediyor';
      case PurchasesErrorCode.unknownBackendError:
        return 'Bilinmeyen sunucu hatası';
      default:
        return 'Satın alma işlemi başarısız oldu';
    }
  }
}
