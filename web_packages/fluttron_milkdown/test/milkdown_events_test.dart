import 'package:flutter_test/flutter_test.dart';
import 'package:fluttron_milkdown/src/milkdown_events.dart';

void main() {
  group('MilkdownChangeEvent', () {
    group('constructor', () {
      test('creates event with all fields', () {
        const event = MilkdownChangeEvent(
          viewId: 42,
          markdown: '# Hello World',
          characterCount: 13,
          lineCount: 1,
          updatedAt: '2026-02-16T10:00:00.000Z',
        );

        expect(event.viewId, equals(42));
        expect(event.markdown, equals('# Hello World'));
        expect(event.characterCount, equals(13));
        expect(event.lineCount, equals(1));
        expect(event.updatedAt, equals('2026-02-16T10:00:00.000Z'));
      });

      test('creates event with empty markdown', () {
        const event = MilkdownChangeEvent(
          viewId: 1,
          markdown: '',
          characterCount: 0,
          lineCount: 0,
          updatedAt: '',
        );

        expect(event.markdown, isEmpty);
        expect(event.characterCount, isZero);
        expect(event.lineCount, isZero);
      });

      test('creates event with multiline markdown', () {
        const markdown = '''# Title
## Subtitle
- Item 1
- Item 2''';
        const event = MilkdownChangeEvent(
          viewId: 1,
          markdown: markdown,
          characterCount: 35,
          lineCount: 4,
          updatedAt: '2026-02-16T10:00:00.000Z',
        );

        expect(event.markdown, equals(markdown));
        expect(event.lineCount, equals(4));
      });
    });

    group('fromMap factory', () {
      test('creates event from complete map', () {
        final event = MilkdownChangeEvent.fromMap({
          'viewId': 42,
          'markdown': '# Test',
          'characterCount': 7,
          'lineCount': 1,
          'updatedAt': '2026-02-16T10:00:00.000Z',
          'instanceToken': 'token-42',
        });

        expect(event.viewId, equals(42));
        expect(event.markdown, equals('# Test'));
        expect(event.characterCount, equals(7));
        expect(event.lineCount, equals(1));
        expect(event.updatedAt, equals('2026-02-16T10:00:00.000Z'));
        expect(event.instanceToken, equals('token-42'));
      });

      test('handles num types for integers', () {
        final event = MilkdownChangeEvent.fromMap({
          'viewId': 42.0, // double instead of int
          'markdown': 'test',
          'characterCount': 4.0,
          'lineCount': 1.0,
          'updatedAt': '2026-02-16T10:00:00.000Z',
        });

        expect(event.viewId, equals(42));
        expect(event.characterCount, equals(4));
        expect(event.lineCount, equals(1));
      });

      test('handles missing viewId', () {
        final event = MilkdownChangeEvent.fromMap({
          'markdown': 'test',
          'characterCount': 4,
          'lineCount': 1,
          'updatedAt': '2026-02-16T10:00:00.000Z',
        });

        expect(event.viewId, equals(0));
      });

      test('handles missing markdown', () {
        final event = MilkdownChangeEvent.fromMap({
          'viewId': 1,
          'characterCount': 0,
          'lineCount': 0,
          'updatedAt': '2026-02-16T10:00:00.000Z',
        });

        expect(event.markdown, isEmpty);
      });

      test('handles null values', () {
        final event = MilkdownChangeEvent.fromMap({
          'viewId': null,
          'markdown': null,
          'characterCount': null,
          'lineCount': null,
          'updatedAt': null,
        });

        expect(event.viewId, equals(0));
        expect(event.markdown, isEmpty);
        expect(event.characterCount, isZero);
        expect(event.lineCount, isZero);
        expect(event.updatedAt, isEmpty);
      });

      test('handles empty map', () {
        final event = MilkdownChangeEvent.fromMap({});

        expect(event.viewId, equals(0));
        expect(event.markdown, isEmpty);
        expect(event.characterCount, isZero);
        expect(event.lineCount, isZero);
        expect(event.updatedAt, isEmpty);
      });

      test('handles string type coercion', () {
        final event = MilkdownChangeEvent.fromMap({
          'viewId': 1,
          'markdown': 123, // Not a string
          'characterCount': 3,
          'lineCount': 1,
          'updatedAt': '2026-02-16T10:00:00.000Z',
        });

        // toString() is called for non-string markdown
        expect(event.markdown, equals('123'));
      });
    });

    group('toString', () {
      test('includes viewId, characterCount, and lineCount', () {
        const event = MilkdownChangeEvent(
          viewId: 42,
          markdown: '# Hello World',
          characterCount: 13,
          lineCount: 1,
          updatedAt: '2026-02-16T10:00:00.000Z',
        );

        final str = event.toString();

        expect(str, contains('viewId: 42'));
        expect(str, contains('characterCount: 13'));
        expect(str, contains('lineCount: 1'));
      });

      test('does not include full markdown content', () {
        const event = MilkdownChangeEvent(
          viewId: 1,
          markdown: 'Very long markdown content...',
          characterCount: 30,
          lineCount: 1,
          updatedAt: '2026-02-16T10:00:00.000Z',
        );

        final str = event.toString();

        expect(str, isNot(contains('Very long markdown')));
      });
    });

    group('equality', () {
      test('equal events have same hashCode', () {
        const event1 = MilkdownChangeEvent(
          viewId: 42,
          markdown: '# Test',
          characterCount: 7,
          lineCount: 1,
          updatedAt: '2026-02-16T10:00:00.000Z',
        );
        const event2 = MilkdownChangeEvent(
          viewId: 42,
          markdown: '# Test',
          characterCount: 7,
          lineCount: 1,
          updatedAt: '2026-02-16T10:00:00.000Z',
        );

        expect(event1, equals(event2));
        expect(event1.hashCode, equals(event2.hashCode));
      });

      test('different viewId makes events unequal', () {
        const event1 = MilkdownChangeEvent(
          viewId: 1,
          markdown: 'test',
          characterCount: 4,
          lineCount: 1,
          updatedAt: '2026-02-16T10:00:00.000Z',
        );
        const event2 = MilkdownChangeEvent(
          viewId: 2,
          markdown: 'test',
          characterCount: 4,
          lineCount: 1,
          updatedAt: '2026-02-16T10:00:00.000Z',
        );

        expect(event1, isNot(equals(event2)));
      });

      test('different markdown makes events unequal', () {
        const event1 = MilkdownChangeEvent(
          viewId: 1,
          markdown: 'test1',
          characterCount: 5,
          lineCount: 1,
          updatedAt: '2026-02-16T10:00:00.000Z',
        );
        const event2 = MilkdownChangeEvent(
          viewId: 1,
          markdown: 'test2',
          characterCount: 5,
          lineCount: 1,
          updatedAt: '2026-02-16T10:00:00.000Z',
        );

        expect(event1, isNot(equals(event2)));
      });

      test('different updatedAt makes events unequal', () {
        const event1 = MilkdownChangeEvent(
          viewId: 1,
          markdown: 'test',
          characterCount: 4,
          lineCount: 1,
          updatedAt: '2026-02-16T10:00:00.000Z',
        );
        const event2 = MilkdownChangeEvent(
          viewId: 1,
          markdown: 'test',
          characterCount: 4,
          lineCount: 1,
          updatedAt: '2026-02-16T10:01:00.000Z',
        );

        expect(event1, isNot(equals(event2)));
      });

      test('different instanceToken makes events unequal', () {
        const event1 = MilkdownChangeEvent(
          viewId: 1,
          markdown: 'test',
          characterCount: 4,
          lineCount: 1,
          updatedAt: '2026-02-16T10:00:00.000Z',
          instanceToken: 'token-a',
        );
        const event2 = MilkdownChangeEvent(
          viewId: 1,
          markdown: 'test',
          characterCount: 4,
          lineCount: 1,
          updatedAt: '2026-02-16T10:00:00.000Z',
          instanceToken: 'token-b',
        );

        expect(event1, isNot(equals(event2)));
      });

      test('identical reference is equal', () {
        const event = MilkdownChangeEvent(
          viewId: 1,
          markdown: 'test',
          characterCount: 4,
          lineCount: 1,
          updatedAt: '2026-02-16T10:00:00.000Z',
        );

        expect(event, equals(event));
      });

      test('not equal to different type', () {
        const event = MilkdownChangeEvent(
          viewId: 1,
          markdown: 'test',
          characterCount: 4,
          lineCount: 1,
          updatedAt: '2026-02-16T10:00:00.000Z',
        );

        expect(event, isNot(equals('not an event')));
        expect(event, isNot(equals(42)));
        expect(event, isNot(equals(null)));
      });
    });
  });
}
