# Services API Reference

Fluttron provides five built-in Host services with typed Dart clients in `fluttron_ui`.

## Quick Start

```dart
import 'package:fluttron_ui/fluttron_ui.dart';

final client = FluttronClient();
final fileService = FileServiceClient(client);
final dialogService = DialogServiceClient(client);
final clipboardService = ClipboardServiceClient(client);
final systemService = SystemServiceClient(client);
final storageService = StorageServiceClient(client);
```

## Built-in Services

| Service | Namespace | Client class | Status |
|---------|-----------|--------------|--------|
| FileService | `file` | `FileServiceClient` | ✅ Stable |
| DialogService | `dialog` | `DialogServiceClient` | ✅ Stable |
| ClipboardService | `clipboard` | `ClipboardServiceClient` | ✅ Stable |
| SystemService | `system` | `SystemServiceClient` | ✅ Stable |
| StorageService | `storage` | `StorageServiceClient` | ✅ Stable |

## FileService (`file.*`)

Methods:
- `readFile(path)`
- `writeFile(path, content)`
- `listDirectory(path)`
- `stat(path)`
- `createFile(path, {content})`
- `delete(path)`
- `rename(oldPath, newPath)`
- `exists(path)`

```dart
final content = await fileService.readFile('/Users/me/notes.md');
await fileService.writeFile('/Users/me/notes.md', '# Updated');
final entries = await fileService.listDirectory('/Users/me');
```

## DialogService (`dialog.*`)

Methods:
- `openFile(...)`
- `openFiles(...)`
- `openDirectory(...)`
- `saveFile(...)`

```dart
final filePath = await dialogService.openFile(
  title: 'Select markdown file',
  allowedExtensions: ['md'],
);

final folderPath = await dialogService.openDirectory(
  title: 'Select workspace',
);
```

`openFile/openDirectory/saveFile` return `null` when user cancels.  
`openFiles` returns an empty list when user cancels.

## ClipboardService (`clipboard.*`)

Methods:
- `getText()`
- `setText(text)`
- `hasText()`

```dart
await clipboardService.setText('Hello from Fluttron');
final text = await clipboardService.getText();
final hasText = await clipboardService.hasText();
```

## SystemService (`system.*`)

Methods:
- `getPlatform()`

```dart
final platform = await systemService.getPlatform();
print('Running on: $platform'); // macos/windows/linux/android/ios
```

## StorageService (`storage.*`)

Methods:
- `set(key, value)`
- `get(key)`

```dart
await storageService.set('user.name', 'Alice');
final name = await storageService.get('user.name');
```

`get` returns `null` when key does not exist.

## Backward Compatibility

`FluttronClient.invoke()` remains the core transport and is not deprecated.

`FluttronClient.getPlatform()`, `FluttronClient.kvSet()`, and `FluttronClient.kvGet()` are still available but deprecated. Prefer `SystemServiceClient` and `StorageServiceClient`.

## Custom Services

```dart
final client = FluttronClient();
final result = await client.invoke('greeting.greet', {'name': 'Alice'});
print(result['message']); // "Hello, Alice!"
```

## Generic invoke()

For any service (built-in or custom), you can always call:

```dart
final client = FluttronClient();
final result = await client.invoke('namespace.method', {
  'param1': 'value1',
  'param2': 42,
});
```

## Next Steps

- [Host Layer](../architecture/host-layer.md)
- [Renderer Layer](../architecture/renderer-layer.md)
- [Web Views API](./web-views.md)
