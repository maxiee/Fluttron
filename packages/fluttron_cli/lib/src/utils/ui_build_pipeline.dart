import 'dart:io';

import 'package:fluttron_shared/fluttron_shared.dart';
import 'package:path/path.dart' as p;

import 'file_ops.dart';
import 'frontend_builder.dart';
import 'js_asset_validator.dart';

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
    JsAssetValidator? jsAssetValidator,
    LogWriter? writeOut,
    LogWriter? writeErr,
  }) : _writeOut = writeOut ?? _defaultStdoutWriter,
       _writeErr = writeErr ?? _defaultStderrWriter,
       _commandRunner = commandRunner ?? defaultProcessCommandRunner,
       _clearDirectory = clearDirectoryFn ?? clearDirectory,
       _copyDirectoryContents = copyDirectoryFn ?? copyDirectoryContents,
       _jsAssetValidator = jsAssetValidator ?? const JsAssetValidator() {
    _frontendBuilder =
        frontendBuilder ??
        FrontendBuilder(commandRunner: _commandRunner, writeOut: _writeOut);
  }

  final LogWriter _writeOut;
  final LogWriter _writeErr;
  final ProcessCommandRunner _commandRunner;
  final DirectoryClearFn _clearDirectory;
  final DirectoryCopyFn _copyDirectoryContents;
  final JsAssetValidator _jsAssetValidator;
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

    final sourceWebDir = Directory(p.join(uiDir.path, 'web'));
    final sourceIndexFile = File(
      p.join(sourceWebDir.path, manifest.entry.index),
    );
    late final List<JsScriptAsset> scriptAssets;
    try {
      scriptAssets = _jsAssetValidator.collectLocalScriptAssets(
        indexFile: sourceIndexFile,
        webRootDir: sourceWebDir,
      );
    } on JsAssetValidationException catch (error) {
      _writeErr(error.message);
      return 2;
    }

    final sourceAssetLabel = p.normalize(
      p.join(manifest.entry.uiProjectPath, 'web'),
    );
    final sourceAssets = scriptAssets.where(
      (asset) => !asset.isFlutterGenerated,
    );
    if (!_validateJsAssets(
      stageLabel: sourceAssetLabel,
      rootDir: sourceWebDir,
      assets: sourceAssets,
    )) {
      return 2;
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

    final buildAssetLabel = p.normalize(
      p.join(manifest.entry.uiProjectPath, 'build', 'web'),
    );
    if (!_validateJsAssets(
      stageLabel: buildAssetLabel,
      rootDir: buildOutputDir,
      assets: scriptAssets,
    )) {
      return 2;
    }

    _writeOut('Clearing host assets directory...');
    await _clearDirectory(hostAssetsDir);

    _writeOut('Copying web build output to host assets...');
    await _copyDirectoryContents(
      sourceDir: buildOutputDir,
      destinationDir: hostAssetsDir,
    );

    final hostAssetLabel = p.normalize(manifest.entry.hostAssetPath);
    if (!_validateJsAssets(
      stageLabel: hostAssetLabel,
      rootDir: hostAssetsDir,
      assets: scriptAssets,
    )) {
      return 2;
    }

    _writeOut('Build complete.');
    return 0;
  }

  bool _validateJsAssets({
    required String stageLabel,
    required Directory rootDir,
    required Iterable<JsScriptAsset> assets,
  }) {
    final assetList = assets.toList();
    if (assetList.isEmpty) {
      _writeOut('JS asset validation ($stageLabel): no local script assets.');
      return true;
    }

    final missingPaths = _jsAssetValidator.findMissingAssetPaths(
      rootDir: rootDir,
      assets: assetList,
    );
    if (missingPaths.isEmpty) {
      _writeOut(
        'JS asset validation ($stageLabel): ${assetList.length} file(s) OK.',
      );
      return true;
    }

    _writeErr(
      _buildMissingJsAssetsMessage(
        stageLabel: stageLabel,
        missingPaths: missingPaths,
      ),
    );
    return false;
  }

  String _buildMissingJsAssetsMessage({
    required String stageLabel,
    required List<String> missingPaths,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('JS asset validation failed at $stageLabel.');
    buffer.writeln('Missing files:');
    for (final missingPath in missingPaths) {
      buffer.writeln('- ${p.normalize(missingPath)}');
    }
    return buffer.toString().trimRight();
  }
}
