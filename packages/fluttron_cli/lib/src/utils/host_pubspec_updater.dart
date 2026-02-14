import 'dart:io';

import 'package:path/path.dart' as p;

/// Exception thrown when host pubspec update fails.
class HostPubspecUpdaterException implements Exception {
  HostPubspecUpdaterException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Updates the host pubspec.yaml to include web package asset declarations.
///
/// Flutter requires explicit asset declarations in pubspec.yaml for assets
/// to be included in the build. This class ensures that web package assets
/// under `assets/www/ext/packages/<package_name>/` are properly declared.
class HostPubspecUpdater {
  /// Updates the host pubspec.yaml to include asset declarations for the given packages.
  ///
  /// [hostPubspecFile] - The host's pubspec.yaml file.
  /// [packageNames] - List of web package names to add asset declarations for.
  ///
  /// Returns true if any changes were made, false if no changes were needed.
  Future<bool> update({
    required File hostPubspecFile,
    required List<String> packageNames,
  }) async {
    if (!hostPubspecFile.existsSync()) {
      throw HostPubspecUpdaterException(
        'Host pubspec.yaml not found: ${hostPubspecFile.path}',
      );
    }

    if (packageNames.isEmpty) {
      return false;
    }

    final content = await hostPubspecFile.readAsString();
    final lines = content.split('\n');

    // Find the assets section
    int? assetsStartIndex;
    int? assetsEndIndex;
    bool inFlutterSection = false;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];

      if (line.trim() == 'flutter:') {
        inFlutterSection = true;
        continue;
      }

      if (inFlutterSection && line.trim().startsWith('assets:')) {
        assetsStartIndex = i;
        continue;
      }

      // Detect end of assets section (next top-level key or end of flutter section)
      if (assetsStartIndex != null &&
          line.isNotEmpty &&
          !line.startsWith(' ') &&
          !line.startsWith('\t')) {
        assetsEndIndex = i;
        break;
      }
    }

    if (assetsStartIndex == null) {
      throw HostPubspecUpdaterException(
        'No assets section found in host pubspec.yaml. '
        'Please add an assets section under flutter:.',
      );
    }

    // If we didn't find an end, it means assets is the last section
    assetsEndIndex ??= lines.length;

    // Extract existing asset declarations
    final existingAssets = <String>{};
    for (int i = assetsStartIndex + 1; i < assetsEndIndex!; i++) {
      final line = lines[i];
      final trimmed = line.trim();
      if (trimmed.startsWith('- ')) {
        final assetPath = trimmed.substring(2).trim();
        existingAssets.add(assetPath);
      }
    }

    // Determine which new assets need to be added
    final newAssets = <String>[];
    for (final packageName in packageNames) {
      final assetPath = 'assets/www/ext/packages/$packageName/';
      if (!existingAssets.contains(assetPath)) {
        newAssets.add(assetPath);
      }
    }

    if (newAssets.isEmpty) {
      return false;
    }

    // Find the indentation of existing assets
    String assetIndent = '    '; // Default 4 spaces
    for (int i = assetsStartIndex + 1; i < assetsEndIndex!; i++) {
      final line = lines[i];
      if (line.trim().startsWith('- ')) {
        final indent = line.substring(0, line.indexOf('-'));
        if (indent.isNotEmpty) {
          assetIndent = indent;
          break;
        }
      }
    }

    // Insert new asset declarations after existing assets
    final insertionIndex = assetsEndIndex!;
    for (int i = 0; i < newAssets.length; i++) {
      final newLine = '$assetIndent- ${newAssets[i]}';
      lines.insert(insertionIndex + i, newLine);
    }

    // Write back
    await hostPubspecFile.writeAsString(lines.join('\n'));

    return true;
  }

  /// Synchronous version of [update].
  bool updateSync({
    required File hostPubspecFile,
    required List<String> packageNames,
  }) {
    if (!hostPubspecFile.existsSync()) {
      throw HostPubspecUpdaterException(
        'Host pubspec.yaml not found: ${hostPubspecFile.path}',
      );
    }

    if (packageNames.isEmpty) {
      return false;
    }

    final content = hostPubspecFile.readAsStringSync();
    final lines = content.split('\n');

    // Find the assets section
    int? assetsStartIndex;
    int? assetsEndIndex;
    bool inFlutterSection = false;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];

      if (line.trim() == 'flutter:') {
        inFlutterSection = true;
        continue;
      }

      if (inFlutterSection && line.trim().startsWith('assets:')) {
        assetsStartIndex = i;
        continue;
      }

      // Detect end of assets section
      if (assetsStartIndex != null &&
          line.isNotEmpty &&
          !line.startsWith(' ') &&
          !line.startsWith('\t')) {
        assetsEndIndex = i;
        break;
      }
    }

    if (assetsStartIndex == null) {
      throw HostPubspecUpdaterException(
        'No assets section found in host pubspec.yaml. '
        'Please add an assets section under flutter:.',
      );
    }

    assetsEndIndex ??= lines.length;

    // Extract existing asset declarations
    final existingAssets = <String>{};
    for (int i = assetsStartIndex + 1; i < assetsEndIndex!; i++) {
      final line = lines[i];
      final trimmed = line.trim();
      if (trimmed.startsWith('- ')) {
        final assetPath = trimmed.substring(2).trim();
        existingAssets.add(assetPath);
      }
    }

    // Determine which new assets need to be added
    final newAssets = <String>[];
    for (final packageName in packageNames) {
      final assetPath = 'assets/www/ext/packages/$packageName/';
      if (!existingAssets.contains(assetPath)) {
        newAssets.add(assetPath);
      }
    }

    if (newAssets.isEmpty) {
      return false;
    }

    // Find the indentation of existing assets
    String assetIndent = '    ';
    for (int i = assetsStartIndex + 1; i < assetsEndIndex!; i++) {
      final line = lines[i];
      if (line.trim().startsWith('- ')) {
        final indent = line.substring(0, line.indexOf('-'));
        if (indent.isNotEmpty) {
          assetIndent = indent;
          break;
        }
      }
    }

    // Insert new asset declarations
    final insertionIndex = assetsEndIndex!;
    for (int i = 0; i < newAssets.length; i++) {
      final newLine = '$assetIndent- ${newAssets[i]}';
      lines.insert(insertionIndex + i, newLine);
    }

    // Write back
    hostPubspecFile.writeAsStringSync(lines.join('\n'));

    return true;
  }
}
