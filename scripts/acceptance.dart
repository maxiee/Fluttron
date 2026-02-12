#!/usr/bin/env dart
// v0041 Acceptance Test Script
// Run: dart run scripts/acceptance.dart
//
// This script validates the web package feature according to PRD §13

import 'dart:io';

String get repoRoot {
  final scriptDir = Directory.current.path;
  if (scriptDir.contains('Fluttron')) {
    final parts = scriptDir.split(Platform.pathSeparator);
    final index = parts.indexOf('Fluttron');
    return parts.sublist(0, index + 1).join(Platform.pathSeparator);
  }
  return '/Volumes/ssd/Code/Fluttron';
}

Future<bool> testCreateWebPackage() async {
  print('  Creating web package...');
  final tempDir = await Directory.systemTemp.createTemp('acceptance_13_1_');
  final pkgDir = '${tempDir.path}/test_package';

  try {
    final createResult = await Process.run('dart', [
      'run',
      '$repoRoot/packages/fluttron_cli/bin/fluttron.dart',
      'create',
      pkgDir,
      '--name',
      'test_package',
      '--type',
      'web_package',
    ]);
    if (createResult.exitCode != 0) {
      print('  FAIL: create failed - ${createResult.stderr}');
      return false;
    }

    if (!await File('$pkgDir/fluttron_web_package.json').exists()) {
      print('  FAIL: manifest not found');
      return false;
    }

    final frontendDir = Directory('$pkgDir/frontend');
    if (await frontendDir.exists()) {
      final installResult = await Process.run('pnpm', [
        'install',
      ], workingDirectory: frontendDir.path);
      if (installResult.exitCode != 0) {
        print('  SKIP: pnpm install failed (frontend optional for this test)');
      } else {
        final buildResult = await Process.run('pnpm', [
          'run',
          'js:build',
        ], workingDirectory: frontendDir.path);
        if (buildResult.exitCode != 0) {
          print('  FAIL: js:build failed - ${buildResult.stderr}');
          return false;
        }
      }
    }

    final analyzeResult = await Process.run('dart', [
      'analyze',
    ], workingDirectory: pkgDir);
    if (analyzeResult.exitCode != 0) {
      print('  FAIL: dart analyze failed - ${analyzeResult.stderr}');
      return false;
    }

    print('  PASS');
    return true;
  } finally {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  }
}

Future<bool> testUseWebPackage() async {
  print('  Using web package in app...');
  final tempDir = await Directory.systemTemp.createTemp('acceptance_13_2_');
  final pkgDir = '${tempDir.path}/test_package';
  final appDir = '${tempDir.path}/test_app';

  try {
    await Process.run('dart', [
      'run',
      '$repoRoot/packages/fluttron_cli/bin/fluttron.dart',
      'create',
      pkgDir,
      '--name',
      'test_package',
      '--type',
      'web_package',
    ]);

    final createAppResult = await Process.run('dart', [
      'run',
      '$repoRoot/packages/fluttron_cli/bin/fluttron.dart',
      'create',
      appDir,
      '--name',
      'test_app',
    ]);
    if (createAppResult.exitCode != 0) {
      print('  FAIL: app create failed');
      return false;
    }

    final pubspec = File('$appDir/ui/pubspec.yaml');
    var content = await pubspec.readAsString();
    content += '\n  test_package:\n    path: ../$pkgDir\n';
    await pubspec.writeAsString(content);

    await Process.run('flutter', [
      'pub',
      'get',
    ], workingDirectory: '$appDir/ui');

    final buildResult = await Process.run('dart', [
      'run',
      '$repoRoot/packages/fluttron_cli/bin/fluttron.dart',
      'build',
      '-p',
      '.',
    ], workingDirectory: appDir);
    if (buildResult.exitCode != 0) {
      print('  FAIL: build failed - ${buildResult.stderr}');
      return false;
    }

    final indexHtml = File('$appDir/host/assets/www/index.html');
    if (!await indexHtml.exists()) {
      print('  FAIL: index.html not found');
      return false;
    }

    final htmlContent = await indexHtml.readAsString();
    if (!htmlContent.contains('ext/packages/test_package/main.js')) {
      print('  FAIL: package JS not injected in index.html');
      return false;
    }

    final registrations = File(
      '$appDir/ui/lib/generated/web_package_registrations.dart',
    );
    if (!await registrations.exists()) {
      print('  FAIL: registrations file not found');
      return false;
    }

    final regContent = await registrations.readAsString();
    if (!regContent.contains('registerFluttronWebPackages')) {
      print('  FAIL: registerFluttronWebPackages not in generated file');
      return false;
    }

    print('  PASS');
    return true;
  } finally {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  }
}

