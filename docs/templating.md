# Fluttron Templates And Manifest

This document defines the minimal template structure and the `fluttron.json` manifest format.

## Template Structure (Repository Root)

```
<project-root>/
  fluttron.json
  host/
    lib/main.dart
    pubspec.yaml
    assets/www/
  ui/
    lib/main.dart
    pubspec.yaml
    build/web/
```

### Notes

- `host/` is a Flutter desktop app that embeds a WebView and loads assets from `host/assets/www/`.
- `ui/` is a Flutter Web app that builds to `ui/build/web/`.
- The build step should copy `ui/build/web/` into `host/assets/www/`.

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
