# core_architecture_dio

Dio REST backend for [`core_architecture`](../core_architecture).

Adds `DioService` (a configured Dio instance with logging, auth-token and error interceptors),
`DioCrudClient` (a `CrudContract` implementation), Riverpod providers, and a standalone
initializer. Depends on and **re-exports** `core_architecture`, so a single import gives you
everything.

---

## Installation

You do not need to list `core_architecture` separately.

```yaml
dependencies:
  core_architecture_dio:
    git:
      url: https://github.com/Himera19/core_architecture.git
      path: packages/core_architecture_dio
      ref: v2.0.0
```

```dart
import 'package:core_architecture_dio/core_architecture_dio.dart';
```

The barrel re-exports `core_architecture`, `dio` (giving you `Dio`, `Response`, `DioException`,
`Interceptor`, …) and this package's own types.

---

## Environment

```yaml
# your_app/pubspec.yaml
flutter:
  assets:
    - .env
```

```bash
# .env — add to .gitignore!
API_BASE_URL=https://api.example.com
```

`baseUrl` passed to the initializer wins; otherwise `API_BASE_URL` is read from `.env`. If
neither is present, initialization throws `NetworkException`.

---

## Setup

`DioCoreExtension.initialize()` is standalone: it ensures the Flutter binding and loads `.env`
itself, so it can be the only call in `main()`.

```dart
void main() async {
  await DioCoreExtension.initialize();
  runApp(const ProviderScope(child: MyApp()));
}
```

Both steps are idempotent, so it composes cleanly with `CoreInitializer` when you also want the
core's startup logging:

```dart
void main() async {
  await CoreInitializer.initialize(const CoreConfig(appName: 'MyApp'));
  await DioCoreExtension.initialize(baseUrl: 'https://api.example.com');
  runApp(const ProviderScope(child: MyApp()));
}
```

| Parameter | Default | Purpose |
| --- | --- | --- |
| `baseUrl` | `API_BASE_URL` from `.env` | Base URL for every request |
| `envFile` | `'.env'` | Only loaded if dotenv is not already initialized |

`DioService.initialize()` remains available if you want to skip the wrapper entirely.

---

## CRUD

`DioCrudClient` implements `CrudContract`, so repositories can stay backend-agnostic — the same
repository works against Supabase by swapping the injected client.

```dart
@riverpod
class TodosNotifier extends _$TodosNotifier {
  @override
  Future<List<Todo>> build() async {
    final client = ref.watch(dioCrudClientProvider);

    return client.query<Todo>(
      table: 'todos',          // maps to the /todos endpoint
      fromJson: Todo.fromJson,
      filter: {'user_id': userId},
      orderBy: 'created_at',
      ascending: false,
      limit: 20,
    );
  }
}
```

Operations: `query`, `getById`, `insert`, `update`, `delete`, `upsert`, `batchInsert`,
`batchUpdate`, `batchDelete`, `batchUpsert`, `exists`, `count`, `rpc`.

The `table` argument is used as the REST resource path, so `table: 'todos'` maps to
`GET /todos`, `POST /todos`, `PUT /todos/{id}`, `DELETE /todos/{id}`, plus `/todos/batch`,
`/todos/upsert` and `/rpc/{function}` for the batch, upsert and RPC operations.

### Exception types

`DioService` converts `DioException`s into `core_architecture` failures, so the type you catch
from `DioCrudClient` is a `Failure`:

| Cause | Failure |
| --- | --- |
| Connect / send / receive timeout | `TimeoutFailure` |
| 401 | `UnauthorizedFailure` |
| Other 4xx / 5xx | `ServerFailure` |
| Connection error, cancellation | `NetworkFailure` |
| Anything else | `UnknownFailure` |

Going through the raw client gives you `DioException` directly. This package shadows no `dio` or
`dart:async` type name, so `on DioException` and `on TimeoutException` both mean what you
expect:

```dart
try {
  await DioService.instance.client.get<void>('/health');
} on DioException catch (e) {
  debugPrint('${e.response?.statusCode}');
} on TimeoutException catch (e) {     // dart:async's type
  debugPrint(e.message);
}
```

Core's own timeout type is `RequestTimeoutException` — see
[`core_architecture`](../core_architecture#errors).

---

## Providers

| Provider | Returns |
| --- | --- |
| `dioServiceProvider` | `DioService` (keepAlive) |
| `dioCrudClientProvider` | `DioCrudClient` (keepAlive) |

Both assume initialization already happened — reading them before
`DioCoreExtension.initialize()` completes throws.

---

## Direct client access

For requests the CRUD contract does not cover:

```dart
final dio = ref.read(dioServiceProvider).client; // Dio

final response = await dio.post('/auth/login', data: {
  'email': email,
  'password': password,
});
```

Add your own interceptors on the same instance:

```dart
ref.read(dioServiceProvider).client.interceptors.add(MyInterceptor());
```
