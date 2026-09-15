# core_architecture

The backend-agnostic foundation: design tokens, themes, a responsive layer, shared widgets,
storage, logging, the `Failure`/`AppException` hierarchy and common utilities.

No backend, no vendor SDK, no router. For data access add
[`core_architecture_supabase`](../core_architecture_supabase) or
[`core_architecture_dio`](../core_architecture_dio) — each re-exports this package, so one import
covers both.

---

## Install

```yaml
dependencies:
  core_architecture:
    git:
      url: https://github.com/Himera19/core_architecture.git
      path: packages/core_architecture
      ref: v3.2.0
```

```dart
import 'package:core_architecture/core_architecture.dart';   // also re-exports flutter_riverpod
```

## Setup

```dart
void main() async {
  await CoreInitializer.quickStart();                  // binding + .env + storage + logging
  // …or, with a custom app name / env file:
  // await CoreInitializer.initialize(const CoreConfig(appName: 'MyApp', envFile: '.env'));

  runApp(const ProviderScope(child: MyApp()));
}
```

```dart
MaterialApp(
  home: const HomeScreen(),
  theme: lightTheme,
  darkTheme: darkTheme,
  themeMode: ref.watch(themeProvider),
)
```

`CoreConfig` holds only `appName` and `envFile`; backend setup lives in the backend packages'
initializers. Routing is yours — `MaterialApp.router` works the same way, only `routerConfig`
differs.

```
lib/src/
├── backends/contracts/   # CrudContract
├── core/                 # CoreInitializer, StorageConstants, BaseEntity, errors, LoggerService
├── providers/            # themeProvider, onboardingStateProvider
├── services/             # StorageService → SecureStorageService
├── ui/                   # tokens/, themes/, responsive/, widgets/
└── utils/                # Gap, Validators, DateHelper, formatters, extensions, …
```

---

## Design tokens

Each token class is a `final class` namespace — `const`, never instantiated, never subclassed.
All are exported from the barrel.

```dart
Container(
  padding: EdgeInsets.all(AppSpacings.rMd),            // 16
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(AppRadius.lg), // 16
    boxShadow: AppElevations.shadowMd,
    border: Border.all(width: AppBorders.thin, color: context.colorScheme.outline),
  ),
  child: Text('Hello', style: AppTypography.titleMd),
);
```

| Class | Holds | Values |
| --- | --- | --- |
| `AppColors` | `Color` | see below |
| `AppTypography` | `TextStyle` + `fontFamily` | 15-step scale |
| `AppSpacings` | `double` | `w*` / `h*` / `r*` ramps — xxs 4 · xs 8 · sm 12 · md 16 · lg 24 · xl 32 · xxl 40 |
| `AppSizes` | `double` | icons, buttons, avatars, cards, dialogs |
| `AppRadius` | `double` | corner radii — sm 4 · md 8 · lg 16 · xl 24 |
| `AppBorders` | `double` | border **widths** — thin 1 · normal 2 · thick 3 |
| `AppDurations` | `Duration` | fast 150ms · normal 300ms · slow 600ms · shimmer 1.5s · splash 2s |
| `AppElevations` | `double` + `List<BoxShadow>` | `none`…`level5` (0/1/3/6/8/12), `shadowSm/Md/Lg` |
| `AppOpacities` | `int` — **alpha 0–255**, for `withAlpha` | extraLow 30 · low 80 · medium 160 · high 255 |

> Inside widgets prefer `context.colorScheme` over `AppColors`: the tokens are the raw palette and
> hard-code one mode, the theme flips between them. Use raw tokens for values that do not change
> per theme (spacing, radius, sizes, durations) and for building `ThemeData`.

### AppColors

