import 'package:file_selector/file_selector.dart';
import 'package:fluttron_host/src/services/service.dart';
import 'package:fluttron_shared/fluttron_shared.dart';

/// Host service for native file and directory dialogs.
///
/// Provides methods for opening native OS file picker dialogs.
/// Uses file_selector package for cross-platform support.
/// Currently tested on macOS.
class DialogService extends FluttronService {
  @override
  String get namespace => 'dialog';

  @override
  Future<dynamic> handle(String method, Map<String, dynamic> params) async {
    switch (method) {
      case 'openFile':
        return _openFile(params);
      case 'openFiles':
        return _openFiles(params);
      case 'openDirectory':
        return _openDirectory(params);
      case 'saveFile':
        return _saveFile(params);
      default:
        throw FluttronError(
          'METHOD_NOT_FOUND',
          'dialog.$method not implemented',
        );
    }
  }

  /// Opens a single file picker dialog.
  ///
  /// Params:
  /// - title: (optional) Dialog title.
  /// - allowedExtensions: (optional) List of allowed file extensions (e.g., ['md', 'txt']).
  /// - initialDirectory: (optional) Starting directory.
  ///
  /// Returns:
  /// - path: Selected file path, or null if cancelled.
  Future<Map<String, dynamic>> _openFile(Map<String, dynamic> params) async {
    final title = params['title'] as String?;
    final allowedExtensions = (params['allowedExtensions'] as List<dynamic>?)
        ?.map((e) => e.toString())
        .toList();
    final initialDirectory = params['initialDirectory'] as String?;

    final xTypeGroup = XTypeGroup(label: title, extensions: allowedExtensions);

    final path = await openFile(
      acceptedTypeGroups: allowedExtensions != null ? [xTypeGroup] : [],
      initialDirectory: initialDirectory,
    );

    return {'path': path?.path};
  }

  /// Opens a multiple file picker dialog.
  ///
  /// Params:
  /// - title: (optional) Dialog title.
  /// - allowedExtensions: (optional) List of allowed file extensions.
  /// - initialDirectory: (optional) Starting directory.
  ///
  /// Returns:
  /// - paths: List of selected file paths (empty if cancelled).
  Future<Map<String, dynamic>> _openFiles(Map<String, dynamic> params) async {
    final title = params['title'] as String?;
    final allowedExtensions = (params['allowedExtensions'] as List<dynamic>?)
        ?.map((e) => e.toString())
        .toList();
    final initialDirectory = params['initialDirectory'] as String?;

    final xTypeGroup = XTypeGroup(label: title, extensions: allowedExtensions);

    final files = await openFiles(
      acceptedTypeGroups: allowedExtensions != null ? [xTypeGroup] : [],
      initialDirectory: initialDirectory,
    );

    return {'paths': files.map((f) => f.path).toList()};
  }

  /// Opens a directory picker dialog.
  ///
  /// Params:
  /// - title: (optional) Dialog title.
  /// - initialDirectory: (optional) Starting directory.
  ///
  /// Returns:
  /// - path: Selected directory path, or null if cancelled.
  Future<Map<String, dynamic>> _openDirectory(
    Map<String, dynamic> params,
  ) async {
    final initialDirectory = params['initialDirectory'] as String?;

    final path = await getDirectoryPath(initialDirectory: initialDirectory);

    return {'path': path};
  }

  /// Opens a save file dialog.
  ///
  /// Params:
  /// - title: (optional) Dialog title.
  /// - defaultFileName: (optional) Default file name.
  /// - allowedExtensions: (optional) List of allowed file extensions.
  /// - initialDirectory: (optional) Starting directory.
  ///
  /// Returns:
  /// - path: Selected save path, or null if cancelled.
  Future<Map<String, dynamic>> _saveFile(Map<String, dynamic> params) async {
    final title = params['title'] as String?;
    final defaultFileName = params['defaultFileName'] as String?;
    final allowedExtensions = (params['allowedExtensions'] as List<dynamic>?)
        ?.map((e) => e.toString())
        .toList();
    final initialDirectory = params['initialDirectory'] as String?;

    final xTypeGroup = XTypeGroup(label: title, extensions: allowedExtensions);

    final path = await getSaveLocation(
      acceptedTypeGroups: allowedExtensions != null ? [xTypeGroup] : [],
      initialDirectory: initialDirectory,
      suggestedName: defaultFileName,
    );

    return {'path': path?.path};
  }
}
