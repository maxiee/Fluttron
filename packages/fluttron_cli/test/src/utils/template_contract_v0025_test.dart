import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('template contract v0025', () {
    test('host pubspec declares assets/www/ext directory', () {
      final hostPubspec = File(
        p.join(
          Directory.current.path,
          '..',
          '..',
          'templates',
          'host',
          'pubspec.yaml',
        ),
      );
      expect(hostPubspec.existsSync(), isTrue);

      final contents = hostPubspec.readAsStringSync();
      expect(contents, contains('- assets/www/ext/'));
    });

    test('build-frontend clean step removes css artifact and sourcemap', () {
      final buildScript = File(
        p.join(
          Directory.current.path,
          '..',
          '..',
          'templates',
          'ui',
          'scripts',
          'build-frontend.mjs',
        ),
      );
      expect(buildScript.existsSync(), isTrue);

      final contents = buildScript.readAsStringSync();
      expect(
        contents,
        contains(
          "const outputCssFile = path.join(uiRoot, 'web', 'ext', 'main.css');",
        ),
      );

      final cleanSectionMatch = RegExp(
        r'async function cleanFrontend\(\) \{([\s\S]*?)\n\}',
      ).firstMatch(contents);
      expect(cleanSectionMatch, isNotNull);

      final cleanSection = cleanSectionMatch!.group(1)!;
      expect(cleanSection, contains('await rm(outputCssFile, {force: true});'));
      expect(
        cleanSection,
        contains(r'await rm(`${outputCssFile}.map`, {force: true});'),
      );
    });
  });
}
