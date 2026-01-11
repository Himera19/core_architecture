# 🚀 Core Architecture Package - Hızlı Başlangıç Rehberi

## 📌 Paket Nedir?

Riverpod 3 tabanlı, Dio ve Supabase desteği ile gelen hazır Flutter altyapı paketi.

**İçerik:** Tema, widgets, validators, CRUD clients, logging, responsive design.

---

## ⚡ Hızlı Kurulum

### 1️⃣ Paketi Ekle
```yaml
# pubspec.yaml
dependencies:
  core_architecture:
    path: packages/core_architecture
```

### 2️⃣ Build Runner
```bash
cd packages/core_architecture
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
cd ../..
flutter pub get
```

### 3️⃣ Environment Ayarları
```yaml
# pubspec.yaml
assets:
  - .env
```

```env
# .env
SUPABASE_URL=your_url
SUPABASE_ANON_KEY=your_key
# veya
API_BASE_URL=https://api.example.com
```

### 4️⃣ Main.dart
```dart
void main() async {
  await CoreInitializer.initialize(
    CoreConfig(
      appName: 'MyApp',
      useSupabase: true, // veya useDio: true
    ),
  );

  await SupabaseService.initialize(); // veya DioService

  runApp(ProviderScope(child: MyApp()));
}
```

## Örnek main.dart
```dart

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await CoreInitializer.initialize(
    CoreConfig(appName: CoreConstants.appName, useSupabase: true),
  );
  await SupabaseService.initialize();
  runApp(ProviderScope(child: const MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.read(themeProvider);
    final routerConfig = ref.read(routeConfigProvider);
    return ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      builder: (context, child) {
        return MaterialApp.router(
          routerConfig: routerConfig,
          title: CoreConstants.appName,
          darkTheme: darkTheme,
          theme: lightTheme,
          themeMode: themeMode,
        );
      },
    );
  }
}

```

## Örnek routes/route_config.dart
```dart
import 'package:core_architecture/core_architecture.dart';
import 'package:flutter/material.dart';

import '../../features/welcome/pages/splash_page.dart';

/// Global router provider
final routeConfigProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: RouteNames.splash,
    debugLogDiagnostics: true,
    routes: [
      // Splash
      GoRoute(
        path: RouteNames.splash,
        pageBuilder: (context, state) =>
            _buildPageWithTransition(context, state, const SplashPage()),
      ),
    ],
  );
});

/// Helper function to build pages with custom transitions
Page<dynamic> _buildPageWithTransition(
    BuildContext context,
    GoRouterState state,
    Widget child,
    ) {
  return CustomTransitionPage<dynamic>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      // Fade transition
      const begin = 0.0;
      const end = 1.0;
      const curve = Curves.easeInOut;

      var fadeTween = Tween(
        begin: begin,
        end: end,
      ).chain(CurveTween(curve: curve));

      // Slide transition
      const offset = Offset(0.05, 0.0);
      var slideTween = Tween(
        begin: offset,
        end: Offset.zero,
      ).chain(CurveTween(curve: curve));

      return SlideTransition(
        position: animation.drive(slideTween),
        child: FadeTransition(
          opacity: animation.drive(fadeTween),
          child: child,
        ),
      );
    },
    transitionDuration: AppDurations.normal,
    reverseTransitionDuration: AppDurations.normal,
  );
}
```

---

## 📁 Proje Yapısı

```
lib/
├── core/              # Routing, constants, utils
└── features/          # Her özellik için klasör
    └── auth/
        ├── models/
        ├── providers/
        ├── pages/
        ├── widgets/
        └── constants/
```

---

## 🤖 Otomatik OnBoarding Yönetimi

### OnBoarding Provider
**İşaretleme:** OnBoarding görüntüleme tamamlandıktan sonra bu kodu çalıştır:

```dart
ref.read(onboardingStateProvider.notifier).markAsSeen();
```

**Kontrol Etme:** OnBoarding kontrolü için bu kodu çalıştır:

```
await ref.read(onboardingStateProvider.future);
```


## 🎨 Widget Kullanımı

### Button
```dart
CustomButton(
text: 'Gönder',
onPressed: () {},
type: ButtonType.primary,
icon: Icons.send,
)
```

### TextField
```dart
CustomTextField(
label: 'E-posta',
validator: Validators.email,
prefixIcon: Icons.email,
)
```

### Dropdown
```dart
CustomDropdown<String>(
label: 'Şehir',
items: ['İstanbul', 'Ankara'],
itemLabel: (city) => city,
onChanged: (value) {},
)
```

---

## 🔧 Utilities

