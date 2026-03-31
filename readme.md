# Core Architecture

A production-ready, modular Flutter architecture package built on **Riverpod 3** with pluggable backend support for **Supabase** and **Dio (REST API)**.

Drop it into any Flutter project as a local package, keep what you need, delete what you don't.

---

## Table of Contents

- [Features](#-features)
- [Quick Start](#-quick-start)
- [Architecture Overview](#-architecture-overview)
- [Backend Selection](#-backend-selection)
- [Core Layer](#-core-layer)
- [UI Design System](#-ui-design-system)
- [Utilities](#-utilities)
- [Providers](#-providers)
- [CRUD Operations](#-crud-operations)
- [Authentication (Supabase)](#-authentication-supabase)
- [Logging](#-logging)
- [Adding a New Feature](#-adding-a-new-feature)
- [Customization Guide](#-customization-guide)
- [Optional Modules](#-optional-modules)
- [Troubleshooting](#-troubleshooting)
- [Quick Reference](#-quick-reference)

---

## ✨ Features

| Category | What's Included |
|----------|------------------|
| **State Management** | Riverpod 3 with code generation |
| **Backend** | Supabase & Dio (REST API) — pick one or both |
| **UI System** | Design tokens, themes, responsive utilities, reusable widgets |
| **Error Handling** | Extensible `Failure` / `AppException` hierarchy |
| **Storage** | Encrypted key-value storage with in-memory caching |
| **Logging** | Production-aware logger with HTTP request/response tracking |
| **Routing** | GoRouter integration with custom page transitions |
| **Validation** | Email, phone, password, TC ID, IBAN, credit card, and more |
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

```env
# .env (add to .gitignore!)
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key

# Or for REST API:
API_BASE_URL=https://api.example.com
```

### 4. Initialize in `main.dart`

```dart
import 'package:core_architecture/core_architecture.dart';
// Import the backend you need:
import 'package:core_architecture/supabase.dart';
// or: import 'package:core_architecture/dio.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await CoreInitializer.initialize(
    CoreConfig(appName: 'MyApp', useSupabase: true),
  );

  await SupabaseService.initialize();
  // or: await DioService.initialize();

  runApp(ProviderScope(child: const MyApp()));
}

```dart
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
    │   ├── entities/          # BaseEntity
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

The package provides **three entry points** — import only what you need:

```dart
// Core only (no backend specifics)
import 'package:core_architecture/core_architecture.dart';

// Core + Supabase
import 'package:core_architecture/supabase.dart';

// Core + Dio (REST API)
import 'package:core_architecture/dio.dart';
```

---

## 🔌 Backend Selection

This package supports a **"delete what you don't need"** approach:

### Using Supabase Only

1. Delete `lib/src/backends/dio/` directory
2. Delete `lib/dio.dart` barrel file
3. Remove `dio` from `pubspec.yaml`

### Using Dio (REST API) Only

1. Delete `lib/src/backends/supabase/` directory
2. Delete `lib/supabase.dart` barrel file
3. Remove `supabase_flutter` from `pubspec.yaml`

### Using Both

Keep everything as-is. Import from the appropriate barrel file per feature.

---

## 🧱 Core Layer

### CoreInitializer

Bootstraps the application: loads `.env`, initializes Flutter bindings, and validates backend configuration.

```dart
await CoreInitializer.initialize(
  CoreConfig(
    appName: 'MyApp',
    useSupabase: true, // or useDio: true, or both
    envFile: '.env',   // default
  ),
);
```

### Error Handling

Two parallel hierarchies — `Failure` for business logic, `AppException` for thrown exceptions:

```dart
// Abstract base — extend for project-specific failures
abstract class Failure {
  final String message;
  final String? code;
  final dynamic data;
}
```

**Built-in failure types:**

| Failure | Use Case |
|---------|----------|
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

### Storage Service

Abstract `StorageService` interface with `SecureStorageService` implementation using `flutter_secure_storage` and an in-memory cache layer:

```dart
final storage = ref.read(storageServiceProvider);

await storage.write(key: 'token', value: 'abc123');
final token = await storage.read(key: 'token');
await storage.delete(key: 'token');
await storage.clearAll();
```

---

## 🎨 UI Design System

### Design Tokens

All visual constants are centralized in `lib/src/ui/tokens/`:

```dart
// Colors
AppColors.primary          // Brand primary
AppColors.secondary        // Brand secondary
AppColors.error            // Status: error
AppColors.success          // Status: success

// Typography
AppTypography.headlineLg   // 32sp, w600
AppTypography.bodyMd       // 14sp, w400
AppTypography.labelSm      // 11sp, w500

// Spacings
AppSpacings.wMd            // 16.0 (width-based)
AppSpacings.hLg            // 24.0 (height-based)
AppSpacings.rSm            // 12.0 (radius-based)

// Sizes
AppSizes.buttonMd          // 48.0
AppSizes.iconMd            // 24.0
AppSizes.avatarLg          // 64.0

// Radius
AppRadius.sm / .md / .lg

// Durations
AppDurations.fast / .normal / .slow

// Elevations
AppElevations.sm / .md / .lg
```

### Themes

Ready-to-use `lightTheme` and `darkTheme` with Material 3:

```dart
MaterialApp(
  theme: lightTheme,
  darkTheme: darkTheme,
  themeMode: ref.watch(themeProvider),
)
```

Customize colors in `lib/src/ui/tokens/app_colors.dart` and themes in `lib/src/ui/themes/`.

### Widgets

| Widget | Description |
|--------|-------------|
| `CustomButton` | Primary/secondary/outlined with icon support |
| `CustomTextField` | Labeled input with validation and prefix/suffix icons |
| `CustomDropdown<T>` | Searchable dropdown with filtering |
| `CustomAppBar` | Consistent app bar |
| `Navbar` | Bottom navigation bar |

```dart
CustomButton(
  text: 'Submit',
  onPressed: () {},
  type: ButtonType.primary,
  icon: Icons.send,
)

CustomTextField(
  label: 'Email',
  validator: Validators.email,
  prefixIcon: Icons.email,
)

CustomDropdown<String>(
  label: 'City',
  items: ['Istanbul', 'Ankara'],
  itemLabel: (city) => city,
  onChanged: (value) {},
)
```

---

## 🛠 Utilities

### Spacing & Layout

```dart
// Padding
Container(padding: SpacingUtils.all(AppSpacings.wMd))
Container(padding: SpacingUtils.horizontal(AppSpacings.wLg))

// Gaps (for Column/Row children)
Column(children: [
  Widget1(),
  Gap.hMd,    // vertical gap
  Widget2(),
])

Row(children: [
  Widget1(),
  Gap.wSm,    // horizontal gap
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

```dart
Validators.email(value)
Validators.password(value, minLength: 8)
Validators.required(value)
Validators.turkishPhone(value)
Validators.tcKimlik(value)
Validators.iban(value)
Validators.creditCard(value)
```

### Other Utilities

| Utility | Description |
|---------|-------------|
| `PlatformInfo` | Check current platform (`isWeb`, `isMobile`, `isDesktop`) |
| `AppBreakpoints`| Material 3 Window Size Classes (`compact`, `medium`, `expanded`, `large`) |
| `ResponsiveValue`| Adaptive values based on screen size |
| `ResponsiveBuilder`| UI builder based on breakpoint |
| `DateHelper` | Date formatting and parsing |
| `CurrencyHelper` | Currency formatting |
| `InputFormatters` | TextInputFormatter implementations |
| `RadiusUtils` | BorderRadius factory methods |
| `BorderUtils` | Border factory methods |
| `SpinKitIndicator` | Loading animation widget |
| `UrlLauncher` | Open URLs in browser |

---

## 🔄 Providers

### Theme Provider

Persists theme choice to secure storage:

```dart
// Read current theme
final themeMode = ref.watch(themeProvider);

// Toggle light/dark
ref.read(themeProvider.notifier).toggleTheme();

// Set specific mode
ref.read(themeProvider.notifier).setThemeMode(ThemeMode.dark);
```

### Onboarding Provider

Track whether onboarding has been shown:

```dart
// Check status
final seen = await ref.read(onboardingStateProvider.future);

// Mark as complete
ref.read(onboardingStateProvider.notifier).markAsSeen();

// Reset (for testing)
ref.read(onboardingStateProvider.notifier).reset();
```

---

## 💾 CRUD Operations

Both backends implement `CrudContract` — a unified interface for data operations:

### Available Operations

| Method | Description |
|--------|-------------|
| `query<T>` | List with filter, sort, pagination |
| `getById<T>` | Single record by ID |
| `insert<T>` | Create new record |
| `update<T>` | Update existing record |
| `delete` | Delete record |
| `batchInsert<T>` | Bulk create |
| `batchUpdate<T>` | Bulk update |
| `batchDelete` | Bulk delete |
| `upsert<T>` | Insert or update |
| `batchUpsert<T>` | Bulk upsert |
| `exists` | Check record existence |
| `count` | Count records |
| `rpc` | Remote procedure call |

### Supabase Example

```dart
import 'package:core_architecture/supabase.dart';

@riverpod
class Todos extends _$Todos {
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

  Future<void> addTodo(Todo todo) async {
    final client = ref.read(supabaseCrudClientProvider);
    await client.insert<Todo>(
      table: 'todos',
      data: todo.toJson(),
      fromJson: Todo.fromJson,
    );
    ref.invalidateSelf();
  }
}
```

### Dio (REST API) Example

```dart
import 'package:core_architecture/dio.dart';

@riverpod
class Products extends _$Products {
  @override
  Future<List<Product>> build() async {
    final client = ref.watch(dioCrudClientProvider);
    final logger = ref.read(loggerServiceProvider);

    try {
      logger.d('Fetching products', tag: 'Products');

      return await client.query<Product>(
        table: 'products',     // maps to GET /products
        fromJson: Product.fromJson,
        filter: {'category': 'electronics'},
        orderBy: 'created_at',
        ascending: false,
        limit: 20,
      );
    } catch (e) {
      logger.e('Failed to fetch products', error: e, tag: 'Products');
      rethrow;
    }
  }
}
```

**REST API endpoint mapping:**

| CRUD Method | HTTP Endpoint |
|-------------|---------------|
| `query` | `GET /products` |
| `getById` | `GET /products/:id` |
| `insert` | `POST /products` |
| `update` | `PUT /products/:id` |
| `delete` | `DELETE /products/:id` |

---

## 🔐 Authentication (Supabase)

```dart
final auth = ref.read(supabaseAuthProvider.notifier);

// Sign in
await auth.signIn(email: 'user@email.com', password: '123456');

// Sign up
await auth.signUp(
  email: 'user@email.com',
  password: '123456',
  firstName: 'John',
  lastName: 'Doe',
);

// Sign out
await auth.signOut();

// Reset password
await auth.resetPassword('user@email.com');

// Update user metadata
await auth.updateMetadata({'avatar_url': 'https://...'});

// Delete account (irreversible!)
await auth.deleteAccount();

// Listen to auth state
ref.listen(authStateStreamProvider, (prev, next) {
  next.whenData((authState) {
    // Handle auth changes
  });
});
```

---

## 📊 Logging

`LoggerService` is a singleton with production-aware filtering. In release mode, only warnings and errors are logged.

```dart
final logger = ref.read(loggerServiceProvider);

logger.d('Debug message', tag: 'MyFeature');   // Debug
logger.i('User logged in', tag: 'Auth');        // Info
logger.w('Cache miss', tag: 'Cache');           // Warning
logger.e('API failed', error: e, stackTrace: st, tag: 'API');  // Error

// Mask sensitive data in logs
logger.maskSensitive('sk_live_abc123xyz', visibleStart: 7, visibleEnd: 3);
// Output: "sk_live*******xyz"

// HTTP logging (used internally by Dio interceptors)
logger.logRequest(method: 'GET', url: '/api/users');
logger.logResponse(statusCode: 200, url: '/api/users', data: responseData);
```

---

## 🚦 Adding a New Feature

1. **Create feature directory:**

```
lib/features/orders/
├── models/
│   └── order_model.dart
├── providers/
│   └── orders_provider.dart
├── pages/
│   └── orders_page.dart
├── widgets/
│   └── order_card.dart
└── constants/
    └── order_constants.dart
```

2. **Define model** with `@JsonSerializable()`:

```dart
@JsonSerializable()
class OrderModel {
  final String id;
  final String title;
  final double amount;

  OrderModel({required this.id, required this.title, required this.amount});

  factory OrderModel.fromJson(Map<String, dynamic> json) =>
      _$OrderModelFromJson(json);
  Map<String, dynamic> toJson() => _$OrderModelToJson(this);
}
```

3. **Run build_runner:**

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

4. **Create provider** with `@riverpod`:

```dart
@riverpod
class Orders extends _$Orders {
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

5. **Run build_runner** again and build your UI.

---

## ⚙ Customization Guide

### Colors & Branding

Edit `lib/src/ui/tokens/app_colors.dart`:

```dart
static const Color primary = Color(0xFF521A75);    // Your brand color
static const Color secondary = Color(0xFF7F5599);  // Your secondary color
```

### Typography

Edit `lib/src/ui/tokens/app_typography.dart`:

```dart
static const String fontFamily = "Rubik";  // Change to your font
```

### Spacing Scale

Edit `lib/src/ui/tokens/app_spacings.dart` to adjust the spacing scale.

### Theme

Edit `lib/src/ui/themes/light_theme.dart` and `dark_theme.dart` for advanced theme customization.

---

## 📦 Optional Modules

### In-App Purchases (RevenueCat)

`PurchaseFailure` provides user-friendly error messages for RevenueCat errors.

**To remove:**
1. Delete `lib/src/core/errors/purchase_failure.dart`
2. Remove the export from `lib/core_architecture.dart`
3. Remove `purchases_flutter` from `pubspec.yaml`

### Supabase / Dio

See [Backend Selection](#-backend-selection) above.

---

## 🔧 Required Dependencies for Consumer Projects

| Dependency | Purpose | Required? |
|------------|---------|-----------|
| `flutter_dotenv` | Environment variables | ✅ Yes |
| `json_annotation` | Model serialization | ✅ Yes |
| `json_serializable` | Code generation (dev) | ✅ Yes |
| `build_runner` | Code generation (dev) | ✅ Yes |
| `riverpod_annotation` | Provider code generation | ✅ Yes |
| `riverpod_generator` | Provider code generation (dev) | ✅ Yes |
| `flutter_launcher_icons` | App icon generation | ❌ Optional |
| `change_app_package_name` | Package name utility | ❌ Optional |

---

## 🆘 Troubleshooting

### Build Runner Errors

```bash
flutter clean
flutter pub get
flutter pub run build_runner clean
flutter pub run build_runner build --delete-conflicting-outputs
```

### Import Resolution

- **Core only:** `import 'package:core_architecture/core_architecture.dart';`
- **With Supabase:** `import 'package:core_architecture/supabase.dart';`
- **With Dio:** `import 'package:core_architecture/dio.dart';`

> Do not mix barrel imports. Use `supabase.dart` or `dio.dart` — each re-exports `core_architecture.dart` automatically.

---

## 📋 Quick Reference

| Need | Use |
|------|-----|
| Platform Check | `PlatformInfo.isWeb` |
| Breakpoint | `context.windowSizeClass` |
| Responsive Val | `context.responsive<double>(compact: 16, medium: 24)` |
| Padding | `SpacingUtils.all(AppSpacings.wMd)` |
| Gap | `Gap.hMd` / `Gap.wSm` |
| Color | `context.colorScheme.primary` |
| Text Style | `AppTypography.bodyLg` |
| Validation | `Validators.email` |
| Button | `CustomButton(...)` |
| Input | `CustomTextField(...)` |
| Dropdown | `CustomDropdown(...)` |
| Navigate | `context.go('/path')` |
| Snackbar | `context.showSuccess('Message')` |
| Log | `ref.read(loggerServiceProvider).d('Msg', tag: 'Tag')` |
| CRUD | `ref.watch(supabaseCrudClientProvider)` or `dioCrudClientProvider` |
| Theme | `ref.read(themeProvider.notifier).toggleTheme()` |
| Storage | `ref.read(storageServiceProvider)` |

---

## Routing Example

```dart
import 'package:core_architecture/core_architecture.dart';

final routeConfigProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        pageBuilder: (context, state) =>
            _buildPageWithTransition(context, state, const HomePage()),
      ),
      GoRoute(
        path: '/profile',
        pageBuilder: (context, state) =>
            _buildPageWithTransition(context, state, const ProfilePage()),
      ),
    ],
  );
});

/// Custom page transition with fade + slide
Page<dynamic> _buildPageWithTransition(
  BuildContext context,
  GoRouterState state,
  Widget child,
) {
  return CustomTransitionPage<dynamic>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return SlideTransition(
        position: Tween(begin: const Offset(0.05, 0.0), end: Offset.zero)
            .chain(CurveTween(curve: Curves.easeInOut))
            .animate(animation),
        child: FadeTransition(
          opacity: animation,
          child: child,
        ),
      );
    },
    transitionDuration: AppDurations.normal,
  );
}
```

---

## Best Practices

### ❌ Don't

```dart
Container(padding: EdgeInsets.all(16))
Text('Hello', style: TextStyle(fontSize: 18))
if (email.contains('@')) // manual validation
```

### ✅ Do

```dart
Container(padding: SpacingUtils.all(AppSpacings.wMd))
Text('Hello', style: AppTypography.bodyLg)
validator: Validators.email
```

### Constants Pattern

```dart
class AuthConstants {
  static const String loginTitle = 'Sign In';
  static const IconData emailIcon = Icons.email;
  static const int minPasswordLength = 8;
}
```

---

**Version:** 1.2.0
**Status:** Active development
**License:** MIT
