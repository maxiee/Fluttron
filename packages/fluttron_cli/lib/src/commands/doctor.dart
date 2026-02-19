import 'dart:io';

import 'package:args/command_runner.dart';

import '../utils/frontend_builder.dart';

/// Result of a single environment check.
class _CheckResult {
  const _CheckResult({
    required this.name,
    required this.passed,
    required this.detail,
    this.required = true,
  });

  final String name;
  final bool passed;
  final String detail;

  /// If false the check is informational only and does not count as a failure.
  final bool required;
}

/// `fluttron doctor`
///
/// Checks the development environment for Fluttron prerequisites:
/// - Flutter SDK installed and version
/// - Dart SDK version
/// - Node.js installed and version
/// - pnpm installed and version
/// - macOS desktop support enabled (flutter config)
/// - Current project structure (if running inside a Fluttron project)
class DoctorCommand extends Command<int> {
  DoctorCommand({ProcessCommandRunner? processRunner})
      : _processRunner = processRunner ?? _defaultRunner;

  @override
  String get name => 'doctor';

  @override
  String get description =>
      'Check the development environment for Fluttron prerequisites.';

  final ProcessCommandRunner _processRunner;

  static Future<ProcessCommandResult> _defaultRunner(
    String executable,
    List<String> arguments, {
    required String workingDirectory,
    required bool streamOutput,
  }) =>
      defaultProcessCommandRunner(
        executable,
        arguments,
        workingDirectory: workingDirectory,
        streamOutput: streamOutput,
      );

  @override
  Future<int> run() async {
    stdout.writeln('Fluttron Doctor — Checking development environment');
    stdout.writeln('');

    final checks = <_CheckResult>[
      await _checkFlutter(),
      await _checkDart(),
      await _checkNode(),
      await _checkPnpm(),
      await _checkMacosDesktop(),
      _checkFluttronProject(),
    ];

    for (final check in checks) {
      final icon = check.passed ? '✓' : '✗';
      stdout.writeln('  $icon  ${check.name}: ${check.detail}');
    }

    final failed = checks.where((c) => c.required && !c.passed).toList();

    stdout.writeln('');
    if (failed.isEmpty) {
      stdout.writeln('No issues found.');
      return 0;
    } else {
      stdout.writeln('${failed.length} issue(s) detected. See above for details.');
      return 1;
    }
  }

  Future<_CheckResult> _checkFlutter() async {
    final result = await _processRunner(
      'flutter',
      ['--version', '--machine'],
      workingDirectory: Directory.current.path,
      streamOutput: false,
    );
    if (result.exitCode != 0) {
      return const _CheckResult(
        name: 'Flutter SDK',
        passed: false,
        detail: 'Not found. Install from https://flutter.dev',
      );
    }
    // The first line of `flutter --version` (non-machine) contains the version.
    // With --machine, the JSON field "frameworkVersion" has it.
    // Fall back to stdout scanning for a version-like token.
    final version = _extractVersion(result.stdout) ??
        _extractVersion(result.stderr) ??
        'found';
    return _CheckResult(
      name: 'Flutter SDK',
      passed: true,
      detail: version,
    );
  }

  Future<_CheckResult> _checkDart() async {
    final result = await _processRunner(
      'dart',
      ['--version'],
      workingDirectory: Directory.current.path,
      streamOutput: false,
    );
    if (result.exitCode != 0) {
      return const _CheckResult(
        name: 'Dart SDK',
        passed: false,
        detail: 'Not found. Usually bundled with Flutter SDK.',
      );
    }
    // `dart --version` writes to stderr on older SDKs, stdout on newer ones.
    final raw = result.stdout.isNotEmpty ? result.stdout : result.stderr;
    final version = _extractVersion(raw) ?? 'found';
    return _CheckResult(
      name: 'Dart SDK',
      passed: true,
      detail: version,
    );
  }

  Future<_CheckResult> _checkNode() async {
    final result = await _processRunner(
      'node',
      ['--version'],
      workingDirectory: Directory.current.path,
      streamOutput: false,
    );
    if (result.exitCode != 0) {
      return const _CheckResult(
        name: 'Node.js',
        passed: false,
        detail: 'Not found. Install from https://nodejs.org',
      );
    }
    final version = result.stdout.trim().isNotEmpty
        ? result.stdout.trim()
        : (result.stderr.trim().isNotEmpty ? result.stderr.trim() : 'found');
    return _CheckResult(
      name: 'Node.js',
      passed: true,
      detail: version,
    );
  }

  Future<_CheckResult> _checkPnpm() async {
    final result = await _processRunner(
      'pnpm',
      ['--version'],
      workingDirectory: Directory.current.path,
      streamOutput: false,
    );
    if (result.exitCode != 0) {
      return const _CheckResult(
        name: 'pnpm',
        passed: false,
        detail: 'Not found. Install via: npm install -g pnpm',
      );
    }
    final version = result.stdout.trim().isNotEmpty
        ? result.stdout.trim()
        : (result.stderr.trim().isNotEmpty ? result.stderr.trim() : 'found');
    return _CheckResult(
      name: 'pnpm',
      passed: true,
      detail: version,
    );
  }

  Future<_CheckResult> _checkMacosDesktop() async {
    final result = await _processRunner(
      'flutter',
      ['config', '--list'],
      workingDirectory: Directory.current.path,
      streamOutput: false,
    );
    if (result.exitCode != 0) {
      return const _CheckResult(
        name: 'macOS desktop support',
        passed: false,
        detail: 'Could not query flutter config.',
      );
    }
    final combined = '${result.stdout}\n${result.stderr}';
    // Modern Flutter (3.x+) enables macOS desktop by default on macOS;
    // the flag shows as "(Not set)" rather than "true" in `flutter config --list`.
    // Accept either explicit "true" or the default "(Not set)" case.
    final explicitlyEnabled =
        RegExp(r'enable-macos-desktop:\s*true').hasMatch(combined);
    final notSet =
        RegExp(r'enable-macos-desktop:\s*\(Not set\)').hasMatch(combined);
    final explicitlyDisabled =
        RegExp(r'enable-macos-desktop:\s*false').hasMatch(combined);
    final enabled = explicitlyEnabled || (notSet && !explicitlyDisabled);
    if (enabled) {
      return const _CheckResult(
        name: 'macOS desktop support',
        passed: true,
        detail: 'Enabled',
      );
    }
    return const _CheckResult(
      name: 'macOS desktop support',
      passed: false,
      detail:
          'Not enabled. Run: flutter config --enable-macos-desktop',
    );
  }

  _CheckResult _checkFluttronProject() {
    final manifestFile = File(
      '${Directory.current.path}${Platform.pathSeparator}fluttron.json',
    );
    if (manifestFile.existsSync()) {
      return const _CheckResult(
        name: 'Fluttron project',
        passed: true,
        detail: 'fluttron.json found',
        required: false,
      );
    }
    return const _CheckResult(
      name: 'Fluttron project',
      passed: false,
      detail: 'No fluttron.json in current directory (run from project root)',
      required: false,
    );
  }

  /// Extracts the first semver-like token (e.g. `3.19.5`) from [text].
  String? _extractVersion(String text) {
    final match = RegExp(r'\d+\.\d+\.\d+[\w.+-]*').firstMatch(text);
    return match?.group(0);
  }
}
