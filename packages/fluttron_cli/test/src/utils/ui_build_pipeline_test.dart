import 'dart:io';

import 'package:fluttron_shared/fluttron_shared.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'package:fluttron_cli/src/utils/frontend_builder.dart';
import 'package:fluttron_cli/src/utils/ui_build_pipeline.dart';

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
      final hostAssetsDir = Directory(
        p.join(projectDir.path, 'host', 'assets', 'www'),
      )..createSync(recursive: true);
      final buildOutputDir = Directory(p.join(uiDir.path, 'build', 'web'))
        ..createSync(recursive: true);
      File(p.join(buildOutputDir.path, 'index.html')).writeAsStringSync('ok');

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
        },
        copyDirectoryFn:
            ({
              required Directory sourceDir,
              required Directory destinationDir,
            }) async {
              events.add('copy');
              expect(sourceDir.path, buildOutputDir.path);
              expect(destinationDir.path, hostAssetsDir.path);
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
      expect(events, <String>['frontend', 'flutter', 'clear', 'copy']);
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
  });
}

class _FakeFrontendBuilder implements FrontendBuildStep {
  _FakeFrontendBuilder(this._onBuild);

  final Future<FrontendBuildResult> Function(Directory uiDir) _onBuild;

  @override
  Future<FrontendBuildResult> build(Directory uiDir) => _onBuild(uiDir);
}
