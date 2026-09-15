# core_architecture_supabase

Supabase backend for [`core_architecture`](../core_architecture).

Adds `SupabaseService`, `SupabaseCrudClient` (a `CrudContract` implementation), Riverpod auth
providers, and a standalone initializer. Depends on and **re-exports** `core_architecture`, so a
single import gives you everything.

---

## Installation

You do not need to list `core_architecture` separately.

```yaml
dependencies:
  core_architecture_supabase:
    git:
      url: https://github.com/Himera19/core_architecture.git
      path: packages/core_architecture_supabase
      ref: v2.0.0
```

```dart
import 'package:core_architecture_supabase/core_architecture_supabase.dart';
```

The barrel re-exports `core_architecture`, all of `supabase_flutter` (giving you `User`,
`AuthState`, `AuthException`, `PostgrestException`, `StorageException`, …) and this package's
own types. Nothing is hidden: `core_architecture` deliberately avoids the SDK's type names, so
`on AuthException` in your code always means what the SDK throws.

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
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_PUBLISHABLE_KEY=your-publishable-key
```

| Variable | Required | Notes |
| --- | --- | --- |
| `SUPABASE_URL` | yes | Project URL from the Supabase dashboard |
| `SUPABASE_PUBLISHABLE_KEY` | yes | Passed to `Supabase.initialize(publishableKey: …)` |
| `SUPABASE_ANON_KEY` | — | Legacy name for the same key. Used as a fallback when `SUPABASE_PUBLISHABLE_KEY` is absent, so existing `.env` files keep working. |

---

## Setup

`SupabaseCoreExtension.initialize()` is standalone: it ensures the Flutter binding and loads
`.env` itself, so it can be the only call in `main()`.

```dart
void main() async {
  await SupabaseCoreExtension.initialize();
  runApp(const ProviderScope(child: MyApp()));
}
```

Both steps are idempotent, so it composes cleanly with `CoreInitializer` when you also want the
core's startup logging:

```dart
void main() async {
  await CoreInitializer.initialize(const CoreConfig(appName: 'MyApp'));
  await SupabaseCoreExtension.initialize(
    deleteUserRpcName: 'delete_user', // optional, this is the default
  );
  runApp(const ProviderScope(child: MyApp()));
}
```

| Parameter | Default | Purpose |
| --- | --- | --- |
| `deleteUserRpcName` | `'delete_user'` | Postgres RPC invoked by `deleteAccount()` |
| `envFile` | `'.env'` | Only loaded if dotenv is not already initialized |

`SupabaseService.initialize()` remains available if you want to skip the wrapper entirely.

---

## Authentication

Session persistence is handled by the Supabase SDK — never write auth tokens to storage
manually.

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
await auth.deleteAccount(); // calls the configured RPC — irreversible
```

Read the current user, or watch raw auth events:

```dart
final user = ref.watch(supabaseAuthProvider);              // User?
final events = ref.watch(authStateStreamProvider);          // AsyncValue<AuthState>
```

Auth errors are rethrown raw — the consumer owns the display message:

```dart
try {
  await auth.signIn(email: email, password: password);
} catch (e, st) {
  state = AsyncError(_mapAuthError(e), st);
}
```

### Exception types

`SupabaseService` converts the SDK's errors into `core_architecture` failures, so the type you
catch from its methods is `AuthFailure`, `DatabaseFailure` or `StorageFailure`:

```dart
try {
  await SupabaseService.instance.signInWithPassword(email: e, password: p);
} on AuthFailure catch (f) {
  showError(f.message);
}
```

When you go through the **raw client** instead, you get the SDK's own exceptions — and this
package does not shadow their names:

```dart
try {
  await SupabaseService.instance.client.auth.signInWithPassword(
    email: email,
    password: password,
  );
} on AuthException catch (e) {        // the Supabase SDK's type
  showError(e.message);
} on PostgrestException catch (e) {
  showError(e.message);
}
```

> In v1 this did not work: the package exported core's `AuthException` under the same name, so
> the clause compiled but never matched. Core's types are now `AuthenticationException` and
> `LocalStorageException`.

A regression test pins this down — see `test/exception_naming_test.dart`.

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

`SupabaseCrudClient` implements `CrudContract`, so repositories can stay backend-agnostic.

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

Postgrest errors are converted to `DatabaseFailure`, carrying the original message and code.

---

## Providers

| Provider | Returns |
| --- | --- |
| `supabaseServiceProvider` | `SupabaseService` (keepAlive) |
| `supabaseCrudClientProvider` | `SupabaseCrudClient` (keepAlive) |
| `authStateStreamProvider` | `Stream<AuthState>` |
| `supabaseAuthProvider` | `User?` + auth actions (keepAlive) |

All of them assume initialization already happened — reading them before
`SupabaseCoreExtension.initialize()` completes throws.

---

## Direct client access

For anything the service does not wrap:

```dart
final client = ref.read(supabaseServiceProvider).client; // SupabaseClient
await client.from('todos').select().textSearch('title', 'urgent');
```

`SupabaseService` also covers storage directly: `uploadFile`, `downloadFile`, `deleteFile`,
`uploadToSupabase`, `getPublicUrl`, `getSignedUrl`.
