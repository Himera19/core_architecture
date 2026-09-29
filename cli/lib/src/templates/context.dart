import 'dart:convert';

import '../spec.dart';

/// Every user-facing string the generated screens show, in the languages the
/// scaffolder ships translations for. A language outside this table gets the
/// English text, to be translated in its `.arb` file.
const Map<String, Map<String, String>> strings = {
  'homeWelcome': {'en': 'Welcome', 'tr': 'Hoş geldin'},
  'homeSubtitle': {
    'en': 'Your app is set up and running.',
    'tr': 'Uygulaman kuruldu ve çalışıyor.',
  },
  'themeLabel': {'en': 'Theme', 'tr': 'Tema'},
  'themeLight': {'en': 'Light', 'tr': 'Açık'},
  'themeSystem': {'en': 'System', 'tr': 'Sistem'},
  'themeDark': {'en': 'Dark', 'tr': 'Koyu'},
  'signIn': {'en': 'Sign in', 'tr': 'Giriş yap'},
  'signUp': {'en': 'Create account', 'tr': 'Hesap oluştur'},
  'signOut': {'en': 'Sign out', 'tr': 'Çıkış yap'},
  'email': {'en': 'Email', 'tr': 'E-posta'},
  'password': {'en': 'Password', 'tr': 'Şifre'},
  'username': {'en': 'Username', 'tr': 'Kullanıcı adı'},
  'usernameRequired': {
    'en': 'Enter your username.',
    'tr': 'Kullanıcı adını gir.',
  },
  'invalidEmail': {
    'en': 'Enter a valid email address.',
    'tr': 'Geçerli bir e-posta adresi gir.',
  },
  'invalidPassword': {
    'en': 'Use at least 6 characters.',
    'tr': 'En az 6 karakter kullan.',
  },
  'forgotPassword': {'en': 'Forgot password?', 'tr': 'Şifreni mi unuttun?'},
  'sendResetLink': {
    'en': 'Send reset link',
    'tr': 'Sıfırlama bağlantısı gönder',
  },
  'resetLinkSent': {
    'en': 'If an account exists for that email, a reset link is on its way.',
    'tr': 'Bu e-postaya ait bir hesap varsa sıfırlama bağlantısı gönderildi.',
  },
  'noAccount': {
    'en': "Don't have an account? Create one",
    'tr': 'Hesabın yok mu? Oluştur',
  },
  'haveAccount': {
    'en': 'Already have an account? Sign in',
    'tr': 'Zaten hesabın var mı? Giriş yap',
  },
  'confirmEmail': {
    'en': 'Check your inbox to confirm your account, then sign in.',
    'tr': 'Hesabını onaylamak için e-postanı kontrol et, sonra giriş yap.',
  },
  'somethingWentWrong': {
    'en': 'Something went wrong. Please try again.',
    'tr': 'Bir şeyler ters gitti. Lütfen tekrar dene.',
  },
  'retry': {'en': 'Retry', 'tr': 'Tekrar dene'},
  'skip': {'en': 'Skip', 'tr': 'Geç'},
  'next': {'en': 'Next', 'tr': 'İleri'},
  'getStarted': {'en': 'Get started', 'tr': 'Başlayalım'},
  'onboarding1Title': {
    'en': 'Everything in one place',
    'tr': 'Her şey tek yerde',
  },
  'onboarding1Body': {
    'en': 'Replace this page with what makes your app worth opening.',
    'tr': 'Bu sayfayı uygulamanı açmaya değer kılan şeyle değiştir.',
  },
  'onboarding2Title': {'en': 'Built to be fast', 'tr': 'Hız için tasarlandı'},
  'onboarding2Body': {
    'en': 'Tell people the second thing they should know.',
    'tr': 'İnsanlara bilmeleri gereken ikinci şeyi anlat.',
  },
  'onboarding3Title': {'en': 'Ready when you are', 'tr': 'Hazır olduğunda'},
  'onboarding3Body': {
    'en': 'One last page before they start.',
    'tr': 'Başlamadan önceki son sayfa.',
  },
  'emptyList': {'en': 'Nothing here yet.', 'tr': 'Henüz burada bir şey yok.'},
  'add': {'en': 'Add', 'tr': 'Ekle'},
  'cancel': {'en': 'Cancel', 'tr': 'İptal'},
  'nameLabel': {'en': 'Name', 'tr': 'Ad'},
  'nameRequired': {'en': 'Enter a name.', 'tr': 'Bir ad gir.'},
};

/// Rendering helpers shared by every template.
class TemplateContext {
  TemplateContext(this.spec);

  final ProjectSpec spec;

  /// `package:<app>/<path>`.
  String pkg(String path) => "import 'package:${spec.name}/$path';";

  /// The import that brings in core_architecture and every chosen backend.
  /// Each backend package re-exports the core.
  List<String> get coreImports => [
    if (spec.backend.hasSupabase)
      "import 'package:core_architecture_supabase/core_architecture_supabase.dart';",
    if (spec.backend.hasDio)
      "import 'package:core_architecture_dio/core_architecture_dio.dart';",
    if (spec.backend == Backend.none)
      "import 'package:core_architecture/core_architecture.dart';",
  ];

  List<String> get l10nImports =>
      spec.l10n ? [pkg('l10n/l10n.dart')] : const [];

  /// A user-facing string: `context.l10n.key` with localization on, the
  /// English literal without it.
  String t(String key) {
    if (spec.l10n) return 'context.l10n.$key';
    return dartString(strings[key]!['en']!);
  }

  /// The text for [key] in [locale], English when there is no translation.
  String text(String key, String locale) =>
      strings[key]![locale] ?? strings[key]!['en']!;

  /// `context.push(...)` with a router, `Navigator.push` without.
  String push(String widget) => spec.router
      ? 'context.push($widget.path)'
      : 'Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const $widget()))';

  /// Leaves a screen pushed on top of [fallback].
  String back(String fallback) => spec.router
      ? 'context.go($fallback.path)'
      : 'Navigator.of(context).pop()';

  List<String> get routerImports => spec.router
      ? const ["import 'package:go_router/go_router.dart';"]
      : const [];

  /// Whether sign-in asks for an email, or for the REST API's own identifier.
  bool get usesEmail =>
      spec.dataBackend != Backend.dio ||
      spec.dioAuth.identifierField == 'email';

  String get entity => pascalCase(spec.feature!);
  String get entityVar => camelCase(spec.feature!);
  String get entityPlural => pascalCase(spec.table);
  String get featureDir => 'features/${spec.table}';
}

/// A single-quoted Dart string literal.
String dartString(String value) {
  final escaped = value
      .replaceAll(r'\', r'\\')
      .replaceAll("'", r"\'")
      .replaceAll(r'$', r'\$');
  return "'$escaped'";
}

String prettyJson(Object value) =>
    '${const JsonEncoder.withIndent('  ').convert(value)}\n';

/// Joins non-empty lines, dropping the blanks conditional parts leave behind.
String lines(Iterable<String?> parts) =>
    parts.whereType<String>().where((l) => l.isNotEmpty).join('\n');
