# Fluttron Web Package - Product Requirements Document (PRD)

**Version:** 0.2.0-draft  
**Date:** 2026-02-12  
**Status:** Draft  
**Author:** Fluttron Architecture Team

---

## Architecture Decisions (Confirmed)

| Decision | Choice | Rationale |
|----------|--------|-----------|
| **Package Discovery** | `.dart_tool/package_config.json` | Stable, cross-environment consistent, Dart official mechanism |
| **JS Dependencies** | Self-contained | Each package's JS must be fully bundled (esbuild), no cross-package JS dependencies |
| **CSS Isolation** | Convention over configuration | Framework does not process CSS; package authors must use BEM/CSS Modules |
| **Type Conflict** | Runtime warning + last-wins | Later registration overrides earlier, prints warning |
| **Hot Reload** | Not in MVP | Future iteration |
| **Distribution** | Path/Git dependencies first | pub.dev support later |

---

## 1. Executive Summary

### 1.1 Problem Statement

Current Fluttron architecture has a monolithic frontend model:
- All frontend JavaScript code (e.g., Milkdown editor integration) lives in the single `ui/` project
- Reusable frontend components cannot be shared across Fluttron apps
- No standardized mechanism to distribute Flutter Web + HTML/JS hybrid components

### 1.2 Proposed Solution

Introduce **`fluttron_web_package`** — a new project type that packages:
1. **Dart Library**: Standard Flutter Web compatible Dart package
2. **Frontend Assets**: JavaScript bundles, CSS, HTML fragments
3. **View Factories**: Registered HTML view factories for `FluttronHtmlView`

This enables:
- Reusable frontend components distributed via pub.dev
- Dependency-based composition in Fluttron apps
- Build-time asset collection and injection

---

## 2. Terminology

| Term | Definition |
|------|------------|
| **Fluttron App** | Full application created by `fluttron create`, containing `host/` + `ui/` + `fluttron.json` |
| **Web Package** | Reusable Dart library created by `fluttron create --type web_package`, containing frontend assets |
| **Host App** | Native Flutter desktop app embedding WebView |
| **UI Project** | Flutter Web project running inside WebView |
| **View Factory** | JavaScript function creating DOM elements for `FluttronHtmlView` |
| **Asset Manifest** | JSON file declaring frontend assets exported by a web package |

---

## 3. User Stories

### 3.1 Package Developer

> As a **package developer**, I want to create a reusable frontend component (e.g., Milkdown editor, Chart.js wrapper) so that multiple Fluttron apps can use it without duplicating code.

**Acceptance Criteria:**
- [ ] CLI command `fluttron create --type web_package <name>` creates web package scaffold
- [ ] Web package compiles as valid Dart library (publishable to pub.dev)
- [ ] Frontend build produces bundled JavaScript in `web/ext/`
- [ ] Asset manifest declares exported view factories and assets

### 3.2 App Developer

> As an **app developer**, I want to declare web packages as dependencies and have their assets automatically integrated into my app.

**Acceptance Criteria:**
- [ ] Add web package to `ui/pubspec.yaml` dependencies
- [ ] CLI `fluttron build` discovers web packages in dependency tree
- [ ] Collected JS bundles are injected into final HTML
- [ ] View factory registrations are auto-generated in app's `main.dart`

### 3.3 Build System

> As the **build system**, I need to collect assets from all web package dependencies and produce a unified runtime bundle.

**Acceptance Criteria:**
- [ ] Dependency scanning identifies web packages via `fluttron_web_package` tag
- [ ] Asset collection aggregates all `web/ext/*.js` files
- [ ] HTML injection adds `<script>` tags for all collected assets
- [ ] View factory registration code is generated

---

## 4. Project Type Specification

### 4.1 Web Package Structure

```
my_web_package/
├── fluttron_web_package.json     # Asset manifest (NEW)
├── pubspec.yaml                   # Dart package definition
├── lib/
│   ├── my_web_package.dart       # Public API
│   └── src/
│       ├── widgets/              # Flutter Web widgets
│       └── registrations.dart    # View factory registration helpers
├── frontend/
│   ├── package.json              # pnpm + esbuild config
│   ├── pnpm-lock.yaml
│   ├── scripts/
│   │   └── build-frontend.mjs    # Build script (same as template)
│   └── src/
│       └── main.js               # View factory implementations
└── web/
    └── ext/
        └── main.js               # Bundled output (committed)
```

