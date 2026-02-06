import 'dart:convert';
import 'dart:io';

import 'package:fluttron_shared/fluttron_shared.dart';
import 'package:path/path.dart' as p;

class ManifestException implements Exception {
  ManifestException(this.message);

  final String message;

  @override
  String toString() => message;
}

typedef LoadedManifest = ({FluttronManifest manifest, String manifestPath});

class ManifestLoader {
  static const String fileName = 'fluttron.json';

  static LoadedManifest load(Directory projectDir) {
    final manifestPath = p.join(projectDir.path, fileName);
    final manifestFile = File(manifestPath);
    if (!manifestFile.existsSync()) {
      throw ManifestException(
        'Missing fluttron.json at ${p.normalize(manifestPath)}',
      );
    }

    final contents = manifestFile.readAsStringSync();
    final json = _decodeJson(contents, manifestPath);
    final manifest = _decodeManifest(json, manifestPath);
    _validateManifest(manifest, manifestPath);

    return (manifest: manifest, manifestPath: manifestPath);
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

  static FluttronManifest _decodeManifest(
    Map<String, dynamic> json,
    String manifestPath,
  ) {
    try {
      return FluttronManifest.fromJson(json);
    } catch (error) {
      throw ManifestException(
        'Invalid manifest schema in ${p.normalize(manifestPath)}: $error',
      );
    }
  }

  static void _validateManifest(
    FluttronManifest manifest,
    String manifestPath,
  ) {
    _requireNonEmpty(manifest.name, 'name', manifestPath);
    _requireNonEmpty(manifest.version, 'version', manifestPath);
    _requireNonEmpty(
      manifest.entry.uiProjectPath,
      'entry.uiProjectPath',
      manifestPath,
    );
    _requireNonEmpty(
      manifest.entry.hostAssetPath,
      'entry.hostAssetPath',
      manifestPath,
    );
    _requireNonEmpty(manifest.entry.index, 'entry.index', manifestPath);
  }

  static void _requireNonEmpty(
    String value,
    String fieldPath,
    String manifestPath,
  ) {
    if (value.trim().isNotEmpty) {
      return;
    }
    throw ManifestException(
      'Missing or invalid "$fieldPath" in ${p.normalize(manifestPath)}',
    );
  }
}
