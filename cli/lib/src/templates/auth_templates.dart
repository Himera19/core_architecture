import '../spec.dart';
import 'context.dart';

String showErrorDart(TemplateContext c) => lines([
  "import 'package:flutter/material.dart';",
  ...c.coreImports,
  '',
  ...c.l10nImports,
  '',
  '/// A [Failure] carries a message meant for people; anything else does not.',
  'String errorMessage(BuildContext context, Object error) =>',
  '    error is Failure ? error.message : ${c.t('somethingWentWrong')};',
  '',
  'void showError(BuildContext context, Object error) {',
  '  ScaffoldMessenger.of(context)',
  '    ..hideCurrentSnackBar()',
  '    ..showSnackBar(SnackBar(content: Text(errorMessage(context, error))));',
  '}',
  '',
  'void showMessage(BuildContext context, String message) {',
  '  ScaffoldMessenger.of(context)',
  '    ..hideCurrentSnackBar()',
  '    ..showSnackBar(SnackBar(content: Text(message)));',
  '}',
]);

/// The one place the app names its auth backend. Screens talk to
/// [AuthController] and `isSignedInProvider` only.
String authControllerDart(TemplateContext c) {
  final supabase = c.spec.dataBackend == Backend.supabase;
  final notifier = supabase
      ? 'supabaseAuthProvider.notifier'
      : 'dioAuthProvider.notifier';

  return lines([
    "import 'package:riverpod_annotation/riverpod_annotation.dart';",
    ...c.coreImports,
    '',
    "part 'auth_controller.g.dart';",
    '',
    '/// Whether someone is signed in. Loading until the stored session is read.',
    '@Riverpod(keepAlive: true)',
    'AsyncValue<bool> isSignedIn(Ref ref) =>',
    supabase
        ? '    AsyncValue.data(ref.watch(supabaseAuthProvider) != null);'
        : '    ref.watch(dioAuthProvider);',
    '',
    '@Riverpod(keepAlive: true)',
    'AuthController authController(Ref ref) => AuthController(ref);',
    '',
    '/// Every auth action the screens need. Each throws a [Failure] with a',
    '/// message fit to show when the backend rejects it.',
    'class AuthController {',
    '  AuthController(this._ref);',
    '',
    '  final Ref _ref;',
    '',
    '  Future<void> signIn({required String identifier, required String password}) async {',
    supabase
        ? '    await _ref.read($notifier).signIn(email: identifier, password: password);'
        : '    await _ref.read($notifier).signIn(identifier: identifier, password: password);',
    '  }',
    if (c.spec.canSignUp) ...[
      '',
      '  /// Whether the new account is signed in straight away. `false` when',
      '  /// the backend wants the email confirmed first.',
      '  Future<bool> signUp({required String identifier, required String password}) async {',
      if (supabase) ...[
        '    final supabase = _ref.read(supabaseServiceProvider);',
        '    await supabase.signUp(email: identifier, password: password);',
        '    return supabase.isAuthenticated;',
      ] else ...[
        '    await _ref.read($notifier).signUp(identifier: identifier, password: password);',
        '    return _ref.read(dioServiceProvider).hasSession();',
      ],
      '  }',
    ],
    if (c.spec.canResetPassword) ...[
      '',
      '  Future<void> sendPasswordReset(String identifier) =>',
      supabase
          ? '      _ref.read($notifier).resetPassword(identifier);'
          : '      _ref.read($notifier).requestPasswordReset(identifier);',
    ],
    '',
    '  Future<void> signOut() => _ref.read($notifier).signOut();',
    '}',
  ]);
}

