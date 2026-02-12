import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

/// Exception thrown when web package manifest parsing or validation fails.
class WebPackageManifestException implements Exception {
  WebPackageManifestException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Represents a view factory declaration in the manifest.
class ViewFactory {
  const ViewFactory({
    required this.type,
    required this.jsFactoryName,
    this.description,
  });

  /// View type identifier (e.g., "milkdown.editor").
  final String type;

  /// JavaScript factory function name (e.g., "fluttronCreateMilkdownEditorView").
  final String jsFactoryName;

  /// Optional human-readable description.
  final String? description;

  factory ViewFactory.fromJson(Map<String, dynamic> json) {
    return ViewFactory(
      type: json['type'] as String,
      jsFactoryName: json['jsFactoryName'] as String,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'jsFactoryName': jsFactoryName,
      if (description != null) 'description': description,
    };
  }

  @override
  String toString() =>
      'ViewFactory(type: $type, jsFactoryName: $jsFactoryName)';
}

/// Represents asset file declarations (JS and CSS).
class Assets {
  const Assets({required this.js, this.css});

  /// List of JavaScript file paths (e.g., ["web/ext/main.js"]).
  final List<String> js;

  /// Optional list of CSS file paths (e.g., ["web/ext/main.css"]).
  final List<String>? css;

  factory Assets.fromJson(Map<String, dynamic> json) {
    return Assets(
      js: (json['js'] as List).cast<String>(),
      css: (json['css'] as List?)?.cast<String>(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'js': js, if (css != null) 'css': css};
  }

  @override
  String toString() => 'Assets(js: $js, css: $css)';
}

/// Event direction enum.
enum EventDirection {
  jsToDart,
  dartToJs,
  bidirectional;

  static EventDirection fromString(String value) {
    return switch (value) {
      'js_to_dart' => EventDirection.jsToDart,
      'dart_to_js' => EventDirection.dartToJs,
      'bidirectional' => EventDirection.bidirectional,
      _ => throw ArgumentError('Unknown event direction: $value'),
    };
  }

  String toJsonValue() {
    return switch (this) {
      EventDirection.jsToDart => 'js_to_dart',
      EventDirection.dartToJs => 'dart_to_js',
      EventDirection.bidirectional => 'bidirectional',
    };
  }
}

/// Represents an event declaration in the manifest.
class Event {
  const Event({required this.name, required this.direction, this.payloadType});

  /// Event name (e.g., "fluttron.milkdown.editor.change").
  final String name;

  /// Event direction.
  final EventDirection direction;

  /// Optional TypeScript-style type definition.
  final String? payloadType;

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      name: json['name'] as String,
      direction: EventDirection.fromString(json['direction'] as String),
      payloadType: json['payloadType'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'direction': direction.toJsonValue(),
      if (payloadType != null) 'payloadType': payloadType,
    };
  }

  @override
  String toString() => 'Event(name: $name, direction: $direction)';
}

/// Represents a web package manifest (fluttron_web_package.json).
class WebPackageManifest {
  const WebPackageManifest({
    required this.version,
    required this.viewFactories,
    required this.assets,
    this.events,
    this.packageName,
    this.rootPath,
  });

  /// Manifest schema version (must be "1").
  final String version;

  /// List of view factory declarations.
  final List<ViewFactory> viewFactories;

  /// Asset file declarations.
  final Assets assets;

  /// Optional list of event declarations.
  final List<Event>? events;

  /// Package name (set during discovery, not in manifest file).
  final String? packageName;

  /// Root path of the package (set during discovery, not in manifest file).
  final String? rootPath;

  factory WebPackageManifest.fromJson(Map<String, dynamic> json) {
    return WebPackageManifest(
      version: json['version'] as String,
      viewFactories: (json['viewFactories'] as List)
          .map((e) => ViewFactory.fromJson(e as Map<String, dynamic>))
          .toList(),
      assets: Assets.fromJson(json['assets'] as Map<String, dynamic>),
      events: (json['events'] as List?)
          ?.map((e) => Event.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'viewFactories': viewFactories.map((e) => e.toJson()).toList(),
      'assets': assets.toJson(),
      if (events != null) 'events': events!.map((e) => e.toJson()).toList(),
    };
  }

  /// Creates a copy with packageName and rootPath set.
  WebPackageManifest copyWith({String? packageName, String? rootPath}) {
    return WebPackageManifest(
      version: version,
      viewFactories: viewFactories,
      assets: assets,
      events: events,
      packageName: packageName ?? this.packageName,
      rootPath: rootPath ?? this.rootPath,
    );
  }

  @override
  String toString() =>
      'WebPackageManifest(packageName: $packageName, version: $version, viewFactories: $viewFactories)';
}

/// Validation patterns as defined in the PRD.
class _ValidationPatterns {
  // View type: package.type format (e.g., "milkdown.editor")
  static final viewType = RegExp(r'^[a-z0-9_]+\.[a-z0-9_]+$');

  // JS factory name: fluttronCreate<Name>View
  static final jsFactoryName = RegExp(r'^fluttronCreate[A-Z][a-zA-Z0-9]*View$');

  // JS asset path: web/ext/filename.js
  static final jsAssetPath = RegExp(r'^web/ext/[^/]+\.js$');

  // CSS asset path: web/ext/filename.css
  static final cssAssetPath = RegExp(r'^web/ext/[^/]+\.css$');

