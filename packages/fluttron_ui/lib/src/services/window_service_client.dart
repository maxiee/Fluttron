import 'package:fluttron_ui/fluttron_ui.dart';

/// Type-safe client for the built-in `window.*` Host service.
///
/// Provides window management capabilities from the UI side.
///
/// Usage:
/// ```dart
/// final client = FluttronClient();
/// final windowService = WindowServiceClient(client);
/// await windowService.setTitle('My App');
/// await windowService.setSize(1280, 720);
/// ```
class WindowServiceClient {
  /// Creates a [WindowServiceClient] with the given [FluttronClient].
  WindowServiceClient(this._client);

  final FluttronClient _client;

  /// Set the window title.
  Future<void> setTitle(String title) async {
    await _client.invoke('window.setTitle', {'title': title});
  }

  /// Set the window size in logical pixels.
  Future<void> setSize(int width, int height) async {
    await _client.invoke('window.setSize', {'width': width, 'height': height});
  }

  /// Get the current window size.
  Future<Map<String, int>> getSize() async {
    final result = await _client.invoke('window.getSize', {});
    return {
      'width': result['width'] as int,
      'height': result['height'] as int,
    };
  }

  /// Minimize the window.
  Future<void> minimize() async {
    await _client.invoke('window.minimize', {});
  }

  /// Maximize or restore the window.
  Future<void> maximize() async {
    await _client.invoke('window.maximize', {});
  }

  /// Toggle fullscreen mode.
  Future<void> setFullScreen(bool enabled) async {
    await _client.invoke('window.setFullScreen', {'enabled': enabled});
  }

  /// Check if the window is in fullscreen mode.
  Future<bool> isFullScreen() async {
    final result = await _client.invoke('window.isFullScreen', {});
    return result['result'] as bool;
  }

  /// Center the window on screen.
  Future<void> center() async {
    await _client.invoke('window.center', {});
  }

  /// Set the minimum window size.
  Future<void> setMinSize(int width, int height) async {
    await _client.invoke(
      'window.setMinSize',
      {'width': width, 'height': height},
    );
  }
}