### Spacing
```dart
// Padding
SpacingUtils.all(AppSpacings.wMd)
SpacingUtils.horizontal(AppSpacings.wLg)

// Gap (boşluk)
// hMd: Column içi, wMd: Row içi
Column(
children: [
Widget1(),
Gap.hMd,
Widget2(),
],
)
```

### Context Extensions
```dart
context.colorScheme.primary
context.textTheme.titleLarge
context.showSuccess('Başarılı')
context.showError('Hata')
```

### Validators
```dart
Validators.email(value)
Validators.password(value, minLength: 6)
Validators.required(value)
Validators.turkishPhone(value)
```

---

## 💾 Backend Kullanımı

### Supabase
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
    );
  }
}
```

### Dio (REST API)
```dart
import 'package:core_architecture/dio.dart';

@riverpod
class Products extends _$Products {
  @override
  Future<List<Product>> build() async {
    final client = ref.watch(dioCrudClientProvider);
    return await client.query<Product>(
      table: 'products',
      fromJson: (json) => Product.fromJson(json),
    );
  }
}
```

---

## 🔐 Authentication (Supabase)

```dart
final user = ref.read(currentUserProvider.notifier);

// Giriş
await user.signIn(email: 'user@email.com', password: '123456');

// Kayıt
await user.signUp(email: 'user@email.com', password: '123456');

// Çıkış
await user.signOut();
```

---

## 🌐 REST API Detaylı Kullanım (Dio)

### Tam Örnek: Products Feature

```dart
// 1. Model (lib/features/products/models/product_model.dart)
@JsonSerializable()
class Product {
  final String id;
  final String name;
  final double price;
  final String? imageUrl;

  Product({
    required this.id,
    required this.name,
    required this.price,
    this.imageUrl,
  });

  factory Product.fromJson(Map<String, dynamic> json) => _$ProductFromJson(json);
  Map<String, dynamic> toJson() => _$ProductToJson(this);
}

