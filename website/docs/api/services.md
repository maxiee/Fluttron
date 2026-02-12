# Services API Reference

This document describes the services currently available in Fluttron.

## Built-in Services

| Service | Namespace | Status | Description |
|---------|-----------|--------|-------------|
| SystemService | `system` | ✅ Stable | Platform information |
| StorageService | `storage` | ✅ Stable | In-memory key-value storage |

## SystemService

### getPlatform()

**Request:**
```json
{
  "id": "...",
  "method": "system.getPlatform",
  "params": {}
}
```

**Response:**
```json
{
  "id": "...",
  "ok": true,
  "result": {
    "platform": "macos"
  },
  "error": null
}
```

**Dart Usage:**
```dart
final platform = await FluttronClient.getPlatform();
print('Running on: $platform');
```

---

## StorageService

### kvSet(key, value)

**Request:**
```json
{
  "id": "...",
  "method": "storage.kvSet",
  "params": {
    "key": "user.name",
    "value": "Alice"
  }
}
```

**Response:**
```json
{
  "id": "...",
  "ok": true,
  "result": { "ok": true },
  "error": null
}
```

**Dart Usage:**
```dart
await FluttronClient.kvSet('user.name', 'Alice');
```

---

### kvGet(key)

**Request:**
```json
{
  "id": "...",
  "method": "storage.kvGet",
  "params": {
    "key": "user.name"
  }
}
```

**Response (value exists):**
```json
{
  "id": "...",
  "ok": true,
  "result": { "value": "Alice" },
  "error": null
}
```

**Response (missing key):**
```json
{
  "id": "...",
  "ok": true,
  "result": { "value": null },
  "error": null
}
```

**Dart Usage:**
```dart
final name = await FluttronClient.kvGet('user.name');
print('User: $name');
```

---

## Custom Services

Fluttron allows you to create custom services to extend Host capabilities.

### Creating a Custom Service

1. **Create the service class:**

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
        final name = params['name'] ?? 'World';
        return <String, dynamic>{
          'message': 'Hello, $name!',
        };
      case 'goodbye':
        return <String, dynamic>{
          'message': 'Goodbye!',
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

2. **Register the service in `main.dart`:**

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

3. **Call from UI:**

```dart
// Using invoke
final result = await FluttronClient.invoke('greeting.greet', {'name': 'Alice'});
print(result['message']); // "Hello, Alice!"

// Error handling
try {
  await FluttronClient.invoke('greeting.unknown', {});
} catch (e) {
  print('Error: $e'); // "METHOD_NOT_FOUND: greeting.unknown not implemented"
}
```

### Service Interface

All services must implement:

```dart
abstract class FluttronService {
  /// Unique namespace (e.g., "system", "storage", "myapp.custom")
  String get namespace;

  /// Handle method calls
  /// - method: the part after namespace (e.g., "getPlatform")
  /// - params: parameters from the UI
  /// Returns a Map or List that can be JSON-serialized
  Future<dynamic> handle(String method, Map<String, dynamic> params);
}
```

### Error Handling

Throw `FluttronError` for expected failures:

```dart
throw FluttronError('INVALID_PARAM', 'Parameter "key" is required');
```

On failure, the response includes `ok: false`:

```json
{
  "id": "...",
  "ok": false,
  "result": null,
  "error": "METHOD_NOT_FOUND: system.foo not implemented"
}
```

Errors are strings formatted as `CODE:message` for expected failures, or `internal_error:...` for unexpected exceptions.

### Template Example

When you create a new Fluttron project with `fluttron create`, the Host template includes a commented-out `greeting_service.dart` example. See:

- `host/lib/greeting_service.dart` - Example service skeleton
- `host/lib/main.dart` - Registration instructions

## Generic invoke()

For any service (built-in or custom), use the generic `invoke` method:

```dart
final result = await FluttronClient.invoke('namespace.method', {
  'param1': 'value1',
  'param2': 42,
});
```

## Next Steps

- [Host Layer](../architecture/host-layer.md) - Host architecture and service system
- [Web Views API](./web-views.md) - Embedding Web content
