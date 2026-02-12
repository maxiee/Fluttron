import 'dart:io';

import 'package:fluttron_cli/src/utils/web_package_collector.dart';
import 'package:fluttron_cli/src/utils/web_package_manifest.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync(
      'web_package_collector_test_',
    );
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('CollectedAsset', () {
    test('toString contains package name and relative path', () {
      final asset = CollectedAsset(
        packageName: 'my_package',
        relativePath: 'web/ext/main.js',
        sourcePath: '/source/main.js',
        destinationPath: '/dest/main.js',
        type: AssetType.js,
      );

      expect(asset.toString(), contains('my_package'));
      expect(asset.toString(), contains('web/ext/main.js'));
    });
  });

  group('CollectionResult', () {
    test('hasAssets returns false for empty assets', () {
      final result = CollectionResult(
        packages: 0,
        assets: [],
        skippedPackages: [],
      );

      expect(result.hasAssets, isFalse);
    });

    test('hasAssets returns true when assets exist', () {
      final result = CollectionResult(
        packages: 1,
        assets: [
          CollectedAsset(
            packageName: 'pkg',
            relativePath: 'web/ext/main.js',
            sourcePath: '/s/main.js',
            destinationPath: '/d/main.js',
            type: AssetType.js,
          ),
        ],
        skippedPackages: [],
      );

      expect(result.hasAssets, isTrue);
    });

    test('jsAssetPaths returns correct paths', () {
      final result = CollectionResult(
        packages: 1,
        assets: [
          CollectedAsset(
            packageName: 'my_editor',
            relativePath: 'web/ext/main.js',
            sourcePath: '/s/main.js',
            destinationPath: '/dest/ext/packages/my_editor/main.js',
            type: AssetType.js,
          ),
          CollectedAsset(
            packageName: 'my_editor',
            relativePath: 'web/ext/style.css',
            sourcePath: '/s/style.css',
            destinationPath: '/dest/ext/packages/my_editor/style.css',
            type: AssetType.css,
          ),
        ],
        skippedPackages: [],
      );

      expect(result.jsAssetPaths, hasLength(1));
      expect(result.jsAssetPaths[0], contains('my_editor'));
      expect(result.jsAssetPaths[0], contains('.js'));
    });

    test('cssAssetPaths returns correct paths', () {
      final result = CollectionResult(
        packages: 1,
        assets: [
          CollectedAsset(
            packageName: 'pkg',
            relativePath: 'web/ext/main.js',
            sourcePath: '/s/main.js',
            destinationPath: '/d/main.js',
            type: AssetType.js,
          ),
          CollectedAsset(
            packageName: 'pkg',
            relativePath: 'web/ext/theme.css',
            sourcePath: '/s/theme.css',
            destinationPath: '/d/theme.css',
            type: AssetType.css,
          ),
        ],
        skippedPackages: [],
      );

      expect(result.cssAssetPaths, hasLength(1));
      expect(result.cssAssetPaths[0], contains('.css'));
    });
  });

  group('WebPackageCollector', () {
    late Directory buildOutputDir;
    late Directory packageDir;

    setUp(() {
      buildOutputDir = Directory(p.join(tempDir.path, 'build', 'web'))
        ..createSync(recursive: true);
      packageDir = Directory(p.join(tempDir.path, 'packages', 'my_editor'))
        ..createSync(recursive: true);
    });

    WebPackageManifest createManifest({
      required String packageName,
      required String rootPath,
      List<String>? cssPaths,
    }) {
      return WebPackageManifest(
        version: '1',
        viewFactories: [
          ViewFactory(
            type: 'my_editor.view',
            jsFactoryName: 'fluttronCreateMyEditorViewView',
          ),
        ],
        assets: Assets(js: ['web/ext/main.js'], css: cssPaths),
        packageName: packageName,
        rootPath: rootPath,
      );
    }

    void writePackageAssets(Directory pkgDir, {bool includeCss = false}) {
      final extDir = Directory(p.join(pkgDir.path, 'web', 'ext'))
        ..createSync(recursive: true);
      File(p.join(extDir.path, 'main.js')).writeAsStringSync('// JS bundle');
      if (includeCss) {
        File(p.join(extDir.path, 'main.css')).writeAsStringSync('/* CSS */');
      }
    }

    test('collects JS assets from single package', () async {
      writePackageAssets(packageDir);
      final manifest = createManifest(
        packageName: 'my_editor',
        rootPath: packageDir.path,
      );

      final collector = WebPackageCollector();
      final result = await collector.collect(
        buildOutputDir: buildOutputDir,
        manifests: [manifest],
      );

      expect(result.packages, equals(1));
      expect(result.assets, hasLength(1));
      expect(result.assets[0].type, equals(AssetType.js));
      expect(result.assets[0].packageName, equals('my_editor'));

      // Verify file was copied
      final destFile = File(
        p.join(buildOutputDir.path, 'ext', 'packages', 'my_editor', 'main.js'),
      );
      expect(destFile.existsSync(), isTrue);
      expect(destFile.readAsStringSync(), equals('// JS bundle'));
    });

    test('collects JS and CSS assets from single package', () async {
      writePackageAssets(packageDir, includeCss: true);
      final manifest = createManifest(
        packageName: 'my_editor',
        rootPath: packageDir.path,
        cssPaths: ['web/ext/main.css'],
      );

      final collector = WebPackageCollector();
      final result = await collector.collect(
        buildOutputDir: buildOutputDir,
        manifests: [manifest],
      );

      expect(result.assets, hasLength(2));
      expect(result.assets.where((a) => a.type == AssetType.js), hasLength(1));
      expect(result.assets.where((a) => a.type == AssetType.css), hasLength(1));

      // Verify both files were copied
      final jsFile = File(
        p.join(buildOutputDir.path, 'ext', 'packages', 'my_editor', 'main.js'),
      );
      final cssFile = File(
        p.join(buildOutputDir.path, 'ext', 'packages', 'my_editor', 'main.css'),
      );
      expect(jsFile.existsSync(), isTrue);
      expect(cssFile.existsSync(), isTrue);
    });

    test('collects assets from multiple packages', () async {
      final packageA = Directory(p.join(tempDir.path, 'packages', 'editor'))
        ..createSync(recursive: true);
      final packageB = Directory(p.join(tempDir.path, 'packages', 'chart'))
        ..createSync(recursive: true);

      writePackageAssets(packageA);
      writePackageAssets(packageB);

      final manifestA = createManifest(
        packageName: 'editor',
        rootPath: packageA.path,
      );
      final manifestB = createManifest(
        packageName: 'chart',
        rootPath: packageB.path,
      );

      final collector = WebPackageCollector();
      final result = await collector.collect(
        buildOutputDir: buildOutputDir,
        manifests: [manifestA, manifestB],
      );

      expect(result.packages, equals(2));
      expect(result.assets, hasLength(2));

      // Verify directories for both packages
      final editorDir = Directory(
        p.join(buildOutputDir.path, 'ext', 'packages', 'editor'),
      );
      final chartDir = Directory(
        p.join(buildOutputDir.path, 'ext', 'packages', 'chart'),
      );
      expect(editorDir.existsSync(), isTrue);
      expect(chartDir.existsSync(), isTrue);
    });

    test('skips package without rootPath', () async {
      writePackageAssets(packageDir);
      final validManifest = createManifest(
        packageName: 'my_editor',
        rootPath: packageDir.path,
      );
      final invalidManifest = WebPackageManifest(
        version: '1',
        viewFactories: [
          ViewFactory(
            type: 'broken.view',
            jsFactoryName: 'fluttronCreateBrokenViewView',
          ),
        ],
        assets: Assets(js: ['web/ext/main.js']),
        packageName: 'broken_package',
        rootPath: null, // Missing rootPath
      );

      final collector = WebPackageCollector();
      final result = await collector.collect(
        buildOutputDir: buildOutputDir,
        manifests: [validManifest, invalidManifest],
      );

      expect(result.packages, equals(1)); // Only valid one processed
      expect(result.skippedPackages, contains('broken_package'));
    });

    test('throws on missing JS asset file', () async {
      // Don't write assets - manifest points to non-existent files
      final manifest = createManifest(
        packageName: 'my_editor',
        rootPath: packageDir.path,
      );

      final collector = WebPackageCollector();

      expect(
        () => collector.collect(
          buildOutputDir: buildOutputDir,
          manifests: [manifest],
        ),
        throwsA(
          isA<WebPackageCollectorException>().having(
            (e) => e.message,
            'message',
            allOf(
              contains('Asset file not found'),
              contains('my_editor'),
              contains('pnpm run js:build'),
            ),
          ),
        ),
      );
    });

    test('throws on missing CSS asset file', () async {
      writePackageAssets(packageDir); // Only JS, no CSS
      final manifest = createManifest(
        packageName: 'my_editor',
        rootPath: packageDir.path,
        cssPaths: ['web/ext/main.css'], // CSS declared but not present
      );

      final collector = WebPackageCollector();

      expect(
        () => collector.collect(
          buildOutputDir: buildOutputDir,
          manifests: [manifest],
        ),
        throwsA(
          isA<WebPackageCollectorException>().having(
            (e) => e.message,
            'message',
            contains('Asset file not found'),
          ),
        ),
      );
    });

    test('collectSync works same as async collect', () {
      writePackageAssets(packageDir, includeCss: true);
      final manifest = createManifest(
        packageName: 'my_editor',
        rootPath: packageDir.path,
        cssPaths: ['web/ext/main.css'],
      );

      final collector = WebPackageCollector();
      final result = collector.collectSync(
        buildOutputDir: buildOutputDir,
        manifests: [manifest],
      );

      expect(result.packages, equals(1));
      expect(result.assets, hasLength(2));

      final jsFile = File(
        p.join(buildOutputDir.path, 'ext', 'packages', 'my_editor', 'main.js'),
      );
      final cssFile = File(
        p.join(buildOutputDir.path, 'ext', 'packages', 'my_editor', 'main.css'),
      );
      expect(jsFile.existsSync(), isTrue);
      expect(cssFile.existsSync(), isTrue);
    });

    test('creates destination directory recursively', () async {
      writePackageAssets(packageDir);
      final manifest = createManifest(
        packageName: 'my_editor',
        rootPath: packageDir.path,
      );

      // buildOutputDir exists but ext/packages doesn't
      final collector = WebPackageCollector();
      final result = await collector.collect(
        buildOutputDir: buildOutputDir,
        manifests: [manifest],
      );

      expect(result.packages, equals(1));

      final destDir = Directory(
        p.join(buildOutputDir.path, 'ext', 'packages', 'my_editor'),
      );
      expect(destDir.existsSync(), isTrue);
    });

    test('handles package names with underscores', () async {
      final pkgDir = Directory(
        p.join(tempDir.path, 'packages', 'my_editor_pkg'),
      )..createSync(recursive: true);
      writePackageAssets(pkgDir);

      final manifest = WebPackageManifest(
        version: '1',
        viewFactories: [
          ViewFactory(
            type: 'my_editor_pkg.view',
            jsFactoryName: 'fluttronCreateMyEditorPkgViewView',
          ),
        ],
        assets: Assets(js: ['web/ext/main.js']),
        packageName: 'my_editor_pkg',
        rootPath: pkgDir.path,
      );

      final collector = WebPackageCollector();
      final result = await collector.collect(
        buildOutputDir: buildOutputDir,
        manifests: [manifest],
      );

      expect(result.packages, equals(1));
      final destDir = Directory(
        p.join(buildOutputDir.path, 'ext', 'packages', 'my_editor_pkg'),
      );
      expect(destDir.existsSync(), isTrue);
    });
  });

  group('WebPackageCollector.validateAssets', () {
    late Directory packageDir;

    setUp(() {
      packageDir = Directory(p.join(tempDir.path, 'packages', 'test_pkg'))
        ..createSync(recursive: true);
    });

    WebPackageManifest createManifest({List<String>? cssPaths}) {
      return WebPackageManifest(
        version: '1',
        viewFactories: [
          ViewFactory(
            type: 'test.view',
            jsFactoryName: 'fluttronCreateTestViewView',
          ),
        ],
        assets: Assets(js: ['web/ext/main.js'], css: cssPaths),
        packageName: 'test_pkg',
        rootPath: packageDir.path,
      );
    }

    void writePackageAssets({bool includeCss = false}) {
      final extDir = Directory(p.join(packageDir.path, 'web', 'ext'))
        ..createSync(recursive: true);
      File(p.join(extDir.path, 'main.js')).writeAsStringSync('// JS');
      if (includeCss) {
        File(p.join(extDir.path, 'main.css')).writeAsStringSync('/* CSS */');
      }
    }

    test('returns empty list when all assets exist', () {
      writePackageAssets(includeCss: true);
      final manifest = createManifest(cssPaths: ['web/ext/main.css']);

      final collector = WebPackageCollector();
      final missing = collector.validateAssets(manifests: [manifest]);

      expect(missing, isEmpty);
    });

    test('returns missing JS asset path', () {
      // Don't write assets
      final manifest = createManifest();

      final collector = WebPackageCollector();
      final missing = collector.validateAssets(manifests: [manifest]);

      expect(missing, hasLength(1));
      expect(missing[0], contains('test_pkg'));
      expect(missing[0], contains('.js'));
    });

    test('returns missing CSS asset path', () {
      writePackageAssets(); // Only JS
      final manifest = createManifest(cssPaths: ['web/ext/main.css']);

      final collector = WebPackageCollector();
      final missing = collector.validateAssets(manifests: [manifest]);

      expect(missing, hasLength(1));
      expect(missing[0], contains('.css'));
    });

    test('skips manifest without rootPath', () {
      final manifest = WebPackageManifest(
        version: '1',
        viewFactories: [
          ViewFactory(
            type: 'broken.view',
            jsFactoryName: 'fluttronCreateBrokenViewView',
          ),
        ],
        assets: Assets(js: ['web/ext/main.js']),
        packageName: 'broken',
        rootPath: null,
      );

      final collector = WebPackageCollector();
      final missing = collector.validateAssets(manifests: [manifest]);

      expect(missing, isEmpty); // Skipped without error
    });

    test('returns all missing assets from multiple packages', () {
      final packageA = Directory(p.join(tempDir.path, 'packages', 'pkg_a'))
        ..createSync(recursive: true);
      final packageB = Directory(p.join(tempDir.path, 'packages', 'pkg_b'))
        ..createSync(recursive: true);

      // Only write assets for pkg_a
      final extDirA = Directory(p.join(packageA.path, 'web', 'ext'))
        ..createSync(recursive: true);
      File(p.join(extDirA.path, 'main.js')).writeAsStringSync('// JS');

      final manifestA = WebPackageManifest(
        version: '1',
        viewFactories: [
          ViewFactory(type: 'a.view', jsFactoryName: 'fluttronCreateAViewView'),
        ],
        assets: Assets(js: ['web/ext/main.js']),
        packageName: 'pkg_a',
        rootPath: packageA.path,
      );

      final manifestB = WebPackageManifest(
        version: '1',
        viewFactories: [
          ViewFactory(type: 'b.view', jsFactoryName: 'fluttronCreateBViewView'),
        ],
        assets: Assets(js: ['web/ext/main.js']),
        packageName: 'pkg_b',
        rootPath: packageB.path,
      );

      final collector = WebPackageCollector();
      final missing = collector.validateAssets(
        manifests: [manifestA, manifestB],
      );

      expect(missing, hasLength(1));
      expect(missing[0], contains('pkg_b'));
    });
  });
}
