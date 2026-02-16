# markdown_editor — Technical Design Document

**Version:** 0.1.0-draft  
**Date:** 2026-02-16  
**Status:** Draft  
**Author:** Fluttron Architecture Team

---

## 1. Executive Summary

### 1.1 What

`markdown_editor` is a production-grade Markdown editor application built entirely on Fluttron, located at `examples/markdown_editor/`. It demonstrates the full capability of the Fluttron platform — from native Host services to Web Package composition — in a real, shippable desktop application.

### 1.2 Why

This project serves a **triple purpose**:

1. **Production proof**: Prove to the outside world that Fluttron is capable of delivering production-quality desktop applications, not just toy demos.
2. **Framework co-evolution**: Surface real-world gaps in Fluttron's infrastructure (Host services, CLI, build pipeline) and fix them as part of this iteration, so the framework matures alongside the app.
3. **Best-practice showcase**: Serve as the canonical "this is how you build a Fluttron app" reference, replacing the playground as the primary demonstration vehicle.

### 1.3 Scope Overview

| Dimension | Decision |
|-----------|----------|
| App type | Full Fluttron app (host + ui) |
| Location | `examples/markdown_editor/` |
| Creation method | `fluttron create` CLI |
| Editor engine | `fluttron_milkdown` web package (already shipped) |
| File management | Sidebar file tree + open/save/new |
| Host services needed | FileService, DialogService, ClipboardService (NEW) |
| Theme support | Runtime switching via `MilkdownController` |
| Status bar | Character count, line count, file path, save status |
| Target platform | macOS Desktop (primary), other platforms future |

---

## 2. Goals & Success Criteria

### 2.1 Product Goals

| # | Goal | Measurable Criteria |
|---|------|---------------------|
| G1 | Production-quality Markdown editor | A non-technical user can open, edit, save `.md` files without encountering framework-level issues |
| G2 | File management | Sidebar lists files in a user-chosen directory; user can create, open, rename, delete `.md` files |
| G3 | System integration | File open/save dialogs use native OS picker (macOS `NSOpenPanel` / `NSSavePanel`) |
| G4 | Clipboard integration | Copy/paste markdown content works with system clipboard |
| G5 | Theme switching | User can switch between Milkdown themes at runtime, preference persisted |
| G6 | Status bar | Always-visible status bar shows: file name, save status (dirty/clean), character count, line count |
| G7 | Auto-save (stretch) | Optional auto-save with configurable interval |

### 2.2 Framework Evolution Goals

| # | Goal | What we evolve in Fluttron |
|---|------|---------------------------|
| F1 | FileService | New built-in Host service in `fluttron_host` for file read/write/list/stat |
| F2 | DialogService | New built-in Host service for native file picker dialogs |
| F3 | ClipboardService | New built-in Host service for system clipboard read/write |
| F4 | CLI `--template` for examples | Validate `fluttron create` works cleanly for `examples/` directory |
| F5 | Host service extension pattern | Establish the pattern for adding built-in services to `fluttron_host` |
| F6 | UI state management reference | Demonstrate the recommended state management pattern in a real app |

### 2.3 Non-Goals (Explicit)

- Collaborative editing (yjs) — out of scope
- Image upload / drag-and-drop media — out of scope for v1
- Multiple simultaneous editor tabs — out of scope for v1 (stretch goal)
- Custom Milkdown plugins — out of scope
- Mobile platform support — desktop-first, no mobile testing
- Markdown source view / split view — WYSIWYG only for v1
- Export to PDF/HTML — out of scope for v1
- Search & replace within editor — out of scope for v1
- pub.dev distribution — `fluttron_milkdown` remains path/git dependency

---

## 3. Architecture Overview

### 3.1 System Diagram

