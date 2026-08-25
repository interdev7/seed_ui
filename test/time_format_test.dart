import 'package:flutter_test/flutter_test.dart';
import 'package:seed_ui/seed_ui.dart';

void main() {
  group('TimeFields', () {
    test('reads which columns a format asks for', () {
      final full = TimeFields.of('HH:mm:ss');
      expect(full.hour, isTrue);
      expect(full.minute, isTrue);
      expect(full.second, isTrue);
      expect(full.meridiem, isFalse);

      final short = TimeFields.of('HH:mm');
      expect(short.second, isFalse);

      final twelve = TimeFields.of('h:mm a');
      expect(twelve.meridiem, isTrue);
    });

    test('literal text does not count as a field', () {
      // '[min]' names no minute; the brackets make it a word.
      final fields = TimeFields.of('HH[min]');
      expect(fields.minute, isFalse);
      expect(fields.second, isFalse);
      expect(fields.hour, isTrue);
    });

    test('resolution is the finest unit kept', () {
      expect(TimeFields.of('HH:mm:ss').resolution, const Duration(seconds: 1));
      expect(TimeFields.of('HH:mm').resolution, const Duration(minutes: 1));
      expect(TimeFields.of('HH').resolution, const Duration(hours: 1));
    });
  });

  group('normalizeTime', () {
    test('drops what the format cannot show', () {
      final byMinute = TimeFields.of('HH:mm');
      expect(
        normalizeTime(
            const Duration(hours: 9, minutes: 5, seconds: 40), byMinute),
        const Duration(hours: 9, minutes: 5),
      );
    });

    test('wraps past midnight rather than running on', () {
      final f = TimeFields.of('HH:mm');
      expect(
        normalizeTime(const Duration(hours: 25, minutes: 30), f),
        const Duration(hours: 1, minutes: 30),
      );
      expect(
        normalizeTime(const Duration(hours: -1), f),
        const Duration(hours: 23),
      );
    });
  });

  group('formatTime', () {
    test('pads to the width the format asks for', () {
      const t = Duration(hours: 9, minutes: 5, seconds: 3);
      expect(formatTime(t, 'HH:mm:ss'), '09:05:03');
      expect(formatTime(t, 'H:m:s'), '9:5:3');
    });

    test('midnight and noon read as 12, never 0', () {
      expect(formatTime(Duration.zero, 'h:mm a'), '12:00 am');
      expect(formatTime(const Duration(hours: 12), 'h:mm a'), '12:00 pm');
      expect(formatTime(const Duration(hours: 13), 'h:mm A'), '1:00 PM');
    });

    test('a bracketed word is not read as a token', () {
      // Without the brackets the 'a' would become a meridiem and the 'm's
      // minutes.
      expect(
        formatTime(const Duration(hours: 7), 'HH[am start]'),
        '07am start',
      );
    });

    test('the meridiem words come from the caller', () {
      expect(
        formatTime(const Duration(hours: 13), 'h a', am: 'ص', pm: 'م'),
        '1 م',
      );
    });

    test('a value past a day wraps before it is written', () {
      expect(formatTime(const Duration(hours: 26), 'HH:mm'), '02:00');
    });
  });

  group('parseTime', () {
    test('reads what it wrote', () {
      for (final format in ['HH:mm:ss', 'HH:mm', 'H:m']) {
        final t = normalizeTime(
          const Duration(hours: 14, minutes: 7, seconds: 9),
          TimeFields.of(format),
        );
        expect(parseTime(formatTime(t, format), format), t,
            reason: 'round trip failed for $format');
      }
    });

    test('is lenient about width while typing', () {
      expect(parseTime('9:5', 'HH:mm'), const Duration(hours: 9, minutes: 5));
    });

    test('refuses what is not a time, rather than guessing', () {
      expect(parseTime('25:00', 'HH:mm'), isNull);
      expect(parseTime('12:60', 'HH:mm'), isNull);
      expect(parseTime('', 'HH:mm'), isNull);
      expect(parseTime('nope', 'HH:mm'), isNull);
      // Too few fields for the format.
      expect(parseTime('12', 'HH:mm'), isNull);
      // Too many.
      expect(parseTime('12:30:45', 'HH:mm'), isNull);
    });

    test('a 12-hour format needs to be told which half of the day', () {
      expect(parseTime('9:00', 'h:mm a'), isNull, reason: 'ambiguous');
      expect(parseTime('9:00 am', 'h:mm a'), const Duration(hours: 9));
      expect(parseTime('9:00 pm', 'h:mm a'), const Duration(hours: 21));
      expect(parseTime('12:00 am', 'h:mm a'), Duration.zero);
      expect(parseTime('12:00 pm', 'h:mm a'), const Duration(hours: 12));
      // 13 is not an hour on a 12-hour clock.
      expect(parseTime('13:00 pm', 'h:mm a'), isNull);
    });

    test('midnight round-trips on a 12-hour clock', () {
      const format = 'h:mm a';
      expect(
          parseTime(formatTime(Duration.zero, format), format), Duration.zero);
    });
  });
}
