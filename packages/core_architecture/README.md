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
      ref: v3.0.0
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
MaterialApp(
  home: const HomeScreen(),
  theme: lightTheme,
  darkTheme: darkTheme,
  themeMode: ref.watch(themeProvider),
)
```

`lightTheme`, `darkTheme` and `themeProvider` come from this package and need no further setup —
see [Themes](#themes) for what they already style and how to customize them.

This package is **routing-agnostic** — it has no routes, no navigation widgets and no router
dependency. Use whatever you like (`Navigator`, `go_router`, `auto_route`); with
`MaterialApp.router`, pass your own `routerConfig` and keep the three theme arguments unchanged.

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
│   ├── themes/            # lightTheme, darkTheme, lightColorScheme, darkColorScheme
│   ├── tokens/            # Colors, Typography, Spacings, Sizes, Radius, Borders, …
│   └── widgets/           # CustomButton, CustomTextField, CustomDropdown
└── utils/
    ├── extensions/        # ContextExtensions
    └── …                  # Gap, Validators, TurkishPhoneFormatter, DateHelper, …
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

Every token lives in `lib/src/ui/tokens/` and is re-exported from the package barrel, so a single
import gives you all of them:

```dart
import 'package:core_architecture/core_architecture.dart';

Container(
  padding: EdgeInsets.all(AppSpacings.rMd),          // 16
  decoration: BoxDecoration(
    color: AppColors.surfaceContainerLight,
    borderRadius: BorderRadius.circular(AppRadius.lg), // 16
    boxShadow: AppElevations.shadowMd,
  ),
  child: Text('Hello', style: AppTypography.titleMd),
);
```

Each token class is a `final class` with a private constructor — they are namespaces, never
instantiated and never subclassed. Access is always `ClassName.member`.

| Class | Members are | Needs context? |
| --- | --- | --- |
| `AppColors` | `Color` | no |
| `AppTypography` | `TextStyle` + `fontFamily` | no |
| `AppSpacings` | `double` | no |
| `AppSizes` | `double` | no |
| `AppRadius` | `double` | no |
| `AppBorders` | `double` (border **widths**) | no |
| `AppDurations` | `Duration` | no |
| `AppElevations` | `double` + `List<BoxShadow>` | no |
| `AppOpacities` | `int` (alpha 0–255) | no |

> **Prefer `context.colorScheme` over `AppColors` inside widgets.** The tokens are the raw
> palette; the themes map them onto a `ColorScheme` that already flips between light and dark.
> Reading `AppColors.textPrimaryLight` directly hard-codes one mode. Use the raw tokens for
> values that do not change per theme (spacing, radius, durations, sizes) and for building your
> own `ThemeData`. See [Themes](#themes).

### AppColors

```dart
// Brand
AppColors.primary              // 0xFF2563EB  Blue-600
AppColors.secondary            // 0xFF3B82F6  Blue-500
AppColors.onSecondary          // 0xFFFFFFFF

// Surfaces — the *Light / *Dark pairs feed lightColorScheme / darkColorScheme
AppColors.surfaceLight             // 0xFFF8FAFC  Slate-50
AppColors.surfaceDark              // 0xFF0F172A  Slate-950
AppColors.surfaceContainerLight    // 0xFFFFFFFF
AppColors.surfaceContainerDark     // 0xFF1E293B  Slate-800

// Text
AppColors.textPrimaryLight     // 0xFF1E293B    AppColors.textPrimaryDark    // 0xFFF1F5F9
AppColors.textSecondaryLight   // 0xFF64748B    AppColors.textSecondaryDark  // 0xFF94A3B8

// Borders
AppColors.borderLight          // 0xFFCBD5E1    AppColors.borderDark         // 0xFF334155

// Status — identical in both themes
AppColors.error                // 0xFFEF4444
AppColors.success              // 0xFF10B981
AppColors.warning              // 0xFFF59E0B
AppColors.info                 // 0xFF06B6D4
AppColors.promotion            // 0xFFA855F7

