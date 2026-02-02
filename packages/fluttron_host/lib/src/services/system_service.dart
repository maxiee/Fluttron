import 'dart:io';

import 'package:fluttron_host/src/services/service.dart';

class SystemService extends FluttronService {
  @override
  String get namespace => 'system';

  @override
  Future<dynamic> handle(String method, Map<String, dynamic> params) async {
    return <String, dynamic>{
      'platform': Platform.operatingSystem, // "macos"
    };
  }
}
