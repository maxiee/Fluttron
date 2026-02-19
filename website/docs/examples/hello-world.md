---
sidebar_position: 1
---

# Hello World Example

This example uses the CLI template and the built-in demo UI.

## 1. Create a Project

```bash
fluttron create ./hello_fluttron --name HelloFluttron
```

## 2. Build and Run

```bash
fluttron build -p ./hello_fluttron
fluttron run -p ./hello_fluttron
```

## What You'll See

The default UI demo provides:
- **Platform info** via `system.getPlatform`
- **Key-value storage** via `storage.kvSet` / `storage.kvGet`
- **Live IPC** through the bridge

## Where the Code Lives

- `host/lib/main.dart`: launches the host via `runFluttronHost()`
- `ui/lib/main.dart`: launches the UI via `runFluttronUi()`
- Host/Renderer implementations live in the core packages: `packages/fluttron_host`, `packages/fluttron_ui`
