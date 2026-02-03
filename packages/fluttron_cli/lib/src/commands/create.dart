import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;

class CreateCommand extends Command<int> {
  @override
  String get name => 'create';

  @override
  String get description => 'Create a new Fluttron project from templates.';

  CreateCommand() {
    argParser
      ..addOption(
        'name',
        abbr: 'n',
        help: 'Project name (optional).',
        valueHelp: 'name',
      )
      ..addOption(
        'template',
        abbr: 't',
        help: 'Path to templates root (optional).',
        valueHelp: 'path',
      );
  }

  @override
  Future<int> run() async {
    final targetPath = _readSingleRest('target directory');
    final targetDir = Directory(targetPath);
    final normalizedTarget = p.normalize(targetDir.path);

    if (targetDir.existsSync()) {
      final entries = targetDir.listSync();
      if (entries.isNotEmpty) {
        stderr.writeln('Target directory is not empty: $normalizedTarget');
        return 2;
      }
    }

    stdout.writeln('Create command is ready.');
    stdout.writeln('Target: $normalizedTarget');

    final name = argResults?['name'] as String?;
    if (name != null && name.trim().isNotEmpty) {
      stdout.writeln('Name: $name');
    }

    final template = argResults?['template'] as String?;
    if (template != null && template.trim().isNotEmpty) {
      stdout.writeln('Template: ${p.normalize(template)}');
    }

    stdout.writeln('Next step: scaffold templates into the target directory.');
    return 0;
  }

  String _readSingleRest(String label) {
    final rest = argResults?.rest ?? const [];
    if (rest.isEmpty) {
      throw UsageException('Missing $label.', usage);
    }
    if (rest.length > 1) {
      throw UsageException('Too many arguments.', usage);
    }
    return rest.first;
  }
}