```
┌──────────────────────────────────────────────────────────────────────────┐
│                    examples/markdown_editor/                             │
│                                                                          │
│  ┌─────────────────────────────────────┐                                │
│  │           Host (Flutter macOS)       │                                │
│  │                                     │                                │
│  │  ┌───────────────────────────────┐  │                                │
│  │  │  Built-in Services            │  │                                │
│  │  │  ├─ platform.*               │  │  (existing)                    │
│  │  │  ├─ kv.*                     │  │  (existing)                    │
│  │  │  ├─ file.*                   │  │  (NEW — F1)                    │
│  │  │  ├─ dialog.*                 │  │  (NEW — F2)                    │
│  │  │  └─ clipboard.*             │  │  (NEW — F3)                    │
│  │  └───────────────────────────────┘  │                                │
│  │                │                     │                                │
│  │           WebView Bridge             │                                │
│  │                │                     │                                │
│  └────────────────┼────────────────────┘                                │
│                   │                                                      │
│  ┌────────────────┼────────────────────┐                                │
│  │           UI (Flutter Web)          │                                │
│  │                │                     │                                │
│  │  ┌─────────────┴──────────────────┐ │                                │
│  │  │        App Shell               │ │                                │
│  │  │  ┌──────────┐ ┌────────────┐   │ │                                │
│  │  │  │ Sidebar   │ │ Editor     │   │ │                                │
│  │  │  │ (File    │ │ (Milkdown  │   │ │                                │
│  │  │  │  Tree)   │ │  Widget)   │   │ │                                │
│  │  │  └──────────┘ └────────────┘   │ │                                │
│  │  │  ┌─────────────────────────┐   │ │                                │
│  │  │  │ Status Bar              │   │ │                                │
│  │  │  │ (file · chars · lines)  │   │ │                                │
│  │  │  └─────────────────────────┘   │ │                                │
│  │  └────────────────────────────────┘ │                                │
│  │                                     │                                │
│  │  Web Packages:                      │                                │
│  │  └─ fluttron_milkdown              │                                │
│  └─────────────────────────────────────┘                                │
│                                                                          │
│  fluttron.json                                                           │
└──────────────────────────────────────────────────────────────────────────┘
```

### 3.2 Directory Structure

```
examples/markdown_editor/
├── fluttron.json                         # App manifest
├── README.md                             # App README
├── host/
│   ├── pubspec.yaml                      # Depends on fluttron_host
│   ├── lib/
│   │   └── main.dart                     # runFluttronHost()
│   ├── assets/www/                       # Synced from ui/build/web/
│   ├── macos/
│   └── test/
├── ui/
│   ├── pubspec.yaml                      # Depends on fluttron_ui + fluttron_milkdown
│   ├── lib/
│   │   ├── main.dart                     # Entry point
│   │   ├── app.dart                      # App shell layout
│   │   ├── generated/
│   │   │   └── web_package_registrations.dart  # Auto-generated
│   │   ├── models/
│   │   │   ├── editor_state.dart         # Editor state model
│   │   │   └── file_entry.dart           # File/directory model
│   │   ├── services/
│   │   │   ├── file_service_client.dart  # Wraps FluttronClient file.* calls
│   │   │   ├── dialog_service_client.dart
│   │   │   └── clipboard_service_client.dart
│   │   └── widgets/
│   │       ├── sidebar.dart              # File tree sidebar
│   │       ├── editor_area.dart          # MilkdownEditor wrapper
│   │       ├── status_bar.dart           # Bottom status bar
│   │       ├── toolbar.dart              # Top toolbar (theme, actions)
│   │       └── file_tree_item.dart       # Individual file tree node
│   ├── frontend/src/                     # Empty or minimal (no custom JS needed)
│   ├── web/
│   │   └── index.html
│   └── test/
└── test/
    └── integration/                      # End-to-end tests
```

### 3.3 Data Flow

```
User clicks "Open Folder"
  → UI: calls FluttronClient.invoke('dialog.openDirectory', {})
  → Host: DialogService opens native macOS directory picker
  → Host: returns selected path
  → UI: calls FluttronClient.invoke('file.listDirectory', { path: ... })
  → Host: FileService lists directory contents
  → Host: returns file entries
  → UI: renders file tree in sidebar

User clicks a .md file in sidebar
  → UI: calls FluttronClient.invoke('file.readFile', { path: ... })
  → Host: FileService reads file contents
  → Host: returns markdown string
  → UI: calls MilkdownController.setContent(markdown)
  → Editor: renders markdown in WYSIWYG mode

User edits content and presses Cmd+S
  → UI: MilkdownController.getContent() retrieves markdown
  → UI: calls FluttronClient.invoke('file.writeFile', { path: ..., content: ... })
  → Host: FileService writes file to disk
  → UI: status bar updates to "Saved"
```

---

## 4. Framework Evolution — New Host Services

This section details the new services that must be added to `fluttron_host` as part of this iteration. Each service is a self-contained evolution task.