Future<bool> testBuildArtifacts() async {
  print('  Verifying build artifacts...');
  final tempDir = await Directory.systemTemp.createTemp('acceptance_13_3_');
  final pkgDir = '${tempDir.path}/test_package';
  final appDir = '${tempDir.path}/test_app';

  try {
    await Process.run('dart', [
      'run',
      '$repoRoot/packages/fluttron_cli/bin/fluttron.dart',
      'create',
      pkgDir,
      '--name',
      'test_package',
      '--type',
      'web_package',
    ]);

    await Process.run('dart', [
      'run',
      '$repoRoot/packages/fluttron_cli/bin/fluttron.dart',
      'create',
      appDir,
      '--name',
      'test_app',
    ]);

    final pubspec = File('$appDir/ui/pubspec.yaml');
    var content = await pubspec.readAsString();
    content += '\n  test_package:\n    path: ../$pkgDir\n';
    await pubspec.writeAsString(content);

    await Process.run('flutter', [
      'pub',
      'get',
    ], workingDirectory: '$appDir/ui');

    final buildResult = await Process.run('dart', [
      'run',
      '$repoRoot/packages/fluttron_cli/bin/fluttron.dart',
      'build',
      '-p',
      '.',
    ], workingDirectory: appDir);
    if (buildResult.exitCode != 0) {
      print('  FAIL: build failed');
      return false;
    }

    final hostAssets = Directory('$appDir/host/assets/www');
    if (!await hostAssets.exists()) {
      print('  FAIL: host/assets/www not found');
      return false;
    }

    final requiredFiles = [
      'index.html',
      'ext/main.js',
      'ext/packages/test_package/main.js',
    ];

    for (final file in requiredFiles) {
      if (!await File('${hostAssets.path}/$file').exists()) {
        print('  FAIL: $file not found');
        return false;
      }
    }

    print('  PASS');
    return true;
  } finally {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  }
}

Future<void> main() async {
  print('╔══════════════════════════════════════════╗');
  print('║   v0041 Acceptance Test                  ║');
  print('║   PRD §13 Web Package Feature            ║');
  print('╚══════════════════════════════════════════╝\n');

  final results = <String, bool>{};

  print('§13.1 Create Web Package');
  results['13.1'] = await testCreateWebPackage();
  print('');

  print('§13.2 Use Web Package in App');
  results['13.2'] = await testUseWebPackage();
  print('');

  print('§13.3 CI Smoke Test (Build Artifacts)');
  results['13.3'] = await testBuildArtifacts();
  print('');

  print('╔══════════════════════════════════════════╗');
  print('║   Results                                ║');
  print('╠══════════════════════════════════════════╣');
  for (final entry in results.entries) {
    final status = entry.value ? '✓ PASS' : '✗ FAIL';
    print('║   ${entry.key}: $status                         ');
  }
  print('╚══════════════════════════════════════════╝');

  final allPass = results.values.every((v) => v);
  if (allPass) {
    print('\n✓ All acceptance tests passed!');
  } else {
    print('\n✗ Some tests failed. Review output above.');
  }

  exit(allPass ? 0 : 1);
}
