# Renderer Layer

The Renderer layer is a Flutter Web application running in WebView, responsible for UI rendering and business logic.

## Architecture

```
┌───────────────────────────────────────────────┐
│            Fluttron UI (Web App)            │
│                                               │
│  ┌─────────────────────────────────────────┐    │
│  │  main.dart                           │    │
│  │  • Flutter Web initialization         │    │
│  │  • FluttronClient setup              │    │
│  │  • MaterialApp config                │    │
│  └───────────────────┬───────────────────┘    │
│                      │                          │
│  ┌───────────────────▼───────────────────┐    │
│  │  UI Pages & Components              │    │
│  │  • DemoPage (test interface)       │    │
│  │  • Widgets (Buttons, Lists, etc.)    │    │
│  │  • State management                │    │
│  └───────────────────┬───────────────────┘    │
│                      │                          │
│  ┌───────────────────▼───────────────────┐    │
│  │  Business Logic                    │    │
│  │  • User interactions               │    │
│  │  • Data processing                │    │
│  │  • State updates                  │    │
│  └───────────────────┬───────────────────┘    │
│                      │                          │
│  ┌───────────────────▼───────────────────┐    │
│  │  FluttronClient                    │    │
│  │  • High-level API                  │    │
│  │  • getPlatform()                   │    │
│  │  • kvSet(key, value)               │    │
│  │  • kvGet(key)                     │    │
│  └───────────────────┬───────────────────┘    │
│                      │                          │
│  ┌───────────────────▼───────────────────┐    │
│  │  Renderer Bridge                   │    │
│  │  • JS Interop (dart:js_interop)   │    │
│  │  • callHandler('fluttron', ...)    │    │
│  │  • Promise <-> Future conversion    │    │
│  └───────────────────┬───────────────────┘    │
└──────────────────────┼───────────────────────────┘
                       │
                       │ JavaScript Handler
                       │
                 Host Bridge
```

## Key Components

### main.dart

Entry point for Flutter Web application.

**Responsibilities:**
- Initialize Flutter Web app
- Create FluttronClient instance
- Configure MaterialApp
- Define routes and pages

**Example:**
```dart
void main() async {
  await FluttronClient.initialize();
  runApp(FluttronApp());
}

class FluttronApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fluttron',
      theme: ThemeData(...),
      home: DemoPage(),
    );
  }
}
```

### FluttronClient

High-level API for invoking Host services.

**Responsibilities:**
- Simplify service invocation
- Type-safe method calls
- Error handling and conversion
- Request/response management

**Public API:**
```dart
class FluttronClient {
  static Future<void> initialize();
  static Future<String> getPlatform();
  static Future<void> kvSet(String key, String value);
  static Future<String?> kvGet(String key);
}
```

**Example Usage:**
```dart
final platform = await FluttronClient.getPlatform();
print('Running on: $platform');

await FluttronClient.kvSet('user.name', 'Alice');
final name = await FluttronClient.kvGet('user.name');
print('User: $name');
```

### Renderer Bridge

Low-level bridge communication using Dart JS interop.

**Responsibilities:**
- Call Host's JavaScript handler
- Convert Future to Promise
- Parse JSON responses
- Handle errors

**Implementation:**
```dart
class RendererBridge {
  static Future<FluttronResponse> invoke(
    String method,
    Map<String, dynamic> params,
  ) async {
    final request = FluttronRequest(
      id: const Uuid().v4(),
      method: method,
      params: params,
    );

    final handler = window.flutter_inappwebview;
    if (handler == null) {
      throw FluttronError.notRunningInHost();
    }

    final result = await handler.callHandler('fluttron', request.toJson());

    return FluttronResponse.fromJson(result as JSObject);
  }
}
```

### UI Components

Standard Flutter widgets and state management.

**Features:**
- Material Design widgets
- Custom business components
- State management (Provider/Riverpod/Bloc)
- Responsive layouts

## Web Ecosystem Integration

Renderer being pure Flutter Web allows:

- **Web APIs**: Access to localStorage, IndexedDB, Web Workers
- **Web Libraries**: Use any npm/JS library via JS interop
- **Web Standards**: Standards-compliant rendering
- **DevTools**: Full Chrome DevTools support

**Example - Using localStorage:**
```dart
import 'dart:html' as html;

final storage = html.window.localStorage;
storage['key'] = 'value';
print(storage['key']);
```

## Build Process

Renderer is compiled to static assets and loaded by Host.

**Build Script (`build.sh`):**
```bash
flutter build web --release
cp -r build/* ../fluttron_host/assets/www/
```

**Development (`run.sh`):**
```bash
flutter run -d chrome
```

## Communication Flow

1. UI component calls `FluttronClient` method
2. Client creates `FluttronRequest` (JSON)
3. `RendererBridge` calls `window.flutter_inappwebview.callHandler('fluttron', request)`
4. Host receives request via JavaScript Handler
5. Host processes and returns `FluttronResponse` (JSON)
6. Bridge converts JS Object to Dart Map
7. Client parses response and returns to UI
8. UI updates with result

## Performance Considerations

- **Lazy Loading**: Load services only when needed
- **Caching**: Cache frequently accessed data
- **Debouncing**: Debounce rapid service calls
- **Optimized Rendering**: Use Flutter's optimized widgets

## Next Steps

- [Host Layer](./host-layer.md) - Learn about Host architecture
- [Bridge Communication](./bridge-communication.md) - IPC mechanism details
- [API Reference](../api/services.md) - Client API documentation
