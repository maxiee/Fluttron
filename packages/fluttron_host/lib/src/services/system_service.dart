import 'dart:io';

class SystemService {
  Future<Map<String, dynamic>> getPlatform() async {
    return <String, dynamic>{
      'platform': Platform.operatingSystem, // "macos"
    };
  }
}
