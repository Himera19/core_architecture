# core_architecture_supabase

Supabase backend for [`core_architecture`](../core_architecture): `SupabaseService`,
`SupabaseCrudClient` (a `CrudContract` implementation), Riverpod auth providers and a standalone
initializer.

Depends on and **re-exports** `core_architecture` plus all of `supabase_flutter` (`User`,
`AuthState`, `AuthException`, `PostgrestException`, `StorageException`, …), so one import covers
everything.

---

## Install

Do not list `core_architecture` separately — this package brings it in.

```yaml
dependencies:
  core_architecture_supabase:
    git:
      url: https://github.com/Himera19/core_architecture.git
      path: packages/core_architecture_supabase
      ref: v3.2.0
```

```dart
import 'package:core_architecture_supabase/core_architecture_supabase.dart';
```

## Environment

```yaml
# your_app/pubspec.yaml
flutter:
  assets:
    - .env
```

| Variable | Required | Notes |
| --- | --- | --- |
| `SUPABASE_URL` | yes | Project URL from the Supabase dashboard |
| `SUPABASE_PUBLISHABLE_KEY` | yes | Passed to `Supabase.initialize(publishableKey: …)` |
| `SUPABASE_ANON_KEY` | — | Legacy name, used as a fallback so existing `.env` files keep working |

## Setup

`SupabaseCoreExtension.initialize()` is standalone — it ensures the Flutter binding and loads
`.env` itself, so it can be the only call in `main()`. Both steps are idempotent, so it also
composes with `CoreInitializer`:

```dart
void main() async {
  await CoreInitializer.initialize(const CoreConfig(appName: 'MyApp'));   // optional
  await SupabaseCoreExtension.initialize();

  runApp(const ProviderScope(child: MyApp()));
}
```

| Parameter | Default | Purpose |
| --- | --- | --- |
| `deleteUserRpcName` | `'delete_user'` | Postgres RPC invoked by `deleteAccount()` |
| `envFile` | `'.env'` | Only loaded if dotenv is not already initialized |

`SupabaseService.initialize()` is still there if you want to skip the wrapper.

---

## Auth

Session persistence is handled by the Supabase SDK — never write auth tokens to storage manually.

```dart
final auth = ref.read(supabaseAuthProvider.notifier);

await auth.signIn(email: 'user@email.com', password: '123456');
await auth.signUp(
  email: 'user@email.com',
  password: '123456',
  firstName: 'Ada',
  lastName: 'Lovelace',
);
await auth.signOut();
await auth.resetPassword('user@email.com');
await auth.updateMetadata({'avatar_url': 'https://…'});
await auth.verifyOtp(email: '…', token: '123456', newPassword: '…');
await auth.deleteAccount();   // calls the configured RPC — irreversible
```

```dart
final user   = ref.watch(supabaseAuthProvider);      // User?
final events = ref.watch(authStateStreamProvider);   // AsyncValue<AuthState>
```

Auth errors are rethrown raw — the consumer owns the display message:

```dart
try {
  await auth.signIn(email: email, password: password);
} catch (e, st) {
  state = AsyncError(_mapAuthError(e), st);
}
```

### Which type you catch

| Path | Throws |
| --- | --- |
| `SupabaseService` methods | `AuthFailure`, `DatabaseFailure`, `StorageFailure` |
| `SupabaseCrudClient` | `DatabaseFailure`, carrying the Postgrest message and code |
| The raw `client` | The SDK's own `AuthException`, `PostgrestException`, `StorageException` |

`core_architecture` deliberately avoids the SDK's type names (its own are
`AuthenticationException` / `LocalStorageException`), so an unprefixed `on AuthException` always
means what the SDK throws. `test/exception_naming_test.dart` pins this down.

```dart
try {
  await SupabaseService.instance.signInWithPassword(email: e, password: p);
} on AuthFailure catch (f) {
  showError(f.message);
}
```

### `delete_user` RPC

`deleteAccount()` calls a Postgres function you define, running with elevated privileges:

```sql
create or replace function public.delete_user()
returns void
language plpgsql
security definer
as $$
begin
  delete from auth.users where id = auth.uid();
end;
$$;
```

---

## CRUD

`SupabaseCrudClient` implements `CrudContract`, so repositories stay backend-agnostic.

```dart
@riverpod
class TodosNotifier extends _$TodosNotifier {
  @override
  Future<List<Todo>> build() async {
    final client = ref.watch(supabaseCrudClientProvider);

    return client.query<Todo>(
      table: 'todos',
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

---

## Providers

| Provider | Returns |
| --- | --- |
| `supabaseServiceProvider` | `SupabaseService` (keepAlive) |
| `supabaseCrudClientProvider` | `SupabaseCrudClient` (keepAlive) |
| `supabaseAuthProvider` | `User?` + the auth actions above (keepAlive) |
| `authStateStreamProvider` | `Stream<AuthState>` |

All of them assume initialization already happened — reading one before
`SupabaseCoreExtension.initialize()` completes throws.

## Direct client access

```dart
final client = ref.read(supabaseServiceProvider).client;   // SupabaseClient
await client.from('todos').select().textSearch('title', 'urgent');
```

`SupabaseService` also wraps storage: `uploadFile`, `downloadFile`, `deleteFile`,
`uploadToSupabase`, `getPublicUrl`, `getSignedUrl`.
