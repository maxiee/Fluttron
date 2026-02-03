import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:fluttron_shared/fluttron_shared.dart';

class RendererBridge {
  int _seq = 0;

  Future<dynamic> invoke(String method, Map<String, dynamic> params) async {
    final id = '${DateTime.now().millisecondsSinceEpoch}-${_seq++}';
    final req = FluttronRequest(id: id, method: method, params: params);

    // globalContext ~= globalThis (in general)
    final JSObject global = globalContext;

    // window.flutter_inappwebview
    final JSAny? flutterInappwebviewAny = global['flutter_inappwebview'];
    if (flutterInappwebviewAny == null) {
      throw StateError(
        'flutter_inappwebview not found: not running inside Fluttron Host WebView?',
      );
    }

    final JSObject flutterInappwebview = flutterInappwebviewAny as JSObject;

    // InAppWebView injection: window.flutter_inappwebview.callHandler(...)
    // - arg 1: 'fluttron'
    // - arg 2: req.toJson() -> JS value via jsify()
    final JSAny? promiseAny = flutterInappwebview.callMethodVarArgs<JSAny?>(
      'callHandler'.toJS,
      <JSAny?>[
        'fluttron'.toJS,
        req.toJson().jsify() ?? JSObject(), // Ensure a non-null payload.
      ],
    );

    if (promiseAny == null) {
      throw StateError('callHandler returned null (unexpected)');
    }

    final JSPromise<JSAny?> promise = promiseAny as JSPromise<JSAny?>;

    // Promise -> Future via toDart
    final JSAny? respJs = await promise.toDart;

    // JS JSON-like -> Dart via dartify()
    final Object? respDart = respJs.dartify();
    if (respDart is! Map) {
      throw StateError(
        'Unexpected response type from callHandler: ${respDart.runtimeType}',
      );
    }

    final resp = FluttronResponse.fromJson(Map<String, dynamic>.from(respDart));
    if (!resp.ok) {
      throw StateError('Fluttron error: ${resp.error}');
    }
    return resp.result;
  }
}
