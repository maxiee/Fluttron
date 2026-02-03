import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

class ManifestException implements Exception {
  ManifestException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ManifestData {
  ManifestData({
    required this.name,
    required this.version,
    required this.uiProjectPath,
    required this.hostAssetPath,
    required this.index,
    required this.manifestPath,
  });

  final String name;
  final String version;
  final String uiProjectPath;
  final String hostAssetPath;
  final String index;
  final String manifestPath;
}

class ManifestLoader {
  static const String fileName = 'fluttron.json';

  static ManifestData load(Directory projectDir) {
    final manifestPath = p.join(projectDir.path, fileName);
    final manifestFile = File(manifestPath);
    if (!manifestFile.existsSync()) {
      throw ManifestException(
        'Missing fluttron.json at ${p.normalize(manifestPath)}',
      );
    }

    final contents = manifestFile.readAsStringSync();
    final json = _decodeJson(contents, manifestPath);

    final name = _readString(json, 'name', manifestPath);
    final version = _readString(json, 'version', manifestPath);
    final entry = _readMap(json, 'entry', manifestPath);
    final uiProjectPath = _readString(entry, 'uiProjectPath', manifestPath);
    final hostAssetPath = _readString(entry, 'hostAssetPath', manifestPath);
    final index = _readString(entry, 'index', manifestPath);

    return ManifestData(
      name: name,
      version: version,
      uiProjectPath: uiProjectPath,
      hostAssetPath: hostAssetPath,
      index: index,
      manifestPath: manifestPath,
    );
  }

  static Map<String, dynamic> _decodeJson(
    String contents,
    String manifestPath,
  ) {
    try {
      final decoded = jsonDecode(contents);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      throw ManifestException(
        'fluttron.json must be a JSON object: ${p.normalize(manifestPath)}',
      );
    } on FormatException catch (error) {
      throw ManifestException(
        'Invalid JSON in fluttron.json: ${p.normalize(manifestPath)} (${error.message})',
      );
    }
  }

  static Map<String, dynamic> _readMap(
    Map<String, dynamic> source,
    String key,
    String manifestPath,
  ) {
    final value = source[key];
    if (value is Map<String, dynamic>) {
      return value;
    }
    throw ManifestException(
      'Missing or invalid "$key" in ${p.normalize(manifestPath)}',
    );
  }

  static String _readString(
    Map<String, dynamic> source,
    String key,
    String manifestPath,
  ) {
    final value = source[key];
    if (value is String && value.trim().isNotEmpty) {
      return value;
    }
    throw ManifestException(
      'Missing or invalid "$key" in ${p.normalize(manifestPath)}',
    );
  }
}
