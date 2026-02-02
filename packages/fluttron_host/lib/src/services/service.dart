import 'package:fluttron_shared/fluttron_shared.dart';

abstract class FluttronService {
  /// e.g. "system", "storage"
  String get namespace;

  /// method 是 namespace 后面的部分，比如 "getPlatform", "kvSet"
  Future<dynamic> handle(String method, Map<String, dynamic> params);
}

/// 小工具：参数校验用（MVP 用最少即可）
String requireString(Map<String, dynamic> params, String key) {
  final v = params[key];
  if (v is String && v.isNotEmpty) return v;
  throw FluttronError('BAD_PARAMS', 'Missing or invalid "$key"');
}
