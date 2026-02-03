# Project Structure

Fluttron is organized as a monorepo with three main packages. Each package serves a specific purpose in the architecture.

## Monorepo Overview

```
fluttron/
├── packages/
│   ├── fluttron_host/        # Host layer (Flutter Desktop)
│   ├── fluttron_ui/          # Renderer layer (Flutter Web)
│   └── fluttron_shared/      # Shared protocol definitions
├── docs/                     # Documentation
├── website/                  # Docusaurus documentation site
├── README.md
└── LICENSE
```

## Package Details

### fluttron_host

The Host layer is a Flutter Desktop application that manages the window lifecycle and provides native services.

```
fluttron_host/
├── lib/
│   ├── main.dart              # Application entry point
│   ├── host_bridge.dart       # Host-Renderer bridge
│   ├── service.dart           # Service base class
│   ├── service_registry.dart  # Service registration & routing
│   ├── services/
│   │   ├── system_service.dart    # System information service
│   │   └── storage_service.dart  # KV storage service
│   └── web/
│       └── main.dart          # Preload scripts for WebView
├── assets/
│   └── www/                 # Flutter Web build artifacts
├── macos/                   # macOS-specific platform code
├── linux/                   # Linux-specific platform code
├── windows/                 # Windows-specific platform code
├── run.sh                   # Run script
├── pubspec.yaml
└── build.sh                 # Build script
```

**Key Files:**
- `main.dart`: Initializes ServiceRegistry and creates the WebView window
- `host_bridge.dart`: Manages JavaScriptHandler for IPC communication
- `service_registry.dart`: Routes requests to registered services
- `services/`: Implementations of available services

### fluttron_ui

The Renderer layer is a Flutter Web application that handles UI rendering and business logic.

```
fluttron_ui/
├── lib/
│   ├── main.dart              # Flutter Web entry point
│   ├── fluttron/
│   │   ├── fluttron_client.dart  # Client SDK for host services
│   │   └── renderer_bridge.dart  # Bridge communication layer
│   └── pages/
│       └── demo.dart          # Demo page
├── web/
│   └── index.html
├── build.sh                  # Build script (copies to host)
├── run.sh                   # Dev server (Chrome)
└── pubspec.yaml
```

**Key Files:**
- `main.dart`: Initializes FluttronClient and DemoPage
- `fluttron_client.dart`: High-level API for invoking host services
- `renderer_bridge.dart`: Low-level JS interop for bridge communication
- `build.sh`: Compiles Flutter Web and copies to `../fluttron_host/assets/www`

### fluttron_shared

The Shared package contains protocol definitions used by both Host and Renderer.

```
fluttron_shared/
├── lib/src/
│   ├── manifest.dart         # App manifest format
│   ├── request.dart          # Request protocol
│   ├── response.dart         # Response protocol
│   └── error.dart           # Error types
├── lib/fluttron_shared.dart
└── pubspec.yaml
```

**Key Files:**
- `manifest.dart`: Defines `FluttronManifest` and `WindowConfig`
- `request.dart`: Defines `FluttronRequest` (id, method, params)
- `response.dart`: Defines `FluttronResponse` (id, ok, result, error)
- `error.dart`: Defines `FluttronError` (code, message)

## Communication Flow

1. Renderer creates a `FluttronRequest` (JSON)
2. Renderer sends request via JavaScript Handler
3. Host receives request in `host_bridge.dart`
4. Host routes to service via `ServiceRegistry`
5. Service processes request and returns `FluttronResponse` (JSON)
6. Host sends response back to Renderer
7. Renderer parses response and updates UI

## Next Steps

- [Architecture Overview](../architecture/overview.md) - Learn about dual-layer architecture
- [API Reference](../api/services.md) - Explore available services
