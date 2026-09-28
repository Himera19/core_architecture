# Changelog

## 6.1.0

### Added

- `DioConfig` and `DioAuthConfig`, passed as `DioCoreExtension.initialize(config: …)`. Timeouts,
  extra headers, the login / register / refresh / logout / password-reset paths, the request field
  names, the dotted paths of the tokens in responses and the `Authorization` scheme were all
  hard-coded; each is now a field with the old value as its default.
- `dioAuthProvider` and `DioService.signIn` / `signUp` / `signOut` / `requestPasswordReset` /
  `saveTokens` / `hasSession` / `sessionChanges` — the auth flow the Supabase package already had.

### Fixed

- A refresh that got a 401 could refresh again: it ran on the same `Dio` as the request that failed,
  through the same 401 handler. Token endpoints now use a second `Dio` without it, and a retried
  request that is still rejected ends the session instead of refreshing again.
- Parallel requests that got a 401 each ran their own refresh, so an API that rotates refresh tokens
  rejected all but the first. They now share one.
- A 401 on a request that carried no token is no longer treated as an expired session.
- A non-JSON error body (a plain-text 502 from a proxy) threw a `TypeError` out of the error
  mapping instead of giving a `Failure`. The failure types for 4xx responses in the README now
  match the code: `NetworkFailure`, with `ServerFailure` for 5xx only.
- A missing `.env` surfaced as dotenv's `NotInitializedError` instead of the "`API_BASE_URL` not
  found" `NetworkException`.

## 6.0.1

### Fixed

- The `core_architecture` git dependency pointed at `v3.2.0`, a tag that no longer exists on
  origin. A fresh checkout failed to resolve, and a machine whose pub cache still held the tag
  silently got core 3.2.0 instead of 6.0.0. It is now pinned to `v6.0.0`, and this package's
  version follows the core again. The package's own API is unchanged.

## 3.2.0

Version bump to track `core_architecture` 3.2.0. This package's own API is unchanged. The core it
re-exports fixes a startup race that reverted the user's theme choice, and `brandColor` now reaches
every accent slot instead of only `primary` and `secondary`.

## 3.1.0

Version bump to track `core_architecture` 3.1.0. This package's own API is unchanged. The core it
re-exports gains `AppTheme.light()` / `AppTheme.dark()` for re-branding the design system, and the
dark brand colors are now named tokens on `AppColors`.

## 3.0.0

Version bump to track `core_architecture` 3.0.0. This package's own API is unchanged, but the
core it re-exports no longer ships `CustomAppBar`, `Navbar` or `go_router`.

## 2.0.0

Initial release. The Dio REST backend was extracted from `core_architecture` v1.x so that
projects without a REST backend no longer pull in `dio`.

### Added

- `DioCoreExtension.initialize({String? baseUrl, String envFile})` — a standalone entry point
  that sets up the Flutter binding and loads `.env` itself, so `CoreInitializer` is optional.
  Both steps are idempotent, so it also composes with it.
- `lib/core_architecture_dio.dart` barrel, re-exporting `core_architecture` and `dio`.

### Changed

- `DioService`, `DioCrudClient` and the Dio providers moved here from
  `core_architecture/lib/src/backends/dio/`.
- Import via `package:core_architecture_dio/core_architecture_dio.dart` instead of the removed
  `package:core_architecture/dio.dart`.
- `baseUrl` is taken from the initializer argument, falling back to `API_BASE_URL` in `.env`;
  `DioCoreExtension.initialize()` replaces the old `CoreConfig(useDio: true, dioBaseUrl: …)`.