### 4.2 Asset Manifest Schema (`fluttron_web_package.json`)

```json
{
  "$schema": "https://fluttron.dev/schemas/web_package.json",
  "version": "1",
  "viewFactories": [
    {
      "type": "my_package.chart",
      "jsFactoryName": "fluttronCreateMyPackageChartView",
      "description": "Chart.js wrapper component"
    }
  ],
  "assets": {
    "js": ["web/ext/main.js"],
    "css": ["web/ext/main.css"]
  },
  "events": [
    {
      "name": "my_package.chart.change",
      "direction": "js_to_dart",
      "payloadType": "{ value: number, label: string }"
    }
  ]
}
```

### 4.3 Pubspec Tag Convention

Web packages MUST include a special tag in `pubspec.yaml`:

```yaml
name: my_web_package
version: 1.0.0
# This tag identifies the package as a web package
fluttron_web_package: true

dependencies:
  fluttron_ui: ^0.1.0
```

**Rationale:** CLI uses `pub deps` or `dart pub cache` to scan dependencies. The tag can be detected by:
1. Reading `pubspec.yaml` from cached package
2. Checking for `fluttron_web_package: true` field

---

## 5. CLI Commands

### 5.1 `fluttron create --type web_package`

**Usage:**
```bash
fluttron create ./my_chart_package --name my_chart_package --type web_package
```

**Behavior:**
1. Create directory structure from `templates/web_package/`
2. Generate `pubspec.yaml` with `fluttron_web_package: true`
3. Generate `fluttron_web_package.json` with placeholder entries
4. Generate `frontend/src/main.js` with example view factory
5. Generate `lib/my_chart_package.dart` with registration helper

**Output:**
```
my_chart_package/
├── fluttron_web_package.json
├── pubspec.yaml
├── lib/
│   └── my_chart_package.dart
├── frontend/
│   ├── package.json
│   └── src/main.js
└── web/ext/main.js
```

### 5.2 `fluttron build` (Enhanced)

**New Pipeline Stage:** Asset Collection

**Flow:**
```
┌─────────────────────────────────────────────────────────────────┐
│                     fluttron build Pipeline                      │
├─────────────────────────────────────────────────────────────────┤
│ 1. [Existing] Frontend Build (pnpm run js:build)                │
│ 2. [Existing] Flutter Build Web (flutter build web)             │
│ 3. [NEW] Web Package Discovery                                   │
│    ├─ Parse pubspec.lock                                         │
│    ├─ For each dependency:                                       │
│    │   ├─ Check for fluttron_web_package.json in cache          │
│    │   └─ Collect asset manifest if exists                       │
│    └─ Aggregate all manifests                                    │
│ 4. [NEW] Asset Collection                                        │
│    ├─ Copy web/ext/*.js from each package to ui/build/web/ext/  │
│    └─ Copy web/ext/*.css similarly                               │
│ 5. [NEW] HTML Injection                                          │
│    ├─ Parse ui/build/web/index.html                              │
│    ├─ Inject <script> tags for all collected JS                  │
│    └─ Inject <link> tags for all collected CSS                   │
│ 6. [Existing] Copy to host/assets/www/                           │
│ 7. [NEW] Registration Generator                                  │
│    └─ Generate view factory registrations for main.dart          │
└─────────────────────────────────────────────────────────────────┘
```

### 5.3 `fluttron packages list`

**Usage:**
```bash
fluttron packages list -p ./my_app
```

**Output:**
```
Web Packages in my_app:
┌─────────────────────┬─────────┬─────────────────────────────────┐
│ Package             │ Version │ View Factories                   │
├─────────────────────┼─────────┼─────────────────────────────────┤
│ milkdown_editor     │ 0.2.0   │ milkdown.editor                  │
│ chartjs_wrapper     │ 1.0.0   │ chartjs.bar, chartjs.line        │
│ codemirror_adapter  │ 0.1.0   │ codemirror.editor                │
└─────────────────────┴─────────┴─────────────────────────────────┘
```

---

## 6. Technical Design

### 6.1 Package Discovery Mechanism

**Approach:** Parse `.dart_tool/package_config.json` (generated by `pub get`)

This file contains exact resolved paths for all dependency types (hosted, path, git).

