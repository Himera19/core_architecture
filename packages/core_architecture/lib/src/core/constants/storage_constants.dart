// lib/src/core/constants/storage_constants.dart

/// Central registry of all secure-storage key strings.
///
/// Using named constants prevents typos and makes key renames safe.
final class StorageConstants {
  StorageConstants._();

  static const String accessToken = 'access_token';
  static const String refreshToken = 'refresh_token';
  static const String themeMode = 'theme_mode';
  static const String onboardingSeen = 'onboarding_seen';
}