// Passthroughs
AppColors.transparent, AppColors.white, AppColors.black, AppColors.amber, AppColors.grey
```

`error` is the only status color wired into the `ColorScheme`. `success`, `warning`, `info` and
`promotion` have no Material slot — reference them through `AppColors` directly (that is what
`context.showSuccess()` does).

### AppTypography

A 15-step scale, every style already carrying `fontFamily`:

| Group | Styles | Sizes | Weight |
| --- | --- | --- | --- |
| Display | `displayLg` `displayMd` `displaySm` | 57 / 45 / 36 | w400 |
| Headline | `headlineLg` `headlineMd` `headlineSm` | 32 / 28 / 24 | w600 |
| Title | `titleLg` `titleMd` `titleSm` | 22 / 16 / 14 | w600 / w600 / w500 |
| Body | `bodyLg` `bodyMd` `bodySm` | 16 / 14 / 12 | w400 |
| Label | `labelLg` `labelMd` `labelSm` | 14 / 12 / 11 | w500 |

```dart
Text('Title',  style: AppTypography.titleLg);
Text('Muted',  style: AppTypography.bodyMd.copyWith(color: context.colorScheme.outline));
```

Styles carry **no color** — they inherit it from the surrounding `DefaultTextStyle` / theme, which
is what keeps them usable in both modes.

### Font

`AppTypography.fontFamily` ships as the placeholder `"YourFontName"`. Until you change it, Flutter
falls back to the platform default. To use your own font, register it in your **app's**
`pubspec.yaml`:

```yaml
flutter:
  fonts:
    - family: Inter
      fonts:
        - asset: assets/fonts/Inter-Regular.ttf
        - asset: assets/fonts/Inter-SemiBold.ttf
          weight: 600
```

The constant lives inside this package, so you cannot reassign it from your app. Either fork the
value here, or override the family at the theme level, which is the supported path:

```dart
final theme = lightTheme.copyWith(
  textTheme: lightTheme.textTheme.apply(fontFamily: 'Inter'),
);
```

### AppSpacings

Three identically-valued ramps, named for intent — `w*` for horizontal gaps, `h*` for vertical
gaps, `r*` for padding and insets:

| Step | xxs | xs | sm | md | lg | xl | xxl |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Value | 4 | 8 | 12 | 16 | 24 | 32 | 40 |

```dart
EdgeInsets.all(AppSpacings.rMd)                       // 16
EdgeInsets.symmetric(horizontal: AppSpacings.wLg)     // 24
const SizedBox(height: AppSpacings.hSm)               // 12  — or just Gap.hSm
```

### AppSizes

Fixed dimensions, grouped by what they measure:

```dart
// Icons        4 · 8 · 16 · 24 · 32 · 64 · 128
AppSizes.iconXxs, iconXs, iconSm, iconMd, iconLg, iconXl, iconXxl

// Buttons & inputs
AppSizes.buttonSm / buttonMd / buttonLg      // 40 / 48 / 56
AppSizes.inputHeight                         // 56

// Avatars      32 · 48 · 64        Thumbnails   60 · 100 · 150
AppSizes.avatarSm / avatarMd / avatarLg
AppSizes.thumbnailSm / thumbnailMd / thumbnailLg

// Cards        300 × 180           Lists        80 / min 60
AppSizes.cardWidth / cardHeight
AppSizes.listItemHeight / listItemMinHeight

// Dialogs      max 500 wide · 600 / 700 tall · 120 button
AppSizes.dialogMaxWidth / dialogMaxHeight / dialogMaxHeightLarge / dialogButtonWidth

// Misc
AppSizes.handleWidth / handleHeight          // 40 × 4  drag handle
AppSizes.onBoard                             // 250     onboarding illustration
```

### AppRadius & AppBorders

```dart
AppRadius.sm / md / lg / xl      // 4 / 8 / 16 / 24  — corner radii
AppBorders.thin / normal / thick // 1 / 2 / 3        — border *widths*, not radii
```

`AppBorders` values are `BorderSide.width` inputs. `BorderUtils` wraps them so you rarely type the
width yourself:

```dart
Container(
  decoration: BoxDecoration(
    border: Border.all(color: context.colorScheme.outline, width: AppBorders.normal),
    borderRadius: BorderRadius.circular(AppRadius.lg),
  ),
);

