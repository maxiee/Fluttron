# Web Packages

Web packages are reusable Dart packages that include Flutter widgets, JavaScript bundles, and CSS. They can be distributed via pub.dev and used across multiple Fluttron apps.

## Overview

A web package encapsulates:
- **Dart Library**: Flutter Web compatible widgets
- **JavaScript Assets**: Bundled JS with view factory implementations
- **CSS Styles**: Bundled stylesheets (with isolation conventions)
- **Manifest**: `fluttron_web_package.json` defining the package contract

## Creating a Web Package

### 1. Create the Package

```bash
fluttron create ./my_editor --name my_editor --type web_package
```

### 2. Project Structure

```
my_editor/
├── fluttron_web_package.json    # Package manifest
├── pubspec.yaml                  # Dart package definition
├── lib/
│   ├── my_editor.dart           # Library entry point
│   └── src/
│       └── editor_widget.dart   # Widget implementation
├── frontend/
│   ├── package.json             # pnpm + esbuild config
│   ├── scripts/
│   │   └── build-frontend.mjs   # Build script
│   └── src/
│       └── main.js              # View factory implementations
└── web/
    └── ext/
        ├── main.js              # Bundled JS output
        └── main.css             # Bundled CSS output
```

### 3. Build Assets

```bash
cd my_editor/frontend
pnpm install
pnpm run js:build
```

## Package Manifest

The `fluttron_web_package.json` file defines the package's capabilities:

```json
{
  "version": "1",
  "viewFactories": [
    {
      "type": "my_editor.editor",
      "jsFactoryName": "fluttronCreateMyEditorEditorView",
      "description": "Markdown editor component"
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
      "payloadType": "{ content: string, timestamp: number }"
    }
  ]
}
```

### Fields

| Field | Required | Description |
|-------|----------|-------------|
| `version` | Yes | Manifest version (currently `"1"`) |
| `viewFactories` | Yes | Array of view factory definitions |
| `viewFactories[].type` | Yes | Unique type identifier |
| `viewFactories[].jsFactoryName` | Yes | JavaScript factory function name |
| `viewFactories[].description` | No | Human-readable description |
| `assets.js` | Yes | Array of JavaScript file paths |
| `assets.css` | No | Array of CSS file paths |
| `events` | No | Array of event definitions |

## Naming Conventions

### View Types

Format: `<package>.<feature>`

```dart
// Good
'my_editor.editor'
'my_editor.preview'
'chart_viewer.bar'

// Avoid
'editor'  // Too generic
'MyEditor'  // Wrong case
```

### JavaScript Factory Names

Format: `fluttronCreate<Package><Feature>View`

```javascript
// Package: my_editor, Feature: editor
window.fluttronCreateMyEditorEditorView = function(viewId, initialContent) {
  // ...
};
```

### Events

Format: `fluttron.<package>.<feature>.<action>`

```javascript
// Dispatch event
element.dispatchEvent(new CustomEvent('fluttron.my_editor.editor.change', {
  detail: { content: newContent },
  bubbles: true,
}));
```

## CSS Isolation

**Critical**: Web packages must use CSS isolation to avoid conflicts when multiple packages are loaded.

### Recommended: BEM Naming

```css
/* Format: .<package>__<element>--<modifier> */

.my-editor__toolbar { }
.my-editor__button--active { }
.my-editor__editor--focused { }
```

### Alternative: Container Scoping

```css
.fluttron-my-editor .toolbar { }
.fluttron-my-editor .button { }
```

### What NOT to Do

```css
/* ❌ These will conflict with other packages */
.toolbar { }
.active { }
.container { }
```

## Dart Widget Implementation