**`package_config.json` Structure:**
```json
{
  "configVersion": 2,
  "packages": [
    {
      "name": "milkdown_editor",
      "rootUri": "file:///Users/.../.pub-cache/hosted/pub.dev/milkdown_editor-0.1.0",
      "packageUri": "lib/",
      "languageVersion": "3.0"
    },
    {
      "name": "my_local_package",
      "rootUri": "../../packages/my_local_package",
      "packageUri": "lib/"
    }
  ]
}
```

**Discovery Logic:**
```dart
// lib/src/utils/web_package_discovery.dart
class WebPackageDiscovery {
  static const _packageConfigPath = '.dart_tool/package_config.json';
  
  /// Scans package_config.json for web packages
  Future<List<WebPackageManifest>> discover(Directory projectDir) async {
    final configFile = File(p.join(projectDir.path, _packageConfigPath));
    if (!await configFile.exists()) {
      // No package_config.json means no dependencies
      return [];
    }
    
    final config = await _parsePackageConfig(configFile);
    final manifests = <WebPackageManifest>[];
    
    for (final pkg in config.packages) {
      final manifestFile = File(p.join(pkg.rootUriPath, 'fluttron_web_package.json'));
      
      if (await manifestFile.exists()) {
        final manifest = await _parseManifest(manifestFile);
        manifests.add(manifest.copyWith(name: pkg.name, rootPath: pkg.rootUriPath));
      }
    }
    
    return manifests;
  }
}
```

**Advantages over pub cache scanning:**
- Works with path dependencies (monorepo scenario)
- Works with git dependencies (after `pub get`)
- No need to handle `PUB_CACHE` environment variable
- Official Dart mechanism, stable across versions

### 6.2 Asset Collection

**Directory Convention:**
```
ui/build/web/
├── ext/
│   ├── main.js              # App's own frontend bundle
│   ├── main.css             # App's own CSS
│   ├── packages/            # NEW: Collected package assets
│   │   ├── milkdown_editor/
│   │   │   └── main.js
│   │   ├── chartjs_wrapper/
│   │   │   ├── main.js
│   │   │   └── main.css
│   │   └── ...
│   └── ...
└── index.html
```

**Collection Logic:**
```dart
class WebPackageCollector {
  Future<void> collect({
    required Directory buildOutputDir,
    required List<WebPackageManifest> packages,
  }) async {
    final packagesDir = Directory('${buildOutputDir.path}/ext/packages');
    await packagesDir.create(recursive: true);
    
    for (final pkg in packages) {
      final pkgDir = Directory('${packagesDir.path}/${pkg.name}');
      await pkgDir.create(recursive: true);
      
      for (final jsAsset in pkg.assets.js) {
        await _copyAsset(pkg.cachePath, jsAsset, pkgDir);
      }
      for (final cssAsset in pkg.assets.css) {
        await _copyAsset(pkg.cachePath, cssAsset, pkgDir);
      }
    }
  }
}
```

### 6.3 HTML Injection

**Template HTML (`ui/web/index.html`):**
```html
<!DOCTYPE html>
<html>
<head>
  <!-- FLUTTRON_PACKAGES_CSS -->
</head>
<body>
  <!-- FLUTTRON_PACKAGES_JS -->
  <script src="ext/main.js"></script>
  <script src="flutter_bootstrap.js" async></script>
</body>
</html>
```

**Injected HTML:**
```html
<head>
  <!-- FLUTTRON_PACKAGES_CSS -->
  <link rel="stylesheet" href="ext/packages/chartjs_wrapper/main.css">
</head>
<body>
  <!-- FLUTTRON_PACKAGES_JS -->
  <script src="ext/packages/milkdown_editor/main.js"></script>
  <script src="ext/packages/chartjs_wrapper/main.js"></script>
  <script src="ext/main.js"></script>
  <script src="flutter_bootstrap.js" async></script>
</body>
```

**Injection Logic:**
```dart
class HtmlInjector {
  Future<void> inject({
    required File indexHtml,
    required List<WebPackageManifest> packages,
  }) async {
    var content = await indexHtml.readAsString();
    
    final jsTags = packages
        .expand((p) => p.assets.js)
        .map((js) => '<script src="ext/packages/${js}"></script>')
        .join('\n');
    
    final cssTags = packages
        .expand((p) => p.assets.css)
        .map((css) => '<link rel="stylesheet" href="ext/packages/${css}">')
        .join('\n');
    
    content = content.replaceFirst('<!-- FLUTTRON_PACKAGES_JS -->', jsTags);
    content = content.replaceFirst('<!-- FLUTTRON_PACKAGES_CSS -->', cssTags);
    
    await indexHtml.writeAsString(content);
  }
}
```

