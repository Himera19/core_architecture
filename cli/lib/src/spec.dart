import 'package:yaml/yaml.dart';

import 'version.dart';

enum Backend {
  none('No backend'),
  supabase('Supabase'),
  dio('REST API (Dio)'),
  both('Supabase + REST API');

  const Backend(this.label);
  final String label;

  bool get hasSupabase => this == supabase || this == both;
  bool get hasDio => this == dio || this == both;
}

enum AppThemeMode { system, light, dark }

const List<String> allPlatforms = [
  'android',
  'ios',
  'web',
  'macos',
  'windows',
  'linux',
];

/// Endpoints and fields for the REST API's auth, mirroring `DioAuthConfig`.
/// Only the fields that differ from its defaults end up in generated code.
class DioAuthSpec {
  String loginPath = '/auth/login';
  String? registerPath = '/auth/register';
  String? refreshPath = '/auth/refresh';
  String? logoutPath;
  String? passwordResetPath;
  String identifierField = 'email';
  String accessTokenField = 'access_token';
  String refreshTokenField = 'refresh_token';

  static final DioAuthSpec defaults = DioAuthSpec();

  Map<String, Object?> toMap() => {
    'login_path': loginPath,
    'register_path': registerPath,
    'refresh_path': refreshPath,
    'logout_path': logoutPath,
    'password_reset_path': passwordResetPath,
    'identifier_field': identifierField,
    'access_token_field': accessTokenField,
    'refresh_token_field': refreshTokenField,
  };

  void apply(Map<Object?, Object?> map) {
    String? read(String key, String? fallback) =>
        map.containsKey(key) ? map[key] as String? : fallback;

    loginPath = read('login_path', loginPath)!;
    registerPath = read('register_path', registerPath);
    refreshPath = read('refresh_path', refreshPath);
    logoutPath = read('logout_path', logoutPath);
    passwordResetPath = read('password_reset_path', passwordResetPath);
    identifierField = read('identifier_field', identifierField)!;
    accessTokenField = read('access_token_field', accessTokenField)!;
    refreshTokenField = read('refresh_token_field', refreshTokenField)!;
  }
}

/// Every answer the scaffolder needs. Filled by the prompts, a config file,
/// or both — a config file sets the defaults the prompts then offer.
class ProjectSpec {
  ProjectSpec({required this.name});

  /// Dart package name — `snake_case`.
  String name;
  String org = 'com.example';
  List<String> platforms = ['android', 'ios'];

  Backend backend = Backend.none;

  /// Written to `.env` only, never to `core_architecture.yaml`.
  String supabaseUrl = '';
  String supabaseKey = '';
  String deleteUserRpc = 'delete_user';

  /// Written to `.env` only.
  String apiBaseUrl = '';
  DioAuthSpec dioAuth = DioAuthSpec();

  /// `RRGGBB`, or null for the package's own palette.
  String? brandColor;

  /// A Google Fonts family, or null for the platform font.
  String? font;
  AppThemeMode themeMode = AppThemeMode.system;

  bool router = true;
  bool onboarding = true;
  bool auth = true;
  bool l10n = false;
  List<String> locales = ['en', 'tr'];

  /// Singular `snake_case` entity name for the example CRUD feature, or null
  /// for none. Only offered with a backend.
  String? feature = 'item';

  /// Backend table / REST resource the feature reads. Defaults to the plural.
  String? featureTable;

  /// Which backend the feature and auth use when [backend] is [Backend.both].
  Backend primary = Backend.supabase;

  String ref = packageRef;

  // ==================== Derived ====================

  String get displayName =>
      name.split('_').where((w) => w.isNotEmpty).map(_capitalize).join(' ');

  bool get hasAuth => auth && backend != Backend.none;

  bool get hasFeature => feature != null && backend != Backend.none;

  /// The backend auth and the example feature talk to.
  Backend get dataBackend => backend == Backend.both ? primary : backend;

  String get table => featureTable ?? '${feature}s';

  String get templateLocale => locales.contains('en') ? 'en' : locales.first;

  /// Whether the Dio password-reset link can be shown.
  bool get canResetPassword =>
      dataBackend == Backend.supabase || dioAuth.passwordResetPath != null;

  bool get canSignUp =>
      dataBackend == Backend.supabase || dioAuth.registerPath != null;

  // ==================== Validation ====================

  static final RegExp _packageName = RegExp(r'^[a-z][a-z0-9_]*$');
  static final RegExp _hex = RegExp(r'^#?[0-9a-fA-F]{6}$');
  static final RegExp _org = RegExp(r'^[a-zA-Z][\w]*(\.[a-zA-Z][\w]*)+$');

  static String? validateName(String value) {
    if (!_packageName.hasMatch(value)) {
      return 'Use lowercase letters, digits and underscores, starting with a letter.';
    }
    if (_reserved.contains(value)) return '"$value" is a Dart keyword.';
    return null;
  }

  static String? validateOrg(String value) =>
      _org.hasMatch(value) ? null : 'Use a reverse domain like com.example.';

