import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;

import '../utils/manifest_loader.dart';

class RunCommand extends Command<int> {
  @override
  String get name => 'run';

  @override
  String get description => 'Run the host project.';

  RunCommand() {
    argParser.addOption(
      'project',
      abbr: 'p',
      help: 'Path to the Fluttron project root.',
      defaultsTo: '.',
      valueHelp: 'path',
    );
  }

  @override
  Future<int> run() async {
    final projectPath = argResults?['project'] as String? ?? '.';
    final projectDir = Directory(p.normalize(projectPath));

    try {
      final manifest = ManifestLoader.load(projectDir);
      final hostAssetsDir = Directory(
        p.join(projectDir.path, manifest.hostAssetPath),
      );
      if (!hostAssetsDir.existsSync()) {
        stderr.writeln(
          'Host assets directory not found: ${p.normalize(hostAssetsDir.path)}',
        );
        return 2;
      }

      final hostProjectDir = _findFlutterProjectRoot(hostAssetsDir);
      if (hostProjectDir == null) {
        stderr.writeln(
          'Unable to locate host Flutter project (pubspec.yaml not found).',
        );
        return 2;
      }

      stdout.writeln('Manifest: ${p.normalize(manifest.manifestPath)}');
      stdout.writeln('Host project: ${p.normalize(hostProjectDir.path)}');
      stdout.writeln('Next step: run Flutter host from the host project.');
      return 0;
    } on ManifestException catch (error) {
      stderr.writeln(error);
      return 2;
    }
  }

  Directory? _findFlutterProjectRoot(Directory startDir) {
    var current = startDir;
    for (var i = 0; i < 5; i++) {
      final pubspec = File(p.join(current.path, 'pubspec.yaml'));
      if (pubspec.existsSync()) {
        return current;
      }
      final parent = current.parent;
      if (parent.path == current.path) {
        break;
      }
      current = parent;
    }
    return null;
  }
}
