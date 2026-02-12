# Fluttron Templates And Manifest

This document defines the minimal template structure and the `fluttron.json` manifest format.

## Template Structure (Repository Root)

```
<project-root>/
  fluttron.json
  host/
    lib/main.dart
    lib/greeting_service.dart  # Custom service example (commented out)
    pubspec.yaml
    assets/www/
  ui/
    frontend/src/
    lib/main.dart
    pubspec.yaml
    web/ext/
    build/web/
```

### Notes

- `host/` is a Flutter desktop app that embeds a WebView and loads assets from `host/assets/www/`.
- `ui/` is a Flutter Web app that builds to `ui/build/web/`.
- `ui/frontend/src/` stores frontend source files for web ecosystem integration.
- `ui/web/ext/` stores runtime JavaScript assets loaded by `ui/web/index.html`.
- CLI build pipeline runs `pnpm run js:build` before `flutter build web` when `package.json` has `scripts["js:build"]`.
- If `scripts["js:clean"]` exists, CLI runs `pnpm run js:clean` before `js:build`.
- If `package.json` or `scripts["js:build"]` is missing, frontend build is skipped.
- If Node.js/pnpm/frontend build fails, CLI exits with readable errors.
- The build step copies `ui/build/web/` into `host/assets/www/`.
- CLI parses local `<script src="...">` entries from `ui/web/index.html` and validates JS assets in three stages:
  - source stage: `ui/web/` (excluding Flutter-generated scripts such as `flutter_bootstrap.js`)
  - Flutter build stage: `ui/build/web/`
  - host sync stage: `host/assets/www/`
- Any JS asset validation failure is treated as a hard error and stops the build pipeline.

### Host Custom Services

The template includes `host/lib/greeting_service.dart` with a commented-out example service. To enable:

1. Uncomment the code in `greeting_service.dart`
2. Uncomment the import and registration code in `main.dart`
3. Call from UI: `FluttronClient.invoke('greeting.greet', {})`

This provides a reference implementation for creating custom Host services.

### UI Web Views

The template UI uses the Fluttron Web View system:

- `FluttronWebViewRegistry` - Register view types at startup
- `FluttronHtmlView` - Embed Web content with type-driven rendering
- `FluttronEventBridge` - Receive JS→Flutter custom events

See `ui/lib/main.dart` for the registration pattern and `ui/frontend/src/main.js` for the JS factory contract.

## fluttron.json

### Required Fields

- `name`: App name (string).
- `version`: App version (string, SemVer recommended).
- `entry.uiProjectPath`: Relative path to the Flutter Web project (string).
- `entry.hostAssetPath`: Relative path to the host's Web assets directory (string).
- `entry.index`: Entry HTML file name (string).

### Optional Fields

- `window.title`: Window title (string).
- `window.width`: Window width in pixels (number).
- `window.height`: Window height in pixels (number).
- `window.resizable`: Whether window is resizable (boolean).

### Example

```json
{
  "name": "hello_fluttron",
  "version": "0.1.0",
  "entry": {
    "uiProjectPath": "ui",
    "hostAssetPath": "host/assets/www",
    "index": "index.html"
  },
  "window": {
    "title": "Hello Fluttron",
    "width": 1200,
    "height": 800,
    "resizable": true
  }
}
```
