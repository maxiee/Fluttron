import 'package:fluttron_shared/fluttron_shared.dart';
import 'package:fluttron_ui/fluttron_ui.dart';

/// Type-safe client for the built-in `file.*` Host service.
///
/// Wraps [FluttronClient.invoke] calls with proper parameter construction
/// and response deserialization.
///
/// Usage:
/// ```dart
/// final client = FluttronClient();
/// final fileService = FileServiceClient(client);
/// final content = await fileService.readFile('/path/to/file.md');
/// ```
class FileServiceClient {
  /// Creates a [FileServiceClient] with the given [FluttronClient].
  FileServiceClient(this._client);

  final FluttronClient _client;

  /// Reads a file as a UTF-8 string.
  ///
  /// [path] must be an absolute path.
  ///
  /// Throws [StateError] if the file does not exist or cannot be read.
  Future<String> readFile(String path) async {
    final result = await _client.invoke('file.readFile', {'path': path});
    return result['content'] as String;
  }

  /// Writes a UTF-8 string to a file.
  ///
  /// Creates parent directories if they don't exist.
  /// Overwrites existing file content.
  Future<void> writeFile(String path, String content) async {
    await _client.invoke('file.writeFile', {'path': path, 'content': content});
  }

  /// Lists the contents of a directory.
  ///
  /// Returns a list of [FileEntry] sorted directories-first, then alphabetically.
  Future<List<FileEntry>> listDirectory(String path) async {
    final result = await _client.invoke('file.listDirectory', {'path': path});
    final entries = result['entries'] as List<dynamic>;
    return entries
        .map((e) => FileEntry.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// Gets file or directory statistics.
  ///
  /// Returns a [FileStat] with existence, type, size, and modification info.
  Future<FileStat> stat(String path) async {
    final result = await _client.invoke('file.stat', {'path': path});
    return FileStat.fromMap(Map<String, dynamic>.from(result as Map));
  }

  /// Creates a new empty file with optional initial [content].
  ///
  /// Throws [StateError] if the file already exists.
  Future<void> createFile(String path, {String content = ''}) async {
    await _client.invoke('file.createFile', {'path': path, 'content': content});
  }

  /// Deletes a file or empty directory.
  ///
  /// Throws [StateError] if the path doesn't exist or the directory is not empty.
  Future<void> delete(String path) async {
    await _client.invoke('file.delete', {'path': path});
  }

  /// Renames or moves a file or directory.
  ///
  /// Throws [StateError] if the source path doesn't exist.
  Future<void> rename(String oldPath, String newPath) async {
    await _client.invoke('file.rename', {
      'oldPath': oldPath,
      'newPath': newPath,
    });
  }

  /// Checks whether a path exists on the file system.
  Future<bool> exists(String path) async {
    final result = await _client.invoke('file.exists', {'path': path});
    return result['exists'] as bool;
  }
}
