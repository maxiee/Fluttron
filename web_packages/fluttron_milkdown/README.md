# fluttron_milkdown

Milkdown WYSIWYG markdown editor as a Fluttron web package.

## Features

- **Milkdown Crepe Editor**: Full-featured WYSIWYG markdown editing
- **CommonMark + GFM**: Support for standard markdown and GitHub Flavored Markdown
- **Code Highlighting**: Prism-based syntax highlighting in code blocks
- **Event System**: `change`, `ready`, `focus`, `blur` events
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
  onChanged: (markdown) => print(markdown),
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
  String initialMarkdown = '',    // Initial markdown content
  bool readonly = false,          // Read-only mode
  ValueChanged<String>? onChanged, // Content change callback
  WidgetBuilder? loadingBuilder,  // Custom loading widget
  FluttronHtmlViewErrorBuilder? errorBuilder, // Custom error widget
})
```

## CSS Isolation

This package uses BEM naming with `fluttron-milkdown` prefix:

- `.fluttron-milkdown` - Root container
- `.fluttron-milkdown__editor-mount` - Editor mount point

## Events

The package emits the following events via `FluttronEventBridge`:

| Event | Payload |
|-------|---------|
| `fluttron.milkdown.editor.change` | `{ viewId, markdown, characterCount, lineCount, updatedAt }` |
| `fluttron.milkdown.editor.ready` | `{ viewId }` |
| `fluttron.milkdown.editor.focus` | `{ viewId }` |
| `fluttron.milkdown.editor.blur` | `{ viewId }` |

## Bundle Metrics

| Asset | Raw Size | Gzipped |
|-------|----------|---------|
| `main.js` | 5.0 MB | 1.16 MB |
| `main.css` | 1.4 MB | 938 KB |
| **Total** | **6.4 MB** | **2.1 MB** |

The bundle includes all Crepe features by default:
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

## License

MIT
