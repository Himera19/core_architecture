# core_architecture CLI

`core_architecture create` scaffolds a new Flutter app on the `core_architecture` packages. It asks
what the app needs, writes the whole app, generates the code, and runs `flutter analyze` at the
end. The app it hands back builds, analyzes clean and passes its tests, and is ready for
`flutter run`.

```bash
dart pub global activate --source git https://github.com/Himera19/core_architecture.git --git-path cli
core_architecture create my_app
```

If the command isn't found, add `~/.pub-cache/bin` to your `PATH`. Running the same `activate`
command again updates the CLI.

---

## What it asks

| Question | Your answer changes |
| --- | --- |
| **Organization, platforms** | `flutter create --org … --platforms …` |
| **Backend**: none, Supabase, REST (Dio), or both | The package added, the `main()` initializers, `.env` and `.env.example` |
| Supabase URL and key, REST base URL | `.env`. Leave them empty to fill in later |
| Which backend is primary (with both) | The backend that auth and the example feature use |
| **Auth screens** | Sign-in, sign-up and forgot-password screens, plus an `AuthController` so screens never name the backend |
| Account-deletion function (Supabase) | `deleteUserRpcName`, and the function in `supabase/schema.sql` |
| REST endpoints and token fields | `lib/app/dio_config.dart`, listing only what differs from the defaults. A username API gets a username field instead of email |
| **Onboarding** | Three swipeable pages, shown once |
| **go_router** | Splash → onboarding → sign-in → home redirects. Without it, an `AppGate` widget does the same |
| **Languages** | `flutter gen-l10n`, one `.arb` per language, `context.l10n`. English and Turkish come translated; other languages start from the English text |
| **Example CRUD feature** | `features/<table>/` with a model, a repository on `CrudContract`, a Notifier, and a list screen with add, pull-to-refresh and swipe-to-delete. On Supabase it also gets a table with row-level security |
| **Brand colour, Google Font** | `AppTheme.light/dark(brandColor:, fontFamily:)` in `lib/app/theme.dart` |
| **First-launch theme mode** | `system`, `light` or `dark`. The home screen has a switch for all three |

It asks only what applies to your earlier answers. For example, the account-deletion function
question comes up only for Supabase with auth.

## What you get

With every option turned on, on Supabase:

```text
my_app/
├── lib/
│   ├── main.dart                  initializers, first-launch theme mode
│   ├── app/
│   │   ├── app.dart               MaterialApp, themes, localizations
│   │   ├── router.dart            redirects driven by onboarding and sign-in state
│   │   ├── theme.dart             your brand colour and font
│   │   ├── splash_screen.dart     while stored state loads
│   │   └── show_error.dart        Failure → SnackBar
│   ├── features/
│   │   ├── auth/
│   │   │   ├── application/       auth_controller.dart: the only file naming the backend
│   │   │   └── presentation/      sign_in, sign_up, forgot_password
│   │   ├── onboarding/
│   │   ├── home/
│   │   └── products/
│   │       ├── domain/            product.dart
│   │       ├── data/              product_repository.dart (CrudContract)
│   │       └── presentation/      products_notifier.dart, products_screen.dart
│   └── l10n/                      app_en.arb, app_tr.arb, l10n.dart
├── supabase/schema.sql            run once: table, RLS policies, delete_user()
├── test/
│   ├── widget_test.dart           both themes build
│   └── app_flow_test.dart         onboarding → sign-in → home, no backend needed
├── .env / .env.example            .env is git-ignored
├── core_architecture.yaml         your answers, without secrets
└── README.md                      what was chosen, and how to run it
```

After writing the files, it also:

- adds network permissions for Android and macOS release builds,
- runs `flutter gen-l10n`, `build_runner`, `dart fix` and `dart format`,
- finishes with `flutter analyze` and reports the result.

## Without questions

Every answer can come from a YAML file. Each generated app saves its own answers in
`core_architecture.yaml`, so you can scaffold the same app again, or start the next one from it:

```bash
core_architecture create shop --config core_architecture.yaml --yes
```

```yaml
backend: dio
auth: true
router: false
feature: task
theme_mode: dark
dio_auth:
  login_path: /v1/sessions
  register_path: null          # no sign-up screen
  password_reset_path: /v1/password/forgot
  identifier_field: username   # a username field instead of email
  access_token_field: data.token
```

A key the CLI doesn't know is an error, so a typo can't quietly fall back to a default. Without
`--yes`, the file's values become the default answers to each question. [`tool/e2e/`](tool/e2e)
has four complete examples.

| Option | |
| --- | --- |
| `-o, --output` | Parent directory (default `.`) |
| `-c, --config` | Answers file |
| `-y, --yes` | Don't ask anything; take the file's values and defaults |
| `--ref` | The `core_architecture` tag or commit the app depends on (default: this CLI's release) |
| `--version` | The release this CLI scaffolds on |

---

## Develop

```bash
dart test              # every combination of answers renders, every import resolves
bash tool/e2e.sh       # scaffolds four apps for real; each must analyze clean and pass its tests
```

The templates in `lib/src/templates/` are plain Dart functions from answers to file contents. They
never touch the disk, which is what lets `dart test` check all 160 combinations in under a
second.

This package sits outside the Flutter workspace. `mason_logger` needs a newer `win32` than
`flutter_secure_storage` allows, and a CLI's dependencies don't belong in an app's lockfile anyway.
