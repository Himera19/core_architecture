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

/// Helper function to format Supabase auth errors
String formatAuthError(Object error) {
  // Fallback to string matching for other error types
  final errorMessage = error.toString().toLowerCase();

  if (errorMessage.contains('invalid login credentials') ||
      errorMessage.contains('invalid_credentials')) {
    return 'Giriş bilgileri yanlış';
  } else if (errorMessage.contains('email not confirmed')) {
    return 'E-posta adresi doğrulanmamış';
  } else if (errorMessage.contains('user already registered')) {
    return 'Bu e-posta adresi zaten kayıtlı';
  } else if (errorMessage.contains('invalid email')) {
    return 'Geçersiz e-posta adresi';
  } else if (errorMessage.contains('password') &&
      errorMessage.contains('short')) {
    return 'Şifre çok kısa';
  } else if (errorMessage.contains('network')) {
    return 'İnternet bağlantısı hatası';
  } else if (errorMessage.contains('rate limit')) {
    return 'Çok fazla deneme yapıldı, lütfen bekleyin';
  } else if (errorMessage.contains('same_password')) {
    return 'Yeni şifreniz eski şifrenizle aynı olamaz.';
  } else if (errorMessage.contains('otp_expired')) {
    return 'Doğrulama kodu geçersiz veya daha önce kullanılmış. Lütfen yeni bir kod isteyin.';
  }

  return 'Bir hata oluştu';
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
        error: (_, __) {},
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
      throw formatAuthError(e);
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
      throw formatAuthError(e);
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      final supabase = ref.read(supabaseServiceProvider);
      await supabase.signOut();
      state = null;
    } catch (e) {
      throw formatAuthError(e);
    }
  }

  /// Request password reset
  Future<void> resetPassword(String email) async {
    try {
      final supabase = ref.read(supabaseServiceProvider);
      await supabase.client.auth.resetPasswordForEmail(email);
    } catch (e) {
      throw formatAuthError(e);
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
      throw formatAuthError(e);
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
      throw formatAuthError(e);
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
      throw formatAuthError(e);
    }
  }
}
