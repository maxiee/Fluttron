import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'package:fluttron_cli/src/utils/js_asset_validator.dart';

void main() {
  group('JsAssetValidator', () {
    late Directory uiWebDir;

    setUp(() {
      final uiDir = Directory.systemTemp.createTempSync('js_asset_validator_');
      uiWebDir = Directory(p.join(uiDir.path, 'web'))
        ..createSync(recursive: true);
    });

    tearDown(() {
      final root = uiWebDir.parent;
      if (root.existsSync()) {
        root.deleteSync(recursive: true);
      }
    });

    test('collects local script assets and ignores remote scripts', () {
      _writeIndexHtml(uiWebDir, '''
<!DOCTYPE html>
<html>
<body>
  <script src="ext/main.js?v=1#hash"></script>
  <script src="/ext/runtime.js"></script>
  <script src="https://cdn.example.com/app.js"></script>
  <script src="//cdn.example.com/app.js"></script>
  <script src="data:text/javascript,console.log('x')"></script>
  <script src="ext/main.js"></script>
</body>
</html>
''');

      final validator = const JsAssetValidator();
      final assets = validator.collectLocalScriptAssets(
        indexFile: File(p.join(uiWebDir.path, 'index.html')),
        webRootDir: uiWebDir,
      );

      expect(assets.map((asset) => asset.relativePath).toList(), <String>[
        'ext/main.js',
        'ext/runtime.js',
      ]);
    });

    test('throws when local script path resolves outside web root', () {
      _writeIndexHtml(uiWebDir, '''
<html>
  <body>
    <script src="../escape.js"></script>
  </body>
</html>
''');

      final validator = const JsAssetValidator();
      expect(
        () => validator.collectLocalScriptAssets(
          indexFile: File(p.join(uiWebDir.path, 'index.html')),
          webRootDir: uiWebDir,
        ),
        throwsA(
          isA<JsAssetValidationException>().having(
            (error) => error.message,
            'message',
            contains('outside web root'),
          ),
        ),
      );
    });

    test('reports missing local script assets', () {
      _writeIndexHtml(uiWebDir, '''
<html>
  <body>
    <script src="ext/main.js"></script>
    <script src="ext/missing.js"></script>
  </body>
</html>
''');
      final extDir = Directory(p.join(uiWebDir.path, 'ext'))..createSync();
      File(
        p.join(extDir.path, 'main.js'),
      ).writeAsStringSync('console.log("ok");');

      final validator = const JsAssetValidator();
      final assets = validator.collectLocalScriptAssets(
        indexFile: File(p.join(uiWebDir.path, 'index.html')),
        webRootDir: uiWebDir,
      );
      final missingPaths = validator.findMissingAssetPaths(
        rootDir: uiWebDir,
        assets: assets,
      );

      expect(missingPaths.length, 1);
      expect(
        missingPaths.single,
        p.normalize(p.join(uiWebDir.path, 'ext', 'missing.js')),
      );
    });

    test('marks Flutter-generated scripts for source-stage exclusion', () {
      _writeIndexHtml(uiWebDir, '''
<html>
  <body>
    <script src="flutter_bootstrap.js"></script>
    <script src="ext/main.js"></script>
  </body>
</html>
''');

      final validator = const JsAssetValidator();
      final assets = validator.collectLocalScriptAssets(
        indexFile: File(p.join(uiWebDir.path, 'index.html')),
        webRootDir: uiWebDir,
      );

      expect(assets[0].isFlutterGenerated, isTrue);
      expect(assets[1].isFlutterGenerated, isFalse);
    });
  });
}

void _writeIndexHtml(Directory uiWebDir, String contents) {
  File(p.join(uiWebDir.path, 'index.html')).writeAsStringSync(contents);
}
