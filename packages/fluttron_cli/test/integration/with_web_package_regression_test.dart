import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'test_helper.dart';

void main() {
  late Directory tempDir;
  late Directory appDir;
  late Directory pkgDir;

  setUpAll(() async {
    tempDir = await IntegrationTestHelper.createTempDir('with_pkg_test');
    appDir = Directory(p.join(tempDir.path, 'test_app'));
    pkgDir = Directory(p.join(tempDir.path, 'test_package'));

    // Create minimal web package
    await IntegrationTestHelper.createMinimalWebPackage(pkgDir, 'test_package');

    // Create app
    await IntegrationTestHelper.runCli([
      'create',
      appDir.path,
      '--name',
      'test_app',
    ]);

    // Add dependency
    await IntegrationTestHelper.addPathDependency(appDir, pkgDir);
    await IntegrationTestHelper.runPubGet(Directory(p.join(appDir.path, 'ui')));

    // Build once for all tests
    await IntegrationTestHelper.runCli(['build', '-p', appDir.path]);
  });

  tearDownAll(() async {
    await IntegrationTestHelper.recursiveDelete(tempDir);
  });

  group('Apps with web packages', () {
    test('build succeeds', () async {
      // Build already done in setUpAll, verify by checking output
      expect(
        await File(p.join(appDir.path, 'host/assets/www/index.html')).exists(),
        isTrue,
      );
    }, timeout: const Timeout(Duration(minutes: 2)));

    test('registration generates correct code', () async {
      final registrationsFile = File(
        p.join(appDir.path, 'ui/lib/generated/web_package_registrations.dart'),
      );
      expect(await registrationsFile.exists(), isTrue);

      final content = await registrationsFile.readAsString();
      expect(content, contains('FluttronWebViewRegistry.register'));
      expect(content, contains('test_package.example'));
      expect(content, contains('fluttronCreateTestPackageExampleView'));
    });

    test('assets collected to correct location', () async {
      final packageJs = File(
        p.join(
          appDir.path,
          'host/assets/www/ext/packages/test_package/main.js',
        ),
      );
      expect(await packageJs.exists(), isTrue);

      final packageCss = File(
        p.join(
          appDir.path,
          'host/assets/www/ext/packages/test_package/main.css',
        ),
      );
      expect(await packageCss.exists(), isTrue);
    });

    test('HTML has package script injection', () async {
      final indexHtml = File(p.join(appDir.path, 'host/assets/www/index.html'));
      expect(await indexHtml.exists(), isTrue);

      final content = await indexHtml.readAsString();
      expect(content, contains('src="ext/packages/test_package/main.js"'));
    });

    test('HTML has package CSS injection', () async {
      final indexHtml = File(p.join(appDir.path, 'host/assets/www/index.html'));
      expect(await indexHtml.exists(), isTrue);

      final content = await indexHtml.readAsString();
      expect(content, contains('href="ext/packages/test_package/main.css"'));
    });

    test('JS injected before ext/main.js', () async {
      final indexHtml = File(p.join(appDir.path, 'host/assets/www/index.html'));
      final content = await indexHtml.readAsString();

      final packageJsIndex = content.indexOf(
        'ext/packages/test_package/main.js',
      );
      final mainJsIndex = content.indexOf('src="ext/main.js"');

      expect(
        packageJsIndex,
        greaterThan(-1),
        reason: 'Package JS should be found',
      );
      expect(
        mainJsIndex,
        greaterThan(-1),
        reason: 'Local ext/main.js should be found',
      );
      expect(
        packageJsIndex,
        lessThan(mainJsIndex),
        reason: 'Package JS should appear before local ext/main.js',
      );
    });

    test('CSS injected in head section', () async {
      final indexHtml = File(p.join(appDir.path, 'host/assets/www/index.html'));
      final content = await indexHtml.readAsString();

      final headCloseIndex = content.indexOf('</head>');
      final bodyOpenIndex = content.indexOf('<body');
      final cssIndex = content.indexOf('ext/packages/test_package/main.css');

      expect(cssIndex, greaterThan(-1), reason: 'Package CSS should be found');
      expect(
        cssIndex,
        lessThan(headCloseIndex),
        reason: 'Package CSS should be in <head>',
      );
      expect(
        cssIndex,
        lessThan(bodyOpenIndex),
        reason: 'Package CSS should appear before <body>',
      );
    });
  });
}