```dart
import 'package:fluttron_ui/fluttron_ui.dart';
import 'package:flutter/material.dart';

class MyEditorWidget extends StatelessWidget {
  const MyEditorWidget({
    super.key,
    this.initialContent = '',
    this.onContentChanged,
  });

  final String initialContent;
  final ValueChanged<Map<String, dynamic>>? onContentChanged;

  @override
  Widget build(BuildContext context) {
    return FluttronHtmlView(
      type: 'my_editor.editor',
      args: [initialContent],
    );
  }
}

// Event stream helper
Stream<Map<String, dynamic>> myEditorChanges() {
  return FluttronEventBridge()
      .on('fluttron.my_editor.editor.change')
      .map((event) => Map<String, dynamic>.from(event as Map));
}
```

## JavaScript Implementation

```javascript
const EDITOR_CHANGE_EVENT = 'fluttron.my_editor.editor.change';

window.fluttronCreateMyEditorEditorView = function(viewId, initialContent) {
  const container = document.createElement('div');
  container.id = `my-editor-${viewId}`;
  container.className = 'my-editor';
  
  // Create your editor UI
  const textarea = document.createElement('textarea');
  textarea.value = initialContent || '';
  textarea.className = 'my-editor__textarea';
  
  textarea.addEventListener('input', () => {
    // Dispatch event to Flutter
    container.dispatchEvent(new CustomEvent(EDITOR_CHANGE_EVENT, {
      detail: { content: textarea.value },
      bubbles: true,
    }));
  });
  
  container.appendChild(textarea);
  return container;
};
```

## Using in an App

### 1. Add Dependency

In your app's `ui/pubspec.yaml`:

```yaml
dependencies:
  my_editor:
    path: ../my_editor
    # Or from pub.dev:
    # my_editor: ^1.0.0
```

### 2. Register Views (Future)

*Note: Automatic registration via CLI is planned for v0038-v0039.*

Currently, register manually:

```dart
import 'package:fluttron_ui/fluttron_ui.dart';

void main() {
  FluttronWebViewRegistry.register(
    FluttronWebViewRegistration(
      type: 'my_editor.editor',
      jsFactoryName: 'window.fluttronCreateMyEditorEditorView',
    ),
  );
  
  runFluttronUi(home: const MyApp());
}
```

### 3. Use the Widget

```dart
import 'package:my_editor/my_editor.dart';

class EditorPage extends StatefulWidget {
  @override
  _EditorPageState createState() => _EditorPageState();
}

class _EditorPageState extends State<EditorPage> {
  String _content = '';
  StreamSubscription? _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = myEditorChanges().listen((data) {
      setState(() => _content = data['content'] ?? '');
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: MyEditorWidget(
            initialContent: _content,
            onContentChanged: (data) {
              print('Content: ${data['content']}');
            },
          ),
        ),
        Text('Word count: ${_content.split(' ').length}'),
      ],
    );
  }
}
```

## Publishing

Web packages can be published to pub.dev like any Dart package:

```bash
cd my_editor
dart pub publish
```

Users can then add them as dependencies:

```yaml
dependencies:
  my_editor: ^1.0.0
```

## Best Practices

1. **CSS Isolation**: Always use prefixed class names
2. **Self-Contained JS**: Don't assume other packages' JS is loaded
3. **Document Events**: List all events your package emits in README
4. **Semantic Versioning**: Follow SemVer for package versions
5. **Example Widget**: Include a working example widget

## Troubleshooting

### View Factory Not Found

Ensure:
- `fluttron_web_package.json` exists and is valid
- `pubspec.yaml` has `fluttron_web_package: true`
- `web/ext/main.js` exists and exports the factory
- The view is registered in your app

### CSS Conflicts

Check for:
- Generic class names (`.container`, `.button`, etc.)
- Global styles affecting other elements
- Missing BEM prefixes

### Build Fails

Run manually:
```bash
cd frontend
rm -rf node_modules pnpm-lock.yaml
pnpm install
pnpm run js:build
```

## Next Steps

- [Web Views API](./web-views.md) - Core Web View APIs
- [Services API](./services.md) - Host services reference
- [Architecture Overview](../architecture/overview.md) - System architecture
