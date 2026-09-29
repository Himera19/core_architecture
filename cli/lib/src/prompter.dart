import 'dart:io';

import 'package:mason_logger/mason_logger.dart';

import 'spec.dart';

/// Asks every question, offering [spec]'s current values as defaults — so a
/// config file passed alongside pre-fills the answers.
class Prompter {
  Prompter(this.logger);

  final Logger logger;

  Future<ProjectSpec> ask(ProjectSpec spec, {required bool nameGiven}) async {
    logger.info(styleBold.wrap('\nProject'));
    if (!nameGiven) {
      spec.name = _ask(
        'App name (snake_case)',
        spec.name,
        ProjectSpec.validateName,
      );
    }
    spec.org = _ask(
      'Organization (bundle id prefix)',
      spec.org,
      ProjectSpec.validateOrg,
    );
    spec.platforms = logger.chooseAny(
      'Platforms',
      choices: allPlatforms,
      defaultValues: spec.platforms,
    );
    while (spec.platforms.isEmpty) {
      logger.err('Pick at least one platform.');
      spec.platforms = logger.chooseAny('Platforms', choices: allPlatforms);
    }

    logger.info(styleBold.wrap('\nBackend'));
    spec.backend = logger.chooseOne(
      'Which backend does the app talk to?',
      choices: Backend.values,
      defaultValue: spec.backend,
      display: (b) => b.label,
    );

    if (spec.backend.hasSupabase) {
      spec.supabaseUrl = logger
          .prompt(
            'Supabase URL (empty: fill in .env later)',
            defaultValue: spec.supabaseUrl,
          )
          .trim();
      spec.supabaseKey = logger
          .prompt(
            'Supabase publishable key (empty: fill in .env later)',
            defaultValue: spec.supabaseKey,
          )
          .trim();
    }

    if (spec.backend.hasDio) {
      spec.apiBaseUrl = logger
          .prompt(
            'REST API base URL (empty: fill in .env later)',
            defaultValue: spec.apiBaseUrl,
          )
          .trim();
    }

    if (spec.backend == Backend.both) {
      spec.primary = logger.chooseOne(
        'Which one handles sign-in and the example feature?',
        choices: [Backend.supabase, Backend.dio],
        defaultValue: spec.primary,
        display: (b) => b.label,
      );
    }

    logger.info(styleBold.wrap('\nFeatures'));
    if (spec.backend != Backend.none) {
      spec.auth = logger.confirm(
        'Add sign-in, sign-up and password-reset screens?',
        defaultValue: spec.auth,
      );
      if (spec.hasAuth && spec.dataBackend == Backend.supabase) {
        spec.deleteUserRpc = _ask(
          'Postgres function that deletes an account',
          spec.deleteUserRpc,
          ProjectSpec.validateFeature,
        );
      }
      if (spec.backend.hasDio &&
          (spec.hasAuth || spec.dataBackend == Backend.dio)) {
        _askDioAuth(spec);
      }
    }
    spec.onboarding = logger.confirm(
      'Add an onboarding flow shown on first launch?',
      defaultValue: spec.onboarding,
    );
    spec.router = logger.confirm(
      'Use go_router for navigation?',
      defaultValue: spec.router,
    );
    spec.l10n = logger.confirm(
      'Localize the app (flutter gen-l10n)?',
      defaultValue: spec.l10n,
    );
    if (spec.l10n) {
      spec.locales = _askList(
        'Languages, comma-separated (en and tr come translated)',
        spec.locales,
      );
    }
    if (spec.backend != Backend.none) {
      final feature = logger
          .prompt(
            'Example CRUD feature — singular entity name (empty: none)',
            defaultValue: spec.feature ?? '',
          )
          .trim();
      if (feature.isEmpty) {
        spec.feature = null;
      } else {
        spec.feature = ProjectSpec.validateFeature(feature) == null
            ? feature
            : _ask('Entity name', 'item', ProjectSpec.validateFeature);
        final table = _ask(
          spec.dataBackend == Backend.supabase ? 'Table name' : 'REST resource',
          spec.featureTable ?? '${spec.feature}s',
          ProjectSpec.validateFeature,
        );
        spec.featureTable = table == '${spec.feature}s' ? null : table;
      }
    }

    logger.info(styleBold.wrap('\nTheme'));
    final color = logger
        .prompt(
          'Brand colour as hex, e.g. 5D1B9A (empty: package palette)',
          defaultValue: spec.brandColor ?? '',
        )
        .trim();
    spec.brandColor = color.isEmpty
        ? null
        : ProjectSpec.validateHex(color) == null
        ? color.replaceFirst('#', '').toUpperCase()
        : _ask(
            'Brand colour',
            '5D1B9A',
            ProjectSpec.validateHex,
          ).replaceFirst('#', '');
    spec.font = await _askFont(spec.font);
    spec.themeMode = logger.chooseOne(
      'Theme mode on first launch',
      choices: AppThemeMode.values,
      defaultValue: spec.themeMode,
      display: (m) => m.name,
    );

    return spec;
  }

