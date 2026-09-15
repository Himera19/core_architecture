# Core Architecture — Monorepo

A production-ready, modular Flutter architecture built on **Riverpod 3**, split into a
backend-agnostic core plus optional backend packages.

**Version:** 2.0.0 · **Status:** Active development · **License:** MIT

> **Why the split?** In v1 everything shipped as one package, so every consumer pulled in
> `supabase_flutter`, `dio` and `purchases_flutter` whether they used them or not. In v2 you
> depend only on what you actually use.

---

## Packages

| Package | Adds | Depends on |
| --- | --- | --- |
| [`core_architecture`](packages/core_architecture) | Design tokens, themes, responsive layer, shared widgets, storage, logging, `Failure`/`Exception` hierarchy, theme & onboarding providers, and the backend-agnostic `CrudContract` interface. **No backend dependency.** | — |
| [`core_architecture_supabase`](packages/core_architecture_supabase) | `SupabaseService`, `SupabaseCrudClient` (a `CrudContract` implementation), auth providers, `SupabaseCoreExtension`. | `core_architecture`, `supabase_flutter` |
| [`core_architecture_dio`](packages/core_architecture_dio) | `DioService`, `DioCrudClient` (a `CrudContract` implementation), providers, `DioCoreExtension`. | `core_architecture`, `dio` |

Pick `core_architecture` alone, or add exactly one backend package — or both, if your app talks
to Supabase *and* a REST API.

```
.
├── pubspec.yaml                        # pub workspace root + Melos config
├── analysis_options.yaml               # shared lint rules
└── packages/
    ├── core_architecture/              # backend-agnostic core
    ├── core_architecture_supabase/     # core + supabase_flutter
    └── core_architecture_dio/          # core + dio
```

---

## Installation

All packages are consumed as **git dependencies**. Pin a tag with `ref` so your builds are
reproducible.

### Core only — no backend

```yaml
dependencies:
  core_architecture:
    git:
      url: https://github.com/Himera19/core_architecture.git
      path: packages/core_architecture
      ref: v2.0.0
```

```dart
import 'package:core_architecture/core_architecture.dart';
```

### With Supabase

You do **not** need to list `core_architecture` separately — the backend package brings it in
and re-exports it.

```yaml
dependencies:
  core_architecture_supabase:
    git:
      url: https://github.com/Himera19/core_architecture.git
      path: packages/core_architecture_supabase
      ref: v2.0.0
```

```dart
import 'package:core_architecture_supabase/core_architecture_supabase.dart';
```

### With Dio (REST API)

```yaml
dependencies:
  core_architecture_dio:
    git:
      url: https://github.com/Himera19/core_architecture.git
      path: packages/core_architecture_dio
      ref: v2.0.0
```

```dart
import 'package:core_architecture_dio/core_architecture_dio.dart';
```

### Using both backends

List both packages. Import each barrel where you need it, or import
`package:core_architecture/core_architecture.dart` for the shared pieces and the backend barrels
only in the files that touch that backend.

---

## Quick Start

### 1. Environment file

```yaml
# your_app/pubspec.yaml
flutter:
  assets:
    - .env
```

```bash
# .env — add to .gitignore!
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_PUBLISHABLE_KEY=your-publishable-key   # SUPABASE_ANON_KEY still works

# …or, for a REST API:
API_BASE_URL=https://api.example.com
```

### 2. Initialize in `main.dart`

`CoreInitializer` no longer knows about backends. Initialize the core, then each backend you use.

```dart
import 'package:core_architecture_supabase/core_architecture_supabase.dart';

void main() async {
  await CoreInitializer.initialize(
    const CoreConfig(appName: 'MyApp', envFile: '.env'),
  );

  await SupabaseCoreExtension.initialize(
    deleteUserRpcName: 'delete_user', // optional, this is the default
  );

  runApp(const ProviderScope(child: MyApp()));
}
```

**No backend at all?** `quickStart` needs no config object:

