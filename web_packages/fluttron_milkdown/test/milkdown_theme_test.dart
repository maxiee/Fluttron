import 'package:flutter_test/flutter_test.dart';
import 'package:fluttron_milkdown/src/milkdown_theme.dart';

void main() {
  group('MilkdownTheme', () {
    group('enum values', () {
      test('has exactly 4 theme values', () {
        expect(MilkdownTheme.values, hasLength(4));
      });

      test('frame has correct value', () {
        expect(MilkdownTheme.frame.value, equals('frame'));
      });

      test('frameDark has correct value', () {
        expect(MilkdownTheme.frameDark.value, equals('frame-dark'));
      });

      test('nord has correct value', () {
        expect(MilkdownTheme.nord.value, equals('nord'));
      });

      test('nordDark has correct value', () {
        expect(MilkdownTheme.nordDark.value, equals('nord-dark'));
      });
    });

    group('isDark property', () {
      test('frame is not dark', () {
        expect(MilkdownTheme.frame.isDark, isFalse);
      });

      test('frameDark is dark', () {
        expect(MilkdownTheme.frameDark.isDark, isTrue);
      });

      test('nord is not dark', () {
        expect(MilkdownTheme.nord.isDark, isFalse);
      });

      test('nordDark is dark', () {
        expect(MilkdownTheme.nordDark.isDark, isTrue);
      });
    });

    group('lightVariant', () {
      test('frame returns itself', () {
        expect(MilkdownTheme.frame.lightVariant, equals(MilkdownTheme.frame));
      });

      test('frameDark returns frame', () {
        expect(
          MilkdownTheme.frameDark.lightVariant,
          equals(MilkdownTheme.frame),
        );
      });

      test('nord returns itself', () {
        expect(MilkdownTheme.nord.lightVariant, equals(MilkdownTheme.nord));
      });

      test('nordDark returns nord', () {
        expect(MilkdownTheme.nordDark.lightVariant, equals(MilkdownTheme.nord));
      });
    });

    group('darkVariant', () {
      test('frame returns frameDark', () {
        expect(
          MilkdownTheme.frame.darkVariant,
          equals(MilkdownTheme.frameDark),
        );
      });

      test('frameDark returns itself', () {
        expect(
          MilkdownTheme.frameDark.darkVariant,
          equals(MilkdownTheme.frameDark),
        );
      });

      test('nord returns nordDark', () {
        expect(MilkdownTheme.nord.darkVariant, equals(MilkdownTheme.nordDark));
      });

      test('nordDark returns itself', () {
        expect(
          MilkdownTheme.nordDark.darkVariant,
          equals(MilkdownTheme.nordDark),
        );
      });
    });

    group('tryParse', () {
      test('parses "frame" correctly', () {
        expect(MilkdownTheme.tryParse('frame'), equals(MilkdownTheme.frame));
      });

      test('parses "frame-dark" correctly', () {
        expect(
          MilkdownTheme.tryParse('frame-dark'),
          equals(MilkdownTheme.frameDark),
        );
      });

      test('parses "nord" correctly', () {
        expect(MilkdownTheme.tryParse('nord'), equals(MilkdownTheme.nord));
      });

      test('parses "nord-dark" correctly', () {
        expect(
          MilkdownTheme.tryParse('nord-dark'),
          equals(MilkdownTheme.nordDark),
        );
      });

      test('returns null for unknown theme', () {
        expect(MilkdownTheme.tryParse('unknown'), isNull);
      });

      test('returns null for empty string', () {
        expect(MilkdownTheme.tryParse(''), isNull);
      });

      test('returns null for classic theme (not supported)', () {
        // classic/classic-dark themes are not available due to package issues
        expect(MilkdownTheme.tryParse('classic'), isNull);
        expect(MilkdownTheme.tryParse('classic-dark'), isNull);
      });

      test('is case sensitive', () {
        expect(MilkdownTheme.tryParse('FRAME'), isNull);
        expect(MilkdownTheme.tryParse('Nord'), isNull);
      });
    });

    group('light/dark round-trip', () {
      test('frame -> darkVariant -> lightVariant returns frame', () {
        final result = MilkdownTheme.frame.darkVariant.lightVariant;
        expect(result, equals(MilkdownTheme.frame));
      });

      test('nord -> darkVariant -> lightVariant returns nord', () {
        final result = MilkdownTheme.nord.darkVariant.lightVariant;
        expect(result, equals(MilkdownTheme.nord));
      });
    });
  });
}
