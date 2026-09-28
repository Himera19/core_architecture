// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dio_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(dioService)
const dioServiceProvider = DioServiceProvider._();

final class DioServiceProvider
    extends $FunctionalProvider<DioService, DioService, DioService>
    with $Provider<DioService> {
  const DioServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dioServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dioServiceHash();

  @$internal
  @override
  $ProviderElement<DioService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  DioService create(Ref ref) {
    return dioService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DioService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DioService>(value),
    );
  }
}

String _$dioServiceHash() => r'8f3a347cd641ae29138c32cf58f030f028f9a790';

@ProviderFor(dioCrudClient)
const dioCrudClientProvider = DioCrudClientProvider._();

final class DioCrudClientProvider
    extends $FunctionalProvider<DioCrudClient, DioCrudClient, DioCrudClient>
    with $Provider<DioCrudClient> {
  const DioCrudClientProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dioCrudClientProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dioCrudClientHash();

  @$internal
  @override
  $ProviderElement<DioCrudClient> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  DioCrudClient create(Ref ref) {
    return dioCrudClient(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DioCrudClient value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DioCrudClient>(value),
    );
  }
}

String _$dioCrudClientHash() => r'c7b1d59b701c07bea4e68f25b995dbdf4020bc32';

/// Whether the user is signed in, for apps whose REST API issues the tokens.
///
/// The Dio counterpart of `SupabaseAuth`: it starts from the stored access
/// token and follows [DioService.sessionChanges], so a session that ends
/// because a refresh failed flips it to `false` without any call from the app.
/// Endpoints and token fields come from [DioAuthConfig].

@ProviderFor(DioAuth)
const dioAuthProvider = DioAuthProvider._();

/// Whether the user is signed in, for apps whose REST API issues the tokens.
///
/// The Dio counterpart of `SupabaseAuth`: it starts from the stored access
/// token and follows [DioService.sessionChanges], so a session that ends
/// because a refresh failed flips it to `false` without any call from the app.
/// Endpoints and token fields come from [DioAuthConfig].
final class DioAuthProvider extends $AsyncNotifierProvider<DioAuth, bool> {
  /// Whether the user is signed in, for apps whose REST API issues the tokens.
  ///
  /// The Dio counterpart of `SupabaseAuth`: it starts from the stored access
  /// token and follows [DioService.sessionChanges], so a session that ends
  /// because a refresh failed flips it to `false` without any call from the app.
  /// Endpoints and token fields come from [DioAuthConfig].
  const DioAuthProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dioAuthProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dioAuthHash();

  @$internal
  @override
  DioAuth create() => DioAuth();
}

String _$dioAuthHash() => r'cb13122d47def17e0c65f7a8ad2069b595888436';

/// Whether the user is signed in, for apps whose REST API issues the tokens.
///
/// The Dio counterpart of `SupabaseAuth`: it starts from the stored access
/// token and follows [DioService.sessionChanges], so a session that ends
/// because a refresh failed flips it to `false` without any call from the app.
/// Endpoints and token fields come from [DioAuthConfig].

abstract class _$DioAuth extends $AsyncNotifier<bool> {
  FutureOr<bool> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<AsyncValue<bool>, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<bool>, bool>,
              AsyncValue<bool>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
