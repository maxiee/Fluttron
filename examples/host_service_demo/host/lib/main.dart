import 'package:fluttron_host/fluttron_host.dart';

import 'greeting_service.dart';

Future<void> main() async {
  final registry = ServiceRegistry()
    ..register(SystemService())
    ..register(StorageService())
    ..register(GreetingService()); // Register custom service

  await runFluttronHost(registry: registry);
}
