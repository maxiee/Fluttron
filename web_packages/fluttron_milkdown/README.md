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
| `fluttron.milkdown.editor.change` | `{ viewId, markdown, characterCount, lineCount, updatedAt }` |
| `fluttron.milkdown.editor.ready` | `{ viewId }` |
| `fluttron.milkdown.editor.focus` | `{ viewId }` |
| `fluttron.milkdown.editor.blur` | `{ viewId }` |

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

## License

MIT
