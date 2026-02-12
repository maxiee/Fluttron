// ===========================================================================
// Custom Service Extension Example
// ===========================================================================
//
// This file demonstrates how to create a custom Host service that can be
// invoked from the UI (Flutter Web) via FluttronClient.invoke().
//
// To enable this service:
// 1. Uncomment the code below
// 2. Import this file in main.dart
// 3. Register GreetingService in your custom ServiceRegistry
//
// From UI, call: FluttronClient.invoke('greeting.greet', {})
// Expected response: {'message': 'Hello from custom service!'}
//
// ===========================================================================

// UNCOMMENT THE FOLLOWING CODE TO ENABLE:

// import 'package:fluttron_host/fluttron_host.dart';
// import 'package:fluttron_shared/fluttron_shared.dart';
//
// /// A custom Host service example.
// ///
// /// This service provides a simple greeting API that can be called
// /// from the UI layer via the Fluttron bridge.
// ///
// /// Usage from UI:
// /// ```dart
// /// final result = await FluttronClient.invoke('greeting.greet', {});
// /// print(result['message']); // "Hello from custom service!"
// /// ```
// class GreetingService extends FluttronService {
//   @override
//   String get namespace => 'greeting';
//
//   @override
//   Future<dynamic> handle(String method, Map<String, dynamic> params) async {
//     switch (method) {
//       case 'greet':
//         return <String, dynamic>{
//           'message': 'Hello from custom service!',
//         };
//       default:
//         throw FluttronError(
//           'METHOD_NOT_FOUND',
//           'greeting.$method not implemented',
//         );
//     }
//   }
// }
