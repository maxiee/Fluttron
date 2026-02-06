import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:fluttron_shared/fluttron_shared.dart';
import 'package:path/path.dart' as p;

import '../utils/template_copy.dart';

class CreateCommand extends Command<int> {
  @override
  String get name => 'create';

  @override
  String get description => 'Create a new Fluttron project from templates.';

  CreateCommand() {
    argParser
      ..addOption(
        'name',
        abbr: 'n',
        help: 'Project name (optional).',
        valueHelp: 'name',
      )
      ..addOption(
        'template',
        abbr: 't',
        help: 'Path to templates root (optional).',
        valueHelp: 'path',
      );
  }

  @override
  Future<int> run() async {
    final targetPath = _readSingleRest('target directory');
    final targetDir = Directory(targetPath);
    final normalizedTarget = p.normalize(targetDir.path);
    final templateDir = _resolveTemplateDir();

    if (targetDir.existsSync()) {
      final entries = targetDir.listSync();
      if (entries.isNotEmpty) {
        stderr.writeln('Target directory is not empty: $normalizedTarget');
        return 2;
      }
    }

    final name = _resolveProjectName(normalizedTarget);
    try {
      final copier = TemplateCopier();
      await copier.copyContents(
        sourceDir: templateDir,
        destinationDir: targetDir,
      );
      _updateManifest(
        manifestFile: File(p.join(targetDir.path, 'fluttron.json')),
        projectName: name,
      );
      _rewritePubspecPaths(projectDir: targetDir, templateDir: templateDir);
    } on FileSystemException catch (error) {
      stderr.writeln(error.message);
      return 2;
    } on FormatException catch (error) {
      stderr.writeln('Invalid fluttron.json: ${error.message}');
      return 2;
    }

    stdout.writeln('Project created: $normalizedTarget');
    stdout.writeln('Template: ${p.normalize(templateDir.path)}');
    stdout.writeln('Name: $name');
    stdout.writeln('Next step: run `fluttron build` in the project directory.');
    return 0;
  }

  String _readSingleRest(String label) {
    final rest = argResults?.rest ?? const [];
    if (rest.isEmpty) {
      throw UsageException('Missing $label.', usage);
    }
    if (rest.length > 1) {
      throw UsageException('Too many arguments.', usage);
    }
    return rest.first;
  }

  Directory _resolveTemplateDir() {
    final templateArg = argResults?['template'] as String?;
    final templatePath = templateArg?.trim();
    final resolvedPath = templatePath != null && templatePath.isNotEmpty
        ? templatePath
        : p.join(Directory.current.path, 'templates');
    final dir = Directory(p.normalize(resolvedPath));
    if (!dir.existsSync()) {
      throw UsageException(
        'Template directory not found: ${p.normalize(resolvedPath)}',
        usage,
      );
    }
    return dir;
  }

  String _resolveProjectName(String normalizedTarget) {
    final name = argResults?['name'] as String?;
    if (name != null && name.trim().isNotEmpty) {
      return name.trim();
    }
    return p.basename(normalizedTarget);
  }

  void _updateManifest({
    required File manifestFile,
    required String projectName,
  }) {
    if (!manifestFile.existsSync()) {
      return;
    }
    final contents = manifestFile.readAsStringSync();
    final decoded = jsonDecode(contents);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('fluttron.json must be a JSON object.');
    }

    FluttronManifest manifest;
    try {
      manifest = FluttronManifest.fromJson(decoded);
    } catch (error) {
      throw FormatException('Invalid fluttron.json schema: $error');
    }

    manifest = FluttronManifest(
      name: projectName,
      version: manifest.version,
      entry: manifest.entry,
      window: WindowConfig(
        title: projectName,
        width: manifest.window.width,
        height: manifest.window.height,
        resizable: manifest.window.resizable,
      ),
    );

    final encoder = const JsonEncoder.withIndent('  ');
    manifestFile.writeAsStringSync('${encoder.convert(manifest.toJson())}\n');
  }

  void _rewritePubspecPaths({
    required Directory projectDir,
    required Directory templateDir,
  }) {
    final packagesDir = Directory(p.join(templateDir.parent.path, 'packages'));
    if (!packagesDir.existsSync()) {
      return;
    }

    final normalizedPackages = p.normalize(packagesDir.path);
    _rewritePubspecFile(
      File(p.join(projectDir.path, 'host', 'pubspec.yaml')),
      normalizedPackages,
    );
    _rewritePubspecFile(
      File(p.join(projectDir.path, 'ui', 'pubspec.yaml')),
      normalizedPackages,
    );
  }

  void _rewritePubspecFile(File file, String packagesPath) {
    if (!file.existsSync()) {
      return;
    }

    final original = file.readAsStringSync();
    var updated = original
        .replaceAll(
          'path: ../../packages/fluttron_host',
          'path: ${p.join(packagesPath, 'fluttron_host')}',
        )
        .replaceAll(
          'path: ../../packages/fluttron_ui',
          'path: ${p.join(packagesPath, 'fluttron_ui')}',
        )
        .replaceAll(
          'path: ../../packages/fluttron_shared',
          'path: ${p.join(packagesPath, 'fluttron_shared')}',
        );

    if (updated != original) {
      file.writeAsStringSync(updated);
    }
  }
}
