import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'package:fluttron_cli/src/utils/frontend_builder.dart';

void main() {
  group('FrontendBuilder', () {
    late Directory uiDir;

    setUp(() {
      uiDir = Directory.systemTemp.createTempSync('frontend_builder_test_');
    });

    tearDown(() {
      if (uiDir.existsSync()) {
        uiDir.deleteSync(recursive: true);
      }
    });

    test('skips when package.json does not exist', () async {
      final runner = _StubRunner();
      final builder = FrontendBuilder(commandRunner: runner.run);

      final result = await builder.build(uiDir);

      expect(result.status, FrontendBuildStatus.skipped);
      expect(result.reason, 'package.json not found.');
      expect(runner.calls, isEmpty);
    });

    test('skips when scripts["js:build"] is missing', () async {
      _writePackageJson(uiDir, '''
{
  "name": "test-ui",
  "scripts": {
    "test": "echo test"
  }
}
''');
      final runner = _StubRunner();
      final builder = FrontendBuilder(commandRunner: runner.run);

      final result = await builder.build(uiDir);

      expect(result.status, FrontendBuildStatus.skipped);
      expect(
        result.reason,
        'scripts["js:build"] not configured in package.json.',
      );
      expect(runner.calls, isEmpty);
    });

    test('throws readable error when node is unavailable', () async {
      _writePackageJson(uiDir, '''
{
  "name": "test-ui",
  "scripts": {
    "js:build": "node scripts/build-frontend.mjs"
  }
}
''');
      final runner = _StubRunner(
        responses: <String, ProcessCommandResult>{
          'node --version': const ProcessCommandResult(
            exitCode: 127,
            stdout: '',
            stderr: 'node: command not found',
          ),
        },
      );
      final builder = FrontendBuilder(commandRunner: runner.run);

      await expectLater(
        builder.build(uiDir),
        throwsA(
          isA<FrontendBuildException>()
              .having((error) => error.exitCode, 'exitCode', 2)
              .having((error) => error.message, 'message', contains('Node.js')),
        ),
      );

      expect(runner.calls.length, 1);
      expect(runner.calls.first.commandKey, 'node --version');
      expect(runner.calls.first.streamOutput, isFalse);
    });

    test('throws readable error when pnpm is unavailable', () async {
      _writePackageJson(uiDir, '''
{
  "name": "test-ui",
  "scripts": {
    "js:build": "node scripts/build-frontend.mjs"
  }
}
''');
      final runner = _StubRunner(
        responses: <String, ProcessCommandResult>{
          'node --version': const ProcessCommandResult(
            exitCode: 0,
            stdout: 'v24.8.0',
            stderr: '',
          ),
          'pnpm --version': const ProcessCommandResult(
            exitCode: 127,
            stdout: '',
            stderr: 'pnpm: command not found',
          ),
        },
      );
      final builder = FrontendBuilder(commandRunner: runner.run);

      await expectLater(
        builder.build(uiDir),
        throwsA(
          isA<FrontendBuildException>()
              .having((error) => error.exitCode, 'exitCode', 2)
              .having((error) => error.message, 'message', contains('pnpm')),
        ),
      );

      expect(runner.calls.map((call) => call.commandKey).toList(), <String>[
        'node --version',
        'pnpm --version',
      ]);
    });

    test('throws with command exit code when frontend build fails', () async {
      _writePackageJson(uiDir, '''
{
  "name": "test-ui",
  "scripts": {
    "js:build": "node scripts/build-frontend.mjs"
  }
}
''');
      final runner = _StubRunner(
        responses: <String, ProcessCommandResult>{
          'node --version': const ProcessCommandResult(
            exitCode: 0,
            stdout: 'v24.8.0',
            stderr: '',
          ),
          'pnpm --version': const ProcessCommandResult(
            exitCode: 0,
            stdout: '10.0.0',
            stderr: '',
          ),
          'pnpm run js:build': const ProcessCommandResult(
            exitCode: 5,
            stdout: '',
            stderr: 'build failed',
          ),
        },
      );
      final builder = FrontendBuilder(commandRunner: runner.run);

      await expectLater(
        builder.build(uiDir),
        throwsA(
          isA<FrontendBuildException>()
              .having((error) => error.exitCode, 'exitCode', 5)
              .having(
                (error) => error.message,
                'message',
                contains('Frontend build failed'),
              ),
        ),
      );

      expect(runner.calls.length, 3);
      expect(runner.calls[2].commandKey, 'pnpm run js:build');
      expect(runner.calls[2].streamOutput, isTrue);
    });

    test('runs node/pnpm checks then js:build when configured', () async {
      _writePackageJson(uiDir, '''
{
  "name": "test-ui",
  "scripts": {
    "js:build": "node scripts/build-frontend.mjs"
  }
}
''');
      final runner = _StubRunner(
        responses: <String, ProcessCommandResult>{
          'node --version': const ProcessCommandResult(
            exitCode: 0,
            stdout: 'v24.8.0',
            stderr: '',
          ),
          'pnpm --version': const ProcessCommandResult(
            exitCode: 0,
            stdout: '10.0.0',
            stderr: '',
          ),
          'pnpm run js:build': const ProcessCommandResult(
            exitCode: 0,
            stdout: 'ok',
            stderr: '',
          ),
        },
      );
      final builder = FrontendBuilder(commandRunner: runner.run);

      final result = await builder.build(uiDir);

      expect(result.status, FrontendBuildStatus.built);
      expect(
        runner.calls.map((call) => '${call.commandKey}|${call.streamOutput}'),
        <String>[
          'node --version|false',
          'pnpm --version|false',
          'pnpm run js:build|true',
        ],
      );
    });
  });
}

void _writePackageJson(Directory uiDir, String content) {
  final file = File(p.join(uiDir.path, 'package.json'));
  file.writeAsStringSync(content);
}

class _StubRunner {
  _StubRunner({Map<String, ProcessCommandResult>? responses})
    : _responses = responses ?? <String, ProcessCommandResult>{};

  final Map<String, ProcessCommandResult> _responses;
  final List<_CommandCall> calls = <_CommandCall>[];

  Future<ProcessCommandResult> run(
    String executable,
    List<String> arguments, {
    required String workingDirectory,
    required bool streamOutput,
  }) async {
    final commandKey = '$executable ${arguments.join(' ')}';
    calls.add(
      _CommandCall(
        commandKey: commandKey,
        workingDirectory: workingDirectory,
        streamOutput: streamOutput,
      ),
    );
    return _responses[commandKey] ??
        const ProcessCommandResult(exitCode: 0, stdout: '', stderr: '');
  }
}

class _CommandCall {
  const _CommandCall({
    required this.commandKey,
    required this.workingDirectory,
    required this.streamOutput,
  });

  final String commandKey;
  final String workingDirectory;
  final bool streamOutput;
}
