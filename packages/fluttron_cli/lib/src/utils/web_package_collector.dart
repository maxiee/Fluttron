import 'dart:io';

import 'package:path/path.dart' as p;

import 'web_package_manifest.dart';

/// Exception thrown when web package asset collection fails.
class WebPackageCollectorException implements Exception {
  WebPackageCollectorException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Represents a collected asset file with its source and destination paths.
class CollectedAsset {
  const CollectedAsset({
    required this.packageName,
    required this.relativePath,
    required this.sourcePath,
    required this.destinationPath,
    required this.type,
  });

  /// Package name (e.g., "milkdown_editor").
  final String packageName;

  /// Relative path within the package (e.g., "web/ext/main.js").
  final String relativePath;

  /// Absolute source file path.
  final String sourcePath;

  /// Absolute destination file path.
  final String destinationPath;

  /// Asset type (js or css).
  final AssetType type;

  @override
  String toString() => 'CollectedAsset($packageName, $relativePath, $type)';
}

/// Asset type enumeration.
enum AssetType { js, css }

/// Result of a collection operation.
class CollectionResult {
  const CollectionResult({
    required this.packages,
    required this.assets,
    required this.skippedPackages,
  });

  /// Number of packages processed.
  final int packages;

  /// List of all collected assets.
  final List<CollectedAsset> assets;

  /// List of package names that were skipped (missing rootPath).
  final List<String> skippedPackages;

  /// Returns true if any assets were collected.
  bool get hasAssets => assets.isNotEmpty;

  /// Returns all JS asset paths relative to the build output directory.
  List<String> get jsAssetPaths => assets
      .where((a) => a.type == AssetType.js)
      .map(
        (a) => 'ext/packages/${a.packageName}/${p.basename(a.destinationPath)}',
      )
      .toList();

  /// Returns all CSS asset paths relative to the build output directory.
  List<String> get cssAssetPaths => assets
      .where((a) => a.type == AssetType.css)
      .map(
        (a) => 'ext/packages/${a.packageName}/${p.basename(a.destinationPath)}',
      )
      .toList();
}

/// Collects web package assets to the Flutter Web build output directory.
///
/// This class copies JS and CSS files from web packages to
/// `ui/build/web/ext/packages/<package_name>/`, making them available
/// for HTML injection and runtime loading.
///
/// Example usage:
/// ```dart
/// final collector = WebPackageCollector();
/// final result = await collector.collect(
///   buildOutputDir: Directory('path/to/ui/build/web'),
///   manifests: discoveredManifests,
/// );
/// print('Collected ${result.assets.length} assets from ${result.packages} packages');
/// ```
class WebPackageCollector {
  /// Collects assets from web packages to the build output directory.
  ///
  /// [buildOutputDir] - The Flutter Web build output directory (e.g., `ui/build/web`).
  /// [manifests] - List of web package manifests discovered from dependencies.
  ///
  /// Returns a [CollectionResult] with details about collected assets.
  ///
  /// Throws [WebPackageCollectorException] if:
  /// - A manifest is missing rootPath (discovery should have set this)
  /// - A declared asset file does not exist at its source location
  /// - File copy operation fails
  Future<CollectionResult> collect({
    required Directory buildOutputDir,
    required List<WebPackageManifest> manifests,
  }) async {
    final collectedAssets = <CollectedAsset>[];
    final skippedPackages = <String>[];

    for (final manifest in manifests) {
      final packageName = manifest.packageName;
      final rootPath = manifest.rootPath;

      if (packageName == null || rootPath == null) {
        // Skip packages without discovery metadata
        if (packageName != null) {
          skippedPackages.add(packageName);
        }
        continue;
      }

      // Create destination directory for this package
      final packageDestDir = Directory(
        p.join(buildOutputDir.path, 'ext', 'packages', packageName),
      );
      await packageDestDir.create(recursive: true);

      // Collect JS assets
      for (final jsPath in manifest.assets.js) {
        final asset = await _collectAsset(
          packageName: packageName,
          rootPath: rootPath,
          relativePath: jsPath,
          destDir: packageDestDir,
          type: AssetType.js,
        );
        collectedAssets.add(asset);
      }

      // Collect CSS assets (optional)
      final cssPaths = manifest.assets.css;
      if (cssPaths != null) {
        for (final cssPath in cssPaths) {
          final asset = await _collectAsset(
            packageName: packageName,
            rootPath: rootPath,
            relativePath: cssPath,
            destDir: packageDestDir,
            type: AssetType.css,
          );
          collectedAssets.add(asset);
        }
      }
    }

    return CollectionResult(
      packages: manifests.length - skippedPackages.length,
      assets: collectedAssets,
      skippedPackages: skippedPackages,
    );
  }

