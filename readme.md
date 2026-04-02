# Core Architecture

A production-ready, modular Flutter architecture package built on **Riverpod 3** with pluggable backend support for **Supabase** and **Dio (REST API)**.

Drop it into any Flutter project as a local package, keep what you need, delete what you don't.

**Version:** 1.3.1 · **Status:** Active development · **License:** MIT

---

## Table of Contents

* [Features](#-features)
* [Quick Start](#-quick-start)
* [Architecture Overview](#-architecture-overview)
* [Backend Selection](#-backend-selection)
* [Core Layer](#-core-layer)
* [UI Design System](#-ui-design-system)
* [Utilities](#-utilities)
* [Providers](#-providers)
* [CRUD Operations](#-crud-operations)
* [Authentication (Supabase)](#-authentication-supabase)
* [Logging](#-logging)
* [Adding a New Feature](#-adding-a-new-feature)
* [Customization Guide](#-customization-guide)
* [Optional Modules](#-optional-modules)
* [Claude Code Integration](#-claude-code-integration)
* [Changelog](#-changelog)
* [Troubleshooting](#-troubleshooting)
* [Quick Reference](#-quick-reference)

---

## ✨ Features

| Category | What's Included |
| --- | --- |
| **State Management** | Riverpod 3 with code generation |
| **Backend** | Supabase & Dio (REST API) — pick one or both |
| **UI System** | Design tokens, themes, responsive utilities, reusable widgets |
| **Error Handling** | Extensible `Failure` / `AppException` hierarchy |
| **Storage** | Encrypted key-value storage with centralized `StorageConstants` |
| **Logging** | Production-aware logger with HTTP request/response tracking |
| **Routing** | GoRouter integration with custom page transitions |
| **Validation** | Email, phone, password, IBAN, credit card, and more — consumer-provided messages |
| **In-App Purchases** | RevenueCat error handling (optional, removable) |

---

## 🚀 Quick Start

### 1. Add the Package

```yaml
# your_app/pubspec.yaml
dependencies:
  core_architecture:
    path: packages/core_architecture
```

### 2. Install Dependencies & Generate Code

```bash
cd packages/core_architecture
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
cd ../..
flutter pub get
```

### 3. Configure Environment

```yaml
# your_app/pubspec.yaml
flutter:
  assets:
    - .env
```

```bash
# .env (add to .gitignore!)
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key

# Or for REST API:
API_BASE_URL=https://api.example.com
```

### 4. Initialize in `main.dart`

```dart
import 'package:core_architecture/core_architecture.dart';
import 'package:core_architecture/supabase.dart';
// or: import 'package:core_architecture/dio.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // CoreInitializer now handles backend initialization automatically
  await CoreInitializer.initialize(
    CoreConfig(
      appName: 'MyApp',
      useSupabase: true,
      // deleteUserRpcName: 'delete_user', // optional, this is the default
    ),
  );

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    return MaterialApp.router(
      routerConfig: ref.read(routeConfigProvider),
      title: 'MyApp',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeMode,
    );
  }
}
```

---

## 🏗 Architecture Overview

```
lib/
├── core_architecture.dart     # Main barrel — core exports only
├── dio.dart                   # Dio barrel — core + Dio backend
├── supabase.dart              # Supabase barrel — core + Supabase backend
└── src/
    ├── backends/
    │   ├── contracts/         # CrudContract interface
    │   ├── dio/               # Dio service, CRUD client, providers
    │   └── supabase/          # Supabase service, CRUD client, providers
    ├── core/
    │   ├── config/            # CoreInitializer, CoreConfig
    │   ├── constants/         # StorageConstants and app-wide constants
    │   ├── entities/          # BaseEntity (id, equality, copyWith, toString)
    │   ├── errors/            # Failure & Exception hierarchy
    │   └── logging/           # LoggerService
    ├── providers/             # Theme & Onboarding state
    ├── services/              # StorageService abstraction
    ├── ui/
    │   ├── themes/            # Light & dark ThemeData
    │   ├── tokens/            # Colors, typography, spacings, etc.
    │   └── widgets/           # Reusable widgets
    └── utils/                 # Helpers, validators, extensions
```

### Import Strategy

```dart
// Core only (no backend specifics)
import 'package:core_architecture/core_architecture.dart';

// Core + Supabase
import 'package:core_architecture/supabase.dart';

// Core + Dio (REST API)
import 'package:core_architecture/dio.dart';
```

> Do not mix barrel imports. Use `supabase.dart` or `dio.dart` — each re-exports `core_architecture.dart` automatically.

---

## 🔌 Backend Selection

### Using Supabase Only

1. Delete `lib/src/backends/dio/` directory
2. Delete `lib/dio.dart` barrel file
3. Remove `dio` from `pubspec.yaml`

### Using Dio (REST API) Only

1. Delete `lib/src/backends/supabase/` directory
2. Delete `lib/supabase.dart` barrel file
3. Remove `supabase_flutter` from `pubspec.yaml`

---

## 🧱 Core Layer

### CoreInitializer

Bootstraps the application and **automatically initializes the selected backend**. No need to call `SupabaseService.initialize()` or `DioService.initialize()` manually.

```dart
await CoreInitializer.initialize(
  CoreConfig(
    appName: 'MyApp',
    useSupabase: true,
    useDio: false,
    deleteUserRpcName: 'delete_user', // configurable RPC name
  ),
);
```

### BaseEntity

Abstract base for all database entities. Provides:
- `id` field
- `==` / `hashCode` equality by id
- Abstract `copyWith()`
- `toString()`

```dart
@JsonSerializable()
class OrderModel extends BaseEntity {
  final String title;
  final double amount;

  const OrderModel({
    required super.id,
    required this.title,
    required this.amount,
  });

  @override
  OrderModel copyWith({String? id, String? title, double? amount}) =>
      OrderModel(
        id: id ?? this.id,
        title: title ?? this.title,
        amount: amount ?? this.amount,
      );

  factory OrderModel.fromJson(Map<String, dynamic> json) =>
      _$OrderModelFromJson(json);

  Map<String, dynamic> toJson() => _$OrderModelToJson(this);
}
```

### Error Handling

```dart
// Always use Failure subclasses — never throw raw exceptions
throw const ServerFailure(message: 'Failed to fetch orders');
throw const NetworkFailure(message: 'No connection');
throw const AuthFailure(message: 'Session expired');
```

**Built-in failure types:**

| Failure | Use Case |
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

**Extending with project-specific failures:**

```dart
final class PaymentFailure extends Failure {
  const PaymentFailure({required super.message, super.code, super.data});
}
```

### Storage Service & StorageConstants

All storage keys are centralized in `StorageConstants` — never use magic strings.

```dart
// ❌ Wrong
await storage.write(key: 'access_token', value: token);

// ✅ Correct
await storage.write(key: StorageConstants.accessToken, value: token);
```

```dart
final storage = ref.read(storageServiceProvider);

await storage.write(key: StorageConstants.accessToken, value: 'abc123');
final token = await storage.read(key: StorageConstants.accessToken);
await storage.delete(key: StorageConstants.accessToken);
await storage.clearAll();
```

---

## 🎨 UI Design System

### Design Tokens

All visual constants are centralized in `lib/src/ui/tokens/`. **Never use raw values.**

```dart
// ❌ Wrong
Container(padding: EdgeInsets.all(16))
Text('Hello', style: TextStyle(fontSize: 18, color: Colors.black))
SizedBox(height: 8)

// ✅ Correct
Container(padding: SpacingUtils.all(AppSpacings.wMd))
Text('Hello', style: AppTypography.bodyLg)
Gap.hSm
```

| Token | Location | Note |
| --- | --- | --- |
| Colors | `AppColors.*` | |
| Typography | `AppTypography.*` | No color set — inherits from theme |
| Spacing | `AppSpacings.*` + `SpacingUtils.*` | |
| Radius | `AppRadius.*` | |
| Sizes | `AppSizes.*` | |
| Durations | `AppDurations.*` | |
| Elevations | `AppElevations.*` | |
| Gaps | `Gap.hSm / Gap.wMd` | All `const` |
| Opacity | `AppOpacities.*` | Alpha values 0–255 |

> **AppTypography** text styles have no color — they inherit from the active theme. Use `copyWith(color: context.colorScheme.primary)` when a specific color is needed.

### Themes

```dart
MaterialApp(
  theme: lightTheme,
  darkTheme: darkTheme,
  themeMode: ref.watch(themeProvider),
)
```

### Widgets

All string parameters are **required** — the consumer passes localized strings.

| Widget | Description |
| --- | --- |
| `CustomButton` | Primary/secondary/outlined with icon support |
| `CustomTextField` | Labeled input with validation and prefix/suffix icons |
| `CustomDropdown<T>` | Searchable dropdown — requires `hintText`, `searchHint`, `noResultsText` |
| `CustomMultiSelectDropdown<T>` | Multi-select — requires `hintText`, `selectedCountSuffix`, `clearLabel`, `confirmLabel`, `maxSelectionMessage` |
| `CustomAppBar` | Consistent app bar |
| `Navbar` | Bottom navigation bar |

```dart
CustomDropdown<String>(
  label: 'City',
  items: ['Istanbul', 'Ankara'],
  itemLabel: (city) => city,
  hintText: context.l10n.selectCity,
  searchHint: context.l10n.search,
  noResultsText: context.l10n.noResults,
  onChanged: (value) {},
)
```

---

## 🛠 Utilities

### Spacing & Layout

```dart
Container(padding: SpacingUtils.all(AppSpacings.wMd))
Container(padding: SpacingUtils.horizontal(AppSpacings.wLg))

Column(children: [
  Widget1(),
  Gap.hMd,
  Widget2(),
])
```

### Context Extensions

```dart
context.colorScheme.primary
context.textTheme.titleLarge
context.showSuccess('Operation successful')
context.showError('Something went wrong')
context.showInfo('Note: ...')
```

### Validators

All validators require the consumer to provide error messages — the package holds zero strings.

```dart
// ❌ Wrong
validator: Validators.email,

// ✅ Correct
validator: (value) => Validators.email(
  value,
  errorMessage: context.l10n.invalidEmail,
),
```

**Available validators:**
`email`, `password`, `confirmPassword`, `required`, `number`,
`positiveNumber`, `amount`, `minLength`, `maxLength`, `lengthRange`,
`phone`, `url`, `date`, `futureDate`, `pastDate`, `custom`, `compose`

> `turkishPhone`, `turkishLiraFormat` and `tcNumber` were removed in v1.3.1.

### DateHelper

String labels are provided by the consumer — no hardcoded strings in the package.

```dart
DateHelper.getGreeting(
  morning: context.l10n.goodMorning,
  afternoon: context.l10n.goodAfternoon,
  evening: context.l10n.goodEvening,
  night: context.l10n.goodNight,
);

DateHelper.getRelativeDate(
  date,
  todayLabel: context.l10n.today,
  yesterdayLabel: context.l10n.yesterday,
  tomorrowLabel: context.l10n.tomorrow,
  daysAgoSuffix: context.l10n.daysAgo,
  daysLaterSuffix: context.l10n.daysLater,
);
```

### Other Utilities

| Utility | Description |
| --- | --- |
| `PlatformInfo` | Check current platform (`isWeb`, `isMobile`, `isDesktop`) |
| `AppBreakpoints` | Material 3 Window Size Classes |
| `ResponsiveValue` | Adaptive values based on screen size |
| `ResponsiveBuilder` | UI builder based on breakpoint |
| `InputFormatters` | TextInputFormatter implementations |
| `RadiusUtils` | BorderRadius factory methods |
| `BorderUtils` | Border factory methods |
| `SpinKitIndicator` | Loading animation widget |
| `UrlLauncher` | Open URLs in browser |

---

## 🔄 Providers

### Theme Provider

```dart
final themeMode = ref.watch(themeProvider);
ref.read(themeProvider.notifier).toggleTheme();
ref.read(themeProvider.notifier).setThemeMode(ThemeMode.dark);
```

### Onboarding Provider

```dart
final seen = await ref.read(onboardingStateProvider.future);
ref.read(onboardingStateProvider.notifier).markAsSeen();
ref.read(onboardingStateProvider.notifier).reset();
```

---

## 💾 CRUD Operations

Both backends implement `CrudContract`:

| Method | Description |
| --- | --- |
| `query<T>` | List with filter, sort, pagination |
| `getById<T>` | Single record by ID |
| `insert<T>` | Create new record |
| `update<T>` | Update existing record |
| `delete` | Delete record |
| `batchInsert<T>` | Bulk create |
| `batchUpdate<T>` | Bulk update |
| `batchDelete` | Bulk delete |
| `upsert<T>` | Insert or update (onConflict supported) |
| `batchUpsert<T>` | Bulk upsert |
| `exists` | Check record existence |
| `count` | Server-side count (safe for large tables) |
| `rpc` | Remote procedure call — returns `Future<dynamic>` |

### Example

```dart
@riverpod
class TodosNotifier extends _$TodosNotifier {
  @override
  Future<List<Todo>> build() async {
    final client = ref.watch(supabaseCrudClientProvider);

    return await client.query<Todo>(
      table: 'todos',
      fromJson: (json) => Todo.fromJson(json),
      filter: {'user_id': userId},
      orderBy: 'created_at',
      ascending: false,
      limit: 20,
    );
  }
}
```

---

## 🔐 Authentication (Supabase)

Session persistence is managed by the Supabase SDK — never write auth tokens to storage manually.

```dart
final auth = ref.read(supabaseAuthProvider.notifier);

await auth.signIn(email: 'user@email.com', password: '123456');
await auth.signUp(email: 'user@email.com', password: '123456');
await auth.signOut();
await auth.resetPassword('user@email.com');
await auth.updateMetadata({'avatar_url': 'https://...'});
await auth.deleteAccount(); // RPC name configurable via CoreConfig
```

Auth errors are rethrown raw — the consumer handles display messages:

```dart
} catch (e) {
  final message = _mapAuthError(e); // your own mapping
  state = AsyncError(message, st);
}
```

---

## 📊 Logging

```dart
final logger = ref.read(loggerServiceProvider);

logger.d('Debug message', tag: 'MyFeature');
logger.i('User logged in', tag: 'Auth');
logger.w('Cache miss', tag: 'Cache');
logger.e('API failed', error: e, stackTrace: st, tag: 'API');
logger.fatal('Unrecoverable error', error: e, tag: 'Core');

// Mask sensitive data
logger.maskSensitive('sk_live_abc123xyz', visibleStart: 7, visibleEnd: 3);
// Output: "sk_live*******xyz"
```

---

## 🚦 Adding a New Feature

1. **Create feature directory:**

```
lib/features/orders/
├── models/
│   └── order_model.dart
├── providers/
│   └── orders_notifier.dart
├── pages/
│   └── orders_page.dart
└── widgets/
```

2. **Define model:**

```dart
@JsonSerializable()
class OrderModel extends BaseEntity {
  final String title;

  const OrderModel({required super.id, required this.title});

  @override
  OrderModel copyWith({String? id, String? title}) =>
      OrderModel(id: id ?? this.id, title: title ?? this.title);

  factory OrderModel.fromJson(Map<String, dynamic> json) =>
      _$OrderModelFromJson(json);
  Map<String, dynamic> toJson() => _$OrderModelToJson(this);
}
```

3. **Create provider:**

```dart
@riverpod
class OrdersNotifier extends _$OrdersNotifier {
  @override
  Future<List<OrderModel>> build() async {
    final client = ref.watch(supabaseCrudClientProvider);
    return await client.query<OrderModel>(
      table: 'orders',
      fromJson: OrderModel.fromJson,
    );
  }
}
```

4. **Run build_runner** and build your UI.

---

## ⚙ Customization Guide

### Colors & Branding

Edit `lib/src/ui/tokens/app_colors.dart`:

```dart
static const Color primary = Color(0xFF521A75);
static const Color secondary = Color(0xFF7F5599);
```

### Typography

Edit `lib/src/ui/tokens/app_typography.dart`:

```dart
static const String fontFamily = "Rubik";
```

> Do not set `color` on typography tokens — styles are theme-aware.

---

## 📦 Optional Modules

### In-App Purchases (RevenueCat)

**To remove:**
1. Delete `lib/src/core/errors/purchase_failure.dart`
2. Remove the export from `lib/core_architecture.dart`
3. Remove `purchases_flutter` from `pubspec.yaml`

---

## 📋 Changelog

### v1.3.1
- **Validators:** All methods now require consumer-provided error messages — package holds zero strings
- **Removed:** `turkishPhone`, `turkishLiraFormat` and `tcNumber` validators
- **Widgets:** `CustomDropdown` and `CustomMultiSelectDropdown` string parameters are now required
- **DateHelper:** `getGreeting()` and `getRelativeDate()` now require consumer-provided labels
- **Supabase:** `formatAuthError()` removed — auth exceptions are rethrown raw
- **Supabase:** Manual auth token storage removed — SDK manages session

### v1.3.0
- **CoreInitializer:** Now automatically initializes backends based on `CoreConfig` flags
- **BaseEntity:** Added `id`, `==`/`hashCode`, abstract `copyWith()`, `toString()`
- **StorageConstants:** Centralized storage key constants — no more magic strings
- **AppTypography:** Removed hardcoded light-mode colors — styles are now theme-aware
- **Gap:** All properties converted to `const`
- **CrudContract.rpc():** Return type changed from `void` to `Future<dynamic>`
- **SupabaseCrudClient.count():** Now uses server-side counting
- **SupabaseCrudClient.upsert():** `onConflict` parameter now correctly passed
- **LoggerService:** `wtf()` renamed to `fatal()`
- **ThemeProvider:** Notifier class renamed from `Theme` to `ThemeNotifier`
- **DateHelper:** String constants `t` prefix removed (e.g. `tToday` → `today`)
- **analysis_options.yaml:** Added with explicit linting rules
- **Internal imports:** All 17 internal files now use relative imports
- **Supabase barrel:** `onboarding_provider.dart` no longer imports `supabase.dart`

### v1.2.0
- Initial public release

---

## 🔧 Troubleshooting

### Build Runner Errors

```bash
flutter clean
flutter pub get
flutter pub run build_runner clean
flutter pub run build_runner build --delete-conflicting-outputs
```

### Import Resolution

* **Core only:** `import 'package:core_architecture/core_architecture.dart';`
* **With Supabase:** `import 'package:core_architecture/supabase.dart';`
* **With Dio:** `import 'package:core_architecture/dio.dart';`

### Backend Not Initialized

If you see `SupabaseService must be initialized first`, ensure `CoreInitializer.initialize()` is called in `main()` with the correct flags. Do not call backend services manually.

---

## 📋 Quick Reference

| Need | Use |
| --- | --- |
| Platform Check | `PlatformInfo.isWeb` |
| Breakpoint | `context.windowSizeClass` |
| Responsive Val | `context.responsive<double>(compact: 16, medium: 24)` |
| Padding | `SpacingUtils.all(AppSpacings.wMd)` |
| Gap | `Gap.hMd` / `Gap.wSm` |
| Color | `context.colorScheme.primary` |
| Text Style | `AppTypography.bodyLg` |
| Validation | `Validators.email(value, errorMessage: ...)` |
| Button | `CustomButton(...)` |
| Input | `CustomTextField(...)` |
| Dropdown | `CustomDropdown(hintText: ..., searchHint: ..., noResultsText: ...)` |
| Navigate | `context.go('/path')` |
| Snackbar | `context.showSuccess('Message')` |
| Log | `ref.read(loggerServiceProvider).d('Msg', tag: 'Tag')` |
| Fatal Log | `ref.read(loggerServiceProvider).fatal('Msg', error: e)` |
| CRUD | `ref.watch(supabaseCrudClientProvider)` or `dioCrudClientProvider` |
| Storage Key | `StorageConstants.accessToken` |
| Theme | `ref.read(themeProvider.notifier).toggleTheme()` |
| Storage | `ref.read(storageServiceProvider)` |