### 6.4 Registration Code Generation

**Generated File (`ui/lib/generated/web_package_registrations.dart`):**
```dart
// GENERATED BY fluttron build - DO NOT EDIT
// fluttron_web_package registrations

// ignore_for_file: directives_ordering

import 'package:fluttron_ui/fluttron_ui.dart';

void registerFluttronWebPackages() {
  // milkdown_editor
  FluttronWebViewRegistry.register(
    const FluttronWebViewRegistration(
      type: 'milkdown.editor',
      jsFactoryName: 'fluttronCreateMilkdownEditorView',
    ),
  );
  
  // chartjs_wrapper
  FluttronWebViewRegistry.register(
    const FluttronWebViewRegistration(
      type: 'chartjs.bar',
      jsFactoryName: 'fluttronCreateChartjsBarView',
    ),
  );
  FluttronWebViewRegistry.register(
    const FluttronWebViewRegistration(
      type: 'chartjs.line',
      jsFactoryName: 'fluttronCreateChartjsLineView',
    ),
  );
}
```

**App's `main.dart` Usage:**
```dart
import 'generated/web_package_registrations.dart';

void main() {
  registerFluttronWebPackages();  // Register all web package view factories
  _registerLocalWebViews();       // Register app-specific view factories
  runFluttronUi(title: 'My App', home: const MyAppPage());
}
```

**Type Conflict Resolution:**

When multiple packages register the same `type`:
1. Runtime warning is printed: `Warning: View type "chartjs.editor" already registered by "chartjs_wrapper_v1", overriding with "chartjs_wrapper_v2"`
2. Later registration wins (last-wins semantics)
3. This allows intentional overrides when needed

**Implementation in `FluttronWebViewRegistry`:**
```dart
static void register(FluttronWebViewRegistration registration) {
  final existing = _registrations[registration.type];
  if (existing != null && existing.jsFactoryName != registration.jsFactoryName) {
    // Runtime warning, but allow override
    debugPrint('Warning: View type "${registration.type}" already registered by '
        '"${existing.jsFactoryName}", overriding with "${registration.jsFactoryName}"');
  }
  _registrations[registration.type] = registration;
}
```

---

### 6.5 CSS Isolation Convention

**Policy:** Framework does not process or scope CSS. Package authors are responsible for CSS isolation.

**Recommended Patterns:**

1. **BEM Naming Convention:**
```css
/* Good: Scoped by package prefix */
.milkdown-editor__toolbar { }
.milkdown-editor__button--active { }
```

2. **CSS Modules (if build tool supports):**
```javascript
// Generates unique class names
import styles from './editor.module.css';
element.className = styles.toolbar;
```

3. **Container-based Scoping:**
```css
/* All styles nested under unique container */
.fluttron-milkdown-editor .toolbar { }
.fluttron-milkdown-editor .button { }
```

**Documentation Requirement:**

Web package README MUST document:
- CSS class naming convention used
- Any global styles that may affect other elements
- Recommended integration approach

---

### 6.6 JS Bundle Self-Containment

**Constraint:** Each web package's JavaScript MUST be fully self-contained.

**Rationale:**
- Avoids load order dependencies
- Simplifies build pipeline (no DAG resolution needed)
- esbuild already bundles all dependencies into single file

**Allowed:**
```javascript
// Import from npm packages (bundled by esbuild)
import Milkdown from '@milkdown/core';
import { Chart } from 'chart.js';
```

**NOT Allowed:**
```javascript
// Assuming another web package's JS is loaded
// This will fail at runtime
window.fluttronCreateSharedUtilsView // ❌ Not available
```

**Verification:** CLI checks that all `web/ext/*.js` files are present. If a package's JS references external globals not defined in its own bundle, it's the package author's responsibility to fix.

---

## 7. View Factory Naming Convention

**Pattern:** `fluttronCreate<Package><Type>View`

**Examples:**
| Package | Type | Factory Name |
|---------|------|--------------|
| `milkdown_editor` | `editor` | `fluttronCreateMilkdownEditorView` |
| `chartjs_wrapper` | `bar` | `fluttronCreateChartjsBarView` |
| `chartjs_wrapper` | `line` | `fluttronCreateChartjsLineView` |
| `codemirror_adapter` | `editor` | `fluttronCreateCodemirrorEditorView` |

