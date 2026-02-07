# Quick Start

This guide creates and runs a Fluttron app using the CLI.

## Prerequisites

- Flutter SDK with desktop support enabled
- Node.js
- pnpm (Corepack recommended)

## 1. Create a Project

```bash
fluttron create ./hello_fluttron --name HelloFluttron
```

If you are not using the global CLI, run:

```bash
dart run packages/fluttron_cli/bin/fluttron.dart create ./hello_fluttron --name HelloFluttron
```

Run these commands from repo root when using `dart run ...`.

This generates:
- `fluttron.json`
- `host/` (Flutter Desktop app)
- `ui/` (Flutter Web app)

## 2. Build the UI

```bash
fluttron build -p ./hello_fluttron
```

## 3. Run the Host

```bash
fluttron run -p ./hello_fluttron
```

Optional flags:
- `--device <id>` to target a specific Flutter device
- `--no-build` to skip rebuilding the UI

## What You See

The default demo includes:
- **System Service**: `system.getPlatform`
- **Storage Service**: `storage.kvSet` / `storage.kvGet`
- **Bridge Communication**: JSON IPC between Host and Renderer

## Notes

The default templates depend on local Fluttron packages. The CLI rewrites
template `pubspec.yaml` paths to your repo so the project can build locally.

Frontend pipeline notes:
- `ui/frontend/src/main.js` is bundled into `ui/web/ext/main.js`
- `pnpm run js:clean` removes JS/CSS artifacts and sourcemaps in `ui/web/ext/`
- `fluttron build` copies final web assets into `host/assets/www/`

## Next Steps

- [Project Structure](./project-structure.md) - Learn repo and template layout
- [Architecture Overview](../architecture/overview.md) - Deep dive into Fluttron architecture
- [API Reference](../api/services.md) - Explore available services
