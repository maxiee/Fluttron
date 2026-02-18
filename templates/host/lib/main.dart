// ===========================================================================
// Fluttron Host Entry Point
// ===========================================================================
//
// This is the main entry point for your Fluttron Host application.
// By default, it runs with the built-in services (system, storage).
//
// To add custom services:
// 1. Create a service class extending FluttronService (see greeting_service.dart)
// 2. Create a custom ServiceRegistry and register your services
// 3. Pass the registry to runFluttronHost()
//
// ===========================================================================

import 'package:fluttron_host/fluttron_host.dart';

// Uncomment to import your custom service:
// import 'greeting_service.dart';

void main() async {
  // Default: run with built-in services only
  await runFluttronHost();

  // -----------------------------------------------------------------------
  // ALTERNATIVE: Run with custom services
  // -----------------------------------------------------------------------
  // Uncomment the code below to register custom services alongside
  // the default system and storage services.
  //
  // Step 1: Create a ServiceRegistry
  // Step 2: Register built-in services (SystemService, StorageService)
  // Step 3: Register your custom services (e.g., GreetingService)
  // Step 4: Pass the registry to runFluttronHost()
  //
  // Example:
  // ```dart
  // void main() {
  //   final registry = ServiceRegistry()
  //     ..register(SystemService())
  //     ..register(StorageService())
  //     ..register(GreetingService()); // Your custom service
  //
  //   runFluttronHost(registry: registry);
  // }
  // ```
  //
  // Once enabled, you can call from UI:
  // ```dart
  // final result = await FluttronClient.invoke('greeting.greet', {});
  // ```
  // -----------------------------------------------------------------------

  // UNCOMMENT THE FOLLOWING CODE TO ENABLE CUSTOM SERVICES:
  //
  // final registry = ServiceRegistry()
  //   ..register(SystemService())
  //   ..register(StorageService())
  //   ..register(GreetingService()); // Add your custom services here
  //
  // runFluttronHost(registry: registry);
}
