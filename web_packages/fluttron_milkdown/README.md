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

## License

MIT
