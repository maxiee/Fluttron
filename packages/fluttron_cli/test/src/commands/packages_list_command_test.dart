import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'package:fluttron_cli/fluttron_cli.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('packages_list_test_');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('packages list command', () {
    test('returns error when fluttron.json is missing', () async {
      final exitCode = await runCli(['packages', 'list', '-p', tempDir.path]);
      expect(exitCode, equals(2));
    });

    test('returns error when UI project is missing', () async {
      // Create fluttron.json without UI directory
      final manifestFile = File(p.join(tempDir.path, 'fluttron.json'));
      await manifestFile.writeAsString(
        jsonEncode({
          'name': 'test_app',
          'version': '1.0.0',
          'entry': {
            'uiProjectPath': 'ui',
            'hostAssetPath': 'host/assets/www',
            'index': 'index.html',
          },
          'window': {'title': 'Test App', 'width': 800, 'height': 600},
        }),
      );

      final exitCode = await runCli(['packages', 'list', '-p', tempDir.path]);
      expect(exitCode, equals(2));
    });

    test(
      'shows "no web packages" when package_config.json is missing',
      () async {
        // Create minimal project structure
        await _createMinimalProject(tempDir);

        // Run command without package_config.json
        final exitCode = await runCli(['packages', 'list', '-p', tempDir.path]);
        expect(
          exitCode,
          equals(2),
        ); // Error because package_config.json missing
      },
    );

    test('shows "no web packages" when no web package dependencies', () async {
      // Create minimal project structure
      await _createMinimalProject(tempDir);

      // Create package_config.json without web packages
      final dartToolDir = Directory(p.join(tempDir.path, 'ui', '.dart_tool'));
      await dartToolDir.create(recursive: true);
      final packageConfigFile = File(
        p.join(dartToolDir.path, 'package_config.json'),
      );
      await packageConfigFile.writeAsString(
        jsonEncode({
          'configVersion': 2,
          'packages': [
            {
              'name': 'fluttron_ui',
              'rootUri': '../../packages/fluttron_ui',
              'packageUri': 'lib/',
            },
          ],
        }),
      );

      final exitCode = await runCli(['packages', 'list', '-p', tempDir.path]);
      expect(exitCode, equals(0));
    });

    test('lists web packages when found', () async {
      // Create minimal project structure
      await _createMinimalProject(tempDir);

      // Create a mock web package
      final webPackageDir = Directory(p.join(tempDir.path, 'mock_web_package'));
      await webPackageDir.create(recursive: true);

      // Create pubspec.yaml for web package
      final pubspecFile = File(p.join(webPackageDir.path, 'pubspec.yaml'));
      await pubspecFile.writeAsString('''
name: mock_web_package
version: 1.2.3
description: A mock web package
''');

      // Create manifest for web package
      final manifestFile = File(
        p.join(webPackageDir.path, 'fluttron_web_package.json'),
      );
      await manifestFile.writeAsString(
        jsonEncode({
          'version': '1',
          'viewFactories': [
            {
              'type': 'mock.editor',
              'jsFactoryName': 'fluttronCreateMockEditorView',
              'description': 'Mock editor view',
            },
          ],
          'assets': {
            'js': ['web/ext/main.js'],
          },
        }),
      );

      // Create package_config.json referencing the web package
      final dartToolDir = Directory(p.join(tempDir.path, 'ui', '.dart_tool'));
      await dartToolDir.create(recursive: true);
      final packageConfigFile = File(
        p.join(dartToolDir.path, 'package_config.json'),
      );
      // Use file:// URI for reliable path resolution
      await packageConfigFile.writeAsString(
        jsonEncode({
          'configVersion': 2,
          'packages': [
            {
              'name': 'mock_web_package',
              'rootUri': 'file://${webPackageDir.path}',
              'packageUri': 'lib/',
            },
          ],
        }),
      );

      final exitCode = await runCli(['packages', 'list', '-p', tempDir.path]);
      expect(exitCode, equals(0));
    });

    test('handles multiple web packages', () async {
      // Create minimal project structure
      await _createMinimalProject(tempDir);

      // Create two mock web packages
      for (var i = 1; i <= 2; i++) {
        final webPackageDir = Directory(p.join(tempDir.path, 'pkg$i'));
        await webPackageDir.create(recursive: true);

        final pubspecFile = File(p.join(webPackageDir.path, 'pubspec.yaml'));
        await pubspecFile.writeAsString('''
name: pkg$i
version: 0.$i.0
''');

        final manifestFile = File(
          p.join(webPackageDir.path, 'fluttron_web_package.json'),
        );
        await manifestFile.writeAsString(
          jsonEncode({
            'version': '1',
            'viewFactories': [
              {
                'type': 'pkg$i.view',
                'jsFactoryName': 'fluttronCreatePkg${i}ViewView',
              },
            ],
            'assets': {
              'js': ['web/ext/main.js'],
            },
          }),
        );
      }

      // Create package_config.json
      final dartToolDir = Directory(p.join(tempDir.path, 'ui', '.dart_tool'));
      await dartToolDir.create(recursive: true);
      final packageConfigFile = File(
        p.join(dartToolDir.path, 'package_config.json'),
      );
      // Use file:// URIs for reliable path resolution
      await packageConfigFile.writeAsString(
        jsonEncode({
          'configVersion': 2,
          'packages': [
            {
              'name': 'pkg1',
              'rootUri': 'file://${tempDir.path}/pkg1',
              'packageUri': 'lib/',
            },
            {
              'name': 'pkg2',
              'rootUri': 'file://${tempDir.path}/pkg2',
              'packageUri': 'lib/',
            },
          ],
        }),
      );

      final exitCode = await runCli(['packages', 'list', '-p', tempDir.path]);
      expect(exitCode, equals(0));
    });

    test('supports --project option', () async {
      await _createMinimalProject(tempDir);

      final dartToolDir = Directory(p.join(tempDir.path, 'ui', '.dart_tool'));
      await dartToolDir.create(recursive: true);
      final packageConfigFile = File(
        p.join(dartToolDir.path, 'package_config.json'),
      );
      await packageConfigFile.writeAsString(
        jsonEncode({'configVersion': 2, 'packages': <dynamic>[]}),
      );

      final exitCode = await runCli([
        'packages',
        'list',
        '--project',
        tempDir.path,
      ]);
      expect(exitCode, equals(0));
    });
  });
}

/// Creates a minimal Fluttron project structure for testing.
Future<void> _createMinimalProject(Directory projectDir) async {
  // Create fluttron.json
  final manifestFile = File(p.join(projectDir.path, 'fluttron.json'));
  await manifestFile.writeAsString(
    jsonEncode({
      'name': 'test_app',
      'version': '1.0.0',
      'entry': {
        'uiProjectPath': 'ui',
        'hostAssetPath': 'host/assets/www',
        'index': 'index.html',
      },
      'window': {'title': 'Test App', 'width': 800, 'height': 600},
    }),
  );

  // Create ui directory
  final uiDir = Directory(p.join(projectDir.path, 'ui'));
  await uiDir.create(recursive: true);
}
