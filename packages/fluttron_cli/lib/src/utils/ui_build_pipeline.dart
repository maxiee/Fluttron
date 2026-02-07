import 'dart:io';

import 'package:fluttron_shared/fluttron_shared.dart';
import 'package:path/path.dart' as p;

import 'file_ops.dart';
import 'frontend_builder.dart';

typedef DirectoryClearFn = Future<void> Function(Directory directory);
typedef DirectoryCopyFn =
    Future<void> Function({
      required Directory sourceDir,
      required Directory destinationDir,
    });

class UiBuildPipeline {
  UiBuildPipeline({
    FrontendBuildStep? frontendBuilder,
    ProcessCommandRunner? commandRunner,
    DirectoryClearFn? clearDirectoryFn,
    DirectoryCopyFn? copyDirectoryFn,
    LogWriter? writeOut,
    LogWriter? writeErr,
  }) : _writeOut = writeOut ?? _defaultStdoutWriter,
       _writeErr = writeErr ?? _defaultStderrWriter,
       _commandRunner = commandRunner ?? defaultProcessCommandRunner,
       _clearDirectory = clearDirectoryFn ?? clearDirectory,
       _copyDirectoryContents = copyDirectoryFn ?? copyDirectoryContents {
    _frontendBuilder =
        frontendBuilder ??
        FrontendBuilder(commandRunner: _commandRunner, writeOut: _writeOut);
  }

  final LogWriter _writeOut;
  final LogWriter _writeErr;
  final ProcessCommandRunner _commandRunner;
  final DirectoryClearFn _clearDirectory;
  final DirectoryCopyFn _copyDirectoryContents;
  late final FrontendBuildStep _frontendBuilder;

  static void _defaultStdoutWriter(String message) => stdout.writeln(message);
  static void _defaultStderrWriter(String message) => stderr.writeln(message);

  Future<int> build({
    required Directory projectDir,
    required String manifestPath,
    required FluttronManifest manifest,
  }) async {
    final uiDir = Directory(
      p.join(projectDir.path, manifest.entry.uiProjectPath),
    );
    if (!uiDir.existsSync()) {
      _writeErr('UI project not found: ${p.normalize(uiDir.path)}');
      return 2;
    }

    final hostAssetsDir = Directory(
      p.join(projectDir.path, manifest.entry.hostAssetPath),
    );
    if (!hostAssetsDir.existsSync()) {
      _writeErr(
        'Host assets directory not found: ${p.normalize(hostAssetsDir.path)}',
      );
      return 2;
    }

    _writeOut('Manifest: ${p.normalize(manifestPath)}');
    _writeOut('UI project: ${p.normalize(uiDir.path)}');
    _writeOut('Host assets: ${p.normalize(hostAssetsDir.path)}');

    try {
      final frontendResult = await _frontendBuilder.build(uiDir);
      if (frontendResult.status == FrontendBuildStatus.skipped) {
        _writeOut('Frontend build skipped: ${frontendResult.reason}');
      }
    } on FrontendBuildException catch (error) {
      _writeErr(error.message);
      return error.exitCode;
    }

    _writeOut('Building Flutter Web...');
    final flutterBuild = await _commandRunner(
      'flutter',
      const ['build', 'web'],
      workingDirectory: uiDir.path,
      streamOutput: true,
    );
    if (!flutterBuild.isSuccess) {
      _writeErr(
        'Flutter build failed with exit code ${flutterBuild.exitCode}.',
      );
      return flutterBuild.exitCode;
    }

    final buildOutputDir = Directory(p.join(uiDir.path, 'build', 'web'));
    if (!buildOutputDir.existsSync()) {
      _writeErr(
        'Flutter build output not found: ${p.normalize(buildOutputDir.path)}',
      );
      return 2;
    }

    final indexFile = File(p.join(buildOutputDir.path, manifest.entry.index));
    if (!indexFile.existsSync()) {
      _writeErr('Entry file not found: ${p.normalize(indexFile.path)}');
      return 2;
    }

    _writeOut('Clearing host assets directory...');
    await _clearDirectory(hostAssetsDir);

    _writeOut('Copying web build output to host assets...');
    await _copyDirectoryContents(
      sourceDir: buildOutputDir,
      destinationDir: hostAssetsDir,
    );

    _writeOut('Build complete.');
    return 0;
  }
}
