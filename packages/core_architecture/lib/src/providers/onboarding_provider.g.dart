// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'onboarding_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Whether the user has been through onboarding.
///
/// A preference, not a secret — it moved out of the keystore in 6.0.0, and a
/// flag left there by an older version is carried across on first read so
/// nobody is shown onboarding a second time.

@ProviderFor(OnboardingState)
const onboardingStateProvider = OnboardingStateProvider._();

/// Whether the user has been through onboarding.
///
/// A preference, not a secret — it moved out of the keystore in 6.0.0, and a
/// flag left there by an older version is carried across on first read so
/// nobody is shown onboarding a second time.
final class OnboardingStateProvider
    extends $AsyncNotifierProvider<OnboardingState, bool> {
  /// Whether the user has been through onboarding.
  ///
  /// A preference, not a secret — it moved out of the keystore in 6.0.0, and a
  /// flag left there by an older version is carried across on first read so
  /// nobody is shown onboarding a second time.
  const OnboardingStateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'onboardingStateProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$onboardingStateHash();

  @$internal
  @override
  OnboardingState create() => OnboardingState();
}

String _$onboardingStateHash() => r'9dd22e24493d6d5d8d78342d33b36be7d1ba975a';

/// Whether the user has been through onboarding.
///
/// A preference, not a secret — it moved out of the keystore in 6.0.0, and a
/// flag left there by an older version is carried across on first read so
/// nobody is shown onboarding a second time.

abstract class _$OnboardingState extends $AsyncNotifier<bool> {
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
