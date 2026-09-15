# Core Architecture — Monorepo

A production-ready, modular Flutter architecture built on **Riverpod 3**, split into a
backend-agnostic core plus optional backend packages.

**Version:** 3.1.0 · **Status:** Active development · **License:** MIT

> **Why the split?** In v1 everything shipped as one package, so every consumer pulled in
> `supabase_flutter`, `dio` and `purchases_flutter` whether they used them or not. In v2 you
> depend only on what you actually use.

---

## Why use it

Every new Flutter app starts with the same `lib/core/` folder: initialization, secure storage, a
logger, a `Failure` type, spacing constants, a light and dark theme, a responsive helper. It gets
copy-pasted from the last project and drifts from it immediately. This is that folder, versioned
and shared instead of duplicated.

**Your feature code never names a backend.** Repositories depend on `CrudContract` — `query`,
`getById`, `insert`, `update`, `delete`, `upsert` — and `core_architecture_supabase` /
`core_architecture_dio` implement it. Moving from Supabase to a REST API, or running both side by
side, changes which provider you inject, not the features:

```dart
class ProductRepository {
  ProductRepository(this._client);
  final CrudContract _client;   // not SupabaseClient, not Dio
}
```

**Errors are typed, not `catch (e)`.** Ten `Failure` types for the UI layer
(`NetworkFailure`, `AuthFailure`, `ValidationFailure`, `UnknownFailure`, …) and nine matching
`AppException` types for the data layer, so a failed call is something you can switch on instead
of a string you parse.

**The plumbing is already wired.** `CoreInitializer.quickStart()` sets up the Flutter binding,
loads `.env`, and brings up storage and logging in one call. `StorageService` is an abstract
interface with a `flutter_secure_storage` implementation behind it. Theme mode and
onboarding-seen state are Riverpod notifiers that persist themselves.

**One design system instead of scattered magic numbers.** Nine token files (colors, spacing,
sizes, typography, radius, borders, elevations, durations, opacities), `lightTheme` / `darkTheme`
built from them, Material 3 window size classes (`compact` / `medium` / `expanded` / `large`)
with `ResponsiveBuilder` and `ResponsiveValue`, plus `Gap`, `Validators`, `TurkishPhoneFormatter`,
`DateHelper` and `context.colorScheme` / `context.showError()` extensions.

**You pay only for what you import.** The core has no backend or vendor SDK. Add a backend
package only if you need one.

### What it is not

- **Not a state management library.** That is Riverpod 3, which this re-exports and builds on.
- **Not a router.** No routes, no navigation widgets, no router dependency — bring your own.
- **Not a starter template.** It is a dependency you upgrade, not a folder you fork and edit.
- **Opinionated.** Riverpod for DI and state, secure storage for persistence, `Failure` for error
  handling. If your app already disagrees with those, the useful part is the `CrudContract` idea,
  not the package.

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

Add the dependency, then run **`flutter pub get`** as usual. Melos is only for developing this
monorepo (see [Working on the monorepo](#working-on-the-monorepo)) — running `melos bootstrap`
in your own app fails with *"Your current directory does not appear to be within a Melos
workspace"*, which is expected.

### Core only — no backend

```yaml
dependencies:
  core_architecture:
    git:
      url: https://github.com/Himera19/core_architecture.git
      path: packages/core_architecture
      ref: v3.1.0
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
      ref: v3.1.0
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
      ref: v3.1.0
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

These packages are **routing-agnostic**: no routes, no navigation widgets, no router dependency.
Pick your own router and add it to your app's `pubspec.yaml`. With `go_router`, for example:

```dart
// lib/router.dart
import 'package:core_architecture/core_architecture.dart';
import 'package:go_router/go_router.dart';

final Provider<GoRouter> routerProvider = Provider<GoRouter>(
  (Ref ref) => GoRouter(
    initialLocation: '/',
    routes: <RouteBase>[
      GoRoute(path: '/', builder: (_, _) => const HomeScreen()),
    ],
  ),
);
```

```dart
class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'MyApp',
      routerConfig: ref.read(routerProvider),
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ref.watch(themeProvider),   // ThemeMode, persisted by the core
    );
  }
}
```

No router at all? A plain `MaterialApp` works the same way — only `routerConfig` is
router-specific:

```dart
MaterialApp(
  title: 'MyApp',
  home: const HomeScreen(),
  theme: lightTheme,
  darkTheme: darkTheme,
  themeMode: ref.watch(themeProvider),
)
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
5. Tag and push: `git tag vX.Y.Z && git push && git push --tags` — the tag must match the
   `version:` and `ref:` values from steps 3 and 4.

