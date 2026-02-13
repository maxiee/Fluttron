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
│  ┌──────▼─────┐ ┌────▼──────┐ ┌───▼──────┐   │
│  │SystemService│ │StorageService│ │Custom...│   │
│  └────────────┘ └───────────┘ └──────────┘   │
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

Entry point for the host app. By default, it creates a registry with built-in services:

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

### Web Asset Loader

Host loads Renderer assets via a custom scheme (`fluttron://local/...`) and maps
them to `host/assets/www/...` at runtime.

```dart
InAppWebView(
  initialUrlRequest: URLRequest(
    url: WebUri('fluttron://local/index.html'),
  ),
  initialSettings: InAppWebViewSettings(
    resourceCustomSchemes: ['fluttron'],
  ),
  onLoadResourceWithCustomScheme: (controller, request) async {
    final assetPath = 'assets/www${request.url.path}';
    // load bytes from Flutter assets and return CustomSchemeResponse
  },
)
```

This means any files synced by `fluttron build` are directly available to the
WebView, including:

- Core UI assets (`index.html`, `flutter_bootstrap.js`, Flutter-generated files)
- Template frontend assets (`ext/main.js`, optional `ext/main.css`)
- Web package assets (`ext/packages/<package>/...`)

### Services

All services implement:

```dart
abstract class FluttronService {
  String get namespace;
  Future<dynamic> handle(String method, Map<String, dynamic> params);
}
```

## Built-in Services

| Service | Namespace | Description |
|---------|-----------|-------------|
| SystemService | `system` | Platform information |
| StorageService | `storage` | In-memory key-value store |

## Bridge Error Behavior

`HostBridge` validates payload shape and returns normalized error responses.

| Scenario | Response error |
|---------|-----------------|
| Missing JS handler args | `missing_args` |
| Non-map payload | `invalid_payload` |
| Empty request id/method | `bad_request` |
| Known service error (`FluttronError`) | `CODE:message` |
| Unexpected exception | `internal_error:<message>` |

## Custom Services

You can extend Fluttron with custom services that can be invoked from the UI layer.

### Creating a Custom Service

1. Create a service class extending `FluttronService`:

```dart
import 'package:fluttron_host/fluttron_host.dart';
import 'package:fluttron_shared/fluttron_shared.dart';

class GreetingService extends FluttronService {
  @override
  String get namespace => 'greeting';

  @override
  Future<dynamic> handle(String method, Map<String, dynamic> params) async {
    switch (method) {
      case 'greet':
        return <String, dynamic>{
          'message': 'Hello from custom service!',
        };
      default:
        throw FluttronError(
          'METHOD_NOT_FOUND',
          'greeting.$method not implemented',
        );
    }
  }
}
```

2. Create a custom `ServiceRegistry` and register your services:

```dart
import 'package:fluttron_host/fluttron_host.dart';
import 'greeting_service.dart';

void main() {
  final registry = ServiceRegistry()
    ..register(SystemService())
    ..register(StorageService())
    ..register(GreetingService()); // Your custom service

  runFluttronHost(registry: registry);
}
```

3. Call from UI using `FluttronClient`:

```dart
final result = await FluttronClient.invoke('greeting.greet', {});
print(result['message']); // "Hello from custom service!"
```

### Template Example

When you create a new Fluttron project, the Host template includes a `greeting_service.dart` file with a commented-out example service. Uncomment it and follow the instructions to enable custom services.

## Relation to Web Packages

Web Package integration does not require Host-side service changes. The Host
simply serves whatever was produced by the CLI build pipeline in `assets/www/`.

## Next Steps

- [Renderer Layer](./renderer-layer.md) - Renderer architecture
- [Bridge Communication](./bridge-communication.md) - IPC details
- [Services API](../api/services.md) - Built-in services reference
