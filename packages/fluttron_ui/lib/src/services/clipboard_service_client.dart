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
