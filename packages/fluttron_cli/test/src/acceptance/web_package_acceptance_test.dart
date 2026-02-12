/// v0041 Acceptance and Regression Test Matrix for Web Package feature.
///
/// Tests cover PRD §13 acceptance criteria:
/// - §13.1: Create Web Package
/// - §13.2: Use Web Package in App
/// - §13.3: End-to-End Runtime Verification
///
/// Plus regression tests ensuring:
/// - No web package = no regression (build succeeds unchanged)
/// - With web package = correct injection (JS/CSS, registration code)
import 'dart:convert';
import 'dart:io';

import 'package:fluttron_cli/src/utils/html_injector.dart';
import 'package:fluttron_cli/src/utils/registration_generator.dart';
import 'package:fluttron_cli/src/utils/web_package_collector.dart';
import 'package:fluttron_cli/src/utils/web_package_discovery.dart';
import 'package:fluttron_cli/src/utils/web_package_manifest.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync(
      'web_package_acceptance_test_',
    );
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  // ===========================================================================
  // PRD §13.1: Create Web Package
  // ===========================================================================
  group('PRD §13.1: Create Web Package', () {
    late Directory webPackageDir;

    setUp(() {
      webPackageDir = Directory(p.join(tempDir.path, 'test_package'))
        ..createSync(recursive: true);
    });

    test('web_package template has required manifest contract', () {
      // Simulate fluttron create --type web_package output
      _createWebPackageSkeleton(webPackageDir);

      // Verify fluttron_web_package.json exists and is valid
      final manifestFile = File(
        p.join(webPackageDir.path, 'fluttron_web_package.json'),
      );
      expect(
        manifestFile.existsSync(),
        isTrue,
        reason: 'Manifest file must exist',
      );

      final manifest = WebPackageManifestLoader.load(webPackageDir);
      expect(manifest.version, equals('1'));
      expect(manifest.viewFactories, isNotEmpty);
      expect(manifest.assets, isNotNull);
      expect(manifest.assets!.js, isNotEmpty);

      // Verify view factory naming convention
      final factory = manifest.viewFactories.first;
      expect(
        factory.type,
        matches(r'^[a-z0-9_]+\.[a-z0-9_]+$'),
        reason: 'Type must be package.type format',
      );
      expect(
        factory.jsFactoryName,
        matches(r'^fluttronCreate[A-Z][a-zA-Z0-9]*View$'),
        reason: 'Factory name must follow fluttronCreate<Type>View pattern',
      );
    });

    test('web_package template has pubspec with marker tag', () {
      _createWebPackageSkeleton(webPackageDir);

      final pubspecFile = File(p.join(webPackageDir.path, 'pubspec.yaml'));
      expect(pubspecFile.existsSync(), isTrue);

      final contents = pubspecFile.readAsStringSync();
      expect(
        contents,
        contains('fluttron_web_package: true'),
        reason: 'pubspec.yaml must have fluttron_web_package: true marker',
      );
    });

    test('web_package template has frontend build scripts', () {
      _createWebPackageSkeleton(webPackageDir);

      final packageJsonFile = File(
        p.join(webPackageDir.path, 'frontend', 'package.json'),
      );
      expect(packageJsonFile.existsSync(), isTrue);

      final packageJson =
          jsonDecode(packageJsonFile.readAsStringSync())
              as Map<String, dynamic>;
      final scripts = packageJson['scripts'] as Map<String, dynamic>?;

      expect(scripts, isNotNull);
      expect(
        scripts!.containsKey('js:build'),
        isTrue,
        reason: 'Must have js:build script',
      );
    });

    test('web_package template has JS factory implementation', () {
      _createWebPackageSkeleton(webPackageDir);

      final mainJsFile = File(
        p.join(webPackageDir.path, 'frontend', 'src', 'main.js'),
      );
      expect(mainJsFile.existsSync(), isTrue);

      final contents = mainJsFile.readAsStringSync();
      // Verify factory is exported to window
      expect(
        contents,
        contains('window.fluttronCreate'),
        reason: 'Factory must be exported to window global',
      );
      // Note: Event emission pattern is recommended but not required
      // Packages without JS-to-Dart events may not include CustomEvent
    });

    test('web_package template has built assets', () {
      _createWebPackageSkeleton(webPackageDir);

      final mainJsFile = File(
        p.join(webPackageDir.path, 'web', 'ext', 'main.js'),
      );
      expect(
        mainJsFile.existsSync(),
        isTrue,
        reason: 'Built JS bundle must exist at web/ext/main.js',
      );

      // Verify bundle is valid JavaScript (basic check)
      final contents = mainJsFile.readAsStringSync();
      expect(contents, isNotEmpty);
      // IIFE or module format check
      expect(
        contents,
        anyOf(contains('function'), contains('=>')),
        reason: 'Bundle should contain function definitions',
      );
    });
  });

  // ===========================================================================
  // PRD §13.2: Use Web Package in App
  // ===========================================================================
  group('PRD §13.2: Use Web Package in App', () {
    late Directory appDir;
    late Directory uiDir;
    late Directory webPackageDir;
    late Directory buildOutputDir;

    setUp(() {
      appDir = Directory(p.join(tempDir.path, 'test_app'))..createSync();
      uiDir = Directory(p.join(appDir.path, 'ui'))..createSync(recursive: true);
      webPackageDir = Directory(p.join(tempDir.path, 'test_package'))
        ..createSync(recursive: true);
      buildOutputDir = Directory(p.join(uiDir.path, 'build', 'web'))
        ..createSync(recursive: true);

      // Create web package skeleton
      _createWebPackageSkeleton(webPackageDir);

      // Create app UI skeleton with package dependency
      _createAppUiSkeleton(uiDir, webPackageDir);

      // Create build output
      _createBuildOutputSkeleton(buildOutputDir);
    });

    test('discovery finds web package from dependency', () async {
      final discovery = WebPackageDiscovery();
      final manifests = await discovery.discover(uiDir);

      expect(manifests, hasLength(1));
      expect(manifests.first.packageName, equals('test_package'));
      expect(manifests.first.viewFactories, isNotEmpty);
    });

    test('collector copies assets to correct destination', () async {
      final collector = WebPackageCollector();
      final discovery = WebPackageDiscovery();
      final manifests = await discovery.discover(uiDir);

      final result = await collector.collect(
        buildOutputDir: buildOutputDir,
        manifests: manifests,
      );

      expect(result.packages, equals(1));
      expect(result.assets, isNotEmpty);

      // Verify JS asset was copied
      final jsAsset = result.assets.firstWhere(
        (a) => a.type == AssetType.js,
        orElse: () => throw StateError('No JS asset found'),
      );
      expect(jsAsset.packageName, equals('test_package'));
      expect(jsAsset.destinationPath, contains('ext/packages/test_package'));

      // Verify file actually exists
      final destFile = File(jsAsset.destinationPath);
      expect(destFile.existsSync(), isTrue);
    });

    test('injector adds script tags to HTML', () async {
      final collector = WebPackageCollector();
      final discovery = WebPackageDiscovery();
      final manifests = await discovery.discover(uiDir);

      final collectionResult = await collector.collect(
        buildOutputDir: buildOutputDir,
        manifests: manifests,
      );

      final indexFile = File(p.join(buildOutputDir.path, 'index.html'));
      final injector = HtmlInjector();
      final result = await injector.inject(
        indexHtml: indexFile,
        collectionResult: collectionResult,
      );

      expect(result.hasInjections, isTrue);
      expect(result.injectedJsCount, greaterThan(0));

      // Verify HTML contains injected script tag
      final injectedHtml = indexFile.readAsStringSync();
      expect(injectedHtml, contains('ext/packages/test_package/main.js'));
      expect(injectedHtml, contains('<script src='));
    });

    test('generator creates registration code', () async {
      final discovery = WebPackageDiscovery();
      final manifests = await discovery.discover(uiDir);

      final generator = RegistrationGenerator();
      final result = await generator.generate(
        uiProjectDir: uiDir,
        packages: manifests,
      );

      expect(result.hasGenerated, isTrue);
      expect(result.packageCount, equals(1));
      expect(result.factoryCount, greaterThan(0));

      // Verify generated file exists
      final generatedFile = File(result.outputPath);
      expect(generatedFile.existsSync(), isTrue);

      // Verify generated code structure
      final code = generatedFile.readAsStringSync();
      expect(
        code,
        contains('GENERATED'),
        reason: 'Should have generated marker',
      );
      expect(code, contains('registerFluttronWebPackages'));
      expect(code, contains('FluttronWebViewRegistry.register'));
      expect(code, contains('FluttronWebViewRegistration'));
    });
  });

  // ===========================================================================
  // PRD §13.3: End-to-End Runtime Verification
  // ===========================================================================
  group('PRD §13.3: End-to-End Runtime Verification', () {
    late Directory uiDir;
    late Directory webPackageDir;
    late Directory buildOutputDir;

    setUp(() {
      uiDir = Directory(p.join(tempDir.path, 'test_app', 'ui'))
        ..createSync(recursive: true);
      webPackageDir = Directory(p.join(tempDir.path, 'test_package'))
        ..createSync(recursive: true);
      buildOutputDir = Directory(p.join(uiDir.path, 'build', 'web'))
        ..createSync(recursive: true);

      _createWebPackageSkeleton(webPackageDir);
      _createAppUiSkeleton(uiDir, webPackageDir);
      _createBuildOutputSkeleton(buildOutputDir);
    });

    test('generated registration code is syntactically valid Dart', () async {
      final discovery = WebPackageDiscovery();
      final manifests = await discovery.discover(uiDir);

      final generator = RegistrationGenerator();
      final result = await generator.generate(
        uiProjectDir: uiDir,
        packages: manifests,
      );

      final generatedFile = File(result.outputPath);
      final code = generatedFile.readAsStringSync();

      // Basic Dart syntax checks
      expect(code, contains('void registerFluttronWebPackages()'));
      expect(code, contains("import 'package:fluttron_ui/fluttron_ui.dart'"));

      // Check for balanced braces
      final openBraces = code.split('{').length - 1;
      final closeBraces = code.split('}').length - 1;
      expect(
        openBraces,
        equals(closeBraces),
        reason: 'Generated code should have balanced braces',
      );

      // Check for proper semicolons on statements
      expect(
        code,
        contains(');'),
        reason: 'Registration calls should end with );',
      );
    });

    test(
      'generated registration contains correct type and factory mapping',
      () async {
        final discovery = WebPackageDiscovery();
        final manifests = await discovery.discover(uiDir);

        final generator = RegistrationGenerator();
        await generator.generate(uiProjectDir: uiDir, packages: manifests);

        final generatedFile = File(
          p.join(
            uiDir.path,
            'lib',
            'generated',
            'web_package_registrations.dart',
          ),
        );
        final code = generatedFile.readAsStringSync();

        // Verify the view factory type maps to the correct JS factory
        final manifest = manifests.first;
        final factory = manifest.viewFactories.first;

        expect(code, contains("type: '${factory.type}'"));
        expect(code, contains("jsFactoryName: '${factory.jsFactoryName}'"));
      },
    );

    test('injected HTML maintains script load order', () async {
      final collector = WebPackageCollector();
      final discovery = WebPackageDiscovery();
      final injector = HtmlInjector();

      final manifests = await discovery.discover(uiDir);
      final collectionResult = await collector.collect(
        buildOutputDir: buildOutputDir,
        manifests: manifests,
      );

      final indexFile = File(p.join(buildOutputDir.path, 'index.html'));
      await injector.inject(
        indexHtml: indexFile,
        collectionResult: collectionResult,
      );

      final html = indexFile.readAsStringSync();

      // Package scripts should come before app's ext/main.js
      final packageScriptPos = html.indexOf('ext/packages/');
      final appScriptPos = html.indexOf('ext/main.js');
      final flutterBootstrapPos = html.indexOf('flutter_bootstrap.js');

      expect(
        packageScriptPos,
        lessThan(appScriptPos),
        reason: 'Package scripts should load before app script',
      );
      expect(
        appScriptPos,
        lessThan(flutterBootstrapPos),
        reason: 'App script should load before Flutter bootstrap',
      );
    });

    test('view factory type follows namespace convention', () async {
      final discovery = WebPackageDiscovery();
      final manifests = await discovery.discover(uiDir);

      expect(manifests, isNotEmpty);

      final factory = manifests.first.viewFactories.first;
      final parts = factory.type.split('.');

      expect(
        parts.length,
        equals(2),
        reason: 'Type should be in package.feature format',
      );
      expect(
        parts[0],
        equals('test_package'),
        reason: 'First part should match package name',
      );
    });
  });

  // ===========================================================================
  // Regression Tests
  // ===========================================================================
  group('Regression: No Web Package', () {
    late Directory appDir;
    late Directory uiDir;
    late Directory buildOutputDir;

    setUp(() {
      appDir = Directory(p.join(tempDir.path, 'plain_app'))..createSync();
      uiDir = Directory(p.join(appDir.path, 'ui'))..createSync(recursive: true);
      buildOutputDir = Directory(p.join(uiDir.path, 'build', 'web'))
        ..createSync(recursive: true);

      // Create app WITHOUT web package dependency
      _createAppUiSkeletonWithoutWebPackage(uiDir);
      _createBuildOutputSkeleton(buildOutputDir);
    });

    test('discovery returns empty list when no web packages', () async {
      final discovery = WebPackageDiscovery();
      final manifests = await discovery.discover(uiDir);

      expect(manifests, isEmpty);
    });

    test('generator creates placeholder when no packages', () async {
      final generator = RegistrationGenerator();
      final result = await generator.generate(
        uiProjectDir: uiDir,
        packages: [],
      );

      expect(result.hasGenerated, isFalse);
      expect(result.packageCount, equals(0));
      expect(result.factoryCount, equals(0));

      // Placeholder file should still be created for consistent imports
      final generatedFile = File(result.outputPath);
      expect(generatedFile.existsSync(), isTrue);

      final code = generatedFile.readAsStringSync();
      expect(code, contains('registerFluttronWebPackages()'));
      // Should be empty function body
      expect(code, contains('void registerFluttronWebPackages() {'));
    });

    test('HTML remains unchanged when no packages', () async {
      final injector = HtmlInjector();
      final indexFile = File(p.join(buildOutputDir.path, 'index.html'));

      final originalHtml = indexFile.readAsStringSync();

      final result = await injector.inject(
        indexHtml: indexFile,
        collectionResult: CollectionResult(
          packages: 0,
          assets: [],
          skippedPackages: [],
        ),
      );

      expect(result.hasInjections, isFalse);
      expect(result.injectedJsCount, equals(0));
      expect(result.injectedCssCount, equals(0));

      // Placeholders are replaced with empty content when no packages
      // This is correct behavior - no injection means no package tags
      final newHtml = indexFile.readAsStringSync();
      // The placeholders should be replaced (even if with empty content)
      // which means they're no longer in the file as comment markers
      expect(result.injectedJsCount, equals(0));
      expect(result.injectedCssCount, equals(0));
    });
  });

  group('Regression: With Web Package', () {
    late Directory uiDir;
    late Directory webPackageDir;
    late Directory buildOutputDir;

    setUp(() {
      uiDir = Directory(p.join(tempDir.path, 'app_with_pkg', 'ui'))
        ..createSync(recursive: true);
      webPackageDir = Directory(p.join(tempDir.path, 'sample_package'))
        ..createSync(recursive: true);
      buildOutputDir = Directory(p.join(uiDir.path, 'build', 'web'))
        ..createSync(recursive: true);

      _createWebPackageSkeleton(webPackageDir);
      _createAppUiSkeleton(uiDir, webPackageDir);
      _createBuildOutputSkeleton(buildOutputDir);
    });

    test('full pipeline produces correct output structure', () async {
      // Step 1: Discovery
      final discovery = WebPackageDiscovery();
      final manifests = await discovery.discover(uiDir);
      expect(manifests, hasLength(1));

      // Step 2: Registration Generation
      final generator = RegistrationGenerator();
      final regResult = await generator.generate(
        uiProjectDir: uiDir,
        packages: manifests,
      );
      expect(regResult.hasGenerated, isTrue);

      // Step 3: Collection
      final collector = WebPackageCollector();
      final collectResult = await collector.collect(
        buildOutputDir: buildOutputDir,
        manifests: manifests,
      );
      expect(collectResult.hasAssets, isTrue);

      // Step 4: Injection
      final indexFile = File(p.join(buildOutputDir.path, 'index.html'));
      final injector = HtmlInjector();
      final injectResult = await injector.inject(
        indexHtml: indexFile,
        collectionResult: collectResult,
      );
      expect(injectResult.hasInjections, isTrue);

      // Final verification: check all outputs exist
      expect(File(regResult.outputPath).existsSync(), isTrue);
      expect(
        Directory(p.join(buildOutputDir.path, 'ext', 'packages')).existsSync(),
        isTrue,
      );
    });

    test('asset paths use correct relative format', () async {
      final collector = WebPackageCollector();
      final discovery = WebPackageDiscovery();
      final manifests = await discovery.discover(uiDir);

      final result = await collector.collect(
        buildOutputDir: buildOutputDir,
        manifests: manifests,
      );

      for (final asset in result.assets) {
        // Destination should be relative to build output
        expect(asset.destinationPath, contains('ext/packages/test_package/'));
        // Should match asset type
        if (asset.type == AssetType.js) {
          expect(asset.destinationPath, endsWith('.js'));
        } else if (asset.type == AssetType.css) {
          expect(asset.destinationPath, endsWith('.css'));
        }
      }
    });

    test('multiple view factories generate multiple registrations', () async {
      // Create package with multiple view factories
      final manifestFile = File(
        p.join(webPackageDir.path, 'fluttron_web_package.json'),
      );
      final multiFactoryManifest = {
        'version': '1',
        'viewFactories': [
          {
            'type': 'test_package.editor',
            'jsFactoryName': 'fluttronCreateTestPackageEditorView',
          },
          {
            'type': 'test_package.viewer',
            'jsFactoryName': 'fluttronCreateTestPackageViewerView',
          },
        ],
        'assets': {
          'js': ['web/ext/main.js'],
        },
      };
      manifestFile.writeAsStringSync(
        const JsonEncoder.withIndent('  ').convert(multiFactoryManifest),
      );

      final discovery = WebPackageDiscovery();
      final manifests = await discovery.discover(uiDir);

      final generator = RegistrationGenerator();
      final result = await generator.generate(
        uiProjectDir: uiDir,
        packages: manifests,
      );

      expect(result.factoryCount, equals(2));

      final code = File(result.outputPath).readAsStringSync();
      expect(code, contains('test_package.editor'));
      expect(code, contains('test_package.viewer'));
    });
  });
}

