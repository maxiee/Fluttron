# Host Layer

The Host layer is a Flutter Desktop application that exposes native services and loads the Renderer in a WebView.

## Architecture

```
┌───────────────────────────────────────────────┐
│         Fluttron Host (Desktop App)           │
│                                               │
│  ┌─────────────────────────────────────────┐  │
│  │ runFluttronHost()                        │  │
│  │ • Initializes ServiceRegistry            │  │
│  │ • Registers System/Storage services      │  │
│  │ • Creates WebView container              │  │
│  └───────────────────┬──────────────────────┘  │
│                      │                         │
│  ┌───────────────────▼──────────────────────┐  │
│  │ ServiceRegistry                           │  │
│  │ • Route "namespace.method"                │  │
│  └───────────────────┬──────────────────────┘  │
│         ┌────────────┼─────────────┐          │
│         │            │             │          │
│  ┌──────▼─────┐ ┌────▼──────┐       │          │
│  │SystemService│ │StorageService│    │          │
│  └────────────┘ └───────────┘       │          │
│                                               │
│  ┌─────────────────────────────────────────┐  │
│  │ Host Bridge                              │  │
│  │ • JavaScriptHandler: 'fluttron'          │  │
│  │ • Parse FluttronRequest                  │  │
│  │ • Dispatch to ServiceRegistry            │  │
│  │ • Return FluttronResponse                │  │
│  └───────────────────┬──────────────────────┘  │
└──────────────────────┼─────────────────────────┘
                       │
                       │ JavaScript Handler
                       │
                WebView Container
```

## Key Components

### runFluttronHost()

Entry point for the host app.

```dart
void main() {
  runFluttronHost();
}
```

### ServiceRegistry

Routes calls using the `namespace.method` format.

```dart
final registry = ServiceRegistry();
registry.register(SystemService());
registry.register(StorageService());

final result = await registry.dispatch('system.getPlatform', {});
```

### Host Bridge

Registers the JavaScript handler and forwards requests.

```dart
controller.addJavaScriptHandler(
  handlerName: 'fluttron',
  callback: (args) async {
    final request = FluttronRequest.fromJson(
      Map<String, dynamic>.from(args.first as Map),
    );
    final result = await registry.dispatch(
      request.method,
      request.params,
    );
    return FluttronResponse.ok(request.id, result).toJson();
  },
);
```

### Services

All services implement:

```dart
abstract class FluttronService {
  String get namespace;
  Future<dynamic> handle(String method, Map<String, dynamic> params);
}
```

## Available Services

| Service | Namespace | Description |
|---------|-----------|-------------|
| SystemService | `system` | Platform information |
| StorageService | `storage` | In-memory key-value store |

## Next Steps

- [Renderer Layer](./renderer-layer.md) - Renderer architecture
- [Bridge Communication](./bridge-communication.md) - IPC details
