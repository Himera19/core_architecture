import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../core/constants/storage_constants.dart';
import '../core/core_providers.dart';
import '../core/logging/logger_service.dart';
import '../services/settings_migration.dart';
import '../services/storage_service.dart';

part 'onboarding_provider.g.dart';

/// Whether the user has been through onboarding.
///
/// A preference, not a secret — it moved out of the keystore in 6.0.0, and a
/// flag left there by an older version is carried across on first read so
/// nobody is shown onboarding a second time.
@Riverpod(keepAlive: true)
class OnboardingState extends _$OnboardingState {
  static const String _storageKey = StorageConstants.onboardingSeen;

  /// `late`, not `late final` — see [ThemeNotifier]: Riverpod re-runs [build]
  /// on the same notifier instance, and a second assignment to a `late final`
  /// field throws `LateInitializationError`.
  late StorageService _preferences;
  late StorageService _legacySecure;
  late LoggerService _logger;

  @override
  FutureOr<bool> build() async {
    _preferences = ref.watch(preferencesStorageProvider);
    _legacySecure = ref.watch(secureStorageProvider);
    _logger = ref.watch(loggerServiceProvider);

    final String? seen = await readMigratedSetting(
      key: _storageKey,
      preferences: _preferences,
      legacy: _legacySecure,
      logger: _logger,
    );

    _logger.i('Onboarding seen: ${seen ?? "false"}', tag: 'Onboarding');
    return seen == 'true';
  }

  /// Mark onboarding as seen
  Future<void> markAsSeen() async {
    await _preferences.write(key: _storageKey, value: 'true');
    state = const AsyncValue.data(true);
    _logger.i('Onboarding marked as seen', tag: 'Onboarding');
  }

  /// Reset onboarding (for testing)
  Future<void> reset() async {
    await _preferences.delete(key: _storageKey);
    state = const AsyncValue.data(false);
    _logger.i('Onboarding reset', tag: 'Onboarding');
  }
}
