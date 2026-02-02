import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:fluttron_shared/fluttron_shared.dart';

class FluttronClient {
  int _seq = 0;

  Future<dynamic> invoke(String method, Map<String, dynamic> params) async {
    final id = '${DateTime.now().millisecondsSinceEpoch}-${_seq++}';
    final req = FluttronRequest(id: id, method: method, params: params);

    final JSObject global = globalContext;

    // window.flutter_inappwebview
    final JSAny? flutterInappwebviewAny = global['flutter_inappwebview'];
    if (flutterInappwebviewAny == null) {
      throw StateError(
        'flutter_inappwebview not found: not running inside Fluttron Host WebView?',
      );
    }

    final JSObject flutterInappwebview = flutterInappwebviewAny as JSObject;

    // callHandler('fluttron', jsifiedPayload)
    final JSAny? promiseAny = flutterInappwebview.callMethodVarArgs<JSAny?>(
      'callHandler'.toJS,
      <JSAny?>[
        'fluttron'.toJS,
        req.toJson().jsify() ?? JSObject(), // 兜底：不传 null
      ],
    );

    if (promiseAny == null) {
      throw StateError('callHandler returned null (unexpected)');
    }

    final JSPromise<JSAny?> promise = promiseAny as JSPromise<JSAny?>;
    final JSAny? respJs = await promise.toDart;

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

  Future<String> getPlatform() async {
    final result = await invoke('system.getPlatform', {});
    if (result is Map && result['platform'] != null) {
      return result['platform'].toString();
    }
    return result?.toString() ?? 'unknown';
  }

  Future<void> kvSet(String key, String value) async {
    await invoke('storage.kvSet', {'key': key, 'value': value});
  }

  Future<String?> kvGet(String key) async {
    final result = await invoke('storage.kvGet', {'key': key});
    if (result is Map) {
      final v = result['value'];
      return v?.toString();
    }
    return result?.toString();
  }
}
