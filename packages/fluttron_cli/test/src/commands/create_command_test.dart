import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'package:fluttron_cli/fluttron_cli.dart';

void main() {
  late Directory tempDir;
  late Directory templatesDir;

  setUpAll(() async {
    // Find the project root by looking for templates directory
    var dir = Directory.current;
    Directory? foundTemplates;
    while (dir.path != dir.parent.path) {
      final templates = Directory(p.join(dir.path, 'templates'));
      if (await templates.exists()) {
        foundTemplates = templates;
        break;
      }
      dir = dir.parent;
    }

    // If not found from current directory, try relative path
    if (foundTemplates == null) {
      final currentDir = Directory.current;
      final projectRoot = currentDir.path.contains('packages/fluttron_cli')
          ? Directory(p.join(currentDir.path, '..', '..', '..'))
          : currentDir;
      foundTemplates = Directory(p.join(projectRoot.path, 'templates'));
    }

    templatesDir = foundTemplates!;
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('create_command_test_');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('CreateCommand --type option', () {
    test('defaults to app type when --type not specified', () async {
      final targetPath = p.join(tempDir.path, 'my_app');

      final exitCode = await runCli([
        'create',
        targetPath,
        '--name',
        'my_app',
        '--template',
        templatesDir.path,
      ]);

      expect(exitCode, equals(0));

      // Verify app structure created
      expect(await Directory(p.join(targetPath, 'host')).exists(), isTrue);
      expect(await Directory(p.join(targetPath, 'ui')).exists(), isTrue);
      expect(await File(p.join(targetPath, 'fluttron.json')).exists(), isTrue);
    });

    test('creates app type when --type app specified', () async {
      final targetPath = p.join(tempDir.path, 'my_app');

      final exitCode = await runCli([
        'create',
        targetPath,
        '--name',
        'my_app',
        '--type',
        'app',
        '--template',
        templatesDir.path,
      ]);

      expect(exitCode, equals(0));

      // Verify app structure created
      expect(await Directory(p.join(targetPath, 'host')).exists(), isTrue);
      expect(await Directory(p.join(targetPath, 'ui')).exists(), isTrue);
    });

    test(
      'creates web_package type when --type web_package specified',
      () async {
        final targetPath = p.join(tempDir.path, 'my_package');

        final exitCode = await runCli([
          'create',
          targetPath,
          '--name',
          'my_package',
          '--type',
          'web_package',
          '--template',
          templatesDir.path,
        ]);

        expect(exitCode, equals(0));

        // Verify web_package structure created
        expect(await File(p.join(targetPath, 'pubspec.yaml')).exists(), isTrue);
        expect(
          await File(p.join(targetPath, 'fluttron_web_package.json')).exists(),
          isTrue,
        );
        expect(await Directory(p.join(targetPath, 'lib')).exists(), isTrue);
        expect(
          await Directory(p.join(targetPath, 'frontend')).exists(),
          isTrue,
        );

        // Verify app structure NOT created
        expect(await Directory(p.join(targetPath, 'host')).exists(), isFalse);
        expect(await Directory(p.join(targetPath, 'ui')).exists(), isFalse);
      },
    );

    test('web_package transforms package name correctly', () async {
      final targetPath = p.join(tempDir.path, 'markdown_editor');

      final exitCode = await runCli([
        'create',
        targetPath,
        '--name',
        'markdown_editor',
        '--type',
        'web_package',
        '--template',
        templatesDir.path,
      ]);

      expect(exitCode, equals(0));

      // Verify pubspec.yaml has correct name
      final pubspec = File(p.join(targetPath, 'pubspec.yaml'));
      final pubspecContent = await pubspec.readAsString();
      expect(pubspecContent, contains('name: markdown_editor'));

      // Verify manifest has correct type
      final manifest = File(p.join(targetPath, 'fluttron_web_package.json'));
      final manifestContent = await manifest.readAsString();
      expect(manifestContent, contains('"type": "markdown_editor.example"'));
      expect(
        manifestContent,
        contains('"jsFactoryName": "fluttronCreateMarkdownEditorExampleView"'),
      );

      // Verify library file was renamed
      expect(
        await File(p.join(targetPath, 'lib', 'markdown_editor.dart')).exists(),
        isTrue,
      );
    });

    test('web_package rewrites fluttron_ui path dependency', () async {
      final targetPath = p.join(tempDir.path, 'my_package');

      final exitCode = await runCli([
        'create',
        targetPath,
        '--name',
        'my_package',
        '--type',
        'web_package',
        '--template',
        templatesDir.path,
      ]);

      expect(exitCode, equals(0));

      final pubspec = File(p.join(targetPath, 'pubspec.yaml'));
      final pubspecContent = await pubspec.readAsString();
      final expectedPath = p.normalize(
        p.join(templatesDir.parent.path, 'packages', 'fluttron_ui'),
      );
      expect(pubspecContent, contains('path: $expectedPath'));
    });

    test('rejects invalid --type value', () async {
      final targetPath = p.join(tempDir.path, 'test');

      final exitCode = await runCli([
        'create',
        targetPath,
        '--type',
        'invalid_type',
      ]);

      expect(exitCode, isNot(equals(0)));
    });

    test('backward compatible: --template still works for app type', () async {
      final targetPath = p.join(tempDir.path, 'test_app');

      final exitCode = await runCli([
        'create',
        targetPath,
        '--name',
        'test_app',
        '--template',
        templatesDir.path,
      ]);

      expect(exitCode, equals(0));
      expect(await Directory(p.join(targetPath, 'host')).exists(), isTrue);
    });

    test('app rewrites local package dependencies to absolute paths', () async {
      final targetPath = p.join(tempDir.path, 'test_app');

      final exitCode = await runCli([
        'create',
        targetPath,
        '--name',
        'test_app',
        '--template',
        templatesDir.path,
      ]);

      expect(exitCode, equals(0));

      final expectedRoot = p.normalize(
        p.join(templatesDir.parent.path, 'packages'),
      );

      final uiPubspec = File(p.join(targetPath, 'ui', 'pubspec.yaml'));
      final uiContent = await uiPubspec.readAsString();
      expect(
        uiContent,
        contains('path: ${p.join(expectedRoot, 'fluttron_ui')}'),
      );
      expect(
        uiContent,
        contains('path: ${p.join(expectedRoot, 'fluttron_shared')}'),
      );

      final hostPubspec = File(p.join(targetPath, 'host', 'pubspec.yaml'));
      final hostContent = await hostPubspec.readAsString();
      expect(
        hostContent,
        contains('path: ${p.join(expectedRoot, 'fluttron_host')}'),
      );
      expect(
        hostContent,
        contains('path: ${p.join(expectedRoot, 'fluttron_shared')}'),
      );
    });
  });

  group('CreateCommand web_package naming', () {
    test('converts camelCase package name to snake_case', () async {
      final targetPath = p.join(tempDir.path, 'myCoolEditor');

      final exitCode = await runCli([
        'create',
        targetPath,
        '--name',
        'myCoolEditor',
        '--type',
        'web_package',
        '--template',
        templatesDir.path,
      ]);

      expect(exitCode, equals(0));

      final pubspec = File(p.join(targetPath, 'pubspec.yaml'));
      final pubspecContent = await pubspec.readAsString();
      expect(pubspecContent, contains('name: my_cool_editor'));
    });

    test('converts PascalCase package name to snake_case', () async {
      final targetPath = p.join(tempDir.path, 'MyCoolEditor');

      final exitCode = await runCli([
        'create',
        targetPath,
        '--name',
        'MyCoolEditor',
        '--type',
        'web_package',
        '--template',
        templatesDir.path,
      ]);

      expect(exitCode, equals(0));

      final pubspec = File(p.join(targetPath, 'pubspec.yaml'));
      final pubspecContent = await pubspec.readAsString();
      expect(pubspecContent, contains('name: my_cool_editor'));
    });
  });
}
