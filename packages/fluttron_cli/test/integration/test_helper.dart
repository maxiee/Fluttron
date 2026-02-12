import 'dart:io';
import 'package:path/path.dart' as p;

class IntegrationTestHelper {
  static String get repoRoot {
    final scriptDir = Directory.current.path;
    if (scriptDir.endsWith('packages/fluttron_cli')) {
      return p.dirname(p.dirname(scriptDir));
    }
    final testDir = Platform.script.toFilePath();
    final parts = p.split(testDir);
    final fluttronIndex = parts.indexOf('Fluttron');
    if (fluttronIndex != -1) {
      return p.joinAll(parts.sublist(0, fluttronIndex + 1));
    }
    return '/Volumes/ssd/Code/Fluttron';
  }

  static Directory get _integrationWorkDir {
    final workDir = Directory(p.join(repoRoot, '.test_integration'));
    if (!workDir.existsSync()) {
      workDir.createSync(recursive: true);
    }
    return workDir;
  }

  static Future<Directory> createTempDir(String prefix) async {
    final dir = Directory(
      p.join(
        _integrationWorkDir.path,
        '${prefix}_${DateTime.now().millisecondsSinceEpoch}',
      ),
    );
    await dir.create(recursive: true);
    return dir;
  }

  static Future<int> runCli(List<String> args, {String? workingDir}) async {
    final cliPath = p.join(repoRoot, 'packages/fluttron_cli/bin/fluttron.dart');
    final result = await Process.run('dart', [
      'run',
      cliPath,
      ...args,
    ], workingDirectory: workingDir ?? repoRoot);
    if (result.exitCode != 0) {
      print('CLI STDERR: ${result.stderr}');
      print('CLI STDOUT: ${result.stdout}');
    }
    return result.exitCode;
  }

  static Future<void> addPathDependency(
    Directory appDir,
    Directory pkgDir, {
    String packageName = 'test_package',
  }) async {
    final pubspec = File(p.join(appDir.path, 'ui', 'pubspec.yaml'));
    if (!await pubspec.exists()) {
      throw Exception('pubspec.yaml not found at ${pubspec.path}');
    }
    final content = await pubspec.readAsString();
    final relativePath = p.relative(
      pkgDir.path,
      from: p.join(appDir.path, 'ui'),
    );

    // Insert the dependency before dev_dependencies: or flutter: section
    final lines = content.split('\n');
    final newLines = <String>[];
    var inserted = false;

    for (final line in lines) {
      if (!inserted &&
          (line.trim() == 'dev_dependencies:' || line.trim() == 'flutter:')) {
        // Insert dependency before this section
        newLines.add('  $packageName:');
        newLines.add('    path: $relativePath');
        inserted = true;
      }
      newLines.add(line);
    }

    if (!inserted) {
      // Fallback: append at end
      newLines.add('  $packageName:');
      newLines.add('    path: $relativePath');
    }

    await pubspec.writeAsString(newLines.join('\n'));
  }

  static Future<bool> fileContains(File file, String pattern) async {
    if (!await file.exists()) return false;
    final content = await file.readAsString();
    return content.contains(pattern);
  }

  static Future<void> recursiveDelete(Directory dir) async {
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  }

  static Future<void> createMinimalWebPackage(
    Directory pkgDir,
    String name,
  ) async {
    await pkgDir.create(recursive: true);

    final manifest =
        '''
{
  "version": "1",
  "viewFactories": [
    {
      "type": "$name.example",
      "jsFactoryName": "fluttronCreate${_toPascalCase(name)}ExampleView",
      "description": "Example view factory"
    }
  ],
  "assets": {
    "js": ["web/ext/main.js"],
    "css": ["web/ext/main.css"]
  }
}
''';
    await File(
      p.join(pkgDir.path, 'fluttron_web_package.json'),
    ).writeAsString(manifest);

    final pubspec =
        '''
name: $name
version: 0.1.0
description: A minimal test web package
fluttron_web_package: true

environment:
  sdk: ^3.10.4
''';
    await File(p.join(pkgDir.path, 'pubspec.yaml')).writeAsString(pubspec);

    await Directory(p.join(pkgDir.path, 'lib')).create(recursive: true);
    await File(p.join(pkgDir.path, 'lib', '$name.dart')).writeAsString('''
/// Minimal web package for testing.
library $name;
''');

    await Directory(p.join(pkgDir.path, 'web/ext')).create(recursive: true);
    await File(p.join(pkgDir.path, 'web/ext/main.js')).writeAsString('''
window.fluttronCreate${_toPascalCase(name)}ExampleView = function(viewId, args) {
  const container = document.createElement('div');
  container.id = viewId;
  container.textContent = 'Example widget from $name';
  return container;
};
''');
    await File(p.join(pkgDir.path, 'web/ext/main.css')).writeAsString('''
/* $name styles */
''');
  }

  static String _toPascalCase(String input) {
    return input
        .split('_')
        .map(
          (part) => part.isEmpty
              ? ''
              : '${part[0].toUpperCase()}${part.substring(1)}',
        )
        .join();
  }

  static Future<void> runPubGet(Directory uiDir) async {
    final result = await Process.run('flutter', [
      'pub',
      'get',
    ], workingDirectory: uiDir.path);
    if (result.exitCode != 0) {
      print('pub get failed: ${result.stderr}');
    }
  }
}
