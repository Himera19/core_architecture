import 'package:yaml_edit/yaml_edit.dart';

import '../spec.dart';
import 'app_templates.dart';
import 'auth_templates.dart';
import 'context.dart';
import 'screen_templates.dart';

extension on String {
  String get withNewline => '$this\n';
}

/// Every file the scaffolder writes, keyed by path relative to the project
/// root. Pure — it touches no disk — so every combination of answers can be
/// checked without running Flutter.
Map<String, String> renderProject(ProjectSpec spec) {
  final c = TemplateContext(spec);
  final gated = spec.onboarding || spec.hasAuth;

  return {
    'lib/main.dart': mainDart(c),
    'lib/app/app.dart': appDart(c),
    'lib/app/theme.dart': themeDart(c),
    'lib/app/show_error.dart': showErrorDart(c),
    if (spec.backend.hasDio) 'lib/app/dio_config.dart': dioConfigDart(c),
    if (spec.router) 'lib/app/router.dart': routerDart(c),
    if (!spec.router && gated) 'lib/app/app_gate.dart': appGateDart(c),
    if (gated) 'lib/app/splash_screen.dart': splashDart(c),
    'lib/features/home/presentation/home_screen.dart': homeScreenDart(c),
    if (spec.onboarding)
      'lib/features/onboarding/presentation/onboarding_screen.dart':
          onboardingScreenDart(c),
    if (spec.hasAuth) ...{
      'lib/features/auth/application/auth_controller.dart': authControllerDart(
        c,
      ),
      'lib/features/auth/presentation/sign_in_screen.dart': signInScreenDart(c),
      if (spec.canSignUp)
        'lib/features/auth/presentation/sign_up_screen.dart': signUpScreenDart(
          c,
        ),
      if (spec.canResetPassword)
        'lib/features/auth/presentation/forgot_password_screen.dart':
            forgotPasswordScreenDart(c),
    },
    if (spec.hasFeature) ...{
      'lib/${c.featureDir}/domain/${spec.feature}.dart': entityDart(c),
      'lib/${c.featureDir}/data/${spec.feature}_repository.dart':
          repositoryDart(c),
      'lib/${c.featureDir}/presentation/${spec.table}_notifier.dart':
          listNotifierDart(c),
      'lib/${c.featureDir}/presentation/${spec.table}_screen.dart':
          listScreenDart(c),
    },
    if (spec.l10n) ...l10nFiles(c),
    if (spec.backend.hasSupabase && (spec.hasFeature || spec.hasAuth))
      'supabase/schema.sql': supabaseSchema(c),
    if (spec.backend != Backend.none) ...{
      '.env': envFile(spec, withValues: true),
      '.env.example': envFile(spec, withValues: false),
    },
    'test/widget_test.dart': widgetTest(c),
    if (gated) 'test/app_flow_test.dart': appFlowTest(c),
    'README.md': readme(c),
    'core_architecture.yaml': toYamlString(spec.toMap()),
  };
}

String toYamlString(Map<String, Object?> map) {
  final editor = YamlEditor('');
  editor.update([], map);
  return '# Answers core_architecture create was given. Re-run with\n'
      '#   core_architecture create <name> --config core_architecture.yaml\n'
      '# to scaffold the same app again. Secrets live in .env only.\n'
      '${editor.toString()}\n';
}

String envFile(ProjectSpec s, {required bool withValues}) {
  String value(String v, String placeholder) =>
      withValues && v.isNotEmpty ? v : placeholder;

  return lines([
    if (s.backend.hasSupabase) ...[
      'SUPABASE_URL=${value(s.supabaseUrl, 'https://your-project.supabase.co')}',
      'SUPABASE_PUBLISHABLE_KEY=${value(s.supabaseKey, 'your-publishable-key')}',
    ],
    if (s.backend.hasDio)
      'API_BASE_URL=${value(s.apiBaseUrl, 'https://api.example.com')}',
  ]).withNewline;
}

Map<String, String> l10nFiles(TemplateContext c) {
  final s = c.spec;
  return {
    'l10n.yaml': lines([
      'arb-dir: lib/l10n',
      'template-arb-file: app_${s.templateLocale}.arb',
      'output-localization-file: app_localizations.dart',
      'nullable-getter: false',
    ]),
    for (final locale in s.locales)
      'lib/l10n/app_$locale.arb': prettyJson({
        '@@locale': locale,
        for (final key in strings.keys) key: c.text(key, locale),
      }),
    'lib/l10n/l10n.dart': lines([
      "import 'package:flutter/widgets.dart';",
      '',
      c.pkg('l10n/app_localizations.dart'),
      '',
      "export 'package:${s.name}/l10n/app_localizations.dart';",
      '',
      'extension AppLocalizationsX on BuildContext {',
      '  AppLocalizations get l10n => AppLocalizations.of(this);',
      '}',
    ]),
  };
}

