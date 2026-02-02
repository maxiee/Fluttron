class FluttronError implements Exception {
  final String code; // e.g. "METHOD_NOT_FOUND", "BAD_PARAMS"
  final String message;

  FluttronError(this.code, this.message);

  Map<String, dynamic> toJson() => {'code': code, 'message': message};

  @override
  String toString() => 'FluttronError($code): $message';
}