```dart
// Brand
AppColors.primary            // 0xFF2563EB  Blue-600     AppColors.secondary  // 0xFF3B82F6
AppColors.primaryDark        // dark-mode brand tokens    AppColors.secondaryDark

// Surfaces — the *Light / *Dark pairs feed lightColorScheme / darkColorScheme
AppColors.surfaceLight           // 0xFFF8FAFC   AppColors.surfaceDark           // 0xFF0F172A
AppColors.surfaceContainerLight  // 0xFFFFFFFF   AppColors.surfaceContainerDark  // 0xFF1E293B

// Text / borders
AppColors.textPrimaryLight       // 0xFF1E293B   AppColors.textPrimaryDark       // 0xFFF1F5F9
AppColors.textSecondaryLight     // 0xFF64748B   AppColors.textSecondaryDark     // 0xFF94A3B8
AppColors.borderLight            // 0xFFCBD5E1   AppColors.borderDark            // 0xFF334155

// Status — identical in both modes
AppColors.error / success / warning / info / promotion
// 0xFFEF4444  0xFF10B981  0xFFF59E0B  0xFF06B6D4  0xFFA855F7

// Passthroughs: transparent, white, black, amber, grey
```

`error` is the only status color wired into the `ColorScheme`; the rest have no Material slot, so
reference them through `AppColors` (that is what `context.showSuccess()` does).

### AppTypography

| Group | Styles | Sizes | Weight |
| --- | --- | --- | --- |
| Display | `displayLg` `displayMd` `displaySm` | 57 / 45 / 36 | w400 |
| Headline | `headlineLg` `headlineMd` `headlineSm` | 32 / 28 / 24 | w600 |
| Title | `titleLg` `titleMd` `titleSm` | 22 / 16 / 14 | w600 / w600 / w500 |
| Body | `bodyLg` `bodyMd` `bodySm` | 16 / 14 / 12 | w400 |
| Label | `labelLg` `labelMd` `labelSm` | 14 / 12 / 11 | w500 |