The `ref` in a package's git dependency must point at a tag that exists on GitHub — until the
tag is pushed, consumers outside the repo cannot resolve the backend packages.

---

## Documentation

* [`packages/core_architecture/README.md`](packages/core_architecture/README.md) — the full reference. Jump to:
  [design tokens](packages/core_architecture/README.md#design-tokens) ·
  [themes](packages/core_architecture/README.md#themes) ·
  [shared widgets](packages/core_architecture/README.md#shared-widgets) ·
  [utilities](packages/core_architecture/README.md#utilities) ·
  [responsive system](packages/core_architecture/README.md#responsive-system) ·
  [providers](packages/core_architecture/README.md#providers) ·
  [feature conventions](packages/core_architecture/README.md#feature-architecture-convention)
* [`packages/core_architecture_supabase/README.md`](packages/core_architecture_supabase/README.md) — Supabase setup, auth, CRUD
* [`packages/core_architecture_dio/README.md`](packages/core_architecture_dio/README.md) — REST setup, interceptors, CRUD

Each package keeps its own `CHANGELOG.md`; `melos version` appends to them.

---

## Design system

Every token, theme and widget lives in `core_architecture`, so it is available from whichever
package you imported — the backend packages re-export it.

```dart
import 'package:core_architecture/core_architecture.dart';
// …or, if you use a backend package, it is already in scope:
// import 'package:core_architecture_supabase/core_architecture_supabase.dart';
```

**Tokens** are `const` namespaces — no context, no setup, just `ClassName.member`:

```dart
Container(
  padding: EdgeInsets.all(AppSpacings.rMd),           // 16
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(AppRadius.lg), // 16
    boxShadow: AppElevations.shadowMd,
    border: Border.all(width: AppBorders.thin, color: context.colorScheme.outline),
  ),
  child: Text('Hello', style: AppTypography.titleMd),
);
```

| Token class | Holds | Example |
| --- | --- | --- |
| `AppColors` | brand, surface, text, border, status colors | `AppColors.primary` · `AppColors.success` |
| `AppTypography` | 15-step `TextStyle` scale + `fontFamily` | `AppTypography.bodyMd` |
| `AppSpacings` | `w*` / `h*` / `r*` ramps, 4 → 40 | `AppSpacings.rMd` |
| `AppSizes` | icons, buttons, avatars, cards, dialogs | `AppSizes.iconSm` |
| `AppRadius` | corner radii, 4 / 8 / 16 / 24 | `AppRadius.lg` |
| `AppBorders` | border **widths**, 1 / 2 / 3 | `AppBorders.normal` |
| `AppDurations` | animation durations | `AppDurations.normal` |
| `AppElevations` | elevation levels + `BoxShadow` presets | `AppElevations.shadowMd` |
| `AppOpacities` | **alpha ints (0–255)** for `withAlpha` | `AppOpacities.low` |

**Themes** are built from those tokens and driven by a persisted provider:

```dart
MaterialApp(
  theme: lightTheme,
  darkTheme: darkTheme,
  themeMode: ref.watch(themeProvider),   // saved to secure storage
);

await ref.read(themeProvider.notifier).toggleTheme();
```

Inside widgets, prefer the theme over raw color tokens — it already flips between modes:

```dart
context.colorScheme.primary
context.textTheme.titleLarge
context.showSuccess('Saved');
```

Re-brand through `AppTheme` rather than editing the package — the token classes are `final` and
cannot be subclassed:

```dart
MaterialApp(
  theme:     AppTheme.light(brandColor: myPurple, fontFamily: 'Inter'),
  darkTheme: AppTheme.dark(brandColor: myPurple,  fontFamily: 'Inter'),
  themeMode: ref.watch(themeProvider),
);
```

`brandColor` moves only the accent slots — the neutral Slate palette stays put — and derives its
tones from `ColorScheme.fromSeed`, so the `on*` pairs stay readable for any seed. For anything
else, `copyWith` on the result composes as usual.

Full reference — every value, every widget parameter, and the customization rules:
[`packages/core_architecture/README.md`](packages/core_architecture/README.md#design-tokens).

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