### 4.1 FileService (`file.*`)

**Namespace:** `file`

| Method | Signature | Description |
|--------|-----------|-------------|
| `file.readFile` | `{ path: string }` → `{ content: string }` | Read file as UTF-8 string |
| `file.writeFile` | `{ path: string, content: string }` → `{}` | Write UTF-8 string to file |
| `file.listDirectory` | `{ path: string }` → `{ entries: FileEntry[] }` | List directory contents |
| `file.stat` | `{ path: string }` → `{ exists: bool, isFile: bool, isDirectory: bool, size: int, modified: string }` | Get file/directory stats |
| `file.createFile` | `{ path: string, content?: string }` → `{}` | Create new file with optional content |
| `file.delete` | `{ path: string }` → `{}` | Delete file or empty directory |
| `file.rename` | `{ oldPath: string, newPath: string }` → `{}` | Rename/move file |
| `file.exists` | `{ path: string }` → `{ exists: bool }` | Check if path exists |

**FileEntry type:**

```dart
class FileEntry {
  final String name;
  final String path;
  final bool isFile;
  final bool isDirectory;
  final int size; // bytes, 0 for directories
  final String modified; // ISO 8601
}
```

**Security considerations:**
- No path traversal protection in v1 (trusted desktop app context)
- Future: configurable sandbox / allowed paths list

**Implementation location:** `packages/fluttron_host/lib/src/services/file_service.dart`

**Registration:**

```dart
// In fluttron_host's service init
registry.register('file', FileService());
```

### 4.2 DialogService (`dialog.*`)

**Namespace:** `dialog`

| Method | Signature | Description |
|--------|-----------|-------------|
| `dialog.openFile` | `{ title?: string, allowedExtensions?: string[], initialDirectory?: string }` → `{ path?: string }` | Single file picker |
| `dialog.openFiles` | `{ title?: string, allowedExtensions?: string[], initialDirectory?: string }` → `{ paths: string[] }` | Multiple file picker |
| `dialog.openDirectory` | `{ title?: string, initialDirectory?: string }` → `{ path?: string }` | Directory picker |
| `dialog.saveFile` | `{ title?: string, defaultFileName?: string, allowedExtensions?: string[], initialDirectory?: string }` → `{ path?: string }` | Save file dialog |

**macOS implementation approach:**

Use `file_selector` package (Flutter team official) or raw `NSOpenPanel` via MethodChannel. Prefer `file_selector` for cross-platform readiness:

```yaml
# packages/fluttron_host/pubspec.yaml
dependencies:
  file_selector: ^1.0.0
```

**Return convention:** Returns `{ path: null }` when user cancels the dialog (not an error).

**Implementation location:** `packages/fluttron_host/lib/src/services/dialog_service.dart`

### 4.3 ClipboardService (`clipboard.*`)

**Namespace:** `clipboard`

| Method | Signature | Description |
|--------|-----------|-------------|
| `clipboard.getText` | `{}` → `{ text?: string }` | Read text from system clipboard |
| `clipboard.setText` | `{ text: string }` → `{}` | Write text to system clipboard |
| `clipboard.hasText` | `{}` → `{ hasText: bool }` | Check if clipboard has text content |

**Implementation approach:**

Use Flutter's built-in `Clipboard` class from `services.dart`:

```dart
import 'package:flutter/services.dart';

class ClipboardService extends FluttronService {
  @override
  String get namespace => 'clipboard';

  @override
  Future<Map<String, dynamic>> handle(String method, Map<String, dynamic> params) async {
    switch (method) {
      case 'getText':
        final data = await Clipboard.getData(Clipboard.kTextPlain);
        return {'text': data?.text};
      case 'setText':
        await Clipboard.setData(ClipboardData(text: params['text'] as String));
        return {};
      case 'hasText':
        final data = await Clipboard.getData(Clipboard.kTextPlain);
        return {'hasText': data?.text != null && data!.text!.isNotEmpty};
      default:
        throw FluttronError(code: 'METHOD_NOT_FOUND', message: 'Unknown method: $method');
    }
  }
}
```

**Implementation location:** `packages/fluttron_host/lib/src/services/clipboard_service.dart`

### 4.4 Service Registration Pattern

The current `fluttron_host` registers `PlatformService` and `KvService`. New services follow the same pattern:

