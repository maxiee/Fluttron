import 'package:fluttron_shared/fluttron_shared.dart';
import 'package:test/test.dart';

void main() {
  group('FileStat', () {
    test('constructs with required fields', () {
      const stat = FileStat(
        exists: true,
        isFile: true,
        isDirectory: false,
        size: 1024,
        modified: '2026-02-17T10:00:00Z',
      );

      expect(stat.exists, isTrue);
      expect(stat.isFile, isTrue);
      expect(stat.isDirectory, isFalse);
      expect(stat.size, equals(1024));
      expect(stat.modified, equals('2026-02-17T10:00:00Z'));
    });

    test('creates from map', () {
      final stat = FileStat.fromMap({
        'exists': true,
        'isFile': false,
        'isDirectory': true,
        'size': 0,
        'modified': '2026-02-17T12:30:00Z',
      });

      expect(stat.exists, isTrue);
      expect(stat.isFile, isFalse);
      expect(stat.isDirectory, isTrue);
      expect(stat.size, equals(0));
      expect(stat.modified, equals('2026-02-17T12:30:00Z'));
    });

    test('converts to map', () {
      const stat = FileStat(
        exists: true,
        isFile: true,
        isDirectory: false,
        size: 2048,
        modified: '2026-02-17T15:00:00Z',
      );

      final map = stat.toMap();

      expect(map['exists'], isTrue);
      expect(map['isFile'], isTrue);
      expect(map['isDirectory'], isFalse);
      expect(map['size'], equals(2048));
      expect(map['modified'], equals('2026-02-17T15:00:00Z'));
    });

    test('round-trips through map', () {
      const original = FileStat(
        exists: false,
        isFile: false,
        isDirectory: false,
        size: 0,
        modified: '',
      );

      final roundTripped = FileStat.fromMap(original.toMap());

      expect(roundTripped.exists, equals(original.exists));
      expect(roundTripped.isFile, equals(original.isFile));
      expect(roundTripped.isDirectory, equals(original.isDirectory));
      expect(roundTripped.size, equals(original.size));
      expect(roundTripped.modified, equals(original.modified));
    });

    test('implements equality', () {
      const stat1 = FileStat(
        exists: true,
        isFile: true,
        isDirectory: false,
        size: 1024,
        modified: '2026-02-17T10:00:00Z',
      );

      const stat2 = FileStat(
        exists: true,
        isFile: true,
        isDirectory: false,
        size: 1024,
        modified: '2026-02-17T10:00:00Z',
      );

      const stat3 = FileStat(
        exists: false,
        isFile: false,
        isDirectory: false,
        size: 0,
        modified: '',
      );

      expect(stat1, equals(stat2));
      expect(stat1, isNot(equals(stat3)));
      expect(stat1.hashCode, equals(stat2.hashCode));
    });

    test('toString contains key fields', () {
      const stat = FileStat(
        exists: true,
        isFile: true,
        isDirectory: false,
        size: 4096,
        modified: '2026-02-17T20:00:00Z',
      );

      final str = stat.toString();

      expect(str, contains('FileStat'));
      expect(str, contains('exists: true'));
      expect(str, contains('isFile: true'));
      expect(str, contains('isDirectory: false'));
      expect(str, contains('size: 4096'));
      expect(str, contains('2026-02-17T20:00:00Z'));
    });
  });
}
