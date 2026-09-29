# core_architecture

The foundation every app built on this repo shares: a design system you re-brand with one colour,
responsive layout, themed widgets, storage, logging, one error vocabulary, and the `CrudContract`
that keeps features independent of any backend.

It pulls in no backend, no vendor SDK and no router. For data, add
[`core_architecture_supabase`](../core_architecture_supabase) or
[`core_architecture_dio`](../core_architecture_dio). Each re-exports this package, so one import is
enough. **[▶ See it running](https://himera19.github.io/core_architecture/)**

| Area | What's in it |
| --- | --- |
| [Design tokens](#design-tokens) | `AppColors`, `AppTypography`, `AppSpacings`, `AppSizes`, `AppRadius`, `AppBorders`, `AppElevations`, `AppDurations`, `AppOpacities` |
| [Themes](#themes) | Light and dark `ThemeData` from one builder, re-branded by `brandColor` and `fontFamily`, with the mode persisted |
| [Responsive](#responsive) | M3 window size classes, `ResponsiveBuilder`, `ResponsiveValue`, `context.responsive`, `PlatformInfo` |
| [Widgets](#widgets) | `CustomButton`, `CustomTextField`, `CustomDropdown`, `CustomMultiSelectDropdown` |
| [Utilities](#utilities) | `Gap`, `Validators`, `DateHelper`, spacing, radius and border helpers, SnackBar shortcuts, `UrlLauncher` |
| [State and storage](#state-and-storage) | `themeProvider`, `onboardingStateProvider`, secure and preference storage, `LoggerService` |
| [Errors](#errors) | `Failure` for feature code, `AppException` inside services |
| [Building features](#building-features) | `CrudContract`, and the folder layout the scaffolder generates |

---

## Install

```yaml
dependencies:
  core_architecture:
    git:
      url: https://github.com/Himera19/core_architecture.git
      path: packages/core_architecture
      ref: v6.2.0
```

```dart
import 'package:core_architecture/core_architecture.dart';   // also re-exports flutter_riverpod
```

## Setup

```dart
void main() async {
  await CoreInitializer.quickStart();   // binding + .env (if present)
  // or, with your app name in the logs and a custom env file:
  // await CoreInitializer.initialize(const CoreConfig(appName: 'MyApp', envFile: '.env'));

  runApp(const ProviderScope(child: MyApp()));
}
```

```dart
MaterialApp(
  theme: AppTheme.light(),
  darkTheme: AppTheme.dark(),
  themeMode: ref.watch(themeProvider),
  home: const HomeScreen(),
)
```

Routing is up to you. `MaterialApp.router` works the same way; only `routerConfig` changes.

---

## Design tokens

Each token class is a `const` namespace: you never instantiate or subclass it.

```dart
Container(
  padding: const EdgeInsets.all(AppSpacings.rMd),          // 16
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(AppRadius.lg),     // 16
    boxShadow: AppElevations.shadowMd,
    border: Border.all(width: AppBorders.thin, color: context.colorScheme.outline),
  ),
  child: Text('Hello', style: AppTypography.titleMd),
);
```

| Class | Values |
| --- | --- |
| `AppSpacings` | `w*` / `h*` / `r*` ramps: xxs 4 · xs 8 · sm 12 · md 16 · lg 24 · xl 32 · xxl 40 |
| `AppRadius` | sm 4 · md 8 · lg 16 · xl 24 |
| `AppBorders` | border **widths**: thin 1 · normal 2 · thick 3 |
| `AppElevations` | `none`, `level1`…`level5` (1 / 3 / 6 / 8 / 12), `low` / `medium` / `high` / `highest`, `shadowSm` / `Md` / `Lg` |
| `AppDurations` | fast 150ms · normal 300ms · slow 600ms · shimmer 1.5s · splash 2s |
| `AppOpacities` | **alpha 0–255** for `withAlpha`: extraLow 30 · low 80 · medium 160 · high 255 |
| `AppSizes` | icons 4…128 · buttons 40 / 48 / 56 · input 56 · avatars 32 / 48 / 64 · thumbnails 60 / 100 / 150 · card 300×180 · list items 80 / 60 · dialogs 500 wide, max 600 / 700 tall · drag handle 40×4 |
| `AppTypography` | the table below |
| `AppColors` | the palette below |

> Inside widgets, prefer `context.colorScheme` to `AppColors`. The tokens are the raw palette for one
> mode, while the theme switches between modes. Use raw tokens for values that don't change with the
> theme (spacing, radius, sizes, durations) and for building `ThemeData`.

### AppTypography

| Group | Styles | Sizes | Weight |
| --- | --- | --- | --- |
| Display | `displayLg` `displayMd` `displaySm` | 57 / 45 / 36 | w400 |
| Headline | `headlineLg` `headlineMd` `headlineSm` | 32 / 28 / 24 | w600 |
| Title | `titleLg` `titleMd` `titleSm` | 22 / 16 / 14 | w600 / w600 / w500 |
| Body | `bodyLg` `bodyMd` `bodySm` | 16 / 14 / 12 | w400 |
| Label | `labelLg` `labelMd` `labelSm` | 14 / 12 / 11 | w500 |

These styles set size and weight only, with no colour and no font family. Both come from the theme,
so they work in either mode and with whatever font you give `AppTheme`.

### AppColors

```dart
// Brand
AppColors.primary            // 0xFF2563EB Blue-600   AppColors.secondary      // 0xFF3B82F6
AppColors.primaryDark        // dark-mode brand       AppColors.secondaryDark

// Surfaces, text, borders: *Light / *Dark pairs (Slate) feeding the two ColorSchemes
AppColors.surfaceLight / surfaceDark
AppColors.surfaceContainerLight / surfaceContainerDark
AppColors.textPrimaryLight / textPrimaryDark
AppColors.textSecondaryLight / textSecondaryDark
AppColors.borderLight / borderDark

// Status, the same in both modes
AppColors.error    // 0xFFEF4444    AppColors.success  // 0xFF10B981
AppColors.warning  // 0xFFF59E0B    AppColors.info     // 0xFF06B6D4
AppColors.promotion // 0xFFA855F7
```

Only `error` has a `ColorScheme` slot. Reach the other status colours through `AppColors`, which is
what `context.showSuccess()` does.

---

## Themes

```dart
AppTheme.light({Color? brandColor, String? fontFamily, ColorScheme? colorScheme,
                LoadingIndicatorBuilder? loadingIndicatorBuilder})
AppTheme.dark(...)                 // same parameters

lightTheme / darkTheme             // AppTheme.light() / .dark() with no arguments
colorSchemeFor(brightness: …, brandColor: …)   // just the scheme
```

Both modes come from a single builder. They differ only in their `ColorScheme` and base
typography, so radii, button padding, the flat card and the app bar are each defined once.

**`brandColor`** moves every accent: `primary`, `secondary`, their containers, `tertiary` and
`inversePrimary`, which Material widgets use on their own for things like progress tracks and chips.
The tones come from `ColorScheme.fromSeed`, so text on them stays readable even for a light seed
such as yellow. The Slate surfaces, borders, text and `error` stay as they are.

```dart
MaterialApp(
  theme:     AppTheme.light(brandColor: const Color(0xFF7C3AED), fontFamily: 'Inter'),
  darkTheme: AppTheme.dark(brandColor: const Color(0xFF7C3AED), fontFamily: 'Inter'),
  themeMode: ref.watch(themeProvider),
);
```

**`fontFamily`** reaches `ThemeData.fontFamily` and the whole `textTheme`. Either register the
family in your app's `pubspec.yaml` (`flutter: fonts:`), or pass
`GoogleFonts.getFont('Inter').fontFamily`.

**`loadingIndicatorBuilder`** sets the spinner every `CustomButton` shows while loading. It's
Material's by default; plug in flutter_spinkit, Lottie or a brand animation once, here.

**`colorScheme`** replaces the scheme outright and takes priority over `brandColor`. For anything
else, `copyWith` on the result keeps every other token:

```dart
final myLight = AppTheme.light(brandColor: brand).copyWith(
  cardTheme: lightTheme.cardTheme.copyWith(elevation: AppElevations.medium),
);
```

### Already styled, so no need to repeat per widget

| Slot | Styling |
| --- | --- |
| `appBarTheme` | flat, surface-coloured, no tint, left-aligned title |
| `cardTheme` | elevation 0, `AppRadius.lg` corners, outlined with the border token |
| `inputDecorationTheme` | filled surface container, `lg` radius, 2px `primary` focus ring |
| Buttons | `elevated` / `filled` / `outlined` / `text`: `lg` radius, 24×14 padding |
| `textTheme` | Material 2021 scale in the mode's text colour and your font |
| `switchTheme` | white thumb when selected |

The flat look is intentional. Use `AppElevations` to add depth where you want it.

### Theme mode

```dart
ref.watch(themeProvider);                                        // ThemeMode
await ref.read(themeProvider.notifier).setThemeMode(ThemeMode.system);
await ref.read(themeProvider.notifier).toggleTheme();            // light ↔ dark
```

The mode is saved in shared preferences and restored on the next launch. The first frame never
waits for that read, and a choice the user makes while it's still loading wins. Until the user
picks a mode, the app shows `initialThemeModeProvider`, which is `light` unless you override it:

```dart
ProviderScope(
  overrides: [initialThemeModeProvider.overrideWithValue(ThemeMode.system)],
  child: const MyApp(),
)
```

### Reading theme values

```dart
context.theme        // ThemeData
context.textTheme    // TextTheme: titleLarge, bodyMedium, …, with your font and mode
context.colorScheme  // ColorScheme
```

---

## Responsive

Material 3 window size classes:

| Class | Width | Columns | Margin | Typical device |
| --- | --- | --- | --- | --- |
| `compact` | < 600dp | 4 | 16 | Phone portrait |
| `medium` | 600–840dp | 8 | 24 | Tablet portrait, foldable |
| `expanded` | 840–1200dp | 12 | 24 | Tablet landscape, small desktop |
| `large` | ≥ 1200dp | 12 | 24 | Desktop |

```dart
AppBreakpoints.of(context)           // WindowSizeClass. Also fromWidth(double)
AppBreakpoints.columns(sizeClass)    // 4 / 8 / 12 / 12
AppBreakpoints.margin(sizeClass)     // 16 / 24 / 24 / 24
AppBreakpoints.gutter(sizeClass)     // 8 / 16 / 16 / 24
AppBreakpoints.maxContentWidth       // 1200

context.windowSizeClass / isCompact / isMedium / isExpanded / isLarge
context.isDesktopNavigation          // expanded or larger: time for a navigation rail
context.responsive<int>(compact: 1, medium: 2, expanded: 3, large: 4)
```

`ResponsiveBuilder` rebuilds when the size class changes. Only `compact` is required; a missing
builder falls back to the nearest smaller one.

```dart
ResponsiveBuilder(
  compact:  (context) => const MobileLayout(),
  medium:   (context) => const TabletLayout(),
  expanded: (context) => const DesktopLayout(),
);
```

`ResponsiveValue<T>` does the same for a single value. `ResponsiveSpacings` provides ready-made
ones: `pagePadding` (16 → 40), `sectionSpacing` (24 → 64) and `gridColumns` (1 → 4).

```dart
Padding(padding: EdgeInsets.all(ResponsiveSpacings.pagePadding.resolve(context)), child: …);
```

`PlatformInfo` detects the platform at runtime, independent of screen size: `isWeb`, `isMobile`,
`isDesktop`, `isAndroid`, `isIOS`, `isMacOS`, `isWindows`, `isLinux` and `platformName`.

---

## Widgets

All of them follow the theme. **Every user-facing string is a parameter:** the package puts no
English in your UI, so the widgets work in any language.

App bars and bottom navigation are left out on purpose, because both are tied to a router. Build
them with Flutter's `AppBar` / `NavigationBar` and these tokens.

### CustomButton

```dart
CustomButton(
  text: 'Save',
  onPressed: _save,           // null disables it
  type: ButtonType.primary,   // primary | secondary | outlined | danger
  size: ButtonSize.medium,    // small 40 | medium 48 | large 56
  icon: Icons.check,
  isLoading: _saving,         // shows the theme's spinner and ignores taps
  fullWidth: true,
);
```

While `isLoading` is true, taps are ignored, so an action can't fire twice. The spinner comes from
`AppTheme(loadingIndicatorBuilder:)`, or from `loadingIndicator:` for a single button.

### CustomTextField

A themed `TextFormField`. Only `label` is required.

```dart
CustomTextField(
  label: 'Email',
  controller: _email,
  keyboardType: TextInputType.emailAddress,
  prefixIcon: Icons.mail_outline,
  validator: (v) => Validators.email(v, errorMessage: 'Enter a valid email'),
);

CustomTextField(label: 'Password', obscureText: true, showPasswordToggle: true);
```

It also takes `hint`, `initialValue`, `onChanged`, `onSubmitted`, `onTap`, `enabled`, `readOnly`,
`maxLines`, `textInputAction`, `textCapitalization`, `inputFormatters` and `suffixIcon`.

### CustomDropdown / CustomMultiSelectDropdown

Generic over your item type. The choices open in a bottom sheet, optionally with search.

```dart
CustomDropdown<City>(
  label: 'City',
  hintText: 'Select a city',
  searchHint: 'Search…',
  noResultsText: 'No matches',
  items: cities,
  itemLabel: (city) => city.name,
  value: _city,
  onChanged: (city) => setState(() => _city = city),
  type: CustomDropdownType.searchable,   // normal | searchable
);

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

### Gap

`const SizedBox` spacers. `h` means height and `w` means width; the suffix is the `AppSpacings`
step (`Xxs` 4 up to `Xxl` 40).

```dart
Column(children: [title, Gap.hSm, body, Gap.hLg, button]);
Row(children: [const Icon(Icons.star), Gap.wXs, const Text('4.9')]);
```

### Validators

These return `String?`, ready to use as a `validator:`. You always supply the message, so there's
no built-in English.

```dart
Validators.email(v, errorMessage: 'Invalid email')
Validators.password(v, minLength: 8, errorMessage: 'At least 8 characters')
Validators.confirmPassword(v, password.text, errorMessage: 'Does not match')

validator: Validators.compose([        // first failing message wins
  (v) => Validators.required(v, errorMessage: 'Required'),
  (v) => Validators.email(v, errorMessage: 'Invalid email'),
]),
```

The full set is `required`, `email`, `password`, `confirmPassword`, `number`, `positiveNumber`,
`amount`, `minLength`, `maxLength`, `lengthRange`, `phone`, `url`, `date`, `futureDate`,
`pastDate`, `custom` and `compose`.

### DateHelper

Built on `intl`, and it formats in any locale. Day and month names follow `Intl.defaultLocale`
unless you pass a `locale:`. Any locale other than `en` needs `initializeDateFormatting()` first.

```dart
DateHelper.formatDate(date)                          // 15.09.2026, and pattern: / locale: are optional
DateHelper.formatTime(date)                          // 14:30
DateHelper.formatDateTime(date)                      // 15.09.2026 14:30
DateHelper.formatMinutesFromInt(150)                 // 02:30
DateHelper.getDayName(1, locale: 'tr')               // Pazartesi
DateHelper.getMonthName(9, locale: 'en')             // September

DateHelper.isToday / isTomorrow / isYesterday / isSameDay(a, b)
DateHelper.getStartOfDay / getEndOfDay / getDaysInMonth

DateHelper.getGreeting(morning: …, afternoon: …, evening: …, night: …);
DateHelper.getRelativeDate(date, todayLabel: …, yesterdayLabel: …, tomorrowLabel: …,
                           daysAgoSuffix: …, daysLaterSuffix: …);
```

### Layout helpers

```dart
SpacingUtils.all(16) / horizontal(…) / vertical(…) / symmetric(…) / onlyTop(…) …
SpacingUtils.page      // standard screen padding
SpacingUtils.card      // 12 all round

RadiusUtils.all(AppRadius.lg) / only(topLeft: …) / topMd / bottomMd   // bottom sheets
BorderUtils.thin(color) / normal(color) / thick(color)                // 1 / 2 / 3
```

### Context shortcuts and URLs

```dart
context.showSuccess('Saved');       // green floating SnackBar
context.showError('Try again');     // colorScheme.error
context.showInfo('Syncing…');

await UrlLauncher.goToUrl('https://example.com');   // opens externally
```

The SnackBar helpers need a `Scaffold` above them. `url_launcher` needs its usual platform setup
(`LSApplicationQueriesSchemes` on iOS, `<queries>` on Android).

---

## State and storage

| Provider | Type | |
| --- | --- | --- |
| `themeProvider` | `ThemeMode` | Persisted. `.notifier` has `setThemeMode()` and `toggleTheme()` |
| `initialThemeModeProvider` | `ThemeMode` | The mode shown before a choice is stored. Override it in `ProviderScope` |
| `onboardingStateProvider` | `AsyncValue<bool>` | Whether onboarding has been seen. `.notifier` has `markAsSeen()` and `reset()` |
| `secureStorageProvider` | `StorageService` | Keychain / Keystore, for secrets such as tokens |
| `preferencesStorageProvider` | `StorageService` | Shared preferences, for settings |
| `loggerServiceProvider` | `LoggerService` | |

### Storage

Both stores implement the same `StorageService` interface: `write`, `read`, `delete`,
`containsKey` and `clearAll`. Store secrets in the secure one and everything else in preferences.
Keys live in `StorageConstants` rather than as magic strings.

```dart
final secure = ref.read(secureStorageProvider);
await secure.write(key: StorageConstants.accessToken, value: token);

final prefs = ref.read(preferencesStorageProvider);
await prefs.write(key: 'last_tab', value: 'orders');
```

The built-in keys are `accessToken`, `refreshToken`, `themeMode` and `onboardingSeen`. Before 6.0.0
the theme and onboarding flags lived in the keychain. They move across on first read, so nobody
upgrading loses their theme or sees onboarding again.

Because both are providers, tests replace them with an in-memory fake:
`ProviderScope(overrides: [preferencesStorageProvider.overrideWithValue(fake)])`.

### Logging

```dart
final log = ref.read(loggerServiceProvider);

log.d('Cache hit', tag: 'Products');
log.i('User signed in', tag: 'Auth');
log.w('Slow response', tag: 'API');
log.e('Fetch failed', error: e, stackTrace: st, tag: 'API');
log.fatal('Unrecoverable state', tag: 'Core');

log.maskSensitive('sk_live_abc123xyz', visibleStart: 7, visibleEnd: 3);   // sk_live*******xyz
```

`logRequest`, `logResponse` and `logError` are the HTTP versions the backend packages use.

---

## Errors

`Failure` is what repositories throw to feature code. The vocabulary is the same whichever backend
sits underneath, so a screen catches `UnauthorizedFailure` whether it came from Supabase or a REST
API. `AppException` is the lower-level type used inside services.

| Failure | For |
| --- | --- |
| `NetworkFailure` | connectivity, 4xx |
| `ServerFailure` | 5xx |
| `TimeoutFailure` | timeouts |
| `AuthFailure` | sign-in, sign-up |
| `UnauthorizedFailure` | 401 |
| `DatabaseFailure` | queries and writes |
| `ValidationFailure` | input |
| `StorageFailure` / `CacheFailure` | local storage, cache |
| `UnknownFailure` | everything else |

Every failure carries a `message` fit to show, plus an optional `code` and `data`. Add your own
by extending `Failure`:

```dart
final class PaymentFailure extends Failure {
  const PaymentFailure({required super.message, super.code, super.data});
}
```

Three exceptions have unusual names so they never shadow types you already use:
`RequestTimeoutException` (not `dart:async`'s `TimeoutException`), `AuthenticationException` and
`LocalStorageException` (not the Supabase SDK's `AuthException` / `StorageException`). An
unprefixed `on AuthException` in your app always means the SDK's type.

---

## Building features

### CrudContract

This package ships the interface; the backend packages implement it. Write repositories against
it, and switching backends means changing which provider you inject:

```dart
class ProductRepository {
  ProductRepository(this._client);
  final CrudContract _client;

  Future<List<Product>> fetchAll() => _client.query(
    table: 'products',
    fromJson: Product.fromJson,
    filter: {'archived': false},
    orderBy: 'created_at',
    ascending: false,
  );
}

@Riverpod(keepAlive: true)
ProductRepository productRepository(Ref ref) =>
    ProductRepository(ref.watch(supabaseCrudClientProvider));   // or dioCrudClientProvider
```

The operations are `query`, `getById`, `insert`, `update`, `delete`, `upsert`, `batchInsert`,
`batchUpdate`, `batchDelete`, `batchUpsert`, `exists`, `count` and `rpc`.

### Layout

This is the layout `core_architecture create` generates, and the one these packages assume:

```text
lib/
├── main.dart
├── app/                      app-wide: MaterialApp, theme, router, shared helpers
└── features/
    └── products/
        ├── domain/           product.dart: the model, fromJson / toJson
        ├── data/             product_repository.dart: CrudContract only
        ├── application/      controllers shared across screens (e.g. AuthController)
        └── presentation/     screens + their Notifiers
```

**Screens read state and send events, nothing more:** `ref.watch(…)` to rebuild,
`ref.read(…).method()` on a tap. Logic lives in a `Notifier`, and whatever the first load needs
belongs in its `build()`:

```dart
@riverpod
class Products extends _$Products {
  @override
  Future<List<Product>> build() => ref.watch(productRepositoryProvider).fetchAll();

  Future<void> add(String name) async {
    final created = await ref.read(productRepositoryProvider).create(name);
    state = AsyncData([created, ...state.value ?? const []]);
  }
}

class ProductsScreen extends ConsumerWidget {
  const ProductsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (ref.watch(productsProvider)) {
      AsyncData(:final value) => ProductList(products: value),
      AsyncError(:final error) => ErrorView(error: error),
      _ => const Center(child: CircularProgressIndicator()),
    };
  }
}
```

Move UI out of a screen in steps. Keep it as a private method while it's small and used once. Give
it a file in the feature's `presentation/widgets/` once it's reused or large. Move it to `app/`
(or into this package) once several features need it.
