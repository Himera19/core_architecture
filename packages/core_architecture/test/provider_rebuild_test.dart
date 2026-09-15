import 'package:core_architecture/core_architecture.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// In-memory stand-in, so the tests never touch the platform stores.
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

/// A container with both stores faked.
///
/// The settings providers read preferences and fall back to the secure store
/// once, to carry across a value written before 6.0.0 — so faking only one of
/// them would leave the other reaching for a platform channel no test host
/// has.
///
/// Returns the container rather than the override list because `Override` is
/// not part of flutter_riverpod's public surface, so it cannot be named here.
ProviderContainer _container({
  _FakeStorage? preferences,
  _FakeStorage? secure,
}) {
  final ProviderContainer container = ProviderContainer(
    overrides: [
      preferencesStorageProvider.overrideWithValue(
        preferences ?? _FakeStorage(),
      ),
      secureStorageProvider.overrideWithValue(secure ?? _FakeStorage()),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  // Riverpod re-runs build() on the *same* notifier instance when a watched
  // provider is rebuilt. With `late final` service fields that second
  // assignment threw LateInitializationError and left the provider stuck in an
  // error state, taking the app's theme down with it.
  group('notifiers survive a rebuild of a watched provider', () {
    test('themeProvider', () async {
      final ProviderContainer container = _container();

      container.listen(themeProvider, (_, _) {}, fireImmediately: true);
      expect(container.read(themeProvider), ThemeMode.light);

      container.invalidate(preferencesStorageProvider);
      await Future<void>.delayed(Duration.zero);

      expect(container.read(themeProvider), ThemeMode.light);
    });

    test('themeProvider re-reads the stored mode after a rebuild', () async {
      final ProviderContainer container = _container(
        preferences: _FakeStorage({StorageConstants.themeMode: 'dark'}),
      );

      container.listen(themeProvider, (_, _) {}, fireImmediately: true);
      await Future<void>.delayed(Duration.zero);
      expect(container.read(themeProvider), ThemeMode.dark);

      // A rebuild resets state to the light default; the persisted mode has to
      // come back, rather than the stale "user already chose" flag winning.
      container.invalidate(preferencesStorageProvider);
      await Future<void>.delayed(Duration.zero);

      expect(container.read(themeProvider), ThemeMode.dark);
    });

    test('onboardingStateProvider', () async {
      final ProviderContainer container = _container();

      container.listen(
        onboardingStateProvider,
        (_, _) {},
        fireImmediately: true,
      );
      expect(await container.read(onboardingStateProvider.future), isFalse);

      container.invalidate(preferencesStorageProvider);
      await Future<void>.delayed(Duration.zero);

      expect(await container.read(onboardingStateProvider.future), isFalse);
    });
  });

  group('every mode survives a restart', () {
    // setThemeMode persists `mode.name`, so the reader has to understand every
    // name it can write. It only knew "light" and "dark": choosing "system"
    // was written out and then quietly dropped on the next launch.
    for (final ThemeMode mode in ThemeMode.values) {
      test(mode.name, () async {
        final _FakeStorage preferences = _FakeStorage();

        final ProviderContainer first = _container(preferences: preferences);
        first.listen(themeProvider, (_, _) {}, fireImmediately: true);
        await first.read(themeProvider.notifier).setThemeMode(mode);

        expect(
          await preferences.read(key: StorageConstants.themeMode),
          mode.name,
        );

        // A fresh container is what a restart looks like to the provider.
        final ProviderContainer second = _container(preferences: preferences);
        second.listen(themeProvider, (_, _) {}, fireImmediately: true);
        await Future<void>.delayed(Duration.zero);

        expect(second.read(themeProvider), mode);
      });
    }

    test('a value nothing recognises leaves the default alone', () async {
      final ProviderContainer container = _container(
        preferences: _FakeStorage({StorageConstants.themeMode: 'chartreuse'}),
      );

      container.listen(themeProvider, (_, _) {}, fireImmediately: true);
      await Future<void>.delayed(Duration.zero);

      expect(container.read(themeProvider), ThemeMode.light);
    });
  });

  // Settings used to live in the keystore. Reading only preferences after the
  // upgrade would have looked like a first run on every device that already
  // had them: the theme back to light, and onboarding shown a second time to
  // people who had already finished it.
  group('settings written before 6.0.0 are carried across', () {
    test('the theme mode comes back, and leaves the keystore', () async {
      final _FakeStorage preferences = _FakeStorage();
      final _FakeStorage secure = _FakeStorage({
        StorageConstants.themeMode: 'dark',
      });

      final ProviderContainer container = _container(
        preferences: preferences,
        secure: secure,
      );

      container.listen(themeProvider, (_, _) {}, fireImmediately: true);
      await Future<void>.delayed(Duration.zero);

      expect(container.read(themeProvider), ThemeMode.dark);
      expect(
        await preferences.read(key: StorageConstants.themeMode),
        'dark',
        reason: 'the value should now live in preferences',
      );
      expect(
        await secure.read(key: StorageConstants.themeMode),
        isNull,
        reason: 'and no longer in the keystore',
      );
    });

    test('a finished onboarding is not shown again', () async {
      final _FakeStorage preferences = _FakeStorage();
      final _FakeStorage secure = _FakeStorage({
        StorageConstants.onboardingSeen: 'true',
      });

      final ProviderContainer container = _container(
        preferences: preferences,
        secure: secure,
      );

      expect(await container.read(onboardingStateProvider.future), isTrue);
      expect(
        await preferences.read(key: StorageConstants.onboardingSeen),
        'true',
      );
      expect(await secure.read(key: StorageConstants.onboardingSeen), isNull);
    });

    test('preferences win over a stale keystore value', () async {
      final _FakeStorage preferences = _FakeStorage({
        StorageConstants.themeMode: 'light',
      });
      final _FakeStorage secure = _FakeStorage({
        StorageConstants.themeMode: 'dark',
      });

      final ProviderContainer container = _container(
        preferences: preferences,
        secure: secure,
      );

      container.listen(themeProvider, (_, _) {}, fireImmediately: true);
      await Future<void>.delayed(Duration.zero);

      // Migration runs once; after that the keystore is not consulted, so a
      // leftover there can never override a newer choice.
      expect(container.read(themeProvider), ThemeMode.light);
      expect(await secure.read(key: StorageConstants.themeMode), 'dark');
    });

    test('an empty keystore is simply a first run', () async {
      final ProviderContainer container = _container();

      container.listen(themeProvider, (_, _) {}, fireImmediately: true);
      await Future<void>.delayed(Duration.zero);

      expect(container.read(themeProvider), ThemeMode.light);
    });
  });

  group('a user choice outlives a slow storage read', () {
    test('toggling before the load lands is not reverted', () async {
      final ProviderContainer container = _container(
        preferences: _FakeStorage({StorageConstants.themeMode: 'light'}),
      );

      container.listen(themeProvider, (_, _) {}, fireImmediately: true);
      await container.read(themeProvider.notifier).setThemeMode(ThemeMode.dark);
      await Future<void>.delayed(Duration.zero);

      expect(container.read(themeProvider), ThemeMode.dark);
    });
  });
}