// 2. Provider (lib/features/products/providers/products_provider.dart)
@riverpod
class Products extends _$Products {
  @override
  Future<List<Product>> build() async {
    final client = ref.watch(dioCrudClientProvider);
    final logger = ref.read(loggerServiceProvider);

    try {
      logger.d('Fetching products', tag: 'Products');

      return await client.query<Product>(
        table: 'products', // API endpoint: GET /products
        fromJson: (json) => Product.fromJson(json),
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

  // Ürün ekleme
  Future<void> addProduct(Product product) async {
    final client = ref.read(dioCrudClientProvider);
    final logger = ref.read(loggerServiceProvider);

    try {
      await client.insert<Product>(
        table: 'products', // POST /products
        data: product.toJson(),
        fromJson: (json) => Product.fromJson(json),
      );

      ref.invalidateSelf(); // Listeyi yenile
      logger.i('Product added successfully', tag: 'Products');
    } catch (e) {
      logger.e('Failed to add product', error: e, tag: 'Products');
      rethrow;
    }
  }

  // Ürün güncelleme
  Future<void> updateProduct(String id, Product product) async {
    final client = ref.read(dioCrudClientProvider);

    await client.update<Product>(
      table: 'products', // PUT /products/:id
      id: id,
      data: product.toJson(),
      fromJson: (json) => Product.fromJson(json),
    );

    ref.invalidateSelf();
  }

  // Ürün silme
  Future<void> deleteProduct(String id) async {
    final client = ref.read(dioCrudClientProvider);

    await client.delete(
      table: 'products', // DELETE /products/:id
      id: id,
    );

    ref.invalidateSelf();
  }
}

// 3. UI (lib/features/products/pages/products_page.dart)
class ProductsPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsProvider);

    return Scaffold(
      appBar: CustomAppBar(title: 'Ürünler'),
      body: productsAsync.when(
        data: (products) => ListView.builder(
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            return ListTile(
              title: Text(product.name),
              subtitle: Text('${product.price} TL'),
              trailing: IconButton(
                icon: Icon(Icons.delete),
                onPressed: () {
                  ref.read(productsProvider.notifier).deleteProduct(product.id);
                },
              ),
            );
          },
        ),
        loading: () => Center(child: SpinKitIndicator.primaryColored(context)),
        error: (error, stack) => Center(child: Text('Hata: $error')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Ürün ekleme sayfasına git
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
```

**REST API Endpoint Beklentileri:**
- `GET /products` → Ürün listesi döner
- `GET /products/:id` → Tek ürün döner
- `POST /products` → Yeni ürün oluşturur
- `PUT /products/:id` → Ürün günceller
- `DELETE /products/:id` → Ürün siler

---

## 📦 Zorunlu Paket Entegrasyonları

### 1. Environment Variables (.env) ⚠️ ZORUNLU
**Neden Gerekli:** API key'ler, URL'ler gibi hassas bilgileri güvenli saklamak ve koddan ayırmak için  
**Ne Yapar:** Farklı ortamlar (dev, prod) için farklı değerler kullanmanızı sağlar

```bash
flutter pub add flutter_dotenv
```

```env
# .env
supabase ise;
SUPABASE_URL=your_url
SUPABASE_ANON_KEY=your_key

dio ise;
API_BASE_URL=https://api.example.com
SECRET_KEY=your_secret
```

```dart
// Kullanım
import 'package:flutter_dotenv/flutter_dotenv.dart';
final apiKey = dotenv.env['API_KEY'];
```

⚠️ **Önemli:** `.env` dosyasını `.gitignore`'a ekleyin!

### 2. JSON Serialization ⚠️ ZORUNLU
**Neden Gerekli:** API'den gelen JSON verilerini Dart nesnelerine (model) dönüştürmek için  
**Ne Yapar:** Otomatik `fromJson` ve `toJson` metodları oluşturur, hata riskini azaltır

```bash
flutter pub add json_annotation
flutter pub add dev:json_serializable dev:build_runner
```

```dart
@JsonSerializable()
class User {
  final String id;
  final String email;

  User({required this.id, required this.email});

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);
}

// Her model değişikliğinde çalıştır
flutter pub run build_runner build --delete-conflicting-outputs
```

### 3. Riverpod Code Generation ⚠️ ZORUNLU
**Neden Gerekli:** Type-safe provider'lar oluşturmak, hata riskini azaltmak için  
**Ne Yapar:** Provider'ları otomatik generate eder, compile-time hatalarını yakalar

```bash
flutter pub add riverpod_annotation
flutter pub add dev:riverpod_generator dev:build_runner
```

```dart
@riverpod
class Counter extends _$Counter {
  @override
  int build() => 0;

  void increment() => state++;
}

// Her provider değişikliğinde çalıştır
flutter pub run build_runner build --delete-conflicting-outputs
```

---

## 🎁 Önerilen Ek Paketler (Opsiyonel)

### 1. Launcher Icon
**Neden Kullanmalı:** Uygulama ikonunu tüm platformlara (iOS, Android, Web) otomatik uyarlamak için  
**Faydası:** Manuel icon export ve yerleştirme işlemlerinden kurtarır, zaman kazandırır

```bash
dart pub add flutter_launcher_icons
dart run flutter_launcher_icons:generate
# assets/icon/icon.png ekle (1024x1024 PNG önerilir)
dart run flutter_launcher_icons
```

### 2. Package Name Değiştirme
**Neden Kullanmalı:** Uygulama paket adını (com.company.app) tek komutla değiştirmek için  
**Faydası:** Android, iOS, web ve diğer platformlardaki onlarca dosyayı otomatik günceller

```bash
dart pub add change_app_package_name
dart run change_app_package_name:main com.company.app
```

---

## 🎯 Routing (GoRouter)

```dart
final router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => HomeScreen(),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => ProfileScreen(),
    ),
  ],
);

// Navigate
context.go('/profile');
context.pop();
```

---

## 📊 Logging

```dart
// Provider içinde
@riverpod
class MyFeature extends _$MyFeature {
  @override
  Future<void> build() async {
    final logger = ref.read(loggerServiceProvider);
    logger.d('Debug message', tag: 'MyFeature');
    logger.i('Info message', tag: 'MyFeature');
  }

  Future<void> someAction() async {
    try {
      final logger = ref.read(loggerServiceProvider);
      logger.d('Action started', tag: 'MyFeature');
      // ... işlemler
    } catch (e, st) {
      final logger = ref.read(loggerServiceProvider);
      logger.e('Action failed', error: e, stackTrace: st, tag: 'MyFeature');
    }
  }
}

// Widget içinde
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logger = ref.read(loggerServiceProvider);
    logger.d('Widget built', tag: 'MyWidget');
    return Container();
  }
}
```

---

## 💎 Best Practices

### ❌ Yapma
```dart
Container(padding: EdgeInsets.all(16))
Text('Merhaba', style: TextStyle(fontSize: 18))
if (email.contains('@')) // validation
```

### ✅ Yap
```dart
Container(padding: SpacingUtils.all(AppSpacings.wMd))
Text(AppConstants.welcome, style: AppTypography.bodyLg)
validator: Validators.email
```

---

## 📝 Constants Yapısı

```dart
// lib/features/auth/constants/auth_constants.dart
class AuthConstants {
  static const String loginTitle = 'Giriş Yap';
  static const IconData emailIcon = Icons.email;
  static const int minPasswordLength = 6;
}
```

---

## 🗂️ Model Örneği

```dart
@JsonSerializable()
class TodoModel {
  final String id;
  final String title;
  final bool isCompleted;

