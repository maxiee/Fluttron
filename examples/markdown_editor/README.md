# Markdown Editor

A production-grade Markdown editor built with [Fluttron](../../README.md).

Screenshot guide: [docs/screenshot.md](./docs/screenshot.md)

## Features

- **Recursive Markdown Discovery** — Scan subdirectories and list all `.md` files
- **WYSIWYG Editing** — Milkdown-powered editor with GFM (GitHub Flavored Markdown) support
- **Syntax Highlighting** — Code blocks with automatic language detection
- **Theme Switching** — 4 built-in themes (Frame, Frame Dark, Nord, Nord Dark)
- **Theme Persistence** — Your theme preference is saved across sessions
- **Keyboard Shortcuts** — `Cmd/Ctrl + S` to save
- **Save As Flow** — Save a new unsaved document with native save dialog
- **Status Bar** — Real-time file name, save status, character count, and line count
- **New File Creation** — Create new markdown files directly in the app
- **Unsaved-Change Protection** — Confirm before replacing unsaved content
- **Error Handling** — Graceful feedback for file operation failures

## Quick Start

### Prerequisites

- [Flutter SDK](https://flutter.dev) (stable channel) with macOS desktop support
- [Node.js](https://nodejs.org) (v18+)
- [pnpm](https://pnpm.io) (via Corepack or direct install)

### Build & Run

From the repository root:

```bash
# 1. (Optional) Rebuild the Milkdown frontend bundle if needed
cd web_packages/fluttron_milkdown/frontend
pnpm install
pnpm run js:build
cd ../../..

# 2. Build the app
dart run packages/fluttron_cli/bin/fluttron.dart build -p examples/markdown_editor

# 3. Run on macOS
cd examples/markdown_editor/host
flutter run -d macos
```

## Usage

### Open a Folder

1. Click **Open Folder** in the toolbar
2. Select a directory containing markdown files
3. The sidebar will display all `.md` files in that directory

### Create a New File

1. Open a folder first
2. Click **New File** in the toolbar
3. Enter a file name (`.md` extension is added automatically)
4. The new file opens in the editor

### Edit and Save

- Edit your markdown content in the WYSIWYG editor
- Press `Cmd+S` (macOS) or `Ctrl+S` (Windows/Linux) to save
- If no file is open yet, Save triggers a native **Save As** dialog
- The status bar shows "Unsaved" when there are pending changes
- Click **Save** button in the toolbar as an alternative

### Switch Themes

1. Click the theme dropdown in the toolbar
2. Select from: Frame, Frame Dark, Nord, Nord Dark
3. Your choice is persisted automatically

## Project Structure

```
examples/markdown_editor/
├── fluttron.json          # App manifest
├── README.md              # This file
├── docs/                  # Screenshot and demo capture notes
├── host/                  # Flutter desktop host
│   ├── lib/main.dart      # Host entry point
│   ├── pubspec.yaml       # Host dependencies
│   └── assets/www/        # Web assets (synced from ui)
└── ui/                    # Flutter Web renderer
    ├── lib/
    │   ├── main.dart      # App entry
    │   ├── app.dart       # Main app widget
    │   ├── models/        # State models
    │   ├── services/      # Service clients
    │   └── widgets/       # UI components
    └── pubspec.yaml       # UI dependencies
```

## Architecture

This app demonstrates the Fluttron architecture:

- **Host Layer** — Native macOS window with WebView container and file system services
- **Renderer Layer** — Flutter Web UI running inside WebView
- **Bridge** — JSON-based IPC between Host and Renderer via JavaScript handlers

### Host Services Used

| Service | Methods | Purpose |
|---------|---------|---------|
| `file.*` | readFile, writeFile, listDirectory, createFile, exists | File system operations |
| `dialog.*` | openDirectory, saveFile | Native folder picker and Save As |
| `storage.*` | kvGet, kvSet | Theme preference persistence |

### Web Packages Used

| Package | Purpose |
|---------|---------|
| `fluttron_milkdown` | WYSIWYG Markdown editor with Milkdown |

## Development

### Rebuild After Changes

```bash
# After UI changes
dart run packages/fluttron_cli/bin/fluttron.dart build -p examples/markdown_editor

# After host changes
cd examples/markdown_editor/host && flutter run -d macos
```

### Run Tests

```bash
# UI tests
cd examples/markdown_editor/ui
flutter test

# Host tests
cd examples/markdown_editor/host
flutter test
```

## License

Part of the Fluttron project. See [../../LICENSE](../../LICENSE) for details.
