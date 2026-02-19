# fluttron_host

Host runtime package for Fluttron desktop applications.

Provides the WebView container, service registry, and built-in native services that power a Fluttron app's native side.

## Quick Start

```dart
import 'package:fluttron_host/fluttron_host.dart';

void main() {
  final registry = ServiceRegistry()
    ..register(SystemService())
    ..register(StorageService())
    ..register(FileService())
    ..register(DialogService())
    ..register(ClipboardService())
    ..register(WindowService())
    ..register(LoggingService());

  runFluttronHost(registry: registry);
}
```

## Built-in Services

| Namespace | Methods | Purpose |
|-----------|---------|---------|
| `system.*` | `getPlatform` | Platform info |
| `storage.*` | `kvSet`, `kvGet` | Persistent key-value storage |
| `file.*` | `readFile`, `writeFile`, `listDirectory`, `stat`, `createFile`, `delete`, `rename`, `exists` | File system |
| `dialog.*` | `openFile`, `openFiles`, `openDirectory`, `saveFile` | Native dialogs |
| `clipboard.*` | `getText`, `setText`, `hasText` | System clipboard |
| `window.*` | `setTitle`, `setSize`, `getSize`, `minimize`, `maximize`, `setFullScreen`, `isFullScreen`, `center`, `setMinSize` | Window control |
| `logging.*` | `log`, `getLogs`, `clear` | Structured logging (ring buffer) |

## Custom Services

Implement `FluttronService` and register it:

```dart
class GreetingService extends FluttronService {
  @override
  String get namespace => 'greeting';

  @override
  Future<dynamic> handle(String method, Map<String, dynamic> params) async {
    switch (method) {
      case 'hello':
        return {'message': 'Hello, ${params['name']}!'};
      default:
        throw FluttronError('METHOD_NOT_FOUND', 'greeting.$method not found');
    }
  }
}

// Register:
registry.register(GreetingService());
```

For type-safe service contracts with code generation, see the [Custom Services guide](https://maxiee.github.io/Fluttron/docs/getting-started/custom-services).

## Global Error Handling

The host bootstraps `runZonedGuarded` and `FlutterError.onError` automatically when you call `runFluttronHost`. Uncaught errors are logged to stdout with stack traces.

## Documentation

Full documentation: <https://maxiee.github.io/Fluttron/>

- [Getting Started](https://maxiee.github.io/Fluttron/docs/getting-started/installation)
- [Services Reference](https://maxiee.github.io/Fluttron/docs/api/services)
- [Custom Services](https://maxiee.github.io/Fluttron/docs/getting-started/custom-services)
- [Architecture Overview](https://maxiee.github.io/Fluttron/docs/architecture/overview)
