# Core Architecture

Modular Flutter architecture on **Riverpod 3**: a backend-agnostic core plus optional backend
packages. Design tokens, themes, responsive layout, storage, logging and a typed error hierarchy —
versioned as a dependency instead of copy-pasted into every new `lib/core/`.

**v3.2.0** · MIT · Flutter ≥ 3.16 · Dart ≥ 3.8

```dart
class ProductRepository {
  ProductRepository(this._client);
  final CrudContract _client;   // not SupabaseClient, not Dio

  Future<List<Product>> fetchAll() =>
      _client.query(table: 'products', fromJson: Product.fromJson);
}
```

Feature code names no backend. `CrudContract` is implemented by both backend packages, so
switching from Supabase to REST changes which provider you inject, not your features.

No router, no navigation widgets, no in-app purchases — bring your own.

---

## Packages

| Package | Contents | Depends on |
| --- | --- | --- |
| [`core_architecture`](packages/core_architecture) | Design tokens, themes, responsive layer, widgets, storage, logging, `Failure`/`AppException`, theme & onboarding providers, `CrudContract` | — |
| [`core_architecture_supabase`](packages/core_architecture_supabase) | `SupabaseService`, `SupabaseCrudClient`, auth providers | core + `supabase_flutter` |
| [`core_architecture_dio`](packages/core_architecture_dio) | `DioService`, `DioCrudClient`, providers | core + `dio` |

Take the core alone, or add one backend package — or both, if the app talks to Supabase *and* a
REST API. Each backend package re-exports the core, so one import is enough.

---

## Install

Git dependency, pinned to a tag. Then `flutter pub get` as usual — Melos is only for developing
this repo.

```yaml
dependencies:
  core_architecture_supabase:          # or core_architecture_dio / core_architecture
    git:
      url: https://github.com/Himera19/core_architecture.git
      path: packages/core_architecture_supabase
      ref: v3.2.0
```

| Package | `path:` | Import |
| --- | --- | --- |
| core only | `packages/core_architecture` | `package:core_architecture/core_architecture.dart` |
| Supabase | `packages/core_architecture_supabase` | `package:core_architecture_supabase/core_architecture_supabase.dart` |
| Dio | `packages/core_architecture_dio` | `package:core_architecture_dio/core_architecture_dio.dart` |

A backend package pulls in `core_architecture` itself — do not list it separately.

---

## Quick start

**1. `.env`** — declare it as an asset and keep it out of git.

```yaml
# your_app/pubspec.yaml
flutter:
  assets:
    - .env
```

```bash
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_PUBLISHABLE_KEY=your-publishable-key
# …or, for a REST API:
API_BASE_URL=https://api.example.com
```

**2. `main.dart`** — initialize the core, then each backend you use. Backend initializers are
standalone (they set up the binding and load `.env` themselves), so `CoreInitializer` is optional.

```dart
void main() async {
  await CoreInitializer.initialize(const CoreConfig(appName: 'MyApp'));
  await SupabaseCoreExtension.initialize();   // or DioCoreExtension.initialize()

  runApp(const ProviderScope(child: MyApp()));
}
```

No backend at all: `await CoreInitializer.quickStart();`

**3. `MaterialApp`** — the three theme arguments are all the wiring the design system needs.

```dart
MaterialApp(
  home: const HomeScreen(),
  theme: lightTheme,
  darkTheme: darkTheme,
  themeMode: ref.watch(themeProvider),   // persisted to secure storage
)
```

Re-brand without forking: `AppTheme.light(brandColor: myPurple, fontFamily: 'Inter')`.

---

## Docs

| | |
| --- | --- |
| [`core_architecture`](packages/core_architecture/README.md) | [tokens](packages/core_architecture/README.md#design-tokens) · [themes](packages/core_architecture/README.md#themes) · [responsive](packages/core_architecture/README.md#responsive) · [widgets](packages/core_architecture/README.md#widgets) · [utilities](packages/core_architecture/README.md#utilities) · [providers, storage, logging](packages/core_architecture/README.md#providers) · [errors](packages/core_architecture/README.md#errors) |
| [`core_architecture_supabase`](packages/core_architecture_supabase/README.md) | setup · auth · CRUD |
| [`core_architecture_dio`](packages/core_architecture_dio/README.md) | setup · interceptors · CRUD |

Version history is per package: `packages/*/CHANGELOG.md`.

---

## Developing this repo

Dart pub workspace + [Melos](https://melos.invertase.dev) 8.

```bash
dart pub global activate melos
melos bootstrap     # one shared lockfile for every package
```

| Command | Does |
| --- | --- |
| `melos run analyze` | `flutter analyze` everywhere |
| `melos run test` | `flutter test` where a `test/` exists |
| `melos run generate` | `build_runner build` where it is needed |
| `melos run format` / `format-check` | `dart format`, writing / checking |
| `melos run clean` | `flutter clean` everywhere |

Inside the workspace the backend packages resolve `core_architecture` to `packages/core_architecture`,
so local edits apply with no `dependency_overrides`. Melos config lives under the `melos:` key in the
root `pubspec.yaml`.

**`*.g.dart` files are committed on purpose.** pub never runs `build_runner` on a git dependency,
so an ignored generated file means a consumer gets a package whose providers do not exist. After
touching anything `@riverpod`, run `melos run generate` and commit the result with the source.

### Releasing

1. `melos run generate`, then `melos run analyze` and `melos run test`.
2. Bump `version:` in every `packages/*/pubspec.yaml`.
3. Update the `ref:` of the backend packages' `core_architecture` git dependency to the new tag.
4. `git tag vX.Y.Z && git push && git push --tags`.

The tag in step 4 must match steps 2 and 3 — until it is pushed, consumers outside the repo cannot
resolve the backend packages.

---

## Troubleshooting

| Symptom | Cause |
| --- | --- |
| `melos bootstrap` version conflict | One lockfile for all packages — align the constraint across `packages/*/pubspec.yaml`. |
| Consumer cannot resolve `core_architecture` | The backend package's git `ref:` points at an unpushed tag. |
| `_$…Provider` is undefined | Code generation has not run: `melos run generate`. |
| "SupabaseService must be initialized first" | `SupabaseCoreExtension.initialize()` was not awaited before `runApp`. |
| `melos bootstrap` fails in *your* app | Expected — Melos is for this repo. Use `flutter pub get`. |
