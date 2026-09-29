import 'package:core_architecture_cli/core_architecture_cli.dart';
import 'package:core_architecture_cli/src/templates/context.dart'
    show dartString;
import 'package:test/test.dart';

/// Every combination of the answers that change which files exist or how
/// they are wired. Rendering is pure, so all of them run in milliseconds;
/// `tool/e2e.sh` builds and analyzes a representative few for real.
Iterable<ProjectSpec> _combinations() sync* {
  for (final backend in Backend.values) {
    for (final router in [true, false]) {
      for (final onboarding in [true, false]) {
        for (final auth in [true, false]) {
          for (final l10n in [true, false]) {
            for (final feature in ['item', null]) {
              for (final primary in [Backend.supabase, Backend.dio]) {
                if (backend != Backend.both && primary == Backend.dio) continue;
                yield ProjectSpec(name: 'app')
                  ..backend = backend
                  ..primary = primary
                  ..router = router
                  ..onboarding = onboarding
                  ..auth = auth
                  ..l10n = l10n
                  ..feature = feature;
              }
            }
          }
        }
      }
    }
  }
}

void main() {
  test(
    'every combination renders, and every import points at a rendered file',
    () {
      var count = 0;
      for (final spec in _combinations()) {
        final files = renderProject(spec);
        final generated = {'l10n/app_localizations.dart'};

        for (final entry in files.entries.where(
          (e) => e.key.endsWith('.dart'),
        )) {
          for (final match in RegExp(
            r"import 'package:app/([^']+)';",
          ).allMatches(entry.value)) {
            final target = match.group(1)!;
            expect(
              files.containsKey('lib/$target') || generated.contains(target),
              isTrue,
              reason:
                  '${entry.key} imports $target, which is not rendered for ${spec.toMap()}',
            );
          }
        }
        count++;
      }
      expect(count, greaterThan(100));
    },
  );

  test('no backend means no auth, feature, .env or schema', () {
    final files = renderProject(
      ProjectSpec(name: 'app')..backend = Backend.none,
    );
    expect(files.keys.where((k) => k.contains('auth')), isEmpty);
    expect(files.keys.where((k) => k.contains('items')), isEmpty);
    expect(files, isNot(contains('.env')));
    expect(files, isNot(contains('supabase/schema.sql')));
  });

  test('the dio config lists only what differs from the defaults', () {
    final spec = ProjectSpec(name: 'app')..backend = Backend.dio;
    expect(
      renderProject(spec)['lib/app/dio_config.dart'],
      contains('auth: DioAuthConfig(),'),
    );

    spec.dioAuth
      ..identifierField = 'username'
      ..registerPath = null;
    final config = renderProject(spec)['lib/app/dio_config.dart']!;
    expect(config, contains("identifierField: 'username'"));
    expect(config, contains('registerPath: null'));
    expect(config, isNot(contains('loginPath')));

    // No register path, so no sign-up screen and no link to one.
    final files = renderProject(spec);
    expect(
      files,
      isNot(contains('lib/features/auth/presentation/sign_up_screen.dart')),
    );
    expect(
      files['lib/features/auth/presentation/sign_in_screen.dart'],
      isNot(contains('SignUpScreen')),
    );
    expect(
      files['lib/features/auth/presentation/sign_in_screen.dart'],
      contains("'Username'"),
    );
  });

  test('secrets reach .env and never core_architecture.yaml', () {
    final spec = ProjectSpec(name: 'app')
      ..backend = Backend.both
      ..supabaseUrl = 'https://x.supabase.co'
      ..supabaseKey = 'sb_publishable_secret'
      ..apiBaseUrl = 'https://api.x.dev';
    final files = renderProject(spec);

    expect(files['.env'], contains('sb_publishable_secret'));
    expect(files['.env.example'], isNot(contains('sb_publishable_secret')));
    expect(
      files['core_architecture.yaml'],
      isNot(contains('sb_publishable_secret')),
    );
    expect(files['core_architecture.yaml'], isNot(contains('api.x.dev')));
  });

  test('a locale without translations falls back to English text', () {
    final spec = ProjectSpec(name: 'app')
      ..l10n = true
      ..locales = ['tr', 'de'];
    final files = renderProject(spec);

    expect(files['l10n.yaml'], contains('template-arb-file: app_tr.arb'));
    expect(files['lib/l10n/app_de.arb'], contains('"signIn": "Sign in"'));
    expect(files['lib/l10n/app_tr.arb'], contains('"signIn": "Giriş yap"'));
  });

  test('strings with quotes and dollars stay valid Dart', () {
    expect(dartString("Don't pay \$5"), r"'Don\'t pay \$5'");
  });

  group('config file', () {
    test('round-trips through core_architecture.yaml', () {
      final spec = ProjectSpec(name: 'shop')
        ..backend = Backend.both
        ..primary = Backend.dio
        ..brandColor = '0E7C66'
        ..locales = ['tr']
        ..featureTable = 'catalog';
      spec.dioAuth.accessTokenField = 'data.token';

      final again = ProjectSpec.fromYaml(
        renderProject(spec)['core_architecture.yaml']!,
      );
      expect(again.toMap(), spec.toMap());
    });

    test('rejects unknown keys instead of ignoring a typo', () {
      expect(
        () => ProjectSpec.fromYaml('backnd: dio'),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('backnd'),
          ),
        ),
      );
    });

    test('accepts a leading # on the brand colour', () {
      expect(
        ProjectSpec.fromYaml("brand_color: '#0e7c66'").brandColor,
        '0e7c66',
      );
    });
  });

  group('validation', () {
    test('names', () {
      expect(ProjectSpec.validateName('my_app'), isNull);
      expect(ProjectSpec.validateName('MyApp'), isNotNull);
      expect(ProjectSpec.validateName('1app'), isNotNull);
      expect(ProjectSpec.validateName('class'), isNotNull);
    });

    test('a spec with problems lists each one', () {
      final spec = ProjectSpec(name: 'Bad')
        ..org = 'nodots'
        ..platforms = []
        ..brandColor = 'purple';
      expect(spec.validate(), hasLength(4));
    });
  });
}
