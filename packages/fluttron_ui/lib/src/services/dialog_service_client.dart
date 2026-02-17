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
