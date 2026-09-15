import 'package:core_architecture/core_architecture.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// In-memory stand-in, so the tests never touch the platform keychain.
class _FakeStorage implements StorageService {
  _FakeStorage([Map<String, String>? seed]) : _m = {...?seed};

  final Map<String, String> _m;

  @override
  Future<void> write({required String key, required String value}) async =>
      _m[key] = value;

  @override
  Future<String?> read({required String key}) async => _m[key];

  @override
  Future<void> delete({required String key}) async => _m.remove(key);

  @override
  Future<void> clearAll() async => _m.clear();

  @override
  Future<bool> containsKey({required String key}) async => _m.containsKey(key);
}

void main() {
  // Riverpod re-runs build() on the *same* notifier instance when a watched
  // provider is rebuilt. With `late final` service fields that second
  // assignment threw LateInitializationError and left the provider stuck in an
  // error state, taking the app's theme down with it.
  group('notifiers survive a rebuild of a watched provider', () {
    test('themeProvider', () async {
      final container = ProviderContainer(
        overrides: [storageServiceProvider.overrideWithValue(_FakeStorage())],
      );
      addTearDown(container.dispose);

      container.listen(themeProvider, (_, _) {}, fireImmediately: true);
      expect(container.read(themeProvider), ThemeMode.light);

      container.invalidate(storageServiceProvider);
      await Future<void>.delayed(Duration.zero);

      expect(container.read(themeProvider), ThemeMode.light);
    });

    test('themeProvider re-reads the stored mode after a rebuild', () async {
      final container = ProviderContainer(
        overrides: [
          storageServiceProvider.overrideWithValue(
            _FakeStorage({StorageConstants.themeMode: 'dark'}),
          ),
        ],
      );
      addTearDown(container.dispose);

      container.listen(themeProvider, (_, _) {}, fireImmediately: true);
      await Future<void>.delayed(Duration.zero);
      expect(container.read(themeProvider), ThemeMode.dark);

      // A rebuild resets state to the light default; the persisted mode has to
      // come back, rather than the stale "user already chose" flag winning.
      container.invalidate(storageServiceProvider);
      await Future<void>.delayed(Duration.zero);

      expect(container.read(themeProvider), ThemeMode.dark);
    });

    test('onboardingStateProvider', () async {
      final container = ProviderContainer(
        overrides: [storageServiceProvider.overrideWithValue(_FakeStorage())],
      );
      addTearDown(container.dispose);

      container.listen(onboardingStateProvider, (_, _) {},
          fireImmediately: true);
      expect(await container.read(onboardingStateProvider.future), isFalse);

      container.invalidate(storageServiceProvider);
      await Future<void>.delayed(Duration.zero);

      expect(await container.read(onboardingStateProvider.future), isFalse);
    });
  });

  group('a user choice outlives a slow storage read', () {
    test('toggling before the load lands is not reverted', () async {
      final container = ProviderContainer(
        overrides: [
          storageServiceProvider.overrideWithValue(
            _FakeStorage({StorageConstants.themeMode: 'light'}),
          ),
        ],
      );
      addTearDown(container.dispose);

      container.listen(themeProvider, (_, _) {}, fireImmediately: true);
      await container.read(themeProvider.notifier).setThemeMode(ThemeMode.dark);
      await Future<void>.delayed(Duration.zero);

      expect(container.read(themeProvider), ThemeMode.dark);
    });
  });
}