String supabaseSchema(TemplateContext c) {
  final s = c.spec;
  final table = s.table;
  final owned = s.hasAuth;

  return lines([
    '-- Run once in the Supabase SQL editor, or turn into a migration.',
    '',
    if (s.hasFeature && s.dataBackend == Backend.supabase) ...[
      'create table if not exists public.$table (',
      '  id uuid primary key default gen_random_uuid(),',
      '  name text not null,',
      owned
          ? '  created_at timestamptz not null default now(),\n'
                '  user_id uuid not null default auth.uid() references auth.users on delete cascade'
          : '  created_at timestamptz not null default now()',
      ');',
      '',
      'alter table public.$table enable row level security;',
      '',
      if (owned) ...[
        '-- Each user sees and changes their own rows only.',
        'create policy "$table: read own" on public.$table for select using (auth.uid() = user_id);',
        'create policy "$table: insert own" on public.$table for insert with check (auth.uid() = user_id);',
        'create policy "$table: delete own" on public.$table for delete using (auth.uid() = user_id);',
      ] else ...[
        '-- Open to anyone holding the publishable key. Tighten before shipping.',
        'create policy "$table: read" on public.$table for select using (true);',
        'create policy "$table: insert" on public.$table for insert with check (true);',
        'create policy "$table: delete" on public.$table for delete using (true);',
      ],
      '',
    ],
    if (s.hasAuth && s.dataBackend == Backend.supabase) ...[
      '-- Called by SupabaseService.deleteAccount(): deletes the calling user.',
      'create or replace function public.${s.deleteUserRpc}()',
      'returns void',
      'language sql',
      'security definer',
      "set search_path = ''",
      r'as $$',
      '  delete from auth.users where id = auth.uid();',
      r'$$;',
      '',
      'revoke execute on function public.${s.deleteUserRpc}() from anon, public;',
      'grant execute on function public.${s.deleteUserRpc}() to authenticated;',
    ],
  ]).withNewline;
}

/// A smoke test that runs without a backend: the theme and design system
/// build, which is what every screen stands on.
String widgetTest(TemplateContext c) => lines([
  "import 'package:flutter/material.dart';",
  "import 'package:flutter_test/flutter_test.dart';",
  '',
  c.pkg('app/theme.dart'),
  '',
  'void main() {',
  "  testWidgets('both themes build', (tester) async {",
  '    await tester.pumpWidget(',
  '      MaterialApp(',
  '        theme: appLightTheme(),',
  '        darkTheme: appDarkTheme(),',
  "        home: const Scaffold(body: Text('ok')),",
  '      ),',
  '    );',
  "    expect(find.text('ok'), findsOneWidget);",
  '  });',
  '}',
]);

