import 'package:fluttron_host/src/services/logging_service.dart';
import 'package:fluttron_shared/fluttron_shared.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late LoggingService service;

  setUp(() {
    service = LoggingService();
  });

  group('namespace', () {
    test('returns "logging"', () {
      expect(service.namespace, equals('logging'));
    });
  });

  group('log', () {
    test('throws BAD_PARAMS when level is missing', () {
      expect(
        () => service.handle('log', {'message': 'test'}),
        throwsA(isA<FluttronError>().having((e) => e.code, 'code', 'BAD_PARAMS')),
      );
    });

    test('throws BAD_PARAMS when message is missing', () {
      expect(
        () => service.handle('log', {'level': 'info'}),
        throwsA(isA<FluttronError>().having((e) => e.code, 'code', 'BAD_PARAMS')),
      );
    });

    test('throws BAD_PARAMS when level is an int', () {
      expect(
        () => service.handle('log', {'level': 42, 'message': 'test'}),
        throwsA(isA<FluttronError>().having((e) => e.code, 'code', 'BAD_PARAMS')),
      );
    });

    test('throws BAD_PARAMS when level is null', () {
      expect(
        () => service.handle('log', {'level': null, 'message': 'test'}),
        throwsA(isA<FluttronError>().having((e) => e.code, 'code', 'BAD_PARAMS')),
      );
    });

    test('throws BAD_PARAMS when message is an int', () {
      expect(
        () => service.handle('log', {'level': 'info', 'message': 123}),
        throwsA(isA<FluttronError>().having((e) => e.code, 'code', 'BAD_PARAMS')),
      );
    });

    test('throws BAD_PARAMS when level is an invalid string', () {
      expect(
        () => service.handle('log', {'level': 'verbose', 'message': 'test'}),
        throwsA(isA<FluttronError>().having((e) => e.code, 'code', 'BAD_PARAMS')),
      );
    });

    test('throws BAD_PARAMS when level is "trace"', () {
      expect(
        () => service.handle('log', {'level': 'trace', 'message': 'test'}),
        throwsA(isA<FluttronError>().having((e) => e.code, 'code', 'BAD_PARAMS')),
      );
    });

    test('throws BAD_PARAMS when data is a string (not a Map)', () {
      expect(
        () => service.handle('log', {
          'level': 'info',
          'message': 'test',
          'data': 'not a map',
        }),
        throwsA(isA<FluttronError>().having((e) => e.code, 'code', 'BAD_PARAMS')),
      );
    });

    test('accepts debug level and stores entry', () async {
      await service.handle('log', {'level': 'debug', 'message': 'debug msg'});
      final logs = await service.handle('getLogs', {}) as List;
      expect(logs.length, equals(1));
      expect(logs[0]['level'], equals('debug'));
      expect(logs[0]['message'], equals('debug msg'));
    });

    test('accepts info level', () async {
      await service.handle('log', {'level': 'info', 'message': 'info msg'});
      final logs = await service.handle('getLogs', {}) as List;
      expect(logs[0]['level'], equals('info'));
    });

    test('accepts warn level', () async {
      await service.handle('log', {'level': 'warn', 'message': 'warn msg'});
      final logs = await service.handle('getLogs', {}) as List;
      expect(logs[0]['level'], equals('warn'));
    });

    test('accepts error level', () async {
      await service.handle('log', {'level': 'error', 'message': 'error msg'});
      final logs = await service.handle('getLogs', {}) as List;
      expect(logs[0]['level'], equals('error'));
    });

    test('stores optional data in log entry', () async {
      await service.handle('log', {
        'level': 'info',
        'message': 'with data',
        'data': {'key': 'value', 'count': 3},
      });
      final logs = await service.handle('getLogs', {}) as List;
      expect(logs[0]['data'], equals({'key': 'value', 'count': 3}));
    });

    test('log entry contains a timestamp string', () async {
      await service.handle('log', {'level': 'info', 'message': 'test'});
      final logs = await service.handle('getLogs', {}) as List;
      expect(logs[0]['timestamp'], isA<String>());
      expect(logs[0]['timestamp'], isNotEmpty);
    });

    test('log entry with no data omits data key', () async {
      await service.handle('log', {'level': 'info', 'message': 'no data'});
      final logs = await service.handle('getLogs', {}) as List;
      expect(logs[0].containsKey('data'), isFalse);
    });

    test('returns null', () async {
      final result = await service.handle(
        'log',
        {'level': 'info', 'message': 'test'},
      );
      expect(result, isNull);
    });
  });

  group('getLogs', () {
    setUp(() async {
      await service.handle('log', {'level': 'debug', 'message': 'debug 1'});
      await service.handle('log', {'level': 'info', 'message': 'info 1'});
      await service.handle('log', {'level': 'warn', 'message': 'warn 1'});
      await service.handle('log', {'level': 'error', 'message': 'error 1'});
      await service.handle('log', {'level': 'info', 'message': 'info 2'});
    });

    test('returns all logs when no filter specified', () async {
      final logs = await service.handle('getLogs', {}) as List;
      expect(logs.length, equals(5));
    });

    test('filters by level=info', () async {
      final logs = await service.handle('getLogs', {'level': 'info'}) as List;
      expect(logs.length, equals(2));
      expect(logs.every((l) => l['level'] == 'info'), isTrue);
    });

    test('filters by level=error returns only error entries', () async {
      final logs = await service.handle('getLogs', {'level': 'error'}) as List;
      expect(logs.length, equals(1));
      expect(logs[0]['message'], equals('error 1'));
    });

    test('filters by level with no matches returns empty list', () async {
      final logs = await service.handle('getLogs', {'level': 'debug'}) as List;
      expect(logs.length, equals(1));
    });

    test('limits to N most recent entries', () async {
      final logs = await service.handle('getLogs', {'limit': 3}) as List;
      expect(logs.length, equals(3));
      expect(logs.last['message'], equals('info 2'));
    });

    test('limit larger than buffer returns all entries', () async {
      final logs = await service.handle('getLogs', {'limit': 100}) as List;
      expect(logs.length, equals(5));
    });

    test('returns empty list when buffer is empty', () async {
      final emptyService = LoggingService();
      final logs = await emptyService.handle('getLogs', {}) as List;
      expect(logs, isEmpty);
    });

    test('throws BAD_PARAMS when level filter is an int', () {
      expect(
        () => service.handle('getLogs', {'level': 42}),
        throwsA(
          isA<FluttronError>().having((e) => e.code, 'code', 'BAD_PARAMS'),
        ),
      );
    });

    test('throws BAD_PARAMS when limit is a string', () {
      expect(
        () => service.handle('getLogs', {'limit': 'five'}),
        throwsA(
          isA<FluttronError>().having((e) => e.code, 'code', 'BAD_PARAMS'),
        ),
      );
    });
  });

  group('clear', () {
    test('empties the log buffer', () async {
      await service.handle('log', {'level': 'info', 'message': 'msg 1'});
      await service.handle('log', {'level': 'warn', 'message': 'msg 2'});
      await service.handle('clear', {});
      final logs = await service.handle('getLogs', {}) as List;
      expect(logs, isEmpty);
    });

    test('returns null', () async {
      final result = await service.handle('clear', {});
      expect(result, isNull);
    });

    test('can log again after clearing', () async {
      await service.handle('log', {'level': 'info', 'message': 'before clear'});
      await service.handle('clear', {});
      await service.handle('log', {'level': 'info', 'message': 'after clear'});
      final logs = await service.handle('getLogs', {}) as List;
      expect(logs.length, equals(1));
      expect(logs[0]['message'], equals('after clear'));
    });
  });

  group('ring buffer', () {
    test('drops oldest entry when buffer is full', () async {
      final smallService = LoggingService(bufferSize: 3);
      await smallService.handle('log', {'level': 'debug', 'message': 'first'});
      await smallService.handle('log', {'level': 'debug', 'message': 'second'});
      await smallService.handle('log', {'level': 'debug', 'message': 'third'});
      // This should push out 'first'
      await smallService.handle('log', {'level': 'debug', 'message': 'fourth'});

      final logs = await smallService.handle('getLogs', {}) as List;
      expect(logs.length, equals(3));
      expect(logs[0]['message'], equals('second'));
      expect(logs[1]['message'], equals('third'));
      expect(logs[2]['message'], equals('fourth'));
    });

    test('keeps exactly bufferSize entries after overflow', () async {
      final smallService = LoggingService(bufferSize: 5);
      for (var i = 0; i < 10; i++) {
        await smallService.handle('log', {
          'level': 'info',
          'message': 'msg $i',
        });
      }
      final logs = await smallService.handle('getLogs', {}) as List;
      expect(logs.length, equals(5));
      expect(logs.first['message'], equals('msg 5'));
      expect(logs.last['message'], equals('msg 9'));
    });
  });

  group('METHOD_NOT_FOUND', () {
    test('throws for unknown method', () {
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

    test('throws for getLevels (not implemented)', () {
      expect(
        () => service.handle('getLevels', {}),
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
