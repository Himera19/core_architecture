# core_architecture

The backend-agnostic foundation shared by all projects: design tokens, themes, a responsive
layer, shared widgets, storage, logging, the `Failure`/`Exception` hierarchy, and common
utilities.

This package pulls in **no backend dependency**. For data access, add
[`core_architecture_supabase`](../core_architecture_supabase) or
[`core_architecture_dio`](../core_architecture_dio) — each re-exports this package, so one import
is enough.

---

## Installation

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

## Setup

Call `CoreInitializer.initialize` before `runApp`:

```dart
void main() async {
  await CoreInitializer.initialize(
    const CoreConfig(
      appName: 'MyApp',
      envFile: '.env',   // optional, this is the default
    ),
  );
  runApp(const ProviderScope(child: MyApp()));
}
```

Or skip the config object entirely — `quickStart` sets up the Flutter binding, `.env`, storage
and logging and nothing else:

```dart
void main() async {
  await CoreInitializer.quickStart();
  runApp(const ProviderScope(child: MyApp()));
}
```

`CoreConfig` takes only `appName` and `envFile`. Backend setup lives in the backend packages'
own initializers (`SupabaseCoreExtension.initialize()`, `DioCoreExtension.initialize()`), which
can be called on their own or after `CoreInitializer`.

Configure your `MaterialApp` theme:

```dart
MaterialApp.router(
  theme: lightTheme,
  darkTheme: darkTheme,
  themeMode: ref.watch(themeProvider),
)
```

---

## Package Structure

```
lib/src/
├── backends/
│   └── contracts/         # CrudContract interface (implementations live in
│                          # core_architecture_supabase / core_architecture_dio)
├── core/
│   ├── config/            # CoreInitializer, CoreConfig
│   ├── constants/         # StorageConstants
│   ├── entities/          # BaseEntity
│   ├── errors/            # Failures, Exceptions
│   └── logging/           # LoggerService
├── providers/             # ThemeNotifier, OnboardingState
├── services/              # StorageService, SecureStorageService
├── ui/
│   ├── responsive/        # Breakpoints, ResponsiveBuilder, ResponsiveValue, PlatformInfo
│   ├── themes/            # lightTheme, darkTheme, AppColorScheme
│   ├── tokens/            # Colors, Typography, Spacings, Sizes, Radius, Borders, …
│   └── widgets/           # CustomAppBar, CustomButton, CustomTextField, …
└── utils/
    ├── extensions/        # ContextExtensions
    └── …                  # Gap, Validators, InputFormatters, DateHelper, …
```

---

## Backend Selection

This package ships the `CrudContract` interface but no implementation. Add the backend package
you need — each one depends on and re-exports `core_architecture`:

| Need | Add | Import |
| --- | --- | --- |
| Supabase | [`core_architecture_supabase`](../core_architecture_supabase) | `package:core_architecture_supabase/core_architecture_supabase.dart` |
| REST API | [`core_architecture_dio`](../core_architecture_dio) | `package:core_architecture_dio/core_architecture_dio.dart` |
| Neither | — | `package:core_architecture/core_architecture.dart` |

### CrudContract

Both backends implement `CrudContract`. Use it as the type in your repositories so you can swap backends without touching feature code:

```dart
class ProductRepository {
  ProductRepository(this._client);
  final CrudContract _client;

  Future<List<Product>> fetchAll() =>
      _client.query(table: 'products', fromJson: Product.fromJson);
}
```

Available operations: `query`, `getById`, `insert`, `update`, `delete`, `upsert`, `batchInsert`, `batchUpdate`, `batchDelete`, `batchUpsert`, `exists`, `count`, `rpc`.

---

## Errors

`Failure` is what repositories throw at feature code; `AppException` is the lower-level type
used inside services.

Core's exception names deliberately avoid names that the Supabase SDK and `dart:async` already
use, so importing this barrel never shadows them:

| Core exception | Deliberately *not* named |
| --- | --- |
| `RequestTimeoutException` | `TimeoutException` (`dart:async`, thrown by `Future.timeout()`) |
| `AuthenticationException` | `AuthException` (Supabase SDK) |
| `LocalStorageException` | `StorageException` (Supabase SDK) |

The rest — `NetworkException`, `ServerException`, `UnauthorizedException`, `DatabaseException`,
`ValidationException`, `CacheException` — collide with nothing.

