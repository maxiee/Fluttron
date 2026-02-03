import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;

import '../utils/file_ops.dart';
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

      final hostProjectDir = _findFlutterProjectRoot(hostAssetsDir);
      if (hostProjectDir == null) {
        stderr.writeln(
          'Unable to locate host Flutter project (pubspec.yaml not found).',
        );
        return 2;
      }

      stdout.writeln('Manifest: ${p.normalize(manifest.manifestPath)}');
      stdout.writeln('UI project: ${p.normalize(uiDir.path)}');
      stdout.writeln('Host assets: ${p.normalize(hostAssetsDir.path)}');
      stdout.writeln('Building Flutter Web...');

      final buildExitCode = await _runFlutterBuild(uiDir);
      if (buildExitCode != 0) {
        stderr.writeln('Flutter build failed with exit code $buildExitCode.');
        return buildExitCode;
      }

      final buildOutputDir = Directory(p.join(uiDir.path, 'build', 'web'));
      if (!buildOutputDir.existsSync()) {
        stderr.writeln(
          'Flutter build output not found: ${p.normalize(buildOutputDir.path)}',
        );
        return 2;
      }

      final indexFile = File(p.join(buildOutputDir.path, manifest.index));
      if (!indexFile.existsSync()) {
        stderr.writeln(
          'Entry file not found: ${p.normalize(indexFile.path)}',
        );
        return 2;
      }

      stdout.writeln('Clearing host assets directory...');
      await clearDirectory(hostAssetsDir);

      stdout.writeln('Copying web build output to host assets...');
      await copyDirectoryContents(
        sourceDir: buildOutputDir,
        destinationDir: hostAssetsDir,
      );

      stdout.writeln('Host project: ${p.normalize(hostProjectDir.path)}');
      stdout.writeln('Running Flutter host (macOS)...');
      return _runFlutterRun(hostProjectDir);
    } on ManifestException catch (error) {
      stderr.writeln(error);
      return 2;
    } on FileSystemException catch (error) {
      stderr.writeln(error.message);
      return 2;
    }
  }

  Future<int> _runFlutterBuild(Directory uiDir) async {
    final process = await Process.start(
      'flutter',
      const ['build', 'web'],
      workingDirectory: uiDir.path,
      runInShell: true,
    );

    await stdout.addStream(process.stdout);
    await stderr.addStream(process.stderr);
    return process.exitCode;
  }

  Future<int> _runFlutterRun(Directory hostDir) async {
    final process = await Process.start(
      'flutter',
      const ['run', '-d', 'macos'],
      workingDirectory: hostDir.path,
      runInShell: true,
    );

    await stdout.addStream(process.stdout);
    await stderr.addStream(process.stderr);
    return process.exitCode;
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
