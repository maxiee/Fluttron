import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'package:fluttron_cli/src/utils/web_package_copier.dart';

void main() {
  late Directory tempDir;
  late Directory templateDir;
  late Directory targetDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('web_package_copier_test_');
    templateDir = Directory(p.join(tempDir.path, 'template'));
    targetDir = Directory(p.join(tempDir.path, 'target'));
    await templateDir.create(recursive: true);
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('WebPackageCopier', () {
    test('transforms package name to snake_case', () async {
      final copier = WebPackageCopier();

      // Create minimal template structure
      final pubspecFile = File(p.join(templateDir.path, 'pubspec.yaml'));
      await pubspecFile.writeAsString('''
name: fluttron_web_package_template
description: Template
version: 0.1.0
fluttron_web_package: true
''');

      await copier.copyAndTransform(
        packageName: 'MyCoolEditor',
        sourceDir: templateDir,
        destinationDir: targetDir,
      );

      final targetPubspec = File(p.join(targetDir.path, 'pubspec.yaml'));
      expect(await targetPubspec.exists(), isTrue);

      final content = await targetPubspec.readAsString();
      expect(content, contains('name: my_cool_editor'));
    });

    test('renames library file based on package name', () async {
      final copier = WebPackageCopier();

      // Create template structure with library file
      final libDir = Directory(p.join(templateDir.path, 'lib'));
      await libDir.create();

      final libFile = File(
        p.join(libDir.path, 'fluttron_web_package_template.dart'),
      );
      await libFile.writeAsString('''
library fluttron_web_package_template;
export 'src/example_widget.dart';
''');

      await copier.copyAndTransform(
        packageName: 'markdown_editor',
        sourceDir: templateDir,
        destinationDir: targetDir,
      );

      // Check file was renamed
      final renamedFile = File(
        p.join(targetDir.path, 'lib', 'markdown_editor.dart'),
      );
      expect(await renamedFile.exists(), isTrue);

      // Check content was transformed
      final content = await renamedFile.readAsString();
      expect(content, contains('library markdown_editor'));
    });

    test('transforms viewFactory type and jsFactoryName in manifest', () async {
      final copier = WebPackageCopier();

      final manifestFile = File(
        p.join(templateDir.path, 'fluttron_web_package.json'),
      );
      await manifestFile.writeAsString('''
{
  "version": "1",
  "viewFactories": [
    {
      "type": "template_package.example",
      "jsFactoryName": "fluttronCreateTemplatePackageExampleView",
      "description": "Example view factory"
    }
  ],
  "assets": {
    "js": ["web/ext/main.js"],
    "css": ["web/ext/main.css"]
  },
  "events": [
    {
      "name": "fluttron.template_package.example.change",
      "direction": "js_to_dart"
    }
  ]
}
''');

      await copier.copyAndTransform(
        packageName: 'chart_viewer',
        sourceDir: templateDir,
        destinationDir: targetDir,
      );

      final targetManifest = File(
        p.join(targetDir.path, 'fluttron_web_package.json'),
      );
      expect(await targetManifest.exists(), isTrue);

      final content = await targetManifest.readAsString();
      expect(content, contains('"type": "chart_viewer.example"'));
      expect(
        content,
        contains('"jsFactoryName": "fluttronCreateChartViewerExampleView"'),
      );
      expect(
        content,
        contains('"name": "fluttron.chart_viewer.example.change"'),
      );
    });

    test('transforms Dart widget class names', () async {
      final copier = WebPackageCopier();

      final libDir = Directory(p.join(templateDir.path, 'lib', 'src'));
      await libDir.create(recursive: true);

      final widgetFile = File(p.join(libDir.path, 'example_widget.dart'));
      await widgetFile.writeAsString('''
import 'package:fluttron_ui/fluttron_ui.dart';

class TemplatePackageExampleWidget extends StatelessWidget {
  const TemplatePackageExampleWidget({super.key});
  
  @override
  Widget build(BuildContext context) {
    return FluttronHtmlView(
      type: 'template_package.example',
      args: [],
    );
  }
}

Stream<Map<String, dynamic>> templatePackageExampleChanges() {
  return FluttronEventBridge().on('fluttron.template_package.example.change');
}
''');

      await copier.copyAndTransform(
        packageName: 'code_editor',
        sourceDir: templateDir,
        destinationDir: targetDir,
      );

      final targetWidget = File(
        p.join(targetDir.path, 'lib', 'src', 'example_widget.dart'),
      );
      expect(await targetWidget.exists(), isTrue);

      final content = await targetWidget.readAsString();
      expect(content, contains('class CodeEditorExampleWidget'));
      expect(content, contains("type: 'code_editor.example'"));
      expect(content, contains('codeEditorExampleChanges()'));
      expect(content, contains("'fluttron.code_editor.example.change'"));
    });

    test('transforms JavaScript view factory names', () async {
      final copier = WebPackageCopier();

      final frontendDir = Directory(
        p.join(templateDir.path, 'frontend', 'src'),
      );
      await frontendDir.create(recursive: true);

      final jsFile = File(p.join(frontendDir.path, 'main.js'));
      await jsFile.writeAsString('''
const EXAMPLE_CHANGE_EVENT = 'fluttron.template_package.example.change';

const createTemplatePackageExampleView = (viewId, initialContent) => {
  const container = document.createElement('div');
  container.className = 'template-package-example';
  return container;
};

window.fluttronCreateTemplatePackageExampleView = createTemplatePackageExampleView;
''');

      await copier.copyAndTransform(
        packageName: 'image_viewer',
        sourceDir: templateDir,
        destinationDir: targetDir,
      );

      final targetJs = File(
        p.join(targetDir.path, 'frontend', 'src', 'main.js'),
      );
      expect(await targetJs.exists(), isTrue);

      final content = await targetJs.readAsString();
      expect(content, contains("'fluttron.image_viewer.example.change'"));
      expect(content, contains('createImageViewerExampleView'));
      expect(content, contains('window.fluttronCreateImageViewerExampleView'));
      expect(content, contains("'image-viewer-example'"));
    });

    test('handles nested directory structures', () async {
      final copier = WebPackageCopier();

      // Create nested structure
      final webDir = Directory(p.join(templateDir.path, 'web', 'ext'));
      await webDir.create(recursive: true);

      final mainJs = File(p.join(webDir.path, 'main.js'));
      await mainJs.writeAsString('// TemplatePackage JS file');

      await copier.copyAndTransform(
        packageName: 'test_pkg',
        sourceDir: templateDir,
        destinationDir: targetDir,
      );

      final targetJs = File(p.join(targetDir.path, 'web', 'ext', 'main.js'));
      expect(await targetJs.exists(), isTrue);
    });
  });

  group('Naming conventions', () {
    test('converts camelCase to snake_case', () async {
      final copier = WebPackageCopier();

      final pubspecFile = File(p.join(templateDir.path, 'pubspec.yaml'));
      await pubspecFile.writeAsString('name: fluttron_web_package_template');

      await copier.copyAndTransform(
        packageName: 'myCoolEditor',
        sourceDir: templateDir,
        destinationDir: targetDir,
      );

      final targetPubspec = File(p.join(targetDir.path, 'pubspec.yaml'));
      final content = await targetPubspec.readAsString();
      expect(content, contains('name: my_cool_editor'));
    });

    test('converts PascalCase to snake_case', () async {
      final copier = WebPackageCopier();

      final pubspecFile = File(p.join(templateDir.path, 'pubspec.yaml'));
      await pubspecFile.writeAsString('name: fluttron_web_package_template');

      await copier.copyAndTransform(
        packageName: 'MyCoolEditor',
        sourceDir: templateDir,
        destinationDir: targetDir,
      );

      final targetPubspec = File(p.join(targetDir.path, 'pubspec.yaml'));
      final content = await targetPubspec.readAsString();
      expect(content, contains('name: my_cool_editor'));
    });

    test('preserves snake_case input', () async {
      final copier = WebPackageCopier();

      final pubspecFile = File(p.join(templateDir.path, 'pubspec.yaml'));
      await pubspecFile.writeAsString('name: fluttron_web_package_template');

      await copier.copyAndTransform(
        packageName: 'my_cool_editor',
        sourceDir: templateDir,
        destinationDir: targetDir,
      );

      final targetPubspec = File(p.join(targetDir.path, 'pubspec.yaml'));
      final content = await targetPubspec.readAsString();
      expect(content, contains('name: my_cool_editor'));
    });
  });
}
