import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'test_helper.dart';

void main() {
  late Directory tempDir;
  late Directory appDir;

  setUpAll(() async {
    tempDir = await IntegrationTestHelper.createTempDir('no_pkg_test');
    appDir = Directory(p.join(tempDir.path, 'test_app'));

    // Create and build the app once for all tests
    await IntegrationTestHelper.runCli([
      'create',
      appDir.path,
      '--name',
      'test_app',
    ]);
    await IntegrationTestHelper.runCli(['build', '-p', appDir.path]);
  });

  tearDownAll(() async {
    await IntegrationTestHelper.recursiveDelete(tempDir);
  });

  group('Apps without web packages', () {
    test('build succeeds', () async {
      // Build already done in setUpAll, just verify it succeeded by checking output
      expect(
        await File(p.join(appDir.path, 'host/assets/www/index.html')).exists(),
        isTrue,
      );
    }, timeout: const Timeout(Duration(minutes: 2)));

    test('generated registrations file exists and is valid', () async {
      final registrationsFile = File(
        p.join(appDir.path, 'ui/lib/generated/web_package_registrations.dart'),
      );
      expect(await registrationsFile.exists(), isTrue);

      final content = await registrationsFile.readAsString();
      expect(content, contains('registerFluttronWebPackages'));
    });

    test('HTML has no package script injections', () async {
      final indexHtml = File(p.join(appDir.path, 'host/assets/www/index.html'));
      expect(await indexHtml.exists(), isTrue);

      final content = await indexHtml.readAsString();
      expect(content.contains('ext/packages/'), isFalse);
    });

    test('HTML has no package CSS injections', () async {
      final indexHtml = File(p.join(appDir.path, 'host/assets/www/index.html'));
      expect(await indexHtml.exists(), isTrue);

      final content = await indexHtml.readAsString();
      expect(content.contains('href="ext/packages/'), isFalse);
    });

    test('ext/packages directory does not exist', () async {
      final packagesDir = Directory(
        p.join(appDir.path, 'host/assets/www/ext/packages'),
      );
      expect(await packagesDir.exists(), isFalse);
    });

    test('ext/main.js still exists after build', () async {
      final mainJs = File(p.join(appDir.path, 'host/assets/www/ext/main.js'));
      expect(await mainJs.exists(), isTrue);
    });
  });
}
