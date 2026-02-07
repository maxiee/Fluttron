import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;

import '../utils/manifest_loader.dart';
import '../utils/ui_build_pipeline.dart';

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
      final loaded = ManifestLoader.load(projectDir);
      final pipeline = UiBuildPipeline();
      return pipeline.build(
        projectDir: projectDir,
        manifestPath: loaded.manifestPath,
        manifest: loaded.manifest,
      );
    } on ManifestException catch (error) {
      stderr.writeln(error);
      return 2;
    } on FileSystemException catch (error) {
      stderr.writeln(error.message);
      return 2;
    }
  }
}
