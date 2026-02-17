import 'package:fluttron_host/src/services/service.dart';
import 'package:fluttron_shared/fluttron_shared.dart';

class StorageService extends FluttronService {
  @override
  String get namespace => 'storage';

  final Map<String, String> _kv = {};

  @override
  Future<dynamic> handle(String method, Map<String, dynamic> params) async {
    switch (method) {
      case 'kvSet':
        final key = requireString(params, 'key');
        final value = requireString(params, 'value', allowEmpty: true);
        _kv[key] = value;
        return {'ok': true};
      case 'kvGet':
        final key = requireString(params, 'key');
        final value = _kv[key];
        return {'value': value}; // value maybe null
      default:
        throw FluttronError(
          'METHOD_NOT_FOUND',
          'storage.$method not implemented',
        );
    }
  }

  String requireString(
    Map<String, dynamic> params,
    String key, {
    bool allowEmpty = false,
  }) {
    final v = params[key];
    if (v is String && (allowEmpty || v.isNotEmpty)) {
      return v;
    }
    throw FluttronError('BAD_PARAMS', 'Missing or invalid "$key"');
  }
}
