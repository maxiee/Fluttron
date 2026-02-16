import 'package:flutter_test/flutter_test.dart';
import 'package:fluttron_milkdown/src/milkdown_controller.dart';
import 'package:fluttron_milkdown/src/milkdown_theme.dart';

void main() {
  group('MilkdownController', () {
    late MilkdownController controller;

    setUp(() {
      controller = MilkdownController();
    });

    group('initial state', () {
      test('is not attached initially', () {
        expect(controller.isAttached, isFalse);
      });

      test('viewId throws StateError when not attached', () {
        expect(() => controller.viewId, throwsA(isA<StateError>()));
      });
    });

    group('attach', () {
      test('sets isAttached to true', () {
        controller.attach(42);
        expect(controller.isAttached, isTrue);
      });

      test('sets viewId to the provided value', () {
        controller.attach(42);
        expect(controller.viewId, equals(42));
      });

      test('can attach to different viewId', () {
        controller.attach(1);
        expect(controller.viewId, equals(1));

        controller.attach(2);
        expect(controller.viewId, equals(2));
      });

      test('can attach to zero viewId', () {
        controller.attach(0);
        expect(controller.isAttached, isTrue);
        expect(controller.viewId, equals(0));
      });
    });

    group('detach', () {
      test('sets isAttached to false', () {
        controller.attach(42);
        expect(controller.isAttached, isTrue);

        controller.detach();
        expect(controller.isAttached, isFalse);
      });

      test('viewId throws StateError after detach', () {
        controller.attach(42);
        controller.detach();

        expect(() => controller.viewId, throwsA(isA<StateError>()));
      });

      test('detach is idempotent', () {
        controller.attach(42);
        controller.detach();
        controller.detach(); // Should not throw

        expect(controller.isAttached, isFalse);
      });

      test('detach on unattached controller is safe', () {
        // Should not throw
        controller.detach();
        expect(controller.isAttached, isFalse);
      });
    });

    group('control methods when not attached', () {
      test('getContent throws StateError', () async {
        expect(() => controller.getContent(), throwsA(isA<StateError>()));
      });

      test('setContent throws StateError', () async {
        expect(
          () => controller.setContent('content'),
          throwsA(isA<StateError>()),
        );
      });

      test('focus throws StateError', () async {
        expect(() => controller.focus(), throwsA(isA<StateError>()));
      });

      test('insertText throws StateError', () async {
        expect(() => controller.insertText('text'), throwsA(isA<StateError>()));
      });

      test('setReadonly throws StateError', () async {
        expect(() => controller.setReadonly(true), throwsA(isA<StateError>()));
      });

      test('setTheme throws StateError', () async {
        expect(
          () => controller.setTheme(MilkdownTheme.nord),
          throwsA(isA<StateError>()),
        );
      });
    });

    group('attach/detach lifecycle', () {
      test('supports multiple attach/detach cycles', () {
        for (int i = 0; i < 3; i++) {
          expect(controller.isAttached, isFalse);
          controller.attach(i);
          expect(controller.isAttached, isTrue);
          expect(controller.viewId, equals(i));
          controller.detach();
        }
        expect(controller.isAttached, isFalse);
      });
    });

    group('error messages', () {
      test('viewId error message is descriptive', () {
        StateError? error;
        try {
          // ignore: unused_local_variable
          final _ = controller.viewId;
        } on StateError catch (e) {
          error = e;
        }

        expect(error, isNotNull);
        expect(error!.message, contains('not attached'));
      });
    });
  });
}
