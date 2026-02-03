# Host Layer

The Host layer is a Flutter Desktop application that provides native capabilities and manages the application lifecycle.

## Architecture

```
┌───────────────────────────────────────────────┐
│         Fluttron Host (Desktop App)           │
│                                               │
│  ┌─────────────────────────────────────────┐    │
│  │  main.dart                           │    │
│  │  • Application initialization           │    │
│  │  • ServiceRegistry setup               │    │
│  │  • WebView window creation             │    │
│  └───────────────────┬───────────────────┘    │
│                      │                          │
│  ┌───────────────────▼───────────────────┐    │
│  │  ServiceRegistry                      │    │
│  │  • Register services                  │    │
│  │  • Route requests (namespace.method)   │    │
│  └───────────────────┬───────────────────┘    │
│         ┌─────────────┼─────────────┐           │
│         │             │             │           │
│  ┌──────▼─────┐ ┌──▼─────────┐ ┌──▼──────┐  │
│  │SystemService│ │StorageService│ │FileService│  │
│  └────────────┘ └────────────┘ └─────────┘  │
│                                               │
│  ┌─────────────────────────────────────────┐    │
│  │  Host Bridge                        │    │
│  │  • JavaScriptHandler: 'fluttron'    │    │
│  │  • Parse FluttronRequest            │    │
│  │  • Invoke ServiceRegistry             │    │
│  │  • Return FluttronResponse          │    │
│  └───────────────────┬───────────────────┘    │
└──────────────────────┼───────────────────────────┘
                       │
                       │ JavaScript Handler
                       │
                WebView Container
```

## Key Components

### main.dart

Entry point for the Host application.

**Responsibilities:**
- Initialize Flutter app
- Create and configure ServiceRegistry
- Register available services (System, Storage, etc.)
- Create WebView window with Flutter Web app loaded

**Example:**
```dart
void main() {
  final registry = ServiceRegistry();

  registry.register(SystemService());
  registry.register(StorageService());

  runApp(FluttronHost(serviceRegistry: registry));
}
```

### ServiceRegistry

Central service registration and routing mechanism.

**Responsibilities:**
- Register services with unique namespaces
- Route requests to correct service based on `namespace.method` format
- Handle service discovery and lifecycle

**Usage:**
```dart
final registry = ServiceRegistry();

// Register service
registry.register(SystemService());

// Invoke service
final response = await registry.invoke('system.getPlatform', {});
```

### Host Bridge

Communication bridge between Host and Renderer using JavaScript Handlers.

**Responsibilities:**
- Register JavaScript handler named 'fluttron'
- Parse incoming JSON requests
- Route to ServiceRegistry
- Convert responses back to JSON

**Implementation:**
```dart
final webView = InAppWebView(
  initialOptions: InAppWebViewGroupOptions(
    crossPlatform: InAppWebViewOptions(
      javaScriptEnabled: true,
    ),
  ),
  onLoadStop: (controller, url) async {
    await controller.addJavaScriptHandler(
      handlerName: 'fluttron',
      callback: (args) async {
        final request = FluttronRequest.fromJson(args[0]);
        final response = await serviceRegistry.invoke(
          request.method,
          request.params,
        );
        return response.toJson();
      },
    );
  },
);
```

### Services

Host services expose native capabilities. Each service extends `FluttronService`.

**Base Class:**
```dart
abstract class FluttronService {
  String get namespace;
  Future<dynamic> handle(String method, dynamic params);
}
```

**Example - SystemService:**
```dart
class SystemService extends FluttronService {
  @override
  String get namespace => 'system';

  @override
  Future<dynamic> handle(String method, dynamic params) async {
    switch (method) {
      case 'getPlatform':
        return {'platform': Platform.operatingSystem};
      default:
        throw FluttronError.unknownMethod(method);
    }
  }
}
```

## Available Services

| Service | Namespace | Description |
|---------|-----------|-------------|
| SystemService | `system` | Platform information, system capabilities |
| StorageService | `storage` | Key-value storage (memory-based) |
| FileService | `file` | File system access (planned) |
| DatabaseService | `database` | SQLite database (planned) |

## Window Management

Host manages application windows and WebView lifecycle.

**Key Features:**
- Create multiple windows
- Window configuration (size, position, title)
- Load Flutter Web from `assets/www`
- Intercept navigation for custom routing

## Security

Host implements security boundaries:

- **Sandbox**: Renderer runs in isolated WebView
- **Permission Control**: Services control access to resources
- **Request Validation**: All requests validated before execution
- **Error Handling**: Graceful error responses to Renderer

## Platform Support

Host is built with Flutter Desktop:

- **macOS**: Cocoa-based
- **Linux**: GTK-based
- **Windows**: Win32-based

Initial development focuses on macOS.

## Next Steps

- [Renderer Layer](./renderer-layer.md) - Learn about Renderer architecture
- [Bridge Communication](./bridge-communication.md) - IPC mechanism details
- [API Reference](../api/services.md) - Service API documentation
