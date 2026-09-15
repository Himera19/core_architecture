# Changelog

## 3.0.0

Version bump to track `core_architecture` 3.0.0. This package's own API is unchanged, but the
core it re-exports no longer ships `CustomAppBar`, `Navbar` or `go_router`.

## 2.0.0

Initial release. The Supabase backend was extracted from `core_architecture` v1.x so that
projects without Supabase no longer pull in `supabase_flutter` and its native bindings.

### Added

- `SupabaseCoreExtension.initialize({String deleteUserRpcName, String envFile})` — a
  standalone entry point that sets up the Flutter binding and loads `.env` itself, so
  `CoreInitializer` is optional. Both steps are idempotent, so it also composes with it.
- `lib/core_architecture_supabase.dart` barrel, re-exporting `core_architecture` and all of
  `supabase_flutter`.

### Changed

- `SupabaseService`, `SupabaseCrudClient` and the Supabase providers moved here from
  `core_architecture/lib/src/backends/supabase/`.
- Import via `package:core_architecture_supabase/core_architecture_supabase.dart` instead of
  the removed `package:core_architecture/supabase.dart`.
- `Supabase.initialize` no longer uses the deprecated `anonKey` parameter. The key is read
  from `SUPABASE_PUBLISHABLE_KEY`, falling back to the legacy `SUPABASE_ANON_KEY`, and passed
  as `publishableKey`. Existing `.env` files keep working unchanged.

### Fixed

- **Supabase auth and storage errors were never caught.** `SupabaseService` hid the SDK's
  `AuthException` and `StorageException` behind `core_architecture`'s same-named types, so
  nine `on AuthException` / `on StorageException` clauses compiled but never matched what the
  SDK throws — every such error fell through to the generic handler and was reported as an
  unexpected error.

  Fixed at the source: `core_architecture` renamed its colliding types, and this package's
  barrel no longer hides anything. `on AuthException` now means the Supabase SDK's type
  everywhere. Guarded by `test/exception_naming_test.dart`.
