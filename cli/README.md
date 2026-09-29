# core_architecture CLI

Scaffolds a new Flutter app on `core_architecture`. It asks what the app needs, then creates the
project, adds the packages pinned to a matching tag, writes the code and runs code generation.
It finishes with `flutter analyze`, so the app you get back is already clean.

## Install

```bash
dart pub global activate --source git https://github.com/Himera19/core_architecture.git --git-path cli
```

Make sure `~/.pub-cache/bin` is on your `PATH`. To update, run the same command again. Add
`--git-ref vX.Y.Z` to pin a release.

## Use

```bash
core_architecture create my_app
```

| Question | What it changes |
| --- | --- |
| Organization, platforms | `flutter create --org … --platforms …` |
| Backend: none / Supabase / REST (Dio) / both | Which package is added, the `main()` initializers, `.env` and `.env.example` |
| Supabase URL and key, REST base URL | `.env`. Leave them empty to fill in later |
| Which backend is primary (with both) | The backend that auth and the example feature talk to |
| Auth screens | Sign-in, sign-up and forgot-password screens, plus an `AuthController` that hides the backend |
| Account-deletion function (Supabase) | `deleteUserRpcName`, and the function in `supabase/schema.sql` |
| REST endpoints and token fields | `lib/app/dio_config.dart`, listing only what differs from the defaults |
| Onboarding | A three-page `PageView` on `onboardingStateProvider` |
| go_router | Redirects for splash → onboarding → sign-in → home. Without it, an `AppGate` widget does the same |
| Localization and languages | `flutter gen-l10n`, `.arb` files, `context.l10n`. English and Turkish come translated |
| Example CRUD feature | `features/<table>/{domain,data,presentation}` on `CrudContract`, with list, add and swipe-to-delete. On Supabase it also gets a table with row-level security |
| Brand colour, Google Font | `AppTheme.light/dark(brandColor:, fontFamily:)` in `lib/app/theme.dart` |
| First-launch theme mode | An `initialThemeModeProvider` override |

It also adds network permissions for Android and macOS release builds, keeps `.env` out of git, and
writes two tests: one checks that the themes build, the other walks the first-launch flow.

### Without questions

Every answer can come from a YAML file. The generated app keeps its own answers in
`core_architecture.yaml` (secrets stay in `.env`), so you can recreate the same app:

```bash
core_architecture create shop --config core_architecture.yaml --yes
```

```yaml
backend: dio
auth: true
router: false
feature: task
dio_auth:
  login_path: /v1/sessions
  register_path: null          # no sign-up screen
  identifier_field: username   # a username field instead of email
  access_token_field: data.token
```

A key the CLI doesn't know is an error, so a typo can't quietly fall back to a default.
`tool/e2e/*.yaml` has more examples.

| Option | |
| --- | --- |
| `-o, --output` | Parent directory (default `.`) |
| `-c, --config` | Answers file. Without `--yes` its values become the defaults for each question |
| `-y, --yes` | Don't ask anything |
| `--ref` | The `core_architecture` tag or commit to depend on |

## Develop

```bash
dart test              # every combination renders, the config round-trips
bash tool/e2e.sh       # scaffolds four apps for real; each must analyze clean and pass its tests
```

This package is not part of the Flutter workspace. `mason_logger` needs a newer `win32` than
`flutter_secure_storage` allows, and a CLI's dependencies have no place in an app's lockfile anyway.