String _identifierField(TemplateContext c, {bool last = false}) {
  final email = c.usesEmail;
  return lines([
    'CustomTextField(',
    '  controller: _identifier,',
    '  label: ${c.t(email ? 'email' : 'username')},',
    if (email) '  keyboardType: TextInputType.emailAddress,',
    '  textInputAction: ${last ? 'TextInputAction.done' : 'TextInputAction.next'},',
    if (last) '  onSubmitted: (_) => _submit(),',
    email
        ? "  validator: (value) => Validators.email(value?.trim(), errorMessage: ${c.t('invalidEmail')}),"
        : "  validator: (value) => Validators.required(value?.trim(), errorMessage: ${c.t('usernameRequired')}),",
    '),',
  ]);
}

String _passwordField(TemplateContext c) => lines([
  'CustomTextField(',
  '  controller: _password,',
  "  label: ${c.t('password')},",
  '  obscureText: true,',
  '  showPasswordToggle: true,',
  '  textInputAction: TextInputAction.done,',
  '  onSubmitted: (_) => _submit(),',
  "  validator: (value) => Validators.password(value, errorMessage: ${c.t('invalidPassword')}),",
  '),',
]);

/// The shared scaffold of every auth form: centred, width-capped, scrollable.
String _formScaffold(List<String> children, {bool appBar = false}) => lines([
  '    return Scaffold(',
  if (appBar) '      appBar: AppBar(),',
  '      body: SafeArea(',
  '        child: Center(',
  '          child: SingleChildScrollView(',
  '            padding: const EdgeInsets.all(AppSpacings.wLg),',
  '            child: ConstrainedBox(',
  '              constraints: const BoxConstraints(maxWidth: 420),',
  '              child: Form(',
  '                key: _formKey,',
  '                child: Column(',
  '                  crossAxisAlignment: CrossAxisAlignment.stretch,',
  '                  children: [',
  ...children,
  '                  ],',
  '                ),',
  '              ),',
  '            ),',
  '          ),',
  '        ),',
  '      ),',
  '    );',
]);

/// The state-class boilerplate: controllers, a loading flag and a guarded
/// submit that shows the failure.
String _formState({
  required String screen,
  required bool password,
  required List<String> action,
  required String build,
}) => lines([
  'class _${screen}State extends ConsumerState<$screen> {',
  '  final _formKey = GlobalKey<FormState>();',
  '  final _identifier = TextEditingController();',
  if (password) '  final _password = TextEditingController();',
  '  bool _loading = false;',
  '',
  '  @override',
  '  void dispose() {',
  '    _identifier.dispose();',
  if (password) '    _password.dispose();',
  '    super.dispose();',
  '  }',
  '',
  '  Future<void> _submit() async {',
  '    if (!_formKey.currentState!.validate()) return;',
  '    setState(() => _loading = true);',
  '    try {',
  ...action,
  '    } catch (error) {',
  '      if (mounted) showError(context, error);',
  '    } finally {',
  '      if (mounted) setState(() => _loading = false);',
  '    }',
  '  }',
  '',
  '  @override',
  '  Widget build(BuildContext context) {',
  build,
  '  }',
  '}',
]);

List<String> _authImports(TemplateContext c, List<String> screens) => [
  "import 'package:flutter/material.dart';",
  ...c.routerImports,
  ...c.coreImports,
  '',
  c.pkg('app/show_error.dart'),
  c.pkg('features/auth/application/auth_controller.dart'),
  for (final s in screens) c.pkg('features/auth/presentation/$s.dart'),
  ...c.l10nImports,
];

String _screenHeader(String screen, String path) => lines([
  'class $screen extends ConsumerStatefulWidget {',
  '  const $screen({super.key});',
  '',
  "  static const String path = '$path';",
  '',
  '  @override',
  '  ConsumerState<$screen> createState() => _${screen}State();',
  '}',
]);

