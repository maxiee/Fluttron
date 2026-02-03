# Quick Start

This guide creates and runs a Fluttron app using the CLI.

## 1. Create a Project

```bash
fluttron create ./hello_fluttron --name HelloFluttron
```

If you are not using the global CLI, run:

```bash
dart run packages/fluttron_cli/bin/fluttron.dart create ./hello_fluttron --name HelloFluttron
```

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

## Next Steps

- [Project Structure](./project-structure.md) - Learn repo and template layout
- [Architecture Overview](../architecture/overview.md) - Deep dive into Fluttron architecture
- [API Reference](../api/services.md) - Explore available services
