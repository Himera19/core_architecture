// lib/src/core/errors/purchase_failure.dart

import 'package:purchases_flutter/purchases_flutter.dart';

import 'failures.dart';

// ==================== Purchase Failures ====================

/// Purchase-specific failure with RevenueCat error parsing.
///
/// This failure type depends on `purchases_flutter` package.
/// If your project does not use in-app purchases, you can safely
/// delete this file and remove `purchases_flutter` from pubspec.yaml.
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
      return 'Purchase was cancelled';
    }

    // No offerings/products available
    if (errorString.contains('no offerings') ||
        errorString.contains('no products') ||
        errorString.contains('product not found') ||
        errorString.contains('offerings not found')) {
      return 'Product not found. Please try again later.';
    }

    // Network errors
    if (errorString.contains('network') ||
        errorString.contains('internet') ||
        errorString.contains('connection')) {
      return 'Network error. Please check your connection.';
    }

    // Store account issues
    if (errorString.contains('not signed in') ||
        errorString.contains('no account') ||
        errorString.contains('sign in required') ||
        errorString.contains('authentication required')) {
      return 'Please sign in to your store account';
    }

    // Payment issues
    if (errorString.contains('payment') || errorString.contains('billing')) {
      return 'Payment failed';
    }

    // Already purchased
    if (errorString.contains('already') || errorString.contains('owned')) {
      return 'This product has already been purchased';
    }

    // Generic error
    return 'Purchase failed';
  }

  static String _parsePurchasesErrorCode(PurchasesErrorCode errorCode) {
    switch (errorCode) {
      case PurchasesErrorCode.purchaseCancelledError:
        return 'Purchase was cancelled';
      case PurchasesErrorCode.storeProblemError:
        return 'Store error. Please try again later.';
      case PurchasesErrorCode.purchaseNotAllowedError:
        return 'Purchase not allowed';
      case PurchasesErrorCode.purchaseInvalidError:
        return 'Invalid purchase';
      case PurchasesErrorCode.productNotAvailableForPurchaseError:
        return 'Product not available for purchase';
      case PurchasesErrorCode.productAlreadyPurchasedError:
        return 'This product has already been purchased';
      case PurchasesErrorCode.networkError:
        return 'Network error';
      case PurchasesErrorCode.invalidCredentialsError:
        return 'Invalid credentials';
      case PurchasesErrorCode.unexpectedBackendResponseError:
        return 'Server error. Please try again later.';
      case PurchasesErrorCode.invalidReceiptError:
        return 'Invalid purchase receipt';
      case PurchasesErrorCode.missingReceiptFileError:
        return 'Purchase receipt not found';
      case PurchasesErrorCode.receiptAlreadyInUseError:
        return 'This purchase receipt is already in use';
      case PurchasesErrorCode.invalidAppUserIdError:
        return 'Invalid user ID';
      case PurchasesErrorCode.operationAlreadyInProgressError:
        return 'An operation is already in progress';
      case PurchasesErrorCode.unknownBackendError:
        return 'Unknown server error';
      default:
        return 'Purchase failed';
    }
  }
}
