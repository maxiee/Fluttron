# Migration: App Clients to Framework Clients

This guide migrates UI code from app-level service wrappers to built-in clients from `fluttron_ui`.

## What Changed

Built-in typed clients are now provided by the framework:

- `FileServiceClient`
- `DialogServiceClient`
- `ClipboardServiceClient`
- `SystemServiceClient`
- `StorageServiceClient`

`FileStat` is now in `fluttron_shared`.

## 1. Remove app-level client files

Delete local wrappers like:

- `lib/services/file_service_client.dart`
- `lib/services/dialog_service_client.dart`
- `lib/services/clipboard_service_client.dart`

## 2. Update imports

Before:

```dart
import 'services/file_service_client.dart';
import 'services/dialog_service_client.dart';
```

After:

```dart
import 'package:fluttron_ui/fluttron_ui.dart';
import 'package:fluttron_shared/fluttron_shared.dart';
```

## 3. Create service clients from one `FluttronClient`

```dart
final client = FluttronClient();
final fileService = FileServiceClient(client);
final dialogService = DialogServiceClient(client);
final storageService = StorageServiceClient(client);
```

## 4. Replace deprecated convenience APIs

Before:

```dart
await client.kvSet('theme', 'nord');
final theme = await client.kvGet('theme');
final platform = await client.getPlatform();
```

After:

```dart
await storageService.set('theme', 'nord');
final theme = await storageService.get('theme');
final platform = await SystemServiceClient(client).getPlatform();
```

## 5. Verify

Run:

```bash
dart analyze packages/fluttron_ui
dart analyze examples/your_app/ui
```

If your app has integration tests, run them after migration to verify dialog, file, and storage flows.
