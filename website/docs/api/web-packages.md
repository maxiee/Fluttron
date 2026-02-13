# Web Packages

Web packages are reusable Dart packages that bundle Flutter widgets, JavaScript factories, and optional CSS assets for Fluttron apps.

## What Is Implemented

Web Package support is fully integrated in the CLI build flow:

- `fluttron create --type web_package` scaffold
- Dependency discovery from `ui/.dart_tool/package_config.json`
- Manifest + marker validation (`fluttron_web_package.json` + `fluttron_web_package: true`)
- Asset collection into `ext/packages/<package>/...`
- HTML injection for package JS/CSS
- Auto-generation of `ui/lib/generated/web_package_registrations.dart`
- Diagnostics command: `fluttron packages list -p <app>`

## Create a Web Package

```bash
fluttron create ./my_editor --name my_editor --type web_package
cd my_editor
dart pub get
cd frontend
pnpm install
pnpm run js:build
```

Notes:

- Template `pubspec.yaml` includes `fluttron_web_package: true`.
- Template default is `publish_to: none` (MVP distribution is path/git first).
- `create` rewrites local Fluttron dependency paths so local builds work immediately.

## Package Structure

```text
my_editor/
├── fluttron_web_package.json
├── pubspec.yaml
├── lib/
│   ├── my_editor.dart
│   └── src/
│       └── example_widget.dart
├── frontend/
│   ├── package.json
│   ├── scripts/build-frontend.mjs
│   └── src/main.js
└── web/
    └── ext/
        ├── main.js
        └── main.css
```

## Manifest Contract

`fluttron_web_package.json`:

```json
{
  "version": "1",
  "viewFactories": [
    {
      "type": "my_editor.editor",
      "jsFactoryName": "fluttronCreateMyEditorEditorView",
      "description": "Editor component"
    }
  ],
  "assets": {
    "js": ["web/ext/main.js"],
    "css": ["web/ext/main.css"]
  },
  "events": [
    {
      "name": "fluttron.my_editor.editor.change",
      "direction": "js_to_dart",
      "payloadType": "{ content: string }"
    }
  ]
}
```

Field summary:

- `version`: must be `"1"`
- `viewFactories`: required, at least one
- `assets.js`: required
- `assets.css`: optional
- `events`: optional

## Integrate Into an App

1. Add dependency in `ui/pubspec.yaml`:

```yaml
dependencies:
  my_editor:
    path: ../../my_editor
```

2. Resolve UI dependencies:

```bash
cd my_app/ui
flutter pub get
```

3. Build app:

```bash
cd ..
fluttron build -p .
```

During `fluttron build`, the pipeline runs:

1. UI frontend build (`pnpm run js:build`)
2. UI source JS validation
3. Web package discovery
4. Registration generation
5. `flutter build web`
6. Package asset collection
7. HTML injection
8. Build output JS validation
9. Copy to `host/assets/www`
10. Host asset JS validation

## Auto Registration

Generated file:

- `ui/lib/generated/web_package_registrations.dart`

Template apps already import and call:

```dart
import 'generated/web_package_registrations.dart';

void main() {
  registerFluttronWebPackages();
  runFluttronUi(title: 'My App', home: const MyHomePage());
}
```

## JavaScript Factory Contract

Register function name in manifest without `window.` prefix, for example:

- `jsFactoryName: "fluttronCreateMyEditorEditorView"`

Expose it globally in JS:

```javascript
window.fluttronCreateMyEditorEditorView = function(viewId, initialContent) {
  const container = document.createElement('div');
  container.id = `my-editor-${viewId}`;
  return container;
};
```

## Conflict Strategy

Type conflicts are strict:

- Same `type` + same `jsFactoryName`: idempotent
- Same `type` + different `jsFactoryName`: throws `StateError`

This is enforced by `FluttronWebViewRegistry` at runtime.

## Diagnose Dependencies

List discovered web packages:

```bash
fluttron packages list -p ./my_app
```

Output includes package name, version, and exposed view factory types.

## MVP Distribution Scope

Current supported distribution paths:

- Path dependencies (local development)
- Git dependencies

Out of current MVP scope:

- Direct pub.dev distribution workflow

## Troubleshooting

### Package not discovered

Check all of the following in the package root:

- `fluttron_web_package.json` exists
- `pubspec.yaml` contains `fluttron_web_package: true`
- `ui/.dart_tool/package_config.json` is present (`flutter pub get` in `ui/`)

### View factory not found

Check:

- `jsFactoryName` in manifest does not include `window.`
- Corresponding function is attached on `window` in JS
- `web/ext/main.js` was rebuilt (`pnpm run js:build`)

### Asset injection missing

Run:

```bash
fluttron build -p ./my_app
fluttron packages list -p ./my_app
```

Then inspect:

- `host/assets/www/index.html`
- `host/assets/www/ext/packages/<package>/...`
