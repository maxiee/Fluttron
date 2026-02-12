# Host Template

This folder represents the Flutter desktop host template.

Minimum expectations:

- `lib/main.dart` calls `runFluttronHost(...)` from `fluttron_host`.
- `pubspec.yaml` depends on `fluttron_host` and `fluttron_shared`.
- `assets/www/` is the Web asset directory loaded by the host.

## Custom Services

Fluttron supports extending the Host with custom services that can be invoked from the UI layer.

### Quick Start

1. See `lib/greeting_service.dart` for a complete example (currently commented out)
2. Uncomment the service code and import in `main.dart`
3. Register the service in a custom `ServiceRegistry`
4. Call from UI: `FluttronClient.invoke('greeting.greet', {})`

### Service Structure

```dart
class GreetingService extends FluttronService {
  @override
  String get namespace => 'greeting';

  @override
  Future<dynamic> handle(String method, Map<String, dynamic> params) async {
    switch (method) {
      case 'greet':
        return {'message': 'Hello from custom service!'};
      default:
        throw FluttronError('METHOD_NOT_FOUND', 'greeting.$method not implemented');
    }
  }
}
```

### Registration

```dart
void main() {
  final registry = ServiceRegistry()
    ..register(SystemService())
    ..register(StorageService())
    ..register(GreetingService()); // Your custom service

  runFluttronHost(registry: registry);
}
```
