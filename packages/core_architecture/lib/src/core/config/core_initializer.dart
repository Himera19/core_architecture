// lib/src/core/config/core_initializer.dart

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../logging/logger_service.dart';

/// Configuration for [CoreInitializer].
///
/// Backend setup is no longer part of this config. Each backend package ships
/// its own initializer and is called separately after [CoreInitializer]:
///
/// ```dart
/// await CoreInitializer.initialize(const CoreConfig(appName: 'My App'));
/// await SupabaseCoreExtension.initialize();   // core_architecture_supabase
/// await DioCoreExtension.initialize();        // core_architecture_dio
/// ```
class CoreConfig {
  /// Human-readable app name, used in initialization logs.
  final String appName;

  /// Dotenv file loaded during initialization. Missing files are tolerated.
  final String envFile;

  const CoreConfig({
    required this.appName,
    this.envFile = '.env',
  });
}

/// Initializes the backend-agnostic core: Flutter binding, environment
/// variables, storage and logging.
class CoreInitializer {
  static final LoggerService _logger = LoggerService();
  static bool _isInitialized = false;

  static bool get isInitialized => _isInitialized;

  /// Shared logger instance, so backend packages can log through the same sink.
  static LoggerService get logger => _logger;

  /// Full initialization driven by [CoreConfig].
  static Future<void> initialize(CoreConfig config) async {
    if (_isInitialized) {
      _logger.w('Core already initialized', tag: 'Core');
      return;
    }

    _logger.i(
      '========== INITIALIZING ${config.appName.toUpperCase()} ==========',
      tag: 'Core',
    );

    try {
      // Flutter binding
      WidgetsFlutterBinding.ensureInitialized();
      _logger.i('[✓] Flutter binding initialized', tag: 'Core');

      // Load environment
      await _loadEnvironment(config.envFile);
      // No storage line here: nothing is initialized for it. Both stores
      // resolve lazily on first use, so claiming otherwise only made the
      // startup log harder to trust.

      _isInitialized = true;
      _logger.i('========== INITIALIZATION COMPLETE ==========', tag: 'Core');
    } catch (e, st) {
      _logger.e(
        'Initialization failed',
        error: e,
        stackTrace: st,
        tag: 'Core',
      );
      rethrow;
    }
  }

  /// Zero-config initialization.
  ///
  /// Sets up the Flutter binding, loads `.env` if present, and prepares
  /// storage and logging — nothing else. Use this when you do not need a
  /// custom env file:
  ///
  /// ```dart
  /// void main() async {
  ///   await CoreInitializer.quickStart();
  ///   runApp(const ProviderScope(child: MyApp()));
  /// }
  /// ```
  static Future<void> quickStart({String appName = 'App'}) {
    return initialize(CoreConfig(appName: appName));
  }

  static Future<void> _loadEnvironment(String envFile) async {
    try {
      await dotenv.load(fileName: envFile);
      _logger.i('[✓] Environment variables loaded', tag: 'Core');
    } catch (e) {
      _logger.w('[!] Environment file not found: $envFile', tag: 'Core');
    }
  }

  @visibleForTesting
  static void reset() {
    _isInitialized = false;
  }
}
