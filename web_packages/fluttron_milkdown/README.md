# fluttron_milkdown

Milkdown WYSIWYG markdown editor as a Fluttron web package.

## Features

- **Milkdown Crepe Editor**: Full-featured WYSIWYG markdown editing
- **CommonMark + GFM**: Support for standard markdown and GitHub Flavored Markdown
- **Code Highlighting**: Prism-based syntax highlighting in code blocks
- **Event System**: `change`, `ready`, `focus`, `blur` events
- **Multi-Theme Support**: 4 built-in themes with runtime switching
- **Configurable**: Initial markdown, readonly mode, theme support

## Installation

Add to your app's `ui/pubspec.yaml`:

```yaml
dependencies:
  fluttron_milkdown:
    path: ../../web_packages/fluttron_milkdown
```

## Quick Start

```dart
import 'package:fluttron_milkdown/fluttron_milkdown.dart';

MilkdownEditor(
  initialMarkdown: '# Hello World',
  theme: MilkdownTheme.nord,
  onChanged: (event) => print(event.markdown),
)
```

## Build Frontend Assets

Before using this package, build the JavaScript assets:

```bash
cd web_packages/fluttron_milkdown/frontend
pnpm install
pnpm run js:build
```

## API Reference

### MilkdownEditor Widget

```dart
MilkdownEditor({
  MilkdownController? controller,   // Runtime control
  String initialMarkdown = '',      // Initial content
  MilkdownTheme theme = MilkdownTheme.frame,  // Visual theme
  bool readonly = false,            // Read-only mode
  ValueChanged<MilkdownChangeEvent>? onChanged, // Content change callback
  VoidCallback? onReady,            // Editor ready callback
  VoidCallback? onFocus,            // Focus callback
  VoidCallback? onBlur,             // Blur callback
  WidgetBuilder? loadingBuilder,    // Custom loading widget
  FluttronHtmlViewErrorBuilder? errorBuilder, // Custom error widget
})
```

### MilkdownController

```dart
final controller = MilkdownController();

MilkdownEditor(
  controller: controller,
  onReady: () {
    // Controller is ready to use
  },
);

// After ready:
final content = await controller.getContent();
await controller.setContent('# New content');
await controller.focus();
await controller.insertText('text at cursor');
await controller.setReadonly(true);
await controller.setTheme(MilkdownTheme.nordDark);
```

## Themes

4 built-in themes from @milkdown/crepe:

| Theme | Description |
|-------|-------------|
| `MilkdownTheme.frame` | Modern frame style (light) |
| `MilkdownTheme.frameDark` | Modern frame style (dark) |
| `MilkdownTheme.nord` | Nord color palette (light) |
| `MilkdownTheme.nordDark` | Nord color palette (dark) |

Set initial theme:

```dart
MilkdownEditor(
  theme: MilkdownTheme.nordDark,
  ...
)
```

Runtime switching:

```dart
await controller.setTheme(MilkdownTheme.frame);
```

## CSS Isolation

This package uses BEM naming with `fluttron-milkdown` prefix:

- `.fluttron-milkdown` - Root container
- `.fluttron-milkdown__editor-mount` - Editor mount point

## Events

The package emits the following events via `FluttronEventBridge`:

| Event | Payload |
|-------|---------|
| `fluttron.milkdown.editor.change` | `{ viewId, markdown, characterCount, lineCount, updatedAt, instanceToken? }` |
| `fluttron.milkdown.editor.ready` | `{ viewId, instanceToken? }` |
| `fluttron.milkdown.editor.focus` | `{ viewId, instanceToken? }` |
| `fluttron.milkdown.editor.blur` | `{ viewId, instanceToken? }` |

## Bundle Metrics

| Asset | Raw Size | Gzipped |
|-------|----------|---------|
| `main.js` | 5.0 MB | ~1.2 MB |
| `main.css` | 1.5 MB | ~940 KB |
| **Total** | **6.5 MB** | **~2.1 MB** |

The bundle includes:
- All 4 themes (frame, frame-dark, nord, nord-dark)
- **GFM (GitHub Flavored Markdown)**: Tables, task lists, strikethrough
- **Code highlighting**: Prism-based syntax highlighting with CodeMirror
- **Editing experience**: History (undo/redo), slash commands, tooltip toolbar
- **LaTeX**: Mathematical formulas with KaTeX
- **Image support**: Inline and block images

> **Note**: The bundle is larger than a minimal markdown editor because it includes comprehensive language support for CodeMirror and KaTeX fonts. Future versions may offer slim variants with fewer features.

## Feature Configuration

The editor supports feature toggles via the config object (JS layer). All features are enabled by default:

```javascript
// Example: Disable specific features
fluttronCreateMilkdownEditorView(viewId, {
  initialMarkdown: '# Hello',
  features: {
    latex: false,      // Disable LaTeX math support
    imageBlock: false, // Disable image blocks
  }
});
```