Failures: `NetworkFailure`, `ServerFailure`, `TimeoutFailure`, `AuthFailure`,
`UnauthorizedFailure`, `DatabaseFailure`, `ValidationFailure`, `StorageFailure`, `CacheFailure`,
`UnknownFailure`. Extend `Failure` for project-specific ones.

---

## Responsive System

Material 3 Window Size Classes. All files live in `src/ui/responsive/`.

| Class | Width | Typical device |
|---|---|---|
| `compact` | < 600dp | Phone portrait |
| `medium` | 600–840dp | Tablet portrait, foldable |
| `expanded` | 840–1200dp | Tablet landscape, small desktop |
| `large` | ≥ 1200dp | Desktop, wide screen |

### AppBreakpoints

```dart
final sizeClass = AppBreakpoints.of(context);  // WindowSizeClass
final columns   = AppBreakpoints.columns(sizeClass); // 4 / 8 / 12 / 12
final margin    = AppBreakpoints.margin(sizeClass);  // 16 / 24 / 24 / 24
```

### ResponsiveBuilder

Rebuilds its subtree when the window size class changes. Only `compact` is required — others fall back to the nearest smaller builder.

```dart
ResponsiveBuilder(
  compact:  (context) => MobileLayout(),
  medium:   (context) => TabletLayout(),
  expanded: (context) => DesktopLayout(),
)
```

### ResponsiveValue

Use for any scalar that changes per breakpoint (padding, font size, column count, …):

```dart
const padding = ResponsiveValue<double>(compact: 16, medium: 24, expanded: 32, large: 40);

Container(padding: EdgeInsets.all(padding.resolve(context)));
```

Pre-built values in `ResponsiveSpacings`: `pagePadding`, `sectionSpacing`, `gridColumns`.

### Context extensions

```dart
context.isCompact          // bool
context.isDesktopNavigation
context.responsive<int>(compact: 1, medium: 2, expanded: 3, large: 4)
```

### PlatformInfo

Runtime platform detection (does not depend on screen size):

```dart
PlatformInfo.isWeb
PlatformInfo.isMobile   // Android | iOS
PlatformInfo.isDesktop  // Windows | macOS | Linux
PlatformInfo.platformName
```

---

## Design Tokens

All tokens are pure `const` values — no context needed.

| Class | What it provides |
|---|---|
| `AppColors` | Brand palette + semantic colors |
| `AppTypography` | `TextStyle` scale (display / headline / title / body / label) |
| `AppSpacings` | `w*`, `h*`, `r*` spacing values (xxs → xxl) |
| `AppSizes` | Fixed dimension constants |
| `AppRadius` | Border radius values |
| `AppBorders` | `BorderRadius` presets |
| `AppDurations` | Animation durations |
| `AppElevations` | Elevation levels |
| `AppOpacities` | Opacity constants |

### Font

Set your font family in `AppTypography.fontFamily` and register it in `pubspec.yaml` under `flutter.fonts`.

---

## Themes

```dart
lightTheme   // ThemeData
darkTheme    // ThemeData
AppColorScheme     // shared ColorScheme helpers
```

Switch themes via `ThemeNotifier`:

```dart
await ref.read(themeProvider.notifier).toggleTheme();
await ref.read(themeProvider.notifier).setThemeMode(ThemeMode.dark);
```

Both persist the choice through `StorageService`.

---

## Shared Widgets

| Widget | Description |
|---|---|
| `CustomAppBar` | Themed app bar |
| `CustomButton` | Primary / secondary button variants |
| `CustomTextField` | Styled text input |
| `CustomDropdown` | Styled dropdown |
| `Navbar` | Bottom navigation bar |

---

## Utilities

### Gap

Pre-built `SizedBox` constants for spacing. Prefix `h` = height, `w` = width:

```dart
Gap.hMd   // SizedBox(height: 16)
Gap.wSm   // SizedBox(width: 12)
```

### Validators

`String? Function(String?)` validators ready for `TextFormField.validator`:

```dart
Validators.email(value, errorMessage: 'Invalid email')
Validators.password(value, minLength: 8, errorMessage: '...')
Validators.required(value, errorMessage: '...')
Validators.compose([Validators.required(...), Validators.email(...)])
```

