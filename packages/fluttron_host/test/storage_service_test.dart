import 'package:fluttron_host/src/services/storage_service.dart';
import 'package:fluttron_shared/fluttron_shared.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late StorageService service;

  setUp(() {
    service = StorageService();
  });

  group('namespace', () {
    test('returns "storage"', () {
      expect(service.namespace, equals('storage'));
    });
  });

  group('kvSet', () {
    test('stores key-value and returns ok', () async {
      final result = await service.handle('kvSet', {
        'key': 'theme',
        'value': 'dark',
      });
      expect(result, equals({'ok': true}));
    });

    test('accepts empty string value', () async {
      await service.handle('kvSet', {'key': 'draft', 'value': ''});
      final result = await service.handle('kvGet', {'key': 'draft'});
      expect(result, equals({'value': ''}));
    });

    test('throws BAD_PARAMS for missing key', () async {
      expect(
        () => service.handle('kvSet', {'value': 'dark'}),
        throwsA(
          isA<FluttronError>().having((e) => e.code, 'code', 'BAD_PARAMS'),
        ),
      );
    });

    test('throws BAD_PARAMS for empty key', () async {
      expect(
        () => service.handle('kvSet', {'key': '', 'value': 'dark'}),
        throwsA(
          isA<FluttronError>().having((e) => e.code, 'code', 'BAD_PARAMS'),
        ),
      );
    });

    test('throws BAD_PARAMS for non-string value', () async {
      expect(
        () => service.handle('kvSet', {'key': 'theme', 'value': 1}),
        throwsA(
          isA<FluttronError>().having((e) => e.code, 'code', 'BAD_PARAMS'),
        ),
      );
    });
  });

  group('kvGet', () {
    test('returns stored value', () async {
      await service.handle('kvSet', {'key': 'theme', 'value': 'light'});
      final result = await service.handle('kvGet', {'key': 'theme'});
      expect(result, equals({'value': 'light'}));
    });

    test('returns null for missing key', () async {
      final result = await service.handle('kvGet', {'key': 'missing'});
      expect(result, equals({'value': null}));
    });

    test('throws BAD_PARAMS for empty key', () async {
      expect(
        () => service.handle('kvGet', {'key': ''}),
        throwsA(
          isA<FluttronError>().having((e) => e.code, 'code', 'BAD_PARAMS'),
        ),
      );
    });
  });

  group('METHOD_NOT_FOUND', () {
    test('throws for unknown method', () async {
      expect(
        () => service.handle('unknownMethod', {}),
        throwsA(
          isA<FluttronError>().having(
            (e) => e.code,
            'code',
            'METHOD_NOT_FOUND',
          ),
        ),
      );
    });
  });
}
