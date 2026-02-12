import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

typedef LogWriter = void Function(String message);

class ProcessCommandResult {
  const ProcessCommandResult({
    required this.exitCode,
    required this.stdout,
    required this.stderr,
  });

  final int exitCode;
  final String stdout;
  final String stderr;

  bool get isSuccess => exitCode == 0;
}

typedef ProcessCommandRunner =
    Future<ProcessCommandResult> Function(
      String executable,
      List<String> arguments, {
      required String workingDirectory,
      required bool streamOutput,
    });

Future<ProcessCommandResult> defaultProcessCommandRunner(
  String executable,
  List<String> arguments, {
  required String workingDirectory,
  required bool streamOutput,
}) async {
  try {
    if (!streamOutput) {
      final result = await Process.run(
        executable,
        arguments,
        workingDirectory: workingDirectory,
        runInShell: true,
      );
      return ProcessCommandResult(
        exitCode: result.exitCode,
        stdout: result.stdout?.toString() ?? '',
        stderr: result.stderr?.toString() ?? '',
      );
    }

    final process = await Process.start(
      executable,
      arguments,
      workingDirectory: workingDirectory,
      runInShell: true,
    );
    final stdoutBuffer = StringBuffer();
    final stderrBuffer = StringBuffer();

    final stdoutDone = process.stdout.transform(utf8.decoder).forEach((chunk) {
      stdoutBuffer.write(chunk);
      stdout.write(chunk);
    });
    final stderrDone = process.stderr.transform(utf8.decoder).forEach((chunk) {
      stderrBuffer.write(chunk);
      stderr.write(chunk);
    });

    final exitCode = await process.exitCode;
    await Future.wait([stdoutDone, stderrDone]);
    return ProcessCommandResult(
      exitCode: exitCode,
      stdout: stdoutBuffer.toString(),
      stderr: stderrBuffer.toString(),
    );
  } on ProcessException catch (error) {
    return ProcessCommandResult(
      exitCode: 127,
      stdout: '',
      stderr: error.message,
    );
  }
}

enum FrontendBuildStatus { skipped, built }

class FrontendBuildResult {
  const FrontendBuildResult._({required this.status, this.reason});

  const FrontendBuildResult.skipped(String reason)
    : this._(status: FrontendBuildStatus.skipped, reason: reason);

  const FrontendBuildResult.built() : this._(status: FrontendBuildStatus.built);

  final FrontendBuildStatus status;
  final String? reason;
}

class FrontendBuildException implements Exception {
  const FrontendBuildException(this.message, {this.exitCode = 2});

  final String message;
  final int exitCode;

  @override
  String toString() => message;
}

abstract interface class FrontendBuildStep {
  Future<FrontendBuildResult> build(Directory uiDir);
}

class FrontendBuilder implements FrontendBuildStep {
  FrontendBuilder({ProcessCommandRunner? commandRunner, LogWriter? writeOut})
    : _commandRunner = commandRunner ?? defaultProcessCommandRunner,
      _writeOut = writeOut ?? _defaultStdoutWriter;

  final ProcessCommandRunner _commandRunner;
  final LogWriter _writeOut;

  static void _defaultStdoutWriter(String message) => stdout.writeln(message);

