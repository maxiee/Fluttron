import 'dart:convert';

class FluttronResolvedHtmlViewDescriptor {
  const FluttronResolvedHtmlViewDescriptor({
    required this.type,
    required this.resolvedViewType,
    required this.normalizedArgs,
    required this.argsSignature,
    required this.argsDebug,
  });

  final String type;
  final String resolvedViewType;
  final List<dynamic> normalizedArgs;
  final String argsSignature;
  final String argsDebug;
}

class FluttronResolvedHtmlViewFactoryRecord {
  const FluttronResolvedHtmlViewFactoryRecord({
    required this.type,
    required this.jsFactoryName,
    required this.argsSignature,
    required this.argsDebug,
  });

  final String type;
  final String jsFactoryName;
  final String argsSignature;
  final String argsDebug;

  bool matches({
    required String incomingJsFactoryName,
    required String incomingArgsSignature,
  }) {
    return jsFactoryName == incomingJsFactoryName &&
        argsSignature == incomingArgsSignature;
  }
}

class FluttronResolvedHtmlViewFactoryRegistry {
  final Map<String, FluttronResolvedHtmlViewFactoryRecord> _records =
      <String, FluttronResolvedHtmlViewFactoryRecord>{};

  bool hasCompatibleRegistrationOrThrow({
    required String resolvedViewType,
    required String type,
    required String jsFactoryName,
    required String argsSignature,
    required String argsDebug,
  }) {
    final FluttronResolvedHtmlViewFactoryRecord? existingRecord =
        _records[resolvedViewType];
    if (existingRecord == null) {
      return false;
    }

    if (existingRecord.matches(
      incomingJsFactoryName: jsFactoryName,
      incomingArgsSignature: argsSignature,
    )) {
      return true;
    }

    throw StateError(
      'Conflicting FluttronHtmlView registration for resolvedViewType '
      '"$resolvedViewType" (type "$type"). Existing '
      'jsFactoryName="${existingRecord.jsFactoryName}", '
      'jsFactoryArgs=${existingRecord.argsDebug}. Incoming '
      'jsFactoryName="$jsFactoryName", jsFactoryArgs=$argsDebug.',
    );
  }

  void record({
    required String resolvedViewType,
    required String type,
    required String jsFactoryName,
    required String argsSignature,
    required String argsDebug,
  }) {
    _records[resolvedViewType] = FluttronResolvedHtmlViewFactoryRecord(
      type: type,
      jsFactoryName: jsFactoryName,
      argsSignature: argsSignature,
      argsDebug: argsDebug,
    );
  }
}

FluttronResolvedHtmlViewDescriptor resolveFluttronHtmlViewDescriptor({
  required String type,
  List<dynamic>? args,
}) {
  final List<dynamic> normalizedArgs = _cloneJsonLikeList(
    args ?? const <dynamic>[],
    path: 'args',
  );
  final String argsSignature = _buildArgsSignature(normalizedArgs);
  final String argsDebug = _buildArgsDebug(normalizedArgs);
  final String resolvedViewType = _buildResolvedViewType(
    type: type,
    args: normalizedArgs,
    argsSignature: argsSignature,
  );

  return FluttronResolvedHtmlViewDescriptor(
    type: type,
    resolvedViewType: resolvedViewType,
    normalizedArgs: normalizedArgs,
    argsSignature: argsSignature,
    argsDebug: argsDebug,
  );
}

String _buildResolvedViewType({
  required String type,
  required List<dynamic> args,
  required String argsSignature,
}) {
  if (args.isEmpty) {
    return type;
  }
  return '$type.__${_fnv1a64Hex(argsSignature)}';
}

String _buildArgsSignature(List<dynamic> args) {
  return jsonEncode(_canonicalizeJsonLikeValue(args, path: 'args'));
}

String _buildArgsDebug(List<dynamic> args) {
  return jsonEncode(_canonicalizeJsonLikeValue(args, path: 'args'));
}

String _fnv1a64Hex(String input) {
  const String offsetBasisHex = 'cbf29ce484222325';
  const String primeHex = '100000001b3';
  const String maskHex = 'ffffffffffffffff';

  final BigInt offsetBasis = BigInt.parse(offsetBasisHex, radix: 16);
  final BigInt prime = BigInt.parse(primeHex, radix: 16);
  final BigInt mask = BigInt.parse(maskHex, radix: 16);

  BigInt hash = offsetBasis;
  final List<int> bytes = utf8.encode(input);

  for (final int byte in bytes) {
    hash = ((hash ^ BigInt.from(byte)) * prime) & mask;
  }

  return hash.toRadixString(16).padLeft(16, '0');
}

List<dynamic> _cloneJsonLikeList(List<dynamic> source, {required String path}) {
  return List<dynamic>.generate(
    source.length,
    (int index) => _cloneJsonLikeValue(source[index], path: '$path[$index]'),
    growable: false,
  );
}

Object? _cloneJsonLikeValue(Object? value, {required String path}) {
  if (value == null || value is String || value is bool) {
    return value;
  }
  if (value is num) {
    if (value is double && !value.isFinite) {
      throw StateError(
        'Invalid value in $path: non-finite double values are not supported.',
      );
    }
    return value;
  }
  if (value is List) {
    return List<dynamic>.generate(
      value.length,
      (int index) => _cloneJsonLikeValue(value[index], path: '$path[$index]'),
      growable: false,
    );
  }
  if (value is Map) {
    final Map<String, dynamic> clone = <String, dynamic>{};
    for (final MapEntry<dynamic, dynamic> entry in value.entries) {
      final Object? rawKey = entry.key;
      if (rawKey is! String) {
        throw StateError(
          'Invalid map key type in $path: ${rawKey.runtimeType}. '
          'Only String keys are supported.',
        );
      }
      clone[rawKey] = _cloneJsonLikeValue(entry.value, path: '$path.$rawKey');
    }
    return clone;
  }

  throw StateError(
    'Unsupported value in $path: ${value.runtimeType}. '
    'Allowed types: String, num, bool, null, List, Map<String, dynamic>.',
  );
}

Object? _canonicalizeJsonLikeValue(Object? value, {required String path}) {
  if (value == null || value is String || value is bool || value is num) {
    return value;
  }
  if (value is List) {
    return List<Object?>.generate(
      value.length,
      (int index) =>
          _canonicalizeJsonLikeValue(value[index], path: '$path[$index]'),
      growable: false,
    );
  }
  if (value is Map) {
    final List<String> keys = <String>[];
    for (final Object? rawKey in value.keys) {
      if (rawKey is! String) {
        throw StateError(
          'Invalid map key type in $path: ${rawKey.runtimeType}. '
          'Only String keys are supported.',
        );
      }
      keys.add(rawKey);
    }
    keys.sort();

    final Map<String, Object?> canonicalized = <String, Object?>{};
    for (final String key in keys) {
      canonicalized[key] = _canonicalizeJsonLikeValue(
        value[key],
        path: '$path.$key',
      );
    }
    return canonicalized;
  }

  throw StateError(
    'Unsupported value in $path: ${value.runtimeType}. '
    'Allowed types: String, num, bool, null, List, Map<String, dynamic>.',
  );
}