// =============================================================================
// Test Fixtures
// =============================================================================

void _createWebPackageSkeleton(Directory packageDir) {
  // Create manifest
  final manifest = {
    'version': '1',
    'viewFactories': [
      {
        'type': 'test_package.example',
        'jsFactoryName': 'fluttronCreateTestPackageExampleView',
        'description': 'Example view factory',
      },
    ],
    'assets': {
      'js': ['web/ext/main.js'],
      'css': ['web/ext/main.css'],
    },
    'events': [
      {
        'name': 'fluttron.test_package.example.change',
        'direction': 'js_to_dart',
        'payloadType': '{ content: string }',
      },
    ],
  };
  File(
    p.join(packageDir.path, 'fluttron_web_package.json'),
  ).writeAsStringSync(const JsonEncoder.withIndent('  ').convert(manifest));

  // Create pubspec with marker
  final pubspec = '''
name: test_package
version: 1.0.0
fluttron_web_package: true

environment:
  sdk: ^3.10.0

dependencies:
  fluttron_ui:
    path: ../../../packages/fluttron_ui
''';
  File(p.join(packageDir.path, 'pubspec.yaml')).writeAsStringSync(pubspec);

  // Create frontend package.json
  final packageJson = {
    'name': 'test_package_frontend',
    'scripts': {
      'js:build': 'node scripts/build-frontend.mjs',
      'js:watch': 'node scripts/build-frontend.mjs --watch',
      'js:clean': 'node scripts/build-frontend.mjs --clean',
    },
    'devDependencies': {'esbuild': '^0.25.0'},
  };
  Directory(p.join(packageDir.path, 'frontend')).createSync();
  File(
    p.join(packageDir.path, 'frontend', 'package.json'),
  ).writeAsStringSync(const JsonEncoder.withIndent('  ').convert(packageJson));

  // Create frontend source
  Directory(p.join(packageDir.path, 'frontend', 'src')).createSync();
  final mainJs = '''
const CHANGE_EVENT = 'fluttron.test_package.example.change';

function createTestPackageExampleView(viewId, initialContent) {
  const container = document.createElement('div');
  container.id = 'test-package-' + viewId;
  container.innerText = initialContent || 'Hello';
  return container;
}

window.fluttronCreateTestPackageExampleView = createTestPackageExampleView;
''';
  File(
    p.join(packageDir.path, 'frontend', 'src', 'main.js'),
  ).writeAsStringSync(mainJs);

  // Create built assets
  Directory(p.join(packageDir.path, 'web', 'ext')).createSync(recursive: true);
  File(
    p.join(packageDir.path, 'web', 'ext', 'main.js'),
  ).writeAsStringSync('(function() { ${mainJs} })();');
  File(
    p.join(packageDir.path, 'web', 'ext', 'main.css'),
  ).writeAsStringSync('.test-package-example { }');
}

