import 'dart:io';

import 'package:fluttron_shared/fluttron_shared.dart';
import 'package:path/path.dart' as p;

import 'file_ops.dart';
import 'frontend_builder.dart';
import 'host_pubspec_updater.dart';
import 'html_injector.dart';
import 'js_asset_validator.dart';
import 'registration_generator.dart';
import 'web_package_collector.dart';
import 'web_package_discovery.dart';
import 'web_package_manifest.dart';

typedef DirectoryClearFn = Future<void> Function(Directory directory);
typedef DirectoryCopyFn =
    Future<void> Function({
      required Directory sourceDir,
      required Directory destinationDir,
    });

/// Function type for discovering web packages.
typedef WebPackageDiscoveryFn =
    Future<List<WebPackageManifest>> Function(Directory uiProjectDir);

/// Function type for collecting web package assets.
typedef WebPackageCollectFn =
    Future<CollectionResult> Function({
      required Directory buildOutputDir,
      required List<WebPackageManifest> manifests,
    });

/// Function type for injecting HTML assets.
typedef HtmlInjectFn =
    Future<InjectionResult> Function({
      required File indexHtml,
      required CollectionResult collectionResult,
    });

/// Function type for generating registration code.
typedef RegistrationGenerateFn =
    Future<RegistrationResult> Function({
      required Directory uiProjectDir,
      required List<WebPackageManifest> packages,
      String? outputDir,
    });

