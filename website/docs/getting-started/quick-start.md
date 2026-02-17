# Quick Start

This guide creates and runs a Fluttron app using the CLI.

## Prerequisites

- Flutter SDK with desktop support enabled
- Node.js
- pnpm (Corepack recommended)

## 1. Create a Project

### Create an App

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

### Create a Web Package

Web packages are reusable components that can be shared across Fluttron apps:

```bash
fluttron create ./my_editor --name my_editor --type web_package
cd my_editor
dart pub get
```

This generates:
- `fluttron_web_package.json`
- `lib/` (Dart library with widgets)
- `frontend/` (JavaScript source)
- `web/ext/` (Built assets)

## 2. Build the UI

For an app:

```bash
fluttron build -p ./hello_fluttron
```

For a web package:

```bash
cd my_editor/frontend
pnpm install
pnpm run js:build
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
- **Web View**: Embedded editor using `FluttronHtmlView`
- **Event Bridge**: JS→Flutter event communication

## CLI Commands

| Command | Description |
|---------|-------------|
| `fluttron create <path>` | Create a new app project |
| `fluttron create <path> --type web_package` | Create a web package |
| `fluttron build -p <path>` | Build the UI and copy to host |
| `fluttron run -p <path>` | Run the host application |
| `fluttron packages list -p <path>` | List discovered web packages in app dependencies |

## Custom Services

The template includes a commented-out custom service example:
- `host/lib/greeting_service.dart` - Example service skeleton
- Uncomment to enable and call from UI:
  ```dart
  final client = FluttronClient();
  final result = await client.invoke('greeting.greet', {});
  ```

## Using Web Packages in Your App

1. Create a web package:
   ```bash
   fluttron create ./my_widget --name my_widget --type web_package
   ```

2. Build the package assets:
   ```bash
   cd my_widget/frontend && pnpm install && pnpm run js:build
   ```

3. Add to your app's `ui/pubspec.yaml`:
   ```yaml
   dependencies:
     my_widget:
       path: ../../my_widget
   ```

4. Resolve UI dependencies and build:
   ```bash
   cd my_app/ui
   flutter pub get
   cd ..
   fluttron build -p .
   fluttron packages list -p .
   ```

5. Use the widget in your app:
   ```dart
   import 'package:my_widget/my_widget.dart';
   
   // In your widget tree
   MyWidgetExampleWidget(
     initialContent: 'Hello',
     onContentChanged: (data) => print(data),
   )
   ```

## Notes

The default templates depend on local Fluttron packages. The CLI rewrites
template `pubspec.yaml` paths to your repo so the project can build locally.

Frontend pipeline notes:
- `ui/frontend/src/main.js` is bundled into `ui/web/ext/main.js`
- `pnpm run js:clean` removes JS/CSS artifacts and sourcemaps in `ui/web/ext/`
- `fluttron build` copies final web assets into `host/assets/www/`
- For Web Packages, `fluttron build` also generates `ui/lib/generated/web_package_registrations.dart`

## Next Steps

- [Project Structure](./project-structure.md) - Learn repo and template layout
- [Architecture Overview](../architecture/overview.md) - Deep dive into Fluttron architecture
- [Services API](../api/services.md) - Built-in and custom services reference
- [Web Views API](../api/web-views.md) - Embed Web content into Flutter Web
- [Web Packages](../api/web-packages.md) - Create reusable web components
