import 'dart:async';

import 'package:fluttron_milkdown/src/milkdown_events.dart';
import 'package:fluttron_ui/fluttron_ui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('milkdown event stream helpers', () {
    test('milkdownEditorReady filters by instanceToken', () async {
      final bridge = _FakeFluttronEventBridge({
        'fluttron.milkdown.editor.ready':
            Stream<Map<String, dynamic>>.fromIterable([
              <String, dynamic>{'viewId': 1, 'instanceToken': 'token-a'},
              <String, dynamic>{'viewId': 2, 'instanceToken': 'token-b'},
              <String, dynamic>{'viewId': 3},
            ]),
      });

      final List<int> values = await milkdownEditorReady(
        instanceToken: 'token-b',
        eventBridge: bridge,
      ).toList();

      expect(values, <int>[2]);
    });

    test('milkdownEditorFocus filters by viewId', () async {
      final bridge = _FakeFluttronEventBridge({
        'fluttron.milkdown.editor.focus':
            Stream<Map<String, dynamic>>.fromIterable([
              <String, dynamic>{'viewId': 10},
              <String, dynamic>{'viewId': 11},
              <String, dynamic>{'viewId': 10},
            ]),
      });

      final List<int> values = await milkdownEditorFocus(
        viewId: 10,
        eventBridge: bridge,
      ).toList();

      expect(values, <int>[10, 10]);
    });

    test(
      'milkdownEditorChanges applies combined viewId and token filter',
      () async {
        final bridge = _FakeFluttronEventBridge({
          'fluttron.milkdown.editor.change':
              Stream<Map<String, dynamic>>.fromIterable([
                <String, dynamic>{
                  'viewId': 5,
                  'instanceToken': 'token-a',
                  'markdown': 'A',
                  'characterCount': 1,
                  'lineCount': 1,
                  'updatedAt': 't1',
                },
                <String, dynamic>{
                  'viewId': 5,
                  'instanceToken': 'token-b',
                  'markdown': 'B',
                  'characterCount': 1,
                  'lineCount': 1,
                  'updatedAt': 't2',
                },
                <String, dynamic>{
                  'viewId': 6,
                  'instanceToken': 'token-a',
                  'markdown': 'C',
                  'characterCount': 1,
                  'lineCount': 1,
                  'updatedAt': 't3',
                },
              ]),
        });

        final List<MilkdownChangeEvent> values = await milkdownEditorChanges(
          viewId: 5,
          instanceToken: 'token-b',
          eventBridge: bridge,
        ).toList();

        expect(values, hasLength(1));
        expect(values.single.markdown, 'B');
        expect(values.single.instanceToken, 'token-b');
      },
    );
  });
}

class _FakeFluttronEventBridge extends FluttronEventBridge {
  _FakeFluttronEventBridge(this._eventStreams);

  final Map<String, Stream<Map<String, dynamic>>> _eventStreams;

  @override
  Stream<Map<String, dynamic>> on(String eventName) {
    return _eventStreams[eventName] ??
        const Stream<Map<String, dynamic>>.empty();
  }

  @override
  void dispose() {}
}