```dart
// packages/fluttron_host/lib/src/host_app.dart (or equivalent)

void _registerServices(ServiceRegistry registry) {
  registry.register('platform', PlatformService());  // existing
  registry.register('kv', KvService());               // existing
  registry.register('file', FileService());            // NEW
  registry.register('dialog', DialogService());        // NEW
  registry.register('clipboard', ClipboardService()); // NEW
}
```

This establishes the pattern for any future built-in services.

---

## 5. UI Design

### 5.1 Layout Structure

```
┌─────────────────────────────────────────────────────┐
│  Toolbar                                            │
│  [📁 Open Folder] [📄 New] [💾 Save]  [Theme ▾]    │
├──────────────┬──────────────────────────────────────┤
│              │                                      │
│  Sidebar     │  Editor Area                         │
│  (File Tree) │  (MilkdownEditor)                    │
│              │                                      │
│  📁 docs/    │  # My Document                       │
│   📄 readme  │                                      │
│   📄 notes   │  Welcome to the **markdown editor**. │
│  📁 blog/    │                                      │
│   📄 post1   │  - Item 1                            │
│   📄 post2   │  - Item 2                            │
│              │                                      │
│              │                                      │
├──────────────┴──────────────────────────────────────┤
│  Status Bar                                         │
│  readme.md  ·  Saved  ·  1,234 chars  ·  42 lines   │
└─────────────────────────────────────────────────────┘
```

### 5.2 Toolbar

| Element | Action |
|---------|--------|
| Open Folder | `dialog.openDirectory` → load file tree |
| New File | Prompt file name → `file.createFile` |
| Save (Cmd+S) | `file.writeFile` with current editor content |
| Theme dropdown | Switch MilkdownTheme at runtime |

### 5.3 Sidebar (File Tree)

- Displays `.md` files in the opened directory (recursive, limited depth)
- Click to open a file in the editor
- Currently editing file highlighted
- Unsaved changes indicated with a dot/icon
- Right-click context menu: Rename, Delete (stretch)
- Collapsible subdirectories

### 5.4 Editor Area

- Full `MilkdownEditor` from `fluttron_milkdown` package
- WYSIWYG editing with GFM, code highlighting, slash commands, tooltip toolbar
- Controlled via `MilkdownController`
- Fills remaining space (flexible layout)

### 5.5 Status Bar

| Segment | Data source |
|---------|-------------|
| File name | Current open file path (basename) |
| Save status | "Saved" / "Unsaved" based on dirty flag |
| Character count | From `MilkdownChangeEvent.characterCount` |
| Line count | From `MilkdownChangeEvent.lineCount` |

---

## 6. State Management

### 6.1 Editor State Model

```dart
class EditorState {
  final String? currentFilePath;    // null = no file open
  final String? currentDirectoryPath; // null = no folder opened
  final String currentContent;       // current markdown in editor
  final String savedContent;         // last saved version (for dirty check)
  final bool isDirty;               // currentContent != savedContent
  final int characterCount;
  final int lineCount;
  final MilkdownTheme currentTheme;
  final bool isLoading;
  final String? errorMessage;
  final List<FileEntry> fileTree;   // current directory listing
}
```

### 6.2 State Flow

```
App Start
  → EditorState(currentFilePath: null, currentDirectoryPath: null, ...)
  → Show empty editor with welcome markdown

Open Folder
  → Update currentDirectoryPath
  → Load file tree
  → Show sidebar

Open File
  → Read file content from Host
  → setContent on MilkdownController
  → Update currentFilePath, savedContent
  → isDirty = false

Edit Content (onChanged callback)
  → Update currentContent, characterCount, lineCount
  → isDirty = currentContent != savedContent

Save (Cmd+S)
  → Write currentContent to Host file
  → savedContent = currentContent
  → isDirty = false

New File
  → Prompt name
  → Create file on Host
  → Open the new file in editor
```

### 6.3 Pattern Choice

Use `StatefulWidget` + `setState` for v1.  This is the simplest approach and sufficient for a single-view app. If the app evolves to multi-tab, reconsider with `ChangeNotifier` / `Riverpod`.

---

## 7. UI ↔ Host Communication

### 7.1 Service Client Wrappers

Thin Dart wrappers around `FluttronClient.invoke()` calls for type safety in the UI:

