# Host Service Demo

A minimal Fluttron app demonstrating custom Host service integration.

## What This Demonstrates

This example shows the end-to-end flow of creating and using a custom Host service:

1. **Define a Service** — `host/lib/greeting_service.dart` implements `FluttronService`
2. **Register the Service** — `host/lib/main.dart` adds the service to the registry
3. **Call from UI** — `ui/lib/main.dart` invokes the service via `FluttronClient`

## Custom Service: GreetingService

The `GreetingService` provides two methods:

| Method | Params | Returns |
|--------|--------|---------|
| `greeting.greet` | `name` (optional) | `{message: string}` |
| `greeting.echo` | `text` (required) | `{text: string, timestamp: string}` |

## Quick Start

From the repository root:

```bash
# Build the app
dart run packages/fluttron_cli/bin/fluttron.dart build -p examples/host_service_demo

# Run on macOS
cd examples/host_service_demo/host
flutter run -d macos
```

## Code Walkthrough

### 1. Service Implementation (Host)

```dart
// host/lib/greeting_service.dart
class GreetingService extends FluttronService {
  @override
  String get namespace => 'greeting';

  @override
  Future<dynamic> handle(String method, Map<String, dynamic> params) async {
    switch (method) {
      case 'greet':
        return _greet(params);
      case 'echo':
        return _echo(params);
      default:
        throw FluttronError('METHOD_NOT_FOUND', 'greeting.$method not implemented');
    }
  }
  
  // ... implementation details
}
```

### 2. Service Registration (Host)

```dart
// host/lib/main.dart
void main() {
  final registry = ServiceRegistry()
    ..register(SystemService())
    ..register(StorageService())
    ..register(GreetingService()); // Add your custom service

  runFluttronHost(registry: registry);
}
```

### 3. Service Invocation (UI)

```dart
// ui/lib/main.dart
final client = FluttronClient();

// Call the custom service
final result = await client.invoke('greeting.greet', {'name': 'Fluttron'});
print(result['message']); // "Hello, Fluttron! Welcome to Fluttron."
```

## Architecture

```
┌─────────────────────────────────────────┐
│  Host (Flutter Desktop)                 │
│  ┌───────────────────────────────────┐  │
│  │  ServiceRegistry                  │  │
│  │  ├─ SystemService                 │  │
│  │  ├─ StorageService                │  │
│  │  └─ GreetingService ← YOUR SERVICE│  │
│  └───────────────────────────────────┘  │
│                  │                      │
│           HostBridge                    │
└──────────────────┼──────────────────────┘
                   │ JSON IPC
┌──────────────────┼──────────────────────┐
│  UI (Flutter Web)│                      │
│  ┌───────────────┴─────────────────┐    │
│  │  FluttronClient                 │    │
│  │  .invoke('greeting.greet', ...) │    │
│  └─────────────────────────────────┘    │
└─────────────────────────────────────────┘
```

## See Also

- [Custom Services Tutorial](../../website/docs/getting-started/custom-services.md)
- [Services API](../../website/docs/api/services.md)
- [Host Layer Architecture](../../website/docs/architecture/host-layer.md)
