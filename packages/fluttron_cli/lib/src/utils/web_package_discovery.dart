import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'web_package_manifest.dart';

/// Exception thrown when package discovery fails.
class WebPackageDiscoveryException implements Exception {
  WebPackageDiscoveryException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Represents a package entry from package_config.json.
class PackageConfigEntry {
  const PackageConfigEntry({
    required this.name,
    required this.rootUri,
    required this.packageUri,
    this.languageVersion,
  });

  /// Package name (e.g., "milkdown_editor").
  final String name;

  /// Root URI as string (can be relative or file:// URI).
  final String rootUri;

  /// Package URI (usually "lib/").
  final String packageUri;

  /// Optional language version.
  final String? languageVersion;

  /// Resolves the root path from rootUri.
  /// Handles both relative paths and file:// URIs.
  String resolveRootPath(String baseDir) {
    if (rootUri.startsWith('file://')) {
      // file:// URI - convert to path
      return Uri.parse(rootUri).toFilePath();
    } else {
      // Relative path - resolve against base directory
      return p.normalize(p.join(baseDir, rootUri));
    }
  }

  factory PackageConfigEntry.fromJson(Map<String, dynamic> json) {
    return PackageConfigEntry(
      name: json['name'] as String,
      rootUri: json['rootUri'] as String,
      packageUri: json['packageUri'] as String,
      languageVersion: json['languageVersion'] as String?,
    );
  }
}

/// Represents the parsed package_config.json structure.
class PackageConfig {
  const PackageConfig({
    required this.configVersion,
    required this.packages,
    this.generator,
    this.generatorVersion,
  });

  final int configVersion;
  final List<PackageConfigEntry> packages;
  final String? generator;
  final String? generatorVersion;

  factory PackageConfig.fromJson(Map<String, dynamic> json) {
    return PackageConfig(
      configVersion: json['configVersion'] as int,
      packages: (json['packages'] as List)
          .map((e) => PackageConfigEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      generator: json['generator'] as String?,
      generatorVersion: json['generatorVersion'] as String?,
    );
  }
}

/// Discovers web packages from package_config.json dependencies.
///
/// This class parses `.dart_tool/package_config.json` to find all dependencies,
/// then checks each for a `fluttron_web_package.json` manifest. Packages with
/// manifests are returned as [WebPackageManifest] objects with packageName and
/// rootPath populated.
///
/// Example usage:
/// ```dart
/// final discovery = WebPackageDiscovery();
/// final packages = await discovery.discover(Directory('path/to/ui'));
/// for (final pkg in packages) {
///   print('Found web package: ${pkg.packageName} at ${pkg.rootPath}');
/// }
/// ```
class WebPackageDiscovery {
  /// Relative path to package_config.json from UI project root.
  static const String packageConfigPath = '.dart_tool/package_config.json';

  /// Discovers web packages in the dependency tree of a UI project.
  ///
  /// [uiProjectDir] - The UI project directory containing .dart_tool/.
  ///
  /// Returns a list of [WebPackageManifest] objects for all dependencies
  /// that have a valid `fluttron_web_package.json` manifest.
  ///
  /// Throws [WebPackageDiscoveryException] if package_config.json is missing
  /// or contains invalid JSON.
  Future<List<WebPackageManifest>> discover(Directory uiProjectDir) async {
    final configPath = p.join(uiProjectDir.path, packageConfigPath);
    final configFile = File(configPath);

    if (!await configFile.exists()) {
      throw WebPackageDiscoveryException(
        'package_config.json not found at ${p.normalize(configPath)}.\n'
        'Please run "flutter pub get" in the UI project first.',
      );
    }

    final PackageConfig config;
    try {
      config = await _parsePackageConfig(configFile);
    } on WebPackageDiscoveryException {
      rethrow;
    } catch (error) {
      throw WebPackageDiscoveryException(
        'Failed to parse package_config.json: $error',
      );
    }

    final manifests = <WebPackageManifest>[];
    final baseDir = uiProjectDir.path;

    for (final pkg in config.packages) {
      final rootPath = pkg.resolveRootPath(baseDir);
      final manifestFile = File(
        p.join(rootPath, WebPackageManifestLoader.fileName),
      );

      if (await manifestFile.exists()) {
        final manifest = WebPackageManifestLoader.tryLoad(Directory(rootPath));
        if (manifest != null) {
          manifests.add(
            manifest.copyWith(packageName: pkg.name, rootPath: rootPath),
          );
        }
      }
    }

    return manifests;
  }

  /// Synchronous version of [discover] for use in contexts where async is not available.
  List<WebPackageManifest> discoverSync(Directory uiProjectDir) {
    final configPath = p.join(uiProjectDir.path, packageConfigPath);
    final configFile = File(configPath);

    if (!configFile.existsSync()) {
      throw WebPackageDiscoveryException(
        'package_config.json not found at ${p.normalize(configPath)}.\n'
        'Please run "flutter pub get" in the UI project first.',
      );
    }

    final PackageConfig config;
    try {
      config = _parsePackageConfigSync(configFile);
    } on WebPackageDiscoveryException {
      rethrow;
    } catch (error) {
      throw WebPackageDiscoveryException(
        'Failed to parse package_config.json: $error',
      );
    }

    final manifests = <WebPackageManifest>[];
    final baseDir = uiProjectDir.path;

    for (final pkg in config.packages) {
      final rootPath = pkg.resolveRootPath(baseDir);
      final manifestFile = File(
        p.join(rootPath, WebPackageManifestLoader.fileName),
      );

      if (manifestFile.existsSync()) {
        final manifest = WebPackageManifestLoader.tryLoad(Directory(rootPath));
        if (manifest != null) {
          manifests.add(
            manifest.copyWith(packageName: pkg.name, rootPath: rootPath),
          );
        }
      }
    }

    return manifests;
  }

  Future<PackageConfig> _parsePackageConfig(File configFile) async {
    final contents = await configFile.readAsString();
    return _decodePackageConfig(contents, configFile.path);
  }

  PackageConfig _parsePackageConfigSync(File configFile) {
    final contents = configFile.readAsStringSync();
    return _decodePackageConfig(contents, configFile.path);
  }

  PackageConfig _decodePackageConfig(String contents, String configPath) {
    final json = _decodeJson(contents, configPath);
    return PackageConfig.fromJson(json);
  }

  Map<String, dynamic> _decodeJson(String contents, String configPath) {
    try {
      final decoded = jsonDecode(contents);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      throw WebPackageDiscoveryException(
        'package_config.json must be a JSON object: ${p.normalize(configPath)}',
      );
    } on FormatException catch (error) {
      throw WebPackageDiscoveryException(
        'Invalid JSON in package_config.json: ${p.normalize(configPath)} '
        '(${error.message})',
      );
    }
  }
}
