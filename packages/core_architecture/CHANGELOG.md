# Changelog

## 6.3.0

### Fixed

- HTTP logs printed secrets in debug builds. `logRequest` and `logResponse` wrote headers and bodies
  as they were, so a sign-in logged the password, and every authenticated request and token
  response logged the tokens. They now mask any key containing `password`, `token`, `secret`,
  `authorization`, `cookie`, `apikey`, `credential` or `signature`, or equal to `otp`, `pin`,
  `cvv`, `cvc` or `ssn`, at any depth, inside JSON string bodies, and in URL query strings. A
  response is masked before it's truncated.

### Added

- `LoggerService.redact`, `redactUrl`, `isSensitiveKey` and `addSensitiveKeys`, to apply the same
  masking elsewhere and to extend it with app-specific keys.

## 6.2.0

### Added

- `initialThemeModeProvider`: the mode `themeProvider` shows until the user has picked one.
  Override it in `ProviderScope` to start an app in `ThemeMode.system` or `ThemeMode.dark`; it
  stays `ThemeMode.light` otherwise, as before. A stored choice still wins.

> There is no core 6.0.1 or 6.1.0. Those tags changed only the backend packages, so the core stayed
> at 6.0.0 until 6.2.0.

## 6.0.0

### Breaking

- `storageServiceProvider` is replaced by two providers. `secureStorageProvider` (the keychain /
  keystore) holds secrets such as tokens, and the new `preferencesStorageProvider`
  (`shared_preferences`) holds settings. An app that overrode `storageServiceProvider` in tests now
  overrides both.
- `DateHelper.dayNames` and `monthNames` are now functions taking an optional `locale`, not
  `const` Turkish lists.
- `CustomButton` corners change from `AppRadius.md` (8) to `AppRadius.lg` (16), matching what
  `AppTheme` gives every Material button. A `CustomButton` and a `FilledButton` on one screen
  used to have different corners.

### Changed

- The theme mode and the onboarding flag moved from the keystore to shared preferences. Reading
  them through the keystore cost a round trip on every launch, could fail on iOS before the
  device's first unlock, and gained nothing on the web. Values written by an older version are
  carried across on first read and then cleared from the keystore (`readMigratedSetting`), so
  nobody loses their theme or sees onboarding a second time. A value already in preferences wins,
  so migration never overwrites a newer choice.
- `DateHelper` takes day and month names from `intl` for the locale you pass, defaulting to
  `Intl.defaultLocale`, and `formatDate` / `formatTime` / `formatDateTime` take an optional
  `pattern`. The package no longer decides the app's language.
- `AppSpacings`' `w*` / `h*` / `r*` ramps share one set of constants instead of three lists of
  literals that could drift apart. `AppBreakpoints.margin` and `gutter` now come from
  `AppSpacings`.
- The dropdown sheets read the colour scheme from their own context, and sit inside a `SafeArea`
  so the confirm button clears the home indicator.

### Added

- `CustomButton(fullWidth:)`, `true` by default. The width used to be forced to infinity, so two
  buttons couldn't share a `Row` without an `Expanded` around each.
- `PreferencesStorageService`, `preferencesStorageProvider` and `readMigratedSetting`.

### Fixed

- `SecureStorageService` no longer caches a miss. A cached `null` never expired, so a key written
  later, by the native side or a fresh login, stayed invisible for the life of the app.
- `CoreInitializer` no longer logs "Storage service initialized". It was never true, since both
  stores resolve lazily on first use.

## 5.1.1

### Fixed

- Choosing `ThemeMode.system` did not survive a restart. `ThemeNotifier` saved `mode.name` but
  only recognised `"light"` and `"dark"` when reading it back, so `"system"` was silently dropped
  and the app came back up in light. The stored value is now matched against every `ThemeMode`,
  and a value it doesn't recognise still leaves the default alone.

## 5.1.0

### Added

- An app-wide loading indicator. `AppTheme.light` / `dark(loadingIndicatorBuilder:)` installs a
  `CoreComponentsTheme` extension that every `CustomButton` reads, so the spinner is chosen once
  instead of at every call site. The builder receives the asking button's foreground colour, so
  one builder serves every `ButtonType`. A button's own `loadingIndicator` still wins over the
  theme's, and Material's `CircularProgressIndicator` is the fallback.

### Fixed

- A loading `CustomButton` still took taps. It was given an empty callback, so Material treated it
  as enabled: it rippled, took focus, answered the keyboard, and a second tap could start the work
  again. It is now disabled while loading, keeping its own colours so it reads as busy rather than
  unavailable.

## 5.0.0

### Breaking

