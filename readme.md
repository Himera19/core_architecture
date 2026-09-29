# Core Architecture

**Start a Flutter app with everything already set up:** a design system, theming, storage,
logging, error types, auth and data access, all on Riverpod 3. Answer a few questions and you get
an app that already builds, analyzes clean and passes its tests. Or add the packages to an app you
already have.

**v6.3.0** · MIT · Flutter ≥ 3.16 · Dart ≥ 3.8 ·
**[▶ Live demo](https://himera19.github.io/core_architecture/)**

```bash
dart pub global activate --source git https://github.com/Himera19/core_architecture.git --git-path cli
core_architecture create my_app
```

---

## What you get

| | |
| --- | --- |
| 🎨 **Design system** | Tokens for colour, type, spacing, radius, size, elevation and motion. Light and dark themes built from a single brand colour and font. |
| 📱 **Responsive layout** | Material 3 window size classes, `ResponsiveBuilder`, per-size values, and platform detection. |
| 🧩 **Widgets** | Themed button, text field and dropdown (searchable and multi-select) with loading states and validation. They ship no hard-coded English. |
| 🔐 **Auth** | Supabase auth, or token auth for any REST API. REST sessions refresh on 401 and end cleanly when the refresh fails. |
| 🗄️ **Data** | One `CrudContract` covering query, get, insert, update, delete, upsert, batch, count and RPC, implemented for both Supabase and REST. Features never name a backend. |
| 💾 **Storage** | Secure storage for secrets and shared preferences for settings. Theme mode and onboarding state are persisted for you. |
| 🧯 **Errors** | One `Failure` type for every backend: network, server, timeout, auth, unauthorized, database and more. |
| 🪵 **Logging** | Tagged levels, and HTTP request and response logs that mask passwords, tokens, keys and cookies. |
| 🛠️ **Utilities** | Validators, locale-aware date helpers, spacing and radius helpers, SnackBar shortcuts, and a URL launcher. |
| ⚡ **Scaffolder** | `core_architecture create` builds a new app from your answers: backend, auth screens, onboarding, router, languages, an example CRUD feature and the theme. |

No router or navigation widgets in the packages themselves. You choose one, or the scaffolder
wires up `go_router` for you.

---

## Start a new app

```text
$ core_architecture create shop

Project
Organization (bundle id prefix) (com.example) dev.shop
Platforms [android, ios]

Backend
Which backend does the app talk to? Supabase
Supabase URL (empty: fill in .env later) https://xyz.supabase.co
Supabase publishable key (empty: fill in .env later) sb_publishable_…

Features
Add sign-in, sign-up and password-reset screens? Yes
Postgres function that deletes an account (delete_user) delete_user
Add an onboarding flow shown on first launch? Yes
Use go_router for navigation? Yes
Localize the app (flutter gen-l10n)? Yes
Languages, comma-separated (en and tr come translated) en,tr
Example CRUD feature — singular entity name (empty: none) product
Table name (products) products

Theme
Brand colour as hex, e.g. 5D1B9A (empty: package palette) 5D1B9A
Google Fonts family, e.g. Inter (empty: platform font) Inter
Theme mode on first launch system

Create shop with these answers? (Y/n) Yes
✓ Creating the Flutter project (0.6s)
✓ Adding dependencies (2.7s)
✓ Writing 27 files (3ms)
✓ Resolving packages (1.1s)
✓ Generating localizations (0.4s)
✓ Generating providers (22.1s)
✓ Tidying code (1.9s)
✓ Formatting (0.1s)
✓ No analyzer issues (2.9s)
```

That session produces this app:

```text
shop/
├── lib/
│   ├── main.dart                  initializers, first-launch theme mode
│   ├── app/
│   │   ├── app.dart               MaterialApp.router, themes, localizations
│   │   ├── router.dart            splash → onboarding → sign-in → home redirects
│   │   ├── theme.dart             AppTheme.light/dark(brandColor, fontFamily)
│   │   ├── splash_screen.dart
│   │   └── show_error.dart        Failure → SnackBar
│   ├── features/
│   │   ├── auth/                  sign-in, sign-up, forgot password, AuthController
│   │   ├── onboarding/            three pages, remembered once seen
│   │   ├── home/                  light / system / dark switch, sign-out
│   │   └── products/              domain / data / presentation: list, add, swipe to delete
│   └── l10n/                      app_en.arb, app_tr.arb, context.l10n
├── supabase/schema.sql            products table with row-level security, delete_user()
├── test/app_flow_test.dart        walks the first-launch flow, no backend needed
├── .env / .env.example
└── core_architecture.yaml         your answers, to scaffold the same app again
```

With a REST backend, you get `lib/app/dio_config.dart` instead of the Supabase schema. It holds your
API's login, refresh and reset endpoints, and where the tokens sit in its responses. With no
router, an `AppGate` widget does what the redirects do. Everything you can choose is listed in the
[CLI docs](cli/README.md).

---

## Packages

| Package | What it is | Brings in |
| --- | --- | --- |
| [`core_architecture`](packages/core_architecture) | The foundation: design system, themes, responsive layout, widgets, storage, logging, errors, utilities, `CrudContract` | `flutter_riverpod` (re-exported) |
| [`core_architecture_supabase`](packages/core_architecture_supabase) | Supabase auth, CRUD and file storage, with Riverpod providers | the core + `supabase_flutter` |
| [`core_architecture_dio`](packages/core_architecture_dio) | A REST client with token auth, refresh-and-retry, error mapping and CRUD | the core + `dio` |
| [`cli`](cli) | `core_architecture create`, the app scaffolder | — |
| [`example`](example) | The [live demo](https://himera19.github.io/core_architecture/): every core feature, running | the core |

Use the core on its own, or add one backend package, or both if the app talks to Supabase *and* a
REST API. Each backend package re-exports the core, so one import is enough.

---

## Add to an existing app

**1. Dependency.** Add a git dependency pinned to a tag. Don't list `core_architecture` next to a
backend package, because the backend package brings it in.

```yaml
dependencies:
  core_architecture_supabase:          # or core_architecture_dio, or core_architecture
    git:
      url: https://github.com/Himera19/core_architecture.git
      path: packages/core_architecture_supabase
      ref: v6.3.0
```

**2. `.env`.** Declare it as an asset, and keep it out of git.

```yaml
flutter:
  assets:
    - .env
```

```bash
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_PUBLISHABLE_KEY=your-publishable-key
API_BASE_URL=https://api.example.com          # for core_architecture_dio
```

**3. `main.dart`.** Initialize the core, then each backend you use.

```dart
void main() async {
  await CoreInitializer.initialize(const CoreConfig(appName: 'MyApp'));
  await SupabaseCoreExtension.initialize();   // or DioCoreExtension.initialize()

  runApp(const ProviderScope(child: MyApp()));
}
```

**4. `MaterialApp`.** Three arguments are all the design system needs.

```dart
MaterialApp(
  theme: AppTheme.light(brandColor: const Color(0xFF5D1B9A)),
  darkTheme: AppTheme.dark(brandColor: const Color(0xFF5D1B9A)),
  themeMode: ref.watch(themeProvider),   // persisted and restored on launch
  home: const HomeScreen(),
)
```

Then write features against `CrudContract`, and the backend becomes a detail you inject:

```dart
class ProductRepository {
  ProductRepository(this._client);
  final CrudContract _client;   // not SupabaseClient, not Dio

  Future<List<Product>> fetchAll() =>
      _client.query(table: 'products', fromJson: Product.fromJson);
}

final repo = ProductRepository(ref.watch(supabaseCrudClientProvider));   // or dioCrudClientProvider
```

---

## Docs

| | |
| --- | --- |
| [`core_architecture`](packages/core_architecture/README.md) | [tokens](packages/core_architecture/README.md#design-tokens) · [themes](packages/core_architecture/README.md#themes) · [responsive](packages/core_architecture/README.md#responsive) · [widgets](packages/core_architecture/README.md#widgets) · [utilities](packages/core_architecture/README.md#utilities) · [state and storage](packages/core_architecture/README.md#state-and-storage) · [errors](packages/core_architecture/README.md#errors) · [features](packages/core_architecture/README.md#building-features) |
| [`core_architecture_supabase`](packages/core_architecture_supabase/README.md) | [setup](packages/core_architecture_supabase/README.md#setup) · [auth](packages/core_architecture_supabase/README.md#auth) · [CRUD](packages/core_architecture_supabase/README.md#crud) · [file storage](packages/core_architecture_supabase/README.md#file-storage) |
| [`core_architecture_dio`](packages/core_architecture_dio/README.md) | [setup](packages/core_architecture_dio/README.md#setup) · [config](packages/core_architecture_dio/README.md#configuration) · [auth](packages/core_architecture_dio/README.md#auth) · [CRUD](packages/core_architecture_dio/README.md#crud) |
| [`cli`](cli/README.md) | [questions](cli/README.md#what-it-asks) · [config files](cli/README.md#without-questions) |

Each package has its own version history in `packages/*/CHANGELOG.md` and `cli/CHANGELOG.md`.

---

## Developing this repo

A Dart pub workspace with [Melos](https://melos.invertase.dev) 8. The CLI in `cli/` sits outside
the workspace and has its own lockfile.

```bash
dart pub global activate melos
melos bootstrap
```

| Command | Does |
| --- | --- |
| `melos run analyze` / `test` | `flutter analyze` / `flutter test` in every package |
| `melos run generate` | `build_runner` wherever `@riverpod` is used |
| `melos run format` / `format-check` | `dart format`, writing or checking |
| `melos run check-refs` | Checks that every pinned tag is on origin and carries this core |
| `cd cli && dart test` | Checks that every combination of scaffolder answers renders |
| `bash cli/tool/e2e.sh` | Scaffolds four real apps. Each must analyze clean and pass its tests |

Inside the workspace, the backend packages use the local `packages/core_architecture`, so your
edits apply straight away.

**`*.g.dart` files are committed on purpose.** pub never runs `build_runner` on a git dependency,
so without them a consumer would get providers that don't exist. After touching anything
`@riverpod`, run `melos run generate` and commit the output.

### Releasing

1. Run `melos run generate`, `melos run analyze` and `melos run test`.
2. Bump `version:` in every `packages/*/pubspec.yaml` and in `cli/pubspec.yaml`.
3. Point the backend packages' `core_architecture` `ref:`, and `packageRef` in
   `cli/lib/src/version.dart`, at the new tag.
4. Run `git tag vX.Y.Z && git push && git push --tags`.
5. Run `melos run check-refs` to confirm the refs from step 3 resolve.
6. Run `bash cli/tool/e2e.sh` to confirm apps scaffold on the new tag.

Until the tag from step 4 is pushed, nobody outside the repo can resolve the backend packages.

---

## Troubleshooting

| Symptom | Cause |
| --- | --- |
| An app can't resolve `core_architecture` | A backend package's `ref:` points at a tag that isn't pushed. |
| An app gets an older `core_architecture` than expected | The tag was removed from origin but is still in the local pub cache. Fix the ref, then run `flutter pub cache clean`. |
| `_$…Provider` is undefined | Code generation hasn't run. Run `dart run build_runner build -d`. |
| "SupabaseService must be initialized first" | `SupabaseCoreExtension.initialize()` wasn't awaited before `runApp`. |
| `melos bootstrap` version conflict | All packages share one lockfile. Align the constraint across `packages/*/pubspec.yaml`. |
| `melos bootstrap` fails in *your* app | Expected: Melos is only for this repo. Use `flutter pub get`. |
| `core_architecture: command not found` | Add `~/.pub-cache/bin` to your `PATH`. |