```dart
// ui/lib/services/file_service_client.dart

class FileServiceClient {
  final FluttronClient _client;

  FileServiceClient(this._client);

  Future<String> readFile(String path) async {
    final result = await _client.invoke('file.readFile', {'path': path});
    return result['content'] as String;
  }

  Future<void> writeFile(String path, String content) async {
    await _client.invoke('file.writeFile', {'path': path, 'content': content});
  }

  Future<List<FileEntry>> listDirectory(String path) async {
    final result = await _client.invoke('file.listDirectory', {'path': path});
    final entries = result['entries'] as List<dynamic>;
    return entries.map((e) => FileEntry.fromMap(e as Map<String, dynamic>)).toList();
  }

  Future<void> createFile(String path, {String content = ''}) async {
    await _client.invoke('file.createFile', {'path': path, 'content': content});
  }

  Future<void> deleteFile(String path) async {
    await _client.invoke('file.delete', {'path': path});
  }

  Future<void> rename(String oldPath, String newPath) async {
    await _client.invoke('file.rename', {'oldPath': oldPath, 'newPath': newPath});
  }
}
```

```dart
// ui/lib/services/dialog_service_client.dart

class DialogServiceClient {
  final FluttronClient _client;

  DialogServiceClient(this._client);

  Future<String?> openDirectory({String? title}) async {
    final result = await _client.invoke('dialog.openDirectory', {
      if (title != null) 'title': title,
    });
    return result['path'] as String?;
  }

  Future<String?> openFile({
    String? title,
    List<String>? allowedExtensions,
  }) async {
    final result = await _client.invoke('dialog.openFile', {
      if (title != null) 'title': title,
      if (allowedExtensions != null) 'allowedExtensions': allowedExtensions,
    });
    return result['path'] as String?;
  }

  Future<String?> saveFile({
    String? title,
    String? defaultFileName,
    List<String>? allowedExtensions,
  }) async {
    final result = await _client.invoke('dialog.saveFile', {
      if (title != null) 'title': title,
      if (defaultFileName != null) 'defaultFileName': defaultFileName,
      if (allowedExtensions != null) 'allowedExtensions': allowedExtensions,
    });
    return result['path'] as String?;
  }
}
```

```dart
// ui/lib/services/clipboard_service_client.dart

class ClipboardServiceClient {
  final FluttronClient _client;

  ClipboardServiceClient(this._client);

  Future<String?> getText() async {
    final result = await _client.invoke('clipboard.getText', {});
    return result['text'] as String?;
  }

  Future<void> setText(String text) async {
    await _client.invoke('clipboard.setText', {'text': text});
  }
}
```

---

## 8. Creation Workflow

### 8.1 Using `fluttron create`

```bash
cd /path/to/Fluttron
fluttron create examples/markdown_editor --name markdown_editor
```

This creates the standard app scaffold. Then manually:

1. Add `fluttron_milkdown` dependency to `ui/pubspec.yaml`
2. Develop the UI code in `ui/lib/`
3. No custom JS needed — all editor functionality comes from `fluttron_milkdown`

### 8.2 Build & Run

```bash
# 1. Ensure fluttron_milkdown frontend is built
cd web_packages/fluttron_milkdown/frontend
pnpm install && pnpm run js:build
cd ../../..

# 2. Build the app
fluttron build -p examples/markdown_editor

# 3. Run on macOS
cd examples/markdown_editor/host
flutter run -d macos
```

### 8.3 fluttron.json

```json
{
  "name": "markdown_editor",
  "version": "0.1.0",
  "entry": {
    "uiProjectPath": "ui",
    "hostAssetPath": "host/assets/www",
    "index": "index.html"
  },
  "window": {
    "title": "Markdown Editor",
    "width": 1280,
    "height": 800,
    "resizable": true
  }
}
```

---

## 9. Fluttron Framework Evolution Tasks

Each framework improvement is listed as an independent sub-task, ordered by dependency. These are tracked separately from the App feature tasks.

### F1: FileService — Add to `fluttron_host`

| Aspect | Detail |
|--------|--------|
| **Package** | `packages/fluttron_host` |
| **Files** | `lib/src/services/file_service.dart` |
| **Methods** | `readFile`, `writeFile`, `listDirectory`, `stat`, `createFile`, `delete`, `rename`, `exists` |
| **Registration** | Add to `ServiceRegistry` in host init |
| **Tests** | Unit tests for each method; integration test with Host bridge |
| **Dependency** | None (can start immediately) |
| **Acceptance** | From UI code: `FluttronClient.invoke('file.readFile', {'path': '/tmp/test.md'})` returns file content |

