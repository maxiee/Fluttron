import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;

import '../utils/manifest_loader.dart';
import '../utils/ui_build_pipeline.dart';

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
    argParser.addOption(
      'device',
      abbr: 'd',
      help: 'Flutter device id or name (optional).',
      valueHelp: 'device',
    );
    argParser.addFlag(
      'build',
      help: 'Build the UI before running the host.',
      defaultsTo: true,
      negatable: true,
    );
  }

  @override
  Future<int> run() async {
    final projectPath = argResults?['project'] as String? ?? '.';
    final device = (argResults?['device'] as String?)?.trim();
    final shouldBuild = argResults?['build'] as bool? ?? true;
    final projectDir = Directory(p.normalize(projectPath));

    try {
      final loaded = ManifestLoader.load(projectDir);
      final manifest = loaded.manifest;
      final hostAssetsDir = Directory(
        p.join(projectDir.path, manifest.entry.hostAssetPath),
      );
      if (shouldBuild) {
        final pipeline = UiBuildPipeline();
        final buildExitCode = await pipeline.build(
          projectDir: projectDir,
          manifestPath: loaded.manifestPath,
          manifest: manifest,
        );
        if (buildExitCode != 0) {
          return buildExitCode;
        }
      } else {
        if (!hostAssetsDir.existsSync()) {
          stderr.writeln(
            'Host assets directory not found: ${p.normalize(hostAssetsDir.path)}',
          );
          return 2;
        }
        stdout.writeln('Manifest: ${p.normalize(loaded.manifestPath)}');
        stdout.writeln('Host assets: ${p.normalize(hostAssetsDir.path)}');
        final indexFile = File(
          p.join(hostAssetsDir.path, manifest.entry.index),
        );
        if (!indexFile.existsSync()) {
          stderr.writeln(
            'Entry file not found in host assets: ${p.normalize(indexFile.path)}',
          );
          return 2;
        }
      }

      final hostProjectDir = _findFlutterProjectRoot(hostAssetsDir);
      if (hostProjectDir == null) {
        stderr.writeln(
          'Unable to locate host Flutter project (pubspec.yaml not found).',
        );
        return 2;
      }

      stdout.writeln('Host project: ${p.normalize(hostProjectDir.path)}');
      final deviceLabel = device == null || device.isEmpty ? 'default' : device;
      stdout.writeln('Running Flutter host (device: $deviceLabel)...');
      return _runFlutterRun(hostProjectDir, device: device);
    } on ManifestException catch (error) {
      stderr.writeln(error);
      return 2;
    } on FileSystemException catch (error) {
      stderr.writeln(error.message);
      return 2;
    }
  }

  Future<int> _runFlutterRun(Directory hostDir, {String? device}) async {
    final args = <String>['run'];
    if (device != null && device.isNotEmpty) {
      args.addAll(['-d', device]);
    } else {
      args.addAll(const ['-d', 'macos']);
    }
    final process = await Process.start(
      'flutter',
      args,
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
