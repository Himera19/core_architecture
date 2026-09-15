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
