# Renderer Layer

The Renderer layer is a Flutter Web application running inside the Host WebView.

## Architecture

```
┌───────────────────────────────────────────────┐
│            Fluttron UI (Web App)              │
│                                               │
│  ┌─────────────────────────────────────────┐  │
│  │ main.dart                                 │  │
│  │ • runFluttronUi(title, home)              │  │
│  └───────────────────┬──────────────────────┘  │
│                      │                         │
│  ┌───────────────────▼──────────────────────┐  │
│  │ UI Pages & Components                     │  │
│  │ • FluttronHtmlView (embed Web content)    │  │
│  │ • FluttronEventBridge (JS→Dart events)    │  │
│  └───────────────────┬──────────────────────┘  │
│                      │                         │
│  ┌───────────────────▼──────────────────────┐  │
│  │ FluttronWebViewRegistry                   │  │
│  │ • Register view types & factories         │  │
│  │ • Lookup by type at render time           │  │
│  └───────────────────┬──────────────────────┘  │
│                      │                         │
│  ┌───────────────────▼──────────────────────┐  │
│  │ FluttronClient                            │  │
│  │ • invoke(method, params)                  │  │
│  │ • getPlatform() / kvSet() / kvGet()       │  │
│  └───────────────────┬──────────────────────┘  │
│                      │                         │
│  ┌───────────────────▼──────────────────────┐  │
│  │ Renderer Bridge (dart:js_interop)         │  │
│  │ • callHandler('fluttron', request)        │  │
│  └─────────────────────────────────────────┘  │
└───────────────────────────────────────────────┘
```

## Key Components

### runFluttronUi()

Configurable entry point for the UI app:

```dart
void main() {
  runFluttronUi(
    title: 'My App',
    home: const MyHomePage(),
    debugBanner: false,
  );
}
```

### FluttronClient

Call Host services from the UI:

```dart
// Generic invoke
final result = await FluttronClient.invoke('greeting.greet', {});

// Convenience methods
final platform = await FluttronClient.getPlatform();
await FluttronClient.kvSet('key', 'value');
final value = await FluttronClient.kvGet('key');
```

### FluttronWebViewRegistry

Register Web view factories before rendering. This follows the "register-first, render-later" pattern:

```dart
void main() {
  // Register views at startup
  FluttronWebViewRegistry.registerAll([
    FluttronWebViewRegistration(
      type: 'myapp.editor',
      jsFactoryName: 'window.fluttronCreateMyAppEditorView',
    ),
  ]);

  runFluttronUi(home: const MyApp());
}
```

### FluttronHtmlView

Embed Web content (HTML/JS/CSS) into your Flutter Web app:

```dart
FluttronHtmlView(
  type: 'myapp.editor',
  args: {'initialText': 'Hello, World!'},
  loadingBuilder: (context) => const CircularProgressIndicator(),
  errorBuilder: (context, error) => Text('Error: $error'),
)
```

**Key Features:**
- Three-state UI: loading → ready → error
- Customizable loading/error builders
- Type-driven rendering (uses `FluttronWebViewRegistry`)
- Args canonicalization with FNV-1a hash for view type collision protection

### FluttronEventBridge

Receive custom events from JavaScript in your Flutter Web app:

```dart
final bridge = FluttronEventBridge();
final subscription = bridge.on('myapp.editor.change').listen((detail) {
  print('Content changed: ${detail['content']}');
});

// Don't forget to dispose
@override
void dispose() {
  subscription.cancel();
  bridge.dispose();
  super.dispose();
}
```

## Web View Contract

When creating a JavaScript factory for `FluttronHtmlView`, follow this contract:

```javascript
// Factory function naming convention:
// window.fluttronCreate<YourViewType>View(viewId, ...args)

window.fluttronCreateMyAppEditorView = function(viewId, initialText) {
  const container = document.createElement('div');
  container.id = viewId;
  // ... setup your Web content

  // Dispatch events back to Flutter
  container.dispatchEvent(new CustomEvent('myapp.editor.change', {
    detail: { content: 'updated content' },
    bubbles: true,
  }));

  return container;
};
```

## Build and Run

The CLI handles building and copying UI assets:

```bash
fluttron build -p ./hello_fluttron
fluttron run -p ./hello_fluttron
```

## Next Steps

- [Host Layer](./host-layer.md) - Host architecture
- [Bridge Communication](./bridge-communication.md) - IPC details
- [Web Views API](../api/web-views.md) - Web view API reference
