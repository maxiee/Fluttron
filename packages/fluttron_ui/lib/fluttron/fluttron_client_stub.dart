class FluttronClient {
  UnsupportedError _unsupported() {
    return UnsupportedError(
      'FluttronClient is only supported on Flutter Web runtime.',
    );
  }

  Future<dynamic> invoke(String method, Map<String, dynamic> params) {
    throw _unsupported();
  }

  Future<String> getPlatform() {
    throw _unsupported();
  }

  Future<void> kvSet(String key, String value) {
    throw _unsupported();
  }

  Future<String?> kvGet(String key) {
    throw _unsupported();
  }
}
