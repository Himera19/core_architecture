# core_architecture_dio

A REST API client for apps on [`core_architecture`](../core_architecture). It covers token auth
that refreshes itself, CRUD through `CrudContract`, and error mapping to the core's `Failure`
types, all configured in one place so it fits the API you already have.

| | |
| --- | --- |
| 🔐 **Auth** | Sign in, sign up, sign out, password reset. `dioAuthProvider` tells you whether someone is signed in and turns `false` by itself when a session can't be recovered |
| 🔄 **Token refresh** | A 401 triggers one refresh and one retry. Parallel requests share that refresh, so rotating refresh tokens are never spent twice |
| ⚙️ **Configurable** | Endpoints, field names, token paths such as `data.token`, the header scheme, timeouts and extra headers |
| 🗄️ **CRUD** | `DioCrudClient` implements `CrudContract` over REST conventions, so repositories also run on Supabase |
| 🧯 **Errors** | Timeouts, 401, 4xx, 5xx and offline all become `Failure`s, with your API's `message` |
| 🪵 **Logging** | Every request and response is logged in debug builds. Release builds keep only warnings and errors |

It depends on and **re-exports** both `core_architecture` and `dio` (`Dio`, `Response`,
`DioException`, `Interceptor`, …), so one import is enough.

> Starting a new app? `core_architecture create` with the REST backend asks for your endpoints,
> writes the `DioConfig` and generates the auth screens. See [the CLI](../../cli).

---

## Install

```yaml
dependencies:
  core_architecture_dio:             # brings in core_architecture, so don't list it too
    git:
      url: https://github.com/Himera19/core_architecture.git
      path: packages/core_architecture_dio
      ref: v6.2.0
```

```dart
import 'package:core_architecture_dio/core_architecture_dio.dart';
```

## Setup

```yaml
# pubspec.yaml
flutter:
  assets:
    - .env
```

```bash
# .env
API_BASE_URL=https://api.example.com
```

```dart
void main() async {
  await CoreInitializer.initialize(const CoreConfig(appName: 'MyApp'));   // optional
  await DioCoreExtension.initialize();                                     // or (config: dioConfig)

  runApp(const ProviderScope(child: MyApp()));
}
```

The base URL is `baseUrl:` if you pass it, then `config.baseUrl`, then `API_BASE_URL` from `.env`.
With none of them set, initialization throws a `NetworkException` that says so. The initializer
also works on its own: it sets up the Flutter binding and loads `.env` itself.

---

## Configuration

Out of the box it expects the most common shape:

```text
POST /auth/login     {"email", "password"}   →  {"access_token", "refresh_token"}
POST /auth/register  {"email", "password"}   →  same, or no tokens if email must be confirmed
POST /auth/refresh   {"refresh_token"}       →  {"access_token", "refresh_token"?}
Authorization: Bearer <access_token>
```

When your API differs, override only what changes:

```dart
const dioConfig = DioConfig(
  receiveTimeout: Duration(seconds: 60),
  headers: {'X-Client': 'mobile'},
  auth: DioAuthConfig(
    loginPath: '/v1/sessions',
    registerPath: null,                  // no self sign-up
    passwordResetPath: '/v1/password/forgot',
    identifierField: 'username',         // log in with a username
    accessTokenField: 'data.token',      // {"data": {"token": "…"}}
    refreshTokenField: 'data.refresh',
    tokenType: 'Token',                  // Authorization: Token <…>
  ),
);

await DioCoreExtension.initialize(config: dioConfig);
```

| `DioConfig` | Default |
| --- | --- |
| `baseUrl` | `API_BASE_URL` from `.env` |
| `connectTimeout` / `receiveTimeout` / `sendTimeout` | 30 s each |
| `headers` | none (added to the JSON `Content-Type` and `Accept`) |
| `auth` | `const DioAuthConfig()` |

| `DioAuthConfig` | Default | Used by |
| --- | --- | --- |
| `loginPath` | `/auth/login` | `signIn` |
| `registerPath` | `/auth/register`; `null` means no sign-up | `signUp` |
| `refreshPath` | `/auth/refresh`; `null` means a 401 ends the session | the 401 handler |
| `logoutPath` | `null`, so no server call | `signOut` |
| `passwordResetPath` | `null` | `requestPasswordReset` |
| `identifierField` / `passwordField` | `email` / `password` | login, register and reset bodies |
| `accessTokenField` / `refreshTokenField` | `access_token` / `refresh_token`, as dotted paths | reading responses |
| `refreshRequestField` | `refresh_token` | the refresh body |
| `tokenType` | `Bearer` | the `Authorization` header |

