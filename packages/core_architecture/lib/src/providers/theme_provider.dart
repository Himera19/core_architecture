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
@Riverpod(keepAlive: true)
class ThemeNotifier extends _$ThemeNotifier {
  late final LoggerService _logger;
  late final StorageService _storage;

  static const String _storageKey = StorageConstants.themeMode;

  @override
  ThemeMode build() {
    _logger = ref.watch(loggerServiceProvider);
    _storage = ref.watch(storageServiceProvider);
    _loadTheme();
    return ThemeMode.light;
  }

  /// Loads saved theme mode from secure storage.
  Future<void> _loadTheme() async {
    try {
      final String? stored = await _storage.read(key: _storageKey);
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
    try {
      state = mode;
      await _storage.write(key: _storageKey, value: mode.name);
      _logger.i('Theme set to ${mode.name}', tag: 'Theme');
    } catch (e, st) {
      _logger.e('Theme set failed', error: e, stackTrace: st, tag: 'Theme');
    }
  }

  /// Toggles between light and dark modes and persists securely.
  Future<void> toggleTheme() async {
    try {
      final ThemeMode newMode = state == ThemeMode.light
          ? ThemeMode.dark
          : ThemeMode.light;
      state = newMode;
      await _storage.write(key: _storageKey, value: newMode.name);
      _logger.i('Theme switched to ${newMode.name}', tag: 'Theme');
    } catch (e, st) {
      _logger.e('Theme toggle failed', error: e, stackTrace: st, tag: 'Theme');
    }
  }
}