### F2: DialogService — Add to `fluttron_host`

| Aspect | Detail |
|--------|--------|
| **Package** | `packages/fluttron_host` |
| **Files** | `lib/src/services/dialog_service.dart` |
| **Dependencies** | `file_selector` package (or equivalent) |
| **Methods** | `openFile`, `openFiles`, `openDirectory`, `saveFile` |
| **Platform** | macOS only for v1 |
| **Tests** | Unit test for param validation; manual test for dialog display |
| **Dependency** | None (can start immediately) |
| **Acceptance** | Native macOS file/directory picker appears when called from UI |

### F3: ClipboardService — Add to `fluttron_host`

| Aspect | Detail |
|--------|--------|
| **Package** | `packages/fluttron_host` |
| **Files** | `lib/src/services/clipboard_service.dart` |
| **Methods** | `getText`, `setText`, `hasText` |
| **Tests** | Unit test with mock clipboard |
| **Dependency** | None (can start immediately) |
| **Acceptance** | From UI: copy/paste text works with system clipboard |

### F4: Service Registration Documentation

| Aspect | Detail |
|--------|--------|
| **Package** | `packages/fluttron_host` |
| **Deliverable** | README update + code comments documenting how to add custom services |
| **Pattern** | Demonstrate `ServiceRegistry.register()` + `FluttronService` base class |
| **Dependency** | After F1-F3 complete |

### F5: CLI Validation for `examples/`

| Aspect | Detail |
|--------|--------|
| **Package** | `packages/fluttron_cli` |
| **Deliverable** | Verify `fluttron create` + `fluttron build` works with `examples/markdown_editor` path |
| **Test** | `fluttron build -p examples/markdown_editor` succeeds end-to-end |
| **Risk** | Path resolution for web package dependencies (relative paths from `examples/` to `web_packages/`) |
| **Dependency** | After app scaffold created |

### F6: fluttron_shared — FileEntry Model (Optional)

| Aspect | Detail |
|--------|--------|
| **Package** | `packages/fluttron_shared` |
| **Deliverable** | `FileEntry` model class shared between Host and UI |
| **Rationale** | Ensures type-safe serialization across bridge |
| **Dependency** | Before or alongside F1 |

---

## 10. Iterative Execution Plan

### Phase 1: Scaffold & Framework Services (v0051–v0053)

**v0051: Framework — FileService**

*Framework sub-task — independent of App code*

- Implement `FileService` in `packages/fluttron_host/lib/src/services/file_service.dart`
- Register in Host service init
- Methods: `readFile`, `writeFile`, `listDirectory`, `stat`, `createFile`, `delete`, `rename`, `exists`
- Add `FileEntry` model to `fluttron_shared` (or keep Host-local)
- Unit tests for all methods
- **Acceptance**: `FluttronClient.invoke('file.readFile', {'path': '/tmp/test.md'})` returns file content in playground

**v0052: Framework — DialogService + ClipboardService**

*Framework sub-task — independent of App code*

- Implement `DialogService` in `packages/fluttron_host/lib/src/services/dialog_service.dart`
- Implement `ClipboardService` in `packages/fluttron_host/lib/src/services/clipboard_service.dart`
- Add `file_selector` (or equivalent) dependency for native dialogs
- Register both in Host service init
- Unit tests + manual macOS dialog test
- **Acceptance**: Native macOS open/save dialogs appear; clipboard read/write works

**v0053: App Scaffold + Editor Integration**

- Run `fluttron create examples/markdown_editor --name markdown_editor`
- Add `fluttron_milkdown` as path dependency in `ui/pubspec.yaml`
- Implement minimal `main.dart` with `MilkdownEditor` widget
- Verify `fluttron build -p examples/markdown_editor` works end-to-end
- App opens with a working Milkdown editor (no sidebar yet)
- **Acceptance**: `flutter run -d macos` shows the app with a working editor; build pipeline discovers `fluttron_milkdown` and injects assets

### Phase 2: File Management (v0054–v0056)

**v0054: Open Folder + File Tree Sidebar**

