import 'dart:convert';
import 'dart:io';

import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as p;
import 'package:yaml_edit/yaml_edit.dart';

import 'spec.dart';
import 'templates/project.dart';
import 'version.dart';

class GeneratorException implements Exception {
  GeneratorException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Turns a [ProjectSpec] into a Flutter project on disk: `flutter create`,
/// the dependencies, the rendered files, then code generation and a final
/// `flutter analyze`.
class Generator {
  Generator(this.logger, {this.flutter = 'flutter', this.dart = 'dart'});

  final Logger logger;
  final String flutter;
  final String dart;

  /// Returns whether `flutter analyze` came back clean.
  Future<bool> generate(ProjectSpec spec, Directory target) async {
    final errors = spec.validate();
    if (errors.isNotEmpty) throw GeneratorException(errors.join('\n'));
    if (target.existsSync() && target.listSync().isNotEmpty) {
      throw GeneratorException(
        '${target.path} already exists and is not empty.',
      );
    }

    final dir = target.path;

    await _step('Creating the Flutter project', flutter, [
      'create',
      '--org',
      spec.org,
      '--project-name',
      spec.name,
      '--platforms',
      spec.platforms.join(','),
      '--empty',
      '--no-pub',
      dir,
    ]);

    await _step('Adding dependencies', flutter, [
      'pub',
      'add',
      ..._dependencies(spec),
    ], dir: dir);

    final files = renderProject(spec);
    final progress = logger.progress('Writing ${files.length} files');
    for (final entry in files.entries) {
      final file = File(p.join(dir, entry.key));
      file.parent.createSync(recursive: true);
      file.writeAsStringSync(entry.value);
    }
    _editPubspec(spec, dir);
    _editGitignore(spec, dir);
    _addPlatformPermissions(spec, dir);
    progress.complete();

    await _step('Resolving packages', flutter, ['pub', 'get'], dir: dir);
    if (spec.l10n) {
      await _step('Generating localizations', flutter, ['gen-l10n'], dir: dir);
    }
    await _step('Generating providers', dart, [
      'run',
      'build_runner',
      'build',
      '--delete-conflicting-outputs',
    ], dir: dir);
    await _step('Tidying code', dart, ['fix', '--apply'], dir: dir);
    await _step('Formatting', dart, ['format', '.'], dir: dir);

    final analyze = logger.progress('Analyzing');
    final result = await Process.run(flutter, [
      'analyze',
    ], workingDirectory: dir);
    if (result.exitCode == 0) {
      analyze.complete('No analyzer issues');
      return true;
    }
    analyze.fail('The analyzer found issues');
    logger.info('${result.stdout}');
    return false;
  }

  /// Arguments for one `flutter pub add`, so pub picks every version against
  /// the others in a single resolution.
  List<String> _dependencies(ProjectSpec spec) {
    String git(String package) =>
        '$package:${jsonEncode({
          'git': {'url': repositoryUrl, 'path': 'packages/$package', 'ref': spec.ref},
        })}';

    return [
      if (spec.backend.hasSupabase) git('core_architecture_supabase'),
      if (spec.backend.hasDio) git('core_architecture_dio'),
      if (spec.backend == Backend.none) git('core_architecture'),
      'riverpod_annotation',
      if (spec.router) 'go_router',
      if (spec.font != null) 'google_fonts',
      if (spec.l10n) ...['intl', 'flutter_localizations:{"sdk":"flutter"}'],
      'dev:build_runner',
      'dev:riverpod_generator',
    ];
  }

  void _editPubspec(ProjectSpec spec, String dir) {
    final file = File(p.join(dir, 'pubspec.yaml'));
    final editor = YamlEditor(file.readAsStringSync());
    if (spec.backend != Backend.none) {
      editor.update(['flutter', 'assets'], ['.env']);
    }
    if (spec.l10n) editor.update(['flutter', 'generate'], true);
    file.writeAsStringSync(editor.toString());
  }

  void _editGitignore(ProjectSpec spec, String dir) {
    if (spec.backend == Backend.none) return;
    final file = File(p.join(dir, '.gitignore'));
    final current = file.existsSync() ? file.readAsStringSync() : '';
    file.writeAsStringSync(
      '$current\n# Backend credentials — .env.example is the template to commit.\n.env\n',
    );
  }

  /// Release builds need these to reach the network; debug builds hide their
  /// absence.
  void _addPlatformPermissions(ProjectSpec spec, String dir) {
    if (spec.backend == Backend.none && spec.font == null) return;

    final manifest = File(
      p.join(dir, 'android/app/src/main/AndroidManifest.xml'),
    );
    if (manifest.existsSync()) {
      const permission =
          '<uses-permission android:name="android.permission.INTERNET"/>';
      final xml = manifest.readAsStringSync();
      if (!xml.contains(permission)) {
        manifest.writeAsStringSync(
          xml.replaceFirst(
            RegExp(r'(<manifest[^>]*>)'),
            '\$1\n    $permission',
          ),
        );
      }
    }

    for (final name in ['DebugProfile.entitlements', 'Release.entitlements']) {
      final file = File(p.join(dir, 'macos/Runner', name));
      if (!file.existsSync()) continue;
      final plist = file.readAsStringSync();
      if (plist.contains('com.apple.security.network.client')) continue;
      file.writeAsStringSync(
        plist.replaceFirst(
          '<dict>',
          '<dict>\n\t<key>com.apple.security.network.client</key>\n\t<true/>',
        ),
      );
    }
  }

  Future<void> _step(
    String label,
    String executable,
    List<String> args, {
    String? dir,
  }) async {
    final progress = logger.progress(label);
    final result = await Process.run(executable, args, workingDirectory: dir);
    if (result.exitCode != 0) {
      progress.fail(label);
      throw GeneratorException(
        '`$executable ${args.join(' ')}` failed:\n${result.stdout}${result.stderr}',
      );
    }
    progress.complete();
  }
}
