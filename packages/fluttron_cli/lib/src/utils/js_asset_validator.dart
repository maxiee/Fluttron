import 'dart:io';

import 'package:path/path.dart' as p;

class JsAssetValidationException implements Exception {
  const JsAssetValidationException(this.message);

  final String message;

  @override
  String toString() => message;
}

class JsScriptAsset {
  const JsScriptAsset({required this.sourceValue, required this.relativePath});

  final String sourceValue;
  final String relativePath;

  bool get isFlutterGenerated =>
      JsAssetValidator.isFlutterGeneratedScript(relativePath);
}

class JsAssetValidator {
  const JsAssetValidator();

  static const Set<String> _flutterGeneratedScriptNames = <String>{
    'flutter_bootstrap.js',
    'flutter.js',
    'main.dart.js',
    'flutter_service_worker.js',
  };

  static final RegExp _scriptSrcPattern = RegExp(
    r'''<script\b[^>]*\bsrc\s*=\s*(["'])([^"']+)\1''',
    caseSensitive: false,
  );

  List<JsScriptAsset> collectLocalScriptAssets({
    required File indexFile,
    required Directory webRootDir,
  }) {
    final normalizedIndexPath = p.normalize(indexFile.path);
    if (!indexFile.existsSync()) {
      throw JsAssetValidationException(
        'JS asset validation failed: index file not found: $normalizedIndexPath',
      );
    }

    final indexRelativePath = _relativePathWithinRoot(
      filePath: indexFile.path,
      rootPath: webRootDir.path,
      errorPrefix: 'Invalid index file location',
    );
    final indexDirectory = p.posix.dirname(indexRelativePath);
    final html = indexFile.readAsStringSync();

    final assets = <JsScriptAsset>[];
    final deduplicatedPaths = <String>{};
    for (final match in _scriptSrcPattern.allMatches(html)) {
      final srcValue = (match.group(2) ?? '').trim();
      if (srcValue.isEmpty || _isRemoteScript(srcValue)) {
        continue;
      }

      final resolvedPath = _resolveScriptPath(
        srcValue: srcValue,
        indexDirectory: indexDirectory == '.' ? '' : indexDirectory,
      );

      if (_isPathOutsideRoot(resolvedPath)) {
        throw JsAssetValidationException(
          'Invalid local script path "$srcValue" in $normalizedIndexPath: resolved outside web root.',
        );
      }

      if (deduplicatedPaths.add(resolvedPath)) {
        assets.add(
          JsScriptAsset(sourceValue: srcValue, relativePath: resolvedPath),
        );
      }
    }

    return assets;
  }

  List<String> findMissingAssetPaths({
    required Directory rootDir,
    required Iterable<JsScriptAsset> assets,
  }) {
    final missingPaths = <String>[];
    for (final asset in assets) {
      final file = File(p.join(rootDir.path, asset.relativePath));
      if (!file.existsSync()) {
        missingPaths.add(p.normalize(file.path));
      }
    }
    return missingPaths;
  }

  static bool isFlutterGeneratedScript(String relativePath) {
    final normalizedPath = relativePath.replaceAll('\\', '/');
    final scriptName = p.posix.basename(normalizedPath);
    return _flutterGeneratedScriptNames.contains(scriptName);
  }

  String _relativePathWithinRoot({
    required String filePath,
    required String rootPath,
    required String errorPrefix,
  }) {
    final relativePath = p
        .relative(filePath, from: rootPath)
        .replaceAll('\\', '/');
    if (_isPathOutsideRoot(relativePath)) {
      throw JsAssetValidationException(
        '$errorPrefix: ${p.normalize(filePath)}',
      );
    }
    return p.posix.normalize(relativePath);
  }

  String _resolveScriptPath({
    required String srcValue,
    required String indexDirectory,
  }) {
    final stripped = _stripQueryAndHash(srcValue).replaceAll('\\', '/');
    if (stripped.startsWith('/')) {
      return p.posix.normalize(stripped.substring(1));
    }
    if (indexDirectory.isEmpty) {
      return p.posix.normalize(stripped);
    }
    return p.posix.normalize(p.posix.join(indexDirectory, stripped));
  }

  String _stripQueryAndHash(String value) {
    var sanitized = value;
    final hashIndex = sanitized.indexOf('#');
    if (hashIndex >= 0) {
      sanitized = sanitized.substring(0, hashIndex);
    }
    final queryIndex = sanitized.indexOf('?');
    if (queryIndex >= 0) {
      sanitized = sanitized.substring(0, queryIndex);
    }
    return sanitized.trim();
  }

  bool _isRemoteScript(String srcValue) {
    final lowerValue = srcValue.toLowerCase();
    return lowerValue.startsWith('http://') ||
        lowerValue.startsWith('https://') ||
        lowerValue.startsWith('//') ||
        lowerValue.startsWith('data:') ||
        lowerValue.startsWith('blob:') ||
        lowerValue.startsWith('javascript:');
  }

  bool _isPathOutsideRoot(String relativePath) {
    return relativePath.isEmpty ||
        relativePath == '.' ||
        relativePath == '..' ||
        relativePath.startsWith('../') ||
        p.posix.isAbsolute(relativePath);
  }
}
