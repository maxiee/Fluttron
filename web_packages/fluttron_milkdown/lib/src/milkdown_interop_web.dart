/// Web platform implementation for Milkdown interop.
///
/// Calls `window.fluttronMilkdownControl` JavaScript function.
library;

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'milkdown_interop.dart';

/// JavaScript response type for fluttronMilkdownControl.
extension type MilkdownControlResponse._(JSObject _) implements JSObject {
  external bool get ok;
  external JSAny? get result;
  external JSString? get error;
}

/// Calls the JavaScript control channel.
MilkdownControlResult callMilkdownControlImpl(
  int viewId,
  String action, [
  Map<String, dynamic>? params,
]) {
  final JSAny? responseAny = globalContext.callMethodVarArgs<JSAny?>(
    'fluttronMilkdownControl'.toJS,
    <JSAny?>[
      viewId.toJS,
      action.toJS,
      params != null ? _mapToJS(params) : null,
    ],
  );

  if (responseAny == null) {
    return MilkdownControlResult.failure(
      'fluttronMilkdownControl returned null',
    );
  }

  final MilkdownControlResponse response;
  try {
    response = responseAny as MilkdownControlResponse;
  } on Object {
    return MilkdownControlResult.failure(
      'fluttronMilkdownControl returned unexpected type',
    );
  }

  if (response.ok) {
    final dynamic dartResult = response.result?.dartify();
    return MilkdownControlResult.success(dartResult);
  }

  final String? errorMsg = response.error?.dartify() as String?;
  return MilkdownControlResult.failure(
    errorMsg ?? 'Unknown error from fluttronMilkdownControl',
  );
}

/// Converts a Dart Map to a JS object.
JSObject _mapToJS(Map<String, dynamic> map) {
  final JSObject jsObj = JSObject();
  for (final MapEntry<String, dynamic> entry in map.entries) {
    jsObj.setProperty(entry.key.toJS, _valueToJS(entry.value));
  }
  return jsObj;
}

/// Converts a Dart value to a JS value.
JSAny? _valueToJS(dynamic value) {
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
  if (value is List) {
    return value.map(_valueToJS).toList().toJS;
  }
  if (value is Map<String, dynamic>) {
    return _mapToJS(value);
  }
  return value.toString().toJS;
}
