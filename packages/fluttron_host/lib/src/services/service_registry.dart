import 'package:fluttron_shared/fluttron_shared.dart';
import 'service.dart';

class ServiceRegistry {
  final Map<String, FluttronService> _services = {};

  void register(FluttronService service) {
    _services[service.namespace] = service;
  }

  Future<dynamic> dispatch(
    String fullMethod,
    Map<String, dynamic> params,
  ) async {
    final parts = fullMethod.split('.');
    if (parts.length != 2) {
      throw FluttronError(
        'BAD_METHOD',
        'Method must be like "namespace.method": $fullMethod',
      );
    }

    final namespace = parts[0];
    final method = parts[1];

    final service = _services[namespace];
    if (service == null) {
      throw FluttronError(
        'NAMESPACE_NOT_FOUND',
        'No service for namespace "$namespace"',
      );
    }

    return await service.handle(method, params);
  }
}
