import 'dart:io';

import 'package:fluttron_host/src/services/service.dart';
import 'package:fluttron_shared/fluttron_shared.dart';

/// Host service for file system operations.
///
/// Provides methods for reading, writing, listing, and managing files
/// and directories. All paths are absolute paths.
///
/// Security note: No path traversal protection in v1 (trusted desktop app context).
/// Future: configurable sandbox / allowed paths list.
class FileService extends FluttronService {
  @override
  String get namespace => 'file';

  @override
  Future<dynamic> handle(String method, Map<String, dynamic> params) async {
    switch (method) {
      case 'readFile':
        return _readFile(params);
      case 'writeFile':
        return _writeFile(params);
      case 'listDirectory':
        return _listDirectory(params);
      case 'stat':
        return _stat(params);
      case 'createFile':
        return _createFile(params);
      case 'delete':
        return _delete(params);
      case 'rename':
        return _rename(params);
      case 'exists':
        return _exists(params);
      default:
        throw FluttronError('METHOD_NOT_FOUND', 'file.$method not implemented');
    }
  }

  /// Reads a file as a UTF-8 string.
  ///
  /// Params:
  /// - path: (required) The absolute path to the file.
  ///
  /// Returns:
  /// - content: The file contents as a string.
  Map<String, dynamic> _readFile(Map<String, dynamic> params) {
    final path = _requirePath(params, 'path');
    final file = File(path);

    if (!file.existsSync()) {
      throw FluttronError('FILE_NOT_FOUND', 'File not found: $path');
    }

    final content = file.readAsStringSync();
    return {'content': content};
  }

  /// Writes a UTF-8 string to a file.
  ///
  /// Params:
  /// - path: (required) The absolute path to the file.
  /// - content: (required) The content to write.
  ///
  /// Returns: empty object on success.
  Map<String, dynamic> _writeFile(Map<String, dynamic> params) {
    final path = _requirePath(params, 'path');
    final content = _requireString(params, 'content', allowEmpty: true);

    final file = File(path);

    // Create parent directories if they don't exist
    final parent = file.parent;
    if (!parent.existsSync()) {
      parent.createSync(recursive: true);
    }

    file.writeAsStringSync(content);
    return {};
  }

  /// Lists the contents of a directory.
  ///
  /// Params:
  /// - path: (required) The absolute path to the directory.
  ///
  /// Returns:
  /// - entries: An array of FileEntry objects.
  Map<String, dynamic> _listDirectory(Map<String, dynamic> params) {
    final path = _requirePath(params, 'path');
    final dir = Directory(path);

    if (!dir.existsSync()) {
      throw FluttronError('DIRECTORY_NOT_FOUND', 'Directory not found: $path');
    }

    final entries = <Map<String, dynamic>>[];

    final list = dir.listSync();
    for (final entity in list) {
      final stat = entity.statSync();
      entries.add({
        'name': entity.path.split(Platform.pathSeparator).last,
        'path': entity.path,
        'isFile': entity is File,
        'isDirectory': entity is Directory,
        'size': entity is Directory ? 0 : stat.size,
        'modified': stat.modified.toUtc().toIso8601String(),
      });
    }

    // Sort: directories first, then by name
    entries.sort((a, b) {
      final aIsDir = a['isDirectory'] as bool;
      final bIsDir = b['isDirectory'] as bool;
      if (aIsDir != bIsDir) {
        return aIsDir ? -1 : 1;
      }
      return (a['name'] as String).compareTo(b['name'] as String);
    });

    return {'entries': entries};
  }

