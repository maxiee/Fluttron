# Web Views API Reference

This document describes the Web View APIs available in Fluttron for embedding Web content into Flutter Web applications.

## Overview

Fluttron provides a type-driven Web View system that allows you to embed HTML/JS/CSS content into your Flutter Web app. The system follows a "register-first, render-later" pattern for better organization and type safety.

## Core Components

### FluttronWebViewRegistry

Central registry for Web view types and their JavaScript factories.

#### Registration

```dart
// Register a single view
FluttronWebViewRegistry.register(
  FluttronWebViewRegistration(
    type: 'myapp.editor',
    jsFactoryName: 'fluttronCreateMyAppEditorView',
  ),
);

// Register multiple views at once
FluttronWebViewRegistry.registerAll([
  FluttronWebViewRegistration(
    type: 'myapp.editor',
    jsFactoryName: 'fluttronCreateMyAppEditorView',
  ),
  FluttronWebViewRegistration(
    type: 'myapp.chart',
    jsFactoryName: 'fluttronCreateMyAppChartView',
  ),
]);
```

#### Lookup

```dart
// Check if a type is registered
if (FluttronWebViewRegistry.isRegistered('myapp.editor')) {
  // ...
}

// Get registration details
final registration = FluttronWebViewRegistry.lookup('myapp.editor');
print(registration.jsFactoryName);
```

### FluttronWebViewRegistration

Data class representing a view registration.

| Property | Type | Description |
|----------|------|-------------|
| `type` | `String` | Unique type identifier (e.g., `'myapp.editor'`) |
| `jsFactoryName` | `String` | JavaScript factory function name |

### FluttronHtmlView

Widget for rendering embedded Web content.

#### Constructor

```dart
FluttronHtmlView({
  required String type,      // View type (must be registered)
  List<dynamic>? args,       // Optional arguments passed to JS factory
  WidgetBuilder? loadingBuilder,
  Widget Function(BuildContext, Object)? errorBuilder,
})
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `type` | `String` | Registered view type |
| `args` | `List<dynamic>?` | Arguments passed to JavaScript factory |
| `loadingBuilder` | `WidgetBuilder?` | Custom loading widget |
| `errorBuilder` | `Widget Function(BuildContext, Object)?` | Custom error widget |

#### Usage Example

```dart
class EditorPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FluttronHtmlView(
        type: 'myapp.editor',
        args: ['Hello, World!', 'dark'],
        loadingBuilder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
        errorBuilder: (context, error) => Center(
          child: Text('Failed to load: $error'),
        ),
      ),
    );
  }
}
```

#### Three-State UI

`FluttronHtmlView` automatically manages three states:

1. **Loading**: Shown while the view is being created (default: `CircularProgressIndicator`)
2. **Ready**: Shown when the view is successfully rendered
3. **Error**: Shown if view creation fails (default: red error text)

### FluttronEventBridge

Bridge for receiving JavaScript `CustomEvent` in Flutter.

#### Constructor

```dart
final bridge = FluttronEventBridge();
```

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `on(String eventName)` | `Stream<Map<String, dynamic>>` | Listen to a custom event |
| `dispose()` | `void` | Clean up listeners and resources |

#### Usage Example

```dart
class EditorPage extends StatefulWidget {
  @override
  _EditorPageState createState() => _EditorPageState();
}

class _EditorPageState extends State<EditorPage> {
  final _bridge = FluttronEventBridge();
  StreamSubscription? _subscription;
  String _content = '';

  @override
  void initState() {
    super.initState();
    _subscription = _bridge.on('myapp.editor.change').listen((detail) {
      setState(() {
        _content = detail['content'] ?? '';
      });
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _bridge.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: FluttronHtmlView(
            type: 'myapp.editor',
            args: [_content],
          ),
        ),
        Text('Current content: $_content'),
      ],
    );
  }
}
```

## JavaScript Contract

### Factory Function

Create a factory function following this naming convention:

```javascript
// Register in Dart as:
// jsFactoryName: 'fluttronCreateMyAppEditorView'
//
// Expose globally in JS:
// window.fluttronCreateMyAppEditorView = function(viewId, ...args)

window.fluttronCreateMyAppEditorView = function(viewId, initialText, theme) {
  const container = document.createElement('div');
  container.id = viewId;
  container.style.width = '100%';
  container.style.height = '100%';

  // Your Web content initialization
  const editor = createEditor(container, {
    initialText: initialText,
    theme: theme,
    onChange: (content) => {
      // Dispatch event to Flutter
      window.dispatchEvent(new CustomEvent('myapp.editor.change', {
        detail: { viewId, content },
      }));
    }
  });

  return container;
};
```

### Dispatching Events

Use `CustomEvent` to send data back to Flutter (`window.dispatchEvent` is recommended):

```javascript
window.dispatchEvent(new CustomEvent('event.name', {
  detail: {
    viewId: 7,
    key: 'value',
    nested: {
      data: 123
    }
  }
}));
```

## View Type Collision Protection

When using `args`, Fluttron generates a unique `resolvedViewType` using FNV-1a hash:

- Without args: `type` = `myapp.editor`
- With args: `type` = `myapp.editor.__<fnv1a64_hash>`

This ensures that different argument combinations don't collide.

## Registration Conflict Behavior

`FluttronWebViewRegistry.register(...)` is strict for conflicting types:

- Same `type` + same `jsFactoryName`: accepted (idempotent)
- Same `type` + different `jsFactoryName`: throws `StateError`

## Best Practices

### 1. Register at App Startup

```dart
void main() {
  FluttronWebViewRegistry.registerAll([
    // All your view registrations
  ]);

  runFluttronUi(home: const MyApp());
}
```

### 2. Use Descriptive Type Names

```dart
// Good: namespace.component format
'myapp.editor'
'myapp.chart.line'
'myapp.map.location'

// Avoid: generic names
'editor'
'chart'
```

### 3. Clean Up Event Listeners

```dart
@override
void dispose() {
  _subscription?.cancel();
  _bridge.dispose();
  super.dispose();
}
```

### 4. Handle Loading and Error States

```dart
FluttronHtmlView(
  type: 'myapp.editor',
  loadingBuilder: (context) => const SkeletonLoader(),
  errorBuilder: (context, error) => ErrorCard(message: error.toString()),
)
```

## Next Steps

- [Renderer Layer](../architecture/renderer-layer.md) - Renderer architecture
- [Services API](./services.md) - Host services reference