// equivalent, shorter
Border.fromBorderSide(BorderUtils.normal(context.colorScheme.outline));
```

### AppDurations

```dart
AppDurations.fast     // 150ms — hovers, ripples, small state flips
AppDurations.normal   // 300ms — page transitions, expand/collapse
AppDurations.slow     // 600ms — emphasised motion
AppDurations.shimmer  // 1.5s  — skeleton loop
AppDurations.splash   // 2s    — splash hold

AnimatedContainer(duration: AppDurations.normal, /* … */);
```

### AppElevations

Two kinds of value in one class. The `double`s go to any widget taking `elevation:`; the
`List<BoxShadow>` getters go into a `BoxDecoration`:

```dart
// Material elevation
AppElevations.none / level1 / level2 / level3 / level4 / level5   // 0 / 1 / 3 / 6 / 8 / 12
AppElevations.low / medium / high / highest                       // aliases → 1 / 3 / 6 / 12

Card(elevation: AppElevations.medium);

// Custom shadows
AppElevations.shadowSm   // blur 4,  y+2,  alpha 30
AppElevations.shadowMd   // blur 8,  y+4,  alpha 80
AppElevations.shadowLg   // blur 16, y+8,  alpha 160

Container(decoration: BoxDecoration(boxShadow: AppElevations.shadowLg));
```

Note that `lightTheme`/`darkTheme` set `elevation: 0` on cards and app bars by design — the flat
look is deliberate. Reach for `AppElevations` when you want to opt back in locally.

### AppOpacities

**Alpha values (0–255), not fractions.** They pair with `Color.withAlpha`, not `withOpacity`:

```dart
AppOpacities.extraLow   // 30
AppOpacities.low        // 80
AppOpacities.medium     // 160
AppOpacities.high       // 255

context.colorScheme.primary.withAlpha(AppOpacities.low);   // ✅
context.colorScheme.primary.withOpacity(AppOpacities.low); // ❌ expects 0.0–1.0
```

---

## Themes

Both themes are produced by a single builder, `AppTheme`, from the tokens above. The two modes
differ only in their `ColorScheme` and the base typography they tint — everything else (corner
radii, button padding, the flat card and app bar) is defined once and applies to both.

```dart
lightTheme          // ThemeData — shorthand for AppTheme.light()
darkTheme           // ThemeData — shorthand for AppTheme.dark()

AppTheme.light()    // same, with optional overrides — see Customizing
AppTheme.dark()

lightColorScheme    // const ColorScheme
darkColorScheme     // const ColorScheme

colorSchemeFor(brightness: Brightness.dark)   // the scheme on its own
```

Wire all three into `MaterialApp` and let `themeProvider` drive the mode:

```dart
class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ref.watch(themeProvider),   // persisted to secure storage
      home: const HomeScreen(),
    );
  }
}
```

```dart
await ref.read(themeProvider.notifier).toggleTheme();
await ref.read(themeProvider.notifier).setThemeMode(ThemeMode.dark);
```

`ThemeNotifier` writes the choice through `StorageService` under `StorageConstants.themeMode` and
restores it on next launch. It starts at `ThemeMode.light` and switches once the stored value is
read — it never resolves to `ThemeMode.system`, so what you set is what you get.

### What the themes already style

You get these for free; do not re-specify them per widget:

| Slot | Light | Dark |
| --- | --- | --- |
| `appBarTheme` | flat, `surfaceLight`, no tint, left-aligned title | flat, `surfaceDark` |
| `cardTheme` | elevation 0, `AppRadius.lg` corners, `borderLight` outline | same with `borderDark` |
| `inputDecorationTheme` | filled `surfaceContainerLight`, `lg` radius, 2px `primary` focus ring | filled `surfaceContainerDark`, Blue-400 focus ring |
| Buttons | `elevated` / `filled` / `outlined` / `text` — all `lg` radius, 24×14 padding | same |
| `textTheme` | Material 2021 scale, `fontFamily` applied, `textPrimaryLight` | `textPrimaryDark` |
| `switchTheme` | white thumb when selected | white thumb when selected |

### Reading theme values in a widget

```dart
context.theme        // ThemeData
context.textTheme    // TextTheme  — Material names: titleLarge, bodyMedium, …
context.colorScheme  // ColorScheme

