# fluttron_host

Host runtime package for Fluttron desktop/mobile containers.

It provides:

- WebView container bootstrap (`runFluttronHost`)
- Host ↔ UI bridge (`ServiceRegistry`, `FluttronService`)
- Built-in native services

## Built-in Services

| Namespace | Methods | Purpose |
|---|---|---|
| `system.*` | `getPlatform` | Platform info |
| `storage.*` | `kvSet`, `kvGet` | Persistent key-value storage |
| `file.*` | `readFile`, `writeFile`, `listDirectory`, `stat`, `createFile`, `delete`, `rename`, `exists` | File system operations |
| `dialog.*` | `openFile`, `openFiles`, `openDirectory`, `saveFile` | Native file/directory dialogs |
| `clipboard.*` | `getText`, `setText`, `hasText` | System clipboard access |

## Service Extension Pattern

Add custom host capabilities by implementing `FluttronService` and registering
the service in `ServiceRegistry`.

```dart
class GreetingService extends FluttronService {
  @override
  String get namespace => 'greeting';

  @override
  Future<dynamic> handle(String method, Map<String, dynamic> params) async {
    switch (method) {
      case 'hello':
        return <String, dynamic>{'message': 'hello'};
      default:
        throw FluttronError('METHOD_NOT_FOUND', 'greeting.$method not implemented');
    }
  }
}
```

```dart
void main() {
  final registry = ServiceRegistry()
    ..register(SystemService())
    ..register(StorageService())
    ..register(GreetingService());

  runFluttronHost(registry: registry);
}
```

From UI:

```dart
final result = await FluttronClient().invoke('greeting.hello', {});
```
