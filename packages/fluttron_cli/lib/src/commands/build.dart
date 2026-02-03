import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;

import '../utils/manifest_loader.dart';

class BuildCommand extends Command<int> {
  @override
  String get name => 'build';

  @override
  String get description =>
      'Build the UI, then copy assets into the host project.';

  BuildCommand() {
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
      final uiDir = Directory(p.join(projectDir.path, manifest.uiProjectPath));
      if (!uiDir.existsSync()) {
        stderr.writeln('UI project not found: ${p.normalize(uiDir.path)}');
        return 2;
      }

      final hostAssetsDir = Directory(
        p.join(projectDir.path, manifest.hostAssetPath),
      );
      if (!hostAssetsDir.existsSync()) {
        stderr.writeln(
          'Host assets directory not found: ${p.normalize(hostAssetsDir.path)}',
        );
        return 2;
      }

      stdout.writeln('Manifest: ${p.normalize(manifest.manifestPath)}');
      stdout.writeln('UI project: ${p.normalize(uiDir.path)}');
      stdout.writeln('Host assets: ${p.normalize(hostAssetsDir.path)}');
      stdout.writeln('Next step: build Flutter Web and copy output.');
      return 0;
    } on ManifestException catch (error) {
      stderr.writeln(error);
      return 2;
    }
  }
}