Text('Heading', style: context.textTheme.headlineSmall);
Container(color: context.colorScheme.surfaceContainerHighest);
```

`context.textTheme` is the **Material** scale (`titleLarge`, `bodyMedium`, …) applied by the theme;
`AppTypography` is this package's own scale (`titleLg`, `bodyMd`, …). Both are valid — the first
follows the theme's colors automatically, the second is a fixed `const`. Pick one per surface and
stay consistent.

### Customizing

Both themes come from one builder, `AppTheme`, which takes three optional overrides. This is the
supported way to re-brand — the token classes are `final` with private constructors, so you cannot
subclass or reassign them from your app.

```dart
AppTheme.light({Color? brandColor, String? fontFamily, ColorScheme? colorScheme})
AppTheme.dark ({Color? brandColor, String? fontFamily, ColorScheme? colorScheme})
```

With no arguments they are exactly `lightTheme` / `darkTheme`.

#### brandColor — re-brand the accent

```dart
const brand = Color(0xFF7C3AED);   // violet

MaterialApp(
  theme:     AppTheme.light(brandColor: brand),
  darkTheme: AppTheme.dark(brandColor: brand),
  themeMode: ref.watch(themeProvider),
);
```

Only the four accent slots change — `primary`, `onPrimary`, `secondary`, `onSecondary`. The Slate
surfaces, borders, text colors and the `error` pair stay exactly as they are, so re-branding moves
the accent without disturbing the neutral palette the rest of the design system is built on.

The tones come from `ColorScheme.fromSeed`, so Material 3's own tonal-palette algorithm picks
them: it shifts hue and chroma rather than just lightness, and it guarantees a readable `on*`
partner for any seed — including light ones like yellow, where a naive approach would put white
on yellow.

Everything wired to `colorScheme.primary` follows automatically: the input focus ring, outlined
button borders, and `CustomButton`'s `primary` / `outlined` types.

#### fontFamily — use your own font

`AppTypography.fontFamily` ships as the placeholder `"YourFontName"`, which does not resolve, so
Flutter falls back to the platform default until you override it:

```dart
AppTheme.light(fontFamily: 'Inter')
```

This reaches `ThemeData.fontFamily` and every style in the `textTheme`. Register the family in
your **app's** `pubspec.yaml` first:

```yaml
flutter:
  fonts:
    - family: Inter
      fonts:
        - asset: assets/fonts/Inter-Regular.ttf
        - asset: assets/fonts/Inter-SemiBold.ttf
          weight: 600
```

Note this does not change the `const` `TextStyle`s on `AppTypography` itself — those still carry
the placeholder family. Read type through `context.textTheme` and it follows the override; read it
through `AppTypography.titleMd` and it does not. See
[Reading theme values in a widget](#reading-theme-values-in-a-widget).

#### colorScheme — bring your own scheme

Takes precedence over `brandColor` and replaces the scheme outright, for apps that maintain a full
hand-built palette:

```dart
AppTheme.light(colorScheme: myScheme)
```

#### copyWith — adjust anything else

For component styling the three parameters do not cover, `copyWith` on the result composes
cleanly and keeps every other token:

```dart
final myLight = AppTheme.light(brandColor: brand).copyWith(
  inputDecorationTheme: lightTheme.inputDecorationTheme.copyWith(
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
  ),
  cardTheme: lightTheme.cardTheme.copyWith(elevation: AppElevations.medium),
);
```

#### App-specific tokens

For values the package does not ship (a chart palette, a gradient set), declare your own namespace
next to these and keep the same shape:

```dart
final class BrandColors {
  BrandColors._();
  static const Color chartPositive = Color(0xFF10B981);
  static const Color chartNegative = Color(0xFFEF4444);
}
```

If the value must change with the theme, put it in a `ThemeExtension` instead so it resolves
through `Theme.of(context)` like every other themed value.

---

## Shared Widgets

Three widgets, all already token- and theme-aware.

### CustomButton

Full-width button with four visual types and three heights:

```dart
CustomButton(
  text: 'Save',
  onPressed: _save,
  type: ButtonType.primary,   // primary | secondary | outlined | danger
  size: ButtonSize.medium,    // small (40) | medium (48) | large (56)
  icon: Icons.check,          // optional — rendered left of the label
  isLoading: false,           // swaps the label for a themed SpinKit pulse
);
```

| `ButtonType` | Background | Foreground |
| --- | --- | --- |
| `primary` | `colorScheme.primary` | `onPrimary` |
| `secondary` | `colorScheme.secondary` | `onSecondary` |
| `outlined` | transparent, 2px `primary` border | `primary` |
| `danger` | `colorScheme.error` | `onError` |

`onPressed` is nullable — pass `null` to disable. While `isLoading` is true the button stays
tappable but the callback is swallowed, so it will not fire twice.

### CustomTextField

Themed `TextFormField` wrapper. Everything but `label` is optional:

```dart
CustomTextField(
  label: 'Email',
  hint: 'you@example.com',
  controller: _emailController,
  keyboardType: TextInputType.emailAddress,
  textInputAction: TextInputAction.next,
  prefixIcon: Icons.mail_outline,
  validator: (v) => Validators.email(v, errorMessage: 'Invalid email'),
);

