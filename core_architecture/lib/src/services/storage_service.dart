// core/storage/storage_service.dart

/// Abstract interface for a key-value storage service.
///
/// This is a minimal, project-agnostic interface that provides only
/// the essential storage operations. Projects should extend this
/// interface or create wrapper classes with domain-specific methods
/// (e.g., token management, user data, app settings, etc.).
///
/// Example:
/// ```dart
/// class AppStorageService extends SecureStorageService {
///   Future<String?> getAccessToken() => read(key: 'access_token');
///   Future<void> saveAccessToken(String token) => write(key: 'access_token', value: token);
/// }
/// ```
abstract class StorageService {
  // ==================== Core Operations ====================

  /// Write a value to storage.
  Future<void> write({required String key, required String value});

  /// Read a value from storage.
  Future<String?> read({required String key});

  /// Delete a value from storage.
  Future<void> delete({required String key});

  /// Clear all data from storage.
  Future<void> clearAll();

  /// Check if a key exists in storage.
  Future<bool> containsKey({required String key});
}
