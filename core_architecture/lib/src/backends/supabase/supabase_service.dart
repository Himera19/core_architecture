// lib/src/backends/supabase/supabase_service.dart

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    hide AuthException, StorageException;

import '../../core/constants/storage_constants.dart';
import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../core/logging/logger_service.dart';
import '../../services/storage_service.dart';
import '../../services/secure_storage_service.dart';


/// Clean Supabase service
final class SupabaseService {
  SupabaseService._internal({
    required LoggerService logger,
    required StorageService storage,
    required String deleteUserRpcName,
    SupabaseClient? client,
  })  : _logger = logger,
        _storage = storage,
        _deleteUserRpcName = deleteUserRpcName,
        _client = client ?? Supabase.instance.client;

  static SupabaseService? _instance;
  final LoggerService _logger;
  final StorageService _storage;
  final SupabaseClient _client;
  final String _deleteUserRpcName;

  /// Initialize Supabase from .env
  static Future<void> initialize({
    String deleteUserRpcName = 'delete_user',
  }) async {
    final url = dotenv.env['SUPABASE_URL'];
    final anonKey = dotenv.env['SUPABASE_ANON_KEY'];

    if (url == null || url.isEmpty || anonKey == null || anonKey.isEmpty) {
      throw const DatabaseException(
        message: 'SUPABASE_URL or SUPABASE_ANON_KEY not found in .env',
      );
    }

    await Supabase.initialize(url: url, anonKey: anonKey);

    _instance = SupabaseService._internal(
      logger: LoggerService(),
      storage: SecureStorageService(),
      deleteUserRpcName: deleteUserRpcName,
    );

    _instance!._logger.i(
      'Supabase initialized. URL: ${_instance!._logger.maskSensitive(url, visibleStart: 8, visibleEnd: 4)}',
      tag: 'Supabase',
    );
  }

  /// Get SupabaseService instance
  static SupabaseService get instance {
    if (_instance == null) {
      throw Exception('SupabaseService must be initialized first. Call SupabaseService.initialize()');
    }
    return _instance!;
  }

  /// Get raw Supabase client (for advanced use cases)
  SupabaseClient get client => _client;

  // ==================== Authentication ====================

