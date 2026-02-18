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

You can create custom Host services for app-specific needs. See the [Custom Services Tutorial](../getting-started/custom-services.md) for a complete guide.

Quick example:

```dart
final client = FluttronClient();
final result = await client.invoke('greeting.greet', {'name': 'Alice'});
print(result['message']); // "Hello, Alice!"
```

### Creating a Custom Service

1. **Define the service** (Host side):
   ```dart
   class GreetingService extends FluttronService {
     @override
     String get namespace => 'greeting';
     
     @override
     Future<dynamic> handle(String method, Map<String, dynamic> params) async {
       // Handle methods...
     }
   }
   ```

2. **Register the service**:
   ```dart
   void main() {
     final registry = ServiceRegistry()
       ..register(SystemService())
       ..register(StorageService())
       ..register(GreetingService()); // Your custom service
     
     runFluttronHost(registry: registry);
   }
   ```

3. **Call from UI**:
   ```dart
   final result = await client.invoke('greeting.greet', {'name': 'Alice'});
   ```

### Using Service Packages

For reusable services, use the CLI to create a service package:

```bash
fluttron create ./my_service --type host_service --name my_service
```

This generates both Host implementation and UI client stub packages.

See the [Custom Services Tutorial](../getting-started/custom-services.md) for details.

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

- [Custom Services Tutorial](../getting-started/custom-services.md) — Create your own Host services
- [Host Layer](../architecture/host-layer.md) — Deep dive into the Host layer
- [Renderer Layer](../architecture/renderer-layer.md) — UI architecture
- [Web Views API](./web-views.md) — Embed Web content
