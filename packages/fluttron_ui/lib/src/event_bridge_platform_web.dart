import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

Object createFluttronEventBridgeDelegate() => _WebFluttronEventBridgeDelegate();

Stream<Map<String, dynamic>> fluttronEventBridgeOn({
  required Object delegate,
  required String eventName,
}) {
  return _expectDelegate(delegate).on(eventName);
}

void disposeFluttronEventBridgeDelegate(Object delegate) {
  _expectDelegate(delegate).dispose();
}

_WebFluttronEventBridgeDelegate _expectDelegate(Object delegate) {
  if (delegate is _WebFluttronEventBridgeDelegate) {
    return delegate;
  }
  throw StateError(
    'Invalid FluttronEventBridge delegate type: ${delegate.runtimeType}.',
  );
}

class _WebFluttronEventBridgeDelegate {
  final Map<String, StreamController<Map<String, dynamic>>> _controllers =
      <String, StreamController<Map<String, dynamic>>>{};
  final Map<String, JSFunction> _listeners = <String, JSFunction>{};
  bool _isDisposed = false;

  Stream<Map<String, dynamic>> on(String eventName) {
    if (_isDisposed) {
      throw StateError('FluttronEventBridge is already disposed.');
    }

    final StreamController<Map<String, dynamic>>? existingController =
        _controllers[eventName];
    if (existingController != null) {
      return existingController.stream;
    }

    final StreamController<Map<String, dynamic>> controller =
        StreamController<Map<String, dynamic>>.broadcast();

    final JSFunction listener = ((JSAny? eventAny) {
      final Map<String, dynamic>? detail = _extractEventDetail(eventAny);
      if (detail == null || controller.isClosed) {
        return;
      }
      controller.add(detail);
    }).toJS;

    _controllers[eventName] = controller;
    _listeners[eventName] = listener;

    final JSObject global = globalContext;
    global.callMethodVarArgs<JSAny?>('addEventListener'.toJS, <JSAny?>[
      eventName.toJS,
      listener,
    ]);

    return controller.stream;
  }

  void dispose() {
    if (_isDisposed) {
      return;
    }
    _isDisposed = true;

    final JSObject global = globalContext;
    for (final MapEntry<String, JSFunction> entry in _listeners.entries) {
      global.callMethodVarArgs<JSAny?>('removeEventListener'.toJS, <JSAny?>[
        entry.key.toJS,
        entry.value,
      ]);
    }
    _listeners.clear();

    for (final StreamController<Map<String, dynamic>> controller
        in _controllers.values) {
      unawaited(controller.close());
    }
    _controllers.clear();
  }

  Map<String, dynamic>? _extractEventDetail(JSAny? eventAny) {
    if (eventAny == null) {
      return null;
    }

    final JSObject eventObject;
    try {
      eventObject = eventAny as JSObject;
    } on Object {
      return null;
    }

    final JSAny? detailAny = eventObject['detail'];
    if (detailAny == null) {
      return null;
    }

    final Object? detail = detailAny.dartify();
    return _coerceDetailMap(detail);
  }

  Map<String, dynamic>? _coerceDetailMap(Object? value) {
    if (value is! Map) {
      return null;
    }

    final Map<String, dynamic> result = <String, dynamic>{};
    for (final MapEntry<Object?, Object?> entry in value.entries) {
      final Object? key = entry.key;
      if (key == null) {
        continue;
      }
      result[key.toString()] = _coerceJsonLike(entry.value);
    }
    return result;
  }

  Object? _coerceJsonLike(Object? value) {
    if (value == null || value is String || value is num || value is bool) {
      return value;
    }

    if (value is List) {
      return List<Object?>.generate(
        value.length,
        (int index) => _coerceJsonLike(value[index]),
        growable: false,
      );
    }

    if (value is Map) {
      final Map<String, Object?> result = <String, Object?>{};
      for (final MapEntry<Object?, Object?> entry in value.entries) {
        final Object? key = entry.key;
        if (key == null) {
          continue;
        }
        result[key.toString()] = _coerceJsonLike(entry.value);
      }
      return result;
    }

    return value.toString();
  }
}
