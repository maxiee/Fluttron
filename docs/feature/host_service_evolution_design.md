# Host Service Evolution — Technical Design Document

**Version:** 0.1.0-draft  
**Date:** 2026-02-17  
**Status:** Draft  
**Author:** Fluttron Architecture Team

---

## 1. Executive Summary

### 1.1 What

A three-phase evolution of Fluttron's Host Service architecture:

1. **L1 — Built-in Service Client Uplift**: Move hand-written Client Stubs (e.g., `FileServiceClient`, `DialogServiceClient`) from application code into the `fluttron_ui` framework package, so every Fluttron app gets type-safe Host service access out of the box.
2. **L3 — `host_service` Template**: Add a new `fluttron create --type host_service` template that generates two independent Dart packages (one Host-side implementation, one UI-side client stub) for custom services.
3. **L2 — Service Codegen CLI**: Add `fluttron generate services` command that reads a Dart interface declaration and auto-generates both Host handler scaffold and UI client stub, eliminating manual boilerplate.

### 1.2 Why

After completing `markdown_editor` (v0051-v0060), a clear structural problem has surfaced:

**The Host ↔ UI service boundary has no type-safe contract.**

Evidence:

| Symptom | Example | Impact |
|---------|---------|--------|
| **Client stubs duplicated per app** | `FileServiceClient` exists in `examples/markdown_editor/ui/lib/services/` — any new app must hand-write an identical copy | O(N) boilerplate per app |
| **Contract is implicit** | Host `FileService` returns `{'content': ...}`, Client assumes `result['content']` — no compile-time enforcement | Silent runtime breakage on contract drift |
| **Models scattered** | `FileEntry` is in `fluttron_shared`, but `FileStat` is defined inside `markdown_editor`'s `FileServiceClient` | Unclear ownership, fragile sharing |
| **Switch/case routing** | Every `FluttronService.handle()` is a hand-written `switch` with manual param extraction | Error-prone, repetitive, un-ergonomic |
| **No framework for custom services** | Users must read code or docs to understand the service authoring pattern | High onboarding friction |

This evolution addresses all five symptoms through progressive refinement: first centralize (L1), then templatize (L3), then automate (L2).

### 1.3 Scope Overview

| Dimension | Decision |
|-----------|----------|
| Affected packages | `fluttron_ui`, `fluttron_shared`, `fluttron_cli`, `fluttron_host` |
| New template | `templates/host_service/` (two sub-packages) |
| New CLI command | `fluttron generate services` (L2 phase) |
| Backward compatibility | 100% — existing `FluttronClient.invoke()` still works |
| Platform scope | All (codegen is platform-agnostic) |

### 1.4 Relationship to Existing Concepts

| Existing Concept | This Evolution's Counterpart |
|------------------|------------------------------|
| `web_package` (UI-side reusable component) | `host_service` (Host-side reusable service) |
| `fluttron_web_package.json` (manifest) | `fluttron_host_service.json` (manifest) |
| `WebPackageCopier` (template processor) | `HostServiceCopier` (template processor) |
| `FluttronHtmlView` (declarative UI embedding) | `XxxServiceClient` (declarative service access) |
| `fluttron packages list` (web package diagnostics) | `fluttron services list` (service diagnostics) |

---

## 2. Goals & Success Criteria

### 2.1 Product Goals

| # | Goal | Measurable Criteria |
|---|------|---------------------|
| G1 | Zero-boilerplate access to built-in services | Any Fluttron app can `import 'package:fluttron_ui/fluttron_ui.dart'` and use `FileServiceClient`, `DialogServiceClient`, etc. without hand-writing client code |
| G2 | One-command custom service scaffolding | `fluttron create --type host_service --name my_service` produces two buildable packages with compilable service skeleton |
| G3 | Single-source contract for custom services (L2) | A Dart abstract class with annotations generates both Host handler and UI client; changing the interface re-generates both sides |
| G4 | Shared models ownership clarity | All request/response models for built-in services are in `fluttron_shared`; custom service models are in the generated shared layer |
| G5 | Backward compatible | Existing `FluttronClient.invoke('file.readFile', ...)` usage continues to work |

### 2.2 Framework Evolution Goals

| # | Goal | What We Evolve |
|---|------|----------------|
| F1 | Built-in Client Stubs in `fluttron_ui` | New `services/` directory with typed clients for all 5 built-in services |
| F2 | Shared models consolidation | Move `FileStat` and any other scattered models into `fluttron_shared` |
| F3 | `host_service` template & copier | New template under `templates/host_service/`, new `HostServiceCopier` in CLI |
| F4 | `fluttron create --type host_service` | CLI extension for the new project type |
| F5 | `host_service` manifest format | `fluttron_host_service.json` schema |
| F6 | `fluttron generate services` (L2) | Dart source parsing + code generation CLI command |

### 2.3 Non-Goals (Explicit)

- Runtime service discovery (services are compile-time registered)
- Cross-process or network service transport (Host and UI are in the same process via WebView)
- Automatic Host service registration from dependencies (manual `registry.register()` is intentional for now)
- Dart FFI or native plugin wrapping (services are pure Dart using Flutter APIs)
- Mobile platform parity testing (desktop-first)
- Binary protocol / protobuf transport (JSON over WebView bridge is sufficient for current scale)

---

## 3. Architecture Overview

### 3.1 Current Architecture (Before)

```
┌─────────────────────────────────────────────────────────────────────┐
│  Host (fluttron_host)                                               │
│  ┌──────────────────────────────────────────────────────────┐       │
│  │  ServiceRegistry                                         │       │
│  │  ├─ SystemService    (namespace: "system")               │       │
│  │  ├─ StorageService   (namespace: "storage")              │       │
│  │  ├─ FileService      (namespace: "file")                 │       │
│  │  ├─ DialogService    (namespace: "dialog")               │       │
│  │  └─ ClipboardService (namespace: "clipboard")            │       │
│  └──────────────────────────────────────────────────────────┘       │
│                    │                                                 │
│              HostBridge (WebView JS Handler)                         │
│                    │                                                 │
│               "namespace.method" routing                             │
│                    │                                                 │
└────────────────────┼────────────────────────────────────────────────┘
                     │
┌────────────────────┼────────────────────────────────────────────────┐
│  UI (fluttron_ui)  │                                                │
│  ┌─────────────────┴────────────────────────────────────────┐       │
│  │  FluttronClient                                          │       │
│  │  · invoke('namespace.method', params) → dynamic          │       │
│  │  · getPlatform()  ← convenience, hard-coded              │       │
│  │  · kvSet/kvGet()  ← convenience, hard-coded              │       │
│  └──────────────────────────────────────────────────────────┘       │
│                    │                                                 │
│  ┌─────────────────┴────────────────────────────────────────┐       │
│  │  App-level hand-written clients (PER APP!)               │       │
│  │  · FileServiceClient      ← in markdown_editor/ui/      │       │
│  │  · DialogServiceClient    ← in markdown_editor/ui/      │       │
│  │  · ClipboardServiceClient ← in markdown_editor/ui/      │       │
│  └──────────────────────────────────────────────────────────┘       │
│                                                                     │
│  Contract: IMPLICIT (string-based method names + Map params)        │
│  Models: SCATTERED (FileEntry in shared, FileStat in app)           │
└─────────────────────────────────────────────────────────────────────┘
```

### 3.2 Target Architecture (After L1 + L3 + L2)

