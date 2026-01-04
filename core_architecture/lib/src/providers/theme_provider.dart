import 'package:flutter/material.dart';
import 'package:core_architecture/core_architecture.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'theme_provider.g.dart';

/// Manages the app theme mode with secure persistence.
@Riverpod(keepAlive: true)
class Theme extends _$Theme {
  final LoggerService _loggerService = LoggerService();
  final StorageService _storageService = SecureStorageService();

  static const String _storageKey = 'theme_mode';

  @override
  ThemeMode build() {
    _loadTheme();
    return ThemeMode.light;
  }

  /// Loads saved theme mode from secure storage.
  Future<void> _loadTheme() async {
    try {
      final String? stored = await _storageService.read(key: _storageKey);
      if (stored == 'light') {
        state = ThemeMode.light;
      } else if (stored == 'dark') {
        state = ThemeMode.dark;
      }
      _loggerService.i('Theme loaded: ${state.name}');
    } catch (e, st) {
      _loggerService.e('Theme load failed: $e', stackTrace: st);
    }
  }

  /// Sets a specific theme mode and persists securely.
  Future<void> setThemeMode(ThemeMode mode) async {
    try {
      state = mode;
      await _storageService.write(key: _storageKey, value: mode.name);
      _loggerService.i('Theme set to ${mode.name}');
    } catch (e, st) {
      _loggerService.e('Theme set failed: $e', stackTrace: st);
    }
  }

  /// Toggles between light and dark modes and persists securely.
  Future<void> toggleTheme() async {
    try {
      final ThemeMode newMode = state == ThemeMode.light
          ? ThemeMode.dark
          : ThemeMode.light;
      state = newMode;
      await _storageService.write(key: _storageKey, value: newMode.name);
      _loggerService.i('Theme switched to ${newMode.name}');
    } catch (e, st) {
      _loggerService.e('Theme toggle failed: $e', stackTrace: st);
    }
  }
}
