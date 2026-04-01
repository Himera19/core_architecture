// lib/src/backends/supabase/supabase_providers.dart

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/core_providers.dart';
import 'supabase_crud_client.dart';
import 'supabase_service.dart';

part 'supabase_providers.g.dart';

// ==================== Service Providers ====================

@Riverpod(keepAlive: true)
SupabaseService supabaseService(Ref ref) {
  // This assumes SupabaseService.initialize() was called in main.dart
  return SupabaseService.instance;
}

// ==================== Backend Client Providers ====================

@Riverpod(keepAlive: true)
SupabaseCrudClient supabaseCrudClient(Ref ref) {
  final supabase = ref.watch(supabaseServiceProvider);
  final logger = ref.watch(loggerServiceProvider);

  return SupabaseCrudClient(supabase: supabase, logger: logger);
}

// ==================== Auth State Provider ====================

/// Stream provider for Supabase auth state changes
///
/// Use this to listen to authentication state changes (login, logout, token refresh)
@riverpod
Stream<AuthState> authStateStream(Ref ref) {
  final supabase = ref.watch(supabaseServiceProvider);
  return supabase.client.auth.onAuthStateChange;
}

/// Auth provider
///
/// Returns the currently authenticated Supabase User or null
@Riverpod(keepAlive: true)
class SupabaseAuth extends _$SupabaseAuth {
  @override
  User? build() {
    final supabase = ref.watch(supabaseServiceProvider);

    // Listen to auth state changes
    ref.listen(authStateStreamProvider, (previous, next) {
      next.when(
        data: (authState) {
          state = authState.session?.user;
        },
        loading: () {},
        error: (_, _) {},
      );
    });

    return supabase.client.auth.currentUser;
  }

  /// Sign in with email and password
  Future<void> signIn({required String email, required String password}) async {
    try {
      final supabase = ref.read(supabaseServiceProvider);
      final user = await supabase.signInWithPassword(
        email: email,
        password: password,
      );
      state = user;
    } catch (e) {
      rethrow;
    }
  }

  /// Sign up with email and password
  Future<User> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    try {
      final supabase = ref.read(supabaseServiceProvider);
      final user = await supabase.signUp(
        email: email,
        password: password,
        metadata: {'first_name': firstName, 'last_name': lastName},
      );
      state = user;

      return user;
    } catch (e) {
      rethrow;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      final supabase = ref.read(supabaseServiceProvider);
      await supabase.signOut();
      state = null;
    } catch (e) {
      rethrow;
    }
  }

  /// Request password reset
  Future<void> resetPassword(String email) async {
    try {
      final supabase = ref.read(supabaseServiceProvider);
      await supabase.client.auth.resetPasswordForEmail(email);
    } catch (e) {
      rethrow;
    }
  }

  /// Update user metadata
  Future<void> updateMetadata(Map<String, dynamic> metadata) async {
    try {
      final supabase = ref.read(supabaseServiceProvider);
      final response = await supabase.client.auth.updateUser(
        UserAttributes(data: metadata),
      );
      state = response.user;
    } catch (e) {
      rethrow;
    }
  }

  /// Delete user account permanently
  /// WARNING: This action is irreversible!
  Future<void> deleteAccount() async {
    try {
      final supabase = ref.read(supabaseServiceProvider);
      await supabase.deleteAccount();
      state = null;
    } catch (e) {
      rethrow;
    }
  }

  /// Verify OTP and reset password
  Future<void> verifyOtp({
    required String email,
    required String token,
    required String newPassword,
  }) async {
    try {
      final supabase = ref.read(supabaseServiceProvider);
      await supabase.verifyOtp(
        email: email,
        token: token,
        newPassword: newPassword,
      );
    } catch (e) {
      rethrow;
    }
  }
}
