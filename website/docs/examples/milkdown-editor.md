# Milkdown Editor

This example demonstrates how to integrate `fluttron_milkdown`, a full-featured WYSIWYG Markdown editor web package, into your Fluttron app.

## Overview

`fluttron_milkdown` is an official Fluttron web package that wraps [Milkdown](https://milkdown.dev/) with the Crepe preset, providing:

- **WYSIWYG editing**: Rich text editing with real-time preview
- **GFM support**: Tables, task lists, strikethrough
- **Code highlighting**: Syntax highlighting with CodeMirror
- **Math formulas**: LaTeX support via KaTeX
- **4 built-in themes**: Runtime switchable without reloading
- **Event system**: Subscribe to content changes, ready, focus, blur events
- **Controller API**: Get/set content, insert text, toggle readonly, change themes

## Current Status

As of `v0050` completion, `fluttron_milkdown` is in production-ready package mode:

- Iteration scope `v0042-v0050` is complete
- Runtime control channel (`get/set/focus/insertText/readonly/theme`) is integrated
- Event payload supports `viewId` and optional `instanceToken` for multi-instance filtering
- Test baseline is `67` passing tests (`theme 27 + controller 18 + events 19 + events_stream 3`)

## Installation

### 1. Add dependency

Add `fluttron_milkdown` to your app's `ui/pubspec.yaml`:

```yaml
dependencies:
  fluttron_milkdown:
    path: ../../web_packages/fluttron_milkdown
```

### 2. Build frontend assets

Navigate to the package and build the JavaScript bundle:

```bash
cd web_packages/fluttron_milkdown/frontend
pnpm install
pnpm run js:build
```

### 3. Install Flutter dependencies

```bash
cd your_app/ui
flutter pub get
```

### 4. Build your app

```bash
cd ..
fluttron build -p .
```

If build output indicates that host `pubspec.yaml` was updated with new package assets, run:

```bash
cd your_app/host
flutter pub get
```

## Basic Usage

### Simple Editor

```dart
import 'package:fluttron_milkdown/fluttron_milkdown.dart';
import 'package:flutter/material.dart';

class MyEditor extends StatelessWidget {
  const MyEditor({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Markdown Editor')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: MilkdownEditor(
          initialMarkdown: '# Hello World\n\nStart editing...',
          onChanged: (event) {
            print('Content changed: ${event.markdown.length} chars');
          },
        ),
      ),
    );
  }
}
```

### With Controller

Use `MilkdownController` for runtime control:

```dart
import 'package:fluttron_milkdown/fluttron_milkdown.dart';
import 'package:flutter/material.dart';

class ControlledEditor extends StatefulWidget {
  const ControlledEditor({super.key});

  @override
  State<ControlledEditor> createState() => _ControlledEditorState();
}

class _ControlledEditorState extends State<ControlledEditor> {
  final _controller = MilkdownController();
  bool _isReady = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editor'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isReady ? _save : null,
          ),
        ],
      ),
      body: MilkdownEditor(
        controller: _controller,
        onReady: () => setState(() => _isReady = true),
      ),
    );
  }

  Future<void> _save() async {
    final content = await _controller.getContent();
    // Save to storage...
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saved!')),
      );
    }
  }
}
```

### Theme Switching

```dart
class ThemedEditor extends StatefulWidget {
  const ThemedEditor({super.key});

  @override
  State<ThemedEditor> createState() => _ThemedEditorState();
}

class _ThemedEditorState extends State<ThemedEditor> {
  final _controller = MilkdownController();
  MilkdownTheme _theme = MilkdownTheme.nord;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Themed Editor'),
        actions: [
          IconButton(
            icon: const Icon(Icons.dark_mode),
            onPressed: _toggleTheme,
          ),
        ],
      ),
      body: MilkdownEditor(
        controller: _controller,
        theme: _theme,
        onReady: () {},
      ),
    );
  }

  Future<void> _toggleTheme() async {
    final newTheme = _theme.isDark
        ? _theme.lightVariant
        : _theme.darkVariant;
    await _controller.setTheme(newTheme);
    setState(() => _theme = newTheme);
  }
}
```

## Available Themes

| Theme | Description |
|-------|-------------|
| `MilkdownTheme.frame` | Modern frame style (light) |
| `MilkdownTheme.frameDark` | Modern frame style (dark) |
| `MilkdownTheme.nord` | Nord color palette (light) |
| `MilkdownTheme.nordDark` | Nord color palette (dark) |

## Controller API

| Method | Description |
|--------|-------------|
| `getContent()` | Get current markdown content |
| `setContent(text)` | Replace entire content |
| `focus()` | Focus the editor |
| `insertText(text)` | Insert text at cursor position |
| `setReadonly(bool)` | Toggle readonly mode |
| `setTheme(theme)` | Change visual theme |

## Events

Subscribe to editor events:

```dart
MilkdownEditor(
  onChanged: (event) {
    // event.markdown, event.characterCount, event.lineCount
  },
  onReady: () {
    // Editor is ready, controller attached
  },
  onFocus: () {
    // Editor gained focus
  },
  onBlur: () {
    // Editor lost focus
  },
)
```

### Event Payload

| Event | Payload |
|-------|---------|
| `fluttron.milkdown.editor.change` | `{ viewId, markdown, characterCount, lineCount, updatedAt, instanceToken? }` |
| `fluttron.milkdown.editor.ready` | `{ viewId, instanceToken? }` |
| `fluttron.milkdown.editor.focus` | `{ viewId, instanceToken? }` |
| `fluttron.milkdown.editor.blur` | `{ viewId, instanceToken? }` |

### Advanced Filtering (Raw Stream)

For advanced scenarios, use stream helpers with explicit filters:

```dart
import 'package:fluttron_milkdown/fluttron_milkdown.dart';

void bindEditorEvents() {
  milkdownEditorChanges(
    viewId: 7,
    instanceToken: 'editor-token-7',
  ).listen((event) {
    // Only events matching both filters reach here.
    print(event.markdown);
  });
}
```

## Bundle Size

The package includes comprehensive features:

| Asset | Raw Size | Gzipped |
|-------|----------|---------|
| `main.js` | ~5.0 MB | ~1.2 MB |
| `main.css` | ~1.5 MB | ~940 KB |

> **Note**: Enable gzip compression on your server for optimal loading performance.

## More Information

- Package README: `web_packages/fluttron_milkdown/README.md`
- Design Document: `docs/feature/fluttron_milkdown_design.md`
- Validation Report: `docs/feature/fluttron_milkdown_validation.md`
