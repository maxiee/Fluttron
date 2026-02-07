import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:ui_web' as ui_web;

bool get isFluttronHtmlViewSupported => true;

final Map<String, _RegisteredHtmlViewFactory> _registeredHtmlViewFactories =
    <String, _RegisteredHtmlViewFactory>{};

void ensureFluttronHtmlViewRegistered({
  required String viewType,
  required String jsFactoryName,
  List<dynamic>? jsFactoryArgs,
}) {
  final List<dynamic> normalizedArgs = _cloneJsonLikeList(
    jsFactoryArgs ?? const <dynamic>[],
  );
  final String argsSignature = _buildArgsSignature(normalizedArgs);
  final String argsDebug = _buildArgsDebug(normalizedArgs);
  final _RegisteredHtmlViewFactory? existingFactory =
      _registeredHtmlViewFactories[viewType];

  if (existingFactory != null) {
    if (existingFactory.matches(jsFactoryName, argsSignature)) {
      return;
    }

    throw StateError(
      'Conflicting FluttronHtmlView registration for viewType "$viewType". '
      'Existing jsFactoryName="${existingFactory.jsFactoryName}", '
      'jsFactoryArgs=${existingFactory.jsFactoryArgsDebug}. '
      'Incoming jsFactoryName="$jsFactoryName", jsFactoryArgs=$argsDebug.',
    );
  }

  ui_web.platformViewRegistry.registerViewFactory(viewType, (int viewId) {
    final JSObject global = globalContext;
    final List<JSAny?> factoryArgs = <JSAny?>[viewId.toJS];

    for (int index = 0; index < normalizedArgs.length; index++) {
      factoryArgs.add(
        _toJsAny(normalizedArgs[index], path: 'jsFactoryArgs[$index]'),
      );
    }

    final JSAny? viewElement = global.callMethodVarArgs<JSAny?>(
      jsFactoryName.toJS,
      factoryArgs,
    );

    if (viewElement == null) {
      throw StateError(
        'JS factory "$jsFactoryName" returned null for viewType "$viewType".',
      );
    }

    return viewElement;
  });

  _registeredHtmlViewFactories[viewType] = _RegisteredHtmlViewFactory(
    jsFactoryName: jsFactoryName,
    jsFactoryArgsSignature: argsSignature,
    jsFactoryArgsDebug: argsDebug,
  );
}

class _RegisteredHtmlViewFactory {
  const _RegisteredHtmlViewFactory({
    required this.jsFactoryName,
    required this.jsFactoryArgsSignature,
    required this.jsFactoryArgsDebug,
  });

  final String jsFactoryName;
  final String jsFactoryArgsSignature;
  final String jsFactoryArgsDebug;

  bool matches(String incomingFactoryName, String incomingArgsSignature) {
    return jsFactoryName == incomingFactoryName &&
        jsFactoryArgsSignature == incomingArgsSignature;
  }
}

String _buildArgsSignature(List<dynamic> args) {
  return jsonEncode(_canonicalizeJsonLikeValue(args, path: 'jsFactoryArgs'));
}

String _buildArgsDebug(List<dynamic> args) {
  return jsonEncode(_canonicalizeJsonLikeValue(args, path: 'jsFactoryArgs'));
}

List<dynamic> _cloneJsonLikeList(List<dynamic> source) {
  return List<dynamic>.generate(
    source.length,
    (int index) =>
        _cloneJsonLikeValue(source[index], path: 'jsFactoryArgs[$index]'),
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

JSAny? _toJsAny(Object? value, {required String path}) {
  if (value == null) {
    return null;
  }
  if (value is String) {
    return value.toJS;
  }
  if (value is num) {
    return value.toJS;
  }
  if (value is bool) {
    return value.toJS;
  }
  if (value is List || value is Map) {
    final JSAny? jsValue = value.jsify();
    if (jsValue == null) {
      throw StateError('Failed to convert $path to a JS value.');
    }
    return jsValue;
  }

  throw StateError(
    'Unsupported value in $path: ${value.runtimeType}. '
    'Allowed types: String, num, bool, null, List, Map<String, dynamic>.',
  );
}