CustomTextField(
  label: 'Password',
  obscureText: true,
  showPasswordToggle: true,   // adds the eye icon and manages the toggle itself
  validator: (v) => Validators.password(v, minLength: 8, errorMessage: 'Too short'),
);
```

Also accepts `initialValue`, `onChanged`, `onSubmitted`, `onTap`, `enabled`, `readOnly`,
`maxLines`, `textCapitalization`, `inputFormatters`, `suffixIcon`.

### CustomDropdown

Generic over your item type; you supply the label mapper:

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

Selection opens in a bottom sheet. For multi-select use the dedicated widget, which returns a list
and can cap the selection count:

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

All user-facing strings are **required parameters**, never hard-coded — the package ships no
localization and will not put English in your UI. Pass your own translated values.

App bars and bottom navigation bars are **not** provided: both are tightly coupled to a routing
package, and shipping them would force that choice on every consumer. Build them in your app with
Flutter's `AppBar` / `NavigationBar` and the design tokens here.

---

## Utilities

### Gap

Pre-built `const SizedBox` spacers, so you never write `SizedBox(height: 16)` again. Prefix `h` =
height, `w` = width; the suffix is the `AppSpacings` step:

```dart
Column(
  children: [
    const Text('Title'),
    Gap.hSm,        // SizedBox(height: 12)
    const Text('Body'),
    Gap.hLg,        // SizedBox(height: 24)
  ],
);

Row(children: [const Icon(Icons.star), Gap.wXs, const Text('4.9')]);
```

Available: `hXxs hXs hSm hMd hLg hXl hXxl` and `wXxs wXs wSm wMd wLg wXl wXxl` (4 → 40).

### SpacingUtils

`EdgeInsets` helpers, plus two layout presets:

```dart
SpacingUtils.all(AppSpacings.rMd)
SpacingUtils.horizontal(AppSpacings.wLg)
SpacingUtils.vertical(AppSpacings.hSm)
SpacingUtils.symmetric(vertical: AppSpacings.hSm, horizontal: AppSpacings.wMd)
SpacingUtils.onlyTop(AppSpacings.hXs)   // …also onlyLeft / onlyRight / onlyBottom
SpacingUtils.zero

SpacingUtils.page   // 16 horizontal, 12 vertical — standard screen padding
SpacingUtils.card   // 12 all round
```

They compose with `+`, which is how `CustomButton` builds its padding:

```dart
padding: SpacingUtils.horizontal(AppSpacings.wMd) + SpacingUtils.vertical(AppSpacings.hSm);
```

### RadiusUtils & BorderUtils

```dart
RadiusUtils.all(AppRadius.lg)
RadiusUtils.only(topLeft: AppRadius.lg, topRight: AppRadius.lg)
RadiusUtils.topMd       // vertical top, 8    — bottom sheets
RadiusUtils.bottomMd    // vertical bottom, 8

