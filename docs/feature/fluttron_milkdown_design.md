# fluttron_milkdown — Technical Design Document

**Version:** 0.1.0-draft  
**Date:** 2026-02-14  
**Status:** Draft  
**Author:** Fluttron Architecture Team

---

## 1. Executive Summary

### 1.1 What

`fluttron_milkdown` is the first official Fluttron Web Package, wrapping the JavaScript [Milkdown](https://milkdown.dev/) WYSIWYG markdown editor into a reusable Fluttron UI library. It will be located at `web_packages/fluttron_milkdown/` and distributed as a standard Dart package (path/git dependency).

### 1.2 Why

This project serves a **dual purpose**:

1. **Product value**: Provide a production-quality markdown editor component that any Fluttron app can use by simply adding a dependency — no manual JS integration needed.
2. **Platform validation**: As the first real-world Web Package, `fluttron_milkdown` will stress-test the entire `fluttron_web_package` mechanism (v0032–v0041) end-to-end and expose any fragility that needs hardening.

### 1.3 Scope Overview

| Dimension | Decision |
|-----------|----------|
| Milkdown integration | `@milkdown/crepe` (high-level, batteries-included) |
| Markdown features | CommonMark + GFM + Code highlighting (Prism) + Slash + Tooltip + History |
| Dart API | `MilkdownEditor` widget + event stream + programmatic control |
| Theme strategy | Multiple switchable themes (frame, classic, nord; light + dark) |
| Distribution | Path/git dependency (MVP); pub.dev later |
| Target platform | macOS Desktop (via Fluttron Host WebView) |

---

## 2. Goals & Success Criteria

### 2.1 Product Goals

| # | Goal | Measurable Criteria |
|---|------|---------------------|
| G1 | Drop-in markdown editor | App developer adds 1 dependency + 1 widget, gets a working editor |
| G2 | Rich editing experience | CommonMark, GFM tables/task lists, code blocks with syntax highlighting, slash commands, tooltip toolbar, undo/redo — all working out of the box |
| G3 | Programmatic control | Dart code can get/set content, focus editor, insert text at cursor |
| G4 | Theme switching | Dart code can switch between 6 built-in themes at runtime |

### 2.2 Platform Validation Goals

| # | Goal | What we validate |
|---|------|-----------------|
| V1 | Web Package lifecycle | `fluttron create --type web_package` → develop → build → integrate → run |
| V2 | Asset pipeline | JS/CSS discovery, collection, HTML injection, host sync |
| V3 | Registration generator | Auto-generated `registerFluttronWebPackages()` resolves correctly |
| V4 | CSS isolation | BEM-namespaced CSS does not leak across packages |
| V5 | Multi-asset bundle | Package with both JS and CSS assets works correctly |
| V6 | Dart→JS control channel | New pattern for programmatic control validates/extends Fluttron's communication model |
| V7 | Complex JS dependencies | Large npm dependency tree (Milkdown + ProseMirror) bundles correctly via esbuild |

### 2.3 Non-Goals (Explicit)

- Collaborative editing (yjs) — future iteration
- Image upload integration — requires Host-side file service
- Custom plugin API for end users — out of scope for v1
- pub.dev publishing — MVP uses path/git only
- Mobile platform testing — desktop-first

---

## 3. Architecture Overview

### 3.1 Layer Diagram

```
┌──────────────────────────────────────────────────────────────────────┐
│                        Fluttron App (Consumer)                       │
│                                                                      │
│  ui/lib/main.dart                                                    │
│  ┌────────────────────────────────────────────────────────────────┐  │
│  │  import 'package:fluttron_milkdown/fluttron_milkdown.dart';   │  │
│  │                                                                │  │
│  │  MilkdownEditor(                                               │  │
│  │    controller: _controller,                                    │  │
│  │    theme: MilkdownTheme.frame,                                 │  │
│  │    onChanged: (md) => print(md),                               │  │
│  │  )                                                             │  │
│  └────────────────────────────────────────────────────────────────┘  │
│              │ Dart (Flutter Web)                                     │
│              ▼                                                       │
│  ┌────────────────────────────────────────────────────────────────┐  │
│  │  fluttron_milkdown (Dart Library Layer)                        │  │
│  │  ┌──────────────┐ ┌───────────────┐ ┌──────────────────────┐  │  │
│  │  │ MilkdownEditor│ │MilkdownCtrl   │ │ MilkdownEventBridge  │  │  │
│  │  │ (Widget)      │ │(Controller)   │ │ (Event Stream)       │  │  │
│  │  └──────┬───────┘ └───┬───────────┘ └────────┬─────────────┘  │  │
│  │         │             │                       │                │  │
│  │         ▼             ▼                       ▲                │  │
│  │  FluttronHtmlView   dart:js_interop    FluttronEventBridge     │  │
│  │  (type-driven)      (Dart→JS call)     (JS→Dart stream)       │  │
│  └────────────────────────────────────────────────────────────────┘  │
│              │                                                       │
│              ▼ Browser JS Context (same WebView)                     │
│  ┌────────────────────────────────────────────────────────────────┐  │
│  │  fluttron_milkdown (JS Layer — web/ext/main.js)                │  │
│  │                                                                │  │
│  │  @milkdown/crepe ← CommonMark + GFM + Prism + Slash + History │  │
│  │                                                                │  │
│  │  ┌───────────────────┐  ┌───────────────────────────┐         │  │
│  │  │ View Factory      │  │ Control Channel            │         │  │
│  │  │ fluttronCreate    │  │ window                     │         │  │
│  │  │ MilkdownEditorView│  │  .fluttronMilkdownControl  │         │  │
│  │  └───────────────────┘  └───────────────────────────┘         │  │
│  │  ┌───────────────────┐                                        │  │
│  │  │ Event Emitter      │ → CustomEvent('fluttron.milkdown.*')  │  │
│  │  └───────────────────┘                                        │  │
│  └────────────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────────────┘
```

### 3.2 Directory Structure

```
web_packages/fluttron_milkdown/
├── fluttron_web_package.json        # Asset manifest
├── pubspec.yaml                      # Dart package (fluttron_web_package: true)
├── README.md                         # Package documentation
├── CHANGELOG.md
├── analysis_options.yaml
├── lib/
│   ├── fluttron_milkdown.dart       # Public API barrel export
│   └── src/
│       ├── milkdown_editor.dart     # MilkdownEditor widget
│       ├── milkdown_controller.dart # MilkdownController (programmatic API)
│       ├── milkdown_theme.dart      # MilkdownTheme enum
│       ├── milkdown_events.dart     # Event stream helpers + typed payloads
│       └── milkdown_interop.dart    # dart:js_interop bindings (Dart→JS)
├── frontend/
│   ├── package.json                  # pnpm + esbuild + milkdown deps
│   ├── pnpm-lock.yaml
│   ├── scripts/
│   │   └── build-frontend.mjs       # esbuild bundler script
│   └── src/
│       ├── main.js                   # Entry: factory + control channel + events
│       ├── editor.js                 # Crepe editor lifecycle management
│       ├── themes.js                 # Theme CSS loading/switching
│       └── events.js                 # Event dispatch helpers
├── web/
│   └── ext/
│       ├── main.js                   # Bundled IIFE output (committed)
│       ├── main.js.map
│       ├── main.css                  # Bundled CSS output (committed)
│       └── main.css.map
└── test/
    ├── milkdown_editor_test.dart
    ├── milkdown_controller_test.dart
    └── milkdown_theme_test.dart
```

---

## 4. JS Layer Design

### 4.1 Milkdown Integration — @milkdown/crepe

The playground currently uses `@milkdown/core` + manual plugin assembly. For the reusable library, we adopt `@milkdown/crepe` which:
- Bundles CommonMark, GFM, History, Clipboard, Cursor, Slash, Tooltip, Block by default
- Provides built-in theme support (frame, classic, nord; each with light/dark variants)
- Exposes a simpler API (`new Crepe({...})`) with feature toggles
- Includes Prism-based code highlighting out of the box

**npm dependencies (`frontend/package.json`):**

```json
{
  "name": "fluttron-milkdown-frontend",
  "private": true,
  "packageManager": "pnpm@10.0.0",
  "scripts": {
    "js:build": "node scripts/build-frontend.mjs",
    "js:watch": "node scripts/build-frontend.mjs --watch",
    "js:clean": "node scripts/build-frontend.mjs --clean"
  },
  "dependencies": {
    "@milkdown/crepe": "^7",
    "@milkdown/kit": "^7"
  },
  "devDependencies": {
    "esbuild": "^0.25.0"
  }
}
```

> **Note**: `@milkdown/kit` is included alongside `@milkdown/crepe` for access to low-level APIs needed by the control channel (e.g., `replaceAll` command, `getMarkdown` serializer).

### 4.2 View Factory

**Factory name**: `fluttronCreateMilkdownEditorView`  
**Signature**: `(viewId: number, config: object) => HTMLElement`

Unlike the playground's positional args `(viewId, initialMarkdown)`, the web package uses a **config object** for extensibility:

```javascript
// frontend/src/main.js

const createMilkdownEditorView = (viewId, config) => {
  const options = normalizeConfig(config);
  //   options.initialMarkdown: string
  //   options.theme: 'frame' | 'frame-dark' | 'classic' | 'classic-dark' | 'nord' | 'nord-dark'
  //   options.readonly: boolean

  const container = createEditorContainer(viewId);
  initializeCrepeEditor(viewId, container, options);
  return container;
};

window.fluttronCreateMilkdownEditorView = createMilkdownEditorView;
```

**Config normalization:**

```javascript
const normalizeConfig = (config) => {
  if (typeof config === 'string') {
    // Backward compat: treat string as initialMarkdown
    return { initialMarkdown: config, theme: 'frame', readonly: false };
  }
  if (config == null || typeof config !== 'object') {
    return { initialMarkdown: '', theme: 'frame', readonly: false };
  }
  return {
    initialMarkdown: typeof config.initialMarkdown === 'string' ? config.initialMarkdown : '',
    theme: typeof config.theme === 'string' ? config.theme : 'frame',
    readonly: config.readonly === true,
  };
};
```

### 4.3 Editor Lifecycle Management

```javascript
// frontend/src/editor.js

const editorInstances = new Map(); // viewId → { crepe, container }

const initializeCrepeEditor = async (viewId, container, options) => {
  await destroyEditor(viewId);

  const editorMount = container.querySelector('.fluttron-milkdown__editor-mount');

  const crepe = new Crepe({
    root: editorMount,
    defaultValue: options.initialMarkdown,
    // Feature toggles — all enabled by default with Crepe
  });

  await loadThemeCSS(options.theme);
  await crepe.create();

  if (options.readonly) {
    crepe.setReadonly(true);
  }

  // Listen for content changes
  crepe.on((listener) => {
    listener.markdownUpdated((ctx, markdown, prevMarkdown) => {
      emitEditorChange(viewId, markdown);
    });
  });

  editorInstances.set(viewId, { crepe, container, theme: options.theme });

  emitEditorReady(viewId);
  emitEditorChange(viewId, options.initialMarkdown);
};

const destroyEditor = async (viewId) => {
  const instance = editorInstances.get(viewId);
  if (!instance) return;

  try {
    await instance.crepe.destroy();
  } catch (_) {
    // Ignore destroy errors
  }
  editorInstances.delete(viewId);
};
```

### 4.4 Control Channel (Dart→JS)

A global function `window.fluttronMilkdownControl` enables Dart-side programmatic control:

```javascript
// frontend/src/main.js

window.fluttronMilkdownControl = (viewId, action, params) => {
  const instance = editorInstances.get(viewId);
  if (!instance) {
    return { ok: false, error: `No editor instance for viewId ${viewId}` };
  }

  switch (action) {
    case 'getContent':
      return { ok: true, result: instance.crepe.getMarkdown() };

    case 'setContent':
      instance.crepe.setMarkdown(params?.content ?? '');
      return { ok: true };

    case 'focus':
      instance.crepe.editor.action((ctx) => {
        const view = ctx.get(editorViewCtx);
        view.focus();
      });
      return { ok: true };

    case 'insertText':
      instance.crepe.editor.action((ctx) => {
        const view = ctx.get(editorViewCtx);
        const { state, dispatch } = view;
        const { from } = state.selection;
        dispatch(state.tr.insertText(params?.text ?? '', from));
      });
      return { ok: true };

    case 'setTheme':
      return handleSetTheme(instance, viewId, params?.theme);

    case 'setReadonly':
      instance.crepe.setReadonly(params?.readonly === true);
      return { ok: true };

    default:
      return { ok: false, error: `Unknown action: ${action}` };
  }
};
```

### 4.5 Event Dispatch

```javascript
// frontend/src/events.js

const EVENT_PREFIX = 'fluttron.milkdown.editor';

const emitEditorChange = (viewId, markdown) => {
  window.dispatchEvent(new CustomEvent(`${EVENT_PREFIX}.change`, {
    detail: {
      viewId,
      markdown,
      characterCount: markdown.length,
      lineCount: markdown.split('\n').length,
      updatedAt: new Date().toISOString(),
    },
  }));
};

const emitEditorReady = (viewId) => {
  window.dispatchEvent(new CustomEvent(`${EVENT_PREFIX}.ready`, {
    detail: { viewId },
  }));
};

const emitEditorFocus = (viewId) => {
  window.dispatchEvent(new CustomEvent(`${EVENT_PREFIX}.focus`, {
    detail: { viewId },
  }));
};

const emitEditorBlur = (viewId) => {
  window.dispatchEvent(new CustomEvent(`${EVENT_PREFIX}.blur`, {
    detail: { viewId },
  }));
};
```

### 4.6 Theme Management

```javascript
// frontend/src/themes.js

// All Crepe theme CSS files are imported at build time and toggled at runtime.
// esbuild bundles them into main.css; runtime switching swaps class names on the container.

import '@milkdown/crepe/theme/common/style.css';
import '@milkdown/crepe/theme/frame.css';
import '@milkdown/crepe/theme/frame-dark.css';
import '@milkdown/crepe/theme/classic.css';
import '@milkdown/crepe/theme/classic-dark.css';
import '@milkdown/crepe/theme/nord.css';
import '@milkdown/crepe/theme/nord-dark.css';

const THEME_CLASSES = {
  'frame':         'milkdown-theme-frame',
  'frame-dark':    'milkdown-theme-frame-dark',
  'classic':       'milkdown-theme-classic',
  'classic-dark':  'milkdown-theme-classic-dark',
  'nord':          'milkdown-theme-nord',
  'nord-dark':     'milkdown-theme-nord-dark',
};

const applyTheme = (container, themeName) => {
  // Remove all existing theme classes
  Object.values(THEME_CLASSES).forEach(cls => container.classList.remove(cls));
  // Apply new theme
  const cls = THEME_CLASSES[themeName] || THEME_CLASSES['frame'];
  container.classList.add(cls);
};
```

> **Design decision**: Theme CSS is bundled as a single `main.css` rather than loaded dynamically. This avoids runtime network requests and ensures all themes are immediately available. The trade-off is a slightly larger CSS bundle, but Milkdown's theme files are individually small.

### 4.7 CSS Isolation Strategy

All DOM elements created by `fluttron_milkdown` follow BEM naming with the `fluttron-milkdown` prefix:

```
.fluttron-milkdown                      → Root container
.fluttron-milkdown__editor-mount        → Crepe mount point
.fluttron-milkdown__status              → Status bar
.fluttron-milkdown__status--error       → Error state modifier
.fluttron-milkdown--readonly            → Readonly state modifier
.fluttron-milkdown--theme-frame         → Theme modifier
```

Milkdown's own CSS (via Crepe) uses `.milkdown` prefix and should not leak because the editor is mounted inside our `fluttron-milkdown__editor-mount` container.

### 4.8 esbuild Configuration

```javascript
// frontend/scripts/build-frontend.mjs
// Key esbuild options for milkdown bundling:

function createBuildOptions() {
  return {
    entryPoints: [sourceFile],
    outfile: outputFile,
    bundle: true,
    platform: 'browser',
    format: 'iife',
    target: ['es2020'],
    sourcemap: true,
    logLevel: 'info',
    // CSS extraction — output to web/ext/main.css
    // esbuild handles CSS imports from milkdown automatically
    loader: {
      '.css': 'css',
    },
  };
}
```

> **Risk**: The Milkdown + ProseMirror dependency tree is significantly larger than the playground's manual integration. esbuild should handle it (tree-shaking, dead code elimination), but bundle size needs monitoring. Expected: ~300-500KB JS + ~50-100KB CSS (gzipped: ~80-120KB JS).

---

## 5. Dart Layer Design

### 5.1 Public API (`lib/fluttron_milkdown.dart`)

```dart
library fluttron_milkdown;

export 'src/milkdown_editor.dart';
export 'src/milkdown_controller.dart';
export 'src/milkdown_theme.dart';
export 'src/milkdown_events.dart';
```

### 5.2 MilkdownTheme Enum

```dart
// lib/src/milkdown_theme.dart

/// Available Milkdown themes.
///
/// Each theme has a light and dark variant based on @milkdown/crepe themes.
enum MilkdownTheme {
  /// Modern frame style (light).
  frame('frame'),

  /// Modern frame style (dark).
  frameDark('frame-dark'),

  /// Traditional classic style (light).
  classic('classic'),

  /// Traditional classic style (dark).
  classicDark('classic-dark'),

  /// Nord color palette (light).
  nord('nord'),

  /// Nord color palette (dark).
  nordDark('nord-dark');

  const MilkdownTheme(this.value);

  /// The string value passed to JS layer.
  final String value;
}
```

### 5.3 MilkdownController

```dart
// lib/src/milkdown_controller.dart

import 'dart:async';
import 'milkdown_interop.dart';
import 'milkdown_theme.dart';

/// Controller for programmatically interacting with a MilkdownEditor.
///
/// Create a controller and pass it to [MilkdownEditor]. The controller
/// becomes usable after the editor emits its [MilkdownEditorEvent.ready] event.
class MilkdownController {
  MilkdownController();

  int? _viewId;
  bool _isReady = false;

  /// Whether the editor is initialized and ready for programmatic control.
  bool get isReady => _isReady;

  /// Binds this controller to a specific viewId. Called internally by
  /// [MilkdownEditor] during initialization.
  void attach(int viewId) {
    _viewId = viewId;
    _isReady = true;
  }

  /// Detaches this controller. Called internally during disposal.
  void detach() {
    _viewId = null;
    _isReady = false;
  }

  /// Gets the current markdown content.
  ///
  /// Throws [StateError] if the editor is not ready.
  String getContent() {
    _ensureReady();
    return MilkdownInterop.control(_viewId!, 'getContent', null);
  }

  /// Sets the editor content to [markdown].
  ///
  /// This replaces all existing content.
  void setContent(String markdown) {
    _ensureReady();
    MilkdownInterop.control(_viewId!, 'setContent', {'content': markdown});
  }

  /// Focuses the editor.
  void focus() {
    _ensureReady();
    MilkdownInterop.control(_viewId!, 'focus', null);
  }

  /// Inserts [text] at the current cursor position.
  void insertText(String text) {
    _ensureReady();
    MilkdownInterop.control(_viewId!, 'insertText', {'text': text});
  }

  /// Switches the editor theme at runtime.
  void setTheme(MilkdownTheme theme) {
    _ensureReady();
    MilkdownInterop.control(_viewId!, 'setTheme', {'theme': theme.value});
  }

  /// Sets the editor to readonly mode.
  void setReadonly(bool readonly) {
    _ensureReady();
    MilkdownInterop.control(_viewId!, 'setReadonly', {'readonly': readonly});
  }

  void _ensureReady() {
    if (!_isReady || _viewId == null) {
      throw StateError(
        'MilkdownController is not attached to an active editor. '
        'Wait for MilkdownEditorEvent.ready before calling control methods.',
      );
    }
  }
}
```

### 5.4 MilkdownEditor Widget

```dart
// lib/src/milkdown_editor.dart

import 'package:fluttron_ui/fluttron_ui.dart';
import 'package:flutter/material.dart';
import 'milkdown_controller.dart';
import 'milkdown_theme.dart';

/// A WYSIWYG markdown editor widget powered by Milkdown.
///
/// Usage:
/// ```dart
/// final controller = MilkdownController();
///
/// MilkdownEditor(
///   controller: controller,
///   initialMarkdown: '# Hello',
///   theme: MilkdownTheme.frame,
///   onChanged: (markdown) => print(markdown),
///   onReady: () => print('Editor is ready'),
/// )
/// ```
class MilkdownEditor extends StatefulWidget {
  const MilkdownEditor({
    super.key,
    this.controller,
    this.initialMarkdown = '',
    this.theme = MilkdownTheme.frame,
    this.readonly = false,
    this.onChanged,
    this.onReady,
    this.loadingBuilder,
    this.errorBuilder,
  });

  /// Optional controller for programmatic interaction.
  final MilkdownController? controller;

  /// Initial markdown content.
  final String initialMarkdown;

  /// Editor theme.
  final MilkdownTheme theme;

  /// Whether the editor is readonly.
  final bool readonly;

  /// Called when the markdown content changes.
  final ValueChanged<String>? onChanged;

  /// Called when the editor is fully initialized.
  final VoidCallback? onReady;

  /// Custom loading widget builder.
  final WidgetBuilder? loadingBuilder;

  /// Custom error widget builder.
  final FluttronHtmlViewErrorBuilder? errorBuilder;

  @override
  State<MilkdownEditor> createState() => _MilkdownEditorState();
}

class _MilkdownEditorState extends State<MilkdownEditor> {
  late final FluttronEventBridge _eventBridge;
  StreamSubscription<Map<String, dynamic>>? _changeSubscription;
  StreamSubscription<Map<String, dynamic>>? _readySubscription;

  @override
  void initState() {
    super.initState();
    _eventBridge = FluttronEventBridge();
    _attachListeners();
  }

  @override
  void dispose() {
    _detachListeners();
    _eventBridge.dispose();
    widget.controller?.detach();
    super.dispose();
  }

  void _attachListeners() {
    _changeSubscription = _eventBridge
        .on('fluttron.milkdown.editor.change')
        .listen(_handleChange);
    _readySubscription = _eventBridge
        .on('fluttron.milkdown.editor.ready')
        .listen(_handleReady);
  }

  void _detachListeners() {
    _changeSubscription?.cancel();
    _readySubscription?.cancel();
  }

  void _handleChange(Map<String, dynamic> detail) {
    final String markdown = detail['markdown']?.toString() ?? '';
    widget.onChanged?.call(markdown);
  }

  void _handleReady(Map<String, dynamic> detail) {
    // Controller binding will use viewId from detail when available
    widget.onReady?.call();
  }

  @override
  Widget build(BuildContext context) {
    return FluttronHtmlView(
      type: 'milkdown.editor',
      args: <dynamic>[
        <String, dynamic>{
          'initialMarkdown': widget.initialMarkdown,
          'theme': widget.theme.value,
          'readonly': widget.readonly,
        },
      ],
      loadingBuilder: widget.loadingBuilder,
      errorBuilder: widget.errorBuilder,
    );
  }
}
```

### 5.5 Event Helpers

```dart
// lib/src/milkdown_events.dart

import 'package:fluttron_ui/fluttron_ui.dart';

/// Typed event payload for Milkdown content changes.
class MilkdownChangeEvent {
  const MilkdownChangeEvent({
    required this.markdown,
    required this.characterCount,
    required this.lineCount,
    required this.updatedAt,
  });

  factory MilkdownChangeEvent.fromMap(Map<String, dynamic> map) {
    return MilkdownChangeEvent(
      markdown: map['markdown']?.toString() ?? '',
      characterCount: (map['characterCount'] as num?)?.toInt() ?? 0,
      lineCount: (map['lineCount'] as num?)?.toInt() ?? 0,
      updatedAt: map['updatedAt']?.toString() ?? '',
    );
  }

  final String markdown;
  final int characterCount;
  final int lineCount;
  final String updatedAt;
}

/// Creates a stream of typed [MilkdownChangeEvent] from the raw event bridge.
Stream<MilkdownChangeEvent> milkdownEditorChanges() {
  return FluttronEventBridge()
      .on('fluttron.milkdown.editor.change')
      .map(MilkdownChangeEvent.fromMap);
}
```

### 5.6 JS Interop Layer

```dart
// lib/src/milkdown_interop.dart

// Conditional import for platform safety
import 'milkdown_interop_stub.dart'
    if (dart.library.js_interop) 'milkdown_interop_web.dart'
    as platform;

/// Low-level JS interop for Milkdown control.
abstract final class MilkdownInterop {
  /// Sends a control action to the JS layer.
  ///
  /// Returns the result value from the JS side, or null.
  static dynamic control(int viewId, String action, Map<String, dynamic>? params) {
    return platform.milkdownControl(viewId, action, params);
  }
}
```

```dart
// lib/src/milkdown_interop_web.dart

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

dynamic milkdownControl(int viewId, String action, Map<String, dynamic>? params) {
  final JSObject global = globalContext;
  final JSAny? result = global.callMethodVarArgs<JSAny?>(
    'fluttronMilkdownControl'.toJS,
    <JSAny?>[
      viewId.toJS,
      action.toJS,
      if (params != null) params.jsify() else null,
    ],
  );

  if (result == null) return null;

  final Object? dartResult = result.dartify();
  if (dartResult is Map) {
    if (dartResult['ok'] == true) {
      return dartResult['result'];
    }
    throw StateError(dartResult['error']?.toString() ?? 'Unknown control error');
  }
  return dartResult;
}
```

```dart
// lib/src/milkdown_interop_stub.dart

dynamic milkdownControl(int viewId, String action, Map<String, dynamic>? params) {
  throw UnsupportedError('MilkdownInterop is only available on Flutter Web.');
}
```

---

## 6. Asset Manifest

```json
{
  "$schema": "https://fluttron.dev/schemas/web_package.json",
  "version": "1",
  "viewFactories": [
    {
      "type": "milkdown.editor",
      "jsFactoryName": "fluttronCreateMilkdownEditorView",
      "description": "Milkdown WYSIWYG markdown editor (Crepe)"
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
      "payloadType": "{ viewId: number, markdown: string, characterCount: number, lineCount: number, updatedAt: string }"
    },
    {
      "name": "fluttron.milkdown.editor.ready",
      "direction": "js_to_dart",
      "payloadType": "{ viewId: number }"
    },
    {
      "name": "fluttron.milkdown.editor.focus",
      "direction": "js_to_dart",
      "payloadType": "{ viewId: number }"
    },
    {
      "name": "fluttron.milkdown.editor.blur",
      "direction": "js_to_dart",
      "payloadType": "{ viewId: number }"
    }
  ]
}
```

---

## 7. Programmatic Control — Design Deep Dive

### 7.1 Why a New Pattern is Needed

Fluttron's existing communication model:
- **Dart→Host**: `FluttronClient.invoke()` via WebView bridge handler (for Host services)
- **JS→Dart**: `FluttronEventBridge` via browser `CustomEvent` (unidirectional)
- **Dart→JS (view creation)**: `globalContext.callMethodVarArgs()` for factory invocation

Missing: **Dart→JS runtime control** (calling JS functions after view creation). This is the gap `fluttron_milkdown` surfaces.

### 7.2 Chosen Approach: Direct `globalContext.callMethodVarArgs()`

The simplest pattern that works — JS exposes a global function, Dart calls it directly:

| Aspect | Detail |
|--------|--------|
| JS side | `window.fluttronMilkdownControl(viewId, action, params) → result` |
| Dart side | `globalContext.callMethodVarArgs('fluttronMilkdownControl'.toJS, [...])` |
| Sync/Async | Synchronous (JS→Dart call returns immediately) |
| Error handling | Returns `{ok: false, error: string}` on failure |

### 7.3 ViewId Resolution Challenge

**Problem**: `FluttronHtmlView` uses `platformViewRegistry.registerViewFactory(resolvedViewType, (int viewId) => ...)` — the `viewId` is generated by Flutter's platform view system and is only known inside the factory callback. But our `MilkdownController` needs the `viewId` to send control commands.

**Solution — viewId relay via events**:

1. JS factory receives `viewId` as first argument (existing behavior)
2. JS stores `viewId` in the editor instance map
3. JS emits `fluttron.milkdown.editor.ready` event with `viewId` in detail
4. Dart's `MilkdownEditor._handleReady()` captures `viewId` and calls `controller.attach(viewId)`
5. Controller is now bound and can issue `fluttronMilkdownControl(viewId, ...)` calls

This pattern should be validated carefully — if it works well, it could be upstreamed to `fluttron_ui` as a standard controller binding mechanism.

### 7.4 Fluttron Core Improvement Opportunity

If this pattern proves robust, we should consider adding to `fluttron_ui`:

```dart
/// Base class for Fluttron web view controllers.
abstract class FluttronWebViewController {
  int? _viewId;
  bool get isAttached => _viewId != null;

  @protected
  void attach(int viewId);

  @protected
  void detach();

  @protected
  dynamic callJs(String globalFunctionName, String action, Map<String, dynamic>? params);
}
```

This is a **future backlog item**, not part of this iteration. The `fluttron_milkdown` implementation will be self-contained first, then we evaluate if the pattern generalizes.

---

## 8. Theme Switching — Design Deep Dive

### 8.1 Strategy: All-CSS-Bundled + Class Toggle

Rather than dynamic loading of CSS files (which requires complex async handling and potential FOUC), we bundle all 6 theme CSS files into `main.css` at build time and use CSS class toggling at runtime.

**Pros:**
- Zero latency when switching themes
- No network requests
- Simpler implementation
- Works offline

**Cons:**
- Larger CSS bundle (~100KB total, ~20KB gzipped)
- All theme code loaded even if only one is used

The trade-off is acceptable for an embedded WebView app where the CSS is loaded from local assets.

### 8.2 Implementation: CSS Scoping per Theme

```css
/* Each theme is scoped to a data attribute or class */
.fluttron-milkdown[data-theme="frame"] .milkdown { /* frame overrides */ }
.fluttron-milkdown[data-theme="frame-dark"] .milkdown { /* frame-dark overrides */ }
/* ... */
```

> **Note**: The exact CSS scoping mechanism depends on how @milkdown/crepe's theme system works internally. If Crepe uses top-level CSS custom properties (CSS variables), switching may be as simple as changing variable values on the root container. This needs to be validated during implementation.

### 8.3 Dart-Side Theme Switching

Two approaches:
1. **Constructor parameter** (initial theme): `MilkdownEditor(theme: MilkdownTheme.nord)`
2. **Controller method** (runtime switching): `controller.setTheme(MilkdownTheme.nordDark)`

Both are supported. Constructor changes trigger a widget rebuild, while controller calls update JS directly without Flutter rebuild.

---

## 9. Fluttron Mechanism Validation Checklist

This section lists specific aspects of the Fluttron Web Package mechanism that `fluttron_milkdown` will validate, with expected outcomes and fallback plans.

### 9.1 Checklist

| # | Validation Point | Expected Outcome | Fallback if Fails |
|---|------------------|-------------------|--------------------|
| V1 | Package creation via CLI | `fluttron create --type web_package` produces valid skeleton | Manual creation + CLI bug fix |
| V2 | Large npm dependency bundling | esbuild bundles Milkdown+ProseMirror (~300KB) into single IIFE | Investigate esbuild config: externals, splitting, manual optimization |
| V3 | CSS import bundling | esbuild extracts CSS from `@milkdown/crepe/theme/*.css` into `main.css` | Use esbuild CSS plugin or PostCSS post-processing |
| V4 | `package_config.json` discovery | CLI discovers `fluttron_milkdown` as path dependency | Debug `package_config.json` parsing for edge cases |
| V5 | Asset collection | `web/ext/main.js` + `web/ext/main.css` copied to `build/web/ext/packages/fluttron_milkdown/` | Check collector path resolution |
| V6 | HTML injection | `<script>` and `<link>` tags injected into `build/web/index.html` | Verify placeholder comments exist in template |
| V7 | Registration generation | `registerFluttronWebPackages()` includes `milkdown.editor` type | Check generator output path and import resolution |
| V8 | Factory invocation at runtime | `FluttronHtmlView(type: 'milkdown.editor')` creates a working editor | Debug JS factory invocation chain |
| V9 | Event bridge at runtime | `FluttronEventBridge.on('fluttron.milkdown.editor.change')` receives events | Verify CustomEvent dispatch and detail extraction |
| V10 | Control channel (new pattern) | `globalContext.callMethodVarArgs('fluttronMilkdownControl'.toJS, ...)` works | Test JS function exposure and call semantics |
| V11 | CSS isolation | Milkdown CSS does not leak to app or other packages | Add CSS reset/containment if needed |
| V12 | Full build-run cycle | `fluttron build -p playground` → `run` with milkdown web package | End-to-end debugging |

### 9.2 Mechanism Gaps Anticipated

Based on architectural review, these are areas where the current mechanism may need enhancement:

| Gap | Description | Severity | Solution Path |
|-----|-------------|----------|---------------|
| **Dart→JS control channel** | No fluttron_ui primitive for Dart→JS calls post-view-creation | Medium | Self-contained in this package first; upstream later if pattern stabilizes |
| **ViewId relay** | No standard way for JS view factory to report viewId back to Dart controller | Medium | Use ready event pattern; consider fluttron_ui ControllerMixin for future |
| **Multi-instance isolation** | Multiple MilkdownEditor widgets on same page share global event names | Medium | Include viewId in events for filtering; document single-instance recommendation for v1 |
| **CSS bundle ordering** | HTML injector inserts CSS `<link>` but doesn't guarantee load order vs Milkdown's own styles | Low | Use high-specificity selectors in theme CSS |
| **Build pipeline sequencing** | Web package's own JS must be pre-built before app's `fluttron build` runs | Low | Document: run `pnpm run js:build` in web_package before app build; future: CLI auto-build deps |

---

## 10. Iterative Execution Plan

### Phase 1: Skeleton & Basic Editor (v0042–v0043)

**v0042: Create fluttron_milkdown web package skeleton**
- Use `fluttron create --type web_package` or manual creation in `web_packages/fluttron_milkdown/`
- Set up `pubspec.yaml`, `fluttron_web_package.json`, `analysis_options.yaml`
- Set up `frontend/package.json` with `@milkdown/crepe` + `@milkdown/kit` dependencies
- Create minimal `frontend/src/main.js` with Crepe instantiation (CommonMark only, default theme)
- Run `pnpm install && pnpm run js:build` and verify `web/ext/main.js` + `web/ext/main.css` output
- Dart lib: minimal `MilkdownEditor` widget wrapping `FluttronHtmlView`
- **Acceptance**: `dart analyze` passes, JS builds without error, `web/ext/` contains valid bundles

**v0043: Integrate into playground & validate pipeline**
- Add `fluttron_milkdown` as path dependency in `playground/ui/pubspec.yaml`
- Run `flutter pub get` in `playground/ui/`
- Run `fluttron build -p playground` — validate:
  - Discovery finds `fluttron_milkdown`
  - Assets collected to `build/web/ext/packages/fluttron_milkdown/`
  - HTML injection adds `<script>` + `<link>` tags
  - Registration generated in `ui/lib/generated/web_package_registrations.dart`
- Swap playground's inline milkdown code for `MilkdownEditor` widget from package
- Run the app and verify the editor renders
- **Acceptance**: Full build-run cycle working; editor visible in macOS app

### Phase 2: GFM + Extended Features (v0044)

**v0044: Enable full feature set**
- Enable GFM preset in Crepe config (tables, task lists, strikethrough)
- Enable Prism code highlighting
- Enable History (undo/redo), Slash commands, Tooltip toolbar
- Validate all features render correctly in the WebView
- Monitor JS bundle size; document final bundle metrics
- **Acceptance**: GFM table, task list, code block with highlighting, slash menu, tooltip all working; bundle size documented

### Phase 3: Event Bridge & Change Events (v0045)

**v0045: Rich event system**
- Implement full event dispatch (change, ready, focus, blur)
- Implement `MilkdownChangeEvent` typed payload
- Implement `milkdownEditorChanges()` stream helper
- Wire up `onChanged` and `onReady` callbacks in `MilkdownEditor`
- Test event flow end-to-end in playground
- **Acceptance**: Dart receives typed change events with markdown + character count + line count; ready callback fires on initialization

### Phase 4: Programmatic Control (v0046–v0047)

**v0046: JS control channel**
- Implement `window.fluttronMilkdownControl()` in JS
- Support actions: `getContent`, `setContent`, `focus`, `insertText`, `setReadonly`
- Implement viewId relay via `ready` event
- **Acceptance**: Calling `fluttronMilkdownControl(viewId, 'getContent')` returns current markdown

**v0047: MilkdownController Dart API**
- Implement `MilkdownController` class
- Implement `MilkdownInterop` + platform-conditional imports
- Wire viewId attachment in `MilkdownEditor._handleReady()`
- Add playground UI buttons: "Get Content", "Insert Text", "Toggle Readonly"
- **Acceptance**: Controller methods work; playground demonstrates get/set/focus/insert

### Phase 5: Multi-Theme Support (v0048)

**v0048: Theme switching**
- Bundle all 6 Crepe themes in JS build
- Implement theme switching via `setTheme` control action
- Implement `MilkdownTheme` enum
- Support initial theme via constructor, runtime switching via controller
- Add theme dropdown to playground UI
- **Acceptance**: Switching themes updates editor appearance instantly; no CSS flickering

### Phase 6: Polish & Documentation (v0049–v0050)

**v0049: Tests & validation**
- Write Dart unit tests for controller, theme, events
- Write integration tests validating the complete lifecycle
- Run the Fluttron mechanism validation checklist (§9.1)
- Document any mechanism gaps found
- **Acceptance**: All tests pass; validation checklist completed with results documented

**v0050: Documentation & playground migration**
- Write comprehensive README for `fluttron_milkdown`
- Update playground to fully use `fluttron_milkdown` (remove inline JS milkdown code)
- Update `docs/dev_plan.md` with iteration record
- Create usage guide for website docs
- **Acceptance**: README complete; playground code simplified; dev_plan updated

---

## 11. Playground Migration Plan

The playground currently contains ~150 lines of inline Milkdown JS integration. After `fluttron_milkdown` is complete:

### Before (current playground)

```
playground/ui/
├── frontend/src/main.js           # 150+ lines of Milkdown JS
├── package.json                    # Direct milkdown npm deps
├── lib/main.dart                   # Manual FluttronWebViewRegistry registration
│                                   # Manual FluttronEventBridge wiring
│                                   # Manual state management
```

### After (using fluttron_milkdown)

```
playground/ui/
├── frontend/src/main.js           # Empty or minimal app-specific JS
├── package.json                    # No milkdown deps (handled by web package)
├── lib/main.dart                   # import 'package:fluttron_milkdown/...';
│                                   # MilkdownEditor(
│                                   #   controller: _controller,
│                                   #   theme: MilkdownTheme.frame,
│                                   #   onChanged: (md) => setState(() { ... }),
│                                   # )
```

**Key simplification**: ~200 lines of manual integration → ~20 lines of widget usage.

---

## 12. Risk Analysis

| # | Risk | Probability | Impact | Mitigation |
|---|------|-------------|--------|-----------|
| R1 | esbuild fails to bundle Milkdown+ProseMirror into single IIFE | Low | High | The playground already bundles these deps successfully; Crepe adds more but same pattern |
| R2 | Crepe's CSS conflicts with Flutter Web's generated styles | Medium | Medium | Use CSS containment on the editor container; test in actual WebView early |
| R3 | Multiple editor instances cause event collision | Medium | Medium | Include viewId in all events; filter on Dart side; document limitation |
| R4 | `@milkdown/crepe` API changes in future versions | Low | Medium | Pin `^7` in package.json; document version requirements |
| R5 | Theme CSS bundling increases load time significantly | Low | Low | Monitor bundle size; consider lazy loading in future if > 500KB CSS |
| R6 | viewId relay via events is unreliable (race conditions) | Medium | High | Use synchronous factory return + immediate event; add timeout fallback |
| R7 | Web Package mechanism bugs surface during integration | Medium | Medium | This is intentional — document bugs, fix Fluttron mechanism, iterate |
| R8 | Control channel `globalContext.callMethodVarArgs` fails for complex return types | Low | Medium | Keep return types simple (`{ok, result, error}`); test edge cases |
| R9 | Playground migration breaks existing functionality | Low | High | Keep old playground code on a branch; migrate incrementally |

---

## 13. Bundle Size Budget

| Asset | Expected Size | Gzipped | Budget Limit |
|-------|--------------|---------|--------------|
| `main.js` | 300–500 KB | 80–120 KB | 600 KB |
| `main.css` | 50–100 KB | 15–30 KB | 150 KB |
| **Total** | 350–600 KB | 95–150 KB | 750 KB |

**Reference**: The playground's current Milkdown integration (core + commonmark + listener + nord theme) produces ~200KB JS + ~15KB CSS. Adding Crepe (which includes GFM, slash, tooltip, block, clipboard, cursor, history, and all themes) will increase this.

**Monitoring**: After Phase 1, measure actual bundle size and adjust if needed.

---

## 14. FAQ

### Q: Why not keep milkdown in the playground and skip the web package?

The playground integration works but is not reusable. Any other Fluttron app wanting Milkdown would need to copy ~300 lines of JS + Dart code. The web package turns this into a 1-dependency, 1-widget integration.

### Q: Why @milkdown/crepe instead of @milkdown/kit?

Crepe provides production-ready UX out of the box: floating toolbar, slash menu, block handles, and theme system. Building these from kit would require significant additional JS code and ongoing maintenance. Since we're wrapping for consumers who want a "drop-in" editor, Crepe aligns with that goal.

### Q: Can users customize which plugins are enabled?

Not in v1. Future: expose a `MilkdownEditorConfig` with feature toggles that map to JS-side Crepe feature flags.

### Q: How does multi-instance work?

Each `MilkdownEditor` widget gets a unique `viewId` from Flutter's platform view system. The JS side maintains a `Map<viewId, EditorInstance>`. Events include `viewId` for filtering. However, multi-instance hasn't been extensively tested in Fluttron's WebView context and should be treated as experimental in v1.

### Q: What happens if the web package's JS isn't pre-built?

The CLI's asset validator will detect the missing `web/ext/main.js` file and fail with a clear error message suggesting `cd web_packages/fluttron_milkdown/frontend && pnpm install && pnpm run js:build`. Future: CLI could auto-build web package dependencies.

---

## Document History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 0.1.0-draft | 2026-02-14 | Architecture Team | Initial draft |
