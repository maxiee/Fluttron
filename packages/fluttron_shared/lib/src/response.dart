class FluttronResponse {
  final String id;
  final bool ok;
  final dynamic result;
  final String? error;

  FluttronResponse._({
    required this.id,
    required this.ok,
    this.result,
    this.error,
  });

  factory FluttronResponse.ok(String id, dynamic result) =>
      FluttronResponse._(id: id, ok: true, result: result);

  factory FluttronResponse.err(String id, String error) =>
      FluttronResponse._(id: id, ok: false, error: error);

  Map<String, dynamic> toJson() => {
    'id': id,
    'ok': ok,
    'result': result,
    'error': error,
  };

  factory FluttronResponse.fromJson(Map<String, dynamic> json) {
    return FluttronResponse._(
      id: (json['id'] ?? '').toString(),
      ok: json['ok'] == true,
      result: json['result'],
      error: (json['error'] == null) ? null : json['error'].toString(),
    );
  }
}
