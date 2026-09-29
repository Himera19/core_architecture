// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'theme_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The mode [themeProvider] shows until the user has picked one.
///
/// [ThemeMode.light] unless overridden — the default before 6.1.0:
///
/// ```dart
/// ProviderScope(
///   overrides: [initialThemeModeProvider.overrideWithValue(ThemeMode.system)],
///   child: const MyApp(),
/// )
/// ```

@ProviderFor(initialThemeMode)
const initialThemeModeProvider = InitialThemeModeProvider._();

/// The mode [themeProvider] shows until the user has picked one.
///
/// [ThemeMode.light] unless overridden — the default before 6.1.0:
///
/// ```dart
/// ProviderScope(
///   overrides: [initialThemeModeProvider.overrideWithValue(ThemeMode.system)],
///   child: const MyApp(),
/// )
/// ```

final class InitialThemeModeProvider
    extends $FunctionalProvider<ThemeMode, ThemeMode, ThemeMode>
    with $Provider<ThemeMode> {
  /// The mode [themeProvider] shows until the user has picked one.
  ///
  /// [ThemeMode.light] unless overridden — the default before 6.1.0:
  ///
  /// ```dart
  /// ProviderScope(
  ///   overrides: [initialThemeModeProvider.overrideWithValue(ThemeMode.system)],
  ///   child: const MyApp(),
  /// )
  /// ```
  const InitialThemeModeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'initialThemeModeProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$initialThemeModeHash();

  @$internal
  @override
  $ProviderElement<ThemeMode> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ThemeMode create(Ref ref) {
    return initialThemeMode(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ThemeMode value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ThemeMode>(value),
    );
  }
}

String _$initialThemeModeHash() => r'2e36ff2644e1f1de91a03c0f50e5eed8a36734c5';

/// Manages the app theme mode, persisted as a preference.
///
/// Uses [StorageService] and [LoggerService] via Riverpod DI,
/// making it fully testable and consistent with the architecture.
///
/// [build] returns [initialThemeModeProvider] synchronously and loads the persisted
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
/// [build] returns [initialThemeModeProvider] synchronously and loads the persisted
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
  /// [build] returns [initialThemeModeProvider] synchronously and loads the persisted
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

String _$themeNotifierHash() => r'ea2936ae33d18b5458cb452b07eeda19293c4bbd';

/// Manages the app theme mode, persisted as a preference.
///
/// Uses [StorageService] and [LoggerService] via Riverpod DI,
/// making it fully testable and consistent with the architecture.
///
/// [build] returns [initialThemeModeProvider] synchronously and loads the persisted
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
