import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:ui_web' as ui_web;

import 'html_view_runtime.dart';
import 'web_view_registry.dart';

bool get isFluttronHtmlViewSupported => true;

final FluttronResolvedHtmlViewFactoryRegistry _registeredHtmlViewFactories =
    FluttronResolvedHtmlViewFactoryRegistry();

String ensureFluttronHtmlViewRegistered({
  required String type,
  List<dynamic>? args,
}) {
  final FluttronWebViewRegistration registration =
      FluttronWebViewRegistry.lookup(type);
  final FluttronResolvedHtmlViewDescriptor descriptor =
      resolveFluttronHtmlViewDescriptor(type: registration.type, args: args);
  final bool alreadyRegistered = _registeredHtmlViewFactories
      .hasCompatibleRegistrationOrThrow(
        resolvedViewType: descriptor.resolvedViewType,
        type: descriptor.type,
        jsFactoryName: registration.jsFactoryName,
        argsSignature: descriptor.argsSignature,
        argsDebug: descriptor.argsDebug,
      );
  if (alreadyRegistered) {
    return descriptor.resolvedViewType;
  }

  ui_web.platformViewRegistry.registerViewFactory(descriptor.resolvedViewType, (
    int viewId,
  ) {
    final JSObject global = globalContext;
    final List<JSAny?> factoryArgs = <JSAny?>[viewId.toJS];

    for (int index = 0; index < descriptor.normalizedArgs.length; index++) {
      factoryArgs.add(
        _toJsAny(descriptor.normalizedArgs[index], path: 'args[$index]'),
      );
    }

    final JSAny? viewElement = global.callMethodVarArgs<JSAny?>(
      registration.jsFactoryName.toJS,
      factoryArgs,
    );

    if (viewElement == null) {
      throw StateError(
        'JS factory "${registration.jsFactoryName}" returned null for '
        'resolvedViewType "${descriptor.resolvedViewType}" (type '
        '"${descriptor.type}").',
      );
    }

    return viewElement;
  });

  _registeredHtmlViewFactories.record(
    resolvedViewType: descriptor.resolvedViewType,
    type: descriptor.type,
    jsFactoryName: registration.jsFactoryName,
    argsSignature: descriptor.argsSignature,
    argsDebug: descriptor.argsDebug,
  );
  return descriptor.resolvedViewType;
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
