import 'dart:io';

import 'package:fluttron_host/src/services/service.dart';
import 'package:fluttron_shared/fluttron_shared.dart';

class SystemService extends FluttronService {
  @override
  String get namespace => 'system';

  @override
  Future<dynamic> handle(String method, Map<String, dynamic> params) async {
    switch (method) {
      case 'getPlatform':
        return <String, dynamic>{
          'platform': Platform.operatingSystem,
        };
      default:
        throw FluttronError(
          'METHOD_NOT_FOUND',
          'system.$method not implemented',
        );
    }
  }
}
