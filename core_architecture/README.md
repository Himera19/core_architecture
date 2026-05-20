# core_architecture

Reusable Flutter package providing the foundational layer for all projects: backend adapters, design tokens, responsive utilities, shared widgets, and common utilities.

---

## Installation

```yaml
dependencies:
  core_architecture:
    path: ../packages/core_architecture
```

## Setup

Call `CoreInitializer.initialize` before `runApp`:

```dart
void main() async {
  await CoreInitializer.initialize(
    CoreConfig(
      appName: 'MyApp',
      useSupabase: true,   // or useDio: true
      envFile: '.env',
    ),
  );
  runApp(ProviderScope(child: MyApp()));
}
```

Configure your `MaterialApp` theme:

```dart
MaterialApp.router(
  theme: LightTheme.theme,
  darkTheme: DarkTheme.theme,
  themeMode: ref.watch(themeProvider),
)
```

---

## Package Structure

```
lib/src/
├── backends/
│   ├── contracts/         # CrudContract interface
│   ├── dio/               # Dio HTTP client + providers
│   └── supabase/          # Supabase client + providers
├── core/
│   ├── config/            # CoreInitializer, CoreConfig
│   ├── constants/         # StorageConstants
│   ├── entities/          # BaseEntity
│   ├── errors/            # Failures, Exceptions, PurchaseFailure
│   └── logging/           # LoggerService
├── providers/             # ThemeProvider, OnboardingProvider
├── services/              # StorageService, SecureStorageService
├── ui/
│   ├── responsive/        # Breakpoints, ResponsiveBuilder, ResponsiveValue, PlatformInfo
│   ├── themes/            # LightTheme, DarkTheme, AppColorScheme
│   ├── tokens/            # Colors, Typography, Spacings, Sizes, Radius, Borders, …
│   └── widgets/           # CustomAppBar, CustomButton, CustomTextField, …
└── utils/
    ├── extensions/        # ContextExtensions
    └── …                  # Gap, Validators, InputFormatters, DateHelper, …
```

---

## Backend Selection

Only enable the backend(s) you actually use. Remove unused dependencies from `pubspec.yaml`.

### Supabase

```dart
CoreConfig(useSupabase: true, deleteUserRpcName: 'delete_user')
```

Import via `package:core_architecture/supabase.dart` for Supabase-specific types.

### Dio (REST API)

```dart
CoreConfig(useDio: true, dioBaseUrl: 'https://api.example.com')
```

Import via `package:core_architecture/dio.dart` for Dio-specific types.

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
LightTheme.theme   // ThemeData
DarkTheme.theme    // ThemeData
AppColorScheme     // shared ColorScheme helpers
```

Switch themes via `ThemeProvider`:

```dart
ref.read(themeProvider.notifier).toggle();
```

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

| Provider | Description |
|---|---|
| `themeProvider` | `ThemeMode` — persists to storage |
| `onboardingProvider` | Whether the user has completed onboarding |

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

## Optional Modules

### In-App Purchases

Requires `purchases_flutter`. If not needed, remove from `pubspec.yaml` and delete `purchase_failure.dart`.

### Supabase

If not needed, remove `supabase_flutter` from `pubspec.yaml` and the `supabase/` backend files.