- `SpinKitIndicator` is removed, and `flutter_spinkit` is no longer a dependency. An app that
  imported `flutter_spinkit` through this package must now depend on it directly.

### Added

- `CustomButton(loadingIndicator:)` takes any widget. The default loading state is Material's
  `CircularProgressIndicator` in the button's own foreground colour.

### Fixed

- The loading spinner was always white, so an outlined button showed it white on a white surface.
  It now follows the button's foreground.
- A `CustomButton` label wider than the button overflowed instead of being trimmed. It is now one
  line, ellipsized, with or without an icon.

## 4.0.0

### Breaking

- Removed `AppTypography.fontFamily`, the `"YourFontName"` placeholder. The token styles now carry
  only size and weight, and take the family from the theme.
- Removed `TurkishPhoneFormatter`. It moved the caret to the end on every edit, so text couldn't be
  corrected mid-string. Use any `TextInputFormatter` through `inputFormatters`.
- Removed `CustomDropdownType.multiSelect`. `CustomDropdown` never handled it and silently fell back
  to single selection. Use `CustomMultiSelectDropdown`.

### Fixed

- `AppTheme(fontFamily:)` never reached the text. `AppTypography`, `CustomButton`,
  `CustomTextField` and the SnackBar helpers each stamped the placeholder family over the
  theme's, and `AppTheme` now leaves the family unset when none is passed.
- `ThemeNotifier` and `OnboardingState` threw `LateInitializationError` when a provider they watch
  rebuilt, leaving them stuck in an error state. Riverpod re-runs `build()` on the same instance,
  and their services sat in `late final` fields. `ThemeNotifier` also reads the stored mode again
  after a rebuild, rather than stranding the app on light.
- `DateHelper.getRelativeDate` counted elapsed hours, not calendar days, so a record from 23:00
  read at 01:00 the next day said "today". It now compares midnights, and daylight saving no
  longer shifts the labels.
- `CustomMultiSelectDropdown`'s validator only ever saw `null`, so a "pick at least one" rule could
  never pass. Tapping its arrow did nothing, and confirming handed the caller the sheet's own
  mutable list. All three are fixed.
- Both dropdown sheets now move up with the keyboard, which used to cover the search field and the
  confirm button.

## 3.2.0

### Fixed

- `ThemeNotifier` no longer reverts a theme the user picked during startup. `build()` kicks off
  `_loadTheme()` unawaited so the first frame never waits on the keychain, but that read used to
  write the stored mode back unconditionally when it landed — overwriting a mode chosen in the
  meantime. On a cold start the theme button looked dead for the first few hundred milliseconds:
  the UI flipped, then snapped back. A mode the user picks now wins over the pending load.
- `colorSchemeFor` carries `brandColor` into every accent slot, not just `primary` / `secondary`.
  The scheme was built with `base.copyWith(primary: …)`, and because the base schemes are `const`
  and leave the derived slots unset, `copyWith` read them through their fallback getters and wrote
  the results back as literals — freezing `primaryContainer`, `secondaryContainer`, `tertiary` and
  `inversePrimary` on the default blue. A green brand still rendered a blue progress track. The
  scheme is now seeded first and the neutrals written back on top, with the whole neutral family
  pinned explicitly so re-branding cannot tint cards or dividers.

### Changed

- `toggleTheme()` delegates to `setThemeMode()`, so persistence lives in one place. Its log line is
  now `Theme set to <mode>` rather than `Theme switched to <mode>`.
- The theme-set log is emitted right after the state assignment instead of after the storage write,
  so a trace shows when the UI actually changed. A failed write is still logged as an error, but no
  longer suppresses the state change.
- `errorContainer` / `onErrorContainer` now come from the seeded scheme when `brandColor` is given.
  They previously froze onto the flat `error` red through the same `copyWith` path. `error` and
  `onError` are unchanged.

### Added

- `theme_provider_test.dart` — 3 cases covering restore-on-start, persistence, and the startup race
  above, with a fake `StorageService` whose reads can be held open.
- The neutral-palette test now asserts all 16 neutral and error slots instead of 7, and a new case
  asserts the derived accent slots follow `brandColor`.

## 3.1.0

### Added

- `AppTheme.light()` / `AppTheme.dark()` — a single builder for both themes, with three optional
  overrides: `brandColor`, `fontFamily` and `colorScheme`. `lightTheme` and `darkTheme` are now
  shorthands for the no-argument calls and are unchanged.
