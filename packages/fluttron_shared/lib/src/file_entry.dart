/// Represents a file or directory entry returned by FileService.listDirectory.
class FileEntry {
  /// The name of the file or directory (without path).
  final String name;

  /// The full absolute path to the file or directory.
  final String path;

  /// Whether this entry is a file.
  final bool isFile;

  /// Whether this entry is a directory.
  final bool isDirectory;

  /// The size in bytes. 0 for directories.
  final int size;

  /// The last modified time in ISO 8601 format.
  final String modified;

  const FileEntry({
    required this.name,
    required this.path,
    required this.isFile,
    required this.isDirectory,
    required this.size,
    required this.modified,
  });

  /// Creates a FileEntry from a JSON map returned by the bridge.
  factory FileEntry.fromMap(Map<String, dynamic> map) {
    return FileEntry(
      name: map['name'] as String,
      path: map['path'] as String,
      isFile: map['isFile'] as bool,
      isDirectory: map['isDirectory'] as bool,
      size: map['size'] as int,
      modified: map['modified'] as String,
    );
  }

  /// Converts the FileEntry to a JSON map for serialization.
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'path': path,
      'isFile': isFile,
      'isDirectory': isDirectory,
      'size': size,
      'modified': modified,
    };
  }

  @override
  String toString() {
    return 'FileEntry(name: $name, path: $path, isFile: $isFile, '
        'isDirectory: $isDirectory, size: $size, modified: $modified)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FileEntry &&
        other.name == name &&
        other.path == path &&
        other.isFile == isFile &&
        other.isDirectory == isDirectory &&
        other.size == size &&
        other.modified == modified;
  }

  @override
  int get hashCode {
    return Object.hash(name, path, isFile, isDirectory, size, modified);
  }
}
