import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:fluttron_host/src/services/service_registry.dart';
import 'package:fluttron_shared/fluttron_shared.dart';

class HostBridge {
  HostBridge({required this.registry});

  final ServiceRegistry registry;

  void attach(InAppWebViewController controller) {
    controller.addJavaScriptHandler(
      handlerName: 'fluttron',
      callback: (args) async {
        if (args.isEmpty) {
          return FluttronResponse.err('missing', 'missing_args').toJson();
        }

        final raw = args.first;
        if (raw is! Map) {
          return FluttronResponse.err('invalid', 'invalid_payload').toJson();
        }

        final req = FluttronRequest.fromJson(Map<String, dynamic>.from(raw));

        if (req.id.isEmpty || req.method.isEmpty) {
          return FluttronResponse.err(
            req.id.isEmpty ? 'invalid' : req.id,
            'bad_request',
          ).toJson();
        }

        try {
          final result = await registry.dispatch(req.method, req.params);
          return FluttronResponse.ok(req.id, result).toJson();
        } catch (e) {
          return FluttronResponse.err(req.id, 'internal_error:$e').toJson();
        }
      },
    );
  }
}