BorderUtils.thin(color)    // width 1
BorderUtils.normal(color)  // width 2
BorderUtils.thick(color)   // width 3
```

### Validators

`String?` returning validators, shaped for `TextFormField.validator`. Every one takes the message
as a **required** parameter — no built-in English:

```dart
Validators.email(value, errorMessage: 'Invalid email')
Validators.password(value, minLength: 8, errorMessage: 'At least 8 characters')
Validators.confirmPassword(value, passwordController.text, errorMessage: 'Does not match')
Validators.required(value, errorMessage: 'Required')
```

Compose several — `compose` takes the validator **closures**, not their results, and returns the
first non-null message:

```dart
CustomTextField(
  label: 'Email',
  validator: Validators.compose([
    (v) => Validators.required(v, errorMessage: 'Required'),
    (v) => Validators.email(v, errorMessage: 'Invalid email'),
  ]),
);
```

Full set: `email`, `password`, `confirmPassword`, `required`, `number`, `positiveNumber`, `amount`,
`minLength`, `maxLength`, `lengthRange`, `phone`, `url`, `date`, `futureDate`, `pastDate`,
`custom`, `compose`.

`custom` takes your own predicate:

```dart
Validators.custom(value, (v) => v.startsWith('TR'), 'Must start with TR')
```

### Input formatters

One formatter ships today — `TurkishPhoneFormatter`, which masks input as `(5XX) XXX XX XX` and
caps it at 10 digits:

```dart
CustomTextField(
  label: 'Phone',
  keyboardType: TextInputType.phone,
  inputFormatters: [TurkishPhoneFormatter()],
  validator: (v) => Validators.phone(v, errorMessage: 'Invalid number'),
);
```

Any other `TextInputFormatter` works too — `inputFormatters` is passed straight through.

### ContextExtensions

```dart
context.theme        // ThemeData
context.textTheme    // TextTheme
context.colorScheme  // ColorScheme

context.showSuccess('Saved');              // green floating SnackBar
context.showError('Something went wrong'); // colorScheme.error
context.showInfo('Loading…');              // default SnackBar styling
```

The three SnackBar helpers need a `Scaffold` above them in the tree.

### DateHelper

Formatting and comparison helpers built on `intl`. Turkish day and month names ship as constants;
everything user-facing that is *not* a name takes your own label:

```dart
DateHelper.formatDate(date)               // 15.09.2026
DateHelper.formatTime(date)               // 14:30
DateHelper.formatDateTime(date)           // 15.09.2026 14:30
DateHelper.formatMinutesFromInt(150)      // 02:30

DateHelper.isToday(date)  /  isTomorrow  /  isYesterday  /  isSameDay(a, b)
DateHelper.getStartOfDay(date)  /  getEndOfDay(date)
DateHelper.getDaysInMonth(date)           // List<DateTime>
DateHelper.getDayName(date.weekday)       // 'Pazartesi'
DateHelper.getMonthName(date.month)       // 'Eylül'

DateHelper.getGreeting(
  morning: 'Günaydın', afternoon: 'İyi günler',
  evening: 'İyi akşamlar', night: 'İyi geceler',
);

DateHelper.getRelativeDate(
  date,
  todayLabel: 'Bugün', yesterdayLabel: 'Dün', tomorrowLabel: 'Yarın',
  daysAgoSuffix: 'gün önce', daysLaterSuffix: 'gün sonra',
);
```

### SpinKitIndicator

Themed loading pulse, colored from the current `ColorScheme`:

```dart
SpinKitIndicator.primaryColored(context)              // colorScheme.primary
SpinKitIndicator.onPrimaryColored(context, size: 24)  // colorScheme.onPrimary
```

`size` defaults to 50. `CustomButton` uses the `onPrimary` variant while loading.

### UrlLauncher

```dart
await UrlLauncher.goToUrl('https://example.com');   // opens externally
```

Throws if the platform cannot handle the URL. Requires the usual `url_launcher` platform setup
(`LSApplicationQueriesSchemes` on iOS, `<queries>` on Android).

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
