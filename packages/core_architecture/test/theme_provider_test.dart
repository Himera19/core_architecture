import 'package:core_architecture/core_architecture.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// An in-memory [StorageService] whose reads can be held open, so a test can
/// stand where the real keychain does on a cold start: slow, and answering
/// after the user has already tapped something.
class _FakeStorage implements StorageService {
  _FakeStorage({this.readDelay = Duration.zero, Map<String, String>? seed})
    : _values = {...?seed};

  final Map<String, String> _values;
  final Duration readDelay;

  Map<String, String> get values => Map.unmodifiable(_values);

  @override
  Future<String?> read({required String key}) async {
    // The value is captured before the delay, the way a read already in flight
    // answers with what was stored when it started — not with a write that
    // landed while it was waiting. That ordering is the whole race.
    final String? value = _values[key];
    if (readDelay > Duration.zero) await Future<void>.delayed(readDelay);
    return value;
  }

  @override
  Future<void> write({required String key, required String value}) async {
    _values[key] = value;
  }

  @override
  Future<void> delete({required String key}) async => _values.remove(key);

  @override
  Future<void> clearAll() async => _values.clear();

  @override
  Future<bool> containsKey({required String key}) async =>
      _values.containsKey(key);
}

ProviderContainer _containerWith(_FakeStorage storage) {
  final container = ProviderContainer(
    overrides: [storageServiceProvider.overrideWithValue(storage)],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('ThemeNotifier', () {
    test('starts light and restores the persisted mode', () async {
      final container = _containerWith(
        _FakeStorage(seed: {StorageConstants.themeMode: 'dark'}),
      );

      expect(container.read(themeProvider), ThemeMode.light);
      await Future<void>.delayed(Duration.zero);
      expect(container.read(themeProvider), ThemeMode.dark);
    });

    test('persists the mode the user picks', () async {
      final storage = _FakeStorage();
      final container = _containerWith(storage);

      await container.read(themeProvider.notifier).toggleTheme();

      expect(container.read(themeProvider), ThemeMode.dark);
      expect(storage.values[StorageConstants.themeMode], 'dark');
    });

    test('a slow load does not undo a choice made while it was in flight', () async {
      // Regression: `_loadTheme()` runs unawaited from `build()`. It used to
      // write the stored value unconditionally, so a tap during a cold-start
      // keychain read was reverted a moment later — the theme button looked
      // dead for the first few hundred milliseconds after launch.
      final storage = _FakeStorage(
        readDelay: const Duration(milliseconds: 100),
        seed: {StorageConstants.themeMode: 'dark'},
      );
      final container = _containerWith(storage);

      // User taps while the keychain read is still outstanding.
      expect(container.read(themeProvider), ThemeMode.light);
      await container.read(themeProvider.notifier).setThemeMode(ThemeMode.light);
      expect(container.read(themeProvider), ThemeMode.light);

      // The read lands afterwards.
      await Future<void>.delayed(const Duration(milliseconds: 200));

      expect(
        container.read(themeProvider),
        ThemeMode.light,
        reason: 'the load must not overwrite the choice the user made',
      );
      expect(
        storage.values[StorageConstants.themeMode],
        'light',
        reason: 'and the choice must be what stays persisted',
      );
    });
  });
}
