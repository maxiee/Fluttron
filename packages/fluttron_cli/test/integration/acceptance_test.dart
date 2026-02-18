@Tags(['acceptance'])
library;

import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'test_helper.dart';

void main() {
  late Directory tempDir;
  late Directory pkgDir;
  late Directory appDir;

  setUpAll(() async {
    tempDir = await IntegrationTestHelper.createTempDir('acceptance');
    pkgDir = Directory(p.join(tempDir.path, 'test_package'));
    appDir = Directory(p.join(tempDir.path, 'test_app'));
  });

  tearDownAll(() async {
    await IntegrationTestHelper.recursiveDelete(tempDir);
  });

  group('PRD §13.1 Create Web Package', () {
    test(
      'creates web package with correct structure',
      () async {
        final exitCode = await IntegrationTestHelper.runCli([
          'create',
          pkgDir.path,
          '--name',
          'test_package',
          '--type',
          'web_package',
        ]);
        expect(exitCode, equals(0));

        expect(
          await File(p.join(pkgDir.path, 'fluttron_web_package.json')).exists(),
          isTrue,
          reason: 'Manifest should exist',
        );
        expect(
          await File(p.join(pkgDir.path, 'pubspec.yaml')).exists(),
          isTrue,
          reason: 'pubspec.yaml should exist',
        );
        expect(
          await File(p.join(pkgDir.path, 'lib', 'test_package.dart')).exists(),
          isTrue,
          reason: 'Dart library entry should exist',
        );
      },
      timeout: const Timeout(Duration(minutes: 1)),
    );
  });

  group(
    'PRD §13.2 Use Web Package in App',
    () {
      setUpAll(() async {
        await IntegrationTestHelper.createMinimalWebPackage(
          pkgDir,
          'test_package',
        );
        await IntegrationTestHelper.runCli([
          'create',
          appDir.path,
          '--name',
          'test_app',
        ]);
        await IntegrationTestHelper.addPathDependency(appDir, pkgDir);
        await IntegrationTestHelper.runPubGet(
          Directory(p.join(appDir.path, 'ui')),
        );
        await IntegrationTestHelper.runCli(['build', '-p', appDir.path]);
      });

      test('JS injected in host HTML', () async {
        final indexHtml = File(
          p.join(appDir.path, 'host/assets/www/index.html'),
        );
        expect(await indexHtml.exists(), isTrue);

        final content = await indexHtml.readAsString();
        expect(
          content.contains('ext/packages/test_package/main.js'),
          isTrue,
          reason: 'Package JS should be injected',
        );
      });

      test('registrations generated', () async {
        final registrationsFile = File(
          p.join(
            appDir.path,
            'ui/lib/generated/web_package_registrations.dart',
          ),
        );
        expect(await registrationsFile.exists(), isTrue);

        final content = await registrationsFile.readAsString();
        expect(
          content.contains('registerFluttronWebPackages'),
          isTrue,
          reason: 'Registration function should exist',
        );
      });
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );

  group('PRD §13.3 End-to-End', () {
    late Directory e2eTempDir;
    late Directory e2ePkgDir;
    late Directory e2eAppDir;

    setUpAll(() async {
      e2eTempDir = await IntegrationTestHelper.createTempDir('acceptance_e2e');
      e2ePkgDir = Directory(p.join(e2eTempDir.path, 'test_package'));
      e2eAppDir = Directory(p.join(e2eTempDir.path, 'test_app'));

      await IntegrationTestHelper.createMinimalWebPackage(
        e2ePkgDir,
        'test_package',
      );
      await IntegrationTestHelper.runCli([
        'create',
        e2eAppDir.path,
        '--name',
        'test_app',
      ]);
      await IntegrationTestHelper.addPathDependency(e2eAppDir, e2ePkgDir);
      await IntegrationTestHelper.runPubGet(
        Directory(p.join(e2eAppDir.path, 'ui')),
      );
      await IntegrationTestHelper.runCli(['build', '-p', e2eAppDir.path]);
    });

    tearDownAll(() async {
      await IntegrationTestHelper.recursiveDelete(e2eTempDir);
    });

    test('CI smoke: build artifacts are valid', () async {
      final hostAssets = Directory(p.join(e2eAppDir.path, 'host/assets/www'));
      expect(await hostAssets.exists(), isTrue);
      expect(
        await File(p.join(hostAssets.path, 'index.html')).exists(),
        isTrue,
      );
      expect(
        await File(p.join(hostAssets.path, 'ext/main.js')).exists(),
        isTrue,
      );
      expect(
        await File(
          p.join(hostAssets.path, 'ext/packages/test_package/main.js'),
        ).exists(),
        isTrue,
      );
    });

    test(
      'macOS app launches (manual)',
      () async {
        if (!Platform.isMacOS) {
          markTestSkipped('macOS only');
          return;
        }
        if (Platform.environment['CI'] == 'true') {
          markTestSkipped('Requires macOS device outside CI');
          return;
        }

        final result = await Process.run('flutter', [
          'run',
          '-d',
          'macos',
          '--no-build',
        ], workingDirectory: p.join(e2eAppDir.path, 'host'));

        expect(result.exitCode, equals(0));
      },
      tags: ['e2e', 'macos', 'manual'],
      timeout: const Timeout(Duration(minutes: 5)),
    );
  }, timeout: const Timeout(Duration(minutes: 3)));
}
