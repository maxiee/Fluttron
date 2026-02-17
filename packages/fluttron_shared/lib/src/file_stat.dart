/// Represents file system statistics for a path.
///
/// Returned by [FileServiceClient.stat] and Host's [FileService._stat].
class FileStat {
  /// Creates a [FileStat] with the given values.
  const FileStat({
    required this.exists,
    required this.isFile,
    required this.isDirectory,
    required this.size,
    required this.modified,
  });

  /// Creates a [FileStat] from a JSON map returned by the bridge.
  factory FileStat.fromMap(Map<String, dynamic> map) {
    return FileStat(
      exists: map['exists'] as bool,
      isFile: map['isFile'] as bool,
      isDirectory: map['isDirectory'] as bool,
      size: map['size'] as int,
      modified: map['modified'] as String,
    );
  }

  /// Whether the path exists on the file system.
  final bool exists;

  /// Whether the path is a file.
  final bool isFile;

  /// Whether the path is a directory.
  final bool isDirectory;

  /// Size in bytes (0 for directories).
  final int size;

  /// Last modified time in ISO 8601 format.
  final String modified;

  /// Converts to a JSON map for serialization.
  Map<String, dynamic> toMap() {
    return {
      'exists': exists,
      'isFile': isFile,
      'isDirectory': isDirectory,
      'size': size,
      'modified': modified,
    };
  }

  @override
  String toString() {
    return 'FileStat(exists: $exists, isFile: $isFile, '
        'isDirectory: $isDirectory, size: $size, modified: $modified)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FileStat &&
        other.exists == exists &&
        other.isFile == isFile &&
        other.isDirectory == isDirectory &&
        other.size == size &&
        other.modified == modified;
  }

  @override
  int get hashCode => Object.hash(exists, isFile, isDirectory, size, modified);
}
