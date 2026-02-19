---
sidebar_position: 1
---

# Architecture Overview

Fluttron uses a dual-layer model: a native Host (Flutter Desktop) and a Renderer (Flutter Web) running inside a WebView.

## Core Architecture

```
┌────────────────────────────────────────────────────┐
│                 Fluttron Host                      │
│             (Flutter Desktop App)                  │
│                                                    │
│  ┌──────────────────────────────────────────────┐  │
│  │ ServiceRegistry                              │  │
│  │  • SystemService (platform info)             │  │
│  │  • StorageService (in-memory KV)             │  │
│  └───────────────────┬──────────────────────────┘  │
│                      │                             │
│  ┌───────────────────▼──────────────────────────┐  │
│  │ Host Bridge (Dart)                           │  │
│  │  • JavaScriptHandler: 'fluttron'             │  │
│  │  • Request/response routing                  │  │
│  └───────────────────┬──────────────────────────┘  │
└──────────────────────┼─────────────────────────────┘
                       │ IPC (JSON over JS Handler)
                       │
┌──────────────────────▼─────────────────────────────┐
│                 Renderer (Flutter Web)             │
│                                                    │
│  ┌──────────────────────────────────────────────┐  │
│  │ Renderer Bridge (dart:js_interop)            │  │
│  │  • callHandler('fluttron', request)          │  │
│  │  • Promise <-> Future                         │  │
│  └───────────────────┬──────────────────────────┘  │
│                      │                             │
│  ┌───────────────────▼──────────────────────────┐  │
│  │ FluttronClient                                │  │
│  │  • getPlatform()                              │  │
│  │  • kvSet() / kvGet()                          │  │
│  └──────────────────────────────────────────────┘  │
└────────────────────────────────────────────────────┘
```

## Layer Responsibilities

### Host Layer (Flutter Desktop)

- Creates the native window and WebView
- Loads Web assets from `assets/www`
- Exposes services through `ServiceRegistry`
- Handles IPC requests from the Renderer

### Renderer Layer (Flutter Web)

- Renders UI and runs business logic
- Calls host services through `FluttronClient`
- Uses Dart JS interop to access the bridge
- Loads local `ext/main.js` and injected package assets from `ext/packages/<pkg>/...`

## Web Package Build Flow

When app dependencies include web packages, `fluttron build` adds these stages:

1. Discover packages from `ui/.dart_tool/package_config.json`
2. Filter by `fluttron_web_package: true` and valid `fluttron_web_package.json`
3. Generate `ui/lib/generated/web_package_registrations.dart`
4. Build Flutter Web
5. Copy package assets to `ui/build/web/ext/packages/<pkg>/...`
6. Inject JS/CSS references into `ui/build/web/index.html`
7. Validate and sync to `host/assets/www`

## Communication Protocol

The protocol is defined in `fluttron_shared`:

**Request:**
```json
{
  "id": "req-123",
  "method": "system.getPlatform",
  "params": {}
}
```

**Response (success):**
```json
{
  "id": "req-123",
  "ok": true,
  "result": {
    "platform": "macos"
  },
  "error": null
}
```

**Response (error):**
```json
{
  "id": "req-123",
  "ok": false,
  "result": null,
  "error": "METHOD_NOT_FOUND: system.foo not implemented"
}
```

## Cross-Platform Support

- **Desktop**: macOS (initial focus), Windows/Linux planned
- **Mobile**: Android/iOS planned

## Next Steps

- [Host Layer](./host-layer.md) - Host internals
- [Renderer Layer](./renderer-layer.md) - Renderer internals
- [Bridge Communication](./bridge-communication.md) - IPC details