  static String? validateHex(String value) =>
      _hex.hasMatch(value) ? null : 'Use six hex digits, like 5D1B9A.';

  static String? validateFeature(String value) => _packageName.hasMatch(value)
      ? null
      : 'Use a singular snake_case name, like product.';

  /// Every problem with the current answers, empty when they are usable.
  List<String> validate() => [
    ?validateName(name),
    ?validateOrg(org),
    if (platforms.isEmpty) 'Pick at least one platform.',
    for (final p in platforms)
      if (!allPlatforms.contains(p)) 'Unknown platform "$p".',
    if (brandColor != null) ?validateHex(brandColor!),
    if (feature != null) ?validateFeature(feature!),
    if (backend == Backend.both &&
        primary != Backend.supabase &&
        primary != Backend.dio)
      'primary must be supabase or dio.',
    if (l10n && locales.isEmpty) 'Pick at least one language.',
  ];

  // ==================== Serialization ====================

  /// The answers without secrets, for `core_architecture.yaml`.
  Map<String, Object?> toMap() => {
    'name': name,
    'org': org,
    'platforms': platforms,
    'backend': backend.name,
    if (backend == Backend.both) 'primary': primary.name,
    if (backend.hasSupabase) 'delete_user_rpc': deleteUserRpc,
    if (backend.hasDio) 'dio_auth': dioAuth.toMap(),
    'brand_color': brandColor,
    'font': font,
    'theme_mode': themeMode.name,
    'router': router,
    'onboarding': onboarding,
    'auth': auth,
    'l10n': l10n,
    'locales': locales,
    'feature': feature,
    'feature_table': featureTable,
    'ref': ref,
  };

  /// Applies a config file's values on top of the defaults. Unknown keys are
  /// rejected, so a typo does not silently fall back to a default.
  void apply(Map<Object?, Object?> map) {
    final unknown = map.keys.where((k) => !_keys.contains(k)).toList();
    if (unknown.isNotEmpty) {
      throw FormatException('Unknown config keys: ${unknown.join(', ')}');
    }

    T read<T>(String key, T fallback) =>
        map.containsKey(key) ? map[key] as T : fallback;
    List<String> readList(String key, List<String> fallback) =>
        map.containsKey(key)
        ? [for (final v in map[key] as List) '$v']
        : fallback;

    name = read('name', name);
    org = read('org', org);
    platforms = readList('platforms', platforms);
    backend = Backend.values.byName(read('backend', backend.name));
    primary = Backend.values.byName(read('primary', primary.name));
    deleteUserRpc = read('delete_user_rpc', deleteUserRpc);
    supabaseUrl = read('supabase_url', supabaseUrl);
    supabaseKey = read('supabase_key', supabaseKey);
    apiBaseUrl = read('api_base_url', apiBaseUrl);
    if (map['dio_auth'] case final Map<Object?, Object?> dio) {
      dioAuth.apply(dio);
    }
    brandColor = read<String?>(
      'brand_color',
      brandColor,
    )?.replaceFirst('#', '');
    font = read('font', font);
    themeMode = AppThemeMode.values.byName(read('theme_mode', themeMode.name));
    router = read('router', router);
    onboarding = read('onboarding', onboarding);
    auth = read('auth', auth);
    l10n = read('l10n', l10n);
    locales = readList('locales', locales);
    feature = read('feature', feature);
    featureTable = read('feature_table', featureTable);
    ref = read('ref', ref);
  }

  static ProjectSpec fromYaml(String source, {String? name}) {
    final doc = loadYaml(source);
    final map = doc is Map
        ? Map<Object?, Object?>.of(doc)
        : <Object?, Object?>{};
    final spec = ProjectSpec(name: name ?? map['name'] as String? ?? 'my_app');
    spec.apply(map..remove('name'));
    return spec;
  }

  static const Set<String> _keys = {
    'name',
    'org',
    'platforms',
    'backend',
    'primary',
    'delete_user_rpc',
    'supabase_url',
    'supabase_key',
    'api_base_url',
    'dio_auth',
    'brand_color',
    'font',
    'theme_mode',
    'router',
    'onboarding',
    'auth',
    'l10n',
    'locales',
    'feature',
    'feature_table',
    'ref',
  };

  static const Set<String> _reserved = {
    'abstract',
    'as',
    'assert',
    'async',
    'await',
    'break',
    'case',
    'catch',
    'class',
    'const',
    'continue',
    'default',
    'do',
    'else',
    'enum',
    'export',
    'extends',
    'false',
    'final',
    'finally',
    'for',
    'if',
    'import',
    'in',
    'is',
    'new',
    'null',
    'return',
    'super',
    'switch',
    'this',
    'throw',
    'true',
    'try',
    'var',
    'void',
    'while',
    'with',
    'flutter',
    'test',
  };
}

String _capitalize(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

/// `snake_case` → `PascalCase`.
String pascalCase(String snake) => snake.split('_').map(_capitalize).join();

/// `snake_case` → `camelCase`.
String camelCase(String snake) {
  final pascal = pascalCase(snake);
  return pascal[0].toLowerCase() + pascal.substring(1);
}