- Implement `DialogServiceClient` in UI
- Implement `FileServiceClient` in UI
- Implement Sidebar widget with file tree (`.md` files only)
- Toolbar "Open Folder" button → native directory picker → populate sidebar
- **Acceptance**: User can open a folder and see `.md` files in the sidebar

**v0055: Open File in Editor**

- Click file in sidebar → `FileServiceClient.readFile()` → `MilkdownController.setContent()`
- Track `currentFilePath` and `savedContent` in state
- Highlight currently active file in sidebar
- **Acceptance**: Clicking a file loads its content into the editor

**v0056: Save File + Dirty Tracking**

- Implement dirty flag (`currentContent != savedContent`)
- Save button + Cmd+S keyboard shortcut → `FileServiceClient.writeFile()`
- Status bar shows "Saved" / "Unsaved" state
- Unsaved indicator on sidebar file item
- **Acceptance**: Edit → status shows "Unsaved" → Save → status shows "Saved" → re-read file from disk matches saved content

### Phase 3: Status Bar + Theme (v0057–v0058)

**v0057: Status Bar**

- Implement StatusBar widget showing: file name, save status, character count, line count
- Wire to `MilkdownChangeEvent` for char/line count
- Fixed position at bottom of layout
- **Acceptance**: Status bar reflects real-time editor stats

**v0058: Theme Switching + Persistence**

- Implement theme dropdown in toolbar
- Switch theme via `MilkdownController.setTheme()`
- Persist selected theme in Host KV storage (`kv.set('markdown_editor.theme', ...)`)
- Restore theme on app startup
- **Acceptance**: Theme switches immediately; reopening app preserves theme choice

### Phase 4: New File + Polish (v0059–v0060)

**v0059: New File + Clipboard**

- "New File" button → dialog for file name → `FileServiceClient.createFile()` → open in editor
- Wire `ClipboardServiceClient` for explicit copy/paste actions (if needed beyond browser defaults)
- **Acceptance**: User can create new `.md` files and they appear in sidebar

**v0060: Polish & Documentation**

- Error handling polish (file not found, permission denied, etc.)
- Loading states for file operations
- README for `examples/markdown_editor`
- Update `docs/dev_plan.md` with iteration record
- Screenshot / demo for README
- **Acceptance**: App handles edge cases gracefully; README documents setup & usage

### Stretch Goals (Future Versions)

| Goal | Description | Enter Condition |
|------|-------------|-----------------|
| Auto-save | Periodic save with debounce | Core save flow stable |
| File rename/delete | Right-click context menu on sidebar items | File tree interaction stable |
| Multiple tabs | Open multiple files simultaneously | Core flow proven |
| Keyboard shortcuts | Cmd+N, Cmd+O, Cmd+W | Core interactions complete |
| Recent files | Persist and show recent file list | KV service sufficient |
| Search in files | Search across files in directory | FileService supports search |

---

## 11. Dependency Graph

```
v0051 (FileService)  ──┐
                        ├──→ v0053 (App Scaffold) ──→ v0054 (Open Folder)
v0052 (DialogSvc+Clip) ─┘                             │
                                                       ▼
                                                  v0055 (Open File)
                                                       │
                                                       ▼
                                                  v0056 (Save + Dirty)
                                                       │
                                                       ▼
                                                  v0057 (Status Bar)
                                                       │
                                                       ▼
                                                  v0058 (Theme + Persist)
                                                       │
                                                       ▼
                                                  v0059 (New File + Clip)
                                                       │
                                                       ▼
                                                  v0060 (Polish + Docs)
```

**Parallelization opportunities:**
- v0051 and v0052 are independent — can be developed in parallel
- v0057 can partially start alongside v0055-v0056 (layout can be built before wiring all data)

---

## 12. Risk Analysis

| # | Risk | Probability | Impact | Mitigation |
|---|------|-------------|--------|-----------|
| R1 | `file_selector` package doesn't work well on macOS for directory picking | Medium | High | Test early in v0052; fallback to MethodChannel with native NSOpenPanel |
| R2 | WebView clipboard isolation (browser clipboard != system clipboard) | Medium | Medium | ClipboardService on Host side bypasses WebView clipboard limitations |
| R3 | Large file performance (reading/writing large Markdown files) | Low | Medium | Set file size limit (e.g., 1MB); warn user for large files |
| R4 | MilkdownController.setContent() causes editor flicker on file switch | Medium | Medium | Add loading overlay during content switch; debounce rapid switches |
| R5 | Relative path resolution for `fluttron_milkdown` from `examples/` | Medium | Medium | Validate in v0053; may need absolute path or CLI path resolution fix |
| R6 | File system watchers (external changes to files) not supported | Low | Low | Out of scope for v1; add manual refresh button |
| R7 | Host services add breaking changes to `fluttron_host` API | Low | High | Keep services additive; don't modify existing PlatformService/KvService contracts |
| R8 | Framework evolution delays App development | Medium | Medium | Framework tasks (F1-F3) can be mocked in UI development while services are built |