  TodoModel({
    required this.id,
    required this.title,
    this.isCompleted = false,
  });

  factory TodoModel.fromJson(Map<String, dynamic> json) =>
      _$TodoModelFromJson(json);
  Map<String, dynamic> toJson() => _$TodoModelToJson(this);
}
```

---

## 🔄 CRUD Operations

```dart
final client = ref.watch(supabaseCrudClientProvider);

// Query
await client.query<Todo>(
table: 'todos',
fromJson: Todo.fromJson,
filter: {'user_id': userId},
orderBy: 'created_at',
limit: 20,
);

// Get by ID
await client.getById<Todo>(
table: 'todos',
id: '123',
fromJson: Todo.fromJson,
);

// Insert
await client.insert<Todo>(
table: 'todos',
data: todo.toJson(),
fromJson: Todo.fromJson,
);

// Update
await client.update<Todo>(
table: 'todos',
id: '123',
data: {'title': 'New Title'},
fromJson: Todo.fromJson,
);

// Delete
await client.delete(table: 'todos', id: '123');
```

---

## 🎨 Design Tokens

```dart
// Colors
AppColors.primary
AppColors.secondary
AppColors.error

// Spacings
AppSpacings.wMd   // width
AppSpacings.hLg   // height
AppSpacings.rSm   // radius

// Sizes
AppSizes.iconMd
AppSizes.buttonMd
AppSizes.inputHeight

// Typography
AppTypography.bodyLg
AppTypography.titleMd

// Radius
AppRadius.sm
AppRadius.md
AppRadius.lg
```

---

## 🆘 Sık Karşılaşılan Durumlar

### Build Runner Hatası
```bash
flutter clean
flutter pub get
flutter pub run build_runner clean
flutter pub run build_runner build --delete-conflicting-outputs
```

### Supabase veya Dio Seçimi
- **Sadece Supabase:** Dio klasörünü silebilirsiniz
- **Sadece REST API:** Supabase klasörünü silebilirsiniz
- **Her ikisi:** Paketi olduğu gibi kullanın

### Theme Değişikliği
```dart
packages/core_architecture/lib/src/ui/tokens/
```
Bu klasördeki dosyaları düzenleyin.

---

## 📌 Önemli Notlar

- ✅ Hard code kullanma, her zaman constants kullan
- ✅ Type belirteçlerini ekle
- ✅ Sayfa yapılarında fonksiyonlar üstte, widgetbuild ortada ve extracted içerikler altta yer almalı
- ✅ Paket utility'lerini kullan (SpacingUtils, Gap, Validators)
- ✅ Her feature için ayrı klasör oluştur
- ✅ Model değişikliklerinde build runner çalıştır
- ✅ .env dosyasını .gitignore'a ekle
- ✅ Logging kullan (özellikle production'da error tracking için)

---

## 🚦 Yeni Feature Ekleme Adımları

1. **Klasör oluştur:** `lib/features/yeni_feature/`
2. **Alt klasörler:** `models/`, `providers/`, `pages/`, `widgets/`, `constants/`
3. **Model yaz:** `@JsonSerializable()` ile
4. **Build:** `flutter pub run build_runner build --delete-conflicting-outputs`
5. **Provider yaz:** `@riverpod` ile
6. **Build:** Tekrar çalıştır
7. **UI oluştur:** Paket widget'larını kullan
8. **Test et**

---

## 📚 Daha Fazla Bilgi

Detaylı kullanım için paket içindeki dosyaları inceleyin:
- `lib/src/ui/widgets/` - Widget örnekleri
- `lib/src/utils/` - Utility fonksiyonları
- `lib/src/backends/` - Backend implementasyonları

---

**Versiyon:** 1.1.3 
**Durum:** Aktif geliştirme aşamasında  
**Son Güncelleme:** 11/01/2026

---

## 💡 Hızlı Referans

| İhtiyaç | Kullan |
|---------|--------|
| Padding | `SpacingUtils.all(AppSpacings.wMd)` |
| Boşluk | `Gap.md` |
| Renk | `context.colorScheme.primary` |
| Text Style | `AppTypography.bodyLg` |
| Validation | `Validators.email` |
| Button | `CustomButton(...)` |
| Input | `CustomTextField(...)` |
| Dropdown | `CustomDropdown(...)` |
| Navigate | `context.go('/path')` |
| Snackbar | `context.showSuccess('Mesaj')` |
| Log | `ref.read(loggerServiceProvider).d('Msg', tag: 'Tag')` |
| CRUD Client | `ref.watch(supabaseCrudClientProvider)` veya `dioCrudClientProvider` |

---