  /// Gets statistics about a file or directory.
  ///
  /// Params:
  /// - path: (required) The absolute path to the file or directory.
  ///
  /// Returns:
  /// - exists: Whether the path exists.
  /// - isFile: Whether it's a file.
  /// - isDirectory: Whether it's a directory.
  /// - size: Size in bytes (0 for directories).
  /// - modified: Last modified time in ISO 8601 format.
  Map<String, dynamic> _stat(Map<String, dynamic> params) {
    final path = _requirePath(params, 'path');

    final file = File(path);
    final dir = Directory(path);

    final exists = file.existsSync() || dir.existsSync();

    if (!exists) {
      return {
        'exists': false,
        'isFile': false,
        'isDirectory': false,
        'size': 0,
        'modified': '',
      };
    }

    final isFile = file.existsSync();
    final entity = isFile ? file as FileSystemEntity : dir as FileSystemEntity;
    final stat = entity.statSync();

    return {
      'exists': true,
      'isFile': isFile,
      'isDirectory': !isFile,
      'size': isFile ? stat.size : 0,
      'modified': stat.modified.toUtc().toIso8601String(),
    };
  }

  /// Creates a new file with optional content.
  ///
  /// Params:
  /// - path: (required) The absolute path for the new file.
  /// - content: (optional) Initial content for the file. Defaults to empty string.
  ///
  /// Returns: empty object on success.
  Map<String, dynamic> _createFile(Map<String, dynamic> params) {
    final path = _requirePath(params, 'path');
    final content = _optionalString(params, 'content') ?? '';

    final file = File(path);

    if (file.existsSync()) {
      throw FluttronError('FILE_EXISTS', 'File already exists: $path');
    }

    // Create parent directories if they don't exist
    final parent = file.parent;
    if (!parent.existsSync()) {
      parent.createSync(recursive: true);
    }

    file.writeAsStringSync(content);
    return {};
  }

  /// Deletes a file or empty directory.
  ///
  /// Params:
  /// - path: (required) The absolute path to delete.
  ///
  /// Returns: empty object on success.
  Map<String, dynamic> _delete(Map<String, dynamic> params) {
    final path = _requirePath(params, 'path');

    final file = File(path);
    final dir = Directory(path);

    if (file.existsSync()) {
      file.deleteSync();
      return {};
    }

    if (dir.existsSync()) {
      // Only delete empty directories for safety
      final contents = dir.listSync();
      if (contents.isNotEmpty) {
        throw FluttronError(
          'DIRECTORY_NOT_EMPTY',
          'Directory is not empty: $path',
        );
      }
      dir.deleteSync();
      return {};
    }

    throw FluttronError('NOT_FOUND', 'File or directory not found: $path');
  }

  /// Renames or moves a file.
  ///
  /// Params:
  /// - oldPath: (required) The current path.
  /// - newPath: (required) The new path.
  ///
  /// Returns: empty object on success.
  Map<String, dynamic> _rename(Map<String, dynamic> params) {
    final oldPath = _requirePath(params, 'oldPath');
    final newPath = _requirePath(params, 'newPath');

    final file = File(oldPath);
    final dir = Directory(oldPath);

    if (file.existsSync()) {
      file.renameSync(newPath);
      return {};
    }

    if (dir.existsSync()) {
      dir.renameSync(newPath);
      return {};
    }

    throw FluttronError('NOT_FOUND', 'File or directory not found: $oldPath');
  }

  /// Checks if a path exists.
  ///
  /// Params:
  /// - path: (required) The absolute path to check.
  ///
  /// Returns:
  /// - exists: Whether the path exists.
  Map<String, dynamic> _exists(Map<String, dynamic> params) {
    final path = _requirePath(params, 'path');

    final file = File(path);
    final dir = Directory(path);

    final exists = file.existsSync() || dir.existsSync();
    return {'exists': exists};
  }

  /// Helper to require a string parameter.
  String _requirePath(Map<String, dynamic> params, String key) {
    return _requireString(params, key, allowEmpty: false);
  }

  String _requireString(
    Map<String, dynamic> params,
    String key, {
    required bool allowEmpty,
  }) {
    final v = params[key];
    if (v is String && (allowEmpty || v.isNotEmpty)) {
      return v;
    }
    throw FluttronError('BAD_PARAMS', 'Missing or invalid "$key"');
  }

  String? _optionalString(Map<String, dynamic> params, String key) {
    final value = params[key];
    if (value == null) {
      return null;
    }
    if (value is String) {
      return value;
    }
    throw FluttronError('BAD_PARAMS', 'Missing or invalid "$key"');
  }
}
