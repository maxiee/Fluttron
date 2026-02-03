# Architecture Overview

Fluttron adopts a dual-layer architecture similar to Electron or mini-program containers, combining the stability of native host applications with the flexibility of web rendering.

## Core Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                   Fluttron Host                          │
│              (Flutter Desktop Application)                  │
│                                                           │
│  ┌─────────────────────────────────────────────────────┐   │
│  │              ServiceRegistry                      │   │
│  │  • SystemService (platform info)                │   │
│  │  • StorageService (key-value storage)           │   │
│  │  • FileService (file system access)             │   │
│  │  • DatabaseService (SQLite)                     │   │
│  └───────────────────┬─────────────────────────────┘   │
│                      │                                   │
│  ┌───────────────────▼─────────────────────────────┐   │
│  │            Host Bridge (Dart)                   │   │
│  │  • JavaScriptHandler: 'fluttron'              │   │
│  │  • Request/Response routing                   │   │
│  └───────────────────┬─────────────────────────────┘   │
└──────────────────────┼──────────────────────────────────┘
                       │ IPC Channel
                       │ (JSON over JS Handler)
                       │
┌──────────────────────▼──────────────────────────────────┐
│                 WebView Container                        │
│                                                       │
│  ┌─────────────────────────────────────────────────┐    │
│  │            Fluttron UI                        │    │
│  │         (Flutter Web Application)               │    │
│  │                                                  │    │
│  │  ┌─────────────────────────────────────────┐    │    │
│  │  │       Renderer Bridge (Dart JS interop) │    │    │
│  │  │  • callHandler('fluttron', request)   │    │    │
│  │  │  • Promise <-> Future conversion        │    │    │
│  │  └───────────────┬───────────────────────┘    │    │
│  │                  │                              │    │
│  │  ┌───────────────▼───────────────────────┐    │    │
│  │  │      FluttronClient (High-level API)  │    │    │
│  │  │  • getPlatform()                    │    │    │
│  │  │  • kvSet(key, value)                │    │    │
│  │  │  • kvGet(key)                      │    │    │
│  │  └───────────────┬───────────────────────┘    │    │
│  │                  │                              │    │
│  │  ┌──────────────▼────────────────────────┐    │    │
│  │  │   Business Logic & UI Components      │    │    │
│  │  └───────────────────────────────────────┘    │    │
│  └─────────────────────────────────────────────────┘    │
└───────────────────────────────────────────────────────────┘
```

## Layer Responsibilities

### Host Layer (Native Dart)

The Host layer is built with Flutter Desktop and is responsible for:

- **Window Management**: Creating, resizing, and managing application windows
- **Lifecycle Management**: Application startup, shutdown, and background tasks
- **Service Exposure**: Providing native capabilities through ServiceRegistry
- **Security**: Sandbox isolation between UI and system resources
- **Resource Management**: Memory, CPU, and system resource allocation

### Runtime Layer (WebView Runtime)

The Runtime layer is the execution environment within WebView:

- **JavaScript Injection**: Loading preload scripts and initializing JS APIs
- **Message Routing**: IPC mechanism between Host and Renderer
- **Module Loading Protocol**: Loading and managing Web modules/apps
- **Security Enforcements**: Restricting access to certain JavaScript APIs

### Renderer Layer (Flutter Web)

The Renderer layer is a standard Flutter Web application:

- **UI Rendering**: All user interface and visual components
- **Business Logic**: Application code, state management, and data flow
- **Web Ecosystem Integration**: Seamless access to Web APIs and libraries
- **Host Communication**: Invoking services via FluttronClient

## Design Principles

### Full-Stack Dart

Both Host and Renderer use Dart, eliminating language switching:
- Host services written in Dart
- UI components written in Dart (Flutter Web)
- No Node.js vs JavaScript context switching

### Service-Oriented Architecture

Host exposes capabilities through registered services:
- Services are registered at startup
- Each service has a namespace and methods
- Easy to extend with custom services

### Web Ecosystem

Renderer is essentially Web, enjoying:
- Flutter's fast rendering
- Access to entire Web ecosystem
- Seamless integration with Web APIs

### Sandbox Isolation

Clear separation between system and UI:
- Host has full system access
- Renderer runs in controlled WebView
- Secure by design

## Communication Protocol

All communication between Host and Renderer uses JSON-based protocol defined in `fluttron_shared`:

**Request:**
```json
{
  "id": "unique-request-id",
  "method": "system.getPlatform",
  "params": {}
}
```

**Response:**
```json
{
  "id": "unique-request-id",
  "ok": true,
  "result": {
    "platform": "macos"
  },
  "error": null
}
```

## Cross-Platform Support

Fluttron supports multiple platforms:

- **Desktop**: macOS, Linux, Windows (using Flutter Desktop)
- **Mobile**: Android, iOS (using Flutter mobile + WebView)
- **Initial Focus**: macOS development

## Next Steps

- [Host Layer Details](./host-layer.md) - Deep dive into Host architecture
- [Renderer Layer Details](./renderer-layer.md) - Learn about Renderer architecture
- [Bridge Communication](./bridge-communication.md) - IPC mechanism details
