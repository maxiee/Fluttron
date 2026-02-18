import 'dart:io';

import 'package:path/path.dart' as p;

/// Exception thrown when pubspec.yaml parsing fails.
class PubspecLoaderException implements Exception {
  PubspecLoaderException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Represents parsed pubspec.yaml content.
class PubspecInfo {
  const PubspecInfo({
    required this.name,
    required this.version,
    this.description,
  });

  /// Package name.
  final String name;

  /// Package version.
  final String version;

  /// Optional package description.
  final String? description;

  @override
  String toString() => 'PubspecInfo(name: $name, version: $version)';
}

/// Loads and parses pubspec.yaml files.
class PubspecLoader {
  static const String fileName = 'pubspec.yaml';

  /// Loads pubspec.yaml from a directory.
  ///
  /// Throws [PubspecLoaderException] if the file is missing or invalid.
  static PubspecInfo load(Directory packageDir) {
    final pubspecPath = p.join(packageDir.path, fileName);
    final pubspecFile = File(pubspecPath);

    if (!pubspecFile.existsSync()) {
      throw PubspecLoaderException(
        'Missing $fileName at ${p.normalize(pubspecPath)}',
      );
    }

    final contents = pubspecFile.readAsStringSync();
    return _parseYaml(contents, pubspecPath);
  }

  /// Loads pubspec.yaml from a directory, returns null if not found.
  static PubspecInfo? tryLoad(Directory packageDir) {
    try {
      return load(packageDir);
    } on PubspecLoaderException {
      return null;
    }
  }

  /// Simple YAML parser for pubspec.yaml (handles basic key-value pairs).
  /// Does not support full YAML spec - only what's needed for pubspec.
  static PubspecInfo _parseYaml(String contents, String pubspecPath) {
    String? name;
    String? version;
    String? description;

    // Simple line-by-line parsing for top-level keys
    for (final line in contents.split('\n')) {
      final trimmed = line.trim();

      // Skip comments and empty lines
      if (trimmed.startsWith('#') || trimmed.isEmpty) continue;

      // Only parse top-level keys (no leading whitespace)
      if (line.startsWith(' ') || line.startsWith('\t')) continue;

      final colonIndex = trimmed.indexOf(':');
      if (colonIndex <= 0) continue;

      final key = trimmed.substring(0, colonIndex).trim();
      var value = trimmed.substring(colonIndex + 1).trim();

      // Remove quotes if present
      if ((value.startsWith("'") && value.endsWith("'")) ||
          (value.startsWith('"') && value.endsWith('"'))) {
        value = value.substring(1, value.length - 1);
      }

      switch (key) {
        case 'name':
          name = value;
        case 'version':
          version = value;
        case 'description':
          description = value;
      }
    }

    if (name == null) {
      throw PubspecLoaderException(
        'Missing "name" field in ${p.normalize(pubspecPath)}',
      );
    }

    // Version defaults to "0.0.0" if not specified
    return PubspecInfo(
      name: name,
      version: version ?? '0.0.0',
      description: description,
    );
  }

  /// Parses pubspec.yaml content as JSON-like map.
  ///
  /// This is a simplified parser for basic YAML structures.
  /// For complex YAML, consider using a proper YAML library.
  static Map<String, dynamic> parseAsMap(String contents) {
    final result = <String, dynamic>{};
    String? currentKey;
    final List<String> currentList = [];
    bool inList = false;

    for (final line in contents.split('\n')) {
      final trimmed = line.trim();

      // Skip comments and empty lines
      if (trimmed.startsWith('#') || trimmed.isEmpty) {
        continue;
      }

      // Check for list items
      if (trimmed.startsWith('- ')) {
        if (inList && currentKey != null) {
          currentList.add(trimmed.substring(2).trim());
        }
        continue;
      }

      final colonIndex = trimmed.indexOf(':');
      if (colonIndex <= 0) {
        continue;
      }

      // Save previous list if any
      if (inList && currentKey != null && currentList.isNotEmpty) {
        result[currentKey] = List.from(currentList);
        currentList.clear();
      }

      final key = trimmed.substring(0, colonIndex).trim();
      var value = trimmed.substring(colonIndex + 1).trim();

      // Check if this is a nested block (value is empty)
      if (value.isEmpty) {
        currentKey = key;
        inList = true;
        currentList.clear();
        continue;
      }

      // Remove quotes if present
      if ((value.startsWith("'") && value.endsWith("'")) ||
          (value.startsWith('"') && value.endsWith('"'))) {
        value = value.substring(1, value.length - 1);
      }

      result[key] = value;
      inList = false;
    }

    // Save last list if any
    if (inList && currentKey != null && currentList.isNotEmpty) {
      result[currentKey] = List.from(currentList);
    }

    return result;
  }
}