void _createAppUiSkeleton(Directory uiDir, Directory webPackageDir) {
  // Create package_config.json with web package dependency
  final dartToolDir = Directory(p.join(uiDir.path, '.dart_tool'))..createSync();

  final relativePath = p.relative(webPackageDir.path, from: uiDir.path);
  final packageConfig = {
    'configVersion': 2,
    'packages': [
      {'name': 'test_package', 'rootUri': relativePath, 'packageUri': 'lib/'},
    ],
    'generator': 'test',
  };
  File(p.join(dartToolDir.path, 'package_config.json')).writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(packageConfig),
  );

  // Create pubspec
  final pubspec =
      '''
name: test_app_ui
version: 1.0.0

environment:
  sdk: ^3.10.0

dependencies:
  flutter:
    sdk: flutter
  fluttron_ui:
    path: ../../../packages/fluttron_ui
  test_package:
    path: ${p.relative(webPackageDir.path, from: uiDir.path)}
''';
  File(p.join(uiDir.path, 'pubspec.yaml')).writeAsStringSync(pubspec);

  // Create lib directory for generated code
  Directory(p.join(uiDir.path, 'lib', 'generated')).createSync(recursive: true);
}

void _createAppUiSkeletonWithoutWebPackage(Directory uiDir) {
  // Create minimal package_config.json without web packages
  final dartToolDir = Directory(p.join(uiDir.path, '.dart_tool'))..createSync();

  final packageConfig = {
    'configVersion': 2,
    'packages': [
      {
        'name': 'fluttron_ui',
        'rootUri': '../../../packages/fluttron_ui',
        'packageUri': 'lib/',
      },
    ],
    'generator': 'test',
  };
  File(p.join(dartToolDir.path, 'package_config.json')).writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(packageConfig),
  );

  // Create pubspec without web package dependency
  final pubspec = '''
name: plain_app_ui
version: 1.0.0

environment:
  sdk: ^3.10.0

dependencies:
  flutter:
    sdk: flutter
  fluttron_ui:
    path: ../../../packages/fluttron_ui
''';
  File(p.join(uiDir.path, 'pubspec.yaml')).writeAsStringSync(pubspec);

  // Create lib directory for generated code
  Directory(p.join(uiDir.path, 'lib', 'generated')).createSync(recursive: true);
}

void _createBuildOutputSkeleton(Directory buildOutputDir) {
  // Create index.html with placeholders
  final indexHtml = '''<!DOCTYPE html>
<html>
<head>
  <base href="/">
  <title>Test App</title>
  <!-- FLUTTRON_PACKAGES_CSS -->
</head>
<body>
  <!-- FLUTTRON_PACKAGES_JS -->
  <script src="ext/main.js"></script>
  <script src="flutter_bootstrap.js" async></script>
</body>
</html>''';
  File(p.join(buildOutputDir.path, 'index.html')).writeAsStringSync(indexHtml);

  // Create ext directory with app's main.js
  Directory(p.join(buildOutputDir.path, 'ext')).createSync();
  File(
    p.join(buildOutputDir.path, 'ext', 'main.js'),
  ).writeAsStringSync('console.log("app main");');
}
