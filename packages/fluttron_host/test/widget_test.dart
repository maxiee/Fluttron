import 'package:fluttron_host/fluttron_host.dart';
import 'package:fluttron_shared/fluttron_shared.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('createDefaultServiceRegistry', () {
    test('includes file/dialog/clipboard namespaces', () async {
      final ServiceRegistry registry = createDefaultServiceRegistry();

      await expectLater(
        () => registry.dispatch('file.unknownMethod', <String, dynamic>{}),
        throwsA(
          isA<FluttronError>().having(
            (FluttronError e) => e.code,
            'code',
            'METHOD_NOT_FOUND',
          ),
        ),
      );

      await expectLater(
        () => registry.dispatch('dialog.unknownMethod', <String, dynamic>{}),
        throwsA(
          isA<FluttronError>().having(
            (FluttronError e) => e.code,
            'code',
            'METHOD_NOT_FOUND',
          ),
        ),
      );

      await expectLater(
        () => registry.dispatch('clipboard.unknownMethod', <String, dynamic>{}),
        throwsA(
          isA<FluttronError>().having(
            (FluttronError e) => e.code,
            'code',
            'METHOD_NOT_FOUND',
          ),
        ),
      );
    });
  });
}
