import 'dart:io';

import 'package:args/args.dart';
import 'package:core_architecture_cli/core_architecture_cli.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as p;

const String _usage = '''
Scaffold a Flutter app on core_architecture.

Usage: core_architecture create [<name>] [options]
''';

Future<void> main(List<String> arguments) async {
  final logger = Logger();
  final parser = ArgParser()
    ..addFlag('help', abbr: 'h', negatable: false)
    ..addFlag('version', negatable: false);
  final create = ArgParser()
    ..addFlag('help', abbr: 'h', negatable: false)
    ..addOption('output', abbr: 'o', help: 'Parent directory.', defaultsTo: '.')
    ..addOption(
      'config',
      abbr: 'c',
      help: 'YAML answers file; prompts still run unless --yes.',
    )
    ..addFlag(
      'yes',
      abbr: 'y',
      negatable: false,
      help: 'Take the config / defaults without asking.',
    )
    ..addOption(
      'ref',
      help: 'core_architecture tag or commit to depend on.',
      defaultsTo: packageRef,
    );
  parser.addCommand('create', create);

  final ArgResults args;
  try {
    args = parser.parse(arguments);
  } on FormatException catch (e) {
    logger.err(e.message);
    stdout.writeln('$_usage\n${create.usage}');
    exit(64);
  }

  if (args.flag('version')) {
    logger.info(packageRef);
    return;
  }
  final command = args.command;
  if (args.flag('help') || command == null || command.flag('help')) {
    stdout.writeln('$_usage\n${create.usage}');
    return;
  }

  final ProjectSpec spec;
  final nameArg = command.rest.isEmpty ? null : command.rest.first;
  try {
    final config = command.option('config');
    spec = config == null
        ? ProjectSpec(name: nameArg ?? 'my_app')
        : ProjectSpec.fromYaml(File(config).readAsStringSync(), name: nameArg);
  } on Object catch (e) {
    logger.err('Could not read the config: $e');
    exit(66);
  }
  spec.ref = command.option('ref') == packageRef
      ? spec.ref
      : command.option('ref')!;

  final nameError = nameArg == null ? null : ProjectSpec.validateName(nameArg);
  if (nameError != null) {
    logger.err(nameError);
    exit(64);
  }

  if (!command.flag('yes')) {
    if (!stdin.hasTerminal || !stdout.hasTerminal) {
      logger.err(
        'No terminal to ask questions in. Pass --yes, with --config for the answers.',
      );
      exit(64);
    }
    await Prompter(logger).ask(spec, nameGiven: nameArg != null);
    logger.info('');
    if (!logger.confirm(
      'Create ${spec.name} with these answers?',
      defaultValue: true,
    )) {
      exit(0);
    }
  }

  final target = Directory(p.join(command.option('output')!, spec.name));
  try {
    final clean = await Generator(logger).generate(spec, target);
    logger.info('');
    if (clean) {
      logger.success('${spec.displayName} is ready in ${target.path}');
    } else {
      logger.warn(
        '${spec.displayName} was created in ${target.path}, with analyzer issues.',
      );
    }
    logger
      ..info('  cd ${target.path}')
      ..info(
        spec.backend == Backend.none
            ? '  flutter run'
            : '  # fill in .env, then\n  flutter run',
      );
    if (!clean) exit(1);
  } on GeneratorException catch (e) {
    logger.err(e.message);
    exit(1);
  }
}
