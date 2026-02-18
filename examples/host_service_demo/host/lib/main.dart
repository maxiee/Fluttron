import 'package:fluttron_host/fluttron_host.dart';

import 'greeting_service.dart';

void main() {
  final registry = ServiceRegistry()
    ..register(SystemService())
    ..register(StorageService())
    ..register(GreetingService()); // Register custom service

  runFluttronHost(registry: registry);
}
