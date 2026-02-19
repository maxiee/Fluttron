// ===========================================================================
// Fluttron Host Entry Point
// ===========================================================================
//
// This is the main entry point for your Fluttron Host application.
// By default, it runs with the built-in services:
//   - SystemService  (system.*)   — platform info
//   - StorageService (storage.*)  — persistent key-value store
//   - FileService    (file.*)     — file read/write/list
//   - DialogService  (dialog.*)   — native open/save dialogs
//   - ClipboardService (clipboard.*) — clipboard read/write
//   - WindowService  (window.*)   — window control (title/size/fullscreen…)
//   - LoggingService (logging.*)  — structured logging with ring buffer
//
// Global error boundaries are set up automatically by runFluttronHost():
//   - FlutterError.onError catches uncaught widget/framework errors
//   - runZonedGuarded catches uncaught async Dart errors
// All uncaught errors are logged with stack traces to host stdout.
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
  // Default: run with all built-in services (including WindowService + LoggingService).
  // Error boundaries (FlutterError.onError + runZonedGuarded) are set up
  // automatically inside runFluttronHost().
  await runFluttronHost();

  // -----------------------------------------------------------------------
  // ALTERNATIVE: Run with custom services
  // -----------------------------------------------------------------------
  // Uncomment the code below to register custom services alongside
  // the default built-in services.
  //
  // Step 1: Create a ServiceRegistry
  // Step 2: Register built-in services
  // Step 3: Register your custom services (e.g., GreetingService)
  // Step 4: Pass the registry to runFluttronHost()
  //
  // Example:
  // ```dart
  // void main() async {
  //   final registry = ServiceRegistry()
  //     ..register(SystemService())
  //     ..register(StorageService())
  //     ..register(FileService())
  //     ..register(DialogService())
  //     ..register(ClipboardService())
  //     ..register(WindowService())
  //     ..register(LoggingService())
  //     ..register(GreetingService()); // Your custom service
  //
  //   await runFluttronHost(registry: registry);
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
  //   ..register(FileService())
  //   ..register(DialogService())
  //   ..register(ClipboardService())
  //   ..register(WindowService())
  //   ..register(LoggingService())
  //   ..register(GreetingService()); // Add your custom services here
  //
  // await runFluttronHost(registry: registry);
}
