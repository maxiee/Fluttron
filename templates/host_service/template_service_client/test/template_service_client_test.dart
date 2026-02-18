import 'package:flutter_test/flutter_test.dart';
import 'package:fluttron_ui/fluttron_ui.dart';
import 'package:template_service_client/template_service_client.dart';

/// A fake [FluttronClient] for testing method routing and params.
class FakeFluttronClient extends FluttronClient {
  final Map<String, dynamic Function(Map<String, dynamic>)> _handlers = {};

  void whenInvoke(
    String method,
    dynamic Function(Map<String, dynamic>) handler,
  ) {
    _handlers[method] = handler;
  }

  @override
  Future<dynamic> invoke(String method, Map<String, dynamic> params) async {
    final handler = _handlers[method];
    if (handler == null) {
      throw StateError('No handler registered for $method');
    }
    return handler(params);
  }
}

void main() {
  late FakeFluttronClient client;
  late TemplateServiceClient service;

  setUp(() {
    client = FakeFluttronClient();
    service = TemplateServiceClient(client);
  });

  test('greet uses optional name parameter', () async {
    client.whenInvoke('template_service.greet', (params) {
      expect(params, equals({'name': 'Alice'}));
      return {'message': 'Hello, Alice!'};
    });

    final message = await service.greet(name: 'Alice');
    expect(message, equals('Hello, Alice!'));
  });

  test('greet sends empty params when name is omitted', () async {
    client.whenInvoke('template_service.greet', (params) {
      expect(params, isEmpty);
      return {'message': 'Hello, World!'};
    });

    final message = await service.greet();
    expect(message, equals('Hello, World!'));
  });

  test('echo forwards text parameter', () async {
    client.whenInvoke('template_service.echo', (params) {
      expect(params, equals({'text': 'ping'}));
      return {'text': 'ping'};
    });

    final text = await service.echo('ping');
    expect(text, equals('ping'));
  });
}
