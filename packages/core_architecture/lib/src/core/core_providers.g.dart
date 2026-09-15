// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'core_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(loggerService)
const loggerServiceProvider = LoggerServiceProvider._();

final class LoggerServiceProvider
    extends $FunctionalProvider<LoggerService, LoggerService, LoggerService>
    with $Provider<LoggerService> {
  const LoggerServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'loggerServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$loggerServiceHash();

  @$internal
  @override
  $ProviderElement<LoggerService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  LoggerService create(Ref ref) {
    return loggerService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LoggerService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LoggerService>(value),
    );
  }
}

String _$loggerServiceHash() => r'cc104855ec00db54237f00c80f82442b048c579c';

/// Settings storage: theme mode, onboarding, anything that is not a secret.
///
/// Kept apart from [secureStorageProvider] because the two cost very
/// different things. This one is a plain on-device file, loaded into memory
/// once; the secure one is a keystore round trip that is slow on every launch
/// and can fail on iOS before the device's first unlock. Until 6.0.0 both went
/// through the keystore, so every app paid that price for its theme.

@ProviderFor(preferencesStorage)
const preferencesStorageProvider = PreferencesStorageProvider._();

/// Settings storage: theme mode, onboarding, anything that is not a secret.
///
/// Kept apart from [secureStorageProvider] because the two cost very
/// different things. This one is a plain on-device file, loaded into memory
/// once; the secure one is a keystore round trip that is slow on every launch
/// and can fail on iOS before the device's first unlock. Until 6.0.0 both went
/// through the keystore, so every app paid that price for its theme.

final class PreferencesStorageProvider
    extends $FunctionalProvider<StorageService, StorageService, StorageService>
    with $Provider<StorageService> {
  /// Settings storage: theme mode, onboarding, anything that is not a secret.
  ///
  /// Kept apart from [secureStorageProvider] because the two cost very
  /// different things. This one is a plain on-device file, loaded into memory
  /// once; the secure one is a keystore round trip that is slow on every launch
  /// and can fail on iOS before the device's first unlock. Until 6.0.0 both went
  /// through the keystore, so every app paid that price for its theme.
  const PreferencesStorageProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'preferencesStorageProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$preferencesStorageHash();

  @$internal
  @override
  $ProviderElement<StorageService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  StorageService create(Ref ref) {
    return preferencesStorage(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(StorageService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<StorageService>(value),
    );
  }
}

String _$preferencesStorageHash() =>
    r'f502bc5127b8384187c31ce6dff63ff496110c19';

/// Secret storage: access tokens, refresh tokens, credentials.
///
/// Backed by the platform keystore. Anything that is merely a preference
/// belongs in [preferencesStorageProvider] instead.

@ProviderFor(secureStorage)
const secureStorageProvider = SecureStorageProvider._();

/// Secret storage: access tokens, refresh tokens, credentials.
///
/// Backed by the platform keystore. Anything that is merely a preference
/// belongs in [preferencesStorageProvider] instead.

final class SecureStorageProvider
    extends $FunctionalProvider<StorageService, StorageService, StorageService>
    with $Provider<StorageService> {
  /// Secret storage: access tokens, refresh tokens, credentials.
  ///
  /// Backed by the platform keystore. Anything that is merely a preference
  /// belongs in [preferencesStorageProvider] instead.
  const SecureStorageProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'secureStorageProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$secureStorageHash();

  @$internal
  @override
  $ProviderElement<StorageService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  StorageService create(Ref ref) {
    return secureStorage(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(StorageService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<StorageService>(value),
    );
  }
}

String _$secureStorageHash() => r'5905b43aa2033ba93dab332bffe18d501086adb6';