  @override
  Future<FrontendBuildResult> build(Directory uiDir) async {
    final packageJsonFile = File(p.join(uiDir.path, 'package.json'));
    if (!packageJsonFile.existsSync()) {
      return const FrontendBuildResult.skipped('package.json not found.');
    }

    final scripts = _readScripts(packageJsonFile);
    final hasBuildScript = scripts.containsKey('js:build');
    if (!hasBuildScript) {
      return const FrontendBuildResult.skipped(
        'scripts["js:build"] not configured in package.json.',
      );
    }

    final nodeCheck = await _commandRunner(
      'node',
      const ['--version'],
      workingDirectory: uiDir.path,
      streamOutput: false,
    );
    if (!nodeCheck.isSuccess) {
      throw FrontendBuildException(_buildNodeUnavailableMessage(nodeCheck));
    }

    final pnpmCheck = await _commandRunner(
      'pnpm',
      const ['--version'],
      workingDirectory: uiDir.path,
      streamOutput: false,
    );
    if (!pnpmCheck.isSuccess) {
      throw FrontendBuildException(_buildPnpmUnavailableMessage(pnpmCheck));
    }

    // Auto-install dependencies if node_modules is missing
    final nodeModulesDir = Directory(p.join(uiDir.path, 'node_modules'));
    if (!nodeModulesDir.existsSync() && _hasDependencies(packageJsonFile)) {
      _writeOut('[frontend] Running pnpm install...');
      final installResult = await _commandRunner(
        'pnpm',
        const ['install'],
        workingDirectory: uiDir.path,
        streamOutput: true,
      );
      if (!installResult.isSuccess) {
        throw FrontendBuildException(
          'pnpm install failed with exit code ${installResult.exitCode}.\n'
          'Check your network connection and package.json, then retry.',
          exitCode: installResult.exitCode == 0 ? 2 : installResult.exitCode,
        );
      }
    }

    if (scripts.containsKey('js:clean')) {
      _writeOut('Cleaning frontend assets with `pnpm run js:clean`...');
      final frontendClean = await _commandRunner(
        'pnpm',
        const ['run', 'js:clean'],
        workingDirectory: uiDir.path,
        streamOutput: true,
      );
      if (!frontendClean.isSuccess) {
        throw FrontendBuildException(
          'Frontend clean failed with exit code ${frontendClean.exitCode}.\n'
          'Fix `scripts["js:clean"]` in ${p.normalize(packageJsonFile.path)} and retry.',
          exitCode: frontendClean.exitCode == 0 ? 2 : frontendClean.exitCode,
        );
      }
      _writeOut('Frontend clean complete.');
    }

    _writeOut('Building frontend assets with `pnpm run js:build`...');
    final frontendBuild = await _commandRunner(
      'pnpm',
      const ['run', 'js:build'],
      workingDirectory: uiDir.path,
      streamOutput: true,
    );
    if (!frontendBuild.isSuccess) {
      throw FrontendBuildException(
        'Frontend build failed with exit code ${frontendBuild.exitCode}.\n'
        'Run `pnpm install` in ${p.normalize(uiDir.path)} if dependencies are missing, '
        'then fix the frontend error and retry.',
        exitCode: frontendBuild.exitCode == 0 ? 2 : frontendBuild.exitCode,
      );
    }

    _writeOut('Frontend build complete.');
    return const FrontendBuildResult.built();
  }

  Map<String, String> _readScripts(File packageJsonFile) {
    final decoded = _parsePackageJson(packageJsonFile);

    final scripts = decoded['scripts'];
    if (scripts is! Map) {
      return const <String, String>{};
    }

    final normalizedScripts = <String, String>{};
    for (final entry in scripts.entries) {
      final key = entry.key;
      final value = entry.value;
      if (key is! String || value is! String) {
        continue;
      }
      final trimmed = value.trim();
      if (trimmed.isEmpty) {
        continue;
      }
      normalizedScripts[key] = trimmed;
    }
    return normalizedScripts;
  }

  /// Checks if package.json has any dependencies (dependencies or devDependencies).
  bool _hasDependencies(File packageJsonFile) {
    final decoded = _parsePackageJson(packageJsonFile);

    final dependencies = decoded['dependencies'];
    final devDependencies = decoded['devDependencies'];

    final hasDeps = dependencies is Map && dependencies.isNotEmpty;
    final hasDevDeps = devDependencies is Map && devDependencies.isNotEmpty;

    return hasDeps || hasDevDeps;
  }

  Map<String, dynamic> _parsePackageJson(File packageJsonFile) {
    final packageJsonPath = p.normalize(packageJsonFile.path);
    final rawContents = packageJsonFile.readAsStringSync();

    dynamic decoded;
    try {
      decoded = jsonDecode(rawContents);
    } on FormatException catch (error) {
      throw FrontendBuildException(
        'Invalid package.json at $packageJsonPath (${error.message}).',
      );
    }

    if (decoded is! Map<String, dynamic>) {
      throw FrontendBuildException(
        'Invalid package.json at $packageJsonPath (JSON object expected).',
      );
    }

    return decoded;
  }

  String _buildNodeUnavailableMessage(ProcessCommandResult result) {
    final details = _buildCommandDetails(result);
    final lines = <String>[
      'Node.js is required for frontend build but `node --version` failed.',
      'Install Node.js and retry `fluttron build`.',
    ];
    if (details.isNotEmpty) {
      lines.add('Details: $details');
    }
    return lines.join('\n');
  }

  String _buildPnpmUnavailableMessage(ProcessCommandResult result) {
    final details = _buildCommandDetails(result);
    final lines = <String>[
      'pnpm is required for frontend build but `pnpm --version` failed.',
      'Try running `corepack enable` and `pnpm install` in the UI project.',
      'Then retry `fluttron build`.',
    ];
    if (details.isNotEmpty) {
      lines.add('Details: $details');
    }
    return lines.join('\n');
  }

  String _buildCommandDetails(ProcessCommandResult result) {
    final stderrText = result.stderr.trim();
    if (stderrText.isNotEmpty) {
      return stderrText;
    }
    final stdoutText = result.stdout.trim();
    if (stdoutText.isNotEmpty) {
      return stdoutText;
    }
    return '';
  }
}
