import 'package:fluttron_ui/fluttron_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'file_service_client_test.dart' show FakeFluttronClient;

void main() {
  late FakeFluttronClient mockClient;
  late LoggingServiceClient loggingService;

  setUp(() {
    mockClient = FakeFluttronClient();
    loggingService = LoggingServiceClient(mockClient);
  });

  group('LoggingServiceClient', () {
    group('debug', () {
      test('invokes logging.log with level=debug', () async {
        var invoked = false;
        mockClient.whenInvoke('logging.log', (params) {
          expect(params['level'], equals('debug'));
          expect(params['message'], equals('Debug message'));
          invoked = true;
          return null;
        });

        await loggingService.debug('Debug message');
        expect(invoked, isTrue);
      });

      test('passes optional data map', () async {
        mockClient.whenInvoke('logging.log', (params) {
          expect(params['level'], equals('debug'));
          expect(params['data'], equals({'key': 'value'}));
          return null;
        });

        await loggingService.debug('With data', data: {'key': 'value'});
      });

      test('omits data key when data is null', () async {
        mockClient.whenInvoke('logging.log', (params) {
          expect(params.containsKey('data'), isFalse);
          return null;
        });

        await loggingService.debug('No data');
      });
    });

    group('info', () {
      test('invokes logging.log with level=info', () async {
        var invoked = false;
        mockClient.whenInvoke('logging.log', (params) {
          expect(params['level'], equals('info'));
          expect(params['message'], equals('Info message'));
          invoked = true;
          return null;
        });

        await loggingService.info('Info message');
        expect(invoked, isTrue);
      });

      test('passes optional data map', () async {
        mockClient.whenInvoke('logging.log', (params) {
          expect(params['data'], equals({'userId': 42}));
          return null;
        });

        await loggingService.info('User action', data: {'userId': 42});
      });
    });

    group('warn', () {
      test('invokes logging.log with level=warn', () async {
        var invoked = false;
        mockClient.whenInvoke('logging.log', (params) {
          expect(params['level'], equals('warn'));
          expect(params['message'], equals('Warn message'));
          invoked = true;
          return null;
        });

        await loggingService.warn('Warn message');
        expect(invoked, isTrue);
      });
    });

    group('error', () {
      test('invokes logging.log with level=error', () async {
        var invoked = false;
        mockClient.whenInvoke('logging.log', (params) {
          expect(params['level'], equals('error'));
          expect(params['message'], equals('Error message'));
          invoked = true;
          return null;
        });

        await loggingService.error('Error message');
        expect(invoked, isTrue);
      });

      test('passes error details in data map', () async {
        mockClient.whenInvoke('logging.log', (params) {
          expect(params['data'], equals({'reason': 'NullPointerException'}));
          return null;
        });

        await loggingService.error(
          'Crash',
          data: {'reason': 'NullPointerException'},
        );
      });
    });

    group('getLogs', () {
      test('invokes logging.getLogs with no params when no args given', () async {
        mockClient.whenInvoke('logging.getLogs', (params) {
          expect(params, isEmpty);
          return [
            {
              'timestamp': '2026-02-19T00:00:00.000Z',
              'level': 'info',
              'message': 'Test',
            },
          ];
        });

        final logs = await loggingService.getLogs();
        expect(logs.length, equals(1));
        expect(logs[0]['level'], equals('info'));
      });

      test('passes level filter when specified', () async {
        mockClient.whenInvoke('logging.getLogs', (params) {
          expect(params['level'], equals('error'));
          expect(params.containsKey('limit'), isFalse);
          return [];
        });

        await loggingService.getLogs(level: 'error');
      });

      test('passes limit when specified', () async {
        mockClient.whenInvoke('logging.getLogs', (params) {
          expect(params['limit'], equals(50));
          expect(params.containsKey('level'), isFalse);
          return [];
        });

        await loggingService.getLogs(limit: 50);
      });

      test('passes both level and limit', () async {
        mockClient.whenInvoke('logging.getLogs', (params) {
          expect(params['level'], equals('warn'));
          expect(params['limit'], equals(10));
          return [];
        });

        await loggingService.getLogs(level: 'warn', limit: 10);
      });

      test('returns list of log entry maps', () async {
        mockClient.whenInvoke('logging.getLogs', (params) {
          return [
            {'timestamp': 'ts1', 'level': 'debug', 'message': 'a'},
            {'timestamp': 'ts2', 'level': 'error', 'message': 'b'},
          ];
        });

        final logs = await loggingService.getLogs();
        expect(logs.length, equals(2));
        expect(logs[0]['message'], equals('a'));
        expect(logs[1]['message'], equals('b'));
      });
    });

    group('clear', () {
      test('invokes logging.clear with no params', () async {
        var invoked = false;
        mockClient.whenInvoke('logging.clear', (params) {
          expect(params, isEmpty);
          invoked = true;
          return null;
        });

        await loggingService.clear();
        expect(invoked, isTrue);
      });
    });

    group('error handling', () {
      test('debug propagates error from client', () async {
        mockClient.whenInvoke('logging.log', (params) {
          throw StateError('Host error');
        });

        expect(
          () => loggingService.debug('fail'),
          throwsA(isA<StateError>()),
        );
      });

      test('getLogs propagates error from client', () async {
        mockClient.whenInvoke('logging.getLogs', (params) {
          throw StateError('Host error');
        });

        expect(
          () => loggingService.getLogs(),
          throwsA(isA<StateError>()),
        );
      });
    });
  });
}