**Collision Avoidance:**
- Package name is always included (prevents same type collision across packages)
- Underscores converted to CamelCase (`milkdown_editor` → `MilkdownEditor`)

---

## 8. Event Namespace Convention

**Pattern:** `fluttron.<package>.<type>.<event>`

**Examples:**
```
fluttron.milkdown_editor.editor.change
fluttron.chartjs_wrapper.bar.click
fluttron.codemirror_adapter.editor.cursor_move
```

---

## 9. CLI Implementation Plan

### Phase 1: Core Infrastructure (v0031)

1. **Web Package Template** (`templates/web_package/`)
   - Create scaffold directory
   - Add `fluttron_web_package.json` schema
   - Add example `frontend/src/main.js` with factory pattern
   - Add CSS namespace convention example

2. **Create Command Enhancement**
   - Add `--type` option (`app` | `web_package`)
   - Default to `app` for backward compatibility
   - Route to different template directories

3. **Manifest Parser**
   - `lib/src/utils/web_package_manifest.dart`
   - JSON schema validation
   - View factory model

### Phase 2: Discovery & Collection (v0032)

1. **Package Discovery**
   - `lib/src/utils/web_package_discovery.dart`
   - Parse `.dart_tool/package_config.json`
   - Resolve manifest paths from rootUri
   - Support path, git, and hosted dependencies

2. **Asset Collector**
   - `lib/src/utils/web_package_collector.dart`
   - Copy JS/CSS to build output
   - Directory structure management
   - Validate self-contained JS (no missing dependencies)

### Phase 3: HTML & Code Generation (v0033)

1. **HTML Injector**
   - `lib/src/utils/html_injector.dart`
   - Comment placeholder replacement
   - Script/link tag generation

2. **Registration Generator**
   - `lib/src/utils/registration_generator.dart`
   - Dart code generation with `@generated` header
   - Output to `ui/lib/generated/`
   - Add `.gitignore` entry recommendation

### Phase 4: Integration & Polish (v0034)

1. **Build Pipeline Integration**
   - Insert stages into `UiBuildPipeline`
   - Conditional execution (skip if no web packages)
   - Error handling and validation

2. **Packages List Command**
   - `fluttron packages list`
   - Output formatting

3. **Documentation**
   - Template README update
   - Website docs update
   - CSS naming convention guide

---

## 10. Risks and Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| **package_config.json missing** | Medium | Requires `pub get` before build; CLI checks existence and provides clear error |
| **Path dependency outside project** | Low | `package_config.json` contains relative/absolute paths; should work |
| **Git dependency not fully fetched** | Low | After `pub get`, git deps are cached locally with all files |
| **JS bundle size bloat** | Medium | Encourage tree-shaking in build scripts; future: support selective loading |
| **CSS conflicts between packages** | Medium | Convention-based: require package authors to namespace CSS; document in README |
| **Type registration conflicts** | Low | Runtime warning + last-wins semantics; documented behavior |
| **Generated code drift** | Low | Add `@generated` header; regenerate on every build; add to .gitignore recommendation |

---

## 11. Backward Compatibility

### 11.1 Existing Apps

- Apps without web packages continue to work unchanged
- `fluttron build` skips discovery if no web packages found
- No changes to `fluttron.json` schema required

### 11.2 Existing Templates

- `templates/host/` and `templates/ui/` remain unchanged
- New `templates/web_package/` added without affecting existing

### 11.3 CLI Commands

- `fluttron create` defaults to `--type app`
- `fluttron build` adds new stages conditionally
- No breaking changes to command signatures

---

## 12. Future Considerations (Out of Scope for MVP)

1. **Hot Reload Support (High Priority)**: Auto-rebuild web packages during development; watch for file changes
2. **pub.dev Distribution**: Support publishing web packages to pub.dev with proper metadata
3. **Selective Loading**: Only load packages needed for current route
4. **Type-Safe Events**: Generate Dart types from event payload schemas
5. **Asset Deduplication**: Shared dependencies between packages
6. **Remote Packages**: Load packages from CDN at runtime
7. **Version Constraints**: Enforce compatible package versions
8. **CSS Auto-Scoping**: Optional build-time CSS prefix injection

---

## 13. Acceptance Test Plan

### 13.1 Create Web Package

```bash
fluttron create ./test_package --name test_package --type web_package
cd test_package
pnpm install
pnpm run js:build
dart analyze
```

**Expected:** No errors, `web/ext/main.js` exists

### 13.2 Use Web Package in App

