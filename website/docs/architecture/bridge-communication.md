# Bridge Communication

Bridge communication is the IPC mechanism between Host and Renderer using `flutter_inappwebview` JavaScript handlers.

## Overview

```
Renderer (Flutter Web)          Host (Flutter Desktop)
       │                              │
       │  1. FluttronRequest          │
       │     (JSON)                   │
       ├─────────────────────────────>│
       │     callHandler('fluttron')  │
       │                              │
       │                              │ 2. Parse Request
       │                              │ 3. Route to Service
       │                              │ 4. Execute Method
       │                              │
       │  5. FluttronResponse         │
       │     (JSON)                   │
       │<─────────────────────────────┤
       │                              │
       │  6. Parse Response           │
       │  7. Update UI                │
```

## Protocol

All messages use the shared protocol in `fluttron_shared`.

### FluttronRequest

```json
{
  "id": "req-123",
  "method": "storage.kvSet",
  "params": {
    "key": "hello",
    "value": "world"
  }
}
```

### FluttronResponse

Success:
```json
{
  "id": "req-123",
  "ok": true,
  "result": { "ok": true },
  "error": null
}
```

Error:
```json
{
  "id": "req-123",
  "ok": false,
  "result": null,
  "error": "METHOD_NOT_FOUND: storage.unknown not implemented"
}
```

Errors use `CODE:message` for expected failures, or `internal_error:...` when
an unexpected exception occurs.

## Host Implementation (概览)

```dart
class HostBridge {
  HostBridge({required this.registry});
  final ServiceRegistry registry;

  void attach(InAppWebViewController controller) {
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
  }
}
```

## Renderer Implementation (概览)

```dart
final result = await window.flutter_inappwebview.callHandler(
  'fluttron',
  request.toJson().jsify(),
);
```

## High-Level API

```dart
final client = FluttronClient();
final platform = await client.getPlatform();
await client.kvSet('hello', 'world');
final value = await client.kvGet('hello');
```

## Next Steps

- [API Services](../api/services.md) - Available service APIs
