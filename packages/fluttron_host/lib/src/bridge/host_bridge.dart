import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:fluttron_shared/fluttron_shared.dart';

import '../services/system_service.dart';

class HostBridge {
  HostBridge({SystemService? systemService})
    : _systemService = systemService ?? SystemService();

  final SystemService _systemService;

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
          switch (req.method) {
            case 'system.getPlatform':
              final result = await _systemService.getPlatform();
              return FluttronResponse.ok(req.id, result).toJson();

            default:
              return FluttronResponse.err(req.id, 'method_not_found').toJson();
          }
        } catch (e) {
          return FluttronResponse.err(req.id, 'internal_error:$e').toJson();
        }
      },
    );
  }
}
