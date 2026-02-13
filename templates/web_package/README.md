# Fluttron Web Package Template

This template creates a reusable Fluttron web package that can be shared across multiple Fluttron apps.

## What is a Web Package?

A web package is a Dart library that includes:
- **Dart Library**: Flutter Web compatible widgets
- **Frontend Assets**: JavaScript bundles and CSS
- **View Factories**: Registered HTML view factories for `FluttronHtmlView`

## Project Structure

```
my_web_package/
├── fluttron_web_package.json     # Asset manifest
├── pubspec.yaml                  # Dart package definition
├── lib/
│   ├── my_web_package.dart       # Public API
│   └── src/
│       └── example_widget.dart   # Widget implementation
├── frontend/
│   ├── package.json              # pnpm + esbuild config
│   ├── scripts/
│   │   └── build-frontend.mjs    # Build script
│   └── src/
│       └── main.js               # View factory implementations
└── web/
    └── ext/
        ├── main.js               # Bundled JS output (committed)
        └── main.css              # Bundled CSS output (committed)
```

## Getting Started

### 1. Create the Package

```bash
fluttron create ./my_package --name my_package --type web_package
cd my_package
```

### 2. Build Frontend Assets

```bash
dart pub get
cd frontend
pnpm install
pnpm run js:build
```

### 3. Use in an App

Add to your app's `ui/pubspec.yaml`:

```yaml
dependencies:
  my_package:
    path: ../../my_package
```

Then run `fluttron build` - the CLI will automatically:
1. Discover web packages in your dependencies
2. Collect JS/CSS assets
3. Inject them into the build output
4. Generate view factory registrations

## Asset Manifest (`fluttron_web_package.json`)

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

## View Factory Naming Convention

**Pattern**: `fluttronCreate<Package><Type>View`

Examples:
| Package | Type | Factory Name |
|---------|------|--------------|
| `milkdown_editor` | `editor` | `fluttronCreateMilkdownEditorView` |
| `chartjs_wrapper` | `bar` | `fluttronCreateChartjsBarView` |

## Event Naming Convention

**Pattern**: `fluttron.<package>.<type>.<event>`

Examples:
- `fluttron.milkdown_editor.editor.change`
- `fluttron.chartjs_wrapper.bar.click`

---

## CSS Isolation Convention (IMPORTANT)

**Policy**: The Fluttron framework does NOT process or scope CSS. Package authors are fully responsible for CSS isolation.

### Why This Matters

Multiple web packages may be loaded in a single app. Without proper CSS isolation, styles can conflict and cause unpredictable behavior.

### Required Patterns

#### 1. BEM Naming Convention (Recommended)

```css
/* Good: Scoped by package prefix */
.my-package__toolbar { }
.my-package__button--active { }
.my-package__editor--focused { }

/* Bad: Generic names will conflict */
.toolbar { }
.button { }
.active { }
```

**BEM Format**: `.<package-name>__<element>--<modifier>`

#### 2. Container-based Scoping

```css
/* All styles nested under unique container */
.fluttron-my-package .toolbar { }
.fluttron-my-package .button { }
.fluttron-my-package .editor { }
```

#### 3. CSS Modules (if build tool supports)

```javascript
// Generates unique class names at build time
import styles from './editor.module.css';
element.className = styles.toolbar;
```

### What NOT to Do

```css
/* ❌ Global styles - will conflict with other packages */
body { margin: 0; }
.editor { background: white; }

/* ❌ Generic class names */
.container { }
.wrapper { }
.active { }
.disabled { }

/* ❌ Overly broad selectors */
div { }
[class*="button"] { }
```

### Documentation Requirement

Your package's README MUST document:
1. CSS class naming convention used
2. Any global styles that may affect other elements
3. Recommended integration approach

---

## JavaScript Self-Containment

Each web package's JavaScript MUST be fully self-contained.

**Allowed:**
```javascript
// Import from npm packages (bundled by esbuild)
import { Chart } from 'chart.js';
```

**NOT Allowed:**
```javascript
// Assuming another web package's JS is loaded
window.fluttronCreateSharedUtilsView  // ❌ Not available
```

---

## Distribution Scope (MVP)

Current MVP workflow focuses on:

- Path dependencies (local development)
- Git dependencies (shared repositories)

Template default is `publish_to: none`, so pub.dev publishing is not part of the default generated setup.

---

## Troubleshooting

### View factory not found

Ensure:
1. `fluttron_web_package.json` exists and is valid
2. `pubspec.yaml` has `fluttron_web_package: true`
3. `web/ext/main.js` exists and exports the factory

### CSS conflicts

Ensure you're using BEM naming or container scoping. Check for generic class names.

### Build fails

Run `pnpm install` in the `frontend/` directory first.