Also available: `confirmPassword`, `number`, `positiveNumber`, `amount`, `phone`, `url`, `date`, `futureDate`, `pastDate`, `minLength`, `maxLength`, `lengthRange`, `custom`.

### ContextExtensions

```dart
context.theme
context.textTheme
context.colorScheme
context.showSuccess('Saved')
context.showError('Something went wrong')
context.showInfo('Loading…')
```

### Other Utils

| Utility | Description |
|---|---|
| `DateHelper` | Date formatting helpers |
| `InputFormatters` | Common `TextInputFormatter` presets |
| `BorderUtils` | Border helper functions |
| `RadiusUtils` | Radius helper functions |
| `SpacingUtils` | Padding/margin helpers |
| `SpinKitIndicator` | Themed loading indicator |
| `UrlLauncher` | Wrapper around `url_launcher` |

---

## Providers

| Provider | Type | Description |
|---|---|---|
| `themeProvider` | `ThemeMode` | Selected theme, persisted to storage |
| `onboardingStateProvider` | `AsyncValue<bool>` | Whether onboarding was completed; `.notifier` exposes `markAsSeen()` and `reset()` |
| `loggerServiceProvider` | `LoggerService` | |
| `storageServiceProvider` | `StorageService` | Backed by `SecureStorageService` |

```dart
final seen = ref.watch(onboardingStateProvider);          // AsyncValue<bool>
await ref.read(onboardingStateProvider.notifier).markAsSeen();
```

---

## Feature Architecture Convention

These rules apply to every feature built on top of this package.

### Pages stay clean

Keep pages under ~200 lines. A page's only job is to **read state and dispatch events** — no business logic, no async calls, no direct repository access.

- `ref.watch(...)` → read state, rebuild UI
- `ref.read(...).someMethod()` → dispatch an event on user interaction
- Everything else belongs in a controller

### Controllers (Notifiers)

All logic lives in a `Notifier` class that acts as the controller for a page or feature flow. Name it after the page: `ProductListController`, `LoginController`, etc.

```dart
// presentation/providers/product_list_controller.dart
@riverpod
class ProductListController extends _$ProductListController {
  @override
  AsyncValue<List<Product>> build() => const AsyncValue.loading();

  Future<void> load() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(productRepositoryProvider).fetchAll(),
    );
  }

  Future<void> delete(String id) async {
    await ref.read(productRepositoryProvider).delete(id);
    await load();
  }
}
```

```dart
// presentation/pages/product_list_page.dart
class ProductListPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(productListControllerProvider);

    return switch (state) {
      AsyncData(:final value) => ProductList(products: value),
      AsyncError(:final error) => ErrorView(error: error),
      _ => const LoadingView(),
    };
  }
}
```

**Rule:** if logic is needed on first load, call it from `build()` via `ref.listen` or in the `Notifier.build()` itself — never inside the widget's `build` method.

### When to extract UI

| Case | Where to put it |
|---|---|
| Small UI snippet used once or twice | Private method on the widget class |
| Large reusable widget within one feature | `feature/presentation/widgets/my_widget.dart` |
| Widget shared across multiple features | `core/widgets/` or this package's `src/ui/widgets/` |

### Feature folder layout

```
features/
└── product/
    ├── models/          # data classes, JSON serialization
    ├── services/        # repository / data-access layer
    ├── providers/       # controllers (Notifiers) + simple providers
    ├── pages/           # ≤ ~200 lines, no logic
    ├── widgets/         # widgets used only in this feature
    └── helpers/         # (optional) pure functions, formatters, mappers
```

A widget belongs in `feature/widgets/` when:
- It is large enough to warrant its own `StatelessWidget` / `ConsumerWidget` class, **and**
- It is reused within the feature, or mixes concerns that don't belong inline.

A widget stays as a private method when:
- It is small, stateless, appears only once, and has no dependencies beyond its arguments.

---

## What this package deliberately leaves out

In v1 everything shipped in one package and you deleted what you didn't need. In v2 nothing
needs deleting — this package carries no backend or vendor SDK at all.

| Concern | Where it lives now |
| --- | --- |
| Supabase | [`core_architecture_supabase`](../core_architecture_supabase) |
| REST / HTTP | [`core_architecture_dio`](../core_architecture_dio) |
| In-app purchases | Your app. Removed in v2.0.0 — extend `Failure` for the error type you need. |
