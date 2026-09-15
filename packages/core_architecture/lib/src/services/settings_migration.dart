import 'storage_service.dart';
import '../core/logging/logger_service.dart';

/// Reads a setting that older versions kept in secure storage.
///
/// Until 6.0.0 the theme mode and the onboarding flag lived in the keystore
/// alongside the tokens. Moving them to [PreferencesStorageService] would have
/// read empty on every device that already had them — the app reopening in
/// light, and everyone who had finished onboarding being shown it again.
///
/// So the first read after the upgrade falls back to [legacy], copies what it
/// finds into [preferences], and clears it from the keystore. Every later read
/// finds it in preferences and never touches [legacy] again.
///
/// Returns null when neither store has the key, which is simply a first run.
Future<String?> readMigratedSetting({
  required String key,
  required StorageService preferences,
  required StorageService legacy,
  LoggerService? logger,
}) async {
  final String? current = await preferences.read(key: key);
  if (current != null) return current;

  final String? carried = await legacy.read(key: key);
  if (carried == null) return null;

  await preferences.write(key: key, value: carried);
  await legacy.delete(key: key);

  (logger ?? LoggerService()).i(
    'Migrated $key out of secure storage',
    tag: 'Settings',
  );

  return carried;
}
