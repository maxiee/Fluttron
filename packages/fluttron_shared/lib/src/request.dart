class FluttronRequest {
  final String id;
  final String method;
  final Map<String, dynamic> params;

  FluttronRequest({
    required this.id,
    required this.method,
    Map<String, dynamic>? params,
  }) : params = params ?? <String, dynamic>{};

  Map<String, dynamic> toJson() => {
    'id': id,
    'method': method,
    'params': params,
  };

  factory FluttronRequest.fromJson(Map<String, dynamic> json) {
    return FluttronRequest(
      id: (json['id'] ?? '').toString(),
      method: (json['method'] ?? '').toString(),
      params: (json['params'] is Map)
          ? Map<String, dynamic>.from(json['params'] as Map)
          : <String, dynamic>{},
    );
  }
}
