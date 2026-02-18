import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:fluttron_shared/fluttron_shared.dart';
import 'package:path/path.dart' as p;

import '../utils/host_service_copier.dart';
import '../utils/template_copy.dart';
import '../utils/web_package_copier.dart';

/// Supported project types for creation.
enum ProjectType { app, webPackage, hostService }

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
        'type',
        help:
            'Project type: "app" for full Fluttron app, "web_package" for reusable web package, "host_service" for custom host service.',
        valueHelp: 'type',
        allowed: ['app', 'web_package', 'host_service'],
        defaultsTo: 'app',
      )
      ..addOption(
        'template',
        help: 'Path to templates root (optional, only for app type).',
        valueHelp: 'path',
      );
  }

  @override
  Future<int> run() async {
    final targetPath = _readSingleRest('target directory');
    final targetDir = Directory(targetPath);
    final normalizedTarget = p.normalize(targetDir.path);
    final projectType = _resolveProjectType();
    final name = _resolveProjectName(normalizedTarget);

    if (targetDir.existsSync()) {
      final entries = targetDir.listSync();
      if (entries.isNotEmpty) {
        stderr.writeln('Target directory is not empty: $normalizedTarget');
        return 2;
      }
    }

    try {
      switch (projectType) {
        case ProjectType.app:
          await _createAppProject(
            targetDir: targetDir,
            normalizedTarget: normalizedTarget,
            name: name,
          );
        case ProjectType.webPackage:
          await _createWebPackageProject(
            targetDir: targetDir,
            normalizedTarget: normalizedTarget,
            name: name,
          );
        case ProjectType.hostService:
          await _createHostServiceProject(
            targetDir: targetDir,
            normalizedTarget: normalizedTarget,
            name: name,
          );
      }
    } on FileSystemException catch (error) {
      stderr.writeln(error.message);
      return 2;
    } on FormatException catch (error) {
      stderr.writeln('Invalid fluttron.json: ${error.message}');
      return 2;
    }

    _printSuccessMessage(
      normalizedTarget: normalizedTarget,
      projectType: projectType,
      name: name,
    );
    return 0;
  }

  Future<void> _createAppProject({
    required Directory targetDir,
    required String normalizedTarget,
    required String name,
  }) async {
    final templateDir = _resolveTemplateDir(subdir: 'host');
    final uiTemplateDir = _resolveTemplateDir(subdir: 'ui');
    final rootTemplateDir = templateDir.parent;

    final copier = TemplateCopier();

    // Copy host template
    final hostTargetDir = Directory(p.join(targetDir.path, 'host'));
    await copier.copyContents(
      sourceDir: templateDir,
      destinationDir: hostTargetDir,
    );

    // Copy ui template
    final uiTargetDir = Directory(p.join(targetDir.path, 'ui'));
    await copier.copyContents(
      sourceDir: uiTemplateDir,
      destinationDir: uiTargetDir,
    );

    // Copy fluttron.json from root template directory
    final rootManifest = File(p.join(rootTemplateDir.path, 'fluttron.json'));
    if (rootManifest.existsSync()) {
      await rootManifest.copy(p.join(targetDir.path, 'fluttron.json'));
    }

    // Update manifest
    _updateManifest(
      manifestFile: File(p.join(targetDir.path, 'fluttron.json')),
      projectName: name,
    );

    // Rewrite pubspec paths
    _rewritePubspecPaths(projectDir: targetDir, templateDir: rootTemplateDir);
  }

  Future<void> _createWebPackageProject({
    required Directory targetDir,
    required String normalizedTarget,
    required String name,
  }) async {
    final templateDir = _resolveTemplateDir(subdir: 'web_package');

    final copier = WebPackageCopier();
    await copier.copyAndTransform(
      packageName: name,
      sourceDir: templateDir,
      destinationDir: targetDir,
    );

    // Rewrite pubspec path for fluttron_ui dependency
    _rewriteWebPackagePubspecPath(
      pubspecFile: File(p.join(targetDir.path, 'pubspec.yaml')),
      templateDir: templateDir.parent,
    );
  }

  Future<void> _createHostServiceProject({
    required Directory targetDir,
    required String normalizedTarget,
    required String name,
  }) async {
    final templateDir = _resolveTemplateDir(subdir: 'host_service');

    final copier = HostServiceCopier();
    await copier.copyAndTransform(
      serviceName: name,
      sourceDir: templateDir,
      destinationDir: targetDir,
    );

    // Rewrite pubspec paths for both host and client packages
    _rewriteHostServicePubspecPaths(
      hostPubspec: File(p.join(targetDir.path, '${name}_host', 'pubspec.yaml')),
      clientPubspec: File(
        p.join(targetDir.path, '${name}_client', 'pubspec.yaml'),
      ),
      templateDir: templateDir.parent,
    );
  }

  void _printSuccessMessage({
    required String normalizedTarget,
    required ProjectType projectType,
    required String name,
  }) {
    stdout.writeln('Project created: $normalizedTarget');
    final typeStr = switch (projectType) {
      ProjectType.app => 'app',
      ProjectType.webPackage => 'web_package',
      ProjectType.hostService => 'host_service',
    };
    stdout.writeln('Type: $typeStr');
    stdout.writeln('Name: $name');

    switch (projectType) {
      case ProjectType.app:
        stdout.writeln(
          'Next step: run `fluttron build` in the project directory.',
        );
      case ProjectType.webPackage:
        stdout.writeln('Next steps:');
        stdout.writeln('  1. cd $normalizedTarget');
        stdout.writeln('  2. dart pub get');
        stdout.writeln('  3. cd frontend && pnpm install && pnpm run js:build');
        stdout.writeln(
          '  4. Add this package to your app\'s ui/pubspec.yaml dependencies',
        );
      case ProjectType.hostService:
        stdout.writeln('');
        stdout.writeln('Created packages:');
        stdout.writeln('  ${name}_host/   — Host-side service implementation');
        stdout.writeln('  ${name}_client/ — UI-side client stub');
        stdout.writeln('');
        stdout.writeln('Next steps:');
        stdout.writeln('  1. cd ${name}_host && dart pub get && flutter test');
        stdout.writeln('  2. cd ../${name}_client && dart pub get');
        stdout.writeln('  3. Add to your host app:');
        stdout.writeln(
          '     import \'package:${name}_host/${name}_host.dart\';',
        );
        stdout.writeln(
          '     registry.register(${_toPascalCase(name)}Service());',
        );
        stdout.writeln('  4. Add to your UI app:');
        stdout.writeln(
          '     import \'package:${name}_client/${name}_client.dart\';',
        );
        stdout.writeln(
          '     final svc = ${_toPascalCase(name)}ServiceClient(client);',
        );
    }
  }

  /// Converts a string to PascalCase.
  String _toPascalCase(String input) {
    final parts = input.split('_');
    return parts
        .map((part) {
          if (part.isEmpty) return '';
          return part[0].toUpperCase() + part.substring(1).toLowerCase();
        })
        .join('');
  }

  ProjectType _resolveProjectType() {
    final typeArg = argResults?['type'] as String?;
    if (typeArg == 'web_package') {
      return ProjectType.webPackage;
    }
    if (typeArg == 'host_service') {
      return ProjectType.hostService;
    }
    return ProjectType.app;
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

  Directory _resolveTemplateDir({String? subdir}) {
    final templateArg = argResults?['template'] as String?;
    var templatePath = templateArg?.trim();

    // If no template arg, use default templates directory
    if (templatePath == null || templatePath.isEmpty) {
      templatePath = p.join(Directory.current.path, 'templates');
    }

    // If subdir is specified, append it
    if (subdir != null) {
      templatePath = p.join(templatePath, subdir);
    }

    final dir = Directory(p.normalize(templatePath));
    if (!dir.existsSync()) {
      throw UsageException(
        'Template directory not found: ${p.normalize(templatePath)}',
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
    final packagesDir = _resolvePackagesDir(templateDir);
    if (packagesDir == null) {
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

  void _rewriteWebPackagePubspecPath({
    required File pubspecFile,
    required Directory templateDir,
  }) {
    if (!pubspecFile.existsSync()) {
      return;
    }

    final packagesDir = _resolvePackagesDir(templateDir);
    if (packagesDir == null) {
      return;
    }

    final normalizedPackages = p.normalize(packagesDir.path);
    _rewritePubspecFile(pubspecFile, normalizedPackages);
  }

  void _rewriteHostServicePubspecPaths({
    required File hostPubspec,
    required File clientPubspec,
    required Directory templateDir,
  }) {
    final packagesDir = _resolvePackagesDir(templateDir);
    if (packagesDir == null) {
      return;
    }

    final normalizedPackages = p.normalize(packagesDir.path);
    _rewritePubspecFile(hostPubspec, normalizedPackages);
    _rewritePubspecFile(clientPubspec, normalizedPackages);
  }

  Directory? _resolvePackagesDir(Directory templateDir) {
    Directory current = templateDir;
    for (var i = 0; i < 8; i++) {
      final candidate = Directory(p.join(current.path, 'packages'));
      if (candidate.existsSync()) {
        return candidate;
      }
      final parent = current.parent;
      if (parent.path == current.path) {
        break;
      }
      current = parent;
    }
    return null;
  }

  void _rewritePubspecFile(File file, String packagesPath) {
    if (!file.existsSync()) {
      return;
    }

    final original = file.readAsStringSync();
    var updated = original
        // Handle ../../packages/ (used by app and web_package templates)
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
        )
        // Handle ../../../packages/ (used by host_service templates)
        .replaceAll(
          'path: ../../../packages/fluttron_host',
          'path: ${p.join(packagesPath, 'fluttron_host')}',
        )
        .replaceAll(
          'path: ../../../packages/fluttron_ui',
          'path: ${p.join(packagesPath, 'fluttron_ui')}',
        )
        .replaceAll(
          'path: ../../../packages/fluttron_shared',
          'path: ${p.join(packagesPath, 'fluttron_shared')}',
        );

    if (updated != original) {
      file.writeAsStringSync(updated);
    }
  }
}
