// lib/src/supabase/supabase_core_extension.dart

import 'package:core_architecture/core_architecture.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'supabase_service.dart';

/// Standalone entry point for the Supabase backend.
///
/// This does **not** require [CoreInitializer]. It ensures the Flutter binding
/// and the environment file are ready on its own, so it can be the only
/// initialization call in `main()`:
///
/// ```dart
/// void main() async {
///   await SupabaseCoreExtension.initialize();
///   runApp(const ProviderScope(child: MyApp()));
/// }
/// ```
///
/// It is equally safe to call it after [CoreInitializer.initialize] — the
/// binding and dotenv steps are idempotent and are skipped when already done:
///
/// ```dart
/// await CoreInitializer.initialize(const CoreConfig(appName: 'My App'));
/// await SupabaseCoreExtension.initialize(deleteUserRpcName: 'delete_account');
/// ```
class SupabaseCoreExtension {
  const SupabaseCoreExtension._();

  static final LoggerService _logger = LoggerService();
  static bool _isInitialized = false;

  static bool get isInitialized => _isInitialized;

  /// Reads `SUPABASE_URL` and `SUPABASE_PUBLISHABLE_KEY` (falling back to the
  /// legacy `SUPABASE_ANON_KEY`) from [envFile] and initializes
  /// [SupabaseService].
  ///
  /// [deleteUserRpcName] is the Postgres RPC invoked by
  /// `SupabaseService.deleteAccount()`. Defaults to `'delete_user'`.
  static Future<void> initialize({
    String deleteUserRpcName = 'delete_user',
    String envFile = '.env',
  }) async {
    if (_isInitialized) {
      _logger.w('Supabase already initialized', tag: 'Supabase');
      return;
    }

    try {
      // Safe to call repeatedly — returns the existing binding if there is one.
      WidgetsFlutterBinding.ensureInitialized();

      if (!dotenv.isInitialized) {
        await _loadEnvironment(envFile);
      }

      _logger.i('[→] Initializing Supabase...', tag: 'Supabase');
      await SupabaseService.initialize(deleteUserRpcName: deleteUserRpcName);

      _isInitialized = true;
      _logger.i('[✓] Supabase initialized', tag: 'Supabase');
    } catch (e, st) {
      _logger.e(
        'Supabase initialization failed',
        error: e,
        stackTrace: st,
        tag: 'Supabase',
      );
      rethrow;
    }
  }

  static Future<void> _loadEnvironment(String envFile) async {
    try {
      await dotenv.load(fileName: envFile);
      _logger.i('[✓] Environment variables loaded', tag: 'Supabase');
    } catch (e) {
      _logger.w('[!] Environment file not found: $envFile', tag: 'Supabase');
    }
  }

  @visibleForTesting
  static void reset() {
    _isInitialized = false;
  }
}
