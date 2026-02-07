import 'package:fluttron_ui/src/event_bridge.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FluttronEventBridge', () {
    test('throws ArgumentError when eventName is empty', () {
      final FluttronEventBridge bridge = FluttronEventBridge();

      expect(() => bridge.on('   '), throwsArgumentError);

      bridge.dispose();
    });

    test('throws StateError when calling on after dispose', () {
      final FluttronEventBridge bridge = FluttronEventBridge();
      bridge.dispose();

      expect(
        () => bridge.on('fluttron.playground.milkdown.change'),
        throwsStateError,
      );
    });

    test('throws UnsupportedError on non-web platforms', () {
      final FluttronEventBridge bridge = FluttronEventBridge();

      expect(
        () => bridge.on('fluttron.playground.milkdown.change'),
        throwsUnsupportedError,
      );

      bridge.dispose();
    });
  });
}
