import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

/// Exception thrown when host service manifest parsing or validation fails.
class HostServiceManifestException implements Exception {
  HostServiceManifestException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Represents a parameter or return field in a host service method.
class HostServiceField {
  const HostServiceField({required this.type, this.required, this.description});

  final String type;
  final bool? required;
  final String? description;

  factory HostServiceField.fromJson(Map<String, dynamic> json) {
    return HostServiceField(
      type: json['type'] as String,
      required: json['required'] as bool?,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      if (required != null) 'required': required,
      if (description != null) 'description': description,
    };
  }
}

/// Represents a method declaration in a host service manifest.
class HostServiceMethod {
  const HostServiceMethod({
    required this.name,
    this.description,
    required this.params,
    required this.returns,
  });

  final String name;
  final String? description;
  final Map<String, HostServiceField> params;
  final Map<String, HostServiceField> returns;

  factory HostServiceMethod.fromJson(Map<String, dynamic> json) {
    final paramsJson = json['params'];
    final returnsJson = json['returns'];

    return HostServiceMethod(
      name: json['name'] as String,
      description: json['description'] as String?,
      params: _decodeFieldMap(paramsJson),
      returns: _decodeFieldMap(returnsJson),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      if (description != null) 'description': description,
      if (params.isNotEmpty)
        'params': params.map((k, v) => MapEntry(k, v.toJson())),
      if (returns.isNotEmpty)
        'returns': returns.map((k, v) => MapEntry(k, v.toJson())),
    };
  }

  static Map<String, HostServiceField> _decodeFieldMap(Object? raw) {
    if (raw == null) {
      return const {};
    }
    if (raw is! Map) {
      throw const FormatException('Field map must be a JSON object.');
    }
    final map = <String, HostServiceField>{};
    for (final entry in raw.entries) {
      final key = entry.key;
      final value = entry.value;
      if (key is! String) {
        throw const FormatException('Field map key must be a string.');
      }
      if (value is! Map) {
        throw const FormatException('Field map value must be a JSON object.');
      }
      map[key] = HostServiceField.fromJson(Map<String, dynamic>.from(value));
    }
    return map;
  }
}

/// Represents `fluttron_host_service.json`.
class HostServiceManifest {
  const HostServiceManifest({
    required this.version,
    required this.name,
    required this.namespace,
    this.description,
    required this.methods,
  });

  final String version;
  final String name;
  final String namespace;
  final String? description;
  final List<HostServiceMethod> methods;

  factory HostServiceManifest.fromJson(Map<String, dynamic> json) {
    return HostServiceManifest(
      version: json['version'] as String,
      name: json['name'] as String,
      namespace: json['namespace'] as String,
      description: json['description'] as String?,
      methods: (json['methods'] as List)
          .map(
            (entry) =>
                HostServiceMethod.fromJson(entry as Map<String, dynamic>),
          )
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'name': name,
      'namespace': namespace,
      if (description != null) 'description': description,
      'methods': methods.map((method) => method.toJson()).toList(),
    };
  }
}

class _HostServiceValidationPatterns {
  static final serviceName = RegExp(r'^[a-z][a-z0-9_]*$');
  static final methodName = RegExp(r'^[a-zA-Z][a-zA-Z0-9_]*$');
}

/// Loads and validates host service manifests.
class HostServiceManifestLoader {
  static const String fileName = 'fluttron_host_service.json';

  /// Loads and validates a manifest from a directory.
  static HostServiceManifest load(Directory serviceDir) {
    final manifestPath = p.join(serviceDir.path, fileName);
    final manifestFile = File(manifestPath);

    if (!manifestFile.existsSync()) {
      throw HostServiceManifestException(
        'Missing $fileName at ${p.normalize(manifestPath)}',
      );
    }

    final contents = manifestFile.readAsStringSync();
    final json = _decodeJson(contents, manifestPath);
    final manifest = _decodeManifest(json, manifestPath);
    _validateManifest(manifest, manifestPath);
    return manifest;
  }

