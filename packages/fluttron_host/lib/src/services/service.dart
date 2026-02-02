import 'package:fluttron_shared/fluttron_shared.dart';

abstract class FluttronService {
  /// e.g. "system", "storage"
  String get namespace;

  /// method 是 namespace 后面的部分，比如 "getPlatform", "kvSet"
  Future<dynamic> handle(String method, Map<String, dynamic> params);
}
