import 'package:fluttron_ui/fluttron_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'file_service_client_test.dart' show FakeFluttronClient;

void main() {
  late FakeFluttronClient mockClient;
  late StorageServiceClient storageService;

  setUp(() {
    mockClient = FakeFluttronClient();
    storageService = StorageServiceClient(mockClient);
  });

  group('StorageServiceClient', () {
    group('set', () {
      test('set invokes storage.kvSet with key and value', () async {
        var invoked = false;
        mockClient.whenInvoke('storage.kvSet', (params) {
          expect(params['key'], equals('theme'));
          expect(params['value'], equals('dark'));
          invoked = true;
          return {};
        });

        await storageService.set('theme', 'dark');
        expect(invoked, isTrue);
      });

      test('set works with empty value', () async {
        var invoked = false;
        mockClient.whenInvoke('storage.kvSet', (params) {
          expect(params['key'], equals('empty_key'));
          expect(params['value'], equals(''));
          invoked = true;
          return {};
        });

        await storageService.set('empty_key', '');
        expect(invoked, isTrue);
      });
    });

    group('get', () {
      test('get invokes storage.kvGet with key', () async {
        mockClient.whenInvoke('storage.kvGet', (params) {
          expect(params['key'], equals('theme'));
          return {'value': 'dark'};
        });

        final value = await storageService.get('theme');
        expect(value, equals('dark'));
      });

      test('get returns null when key does not exist', () async {
        mockClient.whenInvoke('storage.kvGet', (params) {
          return {'value': null};
        });

        final value = await storageService.get('nonexistent');
        expect(value, isNull);
      });

      test('get returns null when result is null', () async {
        mockClient.whenInvoke('storage.kvGet', (params) {
          return null;
        });

        final value = await storageService.get('missing');
        expect(value, isNull);
      });

      test('get handles non-Map result', () async {
        mockClient.whenInvoke('storage.kvGet', (params) {
          return 'direct_value';
        });

        final value = await storageService.get('some_key');
        expect(value, equals('direct_value'));
      });

      test('get handles empty Map result', () async {
        mockClient.whenInvoke('storage.kvGet', (params) {
          return <String, dynamic>{};
        });

        final value = await storageService.get('missing_value_key');
        expect(value, isNull);
      });

      test('get converts value to string', () async {
        mockClient.whenInvoke('storage.kvGet', (params) {
          return {'value': 12345};
        });

        final value = await storageService.get('numeric_value');
        expect(value, equals('12345'));
      });
    });

    group('round-trip', () {
      test('set and get work together', () async {
        final storage = <String, String>{};

        mockClient.whenInvoke('storage.kvSet', (params) {
          storage[params['key'] as String] = params['value'] as String;
          return {};
        });

        mockClient.whenInvoke('storage.kvGet', (params) {
          final key = params['key'] as String;
          return {'value': storage[key]};
        });

        await storageService.set('test_key', 'test_value');
        final value = await storageService.get('test_key');
        expect(value, equals('test_value'));
      });
    });
  });
}