  void _askDioAuth(ProjectSpec spec) {
    final a = spec.dioAuth;
    logger.info(
      darkGray.wrap(
        '  REST auth defaults: POST ${a.loginPath}, ${a.registerPath}, '
        '${a.refreshPath}; tokens at "${a.accessTokenField}" / "${a.refreshTokenField}".',
      ),
    );
    if (!logger.confirm('Does your API differ from these?')) return;

    String? optional(String label, String? value) {
      final answer = logger
          .prompt('$label (- for none)', defaultValue: value ?? '-')
          .trim();
      return answer == '-' || answer.isEmpty ? null : answer;
    }

    a.loginPath = logger.prompt('Login path', defaultValue: a.loginPath).trim();
    a.registerPath = optional('Register path', a.registerPath);
    a.refreshPath = optional('Refresh path', a.refreshPath);
    a.logoutPath = optional('Logout path', a.logoutPath);
    a.passwordResetPath = optional('Password-reset path', a.passwordResetPath);
    a.identifierField = logger
        .prompt(
          'Login identifier field (email, username, …)',
          defaultValue: a.identifierField,
        )
        .trim();
    a.accessTokenField = logger
        .prompt(
          'Access token field (dotted path, e.g. data.token)',
          defaultValue: a.accessTokenField,
        )
        .trim();
    a.refreshTokenField = logger
        .prompt(
          'Refresh token field (dotted path)',
          defaultValue: a.refreshTokenField,
        )
        .trim();
  }

  Future<String?> _askFont(String? current) async {
    while (true) {
      final font = logger
          .prompt(
            'Google Fonts family, e.g. Inter (empty: platform font)',
            defaultValue: current ?? '',
          )
          .trim();
      if (font.isEmpty) return null;
      final exists = await googleFontExists(font);
      if (exists != false) return font;
      logger.err('Google Fonts has no family called "$font".');
      current = null;
    }
  }

  String _ask(
    String message,
    String defaultValue,
    String? Function(String) validate,
  ) {
    while (true) {
      final answer = logger.prompt(message, defaultValue: defaultValue).trim();
      final error = validate(answer);
      if (error == null) return answer;
      logger.err(error);
    }
  }

  List<String> _askList(String message, List<String> defaultValue) {
    final answer = logger.prompt(message, defaultValue: defaultValue.join(','));
    final items = [
      for (final item in answer.split(','))
        if (item.trim().isNotEmpty) item.trim(),
    ];
    return items.isEmpty ? defaultValue : items;
  }
}

/// Whether Google Fonts serves [family]; null when that cannot be told
/// (offline), so the question never blocks on the network.
Future<bool?> googleFontExists(String family) async {
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 5);
  try {
    final uri = Uri.https('fonts.googleapis.com', '/css2', {'family': family});
    final response = await (await client.getUrl(uri)).close();
    await response.drain<void>();
    return response.statusCode == 200;
  } catch (_) {
    return null;
  } finally {
    client.close(force: true);
  }
}
