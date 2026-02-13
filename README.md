# Fluttron

Dart-native cross-platform container OS.

Electron inspired, but built for Dart and Flutter developers.

## Why Fluttron

Fluttron keeps the Host layer and Renderer layer in the Dart ecosystem:

- Host: Flutter app with native lifecycle and service capabilities.
- Renderer: Flutter Web app running inside WebView.
- Bridge: JSON-based IPC between Host and Renderer.

You can keep Flutter for UI while still integrating Web ecosystem assets when needed.

## Architecture

Fluttron uses a dual-layer architecture:

- Host (`Flutter Desktop`): window, lifecycle, service registry.
- Renderer (`Flutter Web`): UI + business logic in WebView.
- Bridge (`JavaScript Handler`): request/response IPC.

```mermaid
graph TD
    subgraph Host ["Fluttron Host (Native Dart)"]
        HostMain["Main Entry"]
        Registry["ServiceRegistry"]
        System["SystemService"]
        Storage["StorageService"]
        HostBridge["Host Bridge"]
    end

    subgraph Renderer ["Fluttron UI (Flutter Web)"]
        WebMain["Web Entry"]
        Client["FluttronClient"]
        AppUI["App UI"]
        UiBridge["Renderer Bridge"]
    end

    AppUI --> Client
    Client --> UiBridge
    UiBridge <-->|"IPC / JS Handler"| HostBridge
    HostBridge --> Registry
    Registry --> System
    Registry --> Storage
```

## Current Status (MVP)

- [x] Host and Renderer split architecture
- [x] Host <-> Renderer bridge protocol
- [x] Service registry with `system` and `storage`
- [x] CLI `create/build/run` pipeline
- [x] Template frontend pipeline (`pnpm` + `esbuild`) with JS asset validation
- [x] Core UI library:
  - `FluttronHtmlView` - Embed Web content into Flutter Web
  - `FluttronEventBridge` - JS→Flutter event communication
  - `FluttronWebViewRegistry` - Type-driven view registration
- [x] Host custom service extension with template example
- [x] Web Package support - discovery, asset injection, and generated registrations
- [ ] Plugin system
- [ ] Typed bridge codegen

## Quick Start

### Create a Fluttron App

Prerequisites:

- Flutter SDK (stable) with macOS desktop support
- Node.js
- pnpm (via Corepack or direct install)

From repo root:

```bash
dart pub global activate --path packages/fluttron_cli
fluttron create ./hello_fluttron --name HelloFluttron
fluttron build -p ./hello_fluttron
fluttron run -p ./hello_fluttron
```

Without global CLI:

```bash
dart run packages/fluttron_cli/bin/fluttron.dart create ./hello_fluttron --name HelloFluttron
dart run packages/fluttron_cli/bin/fluttron.dart build -p ./hello_fluttron
dart run packages/fluttron_cli/bin/fluttron.dart run -p ./hello_fluttron
```

### Create a Web Package

Web packages are reusable Dart packages that include Flutter widgets, JavaScript bundles, and CSS:

```bash
fluttron create ./my_editor --name my_editor --type web_package
cd my_editor
dart pub get
```

This creates a package structure with:
- `lib/` - Dart library with widgets
- `frontend/` - JavaScript source files
- `web/ext/` - Built assets (JS/CSS)
- `fluttron_web_package.json` - Package manifest

Build the frontend assets:

```bash
cd my_editor/frontend
pnpm install
pnpm run js:build
```

Then add to your app's `ui/pubspec.yaml`:

```yaml
dependencies:
  my_editor:
    path: ../../my_editor
```

Resolve dependencies in the app UI and build:

```bash
cd ../my_app/ui
flutter pub get
cd ..
fluttron build -p .
fluttron packages list -p .
```

Current MVP distribution mode is path/git dependencies first.

## CLI Commands

| Command | Description |
|---------|-------------|
| `fluttron create <path>` | Create a new app project |
| `fluttron create <path> --type web_package` | Create a web package |
| `fluttron build -p <path>` | Build the UI and copy to host |
| `fluttron run -p <path>` | Run the host application |
| `fluttron packages list -p <path>` | List discovered web packages |

## Project Types

### App (`--type app`, default)

Full Fluttron application with host and UI:

```
my_app/
├── fluttron.json
├── host/
│   ├── lib/main.dart
│   ├── pubspec.yaml
│   └── assets/www/
└── ui/
    ├── lib/main.dart
    ├── lib/generated/web_package_registrations.dart
    ├── frontend/src/main.js
    ├── pubspec.yaml
    └── web/ext/
```

### Web Package (`--type web_package`)

Reusable component package:

```
my_package/
├── fluttron_web_package.json
├── pubspec.yaml
├── lib/
│   ├── my_package.dart
│   └── src/widget.dart
├── frontend/
│   ├── package.json
│   └── src/main.js
└── web/ext/
    ├── main.js
    └── main.css
```

## Template Frontend Assets

Default template frontend contract:

- Source: `ui/frontend/src/main.js`
- Runtime output: `ui/web/ext/main.js`
- Optional CSS output: `ui/web/ext/main.css`
- Clean behavior: `pnpm run js:clean` removes JS/CSS outputs and sourcemaps

During `fluttron build`, UI web output is copied to Host assets (`host/assets/www`).
For Web Package dependencies, package assets are collected into `host/assets/www/ext/packages/<pkg>/...`
and registration code is generated to `ui/lib/generated/web_package_registrations.dart`.

## Documentation

- Official docs: [https://maxiee.github.io/Fluttron/](https://maxiee.github.io/Fluttron/)
- Internal development plan: `docs/dev_plan.md`
- Template and manifest spec: `docs/templating.md`

## Contributing

Issues and PRs are welcome.
