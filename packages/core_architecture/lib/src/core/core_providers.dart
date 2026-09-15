import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'logging/logger_service.dart';
import '../services/preferences_storage_service.dart';
import '../services/storage_service.dart';
import '../services/secure_storage_service.dart';

part 'core_providers.g.dart';

// ==================== Core Service Providers ====================

@riverpod
LoggerService loggerService(Ref ref) {
  return LoggerService();
}

/// Settings storage: theme mode, onboarding, anything that is not a secret.
///
/// Kept apart from [secureStorageProvider] because the two cost very
/// different things. This one is a plain on-device file, loaded into memory
/// once; the secure one is a keystore round trip that is slow on every launch
/// and can fail on iOS before the device's first unlock. Until 6.0.0 both went
/// through the keystore, so every app paid that price for its theme.
@Riverpod(keepAlive: true)
StorageService preferencesStorage(Ref ref) {
  return PreferencesStorageService();
}

/// Secret storage: access tokens, refresh tokens, credentials.
///
/// Backed by the platform keystore. Anything that is merely a preference
/// belongs in [preferencesStorageProvider] instead.
@Riverpod(keepAlive: true)
StorageService secureStorage(Ref ref) {
  return SecureStorageService();
}