```bash
# Create app
fluttron create ./test_app --name test_app
cd test_app

# Add web package dependency
echo 'dependencies:
  test_package:
    path: ../test_package' >> ui/pubspec.yaml

# Build
fluttron build -p .

# Verify
grep 'ext/packages/test_package/main.js' host/assets/www/index.html
grep 'registerFluttronWebPackages' ui/lib/generated/web_package_registrations.dart
```

**Expected:** JS injected, registrations generated

### 13.3 End-to-End

```bash
cd test_app
fluttron run -p . -d macos
```

**Expected:** App launches, web package view factory callable

---

## 14. Appendix

### A. Example Web Package: Milkdown Editor

**`pubspec.yaml`:**
```yaml
name: fluttron_milkdown
version: 0.1.0
description: Milkdown markdown editor for Fluttron
fluttron_web_package: true

dependencies:
  fluttron_ui: ^0.1.0
```

**`fluttron_web_package.json`:**
```json
{
  "version": "1",
  "viewFactories": [
    {
      "type": "milkdown.editor",
      "jsFactoryName": "fluttronCreateMilkdownEditorView",
      "description": "Milkdown WYSIWYG markdown editor"
    }
  ],
  "assets": {
    "js": ["web/ext/main.js"],
    "css": ["web/ext/main.css"]
  },
  "events": [
    {
      "name": "fluttron.milkdown.editor.change",
      "direction": "js_to_dart",
      "payloadType": "{ markdown: string }"
    }
  ]
}
```

**`lib/fluttron_milkdown.dart`:**
```dart
library fluttron_milkdown;

export 'src/milkdown_editor.dart';
```

**`lib/src/milkdown_editor.dart`:**
```dart
import 'package:fluttron_ui/fluttron_ui.dart';
import 'package:flutter/material.dart';

class MilkdownEditor extends StatelessWidget {
  const MilkdownEditor({
    super.key,
    this.initialMarkdown = '',
    this.onChanged,
  });

  final String initialMarkdown;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return FluttronHtmlView(
      type: 'milkdown.editor',
      args: [initialMarkdown],
    );
  }
}

// Helper for event subscription
Stream<String> milkdownChanges() {
  return FluttronEventBridge()
      .on('fluttron.milkdown.editor.change')
      .map((e) => e['markdown'] as String);
}
```

### B. Asset Manifest JSON Schema

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "$id": "https://fluttron.dev/schemas/web_package.json",
  "type": "object",
  "required": ["version", "viewFactories", "assets"],
  "properties": {
    "version": {
      "type": "string",
      "enum": ["1"],
      "description": "Manifest schema version"
    },
    "viewFactories": {
      "type": "array",
      "items": {
        "type": "object",
        "required": ["type", "jsFactoryName"],
        "properties": {
          "type": {
            "type": "string",
            "pattern": "^[a-z0-9_]+\\.[a-z0-9_]+$",
            "description": "View type identifier (package.type)"
          },
          "jsFactoryName": {
            "type": "string",
            "pattern": "^fluttronCreate[A-Z][a-zA-Z0-9]*View$",
            "description": "JavaScript factory function name"
          },
          "description": {
            "type": "string",
            "description": "Human-readable description"
          }
        }
      }
    },
    "assets": {
      "type": "object",
      "required": ["js"],
      "properties": {
        "js": {
          "type": "array",
          "items": {
            "type": "string",
            "pattern": "^web/ext/[^/]+\\.js$"
          }
        },
        "css": {
          "type": "array",
          "items": {
            "type": "string",
            "pattern": "^web/ext/[^/]+\\.css$"
          }
        }
      }
    },
    "events": {
      "type": "array",
      "items": {
        "type": "object",
        "required": ["name", "direction"],
        "properties": {
          "name": {
            "type": "string",
            "pattern": "^fluttron\\.[a-z0-9_]+\\.[a-z0-9_.]+$"
          },
          "direction": {
            "type": "string",
            "enum": ["js_to_dart", "dart_to_js", "bidirectional"]
          },
          "payloadType": {
            "type": "string",
            "description": "TypeScript-style type definition"
          }
        }
      }
    }
  }
}
```

---

**Document History:**

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 0.1.0-draft | 2026-02-12 | Architecture Team | Initial draft |
| 0.2.0-draft | 2026-02-12 | Architecture Team | Architecture decisions confirmed: package_config.json discovery, self-contained JS, CSS convention, runtime warning + last-wins for conflicts |
