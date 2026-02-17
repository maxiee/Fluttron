import 'package:fluttron_ui/fluttron_ui.dart';

/// Type-safe client for the built-in `storage.*` Host service.
///
/// Provides in-memory key-value storage on the Host.
/// Note: Data is NOT persisted across app restarts in the current implementation.
///
/// Usage:
/// ```dart
/// final client = FluttronClient();
/// final storageService = StorageServiceClient(client);
/// await storageService.set('theme', 'dark');
/// final theme = await storageService.get('theme');
/// ```
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
