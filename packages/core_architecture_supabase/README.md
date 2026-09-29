# core_architecture_supabase

Supabase for apps on [`core_architecture`](../core_architecture). It covers email auth with
Riverpod state, CRUD through `CrudContract`, and file storage, all behind one initializer that
reads your `.env`.

| | |
| --- | --- |
| 🔐 **Auth** | Sign in, sign up, sign out, password reset, OTP, profile metadata, account deletion. `supabaseAuthProvider` holds the current `User?` and updates on every auth event |
| 🗄️ **CRUD** | `SupabaseCrudClient` implements `CrudContract`, so repositories stay backend-agnostic |
| 📁 **Storage** | Upload, download and delete files, plus public and expiring signed URLs |
| 🧯 **Errors** | Failures come back as `AuthFailure` / `DatabaseFailure` / `StorageFailure` with Supabase's message |

It depends on and **re-exports** both `core_architecture` and `supabase_flutter` (`User`,
`AuthState`, `PostgrestException`, …), so one import is enough.

> Starting a new app? `core_architecture create` with the Supabase backend generates the auth
> screens, the redirects, a CRUD feature and the SQL for its table. See [the CLI](../../cli).

---

## Install

```yaml
dependencies:
  core_architecture_supabase:        # brings in core_architecture, so don't list it too
    git:
      url: https://github.com/Himera19/core_architecture.git
      path: packages/core_architecture_supabase
      ref: v6.3.0
```

```dart
import 'package:core_architecture_supabase/core_architecture_supabase.dart';
```

## Setup

```yaml
# pubspec.yaml
flutter:
  assets:
    - .env
```

```bash
# .env: keep it out of git
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_PUBLISHABLE_KEY=your-publishable-key   # SUPABASE_ANON_KEY is still read as a fallback
```

```dart
void main() async {
  await CoreInitializer.initialize(const CoreConfig(appName: 'MyApp'));   // optional
  await SupabaseCoreExtension.initialize();

  runApp(const ProviderScope(child: MyApp()));
}
```

`SupabaseCoreExtension.initialize()` also works on its own. It sets up the Flutter binding and
loads `.env` itself, and it's safe to call after `CoreInitializer`.

| Parameter | Default | |
| --- | --- | --- |
| `deleteUserRpcName` | `'delete_user'` | The Postgres function `deleteAccount()` calls |
| `envFile` | `'.env'` | Loaded only if nothing loaded dotenv yet |

---

## Auth

```dart
final user = ref.watch(supabaseAuthProvider);          // User?, null when signed out
final auth = ref.read(supabaseAuthProvider.notifier);

await auth.signIn(email: email, password: password);
await auth.signUp(email: email, password: password, firstName: 'Ada', lastName: 'Lovelace');
await auth.signOut();
await auth.resetPassword(email);                       // sends Supabase's reset email
await auth.verifyOtp(email: email, token: '123456', newPassword: newPassword);
await auth.updateMetadata({'avatar_url': url});
await auth.deleteAccount();                            // irreversible, see below
```

The SDK keeps the session, so never write auth tokens to storage yourself. `supabaseAuthProvider`
follows `authStateStreamProvider`, which means a token refresh, a sign-out in another tab or an
expired session all show up without any code on your side. A router redirect only needs to watch
it:

```dart
redirect: (context, state) =>
    ref.read(supabaseAuthProvider) == null ? '/sign-in' : null,
```

Sign-up with email confirmation turned on creates the user but no session.
`SupabaseService.instance.isAuthenticated` tells the two cases apart.

### Deleting accounts

`deleteAccount()` calls a Postgres function you create once, which runs with elevated rights:

```sql
create or replace function public.delete_user()
returns void
language sql
security definer
set search_path = ''
as $$
  delete from auth.users where id = auth.uid();
$$;

revoke execute on function public.delete_user() from anon, public;
grant execute on function public.delete_user() to authenticated;
```

### What gets thrown

| Call | Throws |
| --- | --- |
| `signIn`, `signUp`, `signOut`, `verifyOtp`, `deleteAccount` | `AuthFailure` with Supabase's message |
| `resetPassword`, `updateMetadata` | the SDK's `AuthException` |
| `SupabaseCrudClient` | `DatabaseFailure` with the Postgrest message and code |
| Storage methods | `StorageFailure` |
| The raw `client` | the SDK's own `AuthException`, `PostgrestException`, `StorageException` |

`core_architecture` never reuses the SDK's type names, so an unprefixed `on AuthException` always
means the SDK's type. `test/exception_naming_test.dart` guards this.

```dart
try {
  await auth.signIn(email: email, password: password);
} on Failure catch (f) {
  context.showError(f.message);   // "Invalid login credentials"
}
```

---

## CRUD

```dart
final client = ref.watch(supabaseCrudClientProvider);   // CrudContract

final todos = await client.query<Todo>(
  table: 'todos',
  fromJson: Todo.fromJson,
  filter: {'done': false},
  orderBy: 'created_at',
  ascending: false,
  limit: 20,
);

final todo = await client.insert<Todo>(table: 'todos', data: {'title': 'Ship'}, fromJson: Todo.fromJson);
await client.delete(table: 'todos', id: todo.id);
```

The operations are `query`, `getById`, `insert`, `update`, `delete`, `upsert`, `batchInsert`,
`batchUpdate`, `batchDelete`, `batchUpsert`, `exists`, `count` and `rpc`. Type your repository
against `CrudContract` rather than `SupabaseCrudClient`, and it will also run on
[`core_architecture_dio`](../core_architecture_dio).

Row-level security does the per-user filtering. A column like
`user_id uuid default auth.uid()`, plus a policy of `auth.uid() = user_id`, means the app never
passes a user id.

---

## File storage

```dart
final supabase = ref.read(supabaseServiceProvider);

final url = await supabase.uploadFile(bucket: 'avatars', path: '$uid/me.png', bytes: bytes,
                                      contentType: 'image/png');   // returns the public URL
final bytes = await supabase.downloadFile(bucket: 'avatars', path: '$uid/me.png');
await supabase.deleteFile(bucket: 'avatars', path: '$uid/me.png');

supabase.getPublicUrl(bucket: 'avatars', path: '$uid/me.png');
await supabase.getSignedUrl(bucket: 'invoices', path: 'march.pdf',
                            expiresIn: const Duration(minutes: 10));   // private buckets
```

---

## Providers

| Provider | Returns |
| --- | --- |
| `supabaseAuthProvider` | `User?`, plus the auth actions on `.notifier` (keepAlive) |
| `authStateStreamProvider` | `Stream<AuthState>`: every sign-in, sign-out and refresh |
| `supabaseCrudClientProvider` | `SupabaseCrudClient` (keepAlive) |
| `supabaseServiceProvider` | `SupabaseService`: auth, storage and the raw client (keepAlive) |

Each one expects `SupabaseCoreExtension.initialize()` to have finished before it's first read.

For anything the wrappers don't cover, the SDK is one getter away:

```dart
final client = ref.read(supabaseServiceProvider).client;   // SupabaseClient
await client.from('todos').select().textSearch('title', 'urgent');
```
