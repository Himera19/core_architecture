// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'theme_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Manages the app theme mode, persisted as a preference.
///
/// Uses [StorageService] and [LoggerService] via Riverpod DI,
/// making it fully testable and consistent with the architecture.
///
/// [build] returns [ThemeMode.light] synchronously and loads the persisted
/// mode in the background, so the first frame never waits on storage.
/// A mode the user picks while that read is still in flight wins — see
/// [_loadTheme].

@ProviderFor(ThemeNotifier)
const themeProvider = ThemeNotifierProvider._();

/// Manages the app theme mode, persisted as a preference.
///
/// Uses [StorageService] and [LoggerService] via Riverpod DI,
/// making it fully testable and consistent with the architecture.
///
/// [build] returns [ThemeMode.light] synchronously and loads the persisted
/// mode in the background, so the first frame never waits on storage.
/// A mode the user picks while that read is still in flight wins — see
/// [_loadTheme].
final class ThemeNotifierProvider
    extends $NotifierProvider<ThemeNotifier, ThemeMode> {
  /// Manages the app theme mode, persisted as a preference.
  ///
  /// Uses [StorageService] and [LoggerService] via Riverpod DI,
  /// making it fully testable and consistent with the architecture.
  ///
  /// [build] returns [ThemeMode.light] synchronously and loads the persisted
  /// mode in the background, so the first frame never waits on storage.
  /// A mode the user picks while that read is still in flight wins — see
  /// [_loadTheme].
  const ThemeNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'themeProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$themeNotifierHash();

  @$internal
  @override
  ThemeNotifier create() => ThemeNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ThemeMode value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ThemeMode>(value),
    );
  }
}

String _$themeNotifierHash() => r'3ab9e3b238b272bbf83dff22a2ebd45b5d8987be';

/// Manages the app theme mode, persisted as a preference.
///
/// Uses [StorageService] and [LoggerService] via Riverpod DI,
/// making it fully testable and consistent with the architecture.
///
/// [build] returns [ThemeMode.light] synchronously and loads the persisted
/// mode in the background, so the first frame never waits on storage.
/// A mode the user picks while that read is still in flight wins — see
/// [_loadTheme].

abstract class _$ThemeNotifier extends $Notifier<ThemeMode> {
  ThemeMode build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<ThemeMode, ThemeMode>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ThemeMode, ThemeMode>,
              ThemeMode,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
