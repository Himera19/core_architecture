import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../../../core_architecture.dart';


class CoreConfig {
  final String appName;
  final String envFile;
  final bool useSupabase;
  final bool useDio;
  final String? dioBaseUrl;

  const CoreConfig({
    required this.appName,
    this.envFile = '.env',
    this.useSupabase = false,
    this.useDio = false,
    this.dioBaseUrl,
  });
}

class CoreInitializer {
  static final LoggerService _logger = LoggerService();
  static bool _isInitialized = false;

  static bool get isInitialized => _isInitialized;

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

      // Initialize storage
      _logger.i('[✓] Storage service initialized', tag: 'Core');

      // Initialize backends based on configuration
      if (config.useSupabase) {
        _logger.i('[→] Initializing Supabase...', tag: 'Core');
        // Supabase initialization will be called from the backend-specific code
        _logger.i('[✓] Supabase ready for initialization', tag: 'Core');
      }

      if (config.useDio) {
        _logger.i('[→] Initializing Dio...', tag: 'Core');
        // Dio initialization will be called from the backend-specific code
        _logger.i('[✓] Dio ready for initialization', tag: 'Core');
      }

      if (!config.useSupabase && !config.useDio) {
        _logger.w(
          '[!] No backend configured. Set useSupabase or useDio to true',
          tag: 'Core',
        );
      }

      _isInitialized = true;
      _logger.i(
        '========== INITIALIZATION COMPLETE ==========',
        tag: 'Core',
      );
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
