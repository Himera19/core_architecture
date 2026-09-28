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
      ref: v6.1.0
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
| `baseUrl` | `config.baseUrl`, then `API_BASE_URL` from `.env` | Base URL for every request |
| `config` | `const DioConfig()` | Timeouts, extra headers and the auth endpoints — see below |
| `envFile` | `'.env'` | Only loaded if dotenv is not already initialized |

### `DioConfig`

| Field | Default |
| --- | --- |
| `connectTimeout` / `receiveTimeout` / `sendTimeout` | 30 s each |
| `headers` | none — added on top of the JSON `Content-Type` and `Accept` |
| `auth` | `const DioAuthConfig()` |

`DioAuthConfig` describes your API's token endpoints. Response fields are dotted paths, so nested
tokens need no custom code:

| Field | Default | Used by |
| --- | --- | --- |
| `loginPath` | `/auth/login` | `signIn` |
| `registerPath` | `/auth/register` (null: no sign-up) | `signUp` |
| `refreshPath` | `/auth/refresh` (null: a 401 ends the session) | the 401 handler |
| `logoutPath` | null (no server call) | `signOut` |
| `passwordResetPath` | null | `requestPasswordReset` |
| `identifierField` / `passwordField` | `email` / `password` | login, register, reset bodies |
| `accessTokenField` / `refreshTokenField` | `access_token` / `refresh_token` | reading responses |
| `refreshRequestField` | `refresh_token` | refresh body |
| `tokenType` | `Bearer` | `Authorization` header |

```dart
await DioCoreExtension.initialize(
  config: const DioConfig(
    receiveTimeout: Duration(seconds: 60),
    auth: DioAuthConfig(
      loginPath: '/v1/sessions',
      identifierField: 'username',
      accessTokenField: 'data.token',     // {"data": {"token": "…"}}
      refreshTokenField: 'data.refresh',
    ),
  ),
);
```

`DioService.initialize()` is still there if you want to skip the wrapper.

---

## Auth

`dioAuthProvider` is the Dio counterpart of `supabaseAuthProvider`: `AsyncValue<bool>`, `true`
while an access token is stored.

```dart
final signedIn = ref.watch(dioAuthProvider).value ?? false;

await ref.read(dioAuthProvider.notifier).signIn(identifier: email, password: password);
await ref.read(dioAuthProvider.notifier).signUp(identifier: email, password: password, data: {'name': name});
await ref.read(dioAuthProvider.notifier).signOut();
```

Rejected credentials throw `UnauthorizedFailure` carrying the API's `message`. Tokens obtained some
other way (an OAuth redirect) go in with `DioService.instance.saveTokens(...)`.

A 401 on a request that carried a token triggers one refresh against `refreshPath`, then one retry.
Requests that fail while a refresh is running wait for that same refresh — refresh tokens that
rotate are never spent twice. The refresh itself runs on a separate `Dio` with no auth
interceptor, so it cannot recurse. When the refresh fails, or the retry gets another 401, the tokens
are dropped and `dioAuthProvider` turns `false` on its own — watch it in your router's redirect.

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
| 5xx | `ServerFailure` |
| Other 4xx | `NetworkFailure` |
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
| `dioAuthProvider` | `AsyncValue<bool>` — signed in or not (keepAlive) |

Both assume initialization already happened — reading one before
`DioCoreExtension.initialize()` completes throws.

## Direct client access

```dart
final dio = ref.read(dioServiceProvider).client;   // Dio

final response = await dio.get('/reports/export', queryParameters: {'format': 'csv'});

dio.interceptors.add(MyInterceptor());   // your own interceptors go on the same instance
```