Available features:
- `codeMirror` - Code block syntax highlighting
- `listItem` - Bullet/ordered/task lists
- `linkTooltip` - Link tooltips
- `cursor` - Enhanced cursor
- `imageBlock` - Image support
- `blockEdit` - Slash commands, drag-and-drop
- `toolbar` - Formatting toolbar
- `placeholder` - Placeholder text
- `table` - GFM tables
- `latex` - LaTeX math formulas

## Events API (Advanced)

For advanced use cases, you can subscribe to the raw event stream:

```dart
import 'package:fluttron_milkdown/fluttron_milkdown.dart';

// Subscribe to change events from any MilkdownEditor instance
milkdownEditorChanges().listen((event) {
  print('Editor ${event.viewId} changed');
  print('New content: ${event.markdown}');
  print('Character count: ${event.characterCount}');
});
```

## Complete Example

Here's a complete example showing all features:

```dart
import 'package:fluttron_milkdown/fluttron_milkdown.dart';
import 'package:flutter/material.dart';

class MarkdownEditorScreen extends StatefulWidget {
  const MarkdownEditorScreen({super.key});

  @override
  State<MarkdownEditorScreen> createState() => _MarkdownEditorScreenState();
}

class _MarkdownEditorScreenState extends State<MarkdownEditorScreen> {
  final _controller = MilkdownController();
  bool _isReady = false;
  String _content = '';
  MilkdownTheme _theme = MilkdownTheme.nord;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Markdown Editor'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isReady ? _saveContent : null,
          ),
          PopupMenuButton<MilkdownTheme>(
            initialValue: _theme,
            onSelected: (theme) {
              if (_isReady) {
                _controller.setTheme(theme);
                setState(() => _theme = theme);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: MilkdownTheme.frame,
                child: Text('Frame (Light)'),
              ),
              const PopupMenuItem(
                value: MilkdownTheme.frameDark,
                child: Text('Frame (Dark)'),
              ),
              const PopupMenuItem(
                value: MilkdownTheme.nord,
                child: Text('Nord (Light)'),
              ),
              const PopupMenuItem(
                value: MilkdownTheme.nordDark,
                child: Text('Nord (Dark)'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: MilkdownEditor(
              controller: _controller,
              initialMarkdown: '# Hello World\n\nStart editing...',
              theme: _theme,
              onChanged: (event) {
                setState(() => _content = event.markdown);
              },
              onReady: () {
                setState(() => _isReady = true);
              },
            ),
          ),
          if (_content.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text('${_content.length} characters'),
            ),
        ],
      ),
    );
  }

  Future<void> _saveContent() async {
    final content = await _controller.getContent();
    // Save to your storage...
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Content saved!')),
    );
  }
}
```

## FAQ

### Why is the bundle size so large?

The bundle includes:
- All 4 themes (for runtime switching without re-fetching)
- Full CodeMirror language support (syntax highlighting)
- KaTeX fonts for mathematical formulas
- GFM (tables, task lists, strikethrough)
- History, slash commands, and toolbar

For production, consider enabling gzip compression on your server. The gzipped bundle is ~2.1 MB.

### Can I disable specific features?

Yes, at the JS layer you can pass a `features` object:

```javascript
fluttronCreateMilkdownEditorView(viewId, {
  initialMarkdown: '# Hello',
  features: {
    latex: false,      // Disable LaTeX (reduces size)
    imageBlock: false, // Disable image blocks
    toolbar: false,    // Disable formatting toolbar
  }
});
```

Note: This is currently only configurable via direct JS calls. A Dart API for feature configuration may be added in future versions.

### How do I persist markdown content?

Use the `onChanged` callback to capture changes and save to your storage:

```dart
String _savedContent = '';

MilkdownEditor(
  onChanged: (event) {
    _savedContent = event.markdown;
    // Or save to host storage:
    // client.kvSet('markdown', event.markdown);
  },
)
```

To restore content on app restart, load it from storage and pass as `initialMarkdown`.

### Can I have multiple editor instances?

Yes, each `MilkdownEditor` widget gets a unique `viewId`. Events include this `viewId` for filtering:

```dart
MilkdownEditor(
  controller: _controller1,
  onChanged: (event) {
    // event.viewId identifies which instance
  },
)
```

### Why does `controller.getContent()` throw `StateError`?

The controller must be attached before use. Wait for `onReady`:

```dart
final controller = MilkdownController();

MilkdownEditor(
  controller: controller,
  onReady: () {
    // Now controller is safe to use
    controller.getContent();
  },
)
```

### Are classic/classic-dark themes available?

No. The `@milkdown/crepe` package has issues with these themes in v7.x. Only the following 4 themes are supported:
- `frame` / `frameDark`
- `nord` / `nordDark`

### How do I integrate with the Fluttron Host storage?

Use `FluttronClient` from `fluttron_ui`:

```dart
import 'package:fluttron_ui/fluttron_ui.dart';

final _client = FluttronClient();

// Load on startup
final saved = await _client.kvGet('my.markdown');

// Save on change
MilkdownEditor(
  initialMarkdown: saved ?? '',
  onChanged: (event) {
    _client.kvSet('my.markdown', event.markdown);
  },
)
```

## License

MIT
