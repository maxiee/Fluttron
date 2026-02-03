abstract class FluttronService {
  /// e.g. "system", "storage".
  String get namespace;

  /// Method is the part after the namespace, e.g. "getPlatform", "kvSet".
  Future<dynamic> handle(String method, Map<String, dynamic> params);
}
