import '../spec.dart';
import 'context.dart';

String mainDart(TemplateContext c) {
  final s = c.spec;
  final initialMode = s.themeMode == AppThemeMode.light
      ? null
      : 'initialThemeModeProvider.overrideWithValue(ThemeMode.${s.themeMode.name}),';

  return lines([
    "import 'package:flutter/material.dart';",
    if (s.l10n) "import 'package:intl/date_symbol_data_local.dart';",
    ...c.coreImports,
    '',
    c.pkg('app/app.dart'),
    if (s.backend.hasDio) c.pkg('app/dio_config.dart'),
    '',
    'Future<void> main() async {',
    "  await CoreInitializer.initialize(const CoreConfig(appName: ${dartString(s.displayName)}));",
    if (s.backend.hasSupabase)
      s.deleteUserRpc == 'delete_user'
          ? '  await SupabaseCoreExtension.initialize();'
          : '  await SupabaseCoreExtension.initialize(deleteUserRpcName: ${dartString(s.deleteUserRpc)});',
    if (s.backend.hasDio)
      '  await DioCoreExtension.initialize(config: dioConfig);',
    if (s.l10n) ...[
      '',
      '  // DateHelper reads day and month names from intl; load every locale.',
      '  await initializeDateFormatting();',
    ],
    '',
    '  runApp(',
    '    ProviderScope(',
    if (initialMode != null) '      overrides: [$initialMode],',
    '      child: const App(),',
    '    ),',
    '  );',
    '}',
  ]);
}

String dioConfigDart(TemplateContext c) {
  final a = c.spec.dioAuth;
  final d = DioAuthSpec.defaults;

  String? field(String name, String? value, String? fallback) {
    if (value == fallback) return null;
    return '    $name: ${value == null ? 'null' : dartString(value)},';
  }

  final fields = [
    field('loginPath', a.loginPath, d.loginPath),
    field('registerPath', a.registerPath, d.registerPath),
    field('refreshPath', a.refreshPath, d.refreshPath),
    field('logoutPath', a.logoutPath, d.logoutPath),
    field('passwordResetPath', a.passwordResetPath, d.passwordResetPath),
    field('identifierField', a.identifierField, d.identifierField),
    field('accessTokenField', a.accessTokenField, d.accessTokenField),
    field('refreshTokenField', a.refreshTokenField, d.refreshTokenField),
  ].whereType<String>();

  return lines([
    "import 'package:core_architecture_dio/core_architecture_dio.dart';",
    '',
    '/// How the app talks to its REST API. The base URL is `API_BASE_URL` in',
    '/// `.env`; every field left out here keeps the `DioAuthConfig` default.',
    'const DioConfig dioConfig = DioConfig(',
    if (fields.isEmpty)
      '  auth: DioAuthConfig(),'
    else ...[
      '  auth: DioAuthConfig(',
      ...fields,
      '  ),',
    ],
    ');',
  ]);
}

String themeDart(TemplateContext c) {
  final s = c.spec;
  final font = s.font == null
      ? null
      : 'GoogleFonts.getFont(${dartString(s.font!)}).fontFamily';

  String build(String mode) => lines([
    'ThemeData app${mode[0].toUpperCase()}${mode.substring(1)}Theme() => AppTheme.$mode(',
    if (s.brandColor != null) '  brandColor: brandColor,',
    if (font != null) '  fontFamily: $font,',
    ');',
  ]);

  return lines([
    "import 'package:flutter/material.dart';",
    if (font != null) "import 'package:google_fonts/google_fonts.dart';",
    ...c.coreImports,
    '',
    if (s.brandColor != null) ...[
      '/// The one colour the design system is re-branded from.',
      'const Color brandColor = Color(0xFF${s.brandColor!.toUpperCase()});',
      '',
    ],
    build('light'),
    '',
    build('dark'),
  ]);
}

String appDart(TemplateContext c) {
  final s = c.spec;
  final gated = s.onboarding || s.hasAuth;

  return lines([
    "import 'package:flutter/material.dart';",
    ...c.coreImports,
    '',
    if (s.l10n) c.pkg('l10n/app_localizations.dart'),
    if (s.router) c.pkg('app/router.dart'),
    if (!s.router && gated) c.pkg('app/app_gate.dart'),
    if (!s.router && !gated)
      c.pkg('features/home/presentation/home_screen.dart'),
    c.pkg('app/theme.dart'),
    '',
    'class App extends ConsumerWidget {',
    '  const App({super.key});',
    '',
    '  @override',
    '  Widget build(BuildContext context, WidgetRef ref) {',
    if (s.router) ...[
      '    return MaterialApp.router(',
      '      routerConfig: ref.watch(routerProvider),',
    ] else ...[
      '    return MaterialApp(',
      '      home: const ${gated ? 'AppGate' : 'HomeScreen'}(),',
    ],
    '      title: ${dartString(s.displayName)},',
    '      debugShowCheckedModeBanner: false,',
    '      theme: appLightTheme(),',
    '      darkTheme: appDarkTheme(),',
    '      themeMode: ref.watch(themeProvider),',
    if (s.l10n) ...[
      '      localizationsDelegates: AppLocalizations.localizationsDelegates,',
      '      supportedLocales: AppLocalizations.supportedLocales,',
    ],
    '    );',
    '  }',
    '}',
  ]);
}

String splashDart(TemplateContext c) => lines([
  "import 'package:flutter/material.dart';",
  '',
  '/// Shown while the stored onboarding and sign-in state is read.',
  'class SplashScreen extends StatelessWidget {',
  '  const SplashScreen({super.key});',
  '',
  "  static const String path = '/splash';",
  '',
  '  @override',
  '  Widget build(BuildContext context) {',
  '    return const Scaffold(body: Center(child: CircularProgressIndicator()));',
  '  }',
  '}',
]);

