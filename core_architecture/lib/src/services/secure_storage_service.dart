// core/storage/secure_storage_service.dart

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'storage_service.dart';
import '../core/errors/exceptions.dart';
import '../core/logging/logger_service.dart';

/// A [StorageService] implementation that uses [FlutterSecureStorage].
///
/// This service provides a secure way to store key-value pairs.
/// It also includes an in-memory cache to reduce the number of
/// calls to the underlying secure storage.
class SecureStorageService implements StorageService {
  final FlutterSecureStorage _secureStorage;
  final LoggerService _logger;
  final Map<String, String?> _cache = {};

  SecureStorageService({
    FlutterSecureStorage? secureStorage,
    LoggerService? logger,
  })  : _secureStorage = secureStorage ?? const FlutterSecureStorage(),
        _logger = logger ?? LoggerService();

  // ==================== Core Methods ====================

  @override
  Future<void> write({
    required String key,
    required String value,
  }) async {
    try {
      _cache[key] = value;
      await _secureStorage.write(key: key, value: value);
      _logger.d('Stored: $key', tag: 'Storage');
    } catch (e, st) {
      _logger.e('Write failed: $key', error: e, stackTrace: st, tag: 'Storage');
      throw StorageException(message: 'Failed to write to storage', data: e);
    }
  }

  @override
  Future<String?> read({required String key}) async {
    try {
      if (_cache.containsKey(key)) {
        _logger.d('Cache hit: $key', tag: 'Storage');
        return _cache[key];
      }

      final value = await _secureStorage.read(key: key);
      _cache[key] = value;

      _logger.d('Read: $key ${value != null ? '(found)' : '(null)'}', tag: 'Storage');
      return value;
    } catch (e, st) {
      _logger.e('Read failed: $key', error: e, stackTrace: st, tag: 'Storage');
      throw StorageException(message: 'Failed to read from storage', data: e);
    }
  }

  @override
  Future<void> delete({required String key}) async {
    try {
      _cache.remove(key);
      await _secureStorage.delete(key: key);
      _logger.d('Deleted: $key', tag: 'Storage');
    } catch (e, st) {
      _logger.e('Delete failed: $key', error: e, stackTrace: st, tag: 'Storage');
      throw StorageException(message: 'Failed to delete from storage', data: e);
    }
  }

  @override
  Future<void> clearAll() async {
    try {
      _cache.clear();
      await _secureStorage.deleteAll();
      _logger.i('Storage cleared', tag: 'Storage');
    } catch (e, st) {
      _logger.e('Clear failed', error: e, stackTrace: st, tag: 'Storage');
      throw StorageException(message: 'Failed to clear storage', data: e);
    }
  }

  @override
  Future<bool> containsKey({required String key}) async {
    final value = await read(key: key);
    return value != null;
  }
}
