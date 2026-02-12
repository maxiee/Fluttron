import 'dart:io';

import 'package:fluttron_shared/fluttron_shared.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'package:fluttron_cli/src/utils/file_ops.dart';
import 'package:fluttron_cli/src/utils/frontend_builder.dart';
import 'package:fluttron_cli/src/utils/html_injector.dart';
import 'package:fluttron_cli/src/utils/registration_generator.dart';
import 'package:fluttron_cli/src/utils/ui_build_pipeline.dart';
import 'package:fluttron_cli/src/utils/web_package_collector.dart';
import 'package:fluttron_cli/src/utils/web_package_discovery.dart';
import 'package:fluttron_cli/src/utils/web_package_manifest.dart';

void main() {
  group('UiBuildPipeline', () {
    late Directory projectDir;

    setUp(() {
      projectDir = Directory.systemTemp.createTempSync(
        'ui_build_pipeline_test_',
      );
    });

    tearDown(() {
      if (projectDir.existsSync()) {
        projectDir.deleteSync(recursive: true);
      }
    });

    test('runs frontend, flutter build, clear, and copy in order', () async {
      final uiDir = Directory(p.join(projectDir.path, 'ui'))..createSync();
      final sourceWebDir = Directory(p.join(uiDir.path, 'web'))
        ..createSync(recursive: true);
      _writeIndex(sourceWebDir, const <String>['ext/main.js']);
      _writeFile(sourceWebDir, 'ext/main.js', 'console.log("source");');

      final hostAssetsDir = Directory(
        p.join(projectDir.path, 'host', 'assets', 'www'),
      )..createSync(recursive: true);
      final buildOutputDir = Directory(p.join(uiDir.path, 'build', 'web'))
        ..createSync(recursive: true);
      _writeIndex(buildOutputDir, const <String>['ext/main.js']);
      _writeFile(buildOutputDir, 'ext/main.js', 'console.log("build");');

      final events = <String>[];
      final pipeline = UiBuildPipeline(
        frontendBuilder: _FakeFrontendBuilder((_) async {
          events.add('frontend');
          return const FrontendBuildResult.built();
        }),
        commandRunner:
            (
              String executable,
              List<String> arguments, {
              required String workingDirectory,
              required bool streamOutput,
            }) async {
              events.add('flutter');
              expect(executable, 'flutter');
              expect(arguments, const <String>['build', 'web']);
              expect(workingDirectory, uiDir.path);
              return const ProcessCommandResult(
                exitCode: 0,
                stdout: '',
                stderr: '',
              );
            },
        clearDirectoryFn: (Directory directory) async {
          events.add('clear');
          expect(directory.path, hostAssetsDir.path);
          await clearDirectory(directory);
        },
        copyDirectoryFn:
            ({
              required Directory sourceDir,
              required Directory destinationDir,
            }) async {
              events.add('copy');
              expect(sourceDir.path, buildOutputDir.path);
              expect(destinationDir.path, hostAssetsDir.path);
              await copyDirectoryContents(
                sourceDir: sourceDir,
                destinationDir: destinationDir,
              );
            },
        webPackageDiscoveryFn: (Directory uiProjectDir) async {
          events.add('discovery');
          return []; // No web packages
        },
        registrationGenerateFn:
            ({
              required Directory uiProjectDir,
              required List<WebPackageManifest> packages,
              String? outputDir,
            }) async {
              events.add('registration');
              return RegistrationResult(
                outputPath: '',
                packageCount: 0,
                factoryCount: 0,
                hasGenerated: false,
              );
            },
        writeOut: (_) {},
        writeErr: (_) {},
      );

      final exitCode = await pipeline.build(
        projectDir: projectDir,
        manifestPath: p.join(projectDir.path, 'fluttron.json'),
        manifest: const FluttronManifest(
          name: 'demo',
          version: '0.1.0',
          entry: EntryConfig(
            uiProjectPath: 'ui',
            hostAssetPath: 'host/assets/www',
            index: 'index.html',
          ),
        ),
      );

      expect(exitCode, 0);
      expect(events, <String>[
        'frontend',
        'discovery',
        'registration',
        'flutter',
        'clear',
        'copy',
      ]);
      expect(
        File(p.join(hostAssetsDir.path, 'ext', 'main.js')).existsSync(),
        isTrue,
      );
    });

    test('stops immediately when frontend build fails', () async {
      final uiDir = Directory(p.join(projectDir.path, 'ui'))..createSync();
      final hostAssetsDir = Directory(
        p.join(projectDir.path, 'host', 'assets', 'www'),
      )..createSync(recursive: true);

      var flutterCalled = false;
      var clearCalled = false;
      var copyCalled = false;
      final pipeline = UiBuildPipeline(
        frontendBuilder: _FakeFrontendBuilder((_) async {
          throw const FrontendBuildException('frontend failed', exitCode: 9);
        }),
        commandRunner:
            (
              String executable,
              List<String> arguments, {
              required String workingDirectory,
              required bool streamOutput,
            }) async {
              flutterCalled = true;
              return const ProcessCommandResult(
                exitCode: 0,
                stdout: '',
                stderr: '',
              );
            },
        clearDirectoryFn: (Directory directory) async {
          clearCalled = true;
        },
        copyDirectoryFn:
            ({
              required Directory sourceDir,
              required Directory destinationDir,
            }) async {
              copyCalled = true;
            },
        webPackageDiscoveryFn: (Directory uiProjectDir) async {
          return [];
        },
        registrationGenerateFn:
            ({
              required Directory uiProjectDir,
              required List<WebPackageManifest> packages,
              String? outputDir,
            }) async {
              return RegistrationResult(
                outputPath: '',
                packageCount: 0,
                factoryCount: 0,
                hasGenerated: false,
              );
            },
        writeOut: (_) {},
        writeErr: (_) {},
      );

      final exitCode = await pipeline.build(
        projectDir: projectDir,
        manifestPath: p.join(projectDir.path, 'fluttron.json'),
        manifest: const FluttronManifest(
          name: 'demo',
          version: '0.1.0',
          entry: EntryConfig(
            uiProjectPath: 'ui',
            hostAssetPath: 'host/assets/www',
            index: 'index.html',
          ),
        ),
      );

      expect(uiDir.existsSync(), isTrue);
      expect(hostAssetsDir.existsSync(), isTrue);
      expect(exitCode, 9);
      expect(flutterCalled, isFalse);
      expect(clearCalled, isFalse);
      expect(copyCalled, isFalse);
    });

    test(
      'fails before flutter build when source JS assets are missing',
      () async {
        final uiDir = Directory(p.join(projectDir.path, 'ui'))..createSync();
        final sourceWebDir = Directory(p.join(uiDir.path, 'web'))
          ..createSync(recursive: true);
        _writeIndex(sourceWebDir, const <String>['ext/main.js']);

        Directory(
          p.join(projectDir.path, 'host', 'assets', 'www'),
        ).createSync(recursive: true);

        var flutterCalled = false;
        var clearCalled = false;
        var copyCalled = false;
        final pipeline = UiBuildPipeline(
          frontendBuilder: _FakeFrontendBuilder((_) async {
            return const FrontendBuildResult.built();
          }),
          commandRunner:
              (
                String executable,
                List<String> arguments, {
                required String workingDirectory,
                required bool streamOutput,
              }) async {
                flutterCalled = true;
                return const ProcessCommandResult(
                  exitCode: 0,
                  stdout: '',
                  stderr: '',
                );
              },
          clearDirectoryFn: (Directory directory) async {
            clearCalled = true;
          },
          copyDirectoryFn:
              ({
                required Directory sourceDir,
                required Directory destinationDir,
              }) async {
                copyCalled = true;
              },
          webPackageDiscoveryFn: (Directory uiProjectDir) async {
            return [];
          },
          registrationGenerateFn:
              ({
                required Directory uiProjectDir,
                required List<WebPackageManifest> packages,
                String? outputDir,
              }) async {
                return RegistrationResult(
                  outputPath: '',
                  packageCount: 0,
                  factoryCount: 0,
                  hasGenerated: false,
                );
              },
          writeOut: (_) {},
          writeErr: (_) {},
        );

        final exitCode = await pipeline.build(
          projectDir: projectDir,
          manifestPath: p.join(projectDir.path, 'fluttron.json'),
          manifest: const FluttronManifest(
            name: 'demo',
            version: '0.1.0',
            entry: EntryConfig(
              uiProjectPath: 'ui',
              hostAssetPath: 'host/assets/www',
              index: 'index.html',
            ),
          ),
        );

        expect(exitCode, 2);
        expect(flutterCalled, isFalse);
        expect(clearCalled, isFalse);
        expect(copyCalled, isFalse);
      },
    );

    test('fails when JS assets are missing after host copy', () async {
      final uiDir = Directory(p.join(projectDir.path, 'ui'))..createSync();
      final sourceWebDir = Directory(p.join(uiDir.path, 'web'))
        ..createSync(recursive: true);
      _writeIndex(sourceWebDir, const <String>['ext/main.js']);
      _writeFile(sourceWebDir, 'ext/main.js', 'console.log("source");');

      final hostAssetsDir = Directory(
        p.join(projectDir.path, 'host', 'assets', 'www'),
      )..createSync(recursive: true);
      final buildOutputDir = Directory(p.join(uiDir.path, 'build', 'web'))
        ..createSync(recursive: true);
      _writeIndex(buildOutputDir, const <String>['ext/main.js']);
      _writeFile(buildOutputDir, 'ext/main.js', 'console.log("build");');

      var flutterCalled = false;
      var clearCalled = false;
      var copyCalled = false;
      final pipeline = UiBuildPipeline(
        frontendBuilder: _FakeFrontendBuilder((_) async {
          return const FrontendBuildResult.built();
        }),
        commandRunner:
            (
              String executable,
              List<String> arguments, {
              required String workingDirectory,
              required bool streamOutput,
            }) async {
              flutterCalled = true;
              return const ProcessCommandResult(
                exitCode: 0,
                stdout: '',
                stderr: '',
              );
            },
        clearDirectoryFn: (Directory directory) async {
          clearCalled = true;
          await clearDirectory(directory);
        },
        copyDirectoryFn:
            ({
              required Directory sourceDir,
              required Directory destinationDir,
            }) async {
              copyCalled = true;
              final indexContents = File(
                p.join(sourceDir.path, 'index.html'),
              ).readAsStringSync();
              File(
                p.join(destinationDir.path, 'index.html'),
              ).writeAsStringSync(indexContents);
            },
        webPackageDiscoveryFn: (Directory uiProjectDir) async {
          return [];
        },
        registrationGenerateFn:
            ({
              required Directory uiProjectDir,
              required List<WebPackageManifest> packages,
              String? outputDir,
            }) async {
              return RegistrationResult(
                outputPath: '',
                packageCount: 0,
                factoryCount: 0,
                hasGenerated: false,
              );
            },
        writeOut: (_) {},
        writeErr: (_) {},
      );

      final exitCode = await pipeline.build(
        projectDir: projectDir,
        manifestPath: p.join(projectDir.path, 'fluttron.json'),
        manifest: const FluttronManifest(
          name: 'demo',
          version: '0.1.0',
          entry: EntryConfig(
            uiProjectPath: 'ui',
            hostAssetPath: 'host/assets/www',
            index: 'index.html',
          ),
        ),
      );

      expect(exitCode, 2);
      expect(flutterCalled, isTrue);
      expect(clearCalled, isTrue);
      expect(copyCalled, isTrue);
      expect(
        File(p.join(hostAssetsDir.path, 'ext', 'main.js')).existsSync(),
        isFalse,
      );
    });

    group('web package integration', () {
      test('skips web package stages when no packages discovered', () async {
        final uiDir = Directory(p.join(projectDir.path, 'ui'))..createSync();
        final sourceWebDir = Directory(p.join(uiDir.path, 'web'))
          ..createSync(recursive: true);
        _writeIndex(sourceWebDir, const <String>['ext/main.js']);
        _writeFile(sourceWebDir, 'ext/main.js', 'console.log("source");');

        final hostAssetsDir = Directory(
          p.join(projectDir.path, 'host', 'assets', 'www'),
        )..createSync(recursive: true);
        final buildOutputDir = Directory(p.join(uiDir.path, 'build', 'web'))
          ..createSync(recursive: true);
        _writeIndex(buildOutputDir, const <String>['ext/main.js']);
        _writeFile(buildOutputDir, 'ext/main.js', 'console.log("build");');

        final events = <String>[];
        final pipeline = UiBuildPipeline(
          frontendBuilder: _FakeFrontendBuilder((_) async {
            events.add('frontend');
            return const FrontendBuildResult.built();
          }),
          commandRunner:
              (
                String executable,
                List<String> arguments, {
                required String workingDirectory,
                required bool streamOutput,
              }) async {
                events.add('flutter');
                return const ProcessCommandResult(
                  exitCode: 0,
                  stdout: '',
                  stderr: '',
                );
              },
          clearDirectoryFn: (Directory directory) async {
            events.add('clear');
            await clearDirectory(directory);
          },
          copyDirectoryFn:
              ({
                required Directory sourceDir,
                required Directory destinationDir,
              }) async {
                events.add('copy');
                await copyDirectoryContents(
                  sourceDir: sourceDir,
                  destinationDir: destinationDir,
                );
              },
          webPackageDiscoveryFn: (Directory uiProjectDir) async {
            events.add('discovery');
            return []; // No web packages
          },
          registrationGenerateFn:
              ({
                required Directory uiProjectDir,
                required List<WebPackageManifest> packages,
                String? outputDir,
              }) async {
                events.add('registration');
                expect(packages, isEmpty);
                return RegistrationResult(
                  outputPath: '',
                  packageCount: 0,
                  factoryCount: 0,
                  hasGenerated: false,
                );
              },
          webPackageCollectFn:
              ({
                required Directory buildOutputDir,
                required List<WebPackageManifest> manifests,
              }) async {
                events.add('collect');
                return CollectionResult(
                  packages: 0,
                  assets: [],
                  skippedPackages: [],
                );
              },
          htmlInjectFn:
              ({
                required File indexHtml,
                required CollectionResult collectionResult,
              }) async {
                events.add('inject');
                return InjectionResult(
                  injectedJsCount: 0,
                  injectedCssCount: 0,
                  outputPath: indexHtml.path,
                );
              },
          writeOut: (_) {},
          writeErr: (_) {},
        );

        final exitCode = await pipeline.build(
          projectDir: projectDir,
          manifestPath: p.join(projectDir.path, 'fluttron.json'),
          manifest: const FluttronManifest(
            name: 'demo',
            version: '0.1.0',
            entry: EntryConfig(
              uiProjectPath: 'ui',
              hostAssetPath: 'host/assets/www',
              index: 'index.html',
            ),
          ),
        );

        expect(exitCode, 0);
        // discovery and registration should be called, but not collect/inject
        expect(events, containsAll(['discovery', 'registration']));
        expect(events, isNot(contains('collect')));
        expect(events, isNot(contains('inject')));
      });

      test(
        'executes all web package stages when packages discovered',
        () async {
          final uiDir = Directory(p.join(projectDir.path, 'ui'))..createSync();
          final sourceWebDir = Directory(p.join(uiDir.path, 'web'))
            ..createSync(recursive: true);
          _writeIndexWithPlaceholders(sourceWebDir, const <String>[
            'ext/main.js',
          ]);
          _writeFile(sourceWebDir, 'ext/main.js', 'console.log("source");');

          final hostAssetsDir = Directory(
            p.join(projectDir.path, 'host', 'assets', 'www'),
          )..createSync(recursive: true);
          final buildOutputDir = Directory(p.join(uiDir.path, 'build', 'web'))
            ..createSync(recursive: true);
          _writeIndexWithPlaceholders(buildOutputDir, const <String>[
            'ext/main.js',
          ]);
          _writeFile(buildOutputDir, 'ext/main.js', 'console.log("build");');

          final mockPackage = WebPackageManifest(
            version: '1',
            viewFactories: [
              ViewFactory(
                type: 'test.editor',
                jsFactoryName: 'fluttronCreateTestEditorView',
              ),
            ],
            assets: Assets(js: ['web/ext/main.js'], css: null),
            events: null,
            packageName: 'test_package',
            rootPath: '/fake/path',
          );

          final events = <String>[];
          final pipeline = UiBuildPipeline(
            frontendBuilder: _FakeFrontendBuilder((_) async {
              events.add('frontend');
              return const FrontendBuildResult.built();
            }),
            commandRunner:
                (
                  String executable,
                  List<String> arguments, {
                  required String workingDirectory,
                  required bool streamOutput,
                }) async {
                  events.add('flutter');
                  return const ProcessCommandResult(
                    exitCode: 0,
                    stdout: '',
                    stderr: '',
                  );
                },
            clearDirectoryFn: (Directory directory) async {
              events.add('clear');
              await clearDirectory(directory);
            },
            copyDirectoryFn:
                ({
                  required Directory sourceDir,
                  required Directory destinationDir,
                }) async {
                  events.add('copy');
                  await copyDirectoryContents(
                    sourceDir: sourceDir,
                    destinationDir: destinationDir,
                  );
                },
            webPackageDiscoveryFn: (Directory uiProjectDir) async {
              events.add('discovery');
              return [mockPackage];
            },
            registrationGenerateFn:
                ({
                  required Directory uiProjectDir,
                  required List<WebPackageManifest> packages,
                  String? outputDir,
                }) async {
                  events.add('registration');
                  expect(packages.length, 1);
                  expect(packages.first.packageName, 'test_package');
                  return RegistrationResult(
                    outputPath: p.join(
                      uiProjectDir.path,
                      'lib',
                      'generated',
                      'web_package_registrations.dart',
                    ),
                    packageCount: 1,
                    factoryCount: 1,
                    hasGenerated: true,
                  );
                },
            webPackageCollectFn:
                ({
                  required Directory buildOutputDir,
                  required List<WebPackageManifest> manifests,
                }) async {
                  events.add('collect');
                  expect(manifests.length, 1);
                  final asset = CollectedAsset(
                    packageName: 'test_package',
                    relativePath: 'web/ext/main.js',
                    sourcePath: '/fake/path/web/ext/main.js',
                    destinationPath: p.join(
                      buildOutputDir.path,
                      'ext/packages/test_package/main.js',
                    ),
                    type: AssetType.js,
                  );
                  return CollectionResult(
                    packages: 1,
                    assets: [asset],
                    skippedPackages: [],
                  );
                },
            htmlInjectFn:
                ({
                  required File indexHtml,
                  required CollectionResult collectionResult,
                }) async {
                  events.add('inject');
                  expect(collectionResult.hasAssets, isTrue);
                  expect(collectionResult.jsAssetPaths.length, 1);
                  return InjectionResult(
                    injectedJsCount: 1,
                    injectedCssCount: 0,
                    outputPath: indexHtml.path,
                  );
                },
            writeOut: (_) {},
            writeErr: (_) {},
          );

          final exitCode = await pipeline.build(
            projectDir: projectDir,
            manifestPath: p.join(projectDir.path, 'fluttron.json'),
            manifest: const FluttronManifest(
              name: 'demo',
              version: '0.1.0',
              entry: EntryConfig(
                uiProjectPath: 'ui',
                hostAssetPath: 'host/assets/www',
                index: 'index.html',
              ),
            ),
          );

          expect(exitCode, 0);
          // All stages should be called in order
          expect(
            events,
            containsAllInOrder([
              'frontend',
              'discovery',
              'registration',
              'flutter',
              'collect',
              'inject',
              'clear',
              'copy',
            ]),
          );
        },
      );

      test('stops when web package discovery fails', () async {
        final uiDir = Directory(p.join(projectDir.path, 'ui'))..createSync();
        final sourceWebDir = Directory(p.join(uiDir.path, 'web'))
          ..createSync(recursive: true);
        _writeIndex(sourceWebDir, const <String>['ext/main.js']);
        _writeFile(sourceWebDir, 'ext/main.js', 'console.log("source");');

        Directory(p.join(projectDir.path, 'host', 'assets', 'www'))
          ..createSync(recursive: true);

        var flutterCalled = false;
        final pipeline = UiBuildPipeline(
          frontendBuilder: _FakeFrontendBuilder((_) async {
            return const FrontendBuildResult.built();
          }),
          commandRunner:
              (
                String executable,
                List<String> arguments, {
                required String workingDirectory,
                required bool streamOutput,
              }) async {
                flutterCalled = true;
                return const ProcessCommandResult(
                  exitCode: 0,
                  stdout: '',
                  stderr: '',
                );
              },
          webPackageDiscoveryFn: (Directory uiProjectDir) async {
            throw WebPackageDiscoveryException('Discovery failed');
          },
          writeOut: (_) {},
          writeErr: (_) {},
        );

        final exitCode = await pipeline.build(
          projectDir: projectDir,
          manifestPath: p.join(projectDir.path, 'fluttron.json'),
          manifest: const FluttronManifest(
            name: 'demo',
            version: '0.1.0',
            entry: EntryConfig(
              uiProjectPath: 'ui',
              hostAssetPath: 'host/assets/www',
              index: 'index.html',
            ),
          ),
        );

        expect(exitCode, 2);
        expect(flutterCalled, isFalse);
      });

      test('stops when registration generation fails', () async {
        final uiDir = Directory(p.join(projectDir.path, 'ui'))..createSync();
        final sourceWebDir = Directory(p.join(uiDir.path, 'web'))
          ..createSync(recursive: true);
        _writeIndex(sourceWebDir, const <String>['ext/main.js']);
        _writeFile(sourceWebDir, 'ext/main.js', 'console.log("source");');

        Directory(p.join(projectDir.path, 'host', 'assets', 'www'))
          ..createSync(recursive: true);

        var flutterCalled = false;
        final mockPackage = WebPackageManifest(
          version: '1',
          viewFactories: [
            ViewFactory(
              type: 'test.editor',
              jsFactoryName: 'fluttronCreateTestEditorView',
            ),
          ],
          assets: Assets(js: ['web/ext/main.js'], css: null),
          events: null,
          packageName: 'test_package',
          rootPath: '/fake/path',
        );

        final pipeline = UiBuildPipeline(
          frontendBuilder: _FakeFrontendBuilder((_) async {
            return const FrontendBuildResult.built();
          }),
          commandRunner:
              (
                String executable,
                List<String> arguments, {
                required String workingDirectory,
                required bool streamOutput,
              }) async {
                flutterCalled = true;
                return const ProcessCommandResult(
                  exitCode: 0,
                  stdout: '',
                  stderr: '',
                );
              },
          webPackageDiscoveryFn: (Directory uiProjectDir) async {
            return [mockPackage];
          },
          registrationGenerateFn:
              ({
                required Directory uiProjectDir,
                required List<WebPackageManifest> packages,
                String? outputDir,
              }) async {
                throw RegistrationGeneratorException('Generation failed');
              },
          writeOut: (_) {},
          writeErr: (_) {},
        );

        final exitCode = await pipeline.build(
          projectDir: projectDir,
          manifestPath: p.join(projectDir.path, 'fluttron.json'),
          manifest: const FluttronManifest(
            name: 'demo',
            version: '0.1.0',
            entry: EntryConfig(
              uiProjectPath: 'ui',
              hostAssetPath: 'host/assets/www',
              index: 'index.html',
            ),
          ),
        );

        expect(exitCode, 2);
        expect(flutterCalled, isFalse);
      });

      test('stops when asset collection fails', () async {
        final uiDir = Directory(p.join(projectDir.path, 'ui'))..createSync();
        final sourceWebDir = Directory(p.join(uiDir.path, 'web'))
          ..createSync(recursive: true);
        _writeIndex(sourceWebDir, const <String>['ext/main.js']);
        _writeFile(sourceWebDir, 'ext/main.js', 'console.log("source");');

        final buildOutputDir = Directory(p.join(uiDir.path, 'build', 'web'))
          ..createSync(recursive: true);
        _writeIndex(buildOutputDir, const <String>['ext/main.js']);
        _writeFile(buildOutputDir, 'ext/main.js', 'console.log("build");');

        Directory(p.join(projectDir.path, 'host', 'assets', 'www'))
          ..createSync(recursive: true);

        var clearCalled = false;
        final mockPackage = WebPackageManifest(
          version: '1',
          viewFactories: [
            ViewFactory(
              type: 'test.editor',
              jsFactoryName: 'fluttronCreateTestEditorView',
            ),
          ],
          assets: Assets(js: ['web/ext/main.js'], css: null),
          events: null,
          packageName: 'test_package',
          rootPath: '/fake/path',
        );

        final pipeline = UiBuildPipeline(
          frontendBuilder: _FakeFrontendBuilder((_) async {
            return const FrontendBuildResult.built();
          }),
          commandRunner:
              (
                String executable,
                List<String> arguments, {
                required String workingDirectory,
                required bool streamOutput,
              }) async {
                return const ProcessCommandResult(
                  exitCode: 0,
                  stdout: '',
                  stderr: '',
                );
              },
          clearDirectoryFn: (Directory directory) async {
            clearCalled = true;
          },
          webPackageDiscoveryFn: (Directory uiProjectDir) async {
            return [mockPackage];
          },
          registrationGenerateFn:
              ({
                required Directory uiProjectDir,
                required List<WebPackageManifest> packages,
                String? outputDir,
              }) async {
                return RegistrationResult(
                  outputPath: '',
                  packageCount: 1,
                  factoryCount: 1,
                  hasGenerated: true,
                );
              },
          webPackageCollectFn:
              ({
                required Directory buildOutputDir,
                required List<WebPackageManifest> manifests,
              }) async {
                throw WebPackageCollectorException('Collection failed');
              },
          writeOut: (_) {},
          writeErr: (_) {},
        );

        final exitCode = await pipeline.build(
          projectDir: projectDir,
          manifestPath: p.join(projectDir.path, 'fluttron.json'),
          manifest: const FluttronManifest(
            name: 'demo',
            version: '0.1.0',
            entry: EntryConfig(
              uiProjectPath: 'ui',
              hostAssetPath: 'host/assets/www',
              index: 'index.html',
            ),
          ),
        );

        expect(exitCode, 2);
        expect(clearCalled, isFalse);
      });

      test('stops when HTML injection fails', () async {
        final uiDir = Directory(p.join(projectDir.path, 'ui'))..createSync();
        final sourceWebDir = Directory(p.join(uiDir.path, 'web'))
          ..createSync(recursive: true);
        _writeIndex(sourceWebDir, const <String>['ext/main.js']);
        _writeFile(sourceWebDir, 'ext/main.js', 'console.log("source");');

        final buildOutputDir = Directory(p.join(uiDir.path, 'build', 'web'))
          ..createSync(recursive: true);
        _writeIndex(buildOutputDir, const <String>['ext/main.js']);
        _writeFile(buildOutputDir, 'ext/main.js', 'console.log("build");');

        Directory(p.join(projectDir.path, 'host', 'assets', 'www'))
          ..createSync(recursive: true);

        var clearCalled = false;
        final mockPackage = WebPackageManifest(
          version: '1',
          viewFactories: [
            ViewFactory(
              type: 'test.editor',
              jsFactoryName: 'fluttronCreateTestEditorView',
            ),
          ],
          assets: Assets(js: ['web/ext/main.js'], css: null),
          events: null,
          packageName: 'test_package',
          rootPath: '/fake/path',
        );

        final pipeline = UiBuildPipeline(
          frontendBuilder: _FakeFrontendBuilder((_) async {
            return const FrontendBuildResult.built();
          }),
          commandRunner:
              (
                String executable,
                List<String> arguments, {
                required String workingDirectory,
                required bool streamOutput,
              }) async {
                return const ProcessCommandResult(
                  exitCode: 0,
                  stdout: '',
                  stderr: '',
                );
              },
          clearDirectoryFn: (Directory directory) async {
            clearCalled = true;
          },
          webPackageDiscoveryFn: (Directory uiProjectDir) async {
            return [mockPackage];
          },
          registrationGenerateFn:
              ({
                required Directory uiProjectDir,
                required List<WebPackageManifest> packages,
                String? outputDir,
              }) async {
                return RegistrationResult(
                  outputPath: '',
                  packageCount: 1,
                  factoryCount: 1,
                  hasGenerated: true,
                );
              },
          webPackageCollectFn:
              ({
                required Directory buildOutputDir,
                required List<WebPackageManifest> manifests,
              }) async {
                final asset = CollectedAsset(
                  packageName: 'test_package',
                  relativePath: 'web/ext/main.js',
                  sourcePath: '/fake/path/web/ext/main.js',
                  destinationPath: p.join(
                    buildOutputDir.path,
                    'ext/packages/test_package/main.js',
                  ),
                  type: AssetType.js,
                );
                return CollectionResult(
                  packages: 1,
                  assets: [asset],
                  skippedPackages: [],
                );
              },
          htmlInjectFn:
              ({
                required File indexHtml,
                required CollectionResult collectionResult,
              }) async {
                throw HtmlInjectorException('Injection failed');
              },
          writeOut: (_) {},
          writeErr: (_) {},
        );

        final exitCode = await pipeline.build(
          projectDir: projectDir,
          manifestPath: p.join(projectDir.path, 'fluttron.json'),
          manifest: const FluttronManifest(
            name: 'demo',
            version: '0.1.0',
            entry: EntryConfig(
              uiProjectPath: 'ui',
              hostAssetPath: 'host/assets/www',
              index: 'index.html',
            ),
          ),
        );

        expect(exitCode, 2);
        expect(clearCalled, isFalse);
      });
    });
  });
}