  /// Loads and validates a manifest from a directory, returns null if missing.
  static HostServiceManifest? tryLoad(Directory serviceDir) {
    try {
      return load(serviceDir);
    } on HostServiceManifestException {
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
      throw HostServiceManifestException(
        '$fileName must be a JSON object: ${p.normalize(manifestPath)}',
      );
    } on FormatException catch (error) {
      throw HostServiceManifestException(
        'Invalid JSON in $fileName: ${p.normalize(manifestPath)} (${error.message})',
      );
    }
  }

  static HostServiceManifest _decodeManifest(
    Map<String, dynamic> json,
    String manifestPath,
  ) {
    try {
      return HostServiceManifest.fromJson(json);
    } catch (error) {
      throw HostServiceManifestException(
        'Invalid manifest schema in ${p.normalize(manifestPath)}: $error',
      );
    }
  }

  static void _validateManifest(
    HostServiceManifest manifest,
    String manifestPath,
  ) {
    if (manifest.version != '1') {
      throw HostServiceManifestException(
        'Invalid "version" in ${p.normalize(manifestPath)}: '
        'expected "1", got "${manifest.version}"',
      );
    }

    _validateServiceIdentifier(
      value: manifest.name,
      field: 'name',
      manifestPath: manifestPath,
    );
    _validateServiceIdentifier(
      value: manifest.namespace,
      field: 'namespace',
      manifestPath: manifestPath,
    );

    if (manifest.methods.isEmpty) {
      throw HostServiceManifestException(
        'Missing or empty "methods" in ${p.normalize(manifestPath)}',
      );
    }

    final seenMethodNames = <String>{};
    for (var i = 0; i < manifest.methods.length; i++) {
      final method = manifest.methods[i];
      if (!seenMethodNames.add(method.name)) {
        throw HostServiceManifestException(
          'Duplicate method name "${method.name}" in ${p.normalize(manifestPath)}',
        );
      }
      _validateMethod(method, i, manifestPath);
    }
  }

  static void _validateServiceIdentifier({
    required String value,
    required String field,
    required String manifestPath,
  }) {
    if (!_HostServiceValidationPatterns.serviceName.hasMatch(value)) {
      throw HostServiceManifestException(
        'Invalid "$field" in ${p.normalize(manifestPath)}: "$value" '
        'must be snake_case',
      );
    }
  }

  static void _validateMethod(
    HostServiceMethod method,
    int index,
    String manifestPath,
  ) {
    if (!_HostServiceValidationPatterns.methodName.hasMatch(method.name)) {
      throw HostServiceManifestException(
        'Invalid "methods[$index].name" in ${p.normalize(manifestPath)}: '
        '"${method.name}" must be a valid identifier',
      );
    }

    _validateFieldMap(
      fieldGroup: method.params,
      location: 'methods[$index].params',
      manifestPath: manifestPath,
      requireRequiredFlag: true,
    );
    _validateFieldMap(
      fieldGroup: method.returns,
      location: 'methods[$index].returns',
      manifestPath: manifestPath,
      requireRequiredFlag: false,
    );
  }

  static void _validateFieldMap({
    required Map<String, HostServiceField> fieldGroup,
    required String location,
    required String manifestPath,
    required bool requireRequiredFlag,
  }) {
    for (final entry in fieldGroup.entries) {
      final key = entry.key;
      final field = entry.value;

      if (!_HostServiceValidationPatterns.methodName.hasMatch(key)) {
        throw HostServiceManifestException(
          'Invalid "$location.$key" in ${p.normalize(manifestPath)}: '
          'field name must be a valid identifier',
        );
      }

      if (field.type.trim().isEmpty) {
        throw HostServiceManifestException(
          'Invalid "$location.$key.type" in ${p.normalize(manifestPath)}: '
          'type must not be empty',
        );
      }

      if (requireRequiredFlag && field.required == null) {
        throw HostServiceManifestException(
          'Missing "$location.$key.required" in ${p.normalize(manifestPath)}',
        );
      }
    }
  }
}
