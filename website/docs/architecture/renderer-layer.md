---
sidebar_position: 3
---

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
│  │ FluttronClient + Service Clients          │  │
│  │ • invoke(method, params)                  │  │
│  │ • File/Dialog/Clipboard/System/Storage    │  │
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
final client = FluttronClient();

// Generic invoke
final result = await client.invoke('greeting.greet', {});

// Typed built-in clients
final system = SystemServiceClient(client);
final storage = StorageServiceClient(client);
final platform = await system.getPlatform();
await storage.set('key', 'value');
final value = await storage.get('key');
```

`FluttronClient.getPlatform()/kvSet()/kvGet()` are deprecated and retained only for backward compatibility.

### FluttronWebViewRegistry

Register Web view factories before rendering. This follows the "register-first, render-later" pattern:

```dart
void main() {
  // Register views at startup
  FluttronWebViewRegistry.registerAll([
    FluttronWebViewRegistration(
      type: 'myapp.editor',
      jsFactoryName: 'fluttronCreateMyAppEditorView',
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
  args: ['Hello, World!'],
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
// jsFactoryName in Dart uses the global function name only:
// 'fluttronCreateMyAppEditorView'
//
// JavaScript exposes it on `window`:
// window.fluttronCreateMyAppEditorView(viewId, ...args)

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