```dart
import 'package:core_architecture/core_architecture.dart';

void main() async {
  await CoreInitializer.quickStart(); // binding + .env + storage + logger
  runApp(const ProviderScope(child: MyApp()));
}
```

**Backend only?** Each backend initializer is standalone — it sets up the Flutter binding and
loads `.env` itself, so `CoreInitializer` is optional:

```dart
void main() async {
  await SupabaseCoreExtension.initialize();
  runApp(const ProviderScope(child: MyApp()));
}
```

### 3. Wire up the app

```dart
class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      routerConfig: ref.read(routeConfigProvider),
      title: 'MyApp',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ref.watch(themeProvider),
    );
  }
}
```

---

## Swapping backends

Feature code should depend on `CrudContract`, never on a concrete client. Both backend packages
implement it, so switching backends is a provider change, not a rewrite.

```dart
class ProductRepository {
  ProductRepository(this._client);
  final CrudContract _client;

  Future<List<Product>> fetchAll() =>
      _client.query(table: 'products', fromJson: Product.fromJson);
}

// Supabase:
ProductRepository(ref.watch(supabaseCrudClientProvider));
// Dio:
ProductRepository(ref.watch(dioCrudClientProvider));
```

`CrudContract` operations: `query`, `getById`, `insert`, `update`, `delete`, `upsert`,
`batchInsert`, `batchUpdate`, `batchDelete`, `batchUpsert`, `exists`, `count`, `rpc`.

---

## Migrating from v1.x

