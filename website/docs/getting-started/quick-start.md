# Quick Start

This guide will help you create and run your first Fluttron application in minutes.

## Create a Fluttron Project

Currently, Fluttron uses a manual project setup. In the future, a CLI tool will automate this process.

For now, use the monorepo template:

```bash
# Clone the repository
git clone https://github.com/fluttron/fluttron.git
cd fluttron

# The repository structure serves as your template:
# - packages/fluttron_host/  -> Host layer template
# - packages/fluttron_ui/    -> Renderer layer template
# - packages/fluttron_shared/ -> Shared protocol definitions
```

## Build and Run

### Step 1: Build the Renderer (Flutter Web)

```bash
cd packages/fluttron_ui
./build.sh
```

This command:
- Builds the Flutter Web application
- Copies the compiled artifacts to `../fluttron_host/assets/www`

### Step 2: Run the Host

```bash
cd ../fluttron_host
./run.sh
```

This will launch the Fluttron Host application, which loads the Flutter Web app from `assets/www`.

## What You See

The demo page demonstrates:

- **System Service**: Retrieve platform information (e.g., "macos")
- **Storage Service**: Key-value storage operations (kvSet/kvGet)
- **Bridge Communication**: Real-time communication between Renderer and Host

## Architecture Overview

```
┌─────────────────────────────────────┐
│   Fluttron Host (Desktop App)      │
│   ┌─────────────────────────────┐   │
│   │  ServiceRegistry           │   │
│   │  - SystemService          │   │
│   │  - StorageService         │   │
│   └─────────────┬─────────────┘   │
│                 │ Bridge IPC       │
│   ┌─────────────▼─────────────┐   │
│   │  WebView Container         │   │
│   └─────────────┬─────────────┘   │
└─────────────────┼───────────────────┘
                  │
┌─────────────────▼───────────────────┐
│   Fluttron UI (Flutter Web)        │
│   ┌─────────────────────────────┐   │
│   │  FluttronClient           │   │
│   │  - getPlatform()          │   │
│   │  - kvSet() / kvGet()      │   │
│   └─────────────────────────────┘   │
│   ┌─────────────────────────────┐   │
│   │  DemoPage (UI)            │   │
│   └─────────────────────────────┘   │
└─────────────────────────────────────┘
```

## Next Steps

- [Project Structure](./project-structure.md) - Learn about the monorepo organization
- [Architecture Overview](../architecture/overview.md) - Deep dive into Fluttron architecture
- [API Reference](../api/services.md) - Explore available services
