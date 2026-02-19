---
sidebar_position: 4
---

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
       │                              │ 2. Validate Payload
       │                              │ 3. Parse Request
       │                              │ 4. Route to Service
       │                              │ 5. Execute Method
       │                              │
       │  6. FluttronResponse         │
       │     (JSON)                   │
       │<─────────────────────────────┤
       │                              │
       │  7. Parse Response           │
       │  8. Update UI                │
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

## Host Implementation (Overview)

```dart
class HostBridge {
  HostBridge({required this.registry});
  final ServiceRegistry registry;

  void attach(InAppWebViewController controller) {
    controller.addJavaScriptHandler(
      handlerName: 'fluttron',
      callback: (args) async {
        if (args.isEmpty) {
          return FluttronResponse.err('missing', 'missing_args').toJson();
        }

        final raw = args.first;
        if (raw is! Map) {
          return FluttronResponse.err('invalid', 'invalid_payload').toJson();
        }

        final req = FluttronRequest.fromJson(Map<String, dynamic>.from(raw));
        if (req.id.isEmpty || req.method.isEmpty) {
          return FluttronResponse.err(
            req.id.isEmpty ? 'invalid' : req.id,
            'bad_request',
          ).toJson();
        }

        try {
          final result = await registry.dispatch(req.method, req.params);
          return FluttronResponse.ok(req.id, result).toJson();
        } on FluttronError catch (e) {
          return FluttronResponse.err(req.id, '${e.code}:${e.message}').toJson();
        } catch (e) {
          return FluttronResponse.err(req.id, 'internal_error:$e').toJson();
        }
      },
    );
  }
}
```

## Renderer Implementation (Overview)

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

## Error Semantics

- Expected service errors are returned as `CODE:message`
- Validation failures return normalized protocol errors (`missing_args`, `invalid_payload`, `bad_request`)
- Unexpected runtime failures are wrapped as `internal_error:<message>`

## Relation to Web Packages

Web Package loading (discovery, asset injection, registration generation) is a
build-time pipeline concern. It does not change the bridge protocol itself.

## Next Steps

- [API Services](../api/services.md) - Available service APIs
