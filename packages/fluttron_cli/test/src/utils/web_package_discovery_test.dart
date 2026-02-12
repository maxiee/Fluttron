import 'dart:convert';
import 'dart:io';

import 'package:fluttron_cli/src/utils/web_package_discovery.dart';
import 'package:fluttron_cli/src/utils/web_package_manifest.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync(
      'web_package_discovery_test_',
    );
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('PackageConfigEntry', () {
    test('fromJson parses complete entry', () {
      final json = {
        'name': 'my_package',
        'rootUri': '../packages/my_package',
        'packageUri': 'lib/',
        'languageVersion': '3.0',
      };

      final entry = PackageConfigEntry.fromJson(json);

      expect(entry.name, equals('my_package'));
      expect(entry.rootUri, equals('../packages/my_package'));
      expect(entry.packageUri, equals('lib/'));
      expect(entry.languageVersion, equals('3.0'));
    });

    test('fromJson parses entry without languageVersion', () {
      final json = {
        'name': 'simple_package',
        'rootUri': 'file:///path/to/package',
        'packageUri': 'lib/',
      };

      final entry = PackageConfigEntry.fromJson(json);

      expect(entry.name, equals('simple_package'));
      expect(entry.languageVersion, isNull);
    });

    test('resolveRootPath handles relative path', () {
      final entry = PackageConfigEntry(
        name: 'test',
        rootUri: '../packages/test',
        packageUri: 'lib/',
      );

      final resolved = entry.resolveRootPath('/project/ui');

      expect(resolved, equals(p.normalize('/project/packages/test')));
    });

    test('resolveRootPath handles file:// URI', () {
      final entry = PackageConfigEntry(
        name: 'test',
        rootUri: 'file:///Users/test/.pub-cache/hosted/pub.dev/test-1.0.0',
        packageUri: 'lib/',
      );

      final resolved = entry.resolveRootPath('/any/project');

      expect(
        resolved,
        equals('/Users/test/.pub-cache/hosted/pub.dev/test-1.0.0'),
      );
    });

    test('resolveRootPath normalizes path with ..', () {
      final entry = PackageConfigEntry(
        name: 'test',
        rootUri: '../sibling/package',
        packageUri: 'lib/',
      );

      final resolved = entry.resolveRootPath('/project/ui');

      expect(resolved, equals(p.normalize('/project/sibling/package')));
    });
  });

  group('PackageConfig', () {
    test('fromJson parses complete config', () {
      final json = {
        'configVersion': 2,
        'packages': [
          {
            'name': 'package_a',
            'rootUri': '../packages/package_a',
            'packageUri': 'lib/',
          },
          {
            'name': 'package_b',
            'rootUri': 'file:///path/to/package_b',
            'packageUri': 'lib/',
            'languageVersion': '3.0',
          },
        ],
        'generator': 'pub',
        'generatorVersion': '3.10.0',
      };

      final config = PackageConfig.fromJson(json);

      expect(config.configVersion, equals(2));
      expect(config.packages, hasLength(2));
      expect(config.packages[0].name, equals('package_a'));
      expect(config.packages[1].name, equals('package_b'));
      expect(config.generator, equals('pub'));
      expect(config.generatorVersion, equals('3.10.0'));
    });
  });

  group('WebPackageDiscovery', () {
    late Directory uiDir;
    late Directory dartToolDir;

    setUp(() {
      uiDir = Directory(p.join(tempDir.path, 'ui'))..createSync();
      dartToolDir = Directory(p.join(uiDir.path, '.dart_tool'))..createSync();
    });

    void writePackageConfig(List<Map<String, dynamic>> packages) {
      final config = {
        'configVersion': 2,
        'packages': packages,
        'generator': 'test',
      };
      final configFile = File(p.join(dartToolDir.path, 'package_config.json'));
      configFile.writeAsStringSync(
        const JsonEncoder.withIndent('  ').convert(config),
      );
    }

    void writeWebPackageManifest(
      Directory packageDir, {
      required String type,
      required String jsFactoryName,
    }) {
      final manifest = {
        'version': '1',
        'viewFactories': [
          {'type': type, 'jsFactoryName': jsFactoryName},
        ],
        'assets': {
          'js': ['web/ext/main.js'],
        },
      };
      final manifestFile = File(
        p.join(packageDir.path, 'fluttron_web_package.json'),
      );
      manifestFile.writeAsStringSync(
        const JsonEncoder.withIndent('  ').convert(manifest),
      );
    }

    test('throws when package_config.json is missing', () {
      final discovery = WebPackageDiscovery();

      expect(
        () => discovery.discoverSync(uiDir),
        throwsA(
          isA<WebPackageDiscoveryException>().having(
            (e) => e.message,
            'message',
            allOf(
              contains('package_config.json not found'),
              contains('flutter pub get'),
            ),
          ),
        ),
      );
    });

    test('throws when package_config.json has invalid JSON', () {
      final configFile = File(p.join(dartToolDir.path, 'package_config.json'));
      configFile.writeAsStringSync('{ invalid json }');

      final discovery = WebPackageDiscovery();

      expect(
        () => discovery.discoverSync(uiDir),
        throwsA(
          isA<WebPackageDiscoveryException>().having(
            (e) => e.message,
            'message',
            contains('Invalid JSON'),
          ),
        ),
      );
    });

    test('throws when package_config.json is not a JSON object', () {
      final configFile = File(p.join(dartToolDir.path, 'package_config.json'));
      configFile.writeAsStringSync('[]');

      final discovery = WebPackageDiscovery();

      expect(
        () => discovery.discoverSync(uiDir),
        throwsA(
          isA<WebPackageDiscoveryException>().having(
            (e) => e.message,
            'message',
            contains('must be a JSON object'),
          ),
        ),
      );
    });

    test('returns empty list when no web packages exist', () {
      writePackageConfig([
        {
          'name': 'regular_package',
          'rootUri': 'file:///path/to/regular_package',
          'packageUri': 'lib/',
        },
      ]);

      final discovery = WebPackageDiscovery();
      final packages = discovery.discoverSync(uiDir);

      expect(packages, isEmpty);
    });

    test('discovers single web package with relative path', () {
      final packageDir = Directory(
        p.join(tempDir.path, 'packages', 'my_editor'),
      )..createSync(recursive: true);
      writeWebPackageManifest(
        packageDir,
        type: 'my_editor.view',
        jsFactoryName: 'fluttronCreateMyEditorViewView',
      );

      writePackageConfig([
        {
          'name': 'my_editor',
          'rootUri': '../packages/my_editor',
          'packageUri': 'lib/',
        },
      ]);

      final discovery = WebPackageDiscovery();
      final packages = discovery.discoverSync(uiDir);

      expect(packages, hasLength(1));
      expect(packages[0].packageName, equals('my_editor'));
      expect(packages[0].rootPath, equals(packageDir.path));
      expect(packages[0].viewFactories, hasLength(1));
      expect(packages[0].viewFactories[0].type, equals('my_editor.view'));
    });

    test('discovers single web package with file:// URI', () {
      final packageDir = Directory(p.join(tempDir.path, 'cached_package'))
        ..createSync();
      writeWebPackageManifest(
        packageDir,
        type: 'cached.view',
        jsFactoryName: 'fluttronCreateCachedViewView',
      );

      writePackageConfig([
        {
          'name': 'cached_package',
          'rootUri': Uri.file(packageDir.path).toString(),
          'packageUri': 'lib/',
        },
      ]);

      final discovery = WebPackageDiscovery();
      final packages = discovery.discoverSync(uiDir);

      expect(packages, hasLength(1));
      expect(packages[0].packageName, equals('cached_package'));
      expect(packages[0].rootPath, equals(packageDir.path));
    });

    test('discovers multiple web packages', () {
      final packageA = Directory(p.join(tempDir.path, 'packages', 'editor'))
        ..createSync(recursive: true);
      writeWebPackageManifest(
        packageA,
        type: 'editor.view',
        jsFactoryName: 'fluttronCreateEditorViewView',
      );

      final packageB = Directory(p.join(tempDir.path, 'packages', 'chart'))
        ..createSync(recursive: true);
      writeWebPackageManifest(
        packageB,
        type: 'chart.bar',
        jsFactoryName: 'fluttronCreateChartBarView',
      );

      writePackageConfig([
        {
          'name': 'editor',
          'rootUri': '../packages/editor',
          'packageUri': 'lib/',
        },
        {'name': 'chart', 'rootUri': '../packages/chart', 'packageUri': 'lib/'},
        {
          'name': 'regular_package',
          'rootUri': 'file:///path/to/regular',
          'packageUri': 'lib/',
        },
      ]);

      final discovery = WebPackageDiscovery();
      final packages = discovery.discoverSync(uiDir);

      expect(packages, hasLength(2));
      final names = packages.map((p) => p.packageName).toList();
      expect(names, containsAll(['editor', 'chart']));
    });

    test('skips package with invalid manifest', () {
      final packageDir = Directory(p.join(tempDir.path, 'packages', 'broken'))
        ..createSync(recursive: true);
      // Write invalid manifest (missing required fields)
      final manifestFile = File(
        p.join(packageDir.path, 'fluttron_web_package.json'),
      );
      manifestFile.writeAsStringSync('{"version": "1"}');

      final validPackage = Directory(p.join(tempDir.path, 'packages', 'valid'))
        ..createSync(recursive: true);
      writeWebPackageManifest(
        validPackage,
        type: 'valid.view',
        jsFactoryName: 'fluttronCreateValidViewView',
      );

      writePackageConfig([
        {
          'name': 'broken',
          'rootUri': '../packages/broken',
          'packageUri': 'lib/',
        },
        {'name': 'valid', 'rootUri': '../packages/valid', 'packageUri': 'lib/'},
      ]);

      final discovery = WebPackageDiscovery();
      final packages = discovery.discoverSync(uiDir);

      // Invalid manifest should be skipped by tryLoad
      expect(packages, hasLength(1));
      expect(packages[0].packageName, equals('valid'));
    });

    test('handles deeply nested relative paths', () {
      // Create package at same level as ui directory
      final packageDir = Directory(
        p.join(tempDir.path, 'packages', 'my_package'),
      )..createSync(recursive: true);
      writeWebPackageManifest(
        packageDir,
        type: 'nested.view',
        jsFactoryName: 'fluttronCreateNestedViewView',
      );

      writePackageConfig([
        {
          'name': 'my_package',
          'rootUri': '../packages/my_package',
          'packageUri': 'lib/',
        },
      ]);

      final discovery = WebPackageDiscovery();
      final packages = discovery.discoverSync(uiDir);

      expect(packages, hasLength(1));
      expect(packages[0].packageName, equals('my_package'));
    });

    test('async discover works same as sync', () async {
      final packageDir = Directory(
        p.join(tempDir.path, 'packages', 'async_test'),
      )..createSync(recursive: true);
      writeWebPackageManifest(
        packageDir,
        type: 'async.view',
        jsFactoryName: 'fluttronCreateAsyncViewView',
      );

      writePackageConfig([
        {
          'name': 'async_test',
          'rootUri': '../packages/async_test',
          'packageUri': 'lib/',
        },
      ]);

      final discovery = WebPackageDiscovery();
      final packages = await discovery.discover(uiDir);

      expect(packages, hasLength(1));
      expect(packages[0].packageName, equals('async_test'));
    });

    test('handles git dependency style path', () {
      // Git dependencies after pub get are resolved to local cache paths
      final packageDir = Directory(
        p.join(tempDir.path, 'git_cache', 'git_package'),
      )..createSync(recursive: true);
      writeWebPackageManifest(
        packageDir,
        type: 'git.view',
        jsFactoryName: 'fluttronCreateGitViewView',
      );

      writePackageConfig([
        {
          'name': 'git_package',
          'rootUri': Uri.file(packageDir.path).toString(),
          'packageUri': 'lib/',
        },
      ]);

      final discovery = WebPackageDiscovery();
      final packages = discovery.discoverSync(uiDir);

      expect(packages, hasLength(1));
      expect(packages[0].packageName, equals('git_package'));
    });

    test('handles hosted dependency style path', () {
      // Hosted dependencies use file:// URIs to pub cache
      final packageDir = Directory(
        p.join(
          tempDir.path,
          'pub-cache',
          'hosted',
          'pub.dev',
          'hosted_pkg-1.0.0',
        ),
      )..createSync(recursive: true);
      writeWebPackageManifest(
        packageDir,
        type: 'hosted.view',
        jsFactoryName: 'fluttronCreateHostedViewView',
      );

      writePackageConfig([
        {
          'name': 'hosted_pkg',
          'rootUri': Uri.file(packageDir.path).toString(),
          'packageUri': 'lib/',
        },
      ]);

      final discovery = WebPackageDiscovery();
      final packages = discovery.discoverSync(uiDir);

      expect(packages, hasLength(1));
      expect(packages[0].packageName, equals('hosted_pkg'));
    });

    test('manifest has correct packageName and rootPath', () {
      final packageDir = Directory(
        p.join(tempDir.path, 'packages', 'metadata_test'),
      )..createSync(recursive: true);
      writeWebPackageManifest(
        packageDir,
        type: 'metadata.view',
        jsFactoryName: 'fluttronCreateMetadataViewView',
      );

      writePackageConfig([
        {
          'name': 'metadata_test',
          'rootUri': '../packages/metadata_test',
          'packageUri': 'lib/',
        },
      ]);

      final discovery = WebPackageDiscovery();
      final packages = discovery.discoverSync(uiDir);

      expect(packages, hasLength(1));
      final manifest = packages[0];
      expect(manifest.packageName, equals('metadata_test'));
      expect(manifest.rootPath, equals(packageDir.path));
      // Original manifest fields should be preserved
      expect(manifest.version, equals('1'));
      expect(manifest.viewFactories, hasLength(1));
    });
  });
}
