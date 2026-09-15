# Changelog

## Unreleased

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
