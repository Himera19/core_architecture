// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'supabase_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(supabaseService)
const supabaseServiceProvider = SupabaseServiceProvider._();

final class SupabaseServiceProvider
    extends
        $FunctionalProvider<SupabaseService, SupabaseService, SupabaseService>
    with $Provider<SupabaseService> {
  const SupabaseServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'supabaseServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$supabaseServiceHash();

  @$internal
  @override
  $ProviderElement<SupabaseService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SupabaseService create(Ref ref) {
    return supabaseService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SupabaseService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SupabaseService>(value),
    );
  }
}

String _$supabaseServiceHash() => r'c2a81d858cb3ce6df869cef502282782be78462a';

@ProviderFor(supabaseCrudClient)
const supabaseCrudClientProvider = SupabaseCrudClientProvider._();

final class SupabaseCrudClientProvider
    extends
        $FunctionalProvider<
          SupabaseCrudClient,
          SupabaseCrudClient,
          SupabaseCrudClient
        >
    with $Provider<SupabaseCrudClient> {
  const SupabaseCrudClientProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'supabaseCrudClientProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$supabaseCrudClientHash();

  @$internal
  @override
  $ProviderElement<SupabaseCrudClient> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SupabaseCrudClient create(Ref ref) {
    return supabaseCrudClient(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SupabaseCrudClient value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SupabaseCrudClient>(value),
    );
  }
}

String _$supabaseCrudClientHash() =>
    r'c8b692015825bcbe187f786dd13428f22fe238f1';

/// Stream provider for Supabase auth state changes
///
/// Use this to listen to authentication state changes (login, logout, token refresh)

@ProviderFor(authStateStream)
const authStateStreamProvider = AuthStateStreamProvider._();

/// Stream provider for Supabase auth state changes
///
/// Use this to listen to authentication state changes (login, logout, token refresh)

final class AuthStateStreamProvider
    extends
        $FunctionalProvider<AsyncValue<AuthState>, AuthState, Stream<AuthState>>
    with $FutureModifier<AuthState>, $StreamProvider<AuthState> {
  /// Stream provider for Supabase auth state changes
  ///
  /// Use this to listen to authentication state changes (login, logout, token refresh)
  const AuthStateStreamProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authStateStreamProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authStateStreamHash();

  @$internal
  @override
  $StreamProviderElement<AuthState> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<AuthState> create(Ref ref) {
    return authStateStream(ref);
  }
}

String _$authStateStreamHash() => r'ce3c74af59c40f233e636e7d7200b6b9ebc9d53e';

/// Auth provider
///
/// Returns the currently authenticated Supabase User or null

@ProviderFor(SupabaseAuth)
const supabaseAuthProvider = SupabaseAuthProvider._();

/// Auth provider
///
/// Returns the currently authenticated Supabase User or null
final class SupabaseAuthProvider
    extends $NotifierProvider<SupabaseAuth, User?> {
  /// Auth provider
  ///
  /// Returns the currently authenticated Supabase User or null
  const SupabaseAuthProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'supabaseAuthProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$supabaseAuthHash();

  @$internal
  @override
  SupabaseAuth create() => SupabaseAuth();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(User? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<User?>(value),
    );
  }
}

String _$supabaseAuthHash() => r'e6a03c36aadc03349012c8f6e039850b18109bc2';

/// Auth provider
///
/// Returns the currently authenticated Supabase User or null

abstract class _$SupabaseAuth extends $Notifier<User?> {
  User? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<User?, User?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<User?, User?>,
              User?,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
