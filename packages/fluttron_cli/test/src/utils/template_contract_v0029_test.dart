import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('template contract v0030', () {
    test(
      'template main.dart uses web view registry and type-driven html view',
      () {
        final templateMain = File(
          p.join(
            Directory.current.path,
            '..',
            '..',
            'templates',
            'ui',
            'lib',
            'main.dart',
          ),
        );
        expect(templateMain.existsSync(), isTrue);

        final contents = templateMain.readAsStringSync();
        expect(contents, contains('runFluttronUi('));
        expect(
          contents,
          contains("import 'generated/web_package_registrations.dart';"),
        );
        expect(contents, contains('registerFluttronWebPackages();'));
        expect(contents, contains('FluttronWebViewRegistry.register('));
        expect(contents, contains('FluttronWebViewRegistration('));
        expect(contents, contains('FluttronHtmlView('));
        expect(contents, contains('type: _templateEditorWebViewType'));
        expect(contents, contains('FluttronEventBridge'));
      },
    );

    test('template has generated registration placeholder file', () {
      final generatedFile = File(
        p.join(
          Directory.current.path,
          '..',
          '..',
          'templates',
          'ui',
          'lib',
          'generated',
          'web_package_registrations.dart',
        ),
      );
      expect(generatedFile.existsSync(), isTrue);

      final contents = generatedFile.readAsStringSync();
      expect(contents, contains('registerFluttronWebPackages'));
    });

    test(
      'template frontend main.js exports editor factory and emits CustomEvent',
      () {
        final frontendMain = File(
          p.join(
            Directory.current.path,
            '..',
            '..',
            'templates',
            'ui',
            'frontend',
            'src',
            'main.js',
          ),
        );
        expect(frontendMain.existsSync(), isTrue);

        final contents = frontendMain.readAsStringSync();
        expect(contents, contains('fluttron.template.editor.change'));
        expect(contents, contains('window.fluttronCreateTemplateEditorView'));
        expect(contents, contains('new CustomEvent('));
      },
    );
  });
}