  // Event name: fluttron.package.type.event
  static final eventName = RegExp(r'^fluttron\.[a-z0-9_]+\.[a-z0-9_.]+$');
}

/// Loads and validates web package manifest files.
class WebPackageManifestLoader {
  static const String fileName = 'fluttron_web_package.json';

  /// Loads and validates a manifest from a directory.
  static WebPackageManifest load(Directory packageDir) {
    final manifestPath = p.join(packageDir.path, fileName);
    final manifestFile = File(manifestPath);

    if (!manifestFile.existsSync()) {
      throw WebPackageManifestException(
        'Missing $fileName at ${p.normalize(manifestPath)}',
      );
    }

    final contents = manifestFile.readAsStringSync();
    final json = _decodeJson(contents, manifestPath);
    final manifest = _decodeManifest(json, manifestPath);
    _validateManifest(manifest, manifestPath);

    return manifest;
  }

  /// Loads and validates a manifest from a directory, returns null if not found.
  static WebPackageManifest? tryLoad(Directory packageDir) {
    try {
      return load(packageDir);
    } on WebPackageManifestException {
      return null;
    }
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
      throw WebPackageManifestException(
        '$fileName must be a JSON object: ${p.normalize(manifestPath)}',
      );
    } on FormatException catch (error) {
      throw WebPackageManifestException(
        'Invalid JSON in $fileName: ${p.normalize(manifestPath)} (${error.message})',
      );
    }
  }

  static WebPackageManifest _decodeManifest(
    Map<String, dynamic> json,
    String manifestPath,
  ) {
    try {
      return WebPackageManifest.fromJson(json);
    } catch (error) {
      throw WebPackageManifestException(
        'Invalid manifest schema in ${p.normalize(manifestPath)}: $error',
      );
    }
  }

  static void _validateManifest(
    WebPackageManifest manifest,
    String manifestPath,
  ) {
    // Validate version
    if (manifest.version != '1') {
      throw WebPackageManifestException(
        'Invalid "version" in ${p.normalize(manifestPath)}: '
        'expected "1", got "${manifest.version}"',
      );
    }

    // Validate viewFactories
    if (manifest.viewFactories.isEmpty) {
      throw WebPackageManifestException(
        'Missing or empty "viewFactories" in ${p.normalize(manifestPath)}',
      );
    }

    for (var i = 0; i < manifest.viewFactories.length; i++) {
      _validateViewFactory(manifest.viewFactories[i], i, manifestPath);
    }

    // Validate assets
    _validateAssets(manifest.assets, manifestPath);

    // Validate events (optional)
    if (manifest.events != null) {
      for (var i = 0; i < manifest.events!.length; i++) {
        _validateEvent(manifest.events![i], i, manifestPath);
      }
    }
  }

  static void _validateViewFactory(
    ViewFactory factory,
    int index,
    String manifestPath,
  ) {
    // Validate type pattern
    if (!_ValidationPatterns.viewType.hasMatch(factory.type)) {
      throw WebPackageManifestException(
        'Invalid "viewFactories[$index].type" in ${p.normalize(manifestPath)}: '
        '"${factory.type}" does not match pattern '
        '"package.type" (e.g., "milkdown.editor")',
      );
    }

    // Validate jsFactoryName pattern
    if (!_ValidationPatterns.jsFactoryName.hasMatch(factory.jsFactoryName)) {
      throw WebPackageManifestException(
        'Invalid "viewFactories[$index].jsFactoryName" in ${p.normalize(manifestPath)}: '
        '"${factory.jsFactoryName}" does not match pattern '
        '"fluttronCreate<Name>View" (e.g., "fluttronCreateMilkdownEditorView")',
      );
    }
  }

  static void _validateAssets(Assets assets, String manifestPath) {
    // Validate js array exists and is non-empty
    if (assets.js.isEmpty) {
      throw WebPackageManifestException(
        'Missing or empty "assets.js" in ${p.normalize(manifestPath)}',
      );
    }

    // Validate each JS path
    for (var i = 0; i < assets.js.length; i++) {
      final path = assets.js[i];
      if (!_ValidationPatterns.jsAssetPath.hasMatch(path)) {
        throw WebPackageManifestException(
          'Invalid "assets.js[$i]" in ${p.normalize(manifestPath)}: '
          '"$path" does not match pattern "web/ext/filename.js"',
        );
      }
    }

    // Validate each CSS path (optional)
    if (assets.css != null) {
      for (var i = 0; i < assets.css!.length; i++) {
        final path = assets.css![i];
        if (!_ValidationPatterns.cssAssetPath.hasMatch(path)) {
          throw WebPackageManifestException(
            'Invalid "assets.css[$i]" in ${p.normalize(manifestPath)}: '
            '"$path" does not match pattern "web/ext/filename.css"',
          );
        }
      }
    }
  }

  static void _validateEvent(Event event, int index, String manifestPath) {
    // Validate event name pattern
    if (!_ValidationPatterns.eventName.hasMatch(event.name)) {
      throw WebPackageManifestException(
        'Invalid "events[$index].name" in ${p.normalize(manifestPath)}: '
        '"${event.name}" does not match pattern '
        '"fluttron.package.type.event" (e.g., "fluttron.milkdown.editor.change")',
      );
    }
  }
}