/// Without a router: picks the first screen from the stored state and swaps
/// it when that state changes.
String appGateDart(TemplateContext c) {
  final s = c.spec;
  return lines([
    "import 'package:flutter/material.dart';",
    ...c.coreImports,
    '',
    c.pkg('app/splash_screen.dart'),
    if (s.hasAuth) c.pkg('features/auth/application/auth_controller.dart'),
    if (s.hasAuth) c.pkg('features/auth/presentation/sign_in_screen.dart'),
    c.pkg('features/home/presentation/home_screen.dart'),
    if (s.onboarding)
      c.pkg('features/onboarding/presentation/onboarding_screen.dart'),
    '',
    '/// The first screen, chosen from what has been stored: ${[if (s.onboarding) 'onboarding until it has been seen', if (s.hasAuth) 'sign-in until there is a session', 'then home'].join(', ')}.',
    'class AppGate extends ConsumerWidget {',
    '  const AppGate({super.key});',
    '',
    '  @override',
    '  Widget build(BuildContext context, WidgetRef ref) {',
    if (s.onboarding) ...[
      '    final onboarding = ref.watch(onboardingStateProvider);',
      '    if (onboarding.isLoading && !onboarding.hasValue) {',
      '      return const SplashScreen();',
      '    }',
      '    if (!(onboarding.value ?? true)) {',
      '      return const OnboardingScreen();',
      '    }',
      '',
    ],
    if (s.hasAuth) ...[
      '    final signedIn = ref.watch(isSignedInProvider);',
      '    if (signedIn.isLoading && !signedIn.hasValue) {',
      '      return const SplashScreen();',
      '    }',
      '    if (!(signedIn.value ?? false)) {',
      '      return const SignInScreen();',
      '    }',
      '',
    ],
    '    return const HomeScreen();',
    '  }',
    '}',
  ]);
}

String routerDart(TemplateContext c) {
  final s = c.spec;
  final gated = s.onboarding || s.hasAuth;
  final screens = <String, String>{
    'HomeScreen': 'features/home/presentation/home_screen.dart',
    if (gated) 'SplashScreen': 'app/splash_screen.dart',
    if (s.onboarding)
      'OnboardingScreen':
          'features/onboarding/presentation/onboarding_screen.dart',
    if (s.hasAuth)
      'SignInScreen': 'features/auth/presentation/sign_in_screen.dart',
    if (s.hasAuth && s.canSignUp)
      'SignUpScreen': 'features/auth/presentation/sign_up_screen.dart',
    if (s.hasAuth && s.canResetPassword)
      'ForgotPasswordScreen':
          'features/auth/presentation/forgot_password_screen.dart',
    if (s.hasFeature)
      '${c.entityPlural}Screen':
          '${c.featureDir}/presentation/${s.table}_screen.dart',
  };
  final authScreens = [
    'SignInScreen',
    if (s.canSignUp) 'SignUpScreen',
    if (s.canResetPassword) 'ForgotPasswordScreen',
  ];

  return lines([
    "import 'package:flutter/widgets.dart';",
    "import 'package:go_router/go_router.dart';",
    "import 'package:riverpod_annotation/riverpod_annotation.dart';",
    ...c.coreImports,
    '',
    if (s.hasAuth) c.pkg('features/auth/application/auth_controller.dart'),
    for (final path in screens.values) c.pkg(path),
    '',
    "part 'router.g.dart';",
    '',
    '@Riverpod(keepAlive: true)',
    'GoRouter router(Ref ref) {',
    if (gated) ...[
      '  // Re-runs the redirect whenever the state it reads changes.',
      '  final refresh = ValueNotifier<int>(0);',
      '  ref.onDispose(refresh.dispose);',
      if (s.onboarding)
        '  ref.listen(onboardingStateProvider, (_, _) => refresh.value++);',
      if (s.hasAuth)
        '  ref.listen(isSignedInProvider, (_, _) => refresh.value++);',
      '',
    ],
    '  return GoRouter(',
    '    initialLocation: HomeScreen.path,',
    if (gated) ...[
      '    refreshListenable: refresh,',
      '    redirect: (context, state) {',
      '      final location = state.matchedLocation;',
      '      String? to(String path) => location == path ? null : path;',
      '',
      if (s.onboarding) ...[
        '      final onboarding = ref.read(onboardingStateProvider);',
        '      if (onboarding.isLoading && !onboarding.hasValue) {',
        '        return to(SplashScreen.path);',
        '      }',
        '      if (!(onboarding.value ?? true)) {',
        '        return to(OnboardingScreen.path);',
        '      }',
        '',
      ],
      if (s.hasAuth) ...[
        '      final signedIn = ref.read(isSignedInProvider);',
        '      if (signedIn.isLoading && !signedIn.hasValue) {',
        '        return to(SplashScreen.path);',
        '      }',
        '      const authPaths = {${authScreens.map((w) => '$w.path').join(', ')}};',
        '      if (!(signedIn.value ?? false)) {',
        '        return authPaths.contains(location) ? null : SignInScreen.path;',
        '      }',
        '      if (authPaths.contains(location)) {',
        '        return HomeScreen.path;',
        '      }',
        '',
      ],
      '      const gatePaths = {SplashScreen.path${s.onboarding ? ', OnboardingScreen.path' : ''}};',
      '      return gatePaths.contains(location) ? HomeScreen.path : null;',
      '    },',
    ],
    '    routes: [',
    for (final widget in screens.keys)
      '      GoRoute(path: $widget.path, builder: (context, state) => const $widget()),',
    '    ],',
    '  );',
    '}',
  ]);
}