Styles carry no color — they inherit it, which is what keeps them usable in both modes.
`fontFamily` ships as the placeholder `"YourFontName"`; until you override it Flutter falls back to
the platform default. See [fontFamily](#fontfamily).

### AppSizes

```dart
AppSizes.iconXxs … iconXxl                  // 4 · 8 · 16 · 24 · 32 · 64 · 128
AppSizes.buttonSm / buttonMd / buttonLg     // 40 / 48 / 56     AppSizes.inputHeight   // 56
AppSizes.avatarSm / avatarMd / avatarLg     // 32 / 48 / 64
AppSizes.thumbnailSm / thumbnailMd / thumbnailLg          // 60 / 100 / 150
AppSizes.cardWidth / cardHeight             // 300 × 180
AppSizes.listItemHeight / listItemMinHeight // 80 / 60
AppSizes.dialogMaxWidth / dialogMaxHeight / dialogMaxHeightLarge / dialogButtonWidth
AppSizes.handleWidth / handleHeight         // 40 × 4 drag handle       AppSizes.onBoard  // 250
```

---

## Themes

```dart
lightTheme / darkTheme                        // ThemeData — AppTheme.light() / .dark()
lightColorScheme / darkColorScheme            // const ColorScheme
colorSchemeFor(brightness: Brightness.dark)   // the scheme on its own

await ref.read(themeProvider.notifier).toggleTheme();
await ref.read(themeProvider.notifier).setThemeMode(ThemeMode.dark);
```

Both modes come from one builder and differ only in their `ColorScheme` and base typography —
radii, button padding, the flat card and app bar are defined once. `ThemeNotifier` persists the
choice under `StorageConstants.themeMode` and restores it on next launch; it starts at
`ThemeMode.light` and never resolves to `ThemeMode.system`, so what you set is what you get.

### Already styled — do not re-specify per widget

| Slot | Styling |
| --- | --- |
| `appBarTheme` | flat, surface-colored, no tint, left-aligned title |
| `cardTheme` | elevation 0, `AppRadius.lg` corners, outlined with the border token |
| `inputDecorationTheme` | filled surface container, `lg` radius, 2px `primary` focus ring |
| Buttons | `elevated` / `filled` / `outlined` / `text` — `lg` radius, 24×14 padding |
| `textTheme` | Material 2021 scale with `fontFamily` and the mode's text color |
| `switchTheme` | white thumb when selected |

The flat look is deliberate; reach for `AppElevations` to opt back in locally.

### Reading theme values

```dart
context.theme        // ThemeData
context.textTheme    // TextTheme — Material names: titleLarge, bodyMedium, …
context.colorScheme  // ColorScheme
```

`context.textTheme` is the Material scale applied by the theme (follows overrides and mode);
`AppTypography` is this package's fixed `const` scale. Both are valid — pick one per surface.

### Customizing

```dart
AppTheme.light({Color? brandColor, String? fontFamily, ColorScheme? colorScheme})
AppTheme.dark ({Color? brandColor, String? fontFamily, ColorScheme? colorScheme})
```

With no arguments they are exactly `lightTheme` / `darkTheme`. This is the supported way to
re-brand — token classes are `final` with private constructors and cannot be reassigned from your
app.

**brandColor** moves every accent slot: `primary` / `secondary` with their `on*` partners, plus the
derived ones Material reaches for on its own (containers, `tertiary`, `inversePrimary`). Tones come
from `ColorScheme.fromSeed`, so the `on*` pairs stay readable for any seed. The Slate surfaces,
borders, text and the `error` pair stay put.

```dart
MaterialApp(
  theme:     AppTheme.light(brandColor: const Color(0xFF7C3AED)),
  darkTheme: AppTheme.dark(brandColor: const Color(0xFF7C3AED)),
  themeMode: ref.watch(themeProvider),
);
```

#### fontFamily

Register the family in your **app's** `pubspec.yaml`, then pass it to the builder — it reaches
`ThemeData.fontFamily` and the whole `textTheme`. The `const` styles on `AppTypography` keep the
placeholder family, so read type through `context.textTheme` for the override to apply.

```yaml
flutter:
  fonts:
    - family: Inter
      fonts:
        - asset: assets/fonts/Inter-Regular.ttf
        - asset: assets/fonts/Inter-SemiBold.ttf
          weight: 600
```

```dart
AppTheme.light(fontFamily: 'Inter')
```

#### colorScheme and copyWith

`colorScheme:` replaces the scheme outright and takes precedence over `brandColor`. For anything
else, `copyWith` on the result composes and keeps every other token:

```dart
final myLight = AppTheme.light(brandColor: brand).copyWith(
  cardTheme: lightTheme.cardTheme.copyWith(elevation: AppElevations.medium),
);
```

For values this package does not ship, declare your own `final class` namespace next to these — or
a `ThemeExtension` if the value must change with the theme.

---

## Responsive

Material 3 window size classes.

| Class | Width | Columns | Margin | Typical device |
| --- | --- | --- | --- | --- |
| `compact` | < 600dp | 4 | 16 | Phone portrait |
| `medium` | 600–840dp | 8 | 24 | Tablet portrait, foldable |
| `expanded` | 840–1200dp | 12 | 24 | Tablet landscape, small desktop |
| `large` | ≥ 1200dp | 12 | 24 | Desktop |

```dart
AppBreakpoints.of(context)           // WindowSizeClass — also fromWidth(double)
AppBreakpoints.columns(sizeClass)    // 4 / 8 / 12 / 12
AppBreakpoints.margin(sizeClass)     // 16 / 24 / 24 / 24
AppBreakpoints.gutter(sizeClass)     // 8 / 16 / 16 / 24
AppBreakpoints.maxContentWidth       // 1200

context.isCompact
context.isDesktopNavigation
context.responsive<int>(compact: 1, medium: 2, expanded: 3, large: 4)
```

`ResponsiveBuilder` rebuilds the subtree when the size class changes; only `compact` is required,
the rest fall back to the nearest smaller builder.

```dart
ResponsiveBuilder(
  compact:  (context) => MobileLayout(),
  medium:   (context) => TabletLayout(),
  expanded: (context) => DesktopLayout(),
);
```

`ResponsiveValue` does the same for a scalar. Presets in `ResponsiveSpacings`: `pagePadding`,
`sectionSpacing`, `gridColumns`.

```dart
const padding = ResponsiveValue<double>(compact: 16, medium: 24, expanded: 32, large: 40);
Container(padding: EdgeInsets.all(padding.resolve(context)));
```

`PlatformInfo` is runtime platform detection, independent of screen size: `isWeb`, `isMobile`,
`isDesktop`, `platformName`.

---

## Widgets

Three widgets, all token- and theme-aware. Every user-facing string is a **required parameter** —
the package ships no localization and puts no English in your UI.

App bars and bottom navigation are deliberately absent: both are coupled to a routing package.
Build them with Flutter's `AppBar` / `NavigationBar` and the tokens here.

### CustomButton

```dart
CustomButton(
  text: 'Save',
  onPressed: _save,           // null disables the button
  type: ButtonType.primary,   // primary | secondary | outlined | danger
  size: ButtonSize.medium,    // small 40 | medium 48 | large 56
  icon: Icons.check,          // optional, left of the label
  isLoading: false,           // swaps the label for a themed SpinKit pulse
);
```

| `ButtonType` | Background | Foreground |
| --- | --- | --- |
| `primary` | `colorScheme.primary` | `onPrimary` |
| `secondary` | `colorScheme.secondary` | `onSecondary` |
| `outlined` | transparent, 2px `primary` border | `primary` |
| `danger` | `colorScheme.error` | `onError` |

Full width. While `isLoading` is true the callback is swallowed, so it cannot fire twice.

### CustomTextField

Themed `TextFormField` wrapper; everything but `label` is optional.

```dart
CustomTextField(
  label: 'Email',
  hint: 'you@example.com',
  controller: _emailController,
  keyboardType: TextInputType.emailAddress,
  prefixIcon: Icons.mail_outline,
  validator: (v) => Validators.email(v, errorMessage: 'Invalid email'),
);

CustomTextField(
  label: 'Password',
  obscureText: true,
  showPasswordToggle: true,   // adds the eye icon and manages the toggle itself
);
```

Also accepts `initialValue`, `onChanged`, `onSubmitted`, `onTap`, `enabled`, `readOnly`,
`maxLines`, `textInputAction`, `textCapitalization`, `inputFormatters`, `suffixIcon`.

### CustomDropdown

Generic over your item type; selection opens in a bottom sheet.

```dart
CustomDropdown<City>(
  label: 'City',
  hintText: 'Select a city',
  searchHint: 'Search…',
  noResultsText: 'No matches',
  items: cities,
  itemLabel: (city) => city.name,
  value: _selected,
  onChanged: (city) => setState(() => _selected = city),
  type: CustomDropdownType.searchable,   // normal | searchable | multiSelect
  validator: (v) => v == null ? 'Required' : null,
);
```

Multi-select is a separate widget returning a list, with an optional cap:

```dart
CustomMultiSelectDropdown<Tag>(
  label: 'Tags',
  hintText: 'Pick tags',
  selectedCountSuffix: 'selected',
  clearLabel: 'Clear',
  confirmLabel: 'Done',
  maxSelectionMessage: 'You can pick at most 3',
  items: tags,
  itemLabel: (t) => t.name,
  initialValues: _tags,
  maxSelections: 3,
  onChanged: (tags) => setState(() => _tags = tags),
);
```

---

## Utilities

### Gap — `const SizedBox` spacers

`h` = height, `w` = width; the suffix is the `AppSpacings` step (`Xxs Xs Sm Md Lg Xl Xxl`, 4 → 40).

```dart
Column(children: [const Text('Title'), Gap.hSm, const Text('Body'), Gap.hLg]);
Row(children: [const Icon(Icons.star), Gap.wXs, const Text('4.9')]);
```

### SpacingUtils / RadiusUtils / BorderUtils

```dart
SpacingUtils.all(AppSpacings.rMd)          SpacingUtils.horizontal(…) / vertical(…)
SpacingUtils.symmetric(vertical: …, horizontal: …)
SpacingUtils.onlyTop(…) / onlyLeft / onlyRight / onlyBottom          SpacingUtils.zero
SpacingUtils.page   // 16 horizontal, 12 vertical — standard screen padding
SpacingUtils.card   // 12 all round

RadiusUtils.all(AppRadius.lg)              RadiusUtils.only(topLeft: …, topRight: …)
RadiusUtils.topMd / bottomMd               // vertical-only, 8 — bottom sheets

BorderUtils.thin(color) / normal(color) / thick(color)     // widths 1 / 2 / 3
```

`EdgeInsets` compose with `+`, which is how `CustomButton` builds its padding:

```dart
padding: SpacingUtils.horizontal(AppSpacings.wMd) + SpacingUtils.vertical(AppSpacings.hSm);
```

### Validators

`String?` returning, shaped for `TextFormField.validator`. The message is always a required
parameter — no built-in English.

```dart
Validators.email(value, errorMessage: 'Invalid email')
Validators.password(value, minLength: 8, errorMessage: 'At least 8 characters')
Validators.confirmPassword(value, passwordController.text, errorMessage: 'Does not match')
Validators.custom(value, (v) => v.startsWith('TR'), 'Must start with TR')
```

Full set: `email`, `password`, `confirmPassword`, `required`, `number`, `positiveNumber`, `amount`,
`minLength`, `maxLength`, `lengthRange`, `phone`, `url`, `date`, `futureDate`, `pastDate`,
`custom`, `compose`.

`compose` takes the validator **closures**, not their results, and returns the first non-null
message:

```dart
validator: Validators.compose([
  (v) => Validators.required(v, errorMessage: 'Required'),
  (v) => Validators.email(v, errorMessage: 'Invalid email'),
]),
```

### Input formatters

`TurkishPhoneFormatter` masks input as `(5XX) XXX XX XX`, capped at 10 digits. Any other
`TextInputFormatter` works too — `inputFormatters` is passed straight through.

```dart
CustomTextField(
  label: 'Phone',
  keyboardType: TextInputType.phone,
  inputFormatters: [TurkishPhoneFormatter()],
  validator: (v) => Validators.phone(v, errorMessage: 'Invalid number'),
);
```

### Context extensions

```dart
context.theme / textTheme / colorScheme

context.showSuccess('Saved');               // green floating SnackBar
context.showError('Something went wrong');  // colorScheme.error
context.showInfo('Loading…');               // default SnackBar styling
```

The SnackBar helpers need a `Scaffold` above them in the tree.

### DateHelper

Built on `intl`. Turkish day and month names ship as constants; everything else user-facing takes
your own label.

```dart
DateHelper.formatDate(date)            // 15.09.2026
DateHelper.formatTime(date)            // 14:30
DateHelper.formatDateTime(date)        // 15.09.2026 14:30
DateHelper.formatMinutesFromInt(150)   // 02:30

DateHelper.isToday / isTomorrow / isYesterday / isSameDay(a, b)
DateHelper.getStartOfDay(date) / getEndOfDay(date) / getDaysInMonth(date)
DateHelper.getDayName(date.weekday)    // 'Pazartesi'
DateHelper.getMonthName(date.month)    // 'Eylül'

DateHelper.getGreeting(morning: …, afternoon: …, evening: …, night: …);
DateHelper.getRelativeDate(date,
  todayLabel: …, yesterdayLabel: …, tomorrowLabel: …,
  daysAgoSuffix: …, daysLaterSuffix: …);
```

### SpinKitIndicator / UrlLauncher

```dart
SpinKitIndicator.primaryColored(context)              // colorScheme.primary, size 50
SpinKitIndicator.onPrimaryColored(context, size: 24)  // used by CustomButton while loading

await UrlLauncher.goToUrl('https://example.com');     // opens externally, throws if unsupported
```

`url_launcher` needs the usual platform setup (`LSApplicationQueriesSchemes` on iOS, `<queries>` on
Android).

---

## Providers

| Provider | Type | Notes |
| --- | --- | --- |
| `themeProvider` | `ThemeMode` | Persisted; `.notifier` has `toggleTheme()` / `setThemeMode()` |
| `onboardingStateProvider` | `AsyncValue<bool>` | `.notifier` has `markAsSeen()` / `reset()` |
| `storageServiceProvider` | `StorageService` | Backed by `SecureStorageService` |
| `loggerServiceProvider` | `LoggerService` | |

### Storage

`StorageService` is an abstract interface over `flutter_secure_storage`. Keys live in
`StorageConstants` — never magic strings.

```dart
final storage = ref.read(storageServiceProvider);

await storage.write(key: StorageConstants.accessToken, value: 'abc123');
final token = await storage.read(key: StorageConstants.accessToken);
await storage.containsKey(key: StorageConstants.accessToken);
await storage.delete(key: StorageConstants.accessToken);
await storage.clearAll();
```

Shipped keys: `accessToken`, `refreshToken`, `themeMode`, `onboardingSeen`. Subclass
`SecureStorageService` for app-specific helpers.

### Logging

```dart
final logger = ref.read(loggerServiceProvider);

logger.d('Debug message', tag: 'MyFeature');
logger.i('User logged in', tag: 'Auth');
logger.w('Cache miss', tag: 'Cache');
logger.e('API failed', error: e, stackTrace: st, tag: 'API');
logger.fatal('Unrecoverable error', error: e, tag: 'Core');

logger.maskSensitive('sk_live_abc123xyz', visibleStart: 7, visibleEnd: 3); // sk_live*******xyz
```

`logRequest` / `logResponse` / `logError` are the HTTP-shaped variants the backend packages use.

---

## Errors

`Failure` is what repositories throw at feature code — a stable, backend-independent vocabulary.
`AppException` is the lower-level type used inside services.

| Failure | Use case |
| --- | --- |
| `NetworkFailure` | Connectivity |
| `ServerFailure` | 5xx |
| `TimeoutFailure` | Request timeouts |
| `AuthFailure` | Authentication |
| `UnauthorizedFailure` | 401 |
| `DatabaseFailure` | DB operations |
| `ValidationFailure` | Input validation |
| `StorageFailure` | Local storage |
| `CacheFailure` | Cache misses/errors |
| `UnknownFailure` | Catch-all |

```dart
throw const ServerFailure(message: 'Failed to fetch orders');

final class PaymentFailure extends Failure {
  const PaymentFailure({required super.message, super.code, super.data});
}
```

Exceptions: `NetworkException`, `ServerException`, `UnauthorizedException`, `DatabaseException`,
`ValidationException`, `CacheException`, plus three named to avoid shadowing types you rely on:

| Core exception | Deliberately *not* named |
| --- | --- |
| `RequestTimeoutException` | `TimeoutException` — `dart:async`, thrown by `Future.timeout()` |
| `AuthenticationException` | `AuthException` — Supabase SDK |
| `LocalStorageException` | `StorageException` — Supabase SDK |

So an unprefixed `on AuthException` / `on TimeoutException` in your app always means the SDK's or
`dart:async`'s type, never this package's.

---

## Backends

This package ships the `CrudContract` interface and no implementation. Type your repositories
against it and the backend becomes an injection detail:

```dart
class ProductRepository {
  ProductRepository(this._client);
  final CrudContract _client;

  Future<List<Product>> fetchAll() =>
      _client.query(table: 'products', fromJson: Product.fromJson);
}

ProductRepository(ref.watch(supabaseCrudClientProvider));   // or dioCrudClientProvider
```

Operations: `query`, `getById`, `insert`, `update`, `delete`, `upsert`, `batchInsert`,
`batchUpdate`, `batchDelete`, `batchUpsert`, `exists`, `count`, `rpc`.

| Need | Add | Import |
| --- | --- | --- |
| Supabase | [`core_architecture_supabase`](../core_architecture_supabase) | `package:core_architecture_supabase/core_architecture_supabase.dart` |
| REST API | [`core_architecture_dio`](../core_architecture_dio) | `package:core_architecture_dio/core_architecture_dio.dart` |
| Neither | — | `package:core_architecture/core_architecture.dart` |

---

## Feature conventions

The layout these packages assume for features built on top of them:

```
features/product/
├── models/       # data classes, JSON serialization
├── services/     # repository / data access
├── providers/    # controllers (Notifiers) + simple providers
├── pages/        # ≤ ~200 lines, no logic
├── widgets/      # used only in this feature
└── helpers/      # optional: pure functions, formatters, mappers
```

**Pages read state and dispatch events, nothing else** — `ref.watch(…)` to rebuild,
`ref.read(…).method()` on interaction. All logic lives in a `Notifier` named after the page.
Anything needed on first load belongs in `Notifier.build()`, never in a widget's `build`.

```dart
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
}

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

Extracting UI: a private method while it is small, stateless and used once; a file in
`feature/widgets/` once it is reused or large; `core/widgets/` (or this package) once several
features need it.
