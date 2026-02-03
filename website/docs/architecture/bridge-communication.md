# Bridge Communication

Bridge communication is the IPC mechanism between Host and Renderer using JavaScript Handlers.

## Overview

Fluttron uses `flutter_inappwebview` library's JavaScript Handler mechanism for IPC:

```
Renderer (Flutter Web)          Host (Flutter Desktop)
       │                              │
       │  1. FluttronRequest        │
       │     (JSON)                 │
       ├─────────────────────────────>│
       │     callHandler('fluttron') │
       │                              │
       │                              │ 2. Parse Request
       │                              │ 3. Route to Service
       │                              │ 4. Execute Method
       │                              │
       │  5. FluttronResponse       │
       │     (JSON)                 │
       │<─────────────────────────────┤
       │                              │
       │  6. Parse Response          │
       │  7. Update UI              │
```

## Protocol Definition

All communication uses JSON-based protocol defined in `fluttron_shared`:

### FluttronRequest

```dart
class FluttronRequest {
  final String id;
  final String method;
  final Map<String, dynamic> params;

  FluttronRequest({
    required this.id,
    required this.method,
    required this.params,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'method': method,
      'params': params,
    };
  }

  factory FluttronRequest.fromJson(Map<String, dynamic> json) {
    return FluttronRequest(
      id: json['id'] as String,
      method: json['method'] as String,
      params: json['params'] as Map<String, dynamic>,
    );
  }
}
```

**Fields:**
- `id`: Unique request identifier (UUID)
- `method`: Method name in `namespace.method` format
- `params`: Method parameters as key-value pairs

**Example:**
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "method": "storage.kvSet",
  "params": {
    "key": "user.name",
    "value": "Alice"
  }
}
```

### FluttronResponse

```dart
class FluttronResponse {
  final String id;
  final bool ok;
  final dynamic result;
  final Map<String, dynamic>? error;

  FluttronResponse({
    required this.id,
    required this.ok,
    this.result,
    this.error,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ok': ok,
      'result': result,
      'error': error,
    };
  }

  factory FluttronResponse.fromJson(Map<String, dynamic> json) {
    return FluttronResponse(
      id: json['id'] as String,
      ok: json['ok'] as bool,
      result: json['result'],
      error: json['error'] as Map<String, dynamic>?,
    );
  }
}
```

**Fields:**
- `id`: Matches request ID
- `ok`: Success/failure flag
- `result`: Return value on success
- `error`: Error details on failure

**Success Response:**
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "ok": true,
  "result": {
    "platform": "macos"
  },
  "error": null
}
```

**Error Response:**
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "ok": false,
  "result": null,
  "error": {
    "code": "UNKNOWN_METHOD",
    "message": "Method 'unknown.method' not found"
  }
}
```

## Host Implementation

Host registers JavaScript handler and processes requests:

```dart
class HostBridge {
  final ServiceRegistry serviceRegistry;

  HostBridge({required this.serviceRegistry});

  Future<void> setup(InAppWebViewController controller) async {
    await controller.addJavaScriptHandler(
      handlerName: 'fluttron',
      callback: (args) async {
        try {
          final request = FluttronRequest.fromJson(args[0] as Map<String, dynamic>);
          final result = await serviceRegistry.invoke(
            request.method,
            request.params,
          );

          return FluttronResponse(
            id: request.id,
            ok: true,
            result: result,
          ).toJson();
        } catch (e, stack) {
          return FluttronResponse(
            id: request.id,
            ok: false,
            error: {
              'code': e.runtimeType.toString(),
              'message': e.toString(),
            },
          ).toJson();
        }
      },
    );
  }
}
```

**Key Steps:**
1. Register JavaScript handler named 'fluttron'
2. Parse incoming JSON as `FluttronRequest`
3. Invoke method via `ServiceRegistry`
4. Return success or error response as JSON

## Renderer Implementation

Renderer uses Dart JS interop to call host handler:

```dart
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

class RendererBridge {
  Future<FluttronResponse> invoke(
    String method,
    Map<String, dynamic> params,
  ) async {
    final request = FluttronRequest(
      id: const Uuid().v4(),
      method: method,
      params: params,
    );

    final webView = window.flutter_inappwebview;
    if (webView == null) {
      throw FluttronError.notRunningInHost();
    }

    final resultJS = await webView!.callHandler(
      'fluttron',
      request.toJson().jsify() as JSAny,
    );

    return FluttronResponse.fromJson(
      (resultJS as JSObject).toDart as Map<String, dynamic>,
    );
  }
}
```

**Key Steps:**
1. Create `FluttronRequest` with unique ID
2. Access `window.flutter_inappwebview.callHandler`
3. Convert Dart Map to JS Object using `.jsify()`
4. Call handler with 'fluttron' and request
5. Await Promise result
6. Convert JS Object back to Dart Map
7. Parse as `FluttronResponse`

## High-Level API

`FluttronClient` provides type-safe methods:

```dart
class FluttronClient {
  static Future<String> getPlatform() async {
    final bridge = RendererBridge();
    final response = await bridge.invoke('system.getPlatform', {});
    if (!response.ok) {
      throw FluttronError.fromResponse(response);
    }
    return response.result['platform'] as String;
  }

  static Future<void> kvSet(String key, String value) async {
    final bridge = RendererBridge();
    final response = await bridge.invoke('storage.kvSet', {
      'key': key,
      'value': value,
    });
    if (!response.ok) {
      throw FluttronError.fromResponse(response);
    }
  }
}
```

## Error Handling

Comprehensive error handling at each layer:

### Host Side
```dart
try {
  final result = await service.invoke(method, params);
  return successResponse(request.id, result);
} on FluttronException catch (e) {
  return errorResponse(request.id, e.code, e.message);
} catch (e) {
  return errorResponse(request.id, 'INTERNAL_ERROR', e.toString());
}
```

### Renderer Side
```dart
final response = await bridge.invoke(method, params);

if (!response.ok) {
  final error = FluttronError.fromResponse(response);
  throw error;
}

return response.result;
```

## Performance Optimizations

- **Request Batching**: Group multiple requests into single call
- **Connection Pooling**: Reuse WebSocket connections (future)
- **Response Caching**: Cache frequently accessed responses
- **Debouncing**: Debounce rapid requests

## Security Considerations

- **Input Validation**: Validate all params before execution
- **Permission Checks**: Verify service permissions
- **Rate Limiting**: Prevent request flooding
- **Sandbox**: Renderer runs in isolated WebView

## Next Steps

- [API Services](../api/services.md) - Available service APIs