```
┌─────────────────────────────────────────────────────────────────────┐
│  Host (fluttron_host)                                               │
│  ┌──────────────────────────────────────────────────────────┐       │
│  │  ServiceRegistry                                         │       │
│  │  ├─ SystemService        (built-in)                      │       │
│  │  ├─ StorageService       (built-in)                      │       │
│  │  ├─ FileService          (built-in)                      │       │
│  │  ├─ DialogService        (built-in)                      │       │
│  │  ├─ ClipboardService     (built-in)                      │       │
│  │  └─ MyCustomService      (from host_service package)     │       │
│  └──────────────────────────────────────────────────────────┘       │
│                    │                                                 │
│              HostBridge                                              │
└────────────────────┼────────────────────────────────────────────────┘
                     │
┌────────────────────┼────────────────────────────────────────────────┐
│  UI (fluttron_ui)  │                                                │
│  ┌─────────────────┴────────────────────────────────────────┐       │
│  │  FluttronClient (pure invoke channel)                    │       │
│  │  · invoke('namespace.method', params) → dynamic          │       │
│  └──────────────────────────────────────────────────────────┘       │
│                    │                                                 │
│  ┌─────────────────┴────────────────────────────────────────┐       │
│  │  Built-in Service Clients (IN FRAMEWORK) ← L1            │       │
│  │  · FileServiceClient                                     │       │
│  │  · DialogServiceClient                                   │       │
│  │  · ClipboardServiceClient                                │       │
│  │  · SystemServiceClient                                   │       │
│  │  · StorageServiceClient                                  │       │
│  └──────────────────────────────────────────────────────────┘       │
│                    │                                                 │
│  ┌─────────────────┴────────────────────────────────────────┐       │
│  │  Custom Service Clients (from host_service pkg) ← L3     │       │
│  │  · MyCustomServiceClient (separate package)              │       │
│  └──────────────────────────────────────────────────────────┘       │
│                                                                     │
│  Contract: EXPLICIT (Dart types in shared layer)                    │
│  Models: CENTRALIZED (fluttron_shared for built-in,                 │
│           service-specific shared for custom)                       │
└─────────────────────────────────────────────────────────────────────┘
```

### 3.3 Package Dependency Graph

```
fluttron_shared  ←─────────────────────────────────────────────┐
  (protocol, models, error types)                              │
       │                                                        │
       ├──── fluttron_host (depends on shared)                  │
       │       ├── Built-in services                            │
       │       └── ServiceRegistry + HostBridge                 │
       │                                                        │
       ├──── fluttron_ui (depends on shared)                    │
       │       ├── FluttronClient                               │
       │       └── Built-in ServiceClients  ← NEW (L1)         │
       │                                                        │
       └──── my_service_host   ← NEW (L3/L2)                   │
             (custom service impl, depends on fluttron_host)    │
                                                                │
             my_service_client ← NEW (L3/L2)                    │
             (custom service client, depends on fluttron_ui)  ──┘
```

---

## 4. Phase L1 — Built-in Service Client Uplift

### 4.1 Objective

Move all built-in service Client Stubs from application code into `fluttron_ui`, consolidate shared models into `fluttron_shared`, and deprecate the `FluttronClient` convenience methods.

### 4.2 File Changes

#### 4.2.1 New Files in `fluttron_ui`

```
packages/fluttron_ui/lib/
├── fluttron_ui.dart                     # UPDATE: add exports
├── fluttron/
│   ├── fluttron_client.dart             # EXISTING (no change)
│   └── fluttron_client_stub.dart        # EXISTING (no change)
└── src/
    ├── services/                        # NEW directory
    │   ├── file_service_client.dart     # NEW
    │   ├── dialog_service_client.dart   # NEW
    │   ├── clipboard_service_client.dart# NEW
    │   ├── system_service_client.dart   # NEW
    │   └── storage_service_client.dart  # NEW
    └── ... (existing files unchanged)
```

#### 4.2.2 New Files in `fluttron_shared`

```
packages/fluttron_shared/lib/
├── fluttron_shared.dart                 # UPDATE: add exports
└── src/
    ├── file_entry.dart                  # EXISTING (no change)
    └── file_stat.dart                   # NEW (moved from markdown_editor)
```

### 4.3 Detailed Interface Specifications

#### 4.3.1 `FileServiceClient`

**Location:** `packages/fluttron_ui/lib/src/services/file_service_client.dart`

```dart
import 'package:fluttron_shared/fluttron_shared.dart';
import 'package:fluttron_ui/fluttron_ui.dart';

/// Type-safe client for the built-in `file.*` Host service.
///
/// Wraps [FluttronClient.invoke] calls with proper parameter construction
/// and response deserialization.
///
/// Usage:
/// ```dart
/// final client = FluttronClient();
/// final fileService = FileServiceClient(client);
/// final content = await fileService.readFile('/path/to/file.md');
/// ```
class FileServiceClient {
  /// Creates a [FileServiceClient] with the given [FluttronClient].
  FileServiceClient(this._client);

  final FluttronClient _client;

  /// Reads a file as a UTF-8 string.
  ///
  /// [path] must be an absolute path.
  ///
  /// Throws [StateError] if the file does not exist or cannot be read.
  Future<String> readFile(String path) async {
    final result = await _client.invoke('file.readFile', {'path': path});
    return result['content'] as String;
  }

  /// Writes a UTF-8 string to a file.
  ///
  /// Creates parent directories if they don't exist.
  /// Overwrites existing file content.
  Future<void> writeFile(String path, String content) async {
    await _client.invoke('file.writeFile', {'path': path, 'content': content});
  }

