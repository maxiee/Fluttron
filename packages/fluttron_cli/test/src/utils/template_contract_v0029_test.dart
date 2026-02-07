import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('template contract v0029', () {
    test('template main.dart is based on fluttron_ui core APIs', () {
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
      expect(contents, contains('FluttronHtmlView('));
      expect(contents, contains('FluttronEventBridge'));
    });

    test('template frontend main.js emits CustomEvent for editor changes', () {
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
      expect(contents, contains('new CustomEvent('));
    });
  });
}
