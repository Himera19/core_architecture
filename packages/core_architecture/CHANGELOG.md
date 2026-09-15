# Changelog

## Unreleased

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
