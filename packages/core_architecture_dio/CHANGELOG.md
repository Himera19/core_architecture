# Changelog

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
