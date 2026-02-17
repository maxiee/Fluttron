import 'package:fluttron_shared/fluttron_shared.dart';
import 'package:fluttron_ui/fluttron_ui.dart';

/// Client for file.* Host service operations.
///
/// Provides type-safe wrappers around FluttronClient.invoke() for file operations.
class FileServiceClient {
  /// Creates a FileServiceClient with the given FluttronClient.
  FileServiceClient(this._client);

  final FluttronClient _client;

  /// Reads a file as a UTF-8 string.
  ///
  /// Throws [StateError] if the file is not found or cannot be read.
  Future<String> readFile(String path) async {
    final result = await _client.invoke('file.readFile', {'path': path});
    return result['content'] as String;
  }

  /// Writes a UTF-8 string to a file.
  ///
  /// Creates parent directories if they don't exist.
  Future<void> writeFile(String path, String content) async {
    await _client.invoke('file.writeFile', {'path': path, 'content': content});
  }

  /// Lists the contents of a directory.
  ///
  /// Returns a list of [FileEntry] objects sorted by:
  /// 1. Directories first
  /// 2. Alphabetically by name
  Future<List<FileEntry>> listDirectory(String path) async {
    final result = await _client.invoke('file.listDirectory', {'path': path});
    final entries = result['entries'] as List<dynamic>;
    return entries
        .map((e) => FileEntry.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// Gets statistics about a file or directory.
  Future<FileStat> stat(String path) async {
    final result = await _client.invoke('file.stat', {'path': path});
    return FileStat.fromMap(Map<String, dynamic>.from(result as Map));
  }

  /// Creates a new file with optional content.
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

  /// Checks if a path exists.
  Future<bool> exists(String path) async {
    final result = await _client.invoke('file.exists', {'path': path});
    return result['exists'] as bool;
  }
}

/// Represents file statistics returned by [FileServiceClient.stat].
class FileStat {
  /// Creates a FileStat from the given values.
  const FileStat({
    required this.exists,
    required this.isFile,
    required this.isDirectory,
    required this.size,
    required this.modified,
  });

  /// Creates a FileStat from a JSON map.
  factory FileStat.fromMap(Map<String, dynamic> map) {
    return FileStat(
      exists: map['exists'] as bool,
      isFile: map['isFile'] as bool,
      isDirectory: map['isDirectory'] as bool,
      size: map['size'] as int,
      modified: map['modified'] as String,
    );
  }

  /// Whether the path exists.
  final bool exists;

  /// Whether it's a file.
  final bool isFile;

  /// Whether it's a directory.
  final bool isDirectory;

  /// Size in bytes (0 for directories).
  final int size;

  /// Last modified time in ISO 8601 format.
  final String modified;
}
