import 'dart:io';

import 'package:fluttron_cli/src/utils/html_injector.dart';
import 'package:fluttron_cli/src/utils/web_package_collector.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('html_injector_test_');
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('HtmlInjectorException', () {
    test('toString returns message', () {
      final exception = HtmlInjectorException('Test error message');
      expect(exception.toString(), equals('Test error message'));
    });
  });

  group('InjectionResult', () {
    test('hasInjections returns false when no injections', () {
      final result = InjectionResult(
        injectedJsCount: 0,
        injectedCssCount: 0,
        outputPath: '/path/to/index.html',
      );

      expect(result.hasInjections, isFalse);
    });

    test('hasInjections returns true when JS injected', () {
      final result = InjectionResult(
        injectedJsCount: 1,
        injectedCssCount: 0,
        outputPath: '/path/to/index.html',
      );

      expect(result.hasInjections, isTrue);
    });

    test('hasInjections returns true when CSS injected', () {
      final result = InjectionResult(
        injectedJsCount: 0,
        injectedCssCount: 2,
        outputPath: '/path/to/index.html',
      );

      expect(result.hasInjections, isTrue);
    });
  });

  group('HtmlInjector', () {
    late File indexHtml;

    const validHtml = '''<!DOCTYPE html>
<html>
<head>
  <title>Test</title>
  <!-- FLUTTRON_PACKAGES_CSS -->
</head>
<body>
  <!-- FLUTTRON_PACKAGES_JS -->
  <script src="ext/main.js"></script>
  <script src="flutter_bootstrap.js" async></script>
</body>
</html>''';

    void writeIndexHtml(String content) {
      indexHtml = File(p.join(tempDir.path, 'index.html'));
      indexHtml.writeAsStringSync(content);
    }

    /// Extracts package name from path like 'ext/packages/my_editor/main.js'
    String extractPackageName(String path) {
      final parts = path.split('/');
      final packagesIndex = parts.indexOf('packages');
      if (packagesIndex >= 0 && packagesIndex + 1 < parts.length) {
        return parts[packagesIndex + 1];
      }
      return 'pkg';
    }

    /// Extracts filename from path
    String extractFilename(String path) {
      return p.basename(path);
    }

    CollectionResult createCollectionResult({
      List<String> jsPaths = const [],
      List<String> cssPaths = const [],
    }) {
      final assets = <CollectedAsset>[];

      for (final jsPath in jsPaths) {
        final packageName = extractPackageName(jsPath);
        final filename = extractFilename(jsPath);
        assets.add(
          CollectedAsset(
            packageName: packageName,
            relativePath: jsPath,
            sourcePath: '/s/$jsPath',
            destinationPath: '/d/ext/packages/$packageName/$filename',
            type: AssetType.js,
          ),
        );
      }

      for (final cssPath in cssPaths) {
        final packageName = extractPackageName(cssPath);
        final filename = extractFilename(cssPath);
        assets.add(
          CollectedAsset(
            packageName: packageName,
            relativePath: cssPath,
            sourcePath: '/s/$cssPath',
            destinationPath: '/d/ext/packages/$packageName/$filename',
            type: AssetType.css,
          ),
        );
      }

      return CollectionResult(
        packages: jsPaths.isEmpty && cssPaths.isEmpty ? 0 : 1,
        assets: assets,
        skippedPackages: [],
      );
    }

    test('throws when HTML file does not exist', () async {
      final injector = HtmlInjector();
      final nonExistent = File(p.join(tempDir.path, 'nonexistent.html'));
      final result = createCollectionResult();

      expect(
        () => injector.inject(indexHtml: nonExistent, collectionResult: result),
        throwsA(
          isA<HtmlInjectorException>().having(
            (e) => e.message,
            'message',
            allOf(
              contains('HTML file not found'),
              contains('nonexistent.html'),
            ),
          ),
        ),
      );
    });

    test('throws when JS placeholder is missing', () async {
      writeIndexHtml('''
<!DOCTYPE html>
<html>
<head>
  <!-- FLUTTRON_PACKAGES_CSS -->
</head>
<body>
  <script src="ext/main.js"></script>
</body>
</html>
''');

      final injector = HtmlInjector();
      final result = createCollectionResult();

      expect(
        () => injector.inject(indexHtml: indexHtml, collectionResult: result),
        throwsA(
          isA<HtmlInjectorException>().having(
            (e) => e.message,
            'message',
            allOf(
              contains('Missing required placeholder'),
              contains(HtmlInjector.jsPlaceholder),
            ),
          ),
        ),
      );
    });

    test('throws when CSS placeholder is missing', () async {
      writeIndexHtml('''
<!DOCTYPE html>
<html>
<head>
  <title>Test</title>
</head>
<body>
  <!-- FLUTTRON_PACKAGES_JS -->
  <script src="ext/main.js"></script>
</body>
</html>
''');

      final injector = HtmlInjector();
      final result = createCollectionResult();

      expect(
        () => injector.inject(indexHtml: indexHtml, collectionResult: result),
        throwsA(
          isA<HtmlInjectorException>().having(
            (e) => e.message,
            'message',
            allOf(
              contains('Missing required placeholder'),
              contains(HtmlInjector.cssPlaceholder),
            ),
          ),
        ),
      );
    });

    test('throws when both placeholders are missing', () async {
      writeIndexHtml('''
<!DOCTYPE html>
<html>
<head>
  <title>Test</title>
</head>
<body>
  <script src="ext/main.js"></script>
</body>
</html>
''');

      final injector = HtmlInjector();
      final result = createCollectionResult();

      expect(
        () => injector.inject(indexHtml: indexHtml, collectionResult: result),
        throwsA(
          isA<HtmlInjectorException>().having(
            (e) => e.message,
            'message',
            allOf(
              contains(HtmlInjector.jsPlaceholder),
              contains(HtmlInjector.cssPlaceholder),
            ),
          ),
        ),
      );
    });

    test('injects single JS script tag', () async {
      writeIndexHtml(validHtml);

      final injector = HtmlInjector();
      final result = createCollectionResult(
        jsPaths: ['ext/packages/my_editor/main.js'],
      );

      final injectionResult = await injector.inject(
        indexHtml: indexHtml,
        collectionResult: result,
      );

      expect(injectionResult.injectedJsCount, equals(1));
      expect(injectionResult.injectedCssCount, equals(0));
      expect(injectionResult.hasInjections, isTrue);

      final content = indexHtml.readAsStringSync();
      expect(
        content,
        contains('<script src="ext/packages/my_editor/main.js"></script>'),
      );
      // Verify existing scripts are preserved
      expect(content, contains('<script src="ext/main.js"></script>'));
      expect(content, contains('flutter_bootstrap.js'));
    });

    test('injects multiple JS script tags', () async {
      writeIndexHtml(validHtml);

      final injector = HtmlInjector();
      final result = createCollectionResult(
        jsPaths: ['ext/packages/editor/main.js', 'ext/packages/chart/main.js'],
      );

      await injector.inject(indexHtml: indexHtml, collectionResult: result);

      final content = indexHtml.readAsStringSync();
      expect(
        content,
        contains('<script src="ext/packages/editor/main.js"></script>'),
      );
      expect(
        content,
        contains('<script src="ext/packages/chart/main.js"></script>'),
      );
    });

    test('injects single CSS link tag', () async {
      writeIndexHtml(validHtml);

      final injector = HtmlInjector();
      final result = createCollectionResult(
        cssPaths: ['ext/packages/my_editor/main.css'],
      );

      final injectionResult = await injector.inject(
        indexHtml: indexHtml,
        collectionResult: result,
      );

      expect(injectionResult.injectedJsCount, equals(0));
      expect(injectionResult.injectedCssCount, equals(1));

      final content = indexHtml.readAsStringSync();
      expect(
        content,
        contains(
          '<link rel="stylesheet" href="ext/packages/my_editor/main.css">',
        ),
      );
    });

    test('injects multiple CSS link tags', () async {
      writeIndexHtml(validHtml);

      final injector = HtmlInjector();
      final result = createCollectionResult(
        cssPaths: [
          'ext/packages/editor/main.css',
          'ext/packages/chart/theme.css',
        ],
      );

      await injector.inject(indexHtml: indexHtml, collectionResult: result);

      final content = indexHtml.readAsStringSync();
      expect(
        content,
        contains('<link rel="stylesheet" href="ext/packages/editor/main.css">'),
      );
      expect(
        content,
        contains('<link rel="stylesheet" href="ext/packages/chart/theme.css">'),
      );
    });

    test('injects both JS and CSS tags', () async {
      writeIndexHtml(validHtml);

      final injector = HtmlInjector();
      final result = createCollectionResult(
        jsPaths: ['ext/packages/my_editor/main.js'],
        cssPaths: ['ext/packages/my_editor/main.css'],
      );

      final injectionResult = await injector.inject(
        indexHtml: indexHtml,
        collectionResult: result,
      );

      expect(injectionResult.injectedJsCount, equals(1));
      expect(injectionResult.injectedCssCount, equals(1));

      final content = indexHtml.readAsStringSync();
      // JS in body
      expect(
        content,
        contains('<script src="ext/packages/my_editor/main.js"></script>'),
      );
      // CSS in head
      expect(
        content,
        contains(
          '<link rel="stylesheet" href="ext/packages/my_editor/main.css">',
        ),
      );
    });

    test('clears placeholders when no assets to inject', () async {
      writeIndexHtml(validHtml);

      final injector = HtmlInjector();
      final result = createCollectionResult(); // Empty

      await injector.inject(indexHtml: indexHtml, collectionResult: result);

      final content = indexHtml.readAsStringSync();
      // Placeholders should be replaced with empty string
      expect(content, isNot(contains(HtmlInjector.jsPlaceholder)));
      expect(content, isNot(contains(HtmlInjector.cssPlaceholder)));
      // Existing scripts preserved
      expect(content, contains('<script src="ext/main.js"></script>'));
    });

    test('preserves order of existing scripts after injected tags', () async {
      writeIndexHtml(validHtml);

      final injector = HtmlInjector();
      final result = createCollectionResult(
        jsPaths: ['ext/packages/pkg/main.js'],
      );

      await injector.inject(indexHtml: indexHtml, collectionResult: result);

      final content = indexHtml.readAsStringSync();

      // Find positions
      final pkgScriptPos = content.indexOf('ext/packages/pkg/main.js');
      final extMainPos = content.indexOf('ext/main.js');
      final bootstrapPos = content.indexOf('flutter_bootstrap.js');

      // Package script should come before app's ext/main.js
      expect(pkgScriptPos, lessThan(extMainPos));
      // ext/main.js should come before flutter_bootstrap.js
      expect(extMainPos, lessThan(bootstrapPos));
    });

    test('injectSync works same as async inject', () async {
      writeIndexHtml(validHtml);

      final injector = HtmlInjector();
      final result = createCollectionResult(
        jsPaths: ['ext/packages/my_editor/main.js'],
        cssPaths: ['ext/packages/my_editor/main.css'],
      );

      final injectionResult = injector.injectSync(
        indexHtml: indexHtml,
        collectionResult: result,
      );

      expect(injectionResult.injectedJsCount, equals(1));
      expect(injectionResult.injectedCssCount, equals(1));

      final content = indexHtml.readAsStringSync();
      expect(
        content,
        contains('<script src="ext/packages/my_editor/main.js"></script>'),
      );
      expect(
        content,
        contains(
          '<link rel="stylesheet" href="ext/packages/my_editor/main.css">',
        ),
      );
    });

    test('returns correct output path', () async {
      writeIndexHtml(validHtml);

      final injector = HtmlInjector();
      final result = createCollectionResult();

      final injectionResult = await injector.inject(
        indexHtml: indexHtml,
        collectionResult: result,
      );

      expect(injectionResult.outputPath, equals(indexHtml.path));
    });

    test('handles package names with underscores', () async {
      writeIndexHtml(validHtml);

      final injector = HtmlInjector();
      final result = createCollectionResult(
        jsPaths: ['ext/packages/my_editor_pkg/main.js'],
      );

      await injector.inject(indexHtml: indexHtml, collectionResult: result);

      final content = indexHtml.readAsStringSync();
      expect(
        content,
        contains('<script src="ext/packages/my_editor_pkg/main.js"></script>'),
      );
    });
  });
}
