class FluttronClient {
  UnsupportedError _unsupported() {
    return UnsupportedError(
      'FluttronClient is only supported on Flutter Web runtime.',
    );
  }

  Future<dynamic> invoke(String method, Map<String, dynamic> params) {
    throw _unsupported();
  }

  /// Returns the Host platform identifier.
  ///
  /// Deprecated: Use [SystemServiceClient.getPlatform] instead.
  @Deprecated('Use SystemServiceClient(client).getPlatform() instead.')
  Future<String> getPlatform() {
    throw _unsupported();
  }

  /// Stores a key-value pair in Host storage.
  ///
  /// Deprecated: Use [StorageServiceClient.set] instead.
  @Deprecated('Use StorageServiceClient(client).set() instead.')
  Future<void> kvSet(String key, String value) {
    throw _unsupported();
  }

  /// Retrieves a value by key from Host storage.
  ///
  /// Deprecated: Use [StorageServiceClient.get] instead.
  @Deprecated('Use StorageServiceClient(client).get() instead.')
  Future<String?> kvGet(String key) {
    throw _unsupported();
  }
}
