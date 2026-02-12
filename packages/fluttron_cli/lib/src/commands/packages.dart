import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;

import '../utils/manifest_loader.dart';
import '../utils/pubspec_loader.dart';
import '../utils/web_package_discovery.dart';
import '../utils/web_package_manifest.dart';

/// Parent command for web package operations.
///
/// This command serves as a namespace for package-related subcommands.
/// Currently supports:
/// - `list`: Lists all web packages in a project's dependencies
class PackagesCommand extends Command<int> {
  @override
  String get name => 'packages';

  @override
  String get description => 'Manage web packages in Fluttron projects.';

  PackagesCommand() {
    addSubcommand(PackagesListCommand());
  }
}

/// Lists all web packages discovered in a project's UI dependencies.
///
/// Usage:
/// ```bash
/// fluttron packages list -p ./my_app
/// ```
///
/// Output format:
/// ```
/// Web Packages in my_app:
/// ┌─────────────────┬─────────┬──────────────────────────────┐
/// │ Package         │ Version │ View Factories               │
/// ├─────────────────┼─────────┼──────────────────────────────┤
/// │ milkdown_editor │ 0.2.0   │ milkdown.editor              │
/// │ chartjs_wrapper │ 1.0.0   │ chartjs.bar, chartjs.line    │
/// └─────────────────┴─────────┴──────────────────────────────┘
/// ```
class PackagesListCommand extends Command<int> {
  @override
  String get name => 'list';

  @override
  String get description =>
      'List all web packages in the project dependencies.';

  PackagesListCommand() {
    argParser.addOption(
      'project',
      abbr: 'p',
      help: 'Path to the Fluttron project root.',
      defaultsTo: '.',
      valueHelp: 'path',
    );
  }

  @override
  Future<int> run() async {
    final projectPath = argResults?['project'] as String? ?? '.';
    final projectDir = Directory(p.normalize(projectPath));

    // Load manifest to get UI project path
    final LoadedManifest loaded;
    try {
      loaded = ManifestLoader.load(projectDir);
    } on ManifestException catch (error) {
      stderr.writeln(error);
      return 2;
    }

    final uiDir = Directory(
      p.join(projectDir.path, loaded.manifest.entry.uiProjectPath),
    );
    if (!uiDir.existsSync()) {
      stderr.writeln('UI project not found: ${p.normalize(uiDir.path)}');
      return 2;
    }

    // Discover web packages
    final discovery = WebPackageDiscovery();
    final List<WebPackageManifest> packages;
    try {
      packages = await discovery.discover(uiDir);
    } on WebPackageDiscoveryException catch (error) {
      stderr.writeln('Discovery failed: ${error.message}');
      return 2;
    }

    // Output results
    if (packages.isEmpty) {
      stdout.writeln('No web packages found in ${loaded.manifest.name}.');
      stdout.writeln('');
      stdout.writeln(
        'Tip: Add web packages to your ui/pubspec.yaml dependencies.',
      );
      return 0;
    }

    // Build table data
    final tableData = <_PackageRow>[];
    for (final pkg in packages) {
      final packageName = pkg.packageName ?? 'unknown';

      // Load version from pubspec.yaml
      String version = 'unknown';
      if (pkg.rootPath != null) {
        final pubspec = PubspecLoader.tryLoad(Directory(pkg.rootPath!));
        if (pubspec != null) {
          version = pubspec.version;
        }
      }

      // Format view factories as comma-separated list
      final factories = pkg.viewFactories.map((f) => f.type).join(', ');

      tableData.add(
        _PackageRow(
          packageName: packageName,
          version: version,
          viewFactories: factories,
        ),
      );
    }

    // Print formatted output
    _printTable(loaded.manifest.name, tableData);

    return 0;
  }

  void _printTable(String projectName, List<_PackageRow> rows) {
    stdout.writeln('Web Packages in $projectName:');
    stdout.writeln('');

    if (rows.isEmpty) return;

    // Calculate column widths
    final nameWidth = [
      'Package',
      ...rows.map((r) => r.packageName),
    ].map((s) => _displayWidth(s)).reduce((a, b) => a > b ? a : b);

    final versionWidth = [
      'Version',
      ...rows.map((r) => r.version),
    ].map((s) => _displayWidth(s)).reduce((a, b) => a > b ? a : b);

    final factoriesWidth = [
      'View Factories',
      ...rows.map((r) => r.viewFactories),
    ].map((s) => _displayWidth(s)).reduce((a, b) => a > b ? a : b);

    // Print header
    final separator =
        '┌${'─' * (nameWidth + 2)}'
        '┬${'─' * (versionWidth + 2)}'
        '┬${'─' * (factoriesWidth + 2)}┐';
    stdout.writeln(separator);

    stdout.writeln(
      '│ ${'Package'.padRight(nameWidth)} '
      '│ ${'Version'.padRight(versionWidth)} '
      '│ ${'View Factories'.padRight(factoriesWidth)} │',
    );

    final headerSeparator =
        '├${'─' * (nameWidth + 2)}'
        '┬${'─' * (versionWidth + 2)}'
        '┬${'─' * (factoriesWidth + 2)}┤';
    stdout.writeln(headerSeparator);

    // Print rows
    for (final row in rows) {
      stdout.writeln(
        '│ ${row.packageName.padRight(nameWidth)} '
        '│ ${row.version.padRight(versionWidth)} '
        '│ ${row.viewFactories.padRight(factoriesWidth)} │',
      );
    }

    // Print footer
    final footer =
        '└${'─' * (nameWidth + 2)}'
        '┴${'─' * (versionWidth + 2)}'
        '┴${'─' * (factoriesWidth + 2)}┘';
    stdout.writeln(footer);

    // Print summary
    stdout.writeln('');
    stdout.writeln('Total: ${rows.length} web package(s)');
  }

  /// Calculate display width (handles CJK characters).
  int _displayWidth(String text) {
    var width = 0;
    for (final codeUnit in text.codeUnits) {
      // CJK characters are typically double-width
      if (codeUnit >= 0x3000 && codeUnit <= 0x9FFF) {
        width += 2;
      } else {
        width += 1;
      }
    }
    return width;
  }
}

/// Data class for table row.
class _PackageRow {
  const _PackageRow({
    required this.packageName,
    required this.version,
    required this.viewFactories,
  });

  final String packageName;
  final String version;
  final String viewFactories;
}
