import 'package:fluttron_ui/fluttron_ui.dart';

/// Type-safe client for the built-in `system.*` Host service.
///
/// Provides platform information from the Host process.
///
/// Usage:
/// ```dart
/// final client = FluttronClient();
/// final systemService = SystemServiceClient(client);
/// final platform = await systemService.getPlatform();
/// ```
class SystemServiceClient {
  /// Creates a [SystemServiceClient] with the given [FluttronClient].
  SystemServiceClient(this._client);

  final FluttronClient _client;

  /// Returns the Host platform identifier.
  ///
  /// Possible values: `"macos"`, `"windows"`, `"linux"`, `"android"`, `"ios"`.
  Future<String> getPlatform() async {
    final result = await _client.invoke('system.getPlatform', {});
    if (result is Map) {
      final platform = result['platform'];
      if (platform != null) {
        return platform.toString();
      }
      return 'unknown';
    }
    return result?.toString() ?? 'unknown';
  }
}
