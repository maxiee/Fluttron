# Fluttron Templates And Manifest

This document defines the template structure and manifest formats for Fluttron projects.

## App Template Structure

The default app template creates a full Fluttron application:

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

---

## Web Package Template Structure

Web packages are reusable Dart packages that can be distributed and used across multiple Fluttron apps.

Create with:

```bash
fluttron create ./my_package --name my_package --type web_package
```

### Directory Structure

```
my_package/
├── fluttron_web_package.json    # Package manifest (required)
├── pubspec.yaml                  # Dart package definition
├── lib/
│   ├── my_package.dart          # Library entry point
│   └── src/
│       └── example_widget.dart  # Widget implementation
├── frontend/
│   ├── package.json             # pnpm + esbuild config
│   ├── scripts/
│   │   └── build-frontend.mjs   # Build script
│   └── src/
│       └── main.js              # View factory implementations
└── web/
    └── ext/
        ├── main.js              # Bundled JS output (committed)
        └── main.css             # Bundled CSS output (committed)
```

### Key Files

#### pubspec.yaml

Must include `fluttron_web_package: true` tag:

```yaml
name: my_package
fluttron_web_package: true

dependencies:
  flutter:
    sdk: flutter
  fluttron_ui:
    path: ../packages/fluttron_ui
```

#### fluttron_web_package.json

Asset manifest defining view factories, assets, and events:

```json
{
  "version": "1",
  "viewFactories": [
    {
      "type": "my_package.example",
      "jsFactoryName": "fluttronCreateMyPackageExampleView",
      "description": "Example component"
    }
  ],
  "assets": {
    "js": ["web/ext/main.js"],
    "css": ["web/ext/main.css"]
  },
  "events": [
    {
      "name": "fluttron.my_package.example.change",
      "direction": "js_to_dart",
      "payloadType": "{ content: string }"
    }
  ]
}
```

### Naming Conventions

When creating a web package, the CLI automatically transforms the package name:

| Format | Example | Use Case |
|--------|---------|----------|
| snake_case | `markdown_editor` | Dart package name, file names |
| PascalCase | `MarkdownEditor` | Dart class names |
| camelCase | `markdownEditor` | Dart function/method names |
| kebab-case | `markdown-editor` | CSS class prefixes |

### View Factory Naming

**Pattern**: `fluttronCreate<Package><Feature>View`

Examples:
| Package | Feature | Factory Name |
|---------|---------|--------------|
| `markdown_editor` | `editor` | `fluttronCreateMarkdownEditorEditorView` |
| `chart_viewer` | `bar` | `fluttronCreateChartViewerBarView` |

### Event Naming

**Pattern**: `fluttron.<package>.<feature>.<event>`

Examples:
- `fluttron.markdown_editor.editor.change`
- `fluttron.chart_viewer.bar.click`

### CSS Isolation

Web packages must use CSS isolation to avoid conflicts:

**Recommended: BEM naming**

```css
/* Good: Scoped by package prefix */
.my-package__toolbar { }
.my-package__button--active { }

/* Bad: Generic names will conflict */
.toolbar { }
.button { }
```

**Alternative: Container scoping**

```css
.fluttron-my-package .toolbar { }
.fluttron-my-package .button { }
```

### Build Process

1. Install dependencies:
   ```bash
   cd frontend
   pnpm install
   ```

2. Build assets:
   ```bash
   pnpm run js:build
   ```

3. Clean assets (optional):
   ```bash
   pnpm run js:clean
   ```

### Using in an App

Add to your app's `ui/pubspec.yaml`:

```yaml
dependencies:
  my_package:
    path: ../my_package
```

---

## fluttron.json (App Manifest)

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
