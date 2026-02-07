import 'package:fluttron_ui/src/html_view_runtime.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('resolveFluttronHtmlViewDescriptor', () {
    test('returns original type when args is empty', () {
      final FluttronResolvedHtmlViewDescriptor descriptor =
          resolveFluttronHtmlViewDescriptor(
            type: 'fluttron.test.empty',
            args: const <dynamic>[],
          );

      expect(descriptor.resolvedViewType, 'fluttron.test.empty');
      expect(descriptor.argsSignature, '[]');
    });

    test('canonicalizes map keys to produce stable args signature', () {
      final FluttronResolvedHtmlViewDescriptor left =
          resolveFluttronHtmlViewDescriptor(
            type: 'fluttron.test.stable',
            args: <dynamic>[
              <String, dynamic>{'b': 2, 'a': 1},
            ],
          );
      final FluttronResolvedHtmlViewDescriptor right =
          resolveFluttronHtmlViewDescriptor(
            type: 'fluttron.test.stable',
            args: <dynamic>[
              <String, dynamic>{'a': 1, 'b': 2},
            ],
          );

      expect(left.argsSignature, right.argsSignature);
      expect(left.resolvedViewType, right.resolvedViewType);
    });

    test(
      'resolved view type for non-empty args uses deterministic hash suffix',
      () {
        final FluttronResolvedHtmlViewDescriptor first =
            resolveFluttronHtmlViewDescriptor(
              type: 'fluttron.test.hash',
              args: <dynamic>['hello', 7, true],
            );
        final FluttronResolvedHtmlViewDescriptor second =
            resolveFluttronHtmlViewDescriptor(
              type: 'fluttron.test.hash',
              args: <dynamic>['hello', 7, true],
            );

        expect(
          first.resolvedViewType,
          matches(r'^fluttron\.test\.hash\.__[0-9a-f]{16}$'),
        );
        expect(second.resolvedViewType, first.resolvedViewType);
      },
    );

    test('throws for unsupported arg types', () {
      expect(
        () => resolveFluttronHtmlViewDescriptor(
          type: 'fluttron.test.invalid',
          args: <dynamic>[DateTime.now()],
        ),
        throwsStateError,
      );
    });
  });

  group('FluttronResolvedHtmlViewFactoryRegistry', () {
    test('detects compatibility and conflicts', () {
      final FluttronResolvedHtmlViewFactoryRegistry registry =
          FluttronResolvedHtmlViewFactoryRegistry();
      const String resolvedViewType = 'fluttron.test.editor.__abc123';

      final bool beforeRecord = registry.hasCompatibleRegistrationOrThrow(
        resolvedViewType: resolvedViewType,
        type: 'fluttron.test.editor',
        jsFactoryName: 'fluttronCreateEditorView',
        argsSignature: '["hello"]',
        argsDebug: '["hello"]',
      );
      expect(beforeRecord, isFalse);

      registry.record(
        resolvedViewType: resolvedViewType,
        type: 'fluttron.test.editor',
        jsFactoryName: 'fluttronCreateEditorView',
        argsSignature: '["hello"]',
        argsDebug: '["hello"]',
      );

      final bool afterRecord = registry.hasCompatibleRegistrationOrThrow(
        resolvedViewType: resolvedViewType,
        type: 'fluttron.test.editor',
        jsFactoryName: 'fluttronCreateEditorView',
        argsSignature: '["hello"]',
        argsDebug: '["hello"]',
      );
      expect(afterRecord, isTrue);

      expect(
        () => registry.hasCompatibleRegistrationOrThrow(
          resolvedViewType: resolvedViewType,
          type: 'fluttron.test.editor',
          jsFactoryName: 'fluttronCreateEditorView',
          argsSignature: '["changed"]',
          argsDebug: '["changed"]',
        ),
        throwsStateError,
      );
    });
  });
}