---

## Auth

```dart
final signedIn = ref.watch(dioAuthProvider).value ?? false;   // AsyncValue<bool>
final auth = ref.read(dioAuthProvider.notifier);

await auth.signIn(identifier: email, password: password);     // stores both tokens
await auth.signUp(identifier: email, password: password, data: {'name': name});
await auth.requestPasswordReset(email);
await auth.signOut();                                         // tokens dropped even if the server call fails
```

`signIn` and `signUp` return the whole response body, so you can read a user object out of it.
Tokens obtained some other way, such as an OAuth redirect, go in with
`DioService.instance.saveTokens(accessToken: …, refreshToken: …)`.

**How a session behaves:**

1. Every request carries the stored access token.
2. A 401 on a request that sent a token triggers one refresh against `refreshPath`, then one retry
   with the new token.
3. Requests that fail during a refresh wait for that same refresh instead of starting their own.
4. The refresh runs on a separate `Dio` that has no 401 handler, so it can't loop.
5. If the refresh fails, or the retry gets another 401, the tokens are dropped and `dioAuthProvider`
   turns `false`. A router redirect watching it sends the user to sign-in, and your code doesn't
   have to do anything.

Rejected credentials throw `UnauthorizedFailure` carrying your API's `message`.

---

## CRUD

```dart
final client = ref.watch(dioCrudClientProvider);   // CrudContract

final todos = await client.query<Todo>(
  table: 'todos',
  fromJson: Todo.fromJson,
  filter: {'done': false},
  orderBy: 'created_at',
  ascending: false,
  limit: 20,
);
```

`table` is the resource path, and each operation maps to a REST call:

| Operation | Request |
| --- | --- |
| `query` | `GET /todos?done=false&order_by=created_at&ascending=false&limit=20&offset=…` |
| `getById` / `exists` | `GET /todos/{id}` |
| `insert` | `POST /todos` |
| `update` | `PUT /todos/{id}` |
| `delete` | `DELETE /todos/{id}` |
| `batchInsert` / `batchUpdate` / `batchDelete` | `POST` / `PUT` / `DELETE /todos/batch` |
| `upsert` / `batchUpsert` | `POST /todos/upsert` / `POST /todos/upsert/batch` |
| `count` | `GET /todos/count?…filter` |
| `rpc` | `POST /rpc/{function}` |

A list response can be a bare array or `{"data": [...]}`. Type repositories against `CrudContract`
and they also run on [`core_architecture_supabase`](../core_architecture_supabase).

### What gets thrown

`DioCrudClient` and the auth methods throw `Failure`s:

| Cause | Failure |
| --- | --- |
| Connect, send or receive timeout | `TimeoutFailure` |
| 401 | `UnauthorizedFailure` |
| 5xx | `ServerFailure` |
| Other 4xx | `NetworkFailure` |
| Offline, cancelled | `NetworkFailure` |
| Anything else | `UnknownFailure` |

A JSON error body's `message` becomes the failure's message. A plain-text or HTML body, such as a
proxy's 502 page, gets a generic message instead of crashing. The raw client throws `DioException`,
with the `Failure` in its `.error`.

---

## Providers

| Provider | Returns |
| --- | --- |
| `dioAuthProvider` | `AsyncValue<bool>`, signed in or not, plus the auth actions on `.notifier` (keepAlive) |
| `dioCrudClientProvider` | `DioCrudClient` (keepAlive) |
| `dioServiceProvider` | `DioService`: HTTP verbs, session and the raw client (keepAlive) |

Each one expects `DioCoreExtension.initialize()` to have finished before it's first read.

For calls outside CRUD, the service and the raw client come with the same interceptors:

```dart
final api = ref.read(dioServiceProvider);
final report = await api.get('/reports/export', queryParameters: {'format': 'csv'});

api.client.interceptors.add(MyInterceptor());   // the underlying Dio
```