String signInScreenDart(TemplateContext c) {
  final s = c.spec;
  return lines([
    ..._authImports(c, [
      if (s.canSignUp) 'sign_up_screen',
      if (s.canResetPassword) 'forgot_password_screen',
    ]),
    '',
    _screenHeader('SignInScreen', '/sign-in'),
    '',
    _formState(
      screen: 'SignInScreen',
      password: true,
      action: [
        '      await ref.read(authControllerProvider).signIn(',
        '        identifier: _identifier.text.trim(),',
        '        password: _password.text,',
        '      );',
      ],
      build: _formScaffold([
        "Text(${c.t('signIn')}, style: context.textTheme.headlineMedium),",
        'Gap.hLg,',
        _identifierField(c),
        'Gap.hMd,',
        _passwordField(c),
        if (s.canResetPassword) ...[
          'Align(',
          '  alignment: Alignment.centerRight,',
          '  child: TextButton(',
          '    onPressed: () => ${c.push('ForgotPasswordScreen')},',
          "    child: Text(${c.t('forgotPassword')}),",
          '  ),',
          '),',
        ],
        'Gap.hMd,',
        'CustomButton(',
        "  text: ${c.t('signIn')},",
        '  isLoading: _loading,',
        '  onPressed: _loading ? null : _submit,',
        '),',
        if (s.canSignUp) ...[
          'Gap.hSm,',
          'TextButton(',
          '  onPressed: () => ${c.push('SignUpScreen')},',
          "  child: Text(${c.t('noAccount')}),",
          '),',
        ],
      ]),
    ),
  ]);
}

String signUpScreenDart(TemplateContext c) {
  return lines([
    ..._authImports(c, ['sign_in_screen']),
    '',
    _screenHeader('SignUpScreen', '/sign-up'),
    '',
    _formState(
      screen: 'SignUpScreen',
      password: true,
      action: [
        '      final signedIn = await ref.read(authControllerProvider).signUp(',
        '        identifier: _identifier.text.trim(),',
        '        password: _password.text,',
        '      );',
        '      if (!mounted) return;',
        '      if (signedIn) {',
        c.spec.router
            ? '        // The router redirect takes over from here.'
            : '        Navigator.of(context).popUntil((route) => route.isFirst);',
        '      } else {',
        "        showMessage(context, ${c.t('confirmEmail')});",
        '        ${c.back('SignInScreen')};',
        '      }',
      ],
      build: _formScaffold(appBar: true, [
        "Text(${c.t('signUp')}, style: context.textTheme.headlineMedium),",
        'Gap.hLg,',
        _identifierField(c),
        'Gap.hMd,',
        _passwordField(c),
        'Gap.hLg,',
        'CustomButton(',
        "  text: ${c.t('signUp')},",
        '  isLoading: _loading,',
        '  onPressed: _loading ? null : _submit,',
        '),',
        'Gap.hSm,',
        'TextButton(',
        '  onPressed: () => ${c.back('SignInScreen')},',
        "  child: Text(${c.t('haveAccount')}),",
        '),',
      ]),
    ),
  ]);
}

String forgotPasswordScreenDart(TemplateContext c) {
  return lines([
    ..._authImports(c, ['sign_in_screen']),
    '',
    _screenHeader('ForgotPasswordScreen', '/forgot-password'),
    '',
    _formState(
      screen: 'ForgotPasswordScreen',
      password: false,
      action: [
        '      await ref',
        '          .read(authControllerProvider)',
        '          .sendPasswordReset(_identifier.text.trim());',
        '      if (!mounted) return;',
        "      showMessage(context, ${c.t('resetLinkSent')});",
        '      ${c.back('SignInScreen')};',
      ],
      build: _formScaffold(appBar: true, [
        "Text(${c.t('forgotPassword')}, style: context.textTheme.headlineMedium),",
        'Gap.hLg,',
        _identifierField(c, last: true),
        'Gap.hLg,',
        'CustomButton(',
        "  text: ${c.t('sendResetLink')},",
        '  isLoading: _loading,',
        '  onPressed: _loading ? null : _submit,',
        '),',
        'Gap.hSm,',
        'TextButton(',
        '  onPressed: () => ${c.back('SignInScreen')},',
        "  child: Text(${c.t('signIn')}),",
        '),',
      ]),
    ),
  ]);
}
