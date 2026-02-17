import 'package:fluttron_ui/fluttron_ui.dart';

/// Client for dialog.* Host service operations.
///
/// Provides type-safe wrappers around FluttronClient.invoke() for native dialogs.
class DialogServiceClient {
  /// Creates a DialogServiceClient with the given FluttronClient.
  DialogServiceClient(this._client);

  final FluttronClient _client;

  /// Opens a single file picker dialog.
  ///
  /// Returns the selected file path, or null if the user cancelled.
  ///
  /// Parameters:
  /// - [title]: Optional dialog title.
  /// - [allowedExtensions]: Optional list of allowed file extensions (e.g., ['md', 'txt']).
  /// - [initialDirectory]: Optional starting directory.
  Future<String?> openFile({
    String? title,
    List<String>? allowedExtensions,
    String? initialDirectory,
  }) async {
    final result = await _client.invoke('dialog.openFile', {
      if (title != null) 'title': title,
      if (allowedExtensions != null) 'allowedExtensions': allowedExtensions,
      if (initialDirectory != null) 'initialDirectory': initialDirectory,
    });
    return result['path'] as String?;
  }

  /// Opens a multiple file picker dialog.
  ///
  /// Returns a list of selected file paths (empty if cancelled).
  ///
  /// Parameters:
  /// - [title]: Optional dialog title.
  /// - [allowedExtensions]: Optional list of allowed file extensions.
  /// - [initialDirectory]: Optional starting directory.
  Future<List<String>> openFiles({
    String? title,
    List<String>? allowedExtensions,
    String? initialDirectory,
  }) async {
    final result = await _client.invoke('dialog.openFiles', {
      if (title != null) 'title': title,
      if (allowedExtensions != null) 'allowedExtensions': allowedExtensions,
      if (initialDirectory != null) 'initialDirectory': initialDirectory,
    });
    final paths = result['paths'] as List<dynamic>;
    return paths.map((p) => p as String).toList();
  }

  /// Opens a directory picker dialog.
  ///
  /// Returns the selected directory path, or null if the user cancelled.
  ///
  /// Parameters:
  /// - [title]: Optional dialog title.
  /// - [initialDirectory]: Optional starting directory.
  Future<String?> openDirectory({
    String? title,
    String? initialDirectory,
  }) async {
    final result = await _client.invoke('dialog.openDirectory', {
      if (title != null) 'title': title,
      if (initialDirectory != null) 'initialDirectory': initialDirectory,
    });
    return result['path'] as String?;
  }

  /// Opens a save file dialog.
  ///
  /// Returns the selected save path, or null if the user cancelled.
  ///
  /// Parameters:
  /// - [title]: Optional dialog title.
  /// - [defaultFileName]: Optional default file name.
  /// - [allowedExtensions]: Optional list of allowed file extensions.
  /// - [initialDirectory]: Optional starting directory.
  Future<String?> saveFile({
    String? title,
    String? defaultFileName,
    List<String>? allowedExtensions,
    String? initialDirectory,
  }) async {
    final result = await _client.invoke('dialog.saveFile', {
      if (title != null) 'title': title,
      if (defaultFileName != null) 'defaultFileName': defaultFileName,
      if (allowedExtensions != null) 'allowedExtensions': allowedExtensions,
      if (initialDirectory != null) 'initialDirectory': initialDirectory,
    });
    return result['path'] as String?;
  }
}
