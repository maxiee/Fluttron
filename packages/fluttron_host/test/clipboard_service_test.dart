import 'package:fluttron_host/src/services/clipboard_service.dart';
import 'package:fluttron_shared/fluttron_shared.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late ClipboardService service;

  setUp(() {
    service = ClipboardService();
  });

  group('namespace', () {
    test('returns "clipboard"', () {
      expect(service.namespace, equals('clipboard'));
    });
  });

  group('setText', () {
    test('throws BAD_PARAMS for missing text', () async {
      expect(
        () => service.handle('setText', {}),
        throwsA(
          isA<FluttronError>().having((e) => e.code, 'code', 'BAD_PARAMS'),
        ),
      );
    });

    test('throws BAD_PARAMS for non-string text', () async {
      expect(
        () => service.handle('setText', {'text': 123}),
        throwsA(
          isA<FluttronError>().having((e) => e.code, 'code', 'BAD_PARAMS'),
        ),
      );
    });

    test('throws BAD_PARAMS for null text', () async {
      expect(
        () => service.handle('setText', {'text': null}),
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

  // Note: Actual clipboard read/write operations require platform channels
  // and cannot be tested in unit tests. These are verified through manual testing.
  //
  // Manual Test Checklist for macOS:
  // 1. clipboard.setText - Set text and verify with Cmd+V in another app
  // 2. clipboard.getText - Copy text with Cmd+C, then invoke getText
  // 3. clipboard.hasText - Verify returns true when clipboard has content
  // 4. clipboard.hasText - Verify returns false after clearing clipboard
}
