import 'package:flutter_test/flutter_test.dart';
import 'package:fluttron_shared/fluttron_shared.dart';
import 'package:template_service_host/template_service_host.dart';

void main() {
  late TemplateService service;

  setUp(() {
    service = TemplateService();
  });

  test('namespace is template_service', () {
    expect(service.namespace, equals('template_service'));
  });

  group('greet', () {
    test('greets with default name', () async {
      final result = await service.handle('greet', {});
      expect(result, equals({'message': 'Hello, World!'}));
    });

    test('greets with custom name', () async {
      final result = await service.handle('greet', {'name': 'Alice'});
      expect(result, equals({'message': 'Hello, Alice!'}));
    });
  });

  group('echo', () {
    test('echoes text', () async {
      final result = await service.handle('echo', {'text': 'hello'});
      expect(result, equals({'text': 'hello'}));
    });

    test('throws on missing text', () async {
      expect(() => service.handle('echo', {}), throwsA(isA<FluttronError>()));
    });
  });

  test('throws on unknown method', () async {
    expect(() => service.handle('unknown', {}), throwsA(isA<FluttronError>()));
  });
}
