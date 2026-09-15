# core_architecture_dio

Dio REST backend for [`core_architecture`](../core_architecture): `DioService` (a configured Dio
instance with logging, auth-token and error interceptors), `DioCrudClient` (a `CrudContract`
implementation), Riverpod providers and a standalone initializer.

Depends on and **re-exports** `core_architecture` plus `dio` (`Dio`, `Response`, `DioException`,
`Interceptor`, …), so one import covers everything.

---

## Install

Do not list `core_architecture` separately — this package brings it in.

```yaml
dependencies:
  core_architecture_dio:
    git:
      url: https://github.com/Himera19/core_architecture.git
      path: packages/core_architecture_dio
      ref: v3.2.0
```

```dart
import 'package:core_architecture_dio/core_architecture_dio.dart';
```

## Environment

```yaml
# your_app/pubspec.yaml
flutter:
  assets:
    - .env
```

```bash
API_BASE_URL=https://api.example.com
```

The `baseUrl` passed to the initializer wins; otherwise `API_BASE_URL` is read from `.env`. With
neither, initialization throws `NetworkException`.

## Setup

`DioCoreExtension.initialize()` is standalone — it ensures the Flutter binding and loads `.env`
itself, so it can be the only call in `main()`. Both steps are idempotent, so it also composes with
`CoreInitializer`:

```dart
void main() async {
  await CoreInitializer.initialize(const CoreConfig(appName: 'MyApp'));   // optional
  await DioCoreExtension.initialize(baseUrl: 'https://api.example.com');

  runApp(const ProviderScope(child: MyApp()));
}
```

| Parameter | Default | Purpose |
| --- | --- | --- |
| `baseUrl` | `API_BASE_URL` from `.env` | Base URL for every request |
| `envFile` | `'.env'` | Only loaded if dotenv is not already initialized |

`DioService.initialize()` is still there if you want to skip the wrapper.

---

## CRUD

`DioCrudClient` implements `CrudContract`, so the same repository works against Supabase by
swapping the injected client.

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

`table` is the REST resource path, so `table: 'todos'` maps to `GET /todos`, `POST /todos`,
`PUT /todos/{id}`, `DELETE /todos/{id}`, plus `/todos/batch`, `/todos/upsert` and
`/rpc/{function}`.

### Which type you catch

`DioService` converts `DioException`s into `core_architecture` failures, so `DioCrudClient` throws
a `Failure`:

| Cause | Failure |
| --- | --- |
| Connect / send / receive timeout | `TimeoutFailure` |
| 401 | `UnauthorizedFailure` |
| Other 4xx / 5xx | `ServerFailure` |
| Connection error, cancellation | `NetworkFailure` |
| Anything else | `UnknownFailure` |

The raw client gives you `DioException` directly. This package shadows no `dio` or `dart:async`
type name, so both clauses below mean what you expect — core's own timeout type is
`RequestTimeoutException`:

```dart
try {
  await DioService.instance.client.get<void>('/health');
} on DioException catch (e) {
  debugPrint('${e.response?.statusCode}');
} on TimeoutException catch (e) {     // dart:async's type
  debugPrint(e.message);
}
```

---

## Providers

| Provider | Returns |
| --- | --- |
| `dioServiceProvider` | `DioService` (keepAlive) |
| `dioCrudClientProvider` | `DioCrudClient` (keepAlive) |

Both assume initialization already happened — reading one before
`DioCoreExtension.initialize()` completes throws.

## Direct client access

```dart
final dio = ref.read(dioServiceProvider).client;   // Dio

final response = await dio.post('/auth/login', data: {
  'email': email,
  'password': password,
});

dio.interceptors.add(MyInterceptor());   // your own interceptors go on the same instance
```