| v1 | v2 |
| --- | --- |
| `import 'package:core_architecture/supabase.dart';` | `import 'package:core_architecture_supabase/core_architecture_supabase.dart';` |
| `import 'package:core_architecture/dio.dart';` | `import 'package:core_architecture_dio/core_architecture_dio.dart';` |
| `import 'package:core_architecture/core_architecture.dart';` | unchanged |
| `CoreConfig(useSupabase: true, deleteUserRpcName: 'x')` | `CoreConfig(appName: …)` + `SupabaseCoreExtension.initialize(deleteUserRpcName: 'x')` |
| `CoreConfig(useDio: true, dioBaseUrl: 'https://…')` | `CoreConfig(appName: …)` + `DioCoreExtension.initialize(baseUrl: 'https://…')` |
| `PurchaseFailure`, `PurchaseException` | **Removed.** In-app purchase support is out of scope in v2; extend `Failure` in your own app. |
| `AuthException` (core's) | `AuthenticationException` |
| `StorageException` (core's) | `LocalStorageException` |
| `TimeoutException` (core's) | `RequestTimeoutException` |
| `SUPABASE_ANON_KEY` | `SUPABASE_PUBLISHABLE_KEY` (the old name still works) |

`CoreConfig` now takes only `appName` and `envFile`. The `useSupabase`, `useDio`, `dioBaseUrl`
and `deleteUserRpcName` fields moved to the backend initializers.

### Why three exceptions were renamed

v1 exported `AuthException`, `StorageException` and `TimeoutException` — names that are already
taken by the Supabase SDK and by `dart:async`. Importing the barrel silently shadowed them, so
this compiled and never matched anything the SDK throws:

```dart
try {
  await supabase.client.auth.signInWithPassword(email: e, password: p);
} on AuthException catch (e) {   // ← v1: core's type, never thrown here
  …
}
```

The same trap applied to `Future.timeout()`, which throws `dart:async`'s `TimeoutException`.
Core's types are now named so nothing collides, and the SDK / `dart:async` names mean exactly
what you expect:

```dart
import 'package:core_architecture_supabase/core_architecture_supabase.dart';

try {
  await supabase.client.auth.signInWithPassword(email: e, password: p);
} on AuthException catch (e) {          // the Supabase SDK's type ✓
  …
} on TimeoutException catch (e) {       // dart:async's type ✓
  …
}

throw const AuthenticationException(message: 'Session expired');  // core's type
```

If you caught the old names in your app, rename them — the compiler will point at every site.

In-app purchase support (`PurchaseFailure`, `PurchaseException` and the `purchases_flutter`
dependency) was dropped entirely — it pulled heavy native bindings into every consumer for a
concern that belongs in the app. Declare whatever you need on top of `Failure` there.

---

## Working on the monorepo

Requires [Melos](https://melos.invertase.dev) 8+ (the workspace uses Dart pub workspaces).

```bash
dart pub global activate melos
melos bootstrap          # resolves all packages against one shared lockfile
```

| Command | What it does |
| --- | --- |
| `melos run analyze` | `flutter analyze` in every package |
| `melos run generate` | `build_runner build` in every package that needs it |
| `melos run format` | `dart format` across all packages |
| `melos run format-check` | Fails if anything is unformatted |
| `melos run test` | `flutter test` in packages that have a `test/` directory |
| `melos run clean` | `flutter clean` everywhere |

Inside the workspace, the backend packages' git dependency on `core_architecture` resolves to
`packages/core_architecture` automatically — local edits are picked up with no
`dependency_overrides`. The git description only applies to consumers outside the repo.

Melos configuration lives under the `melos:` key in the root `pubspec.yaml` (the standalone
`melos.yaml` file was removed in Melos 7).

### Generated code is committed

`*.g.dart` files are **tracked in git on purpose**. These packages are consumed as git
dependencies, and pub never runs `build_runner` on a dependency — a consumer gets exactly the
files that are committed. Ignoring generated code would ship packages whose providers
(`themeProvider`, `supabaseCrudClientProvider`, …) simply do not exist, and the failure only
shows up in the consumer's build.

After changing anything annotated with `@riverpod`, run `melos run generate` and commit the
result alongside the source change.

---

## Releasing

Every package is versioned together. To cut a release:

1. `melos run generate` — make sure committed `*.g.dart` files match the sources.
2. `melos run analyze` and `melos run test`.
3. Bump `version:` in each `packages/*/pubspec.yaml`.
4. Update the `ref:` in the backend packages' `core_architecture` git dependency to match.
5. Tag and push: `git tag v2.0.0 && git push && git push --tags`.

The `ref` in a package's git dependency must point at a tag that exists on GitHub — until the
tag is pushed, consumers outside the repo cannot resolve the backend packages.

---

## Documentation

* [`packages/core_architecture/README.md`](packages/core_architecture/README.md) — design tokens, themes, responsive system, widgets, utilities, providers, feature conventions
* [`packages/core_architecture_supabase/README.md`](packages/core_architecture_supabase/README.md) — Supabase setup, auth, CRUD
* [`packages/core_architecture_dio/README.md`](packages/core_architecture_dio/README.md) — REST setup, interceptors, CRUD

---

## Error handling

Always throw `Failure` subclasses from repositories — never raw exceptions.

```dart
throw const ServerFailure(message: 'Failed to fetch orders');
throw const NetworkFailure(message: 'No connection');
throw const AuthFailure(message: 'Session expired');
```

| Failure | Use case |
| --- | --- |
| `NetworkFailure` | Connectivity issues |
| `ServerFailure` | 5xx responses |
| `TimeoutFailure` | Request timeouts |
| `AuthFailure` | Authentication errors |
| `UnauthorizedFailure` | 401 responses |
| `DatabaseFailure` | DB operation errors |
| `ValidationFailure` | Input validation |
| `StorageFailure` | Local storage errors |
| `CacheFailure` | Cache misses/errors |
| `UnknownFailure` | Catch-all |

Extend with your own:

```dart
final class PaymentFailure extends Failure {
  const PaymentFailure({required super.message, super.code, super.data});
}
```

### Failures vs. exceptions

`Failure` is what repositories throw at feature code — a stable, backend-independent vocabulary.
`AppException` is the lower-level counterpart used inside services.

Core's exception names deliberately avoid the ones the Supabase SDK and `dart:async` already
use, so an unprefixed `on AuthException` / `on TimeoutException` in your app always means the
SDK's or `dart:async`'s type, never core's.

| Core exception | Notes |
| --- | --- |
| `NetworkException` | |
| `ServerException` | |
| `RequestTimeoutException` | Not `dart:async`'s `TimeoutException` |
| `AuthenticationException` | Not the Supabase SDK's `AuthException` |
| `UnauthorizedException` | |
| `DatabaseException` | |
| `ValidationException` | |
| `LocalStorageException` | Local key-value storage, not the SDK's `StorageException` |
| `CacheException` | |

---

## Logging

```dart
final logger = ref.read(loggerServiceProvider);

logger.d('Debug message', tag: 'MyFeature');
logger.i('User logged in', tag: 'Auth');
logger.w('Cache miss', tag: 'Cache');
logger.e('API failed', error: e, stackTrace: st, tag: 'API');
logger.fatal('Unrecoverable error', error: e, tag: 'Core');

logger.maskSensitive('sk_live_abc123xyz', visibleStart: 7, visibleEnd: 3);
// → "sk_live*******xyz"
```

---

## Storage

All storage keys live in `StorageConstants` — never use magic strings.

```dart
final storage = ref.read(storageServiceProvider);

await storage.write(key: StorageConstants.accessToken, value: 'abc123');
final token = await storage.read(key: StorageConstants.accessToken);
await storage.delete(key: StorageConstants.accessToken);
await storage.clearAll();
```

---

## Troubleshooting

**`melos bootstrap` fails with a version conflict.** All packages share one lockfile, so their
constraints must be mutually satisfiable. Align the conflicting constraint across
`packages/*/pubspec.yaml`, then bootstrap again.

**Consumer's `pub get` cannot resolve `core_architecture`.** The backend package's git `ref:`
points at a tag that has not been pushed yet. Push the tag, or temporarily point `ref:` at a
branch.

**`_$…Provider` is undefined.** Code generation has not run. `melos run generate`, or inside a
single package: `dart run build_runner build`.

**"SupabaseService must be initialized first".** `SupabaseCoreExtension.initialize()` (or
`SupabaseService.initialize()`) was never awaited in `main()`, or `runApp` ran before it
completed.

---

## Changelog

### v2.0.0 — Monorepo split (breaking)

* Split into `core_architecture`, `core_architecture_supabase` and `core_architecture_dio`;
  the repo is now a Melos-managed pub workspace.
* `supabase_flutter`, `dio` and `purchases_flutter` are no longer dependencies of the core
  package.
* Removed the `lib/supabase.dart` and `lib/dio.dart` barrels — each backend package now has its
  own top-level barrel.
* `CoreConfig` reduced to `appName` + `envFile`; backend setup moved to
  `SupabaseCoreExtension.initialize()` / `DioCoreExtension.initialize()`, both of which are
  standalone and no longer require `CoreInitializer`.
* Added `CoreInitializer.quickStart()` for zero-config startup.
* `StorageConstants` is now exported from the core barrel.
* Generated `*.g.dart` files are committed, so git-dependency consumers get working providers.
* Removed in-app purchase support — `PurchaseFailure`, `PurchaseException` and the
  `purchases_flutter` dependency are gone.

**Bug fixes**

* **Supabase auth and storage errors were never caught.** `SupabaseService` hid the SDK's
  `AuthException` / `StorageException` behind core's same-named types, so every
  `on AuthException` / `on StorageException` clause in the service silently failed to match and
  errors fell through to the generic handler. Core's types are renamed
  (`AuthenticationException`, `LocalStorageException`) and the SDK's names are no longer hidden.
  Covered by `packages/core_architecture_supabase/test/exception_naming_test.dart`.
* **Core's `TimeoutException` shadowed `dart:async`'s.** Importing the barrel silently rebound
  the name, so `on TimeoutException` would not catch a `Future.timeout()`. Renamed to
  `RequestTimeoutException`.
* **`Supabase.initialize` no longer uses the deprecated `anonKey` parameter.** The key is read
  from `SUPABASE_PUBLISHABLE_KEY`, falling back to `SUPABASE_ANON_KEY`, and passed as
  `publishableKey`. Existing `.env` files keep working unchanged.

### v1.3.1 and earlier

See the git history of the pre-split package.
