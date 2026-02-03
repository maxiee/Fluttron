# Renderer Layer

The Renderer layer is a Flutter Web application running inside the Host WebView.

## Architecture

```
┌───────────────────────────────────────────────┐
│            Fluttron UI (Web App)              │
│                                               │
│  ┌─────────────────────────────────────────┐  │
│  │ main.dart                                 │  │
│  │ • runFluttronUi()                         │  │
│  └───────────────────┬──────────────────────┘  │
│                      │                         │
│  ┌───────────────────▼──────────────────────┐  │
│  │ UI Pages & Components                     │  │
│  │ • Demo UI                                 │  │
│  └───────────────────┬──────────────────────┘  │
│                      │                         │
│  ┌───────────────────▼──────────────────────┐  │
│  │ FluttronClient                            │  │
│  │ • getPlatform()                           │  │
│  │ • kvSet() / kvGet()                       │  │
│  └───────────────────┬──────────────────────┘  │
│                      │                         │
│  ┌───────────────────▼──────────────────────┐  │
│  │ Renderer Bridge (dart:js_interop)         │  │
│  │ • callHandler('fluttron', request)        │  │
│  └─────────────────────────────────────────┘  │
└───────────────────────────────────────────────┘
```

## Key Components

### main.dart

```dart
void main() {
  runFluttronUi();
}
```

### FluttronClient

```dart
final client = FluttronClient();
final platform = await client.getPlatform();
await client.kvSet('hello', 'world');
final value = await client.kvGet('hello');
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
