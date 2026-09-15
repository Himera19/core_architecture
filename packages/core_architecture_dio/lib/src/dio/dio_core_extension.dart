// lib/src/dio/dio_core_extension.dart

import 'package:core_architecture/core_architecture.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'dio_service.dart';

/// Standalone entry point for the Dio REST backend.
///
/// This does **not** require [CoreInitializer]. It ensures the Flutter binding
/// and the environment file are ready on its own, so it can be the only
/// initialization call in `main()`:
///
/// ```dart
/// void main() async {
///   await DioCoreExtension.initialize();
///   runApp(const ProviderScope(child: MyApp()));
/// }
/// ```
///
/// It is equally safe to call it after [CoreInitializer.initialize] — the
/// binding and dotenv steps are idempotent and are skipped when already done:
///
/// ```dart
/// await CoreInitializer.initialize(const CoreConfig(appName: 'My App'));
/// await DioCoreExtension.initialize(baseUrl: 'https://api.example.com');
/// ```
class DioCoreExtension {
  const DioCoreExtension._();

  static final LoggerService _logger = LoggerService();
  static bool _isInitialized = false;

  static bool get isInitialized => _isInitialized;

  /// Initializes [DioService] with [baseUrl], falling back to `API_BASE_URL`
  /// from [envFile] when [baseUrl] is omitted.
  static Future<void> initialize({
    String? baseUrl,
    String envFile = '.env',
  }) async {
    if (_isInitialized) {
      _logger.w('Dio already initialized', tag: 'Dio');
      return;
    }

    try {
      // Safe to call repeatedly — returns the existing binding if there is one.
      WidgetsFlutterBinding.ensureInitialized();

      if (!dotenv.isInitialized) {
        await _loadEnvironment(envFile);
      }

      _logger.i('[→] Initializing Dio...', tag: 'Dio');
      await DioService.initialize(baseUrl: baseUrl);

      _isInitialized = true;
      _logger.i('[✓] Dio initialized', tag: 'Dio');
    } catch (e, st) {
      _logger.e(
        'Dio initialization failed',
        error: e,
        stackTrace: st,
        tag: 'Dio',
      );
      rethrow;
    }
  }

  static Future<void> _loadEnvironment(String envFile) async {
    try {
      await dotenv.load(fileName: envFile);
      _logger.i('[✓] Environment variables loaded', tag: 'Dio');
    } catch (e) {
      _logger.w('[!] Environment file not found: $envFile', tag: 'Dio');
    }
  }

  @visibleForTesting
  static void reset() {
    _isInitialized = false;
  }
}