/// Drives the first-launch flow through the real [App] — gate or router —
/// with storage faked and the session overridden, so no backend is needed.
String appFlowTest(TemplateContext c) {
  final s = c.spec;
  final afterOnboarding = s.hasAuth ? 'SignInScreen' : 'HomeScreen';

  return lines([
    "import 'package:flutter/material.dart';",
    "import 'package:flutter_test/flutter_test.dart';",
    ...c.coreImports,
    '',
    c.pkg('app/app.dart'),
    if (s.hasAuth) c.pkg('features/auth/application/auth_controller.dart'),
    if (s.hasAuth) c.pkg('features/auth/presentation/sign_in_screen.dart'),
    c.pkg('features/home/presentation/home_screen.dart'),
    if (s.onboarding)
      c.pkg('features/onboarding/presentation/onboarding_screen.dart'),
    '',
    'class _MemoryStorage implements StorageService {',
    '  _MemoryStorage([Map<String, String>? seed]) : values = {...?seed};',
    '',
    '  final Map<String, String> values;',
    '',
    '  @override',
    '  Future<String?> read({required String key}) async => values[key];',
    '',
    '  @override',
    '  Future<void> write({required String key, required String value}) async =>',
    '      values[key] = value;',
    '',
    '  @override',
    '  Future<void> delete({required String key}) async => values.remove(key);',
    '',
    '  @override',
    '  Future<void> clearAll() async => values.clear();',
    '',
    '  @override',
    '  Future<bool> containsKey({required String key}) async =>',
    '      values.containsKey(key);',
    '}',
    '',
    'Widget _app({bool onboardingSeen = false, bool signedIn = false}) {',
    '  return ProviderScope(',
    '    overrides: [',
    '      preferencesStorageProvider.overrideWithValue(',
    "        _MemoryStorage({if (onboardingSeen) StorageConstants.onboardingSeen: 'true'}),",
    '      ),',
    '      secureStorageProvider.overrideWithValue(_MemoryStorage()),',
    if (s.hasAuth)
      '      isSignedInProvider.overrideWithValue(AsyncValue.data(signedIn)),',
    '    ],',
    '    child: const App(),',
    '  );',
    '}',
    '',
    'void main() {',
    if (s.onboarding) ...[
      "  testWidgets('first launch shows onboarding', (tester) async {",
      '    await tester.pumpWidget(_app());',
      '    await tester.pumpAndSettle();',
      '    expect(find.byType(OnboardingScreen), findsOneWidget);',
      '  });',
      '',
      "  testWidgets('skipping onboarding moves on to $afterOnboarding', (tester) async {",
      '    await tester.pumpWidget(_app());',
      '    await tester.pumpAndSettle();',
      '    await tester.tap(find.byType(TextButton).first);',
      '    await tester.pumpAndSettle();',
      '    expect(find.byType($afterOnboarding), findsOneWidget);',
      '  });',
      '',
    ],
    if (s.hasAuth) ...[
      "  testWidgets('a signed-out user lands on sign-in', (tester) async {",
      '    await tester.pumpWidget(_app(onboardingSeen: true));',
      '    await tester.pumpAndSettle();',
      '    expect(find.byType(SignInScreen), findsOneWidget);',
      '  });',
      '',
    ],
    "  testWidgets('a returning user lands on home', (tester) async {",
    '    await tester.pumpWidget(_app(onboardingSeen: true, signedIn: true));',
    '    await tester.pumpAndSettle();',
    '    expect(find.byType(HomeScreen), findsOneWidget);',
    '  });',
    '}',
  ]);
}

String readme(TemplateContext c) {
  final s = c.spec;
  final backend = switch (s.backend) {
    Backend.none => 'none',
    Backend.supabase => 'Supabase (`core_architecture_supabase`)',
    Backend.dio => 'REST API via Dio (`core_architecture_dio`)',
    Backend.both =>
      'Supabase + REST API — ${s.primary.label} serves auth and the example feature',
  };

  return lines([
    '# ${s.displayName}',
    '',
    'Scaffolded by `core_architecture create` on '
        '[core_architecture](https://github.com/Himera19/core_architecture) `${s.ref}`.',
    '',
    '| | |',
    '| --- | --- |',
    '| Backend | $backend |',
    '| Router | ${s.router ? '`go_router`, redirects in `lib/app/router.dart`' : 'none — `lib/app/app_gate.dart` picks the first screen'} |',
    '| Auth screens | ${s.hasAuth ? 'yes — `lib/features/auth`' : 'no'} |',
    '| Onboarding | ${s.onboarding ? 'yes — `lib/features/onboarding`' : 'no'} |',
    '| Localization | ${s.l10n ? s.locales.join(', ') : 'no'} |',
    '| Theme | ${s.brandColor == null ? 'package palette' : 'brand `#${s.brandColor}`'}'
        '${s.font == null ? '' : ', ${s.font}'}, starts ${s.themeMode.name} |',
    if (s.hasFeature)
      '| Example feature | `lib/${c.featureDir}` on `${s.table}` |',
    '',
    '## Run',
    '',
    '```bash',
    if (s.backend != Backend.none)
      '# fill in .env first (template: .env.example)',
    'flutter run',
    '```',
    '',
    if (s.backend.hasSupabase && (s.hasFeature || s.hasAuth)) ...[
      '## Supabase',
      '',
      'Run `supabase/schema.sql` once in the SQL editor: it creates the tables and row-level',
      'security the generated code expects.',
      '',
    ],
    if (s.backend.hasDio) ...[
      '## REST API',
      '',
      'Endpoints and token fields are in `lib/app/dio_config.dart`. With the defaults the API',
      'is expected to answer `POST /auth/login` with `{"access_token", "refresh_token"}`,',
      'and `${s.table}` as `GET/POST /${s.table}`, `DELETE /${s.table}/{id}`.',
      '',
    ],
    '## After changing providers',
    '',
    '```bash',
    'dart run build_runner build -d',
    '```',
    if (s.l10n) ...[
      '',
      '## Strings',
      '',
      'Edit `lib/l10n/app_*.arb`; `flutter gen-l10n` (or any build) regenerates the code.',
      if (s.locales.any((l) => l != 'en' && l != 'tr'))
        'Languages other than English and Turkish start with the English text.',
    ],
  ]).withNewline;
}