void _writeIndex(Directory webDir, List<String> scripts) {
  final buffer = StringBuffer();
  buffer.writeln('<!DOCTYPE html>');
  buffer.writeln('<html><body>');
  for (final script in scripts) {
    buffer.writeln('<script src="$script"></script>');
  }
  buffer.writeln('</body></html>');
  File(p.join(webDir.path, 'index.html')).writeAsStringSync(buffer.toString());
}

void _writeIndexWithPlaceholders(Directory webDir, List<String> scripts) {
  final buffer = StringBuffer();
  buffer.writeln('<!DOCTYPE html>');
  buffer.writeln('<html><head>');
  buffer.writeln('<!-- FLUTTRON_PACKAGES_CSS -->');
  buffer.writeln('</head><body>');
  for (final script in scripts) {
    buffer.writeln('<script src="$script"></script>');
  }
  buffer.writeln('<!-- FLUTTRON_PACKAGES_JS -->');
  buffer.writeln('</body></html>');
  File(p.join(webDir.path, 'index.html')).writeAsStringSync(buffer.toString());
}

void _writeFile(Directory rootDir, String relativePath, String contents) {
  final file = File(p.join(rootDir.path, relativePath));
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(contents);
}

class _FakeFrontendBuilder implements FrontendBuildStep {
  _FakeFrontendBuilder(this._onBuild);

  final Future<FrontendBuildResult> Function(Directory uiDir) _onBuild;

  @override
  Future<FrontendBuildResult> build(Directory uiDir) => _onBuild(uiDir);
}
