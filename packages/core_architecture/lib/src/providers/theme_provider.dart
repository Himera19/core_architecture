import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../core/constants/storage_constants.dart';
import '../core/core_providers.dart';
import '../core/logging/logger_service.dart';
import '../services/storage_service.dart';

part 'theme_provider.g.dart';

/// Manages the app theme mode with secure persistence.
///
/// Uses [StorageService] and [LoggerService] via Riverpod DI,
/// making it fully testable and consistent with the architecture.
///
/// [build] returns [ThemeMode.light] synchronously and loads the persisted
/// mode in the background, so the first frame never waits on the keychain.
/// A mode the user picks while that read is still in flight wins — see
/// [_loadTheme].
@Riverpod(keepAlive: true)
class ThemeNotifier extends _$ThemeNotifier {
  /// Deliberately `late`, not `late final`: Riverpod re-runs [build] on the
  /// same notifier instance whenever a watched provider is rebuilt, and a
  /// second assignment to a `late final` field throws
  /// `LateInitializationError`, leaving the provider stuck in an error state.
  late LoggerService _logger;
  late StorageService _storage;

  static const String _storageKey = StorageConstants.themeMode;

  /// Set once the user picks a mode, so a late [_loadTheme] cannot undo it.
  bool _userChose = false;

  @override
  ThemeMode build() {
    _logger = ref.watch(loggerServiceProvider);
    _storage = ref.watch(storageServiceProvider);

    // A rebuild resets [state] to the default below, so the stored mode has to
    // be read again — otherwise a stale `true` here would make [_loadTheme]
    // skip the read and strand the app on light.
    _userChose = false;

    _loadTheme();
    return ThemeMode.light;
  }

  /// Loads saved theme mode from secure storage.
  ///
  /// This runs unawaited from [build], so on a slow keychain it can finish
  /// *after* the user has already toggled the theme. Writing the stored value
  /// unconditionally at that point would silently revert their choice — the
  /// UI snapping back to the old palette a moment after the tap — so a mode
  /// chosen in the meantime is left alone.
  Future<void> _loadTheme() async {
    try {
      final String? stored = await _storage.read(key: _storageKey);

      if (_userChose) {
        _logger.i(
          'Theme load ignored, user already chose ${state.name}',
          tag: 'Theme',
        );
        return;
      }

      if (stored == 'light') {
        state = ThemeMode.light;
      } else if (stored == 'dark') {
        state = ThemeMode.dark;
      }
      _logger.i('Theme loaded: ${state.name}', tag: 'Theme');
    } catch (e, st) {
      _logger.e('Theme load failed', error: e, stackTrace: st, tag: 'Theme');
    }
  }

  /// Sets a specific theme mode and persists securely.
  Future<void> setThemeMode(ThemeMode mode) async {
    _userChose = true;
    state = mode;
    // Logged before the write so the trace reflects when the UI changed, not
    // when the keychain came back.
    _logger.i('Theme set to ${mode.name}', tag: 'Theme');

    try {
      await _storage.write(key: _storageKey, value: mode.name);
    } catch (e, st) {
      _logger.e('Theme set failed', error: e, stackTrace: st, tag: 'Theme');
    }
  }

  /// Toggles between light and dark modes and persists securely.
  Future<void> toggleTheme() {
    return setThemeMode(
      state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light,
    );
  }
}

