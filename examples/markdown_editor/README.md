# markdown_editor

`markdown_editor` is the production-style Fluttron app example located at
`examples/markdown_editor/`.

## Features

- File tree sidebar (`.md` files only)
- Milkdown WYSIWYG editor with GFM support
- Runtime theme switching (persisted across restarts)
- Save with `Cmd/Ctrl + S`
- Status bar with file name, save status, character/line count

## Structure

- `host/`: Flutter desktop host container
- `ui/`: Flutter Web renderer
- `fluttron.json`: app manifest

## Run

From repository root:

```bash
# Optional: rebuild fluttron_milkdown frontend bundle
cd web_packages/fluttron_milkdown/frontend
pnpm install
pnpm run js:build
cd ../../..

# Build app assets and registrations
dart run packages/fluttron_cli/bin/fluttron.dart build -p examples/markdown_editor

# Run desktop host
cd examples/markdown_editor/host
flutter run -d macos
```
