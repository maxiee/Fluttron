import 'package:fluttron_ui/fluttron_ui.dart';
import 'package:flutter_test/flutter_test.dart';

/// A fake [FluttronClient] for testing that allows mocking invoke calls.
class FakeFluttronClient extends FluttronClient {
  final Map<String, dynamic Function(Map<String, dynamic>)> _handlers = {};

  /// Registers a handler for a specific method.
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
      throw StateError('No mock handler for $method');
    }
    return handler(params);
  }
}

void main() {
  late FakeFluttronClient mockClient;
  late ClipboardServiceClient clipboardService;

  setUp(() {
    mockClient = FakeFluttronClient();
    clipboardService = ClipboardServiceClient(mockClient);
  });

  group('ClipboardServiceClient', () {
    group('getText', () {
      test('invokes clipboard.getText and returns text', () async {
        mockClient.whenInvoke('clipboard.getText', (params) {
          expect(params, isEmpty);
          return {'text': 'copied text'};
        });

        final result = await clipboardService.getText();
        expect(result, equals('copied text'));
      });

      test('returns null when no text available', () async {
        mockClient.whenInvoke('clipboard.getText', (params) {
          return {'text': null};
        });

        final result = await clipboardService.getText();
        expect(result, isNull);
      });
    });

    group('setText', () {
      test('invokes clipboard.setText with text', () async {
        var invoked = false;
        mockClient.whenInvoke('clipboard.setText', (params) {
          expect(params['text'], equals('new clipboard text'));
          invoked = true;
          return {};
        });

        await clipboardService.setText('new clipboard text');
        expect(invoked, isTrue);
      });
    });

    group('hasText', () {
      test('returns true when clipboard has text', () async {
        mockClient.whenInvoke('clipboard.hasText', (params) {
          expect(params, isEmpty);
          return {'hasText': true};
        });

        final result = await clipboardService.hasText();
        expect(result, isTrue);
      });

      test('returns false when clipboard is empty', () async {
        mockClient.whenInvoke('clipboard.hasText', (params) {
          return {'hasText': false};
        });

        final result = await clipboardService.hasText();
        expect(result, isFalse);
      });
    });
  });
}
