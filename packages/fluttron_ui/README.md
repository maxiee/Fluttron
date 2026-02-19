# fluttron_ui

Renderer-side package for Fluttron applications. Runs as Flutter Web inside the host's WebView.

## Overview

`fluttron_ui` provides the UI layer of Fluttron's dual-layer architecture:

```
┌──────────────────────────────┐
│      Fluttron Host (native)  │
│  ┌────────────────────────┐  │
│  │       WebView          │  │
│  │  ┌──────────────────┐  │  │
│  │  │  fluttron_ui     │  │  │
│  │  │  (Flutter Web)   │  │  │
│  │  └──────────────────┘  │  │
│  └────────────────────────┘  │
└──────────────────────────────┘
```

## Quick Start

```dart
import 'package:fluttron_ui/fluttron_ui.dart';

void main() {
  runFluttronUi(
    title: 'My App',
    home: const MyHomePage(),
  );
}
```

## Service Clients

Type-safe wrappers for all built-in host services:

```dart
final file = FileServiceClient();
final content = await file.readFile('/path/to/file.txt');

final dialog = DialogServiceClient();
final path = await dialog.openFile(allowedExtensions: ['.md', '.txt']);

final window = WindowServiceClient();
await window.setTitle('My App - document.md');
await window.setSize(width: 1200, height: 800);

final storage = StorageServiceClient();
await storage.kvSet('theme', 'dark');
final theme = await storage.kvGet('theme');

final logging = LoggingServiceClient();
await logging.info('File opened', {'path': '/tmp/note.md'});

final clipboard = ClipboardServiceClient();
await clipboard.setText('Hello from Fluttron!');

final system = SystemServiceClient();
final platform = await system.getPlatform();
```

## HTML View Integration

Embed JS-rendered components (web packages) in Flutter:

```dart
// Register a web package view type
FluttronWebViewRegistry.register(
  FluttronWebViewRegistration(
    type: 'my-chart',
    jsFactoryName: 'createMyChart',
  ),
);

// Use in your widget tree
FluttronHtmlView(
  type: 'my-chart',
  args: [{'data': [1, 2, 3]}],
  loadingBuilder: (_) => const CircularProgressIndicator(),
)
```

## Event Bridge

Listen to events pushed from the host or JS layer:

```dart
final bridge = FluttronEventBridge();

bridge.on('host-event').listen((data) {
  print('Received: ${data['message']}');
});

bridge.dispose(); // Clean up when done
```

## Documentation

Full documentation: <https://maxiee.github.io/Fluttron/>

- [Getting Started](https://maxiee.github.io/Fluttron/docs/getting-started/installation)
- [Services Reference](https://maxiee.github.io/Fluttron/docs/api/services)
- [Web Packages](https://maxiee.github.io/Fluttron/docs/architecture/web-packages)
- [Architecture Overview](https://maxiee.github.io/Fluttron/docs/architecture/overview)
