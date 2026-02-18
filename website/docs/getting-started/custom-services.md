# Custom Host Services

This tutorial shows how to create and use custom Host services in Fluttron.

## What is a Host Service?

A Host Service is a Dart class that runs in the native Host layer and provides capabilities to the UI layer via the Bridge. Services can:

- Access native platform APIs (file system, dialogs, etc.)
- Perform background computation
- Integrate with native libraries
- Persist data

Built-in services (`file`, `dialog`, `clipboard`, `system`, `storage`) are provided by the framework. You can create custom services for your app-specific needs.

## Two Approaches

| Approach | Use Case | Complexity |
|----------|----------|------------|
| **Inline Service** | Simple, app-specific services | Low |
| **Service Package** | Reusable services, sharing across projects | Medium |

## Quick Start: Inline Service

### 1. Create the Service

Create a file in your host app, e.g., `host/lib/my_service.dart`:

```dart
import 'package:fluttron_host/fluttron_host.dart';
import 'package:fluttron_shared/fluttron_shared.dart';

class MyService extends FluttronService {
  @override
  String get namespace => 'my_service';

  @override
  Future<dynamic> handle(String method, Map<String, dynamic> params) async {
    switch (method) {
      case 'greet':
        return _greet(params);
      default:
        throw FluttronError(
          'METHOD_NOT_FOUND',
          'my_service.$method not implemented',
        );
    }
  }

  Map<String, dynamic> _greet(Map<String, dynamic> params) {
    final name = params['name'] as String? ?? 'World';
    return {'message': 'Hello, $name!'};
  }
}
```

### 2. Register the Service

Update `host/lib/main.dart`:

```dart
import 'package:fluttron_host/fluttron_host.dart';
import 'my_service.dart';  // Import your service

void main() {
  final registry = ServiceRegistry()
    ..register(SystemService())
    ..register(StorageService())
    ..register(MyService());  // Register your service

  runFluttronHost(registry: registry);
}
```

### 3. Call from UI

In your UI code:

```dart
import 'package:fluttron_ui/fluttron_ui.dart';

final client = FluttronClient();
final result = await client.invoke('my_service.greet', {'name': 'Alice'});
print(result['message']); // "Hello, Alice!"
```

## Service Package (Recommended for Reuse)

For services you want to share across projects, create a service package using the CLI:

### 1. Create the Package

```bash
fluttron create ./my_awesome_service --type host_service --name my_awesome_service
```

This creates:

```
my_awesome_service/
├── fluttron_host_service.json     # Service manifest
├── README.md
├── my_awesome_service_host/       # Host-side implementation
│   ├── pubspec.yaml
│   ├── lib/
│   │   ├── my_awesome_service_host.dart
│   │   └── src/my_awesome_service.dart
│   └── test/
└── my_awesome_service_client/     # UI-side client stub
    ├── pubspec.yaml
    ├── lib/
    │   ├── my_awesome_service_client.dart
    │   └── src/my_awesome_service_client.dart
    └── test/
```

### 2. Implement the Service

Edit `my_awesome_service_host/lib/src/my_awesome_service.dart`:

```dart
import 'package:fluttron_host/fluttron_host.dart';
import 'package:fluttron_shared/fluttron_shared.dart';

class MyAwesomeService extends FluttronService {
  @override
  String get namespace => 'my_awesome_service';

  @override
  Future<dynamic> handle(String method, Map<String, dynamic> params) async {
    switch (method) {
      case 'doSomething':
        return _doSomething(params);
      default:
        throw FluttronError(
          'METHOD_NOT_FOUND',
          'my_awesome_service.$method not implemented',
        );
    }
  }

  Map<String, dynamic> _doSomething(Map<String, dynamic> params) {
    // Your implementation here
    return {'result': 'done'};
  }
}
```

### 3. Add Client Methods

Edit `my_awesome_service_client/lib/src/my_awesome_service_client.dart`:

```dart
import 'package:fluttron_ui/fluttron_ui.dart';

class MyAwesomeServiceClient {
  MyAwesomeServiceClient(this._client);

  final FluttronClient _client;

  Future<String> doSomething({String? input}) async {
    final params = <String, dynamic>{};
    if (input != null) params['input'] = input;
    final result = await _client.invoke('my_awesome_service.doSomething', params);
    return result['result'] as String;
  }
}
```

### 4. Use in Your App

**Host side** — Add to `host/pubspec.yaml`:

```yaml
dependencies:
  my_awesome_service_host:
    path: ../../my_awesome_service/my_awesome_service_host
```

**Host main.dart**:

```dart
import 'package:my_awesome_service_host/my_awesome_service_host.dart';

void main() {
  final registry = ServiceRegistry()
    ..register(SystemService())
    ..register(StorageService())
    ..register(MyAwesomeService());
  
  runFluttronHost(registry: registry);
}
```

**UI side** — Add to `ui/pubspec.yaml`:

```yaml
dependencies:
  my_awesome_service_client:
    path: ../../my_awesome_service/my_awesome_service_client
```

**UI code**:

```dart
import 'package:my_awesome_service_client/my_awesome_service_client.dart';

final client = FluttronClient();
final myService = MyAwesomeServiceClient(client);
final result = await myService.doSomething(input: 'test');
```

## Service Manifest

The `fluttron_host_service.json` file documents your service contract:

```json
{
  "version": "1",
  "name": "my_service",
  "namespace": "my_service",
  "description": "A custom Fluttron host service.",
  "methods": [
    {
      "name": "greet",
      "description": "Returns a greeting message.",
      "params": {
        "name": { "type": "string", "required": false, "description": "Name to greet" }
      },
      "returns": {
        "message": { "type": "string", "description": "Greeting message" }
      }
    }
  ]
}
```

The manifest serves as documentation and will be used for code generation in future versions.

## Best Practices

### Error Handling

Always use `FluttronError` for service errors:

```dart
if (params['required_param'] == null) {
  throw FluttronError('BAD_PARAMS', 'Missing required parameter: required_param');
}
```

Common error codes:
- `METHOD_NOT_FOUND` — Unknown method
- `BAD_PARAMS` — Invalid or missing parameters
- `INTERNAL_ERROR` — Unexpected failure

### Namespace Conventions

- Use `snake_case` for namespaces
- Avoid collision with built-in services (`file`, `dialog`, `clipboard`, `system`, `storage`)
- Use descriptive names: `user_prefs`, `network_api`, `notification`

### Parameter Validation

```dart
Map<String, dynamic> _myMethod(Map<String, dynamic> params) {
  // Validate required params
  final text = params['text'];
  if (text is! String || text.isEmpty) {
    throw FluttronError('BAD_PARAMS', 'Missing or empty "text" parameter');
  }
  
  // Handle optional params
  final count = params['count'] as int? ?? 10;
  
  // Return a Map
  return {'result': text.repeat(count)};
}
```

## Example: Complete E2E Demo

See [examples/host_service_demo](../../examples/host_service_demo/) for a complete working example that demonstrates:

- A `GreetingService` with `greet` and `echo` methods
- Service registration in the Host
- Service invocation from the UI
- Result display in a Flutter UI

## Next Steps

- [Services API Reference](../api/services.md) — Built-in service documentation
- [Host Layer Architecture](../architecture/host-layer.md) — Deep dive into the Host layer
- [Bridge Communication](../architecture/bridge-communication.md) — How Host and UI communicate