  /// Synchronous version of [collect] for use in contexts where async is not available.
  CollectionResult collectSync({
    required Directory buildOutputDir,
    required List<WebPackageManifest> manifests,
  }) {
    final collectedAssets = <CollectedAsset>[];
    final skippedPackages = <String>[];

    for (final manifest in manifests) {
      final packageName = manifest.packageName;
      final rootPath = manifest.rootPath;

      if (packageName == null || rootPath == null) {
        if (packageName != null) {
          skippedPackages.add(packageName);
        }
        continue;
      }

      final packageDestDir = Directory(
        p.join(buildOutputDir.path, 'ext', 'packages', packageName),
      );
      packageDestDir.createSync(recursive: true);

      for (final jsPath in manifest.assets.js) {
        final asset = _collectAssetSync(
          packageName: packageName,
          rootPath: rootPath,
          relativePath: jsPath,
          destDir: packageDestDir,
          type: AssetType.js,
        );
        collectedAssets.add(asset);
      }

      final cssPaths = manifest.assets.css;
      if (cssPaths != null) {
        for (final cssPath in cssPaths) {
          final asset = _collectAssetSync(
            packageName: packageName,
            rootPath: rootPath,
            relativePath: cssPath,
            destDir: packageDestDir,
            type: AssetType.css,
          );
          collectedAssets.add(asset);
        }
      }
    }

    return CollectionResult(
      packages: manifests.length - skippedPackages.length,
      assets: collectedAssets,
      skippedPackages: skippedPackages,
    );
  }

  Future<CollectedAsset> _collectAsset({
    required String packageName,
    required String rootPath,
    required String relativePath,
    required Directory destDir,
    required AssetType type,
  }) async {
    final sourceFile = File(p.join(rootPath, relativePath));

    // Validate source file exists
    if (!await sourceFile.exists()) {
      throw WebPackageCollectorException(
        'Asset file not found for package "$packageName": '
        '${p.normalize(sourceFile.path)}\n'
        'Ensure the web package has been built (run pnpm run js:build in the package directory).',
      );
    }

    // Use only the filename for the destination (flatten the directory structure)
    final fileName = p.basename(relativePath);
    final destFile = File(p.join(destDir.path, fileName));

    // Copy the file
    await sourceFile.copy(destFile.path);

    return CollectedAsset(
      packageName: packageName,
      relativePath: relativePath,
      sourcePath: sourceFile.path,
      destinationPath: destFile.path,
      type: type,
    );
  }

  CollectedAsset _collectAssetSync({
    required String packageName,
    required String rootPath,
    required String relativePath,
    required Directory destDir,
    required AssetType type,
  }) {
    final sourceFile = File(p.join(rootPath, relativePath));

    if (!sourceFile.existsSync()) {
      throw WebPackageCollectorException(
        'Asset file not found for package "$packageName": '
        '${p.normalize(sourceFile.path)}\n'
        'Ensure the web package has been built (run pnpm run js:build in the package directory).',
      );
    }

    final fileName = p.basename(relativePath);
    final destFile = File(p.join(destDir.path, fileName));

    sourceFile.copySync(destFile.path);

    return CollectedAsset(
      packageName: packageName,
      relativePath: relativePath,
      sourcePath: sourceFile.path,
      destinationPath: destFile.path,
      type: type,
    );
  }

  /// Validates that all declared assets exist in their source locations.
  ///
  /// This is a pre-collection validation that checks asset availability
  /// without copying any files.
  ///
  /// Returns a list of missing asset paths (empty if all assets exist).
  List<String> validateAssets({required List<WebPackageManifest> manifests}) {
    final missingPaths = <String>[];

    for (final manifest in manifests) {
      final packageName = manifest.packageName;
      final rootPath = manifest.rootPath;

      if (packageName == null || rootPath == null) {
        continue;
      }

      // Check JS assets
      for (final jsPath in manifest.assets.js) {
        final sourceFile = File(p.join(rootPath, jsPath));
        if (!sourceFile.existsSync()) {
          missingPaths.add('$packageName/$jsPath');
        }
      }

      // Check CSS assets
      final cssPaths = manifest.assets.css;
      if (cssPaths != null) {
        for (final cssPath in cssPaths) {
          final sourceFile = File(p.join(rootPath, cssPath));
          if (!sourceFile.existsSync()) {
            missingPaths.add('$packageName/$cssPath');
          }
        }
      }
    }

    return missingPaths;
  }
}