  /// Lists the contents of a directory.
  ///
  /// Returns a list of [FileEntry] sorted directories-first, then alphabetically.
  Future<List<FileEntry>> listDirectory(String path) async {
    final result = await _client.invoke('file.listDirectory', {'path': path});
    final entries = result['entries'] as List<dynamic>;
    return entries
        .map((e) => FileEntry.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// Gets file or directory statistics.
  ///
  /// Returns a [FileStat] with existence, type, size, and modification info.
  Future<FileStat> stat(String path) async {
    final result = await _client.invoke('file.stat', {'path': path});
    return FileStat.fromMap(Map<String, dynamic>.from(result as Map));
  }

  /// Creates a new empty file with optional initial [content].
  ///
  /// Throws [StateError] if the file already exists.
  Future<void> createFile(String path, {String content = ''}) async {
    await _client.invoke(
      'file.createFile',
      {'path': path, 'content': content},
    );
  }

  /// Deletes a file or empty directory.
  ///
  /// Throws [StateError] if the path doesn't exist or the directory is not empty.
  Future<void> delete(String path) async {
    await _client.invoke('file.delete', {'path': path});
  }

  /// Renames or moves a file or directory.
  ///
  /// Throws [StateError] if the source path doesn't exist.
  Future<void> rename(String oldPath, String newPath) async {
    await _client.invoke('file.rename', {
      'oldPath': oldPath,
      'newPath': newPath,
    });
  }

  /// Checks whether a path exists on the file system.
  Future<bool> exists(String path) async {
    final result = await _client.invoke('file.exists', {'path': path});
    return result['exists'] as bool;
  }
}
```

#### 4.3.2 `DialogServiceClient`

**Location:** `packages/fluttron_ui/lib/src/services/dialog_service_client.dart`

```dart
import 'package:fluttron_ui/fluttron_ui.dart';

/// Type-safe client for the built-in `dialog.*` Host service.
///
/// Provides native OS file and directory picker dialogs.
/// Returns `null` when the user cancels a dialog (not an error).
class DialogServiceClient {
  /// Creates a [DialogServiceClient] with the given [FluttronClient].
  DialogServiceClient(this._client);

  final FluttronClient _client;

  /// Opens a native single-file picker dialog.
  ///
  /// Returns the selected file path, or `null` if the user cancelled.
  Future<String?> openFile({
    String? title,
    List<String>? allowedExtensions,
    String? initialDirectory,
  }) async {
    final params = <String, dynamic>{};
    if (title != null) params['title'] = title;
    if (allowedExtensions != null) {
      params['allowedExtensions'] = allowedExtensions;
    }
    if (initialDirectory != null) {
      params['initialDirectory'] = initialDirectory;
    }
    final result = await _client.invoke('dialog.openFile', params);
    return result['path'] as String?;
  }

  /// Opens a native multiple-file picker dialog.
  ///
  /// Returns a list of selected file paths (empty if cancelled).
  Future<List<String>> openFiles({
    String? title,
    List<String>? allowedExtensions,
    String? initialDirectory,
  }) async {
    final params = <String, dynamic>{};
    if (title != null) params['title'] = title;
    if (allowedExtensions != null) {
      params['allowedExtensions'] = allowedExtensions;
    }
    if (initialDirectory != null) {
      params['initialDirectory'] = initialDirectory;
    }
    final result = await _client.invoke('dialog.openFiles', params);
    final paths = result['paths'] as List<dynamic>;
    return paths.map((p) => p as String).toList();
  }

  /// Opens a native directory picker dialog.
  ///
  /// Returns the selected directory path, or `null` if the user cancelled.
  Future<String?> openDirectory({
    String? title,
    String? initialDirectory,
  }) async {
    final params = <String, dynamic>{};
    if (title != null) params['title'] = title;
    if (initialDirectory != null) {
      params['initialDirectory'] = initialDirectory;
    }
    final result = await _client.invoke('dialog.openDirectory', params);
    return result['path'] as String?;
  }

  /// Opens a native save-file dialog.
  ///
  /// Returns the selected save path, or `null` if the user cancelled.
  Future<String?> saveFile({
    String? title,
    String? defaultFileName,
    List<String>? allowedExtensions,
    String? initialDirectory,
  }) async {
    final params = <String, dynamic>{};
    if (title != null) params['title'] = title;
    if (defaultFileName != null) params['defaultFileName'] = defaultFileName;
    if (allowedExtensions != null) {
      params['allowedExtensions'] = allowedExtensions;
    }
    if (initialDirectory != null) {
      params['initialDirectory'] = initialDirectory;
    }
    final result = await _client.invoke('dialog.saveFile', params);
    return result['path'] as String?;
  }
}
```

#### 4.3.3 `ClipboardServiceClient`

**Location:** `packages/fluttron_ui/lib/src/services/clipboard_service_client.dart`

```dart
import 'package:fluttron_ui/fluttron_ui.dart';

/// Type-safe client for the built-in `clipboard.*` Host service.
///
/// Provides system clipboard read/write via the Host's native clipboard access.
/// This bypasses WebView clipboard restrictions.
class ClipboardServiceClient {
  /// Creates a [ClipboardServiceClient] with the given [FluttronClient].
  ClipboardServiceClient(this._client);

  final FluttronClient _client;

  /// Reads text from the system clipboard.
  ///
  /// Returns the clipboard text, or `null` if no text is available.
  Future<String?> getText() async {
    final result = await _client.invoke('clipboard.getText', {});
    return result['text'] as String?;
  }

  /// Writes text to the system clipboard.
  Future<void> setText(String text) async {
    await _client.invoke('clipboard.setText', {'text': text});
  }

  /// Checks whether the system clipboard contains text.
  Future<bool> hasText() async {
    final result = await _client.invoke('clipboard.hasText', {});
    return result['hasText'] as bool;
  }
}
```

#### 4.3.4 `SystemServiceClient`

**Location:** `packages/fluttron_ui/lib/src/services/system_service_client.dart`

```dart
import 'package:fluttron_ui/fluttron_ui.dart';

/// Type-safe client for the built-in `system.*` Host service.
///
/// Provides platform information from the Host process.
class SystemServiceClient {
  /// Creates a [SystemServiceClient] with the given [FluttronClient].
  SystemServiceClient(this._client);

  final FluttronClient _client;

  /// Returns the Host platform identifier.
  ///
  /// Possible values: `"macos"`, `"windows"`, `"linux"`, `"android"`, `"ios"`.
  Future<String> getPlatform() async {
    final result = await _client.invoke('system.getPlatform', {});
    if (result is Map && result['platform'] != null) {
      return result['platform'].toString();
    }
    return result?.toString() ?? 'unknown';
  }
}
```

#### 4.3.5 `StorageServiceClient`

**Location:** `packages/fluttron_ui/lib/src/services/storage_service_client.dart`

```dart
import 'package:fluttron_ui/fluttron_ui.dart';

/// Type-safe client for the built-in `storage.*` Host service.
///
/// Provides in-memory key-value storage on the Host.
/// Note: Data is NOT persisted across app restarts in the current implementation.
class StorageServiceClient {
  /// Creates a [StorageServiceClient] with the given [FluttronClient].
  StorageServiceClient(this._client);

  final FluttronClient _client;

  /// Stores a key-value pair.
  Future<void> set(String key, String value) async {
    await _client.invoke('storage.kvSet', {'key': key, 'value': value});
  }

  /// Retrieves a value by key.
  ///
  /// Returns `null` if the key does not exist.
  Future<String?> get(String key) async {
    final result = await _client.invoke('storage.kvGet', {'key': key});
    if (result is Map) {
      final v = result['value'];
      return v?.toString();
    }
    return result?.toString();
  }
}
```

#### 4.3.6 `FileStat` (shared model uplift)

**Location:** `packages/fluttron_shared/lib/src/file_stat.dart`

```dart
/// Represents file system statistics for a path.
///
/// Returned by [FileServiceClient.stat] and [FileService._stat].
class FileStat {
  const FileStat({
    required this.exists,
    required this.isFile,
    required this.isDirectory,
    required this.size,
    required this.modified,
  });

  /// Creates a [FileStat] from a JSON map returned by the bridge.
  factory FileStat.fromMap(Map<String, dynamic> map) {
    return FileStat(
      exists: map['exists'] as bool,
      isFile: map['isFile'] as bool,
      isDirectory: map['isDirectory'] as bool,
      size: map['size'] as int,
      modified: map['modified'] as String,
    );
  }

  /// Whether the path exists on the file system.
  final bool exists;

  /// Whether the path is a file.
  final bool isFile;

  /// Whether the path is a directory.
  final bool isDirectory;

  /// Size in bytes (0 for directories).
  final int size;

  /// Last modified time in ISO 8601 format.
  final String modified;

  /// Converts to a JSON map for serialization.
  Map<String, dynamic> toMap() {
    return {
      'exists': exists,
      'isFile': isFile,
      'isDirectory': isDirectory,
      'size': size,
      'modified': modified,
    };
  }

  @override
  String toString() {
    return 'FileStat(exists: $exists, isFile: $isFile, '
        'isDirectory: $isDirectory, size: $size, modified: $modified)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FileStat &&
        other.exists == exists &&
        other.isFile == isFile &&
        other.isDirectory == isDirectory &&
        other.size == size &&
        other.modified == modified;
  }

  @override
  int get hashCode => Object.hash(exists, isFile, isDirectory, size, modified);
}
```

### 4.4 Export Changes

#### `fluttron_ui.dart` (update)

```dart
export 'src/ui_app.dart';
export 'src/html_view.dart';
export 'src/event_bridge.dart';
export 'src/web_view_registry.dart';
export 'fluttron/fluttron_client_stub.dart'
    if (dart.library.js_interop) 'fluttron/fluttron_client.dart';

// Built-in service clients (L1)
export 'src/services/file_service_client.dart';
export 'src/services/dialog_service_client.dart';
export 'src/services/clipboard_service_client.dart';
export 'src/services/system_service_client.dart';
export 'src/services/storage_service_client.dart';
```

#### `fluttron_shared.dart` (update)

```dart
library;

export 'src/manifest.dart';
export 'src/request.dart';
export 'src/response.dart';
export 'src/error.dart';
export 'src/file_entry.dart';
export 'src/file_stat.dart';  // NEW
```

### 4.5 `FluttronClient` Deprecation Plan

The current `FluttronClient` has convenience methods (`getPlatform()`, `kvSet()`, `kvGet()`) that duplicate what `SystemServiceClient` and `StorageServiceClient` provide. These should be deprecated:

```dart
class FluttronClient {
  // Keep — this is the core transport method
  Future<dynamic> invoke(String method, Map<String, dynamic> params) async { ... }

  // DEPRECATE — use SystemServiceClient.getPlatform() instead
  @Deprecated('Use SystemServiceClient(client).getPlatform() instead.')
  Future<String> getPlatform() async { ... }

  // DEPRECATE — use StorageServiceClient(client).set() instead
  @Deprecated('Use StorageServiceClient(client).set() instead.')
  Future<void> kvSet(String key, String value) async { ... }

  // DEPRECATE — use StorageServiceClient(client).get() instead
  @Deprecated('Use StorageServiceClient(client).get() instead.')
  Future<String?> kvGet(String key) async { ... }
}
```

**Important:** Do NOT remove the deprecated methods in this phase. Only add `@Deprecated` annotations. Removal is a future breaking change.

### 4.6 Migration Guide for `markdown_editor`

After L1 lands, `examples/markdown_editor/ui/` should:

1. **Delete** `lib/services/file_service_client.dart` — use `FileServiceClient` from `fluttron_ui`
2. **Delete** `lib/services/dialog_service_client.dart` — use `DialogServiceClient` from `fluttron_ui`
3. **Delete** the `FileStat` class from `file_service_client.dart` — use `FileStat` from `fluttron_shared`
4. **Update imports** in `app.dart`:
   ```dart
   // Before:
   import 'services/file_service_client.dart';
   import 'services/dialog_service_client.dart';
   
   // After:
   import 'package:fluttron_ui/fluttron_ui.dart';
   // FileServiceClient and DialogServiceClient are already exported
   ```
5. **Replace** `FluttronClient().kvSet()` / `kvGet()` with `StorageServiceClient(_client).set()` / `.get()`

### 4.7 Stub Compatibility

`fluttron_ui` uses **conditional import** to switch between web and non-web implementations of `FluttronClient`. The service clients sit **above** this layer — they depend only on the `FluttronClient` abstract API (`invoke()`), so they work identically on both web and stub targets.

No additional conditional imports are needed for service clients.

### 4.8 Testing Strategy (L1)

| Test | Location | Method |
|------|----------|--------|
| `FileServiceClient` unit | `packages/fluttron_ui/test/services/file_service_client_test.dart` | Mock `FluttronClient.invoke`, verify correct method names and param shapes |
| `DialogServiceClient` unit | `packages/fluttron_ui/test/services/dialog_service_client_test.dart` | Mock client, verify optional param handling |
| `ClipboardServiceClient` unit | `packages/fluttron_ui/test/services/clipboard_service_client_test.dart` | Mock client, verify read/write roundtrip |
| `SystemServiceClient` unit | `packages/fluttron_ui/test/services/system_service_client_test.dart` | Mock client, verify response parsing |
| `StorageServiceClient` unit | `packages/fluttron_ui/test/services/storage_service_client_test.dart` | Mock client, verify set/get semantics |
| `FileStat` unit | `packages/fluttron_shared/test/file_stat_test.dart` | Construction, fromMap, equality |
| `markdown_editor` regression | `examples/markdown_editor/` | Build + run still works after migration |

**Mock strategy:** Since `FluttronClient` is a concrete class (not an interface), tests should create a simple mock:

```dart
class MockFluttronClient extends FluttronClient {
  final Map<String, dynamic Function(Map<String, dynamic>)> _handlers = {};

  void whenInvoke(String method, dynamic Function(Map<String, dynamic>) handler) {
    _handlers[method] = handler;
  }

  @override
  Future<dynamic> invoke(String method, Map<String, dynamic> params) async {
    final handler = _handlers[method];
    if (handler == null) {
      throw StateError('No mock handler for $method');
    }
    return handler(params);
  }
}
```

> **Note for implementing LLM:** The `FluttronClient` in `fluttron_ui` uses `dart:js_interop` which is not available in test environments. You need to create a test double that doesn't extend the real `FluttronClient`. Instead, define a minimal interface or use the stub variant. The recommended approach is:
> 1. Make service clients accept a `FluttronClient` parameter (they already do).
> 2. In tests, the stub variant of `FluttronClient` throws `UnsupportedError` for all methods.
> 3. Either: (a) Extract a `FluttronClientBase` abstract class that both web and stub implement, or (b) pass a fake that matches the `invoke()` signature.
> 4. The simplest approach: create service client tests that directly construct the client with mocked invocation results, without importing the real web `FluttronClient`.

---

## 5. Phase L3 — `host_service` Template

### 5.1 Objective

Add a new template type to `fluttron create` that generates two independent Dart packages for a custom Host service. This establishes the recommended pattern for community service development.

### 5.2 Template Structure

When the user runs:

```bash
fluttron create ./my_service --type host_service --name my_service
```

The following structure is created:

```
my_service/
├── fluttron_host_service.json         # Service manifest
├── README.md                           # Package documentation
├── my_service_host/                    # Host-side implementation
│   ├── pubspec.yaml
│   ├── lib/
│   │   ├── my_service_host.dart       # Library barrel
│   │   └── src/
│   │       └── my_service.dart        # FluttronService implementation
│   └── test/
│       └── my_service_test.dart       # Service unit tests
└── my_service_client/                  # UI-side client stub
    ├── pubspec.yaml
    ├── lib/
    │   ├── my_service_client.dart     # Library barrel
    │   └── src/
    │       └── my_service_client.dart # Client implementation
    └── test/
        └── my_service_client_test.dart# Client unit tests
```

### 5.3 Template Files (Detailed)

#### 5.3.1 `fluttron_host_service.json` (manifest)

```json
{
  "$schema": "https://fluttron.dev/schemas/host_service.json",
  "version": "1",
  "name": "template_service",
  "namespace": "template_service",
  "description": "A custom Fluttron host service.",
  "methods": [
    {
      "name": "greet",
      "description": "Returns a greeting message.",
      "params": {
        "name": { "type": "string", "required": false, "description": "Name to greet" }
      },
      "returns": {
        "message": { "type": "string", "description": "Greeting message" }
      }
    },
    {
      "name": "echo",
      "description": "Echoes back the input text.",
      "params": {
        "text": { "type": "string", "required": true, "description": "Text to echo" }
      },
      "returns": {
        "text": { "type": "string", "description": "Echoed text" }
      }
    }
  ]
}
```

**Manifest fields:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `$schema` | string | No | JSON schema URL for validation |
| `version` | string | Yes | Manifest format version |
| `name` | string | Yes | Service name (snake_case) |
| `namespace` | string | Yes | Service namespace for `namespace.method` routing |
| `description` | string | No | Human-readable description |
| `methods` | array | Yes | Array of method declarations |
| `methods[].name` | string | Yes | Method name |
| `methods[].description` | string | No | Method description |
| `methods[].params` | object | No | Parameter schema (key = param name) |
| `methods[].params[key].type` | string | Yes | Dart type name: `string`, `int`, `double`, `bool`, `List<string>`, `Map` |
| `methods[].params[key].required` | bool | Yes | Whether the parameter is required |
| `methods[].params[key].description` | string | No | Parameter description |
| `methods[].returns` | object | No | Return value schema (same format as params) |

> **Note:** The manifest serves as documentation and (in L2) as input for code generation. In L3, the actual Dart implementations are hand-written using the manifest as a reference.

#### 5.3.2 `template_service_host/pubspec.yaml`

```yaml
name: template_service_host
description: "Host-side implementation of template_service for Fluttron."
version: 0.1.0
publish_to: none

environment:
  sdk: ^3.10.4

dependencies:
  fluttron_host:
    path: ../../packages/fluttron_host
  fluttron_shared:
    path: ../../packages/fluttron_shared

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0
```

#### 5.3.3 `template_service_host/lib/template_service_host.dart`

```dart
library template_service_host;

export 'src/template_service.dart';
```

#### 5.3.4 `template_service_host/lib/src/template_service.dart`

```dart
import 'package:fluttron_host/fluttron_host.dart';
import 'package:fluttron_shared/fluttron_shared.dart';

/// Host-side implementation of the TemplateService.
///
/// Register this service in your host app's main.dart:
///
/// ```dart
/// import 'package:template_service_host/template_service_host.dart';
///
/// void main() {
///   final registry = ServiceRegistry()
///     ..register(SystemService())
///     ..register(StorageService())
///     ..register(TemplateService()); // Add your service
///
///   runFluttronHost(registry: registry);
/// }
/// ```
class TemplateService extends FluttronService {
  @override
  String get namespace => 'template_service';

  @override
  Future<dynamic> handle(String method, Map<String, dynamic> params) async {
    switch (method) {
      case 'greet':
        return _greet(params);
      case 'echo':
        return _echo(params);
      default:
        throw FluttronError(
          'METHOD_NOT_FOUND',
          'template_service.$method not implemented',
        );
    }
  }

  /// Returns a greeting message.
  ///
  /// Params:
  /// - name: (optional) Name to greet. Defaults to 'World'.
  ///
  /// Returns:
  /// - message: The greeting message.
  Map<String, dynamic> _greet(Map<String, dynamic> params) {
    final name = params['name'] as String? ?? 'World';
    return {'message': 'Hello, $name!'};
  }

  /// Echoes back the input text.
  ///
  /// Params:
  /// - text: (required) Text to echo.
  ///
  /// Returns:
  /// - text: The echoed text.
  Map<String, dynamic> _echo(Map<String, dynamic> params) {
    final text = params['text'];
    if (text is! String || text.isEmpty) {
      throw FluttronError('BAD_PARAMS', 'Missing or empty "text" parameter');
    }
    return {'text': text};
  }
}
```

#### 5.3.5 `template_service_host/test/template_service_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:fluttron_shared/fluttron_shared.dart';
import 'package:template_service_host/template_service_host.dart';

void main() {
  late TemplateService service;

  setUp(() {
    service = TemplateService();
  });

  test('namespace is template_service', () {
    expect(service.namespace, equals('template_service'));
  });

  group('greet', () {
    test('greets with default name', () async {
      final result = await service.handle('greet', {});
      expect(result, equals({'message': 'Hello, World!'}));
    });

    test('greets with custom name', () async {
      final result = await service.handle('greet', {'name': 'Alice'});
      expect(result, equals({'message': 'Hello, Alice!'}));
    });
  });

  group('echo', () {
    test('echoes text', () async {
      final result = await service.handle('echo', {'text': 'hello'});
      expect(result, equals({'text': 'hello'}));
    });

    test('throws on missing text', () async {
      expect(
        () => service.handle('echo', {}),
        throwsA(isA<FluttronError>()),
      );
    });
  });

  test('throws on unknown method', () async {
    expect(
      () => service.handle('unknown', {}),
      throwsA(isA<FluttronError>()),
    );
  });
}
```

#### 5.3.6 `template_service_client/pubspec.yaml`

```yaml
name: template_service_client
description: "UI-side client stub for template_service."
version: 0.1.0
publish_to: none

environment:
  sdk: ^3.10.4

dependencies:
  flutter:
    sdk: flutter
  fluttron_ui:
    path: ../../packages/fluttron_ui
  fluttron_shared:
    path: ../../packages/fluttron_shared

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0
```

#### 5.3.7 `template_service_client/lib/template_service_client.dart`

```dart
library template_service_client;

export 'src/template_service_client.dart';
```

#### 5.3.8 `template_service_client/lib/src/template_service_client.dart`

```dart
import 'package:fluttron_ui/fluttron_ui.dart';

/// Type-safe client for the TemplateService host service.
///
/// Usage in your UI code:
///
/// ```dart
/// final client = FluttronClient();
/// final templateService = TemplateServiceClient(client);
/// final greeting = await templateService.greet(name: 'Alice');
/// ```
class TemplateServiceClient {
  /// Creates a [TemplateServiceClient] with the given [FluttronClient].
  TemplateServiceClient(this._client);

  final FluttronClient _client;

  /// Returns a greeting message.
  ///
  /// [name] — optional name to greet. If omitted, defaults to 'World'.
  Future<String> greet({String? name}) async {
    final params = <String, dynamic>{};
    if (name != null) params['name'] = name;
    final result = await _client.invoke('template_service.greet', params);
    return result['message'] as String;
  }

  /// Echoes back the input [text].
  Future<String> echo(String text) async {
    final result = await _client.invoke(
      'template_service.echo',
      {'text': text},
    );
    return result['text'] as String;
  }
}
```

#### 5.3.9 `template_service_client/test/template_service_client_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:template_service_client/template_service_client.dart';

// See §4.8 for FluttronClient mock strategy.
// Tests verify correct method name and param construction.

void main() {
  // TODO: Implement tests with FluttronClient mock/fake.
  // See the built-in service client tests in fluttron_ui for reference.
}
```

#### 5.3.10 `README.md` (template root)

```markdown
# template_service

A custom Fluttron Host service.

## Structure

- `template_service_host/` — Host-side implementation (`FluttronService`)
- `template_service_client/` — UI-side client stub

## Usage

### 1. Register in Host

```dart
import 'package:template_service_host/template_service_host.dart';

void main() {
  final registry = ServiceRegistry()
    ..register(SystemService())
    ..register(StorageService())
    ..register(TemplateService());

  runFluttronHost(registry: registry);
}
```

### 2. Call from UI

```dart
import 'package:template_service_client/template_service_client.dart';

final client = FluttronClient();
final service = TemplateServiceClient(client);
final greeting = await service.greet(name: 'World');
```

## Development

```bash
# Test host-side
cd template_service_host && flutter test

# Test client-side
cd template_service_client && flutter test
```
```

### 5.4 CLI Changes for `--type host_service`

#### 5.4.1 `CreateCommand` Updates

**File:** `packages/fluttron_cli/lib/src/commands/create.dart`

Add `'host_service'` to the `allowed` list for `--type`:

```dart
..addOption(
  'type',
  help: 'Project type: "app", "web_package", or "host_service".',
  valueHelp: 'type',
  allowed: ['app', 'web_package', 'host_service'],
  defaultsTo: 'app',
)
```

Add a new `ProjectType.hostService` enum value and `_createHostServiceProject()` method:

```dart
Future<void> _createHostServiceProject({
  required Directory targetDir,
  required String normalizedTarget,
  required String name,
}) async {
  final templateDir = _resolveTemplateDir(subdir: 'host_service');

  final copier = HostServiceCopier();
  await copier.copyAndTransform(
    serviceName: name,
    sourceDir: templateDir,
    destinationDir: targetDir,
  );

  // Rewrite pubspec paths for fluttron_host and fluttron_ui dependencies
  _rewriteHostServicePubspecPaths(
    hostPubspec: File(p.join(targetDir.path, '${name}_host', 'pubspec.yaml')),
    clientPubspec: File(p.join(targetDir.path, '${name}_client', 'pubspec.yaml')),
    templateDir: templateDir.parent,
  );
}
```

#### 5.4.2 `HostServiceCopier` (New)

**File:** `packages/fluttron_cli/lib/src/utils/host_service_copier.dart`

The copier follows the same architecture as `WebPackageCopier`:

1. Defines template placeholder strings:
   - `template_service` → snake_case service name
   - `TemplateService` → PascalCase service name
   - `templateService` → camelCase service name
2. Recursively copies files with text substitution
3. Renames files and directories containing placeholder strings
4. Special handling for `pubspec.yaml` name fields
5. Special handling for `fluttron_host_service.json` namespace and method names
6. Skips directories: `node_modules`, `.dart_tool`, `build`, `.idea`

**Key differences from `WebPackageCopier`:**
- Two sub-packages instead of one flat package
- No frontend/JS assets
- Different manifest format (`fluttron_host_service.json` vs `fluttron_web_package.json`)
- Rewrite paths for both `fluttron_host` AND `fluttron_ui` dependencies

### 5.5 Naming Conventions

When the user provides `--name my_notification_service`:

| Format | Result | Use Case |
|--------|--------|----------|
| snake_case | `my_notification_service` | Package names, file names, namespace |
| PascalCase | `MyNotificationService` | Dart class names |
| camelCase | `myNotificationService` | Dart variable/function names |

| Generated Item | Name |
|----------------|------|
| Host package dir | `my_notification_service_host/` |
| Client package dir | `my_notification_service_client/` |
| Host Dart class | `MyNotificationService extends FluttronService` |
| Client Dart class | `MyNotificationServiceClient` |
| Namespace | `my_notification_service` |
| Host lib barrel | `my_notification_service_host.dart` |
| Client lib barrel | `my_notification_service_client.dart` |

### 5.6 Success Message

```
Project created: /path/to/my_notification_service
Type: host_service
Name: my_notification_service

Created packages:
  my_notification_service_host/   — Host-side service implementation
  my_notification_service_client/ — UI-side client stub

Next steps:
  1. cd my_notification_service_host && dart pub get && flutter test
  2. cd ../my_notification_service_client && dart pub get
  3. Add to your host app:
     import 'package:my_notification_service_host/my_notification_service_host.dart';
     registry.register(MyNotificationService());
  4. Add to your UI app:
     import 'package:my_notification_service_client/my_notification_service_client.dart';
     final svc = MyNotificationServiceClient(client);
```

### 5.7 Testing Strategy (L3)

| Test | Location | Method |
|------|----------|--------|
| `HostServiceCopier` unit | `packages/fluttron_cli/test/src/utils/host_service_copier_test.dart` | Verify file copy, substitution, rename |
| CLI `create --type host_service` | `packages/fluttron_cli/test/src/commands/create_command_test.dart` | End-to-end: create → verify structure |
| Generated host package builds | CI | `dart pub get && flutter test` in generated host package |
| Generated client package builds | CI | `dart pub get` in generated client package |
| Name transformation | Unit test in copier | snake/Pascal/camel correctly derived |

---

## 6. Phase L2 — Service Codegen CLI (Future)

### 6.1 Objective

Add a `fluttron generate services` command that reads a Dart abstract class declaration and generates:
1. Host-side `FluttronService` implementation with `switch/case` routing and parameter extraction
2. UI-side `ServiceClient` implementation with typed method wrappers
3. Shared model classes (if annotated)

### 6.2 Why a CLI Command (Not `build_runner`)

| Factor | `build_runner` | CLI Command |
|--------|----------------|-------------|
| **Build complexity** | Adds `build.yaml`, `build_runner` dep, `dart run build_runner build` step | Single `fluttron generate services` command |
| **Dev experience** | Familiar to pub ecosystem, but heavy | Simpler, matches existing `fluttron` CLI UX |
| **Generation trigger** | File save (with watch) or manual run | Manual run (explicit intent) |
| **Cross-package generation** | Difficult (generates into consuming package) | Easy (generates into two sibling directories) |
| **Dart ecosystem trend** | Mainstream but increasingly seen as heavy | Lighter tools gaining favor (e.g., `dart_mappable`, `freezed` moving to macros) |
| **Future Dart macros** | `build_runner` may be deprecated when macros land | CLI command remains valid regardless |

**Decision:** CLI command. It aligns with the existing `fluttron` CLI philosophy and avoids `build_runner` overhead.

### 6.3 Interface Declaration Format

The input is a standard Dart abstract class with annotations:

```dart
// File: my_service/service_contract.dart

import 'package:fluttron_shared/fluttron_shared.dart';

/// Annotation indicating this is a Fluttron service contract.
@FluttronService(namespace: 'weather')
abstract class WeatherService {
  /// Gets current weather for the given city.
  Future<WeatherInfo> getCurrentWeather(String city);

  /// Gets the 5-day forecast.
  ///
  /// [days] defaults to 5 if not specified.
  Future<List<WeatherForecast>> getForecast(String city, {int days = 5});

  /// Checks if the weather API is available.
  Future<bool> isAvailable();
}

/// Model class — generates serialization automatically.
@FluttronModel()
class WeatherInfo {
  final String city;
  final double temperature;
  final String condition;
  final DateTime timestamp;
}

@FluttronModel()
class WeatherForecast {
  final DateTime date;
  final double high;
  final double low;
  final String condition;
}
```

### 6.4 Annotation Definitions

**Location:** `packages/fluttron_shared/lib/src/annotations.dart`

```dart
/// Marks an abstract class as a Fluttron host service contract.
///
/// The code generator will produce:
/// 1. A `FluttronService` subclass with `switch/case` routing in the host package.
/// 2. A `ServiceClient` class with typed method wrappers in the client package.
class FluttronServiceContract {
  /// The namespace used for `namespace.method` routing.
  ///
  /// Must be unique within the application's service registry.
  final String namespace;

  const FluttronServiceContract({required this.namespace});
}

/// Marks a class as a Fluttron model for serialization code generation.
///
/// The generator produces `fromMap()` factory and `toMap()` method.
class FluttronModel {
  const FluttronModel();
}
```

### 6.5 Generated Output

From the `WeatherService` contract above, the generator produces:

#### Host-side (`weather_service_host/lib/src/weather_service_generated.dart`):

```dart
// GENERATED CODE — DO NOT MODIFY BY HAND
// Generated by: fluttron generate services
// Source: service_contract.dart

import 'package:fluttron_host/fluttron_host.dart';
import 'package:fluttron_shared/fluttron_shared.dart';

/// Base class with routing logic.
/// Extend this class to provide method implementations.
abstract class WeatherServiceBase extends FluttronService {
  @override
  String get namespace => 'weather';

  @override
  Future<dynamic> handle(String method, Map<String, dynamic> params) async {
    switch (method) {
      case 'getCurrentWeather':
        final city = _requireString(params, 'city');
        final result = await getCurrentWeather(city);
        return result.toMap();
      case 'getForecast':
        final city = _requireString(params, 'city');
        final days = params['days'] as int? ?? 5;
        final result = await getForecast(city, days: days);
        return result.map((e) => e.toMap()).toList();
      case 'isAvailable':
        return {'result': await isAvailable()};
      default:
        throw FluttronError(
          'METHOD_NOT_FOUND',
          'weather.$method not implemented',
        );
    }
  }

  /// Override to implement: Gets current weather for the given city.
  Future<WeatherInfo> getCurrentWeather(String city);

  /// Override to implement: Gets the 5-day forecast.
  Future<List<WeatherForecast>> getForecast(String city, {int days = 5});

  /// Override to implement: Checks if the weather API is available.
  Future<bool> isAvailable();

  String _requireString(Map<String, dynamic> params, String key) {
    final v = params[key];
    if (v is String && v.isNotEmpty) return v;
    throw FluttronError('BAD_PARAMS', 'Missing or invalid "$key"');
  }
}
```

The user then writes:

```dart
// weather_service_host/lib/src/weather_service.dart (hand-written)

import 'weather_service_generated.dart';

class WeatherService extends WeatherServiceBase {
  @override
  Future<WeatherInfo> getCurrentWeather(String city) async {
    // Real implementation here
    return WeatherInfo(city: city, temperature: 22.5, ...);
  }
  // ... other overrides
}
```

#### Client-side (`weather_service_client/lib/src/weather_service_client_generated.dart`):

```dart
// GENERATED CODE — DO NOT MODIFY BY HAND

import 'package:fluttron_ui/fluttron_ui.dart';

/// Type-safe client for the weather host service.
class WeatherServiceClient {
  WeatherServiceClient(this._client);

  final FluttronClient _client;

  /// Gets current weather for the given city.
  Future<WeatherInfo> getCurrentWeather(String city) async {
    final result = await _client.invoke(
      'weather.getCurrentWeather',
      {'city': city},
    );
    return WeatherInfo.fromMap(Map<String, dynamic>.from(result as Map));
  }

  /// Gets the 5-day forecast.
  Future<List<WeatherForecast>> getForecast(String city, {int days = 5}) async {
    final result = await _client.invoke(
      'weather.getForecast',
      {'city': city, 'days': days},
    );
    final list = result as List<dynamic>;
    return list
        .map((e) => WeatherForecast.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// Checks if the weather API is available.
  Future<bool> isAvailable() async {
    final result = await _client.invoke('weather.isAvailable', {});
    return result['result'] as bool;
  }
}
```

#### Shared models (`weather_service_shared/lib/src/models_generated.dart`):

```dart
// GENERATED CODE — DO NOT MODIFY BY HAND

class WeatherInfo {
  final String city;
  final double temperature;
  final String condition;
  final DateTime timestamp;

  const WeatherInfo({
    required this.city,
    required this.temperature,
    required this.condition,
    required this.timestamp,
  });

  factory WeatherInfo.fromMap(Map<String, dynamic> map) {
    return WeatherInfo(
      city: map['city'] as String,
      temperature: (map['temperature'] as num).toDouble(),
      condition: map['condition'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'city': city,
      'temperature': temperature,
      'condition': condition,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
```

### 6.6 CLI Command Design

```bash
# Generate from a contract file
fluttron generate services --contract path/to/service_contract.dart

# Generate into specific output directories
fluttron generate services \
  --contract path/to/service_contract.dart \
  --host-output weather_service_host/lib/src/ \
  --client-output weather_service_client/lib/src/ \
  --shared-output weather_service_shared/lib/src/

# Dry run (preview generated files without writing)
fluttron generate services --contract path/to/service_contract.dart --dry-run
```

### 6.7 Dart Source Parsing Strategy

The generator needs to parse Dart source code to extract:
1. Class name and `@FluttronServiceContract` annotation
2. Method signatures (name, parameters, return type)
3. `@FluttronModel` annotated classes (fields)

**Approach: `package:analyzer`**

```dart
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';

final parseResult = parseFile(
  path: contractFilePath,
  featureSet: FeatureSet.latestLanguageVersion(),
);

final unit = parseResult.unit;

for (final declaration in unit.declarations) {
  if (declaration is ClassDeclaration) {
    // Check for @FluttronServiceContract annotation
    // Extract methods, parameters, return types
  }
}
```

**Key implementation notes:**

- Use `package:analyzer` for AST parsing — it's the official Dart analysis library
- Parse at the syntactic level only (no resolution needed for simple type extraction)
- Handle `Future<T>` unwrapping for return types
- Handle optional parameters (`{int days = 5}`)
- Handle nullable return types (`Future<String?>`)
- Support basic Dart types: `String`, `int`, `double`, `bool`, `DateTime`, `List<T>`, `Map<String, dynamic>`
- For complex model types: require `@FluttronModel` annotation or fall back to `Map<String, dynamic>`

### 6.8 Type Mapping

| Dart Type | JSON Representation | `toMap` | `fromMap` |
|-----------|---------------------|---------|-----------|
| `String` | `string` | identity | `as String` |
| `int` | `number` | identity | `as int` |
| `double` | `number` | identity | `(as num).toDouble()` |
| `bool` | `boolean` | identity | `as bool` |
| `DateTime` | `string` (ISO 8601) | `.toIso8601String()` | `DateTime.parse()` |
| `String?` | `string \| null` | identity | `as String?` |
| `List<T>` | `array` | `.map(toMap).toList()` | `.map(fromMap).toList()` |
| `Map<String, dynamic>` | `object` | identity | identity |
| `@FluttronModel` class | `object` | `.toMap()` | `.fromMap()` |

### 6.9 Error Handling in Generated Code

Generated host handlers include standard error handling:

```dart
// In the generated switch/case:
case 'myMethod':
  final param = params['param'];
  if (param is! String || param.isEmpty) {
    throw FluttronError('BAD_PARAMS', 'Missing or invalid "param"');
  }
  // ... call implementation
```

Generated client stubs propagate errors via the standard `FluttronClient` error path (StateError).

### 6.10 Regeneration Safety

Generated files use a header comment:

```dart
// GENERATED CODE — DO NOT MODIFY BY HAND
// Generated by: fluttron generate services
// Source: service_contract.dart
// Timestamp: 2026-02-17T10:30:00Z
```

The generator:
- **Overwrites** files ending in `_generated.dart`
- **Never touches** user-written implementation files
- Uses the `Base` class pattern so user code extends generated code, avoiding merge conflicts

### 6.11 Testing Strategy (L2)

| Test | Location | Method |
|------|----------|--------|
| Dart AST parsing | `packages/fluttron_cli/test/src/generate/` | Parse sample contract → verify extracted methods |
| Host code generation | Same | Generate from fixture → compile → verify routing |
| Client code generation | Same | Generate from fixture → compile → verify method names |
| Model code generation | Same | Generate from fixture → verify `fromMap/toMap` |
| Type mapping | Same | Each Dart type → verify correct serialization code |
| Edge cases | Same | Optional params, nullable returns, List types, empty methods |
| End-to-end | Integration | Generate → build both packages → run cross-package test |

---

## 7. Iterative Execution Plan

### Phase 1: L1 — Built-in Client Uplift (v0061-v0063)

| Version | Task | Dependencies | Acceptance |
|---------|------|--------------|------------|
| v0061 | Create `fluttron_ui/lib/src/services/` with `FileServiceClient`, `DialogServiceClient`, `ClipboardServiceClient`. Move `FileStat` to `fluttron_shared`. Update exports. | None | `dart analyze packages/fluttron_ui` clean. Import from `fluttron_ui/fluttron_ui.dart` exposes all three clients. |
| v0062 | Add `SystemServiceClient`, `StorageServiceClient`. Deprecate `FluttronClient.getPlatform/kvSet/kvGet`. | v0061 | All 5 built-in services have framework-level clients. `dart analyze` shows deprecation warnings on old usage. |
| v0063 | Migrate `markdown_editor` to use framework clients. Delete app-level client files. Unit tests for all service clients. Update website/docs. | v0062 | `markdown_editor` builds + runs correctly with zero app-level client code. All new tests pass. |

### Phase 2: L3 — `host_service` Template (v0064-v0067)

| Version | Task | Dependencies | Acceptance |
|---------|------|--------------|------------|
| v0064 | Design and create `templates/host_service/` directory with all template files (manifest, host pkg, client pkg, README). | L1 complete | Template files exist and are valid Dart (manual `dart analyze` in template dirs). |
| v0065 | Implement `HostServiceCopier` with variable substitution. | v0064 | Unit tests pass: copier correctly transforms template names. |
| v0066 | Wire `CreateCommand` to support `--type host_service`. Update `ProjectType` enum, success message, pubspec rewriting. | v0065 | `fluttron create /tmp/test_svc --type host_service --name test_svc` creates valid structure. `flutter test` passes in both generated packages. |
| v0067 | Add `fluttron_host_service.json` manifest parsing (optional diagnostics). Write documentation and example. Validate end-to-end: create service → register in playground → call from UI. | v0066 | End-to-end custom service works in playground. |

### Phase 3: L2 — Codegen CLI (v0068+)

| Version | Task | Dependencies | Acceptance |
|---------|------|--------------|------------|
| v0068 | Add `@FluttronServiceContract` and `@FluttronModel` annotations to `fluttron_shared`. | L3 complete | Annotations importable and usable. |
| v0069 | Implement Dart AST parser for service contracts (extract class, methods, params, return types). | v0068 | Unit tests parse sample contracts correctly. |
| v0070 | Implement host-side code generator (produce `_generated.dart` with `switch/case` routing + `Base` class). | v0069 | Generated code compiles and routes correctly. |
| v0071 | Implement client-side code generator (produce `_generated.dart` with typed method wrappers). | v0069 | Generated code compiles and invokes correct methods. |
| v0072 | Implement model code generator (`fromMap`/`toMap` for `@FluttronModel` classes). | v0069 | Generated models serialize/deserialize correctly. |
| v0073 | Wire `fluttron generate services` CLI command. Support `--contract`, `--dry-run`, output path options. | v0070, v0071, v0072 | CLI command generates all files. End-to-end test passes. |
| v0074 | Documentation, edge case handling, error messages, and final validation. | v0073 | `fluttron generate services` works for realistic service contracts. |

### Dependency Graph

```
v0061 (File/Dialog/Clipboard clients)
  │
  ▼
v0062 (System/Storage clients + deprecations)
  │
  ▼
v0063 (Migration + tests + docs)
  │
  ▼
v0064 (Template files)
  │
  ▼
v0065 (HostServiceCopier)
  │
  ▼
v0066 (CLI --type host_service)
  │
  ▼
v0067 (E2E validation + docs)
  │
  ▼
v0068 (Annotations)
  │
  ▼
v0069 (AST parser)
  │
  ├──→ v0070 (Host codegen)──┐
  ├──→ v0071 (Client codegen)├──→ v0073 (CLI command)──→ v0074 (Docs)
  └──→ v0072 (Model codegen)─┘
```

**Parallelization opportunities:**
- v0070, v0071, v0072 are independent (all depend only on v0069)
- v0061 can start immediately (no blockers)

---

## 8. Risk Analysis

| # | Risk | Phase | Probability | Impact | Mitigation |
|---|------|-------|-------------|--------|-----------|
| R1 | `FluttronClient` is a concrete class with platform-specific imports — mocking in tests is non-trivial | L1 | High | Medium | Define a mock/fake strategy in §4.8. Use the stub variant for testing. Consider extracting `FluttronClientBase` if needed. |
| R2 | Deprecation of `FluttronClient.kvSet/kvGet/getPlatform` creates noise in existing apps | L1 | Medium | Low | Use `@Deprecated` only; don't remove. Provide clear migration path in deprecation message. |
| R3 | `HostServiceCopier` path rewriting fails for deeply nested project layouts | L3 | Medium | Medium | Test with multiple directory layouts. Use `package_config.json` for path resolution where possible. |
| R4 | Dart `package:analyzer` API instability (internal Google package) | L2 | Low | High | Pin to specific version. Only use syntactic parsing (more stable than semantic analysis). |
| R5 | Complex generic types in service contracts (e.g., `Future<Map<String, List<int>>>`) break the parser | L2 | Medium | Medium | Limit supported nesting depth. Fall back to `Map<String, dynamic>` for unrecognized types. Document limitations. |
| R6 | Users expect `build_runner`-style file watching — CLI manual invocation feels manual | L2 | Low | Low | Service contracts change rarely. Manual generation is acceptable. Document explicitly. |
| R7 | Two-package structure is confusing for small services | L3 | Medium | Low | Provide clear README template. Consider a `--single-package` flag for simple services (stretch). |
| R8 | Namespace collision between custom services and built-in services | L3 | Low | High | Validate namespace at service registration time (`ServiceRegistry.register` should throw on duplicate). Document reserved namespaces. |

---

## 9. Backward Compatibility

### 9.1 Guarantees

| Aspect | Guarantee |
|--------|-----------|
| `FluttronClient.invoke()` | Unchanged — remains the universal transport |
| `FluttronService` abstract class | Unchanged — all existing services continue to work |
| `ServiceRegistry.register()` | Unchanged API |
| `HostBridge` | Unchanged |
| `fluttron_shared` protocol | Unchanged (`FluttronRequest/Response/Error`) |
| Existing apps' `host/main.dart` | No changes needed |
| Existing apps' UI code using `invoke()` | Continues to work |

### 9.2 Breaking Changes (None in L1/L3)

L1 and L3 are purely additive. No existing API signatures change.

### 9.3 Future Breaking Changes (L2, planned)

When L2 lands, users who adopt codegen will have a new workflow. But the underlying transport remains `invoke()`, so non-codegen users are unaffected.

---

## 10. Documentation Plan

| Deliverable | Phase | Location |
|-------------|-------|----------|
| Built-in service client API docs | L1 | `website/docs/api/services.md` (update) |
| Service client usage examples | L1 | `website/docs/architecture/renderer-layer.md` (update) |
| Migration guide (app-level → framework clients) | L1 | `website/docs/getting-started/migration.md` (new) |
| `host_service` template README | L3 | Template README (auto-created) |
| Custom service tutorial | L3 | `website/docs/getting-started/custom-services.md` (new) |
| `fluttron generate services` reference | L2 | `website/docs/api/codegen.md` (new) |
| Contract annotation reference | L2 | `website/docs/api/annotations.md` (new) |
| `dev_plan.md` update | All | `docs/dev_plan.md` — new major requirement section |

---

## 11. Open Questions

| # | Question | Context | Decision Needed By |
|---|----------|---------|-------------------|
| Q1 | Should built-in service clients be re-exported from `fluttron_ui.dart` barrel or from a separate `fluttron_ui/services.dart`? | If the barrel file grows too large, a sub-export might be cleaner. | v0061 start |
| Q2 | Should `ServiceRegistry` enforce namespace uniqueness at registration time (throw on duplicate)? | Currently it silently overwrites. Explicit error is safer. | v0066 (before custom services land) |
| Q3 | For L2 codegen, should the generated `Base` class go in the host package or in a shared package? | If in shared, the client can also extend it for testing purposes. | v0068 design time |
| Q4 | Should the manifest `fluttron_host_service.json` be required or optional for L3 templates? | It's useful for documentation and future codegen but adds overhead for simple services. | v0064 |

---

## 12. Glossary

| Term | Definition |
|------|------------|
| **Client Stub** | A Dart class in the UI layer that wraps `FluttronClient.invoke()` calls with type-safe method signatures |
| **Host Handler** | A `FluttronService` subclass that routes `namespace.method` calls to implementation methods |
| **Service Contract** | A Dart abstract class with annotations that defines the interface between Host and UI |
| **Namespace** | The first segment of `namespace.method` routing (e.g., `file` in `file.readFile`) |
| **Transport** | The underlying communication channel (`FluttronClient.invoke` → WebView JS Handler → `HostBridge`) |
| **L1/L2/L3** | Evolution phases: L1 = Client Uplift, L3 = Template, L2 = Codegen |

---

## Document History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 0.1.0-draft | 2026-02-17 | Architecture Team | Initial draft covering L1, L3, L2 phases |
