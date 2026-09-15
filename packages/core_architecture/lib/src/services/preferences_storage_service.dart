import 'package:shared_preferences/shared_preferences.dart';

import 'storage_service.dart';
import '../core/errors/exceptions.dart';
import '../core/logging/logger_service.dart';

/// A [StorageService] for settings — the things that are not secrets.
///
/// Theme mode, onboarding flags, a remembered tab: values that must survive a
/// restart but do not need a keystore. Putting them in
/// [SecureStorageService] made every one of them a Keychain round trip, which
/// is slow on every launch, can fail on iOS before the device's first unlock,
/// and buys nothing on the web, where there is no real secure storage anyway.
///
/// Tokens and credentials still belong in [SecureStorageService].
class PreferencesStorageService implements StorageService {
  PreferencesStorageService({SharedPreferences? preferences, LoggerService? logger})
    : _preferences = preferences,
      _logger = logger ?? LoggerService();

  SharedPreferences? _preferences;
  final LoggerService _logger;

  /// Resolved on first use rather than in a constructor, so the service can be
  /// created synchronously by a provider and still await the platform.
  Future<SharedPreferences> get _instance async =>
      _preferences ??= await SharedPreferences.getInstance();

  @override
  Future<void> write({required String key, required String value}) async {
    try {
      await (await _instance).setString(key, value);
      _logger.d('Stored: $key', tag: 'Preferences');
    } catch (e, st) {
      _logger.e(
        'Write failed: $key',
        error: e,
        stackTrace: st,
        tag: 'Preferences',
      );
      throw LocalStorageException(
        message: 'Failed to write to preferences',
        data: e,
      );
    }
  }

  @override
  Future<String?> read({required String key}) async {
    try {
      // No cache of our own: SharedPreferences already keeps the whole store
      // in memory after the first load, so a second layer would only add a
      // way for the two to disagree.
      return (await _instance).getString(key);
    } catch (e, st) {
      _logger.e(
        'Read failed: $key',
        error: e,
        stackTrace: st,
        tag: 'Preferences',
      );
      throw LocalStorageException(
        message: 'Failed to read from preferences',
        data: e,
      );
    }
  }

  @override
  Future<void> delete({required String key}) async {
    try {
      await (await _instance).remove(key);
      _logger.d('Deleted: $key', tag: 'Preferences');
    } catch (e, st) {
      _logger.e(
        'Delete failed: $key',
        error: e,
        stackTrace: st,
        tag: 'Preferences',
      );
      throw LocalStorageException(
        message: 'Failed to delete from preferences',
        data: e,
      );
    }
  }

  @override
  Future<void> clearAll() async {
    try {
      await (await _instance).clear();
      _logger.i('Preferences cleared', tag: 'Preferences');
    } catch (e, st) {
      _logger.e('Clear failed', error: e, stackTrace: st, tag: 'Preferences');
      throw LocalStorageException(
        message: 'Failed to clear preferences',
        data: e,
      );
    }
  }

  @override
  Future<bool> containsKey({required String key}) async {
    try {
      return (await _instance).containsKey(key);
    } catch (e, st) {
      _logger.e(
        'containsKey failed: $key',
        error: e,
        stackTrace: st,
        tag: 'Preferences',
      );
      throw LocalStorageException(
        message: 'Failed to read from preferences',
        data: e,
      );
    }
  }
}