class UiBuildPipeline {
  UiBuildPipeline({
    FrontendBuildStep? frontendBuilder,
    ProcessCommandRunner? commandRunner,
    DirectoryClearFn? clearDirectoryFn,
    DirectoryCopyFn? copyDirectoryFn,
    JsAssetValidator? jsAssetValidator,
    WebPackageDiscoveryFn? webPackageDiscoveryFn,
    WebPackageCollectFn? webPackageCollectFn,
    HtmlInjectFn? htmlInjectFn,
    RegistrationGenerateFn? registrationGenerateFn,
    LogWriter? writeOut,
    LogWriter? writeErr,
  }) : _writeOut = writeOut ?? _defaultStdoutWriter,
       _writeErr = writeErr ?? _defaultStderrWriter,
       _commandRunner = commandRunner ?? defaultProcessCommandRunner,
       _clearDirectory = clearDirectoryFn ?? clearDirectory,
       _copyDirectoryContents = copyDirectoryFn ?? copyDirectoryContents,
       _jsAssetValidator = jsAssetValidator ?? const JsAssetValidator(),
       _webPackageDiscovery =
           webPackageDiscoveryFn ?? _defaultWebPackageDiscovery,
       _webPackageCollect = webPackageCollectFn ?? _defaultWebPackageCollect,
       _htmlInject = htmlInjectFn ?? _defaultHtmlInject,
       _registrationGenerate =
           registrationGenerateFn ?? _defaultRegistrationGenerate {
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
  final WebPackageDiscoveryFn _webPackageDiscovery;
  final WebPackageCollectFn _webPackageCollect;
  final HtmlInjectFn _htmlInject;
  final RegistrationGenerateFn _registrationGenerate;
  late final FrontendBuildStep _frontendBuilder;

  static void _defaultStdoutWriter(String message) => stdout.writeln(message);
  static void _defaultStderrWriter(String message) => stderr.writeln(message);

  static Future<List<WebPackageManifest>> _defaultWebPackageDiscovery(
    Directory uiProjectDir,
  ) {
    final discovery = WebPackageDiscovery();
    return discovery.discover(uiProjectDir);
  }

  static Future<CollectionResult> _defaultWebPackageCollect({
    required Directory buildOutputDir,
    required List<WebPackageManifest> manifests,
  }) {
    final collector = WebPackageCollector();
    return collector.collect(
      buildOutputDir: buildOutputDir,
      manifests: manifests,
    );
  }

  static Future<InjectionResult> _defaultHtmlInject({
    required File indexHtml,
    required CollectionResult collectionResult,
  }) {
    final injector = HtmlInjector();
    return injector.inject(
      indexHtml: indexHtml,
      collectionResult: collectionResult,
    );
  }

  static Future<RegistrationResult> _defaultRegistrationGenerate({
    required Directory uiProjectDir,
    required List<WebPackageManifest> packages,
    String? outputDir,
  }) {
    final generator = RegistrationGenerator();
    return generator.generate(
      uiProjectDir: uiProjectDir,
      packages: packages,
      outputDir: outputDir,
    );
  }

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

    // Step 1: Frontend build (pnpm + esbuild)
    try {
      final frontendResult = await _frontendBuilder.build(uiDir);
      if (frontendResult.status == FrontendBuildStatus.skipped) {
        _writeOut('Frontend build skipped: ${frontendResult.reason}');
      }
    } on FrontendBuildException catch (error) {
      _writeErr(error.message);
      return error.exitCode;
    }

    // Step 2: Collect JS script assets from source index.html
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

    // Step 3: Validate source JS assets
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

    // Step 4: Web Package Discovery
    List<WebPackageManifest> webPackages = [];
    try {
      _writeOut('Discovering web packages...');
      webPackages = await _webPackageDiscovery(uiDir);
      if (webPackages.isNotEmpty) {
        _writeOut('Found ${webPackages.length} web package(s):');
        for (final pkg in webPackages) {
          _writeOut('  - ${pkg.packageName ?? "unknown"}');
        }
      } else {
        _writeOut('No web packages found.');
      }
    } on WebPackageDiscoveryException catch (error) {
      _writeErr('Web package discovery failed: ${error.message}');
      return 2;
    }

    // Step 5: Generate registration code (before flutter build)
    try {
      _writeOut('Generating web package registrations...');
      final registrationResult = await _registrationGenerate(
        uiProjectDir: uiDir,
        packages: webPackages,
      );
      if (registrationResult.hasGenerated) {
        _writeOut(
          'Generated ${registrationResult.factoryCount} registration(s) from '
          '${registrationResult.packageCount} package(s).',
        );
      } else {
        _writeOut('No web package registrations to generate.');
      }
    } on RegistrationGeneratorException catch (error) {
      _writeErr('Registration generation failed: ${error.message}');
      return 2;
    }

    // Step 6: Flutter build web
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

    // Step 7: Collect web package assets (if any packages found)
    CollectionResult? collectionResult;
    if (webPackages.isNotEmpty) {
      try {
        _writeOut('Collecting web package assets...');
        collectionResult = await _webPackageCollect(
          buildOutputDir: buildOutputDir,
          manifests: webPackages,
        );
        _writeOut(
          'Collected ${collectionResult.assets.length} asset(s) from '
          '${collectionResult.packages} package(s).',
        );
      } on WebPackageCollectorException catch (error) {
        _writeErr('Web package collection failed: ${error.message}');
        return 2;
      }
    }

    // Step 8: Inject HTML assets (if any assets collected)
    if (collectionResult != null && collectionResult.hasAssets) {
      try {
        _writeOut('Injecting web package assets into HTML...');
        final injectionResult = await _htmlInject(
          indexHtml: indexFile,
          collectionResult: collectionResult,
        );
        _writeOut(
          'Injected ${injectionResult.injectedJsCount} JS and '
          '${injectionResult.injectedCssCount} CSS reference(s).',
        );
      } on HtmlInjectorException catch (error) {
        _writeErr('HTML injection failed: ${error.message}');
        return 2;
      }
    }

    // Step 9: Re-collect JS assets from build index (includes injected package scripts)
    late final List<JsScriptAsset> buildScriptAssets;
    try {
      buildScriptAssets = _jsAssetValidator.collectLocalScriptAssets(
        indexFile: indexFile,
        webRootDir: buildOutputDir,
      );
    } on JsAssetValidationException catch (error) {
      _writeErr(error.message);
      return 2;
    }

    // Step 10: Validate build output JS assets
    final buildAssetLabel = p.normalize(
      p.join(manifest.entry.uiProjectPath, 'build', 'web'),
    );
    if (!_validateJsAssets(
      stageLabel: buildAssetLabel,
      rootDir: buildOutputDir,
      assets: buildScriptAssets,
    )) {
      return 2;
    }

    // Step 11: Clear and copy to host assets
    _writeOut('Clearing host assets directory...');
    await _clearDirectory(hostAssetsDir);

    _writeOut('Copying web build output to host assets...');
    await _copyDirectoryContents(
      sourceDir: buildOutputDir,
      destinationDir: hostAssetsDir,
    );

    // Step 12: Update host pubspec.yaml with web package asset declarations
    if (webPackages.isNotEmpty) {
      final packageNames = webPackages
          .map((pkg) => pkg.packageName)
          .whereType<String>()
          .toList();

      if (packageNames.isNotEmpty) {
        // hostAssetsDir is like 'host/assets/www', so we need to go up two levels to get 'host'
        final hostDir = hostAssetsDir.parent.parent;
        final hostPubspecFile = File(p.join(hostDir.path, 'pubspec.yaml'));

        if (hostPubspecFile.existsSync()) {
          try {
            final updater = HostPubspecUpdater();
            final updated = updater.updateSync(
              hostPubspecFile: hostPubspecFile,
              packageNames: packageNames,
            );

            if (updated) {
              _writeOut(
                'Updated host pubspec.yaml with web package asset declarations.\n'
                'Please run "flutter pub get" in the host directory to apply changes.',
              );
            }
          } on HostPubspecUpdaterException catch (error) {
            _writeErr(
              'Warning: Failed to update host pubspec.yaml: ${error.message}',
            );
            _writeErr(
              'You may need to manually add asset declarations for web packages.',
            );
          }
        }
      }
    }

    // Step 13: Validate host assets
    final hostAssetLabel = p.normalize(manifest.entry.hostAssetPath);
    if (!_validateJsAssets(
      stageLabel: hostAssetLabel,
      rootDir: hostAssetsDir,
      assets: buildScriptAssets,
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