  /// Sign in with email and password
  ///
  /// [onUserDataSave] is an optional callback to save additional user data.
  /// Projects can use this to save user-specific information like userId, email, etc.
  Future<User> signInWithPassword({
    required String email,
    required String password,
    Future<void> Function(User user)? onUserDataSave,
  }) async {
    try {
      _logger.d('Signing in user: $email', tag: 'SupabaseAuth');

      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw const AuthFailure(message: 'No user returned after sign-in');
      }

      // Allow projects to save additional user data
      if (onUserDataSave != null) {
        await onUserDataSave(response.user!);
      }

      _logger.i('Sign-in successful. UserID: ${response.user!.id}', tag: 'SupabaseAuth');

      return response.user!;
    } on AuthException catch (e, st) {
      _logger.e('Sign-in failed', error: e.message, stackTrace: st, tag: 'SupabaseAuth');
      throw AuthFailure(message: e.message);
    } catch (e, st) {
      _logger.e('Unexpected auth error', error: e, stackTrace: st, tag: 'SupabaseAuth');
      throw AuthFailure(message: e.toString());
    }
  }

  /// Sign up with email and password
  Future<User> signUp({
    required String email,
    required String password,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      _logger.d('Signing up user: $email', tag: 'SupabaseAuth');

      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: metadata,
      );

      if (response.user == null) {
        throw const AuthFailure(message: 'No user returned after sign-up');
      }

      _logger.i('Sign-up successful. UserID: ${response.user!.id}', tag: 'SupabaseAuth');

      return response.user!;
    } on AuthException catch (e, st) {
      _logger.e('Sign-up failed', error: e.message, stackTrace: st, tag: 'SupabaseAuth');
      throw AuthFailure(message: e.message);
    } catch (e, st) {
      _logger.e('Unexpected auth error', error: e, stackTrace: st, tag: 'SupabaseAuth');
      throw AuthFailure(message: e.toString());
    }
  }

  /// Sign out
  ///
  /// [onClearUserData] is an optional callback to clear additional user data.
  /// Projects can use this to clear user-specific information.
  Future<void> signOut({Future<void> Function()? onClearUserData}) async {
    try {
      _logger.d('Signing out user', tag: 'SupabaseAuth');

      await _client.auth.signOut();
      await _storage.delete(key: StorageConstants.accessToken);
      await _storage.delete(key: StorageConstants.refreshToken);

      // Allow projects to clear additional user data
      if (onClearUserData != null) {
        await onClearUserData();
      }

      _logger.i('Sign-out successful', tag: 'SupabaseAuth');
    } on AuthException catch (e, st) {
      _logger.e('Sign-out failed', error: e.message, stackTrace: st, tag: 'SupabaseAuth');
      throw AuthFailure(message: e.message);
    } catch (e, st) {
      _logger.e('Unexpected auth error', error: e, stackTrace: st, tag: 'SupabaseAuth');
      throw AuthFailure(message: e.toString());
    }
  }

  /// Delete user account permanently
  ///
  /// [onClearUserData] is an optional callback to clear additional user data before deletion.
  /// Projects can use this to clean up user-specific information.
  ///
  /// WARNING: This action is irreversible!
  Future<void> deleteAccount({Future<void> Function()? onClearUserData}) async {
    try {
      _logger.d('Deleting user account', tag: 'SupabaseAuth');

      // Allow projects to clear additional user data before deletion
      if (onClearUserData != null) {
        await onClearUserData();
      }

      // Delete the user account from Supabase Auth
      await _client.rpc(_deleteUserRpcName);

      // Clear stored tokens
      await _storage.delete(key: StorageConstants.accessToken);
      await _storage.delete(key: StorageConstants.refreshToken);

      _logger.i('Account deletion successful', tag: 'SupabaseAuth');
    } on AuthException catch (e, st) {
      _logger.e('Account deletion failed', error: e.message, stackTrace: st, tag: 'SupabaseAuth');
      throw AuthFailure(message: e.message);
    } catch (e, st) {
      _logger.e('Unexpected auth error during account deletion', error: e, stackTrace: st, tag: 'SupabaseAuth');
      throw AuthFailure(message: e.toString());
    }
  }

  /// Verify OTP and reset password
  Future<void> verifyOtp({
    required String email,
    required String token,
    required String newPassword,
  }) async {
    try {
      _logger.d('Verifying OTP for: $email', tag: 'SupabaseAuth');

      // 1. Verify OTP (signs in)
      final response = await _client.auth.verifyOTP(
        email: email,
        token: token,
        type: OtpType.recovery,
      );

      if (response.user == null) {
        throw const AuthFailure(message: 'OTP verification failed');
      }

      // 2. Update password
      await _client.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      _logger.i('Password reset successful', tag: 'SupabaseAuth');
    } on AuthException catch (e, st) {
      _logger.e('Password reset failed', error: e.message, stackTrace: st, tag: 'SupabaseAuth');
      throw AuthFailure(message: e.message);
    } catch (e, st) {
      _logger.e('Unexpected auth error during password reset', error: e, stackTrace: st, tag: 'SupabaseAuth');
      throw AuthFailure(message: e.toString());
    }
  }

  /// Get current user
  Future<User?> getCurrentUser() async {
    try {
      final session = _client.auth.currentSession;
      return session?.user;
    } catch (e, st) {
      _logger.e('Get current user failed', error: e, stackTrace: st, tag: 'SupabaseAuth');
      throw AuthFailure(message: e.toString());
    }
  }

  /// Check if authenticated
  bool get isAuthenticated => _client.auth.currentSession != null;

  /// Get current user ID
  String? get currentUserId => _client.auth.currentUser?.id;

  // ==================== Database Operations ====================

  /// Select data from table
  Future<List<T>> select<T>({
    required String table,
    required T Function(Map<String, dynamic> json) fromJson,
    String columns = '*',
    PostgrestFilterBuilder Function(PostgrestFilterBuilder query)? filter,
    String? orderBy,
    bool ascending = true,
    int? limit,
  }) async {
    try {
      _logger.d('Selecting from: $table', tag: 'SupabaseDB');

      dynamic query = _client.from(table).select(columns);

      if (filter != null) {
        query = filter(query as PostgrestFilterBuilder);
      }

      if (orderBy != null) {
        query = (query as PostgrestTransformBuilder).order(orderBy, ascending: ascending);
      }

      if (limit != null) {
        query = (query as PostgrestTransformBuilder).limit(limit);
      }

      final List<dynamic> response = await query;
      final data = response.map((e) => fromJson(e as Map<String, dynamic>)).toList();

      _logger.d('Select successful. Count: ${data.length}', tag: 'SupabaseDB');

      return data;
    } on PostgrestException catch (e, st) {
      _logger.e(
        'Select failed. Table: $table',
        error: e.message,
        stackTrace: st,
        tag: 'SupabaseDB',
      );
      throw DatabaseFailure(message: e.message, code: e.code);
    } catch (e, st) {
      _logger.e('Unexpected DB error', error: e, stackTrace: st, tag: 'SupabaseDB');
      throw DatabaseFailure(message: e.toString());
    }
  }

  /// Insert data into table
  Future<T> insert<T>({
    required String table,
    required Map<String, dynamic> data,
    required T Function(Map<String, dynamic> json) fromJson,
  }) async {
    try {
      _logger.d('Inserting into: $table', tag: 'SupabaseDB');

      final response = await _client.from(table).insert(data).select().single();

      final result = fromJson(response);

      _logger.d('Insert successful', tag: 'SupabaseDB');

      return result;
    } on PostgrestException catch (e, st) {
      _logger.e(
        'Insert failed. Table: $table',
        error: e.message,
        stackTrace: st,
        tag: 'SupabaseDB',
      );
      throw DatabaseFailure(message: e.message, code: e.code);
    } catch (e, st) {
      _logger.e('Unexpected DB error', error: e, stackTrace: st, tag: 'SupabaseDB');
      throw DatabaseFailure(message: e.toString());
    }
  }

  /// Update data in table
  Future<T> update<T>({
    required String table,
    required Map<String, dynamic> data,
    required PostgrestFilterBuilder Function(PostgrestFilterBuilder query) filter,
    required T Function(Map<String, dynamic> json) fromJson,
  }) async {
    try {
      _logger.d('Updating in: $table', tag: 'SupabaseDB');

      final query = _client.from(table).update(data);
      final filteredQuery = filter(query);
      final response = await filteredQuery.select().single();

      final result = fromJson(response);

      _logger.d('Update successful', tag: 'SupabaseDB');

      return result;
    } on PostgrestException catch (e, st) {
      _logger.e(
        'Update failed. Table: $table',
        error: e.message,
        stackTrace: st,
        tag: 'SupabaseDB',
      );
      throw DatabaseFailure(message: e.message, code: e.code);
    } catch (e, st) {
      _logger.e('Unexpected DB error', error: e, stackTrace: st, tag: 'SupabaseDB');
      throw DatabaseFailure(message: e.toString());
    }
  }

  /// Delete data from table
  Future<void> delete({
    required String table,
    required PostgrestFilterBuilder Function(PostgrestFilterBuilder query) filter,
  }) async {
    try {
      _logger.d('Deleting from: $table', tag: 'SupabaseDB');

      final query = _client.from(table).delete();
      final filteredQuery = filter(query);
      await filteredQuery;

      _logger.d('Delete successful', tag: 'SupabaseDB');
    } on PostgrestException catch (e, st) {
      _logger.e(
        'Delete failed. Table: $table',
        error: e.message,
        stackTrace: st,
        tag: 'SupabaseDB',
      );
      throw DatabaseFailure(message: e.message, code: e.code);
    } catch (e, st) {
      _logger.e('Unexpected DB error', error: e, stackTrace: st, tag: 'SupabaseDB');
      throw DatabaseFailure(message: e.toString());
    }
  }

  // ==================== Storage Operations ====================

  /// Upload file to storage
  Future<String> uploadFile({
    required String bucket,
    required String path,
    required List<int> bytes,
    String? contentType,
  }) async {
    try {
      _logger.d('Uploading file: $bucket/$path', tag: 'SupabaseStorage');

      await _client.storage.from(bucket).uploadBinary(
        path,
        Uint8List.fromList(bytes),
        fileOptions: FileOptions(contentType: contentType),
      );

      final url = _client.storage.from(bucket).getPublicUrl(path);

      _logger.d('Upload successful', tag: 'SupabaseStorage');

      return url;
    } on StorageException catch (e, st) {
      _logger.e('Upload failed', error: e.message, stackTrace: st, tag: 'SupabaseStorage');
      throw StorageFailure(message: e.message);
    } catch (e, st) {
      _logger.e('Unexpected storage error', error: e, stackTrace: st, tag: 'SupabaseStorage');
      throw StorageFailure(message: e.toString());
    }
  }

  /// Download file from storage
  Future<List<int>> downloadFile({
    required String bucket,
    required String path,
  }) async {
    try {
      _logger.d('Downloading file: $bucket/$path', tag: 'SupabaseStorage');

      final bytes = await _client.storage.from(bucket).download(path);

      _logger.d('Download successful', tag: 'SupabaseStorage');

      return bytes;
    } on StorageException catch (e, st) {
      _logger.e('Download failed', error: e.message, stackTrace: st, tag: 'SupabaseStorage');
      throw StorageFailure(message: e.message);
    } catch (e, st) {
      _logger.e('Unexpected storage error', error: e, stackTrace: st, tag: 'SupabaseStorage');
      throw StorageFailure(message: e.toString());
    }
  }

  /// Delete file from storage
  Future<void> deleteFile({
    required String bucket,
    required String path,
  }) async {
    try {
      _logger.d('Deleting file: $bucket/$path', tag: 'SupabaseStorage');

      await _client.storage.from(bucket).remove([path]);

      _logger.d('Delete successful', tag: 'SupabaseStorage');
    } on StorageException catch (e, st) {
      _logger.e('Delete failed', error: e.message, stackTrace: st, tag: 'SupabaseStorage');
      throw StorageFailure(message: e.message);
    } catch (e, st) {
      _logger.e('Unexpected storage error', error: e, stackTrace: st, tag: 'SupabaseStorage');
      throw StorageFailure(message: e.toString());
    }
  }
  /// Unified uploader (File, bytes, Uint8List) with userId support
  Future<String?> uploadToSupabase({
    required String bucket,
    required String userId,
    required String fileName,
    required String folder,
    List<int>? bytes,
    Uint8List? uint8list,
    File? file,
    String? contentType,
    required String logTag,
    required String logErrorMessage,
  }) async {
    try {
      final path = '$folder/$userId/$fileName';

      Uint8List finalBytes;

      // If Uint8List provided directly
      if (uint8list != null) {
        finalBytes = uint8list;
      }
      // If List<int> provided
      else if (bytes != null) {
        finalBytes = Uint8List.fromList(bytes);
      }
      // If File provided
      else if (file != null) {
        finalBytes = await file.readAsBytes();
      }
      else {
        return null;
      }

      await uploadFile(
        bucket: bucket,
        path: path,
        bytes: finalBytes,
        contentType: contentType,
      );

      return getPublicUrl(bucket: bucket, path: path);
    } catch (e, st) {
      _logger.e(
        logErrorMessage,
        error: e,
        stackTrace: st,
        tag: logTag,
      );
      rethrow;
    }
  }

  /// Get public URL for file
  String getPublicUrl({
    required String bucket,
    required String path,
  }) {
    return _client.storage.from(bucket).getPublicUrl(path);
  }

  /// Get signed URL for private file access
  ///
  /// Creates a temporary, secure URL for accessing private storage files.
  /// The URL expires after the specified duration.
  ///
  /// [bucket] - Storage bucket name
  /// [path] - File path within the bucket
  /// [expiresIn] - Duration until the URL expires (default: 1 hour)
  ///
  /// Returns a signed URL string that can be used to access the file
  Future<String> getSignedUrl({
    required String bucket,
    required String path,
    Duration expiresIn = const Duration(hours: 1),
  }) async {
    try {
      _logger.d(
        'Getting signed URL: $bucket/$path (expires in ${expiresIn.inSeconds}s)',
        tag: 'SupabaseStorage',
      );

      final signedUrl = await _client.storage.from(bucket).createSignedUrl(
        path,
        expiresIn.inSeconds,
      );

      _logger.d('Signed URL generated successfully', tag: 'SupabaseStorage');

      return signedUrl;
    } on StorageException catch (e, st) {
      _logger.e(
        'Get signed URL failed',
        error: e.message,
        stackTrace: st,
        tag: 'SupabaseStorage',
      );
      throw StorageFailure(message: e.message);
    } catch (e, st) {
      _logger.e(
        'Unexpected storage error',
        error: e,
        stackTrace: st,
        tag: 'SupabaseStorage',
      );
      throw StorageFailure(message: e.toString());
    }
  }

}