---

## 13. Testing Strategy

### 13.1 Unit Tests

| Area | Location | Scope |
|------|----------|-------|
| FileService | `packages/fluttron_host/test/` | All methods with temp directory |
| DialogService | `packages/fluttron_host/test/` | Param validation (dialog display is manual) |
| ClipboardService | `packages/fluttron_host/test/` | setText/getText round-trip |
| EditorState | `examples/markdown_editor/ui/test/` | State transitions, dirty flag logic |
| Service clients | `examples/markdown_editor/ui/test/` | Client wrapper methods |

### 13.2 Integration Tests

| Scenario | Steps |
|----------|-------|
| Full build cycle | `fluttron build -p examples/markdown_editor` succeeds |
| Open folder → browse files | Open folder → sidebar shows files → click file → editor loads content |
| Edit → save → verify | Open file → edit → save → read from disk → content matches |
| Theme persistence | Set theme → restart app → theme preserved |
| New file workflow | New file → enter name → file created → opened in editor |

### 13.3 Manual Acceptance Tests

| Test | Expected |
|------|----------|
| Native dialog appearance | macOS-native open/save dialogs with proper filtering |
| Large file handling | 500KB markdown file opens without UI freeze |
| Concurrent save/load | No data corruption when rapidly switching files |
| Window resize | Layout adapts; sidebar and editor resize correctly |

---

## 14. Success Metrics

| Metric | Target | How to Measure |
|--------|--------|----------------|
| Build success | `fluttron build` completes in < 60s | CI timing |
| App launch | Window visible in < 3s from `flutter run` | Manual timing |
| File open | File content visible in < 500ms | Manual timing |
| Save latency | Save completes in < 200ms for 100KB file | Manual timing |
| Editor responsiveness | No visible lag while typing | Manual observation |
| Framework services | 3 new services with full test coverage | `flutter test` in `fluttron_host` |
| Code quality | `dart analyze` clean in all packages | CI check |

---

## 15. FAQ

### Q: Why not build the sidebar and file tree as a separate web package?

The sidebar is app-specific UI, not a reusable component. It uses standard Flutter Web widgets (ListView, TreeView) and doesn't need any JS integration. Keeping it in the app's UI is simpler and more appropriate.

### Q: Why add Host services to `fluttron_host` instead of keeping them app-specific?

File access, dialogs, and clipboard are fundamental desktop capabilities that every non-trivial Fluttron app will need. Making them built-in eliminates boilerplate and establishes the pattern for community service development.

### Q: Can the editor work without opening a folder first?

Yes. The app starts with a blank editor and default welcome markdown (similar to VS Code's "Welcome" tab). The user can type freely and later save via "Save As" dialog. Opening a folder is optional and enables the sidebar.

### Q: How does this differ from the playground?

The playground is a developer testing tool that demonstrates framework internals (KV storage, event bridge, controller API). `markdown_editor` is a user-facing application that hides all framework complexity behind a polished UI. It's the difference between a unit test and a product.

### Q: What if `MilkdownController.setContent()` doesn't work well for file switching?

This is a known risk (R4). If there's significant flicker or re-initialization delay, we could:
1. Add a loading overlay during transition
2. Destroy and re-create the entire `MilkdownEditor` widget per file
3. Extend `fluttron_milkdown` to support a `replaceContent()` method optimized for full replacement

### Q: Why StatefulWidget instead of a state management package?

For a single-view app with < 10 state variables, a standard `StatefulWidget` pattern is the least-ceremony approach. Adding Riverpod/Bloc/Provider for this scope is over-engineering. The design document explicitly notes: upgrade to `ChangeNotifier` if multi-tab support is added.

---

## Document History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 0.1.0-draft | 2026-02-16 | Architecture Team | Initial draft |
