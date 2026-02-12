import 'dart:io';

import 'web_package_collector.dart';

/// Exception thrown when HTML injection fails.
class HtmlInjectorException implements Exception {
  HtmlInjectorException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Result of HTML injection operation.
class InjectionResult {
  const InjectionResult({
    required this.injectedJsCount,
    required this.injectedCssCount,
    required this.outputPath,
  });

  /// Number of JS script tags injected.
  final int injectedJsCount;

  /// Number of CSS link tags injected.
  final int injectedCssCount;

  /// Path to the modified HTML file.
  final String outputPath;

  /// Returns true if any tags were injected.
  bool get hasInjections => injectedJsCount > 0 || injectedCssCount > 0;
}

/// Injects web package JS/CSS references into HTML files.
///
/// This class replaces placeholder comments in `index.html` with actual
/// `<script>` and `<link>` tags for collected web package assets.
///
/// Placeholder format:
/// - `<!-- FLUTTRON_PACKAGES_JS -->` - replaced with JS script tags
/// - `<!-- FLUTTRON_PACKAGES_CSS -->` - replaced with CSS link tags
///
/// Example usage:
/// ```dart
/// final injector = HtmlInjector();
/// final result = await injector.inject(
///   indexHtml: File('path/to/ui/build/web/index.html'),
///   collectionResult: collectedAssets,
/// );
/// print('Injected ${result.injectedJsCount} JS and ${result.injectedCssCount} CSS');
/// ```
class HtmlInjector {
  /// JS placeholder comment in HTML.
  static const String jsPlaceholder = '<!-- FLUTTRON_PACKAGES_JS -->';

  /// CSS placeholder comment in HTML.
  static const String cssPlaceholder = '<!-- FLUTTRON_PACKAGES_CSS -->';

  /// Injects web package assets into the HTML file.
  ///
  /// [indexHtml] - The HTML file to modify (typically `ui/build/web/index.html`).
  /// [collectionResult] - The result from `WebPackageCollector.collect()`.
  ///
  /// Returns an [InjectionResult] with injection counts and output path.
  ///
  /// Throws [HtmlInjectorException] if:
  /// - The HTML file does not exist
  /// - Required placeholders are missing in the HTML
  Future<InjectionResult> inject({
    required File indexHtml,
    required CollectionResult collectionResult,
  }) async {
    // Validate file exists
    if (!await indexHtml.exists()) {
      throw HtmlInjectorException(
        'HTML file not found: ${indexHtml.path}\n'
        'Ensure Flutter web build has completed (flutter build web).',
      );
    }

    // Read HTML content
    var content = await indexHtml.readAsString();

    // Validate placeholders exist
    _validatePlaceholders(content);

    // Generate tag strings
    final jsTags = _generateJsTags(collectionResult.jsAssetPaths);
    final cssTags = _generateCssTags(collectionResult.cssAssetPaths);

    // Replace placeholders
    content = content.replaceFirst(jsPlaceholder, jsTags);
    content = content.replaceFirst(cssPlaceholder, cssTags);

    // Write back to file
    await indexHtml.writeAsString(content);

    return InjectionResult(
      injectedJsCount: collectionResult.jsAssetPaths.length,
      injectedCssCount: collectionResult.cssAssetPaths.length,
      outputPath: indexHtml.path,
    );
  }

  /// Synchronous version of [inject].
  InjectionResult injectSync({
    required File indexHtml,
    required CollectionResult collectionResult,
  }) {
    if (!indexHtml.existsSync()) {
      throw HtmlInjectorException(
        'HTML file not found: ${indexHtml.path}\n'
        'Ensure Flutter web build has completed (flutter build web).',
      );
    }

    var content = indexHtml.readAsStringSync();

    _validatePlaceholders(content);

    final jsTags = _generateJsTags(collectionResult.jsAssetPaths);
    final cssTags = _generateCssTags(collectionResult.cssAssetPaths);

    content = content.replaceFirst(jsPlaceholder, jsTags);
    content = content.replaceFirst(cssPlaceholder, cssTags);

    indexHtml.writeAsStringSync(content);

    return InjectionResult(
      injectedJsCount: collectionResult.jsAssetPaths.length,
      injectedCssCount: collectionResult.cssAssetPaths.length,
      outputPath: indexHtml.path,
    );
  }

  /// Validates that required placeholders exist in the HTML content.
  void _validatePlaceholders(String content) {
    final missingPlaceholders = <String>[];

    if (!content.contains(jsPlaceholder)) {
      missingPlaceholders.add(jsPlaceholder);
    }
    if (!content.contains(cssPlaceholder)) {
      missingPlaceholders.add(cssPlaceholder);
    }

    if (missingPlaceholders.isNotEmpty) {
      throw HtmlInjectorException(
        'Missing required placeholder(s) in index.html:\n'
        '  ${missingPlaceholders.join('\n  ')}\n'
        'Ensure the HTML template includes these placeholder comments.',
      );
    }
  }

  /// Generates JS script tags from asset paths.
  ///
  /// Each path is converted to a `<script src="...">` tag.
  /// Returns empty string if no paths provided.
  String _generateJsTags(List<String> jsPaths) {
    if (jsPaths.isEmpty) {
      return '';
    }

    final tags = jsPaths.map((path) => '<script src="$path"></script>');
    return tags.join('\n');
  }

  /// Generates CSS link tags from asset paths.
  ///
  /// Each path is converted to a `<link rel="stylesheet" href="...">` tag.
  /// Returns empty string if no paths provided.
  String _generateCssTags(List<String> cssPaths) {
    if (cssPaths.isEmpty) {
      return '';
    }

    final tags = cssPaths.map((path) => '<link rel="stylesheet" href="$path">');
    return tags.join('\n');
  }
}
