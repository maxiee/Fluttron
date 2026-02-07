import 'package:fluttron_ui/src/web_view_registry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FluttronWebViewRegistry', () {
    setUp(() {
      FluttronWebViewRegistry.resetForTesting();
    });

    tearDown(() {
      FluttronWebViewRegistry.resetForTesting();
    });

    test('registers and looks up a web view type', () {
      const FluttronWebViewRegistration registration =
          FluttronWebViewRegistration(
            type: 'fluttron.test.editor',
            jsFactoryName: 'fluttronCreateTestEditorView',
          );

      FluttronWebViewRegistry.register(registration);

      expect(
        FluttronWebViewRegistry.isRegistered('fluttron.test.editor'),
        isTrue,
      );
      final FluttronWebViewRegistration lookedUp =
          FluttronWebViewRegistry.lookup('fluttron.test.editor');
      expect(lookedUp.type, registration.type);
      expect(lookedUp.jsFactoryName, registration.jsFactoryName);
    });

    test('register is idempotent for identical registration', () {
      const FluttronWebViewRegistration registration =
          FluttronWebViewRegistration(
            type: 'fluttron.test.idempotent',
            jsFactoryName: 'fluttronCreateIdempotentView',
          );

      FluttronWebViewRegistry.register(registration);
      FluttronWebViewRegistry.register(registration);

      final FluttronWebViewRegistration lookedUp =
          FluttronWebViewRegistry.lookup(registration.type);
      expect(lookedUp.jsFactoryName, registration.jsFactoryName);
    });

    test('throws on conflicting registration for same type', () {
      const String type = 'fluttron.test.conflict';
      FluttronWebViewRegistry.register(
        const FluttronWebViewRegistration(
          type: type,
          jsFactoryName: 'fluttronCreateConflictA',
        ),
      );

      expect(
        () => FluttronWebViewRegistry.register(
          const FluttronWebViewRegistration(
            type: type,
            jsFactoryName: 'fluttronCreateConflictB',
          ),
        ),
        throwsStateError,
      );
    });

    test('lookup throws when type is missing', () {
      expect(
        () => FluttronWebViewRegistry.lookup('fluttron.test.missing'),
        throwsStateError,
      );
    });

    test('registerAll registers every entry', () {
      const List<FluttronWebViewRegistration> registrations =
          <FluttronWebViewRegistration>[
            FluttronWebViewRegistration(
              type: 'fluttron.test.bulk.one',
              jsFactoryName: 'factoryOne',
            ),
            FluttronWebViewRegistration(
              type: 'fluttron.test.bulk.two',
              jsFactoryName: 'factoryTwo',
            ),
          ];

      FluttronWebViewRegistry.registerAll(registrations);

      expect(
        FluttronWebViewRegistry.isRegistered('fluttron.test.bulk.one'),
        isTrue,
      );
      expect(
        FluttronWebViewRegistry.isRegistered('fluttron.test.bulk.two'),
        isTrue,
      );
    });
  });
}