- `colorSchemeFor({brightness, brandColor})` — returns the default scheme for a mode, or a
  re-branded one. `brandColor` replaces only `primary`, `onPrimary`, `secondary` and `onSecondary`,
  deriving them from `ColorScheme.fromSeed` so the `on*` pairs stay readable for any seed; the
  Slate surfaces, borders, text and the `error` pair are kept from the base scheme.
- Dark brand tokens on `AppColors`: `primaryDark`, `onPrimaryDark`, `secondaryDark`,
  `onSecondaryDark`, plus `onPrimary` and `onError`. These were previously inline literals in
  `app_color_scheme.dart` and `dark_theme.dart`, so re-coloring the dark mode meant finding four
  scattered `Color(0x…)` values.
- First tests for the package: 30 cases covering the theme builder, including a regression suite
  that asserts the refactor produces `ThemeData` identical to the v3.0.0 definitions.

### Changed

- The light and dark themes now come from one builder instead of two near-identical ~100-line
  files, which differed only in token names and two hardcoded `Color(0xFF60A5FA)` literals. Both
  themes are byte-for-byte identical to v3.0.0 — this is an internal refactor.
- Theme internals read from the `ColorScheme` (`scheme.surface`, `scheme.outline`,
  `scheme.primary`) instead of reaching for mode-specific `AppColors` members, so a re-branded
  scheme flows through to the input focus ring and outlined button borders.
- Magic numbers in the theme are bound to their tokens: `elevation: 0` → `AppElevations.none`,
  `width: 2` → `AppBorders.normal`, input padding → `AppSpacings.wMd` / `hMd`, button horizontal
  padding → `AppSpacings.wLg`. Button vertical padding stays at 14, now a named constant with the
  reason it sits off the spacing ramp.

### Documentation

- Expanded the design-token and theme reference with the actual values, and documented
  customization. Corrected several errors: there is no `AppColorScheme` class (the file exports
  `lightColorScheme` / `darkColorScheme`), `AppBorders` holds border *widths* not radii,
  `AppOpacities` holds alpha ints (0–255) for `withAlpha` not opacity fractions, the phone
  formatter is `TurkishPhoneFormatter` not `InputFormatters`, and the `Validators.compose` example
  did not compile.

## 3.0.0

### Breaking

- Removed the `CustomAppBar` and `Navbar` widgets, along with the `NavigationItem` model. Both
  were built on `go_router` (`context.pop()`, `context.go()`, `GoRouterState.of()`), which forced
  a router choice on every consumer of an otherwise routing-agnostic package. Rebuild them in
  your app with Flutter's `AppBar` / `NavigationBar` and the design tokens here.
- Dropped the `go_router` dependency and its re-export from
  `package:core_architecture/core_architecture.dart`. Apps that used `GoRouter`, `GoRoute` or
  `context.go()` through this barrel must now depend on `go_router` directly and import it
  themselves.

## 2.0.0

The package was split out of a single `core_architecture` package into a Melos-managed
monorepo. This package is now backend-agnostic and carries no backend or vendor SDK.

### Breaking

- Removed the `lib/supabase.dart` and `lib/dio.dart` barrels. The Supabase and Dio backends
  moved to [`core_architecture_supabase`](../core_architecture_supabase) and
  [`core_architecture_dio`](../core_architecture_dio), each with its own barrel that
  re-exports this package.
- Dropped the `supabase_flutter`, `dio` and `purchases_flutter` dependencies.
- `CoreConfig` is reduced to `appName` and `envFile`. The `useSupabase`, `useDio`,
  `dioBaseUrl` and `deleteUserRpcName` fields moved to the backend packages' own
  initializers.
- Removed in-app purchase support: `PurchaseFailure` and `PurchaseException` are gone.
- Renamed three exception types that shadowed names consumers routinely import:

  | Before | After | Collided with |
  | --- | --- | --- |
  | `AuthException` | `AuthenticationException` | Supabase SDK |
  | `StorageException` | `LocalStorageException` | Supabase SDK |
  | `TimeoutException` | `RequestTimeoutException` | `dart:async` |

  The old names silently rebound the SDK's and `dart:async`'s types, so an unprefixed
  `on AuthException` or `on TimeoutException` compiled but never matched what was actually
  thrown.

### Added

- `CoreInitializer.quickStart({String appName})` — zero-config startup: Flutter binding,
  `.env`, storage and logging, nothing else.
- `CoreInitializer.logger` so backend packages can log through the same sink.
- `StorageConstants` is now exported from the barrel; the backend packages depend on it.

### Fixed

- `SecureStorageService` throws `LocalStorageException` (renamed from `StorageException`).
- Generated `*.g.dart` files are committed. pub never runs `build_runner` on a dependency,
  so ignoring them shipped a package whose providers did not exist.
