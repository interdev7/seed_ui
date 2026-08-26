import 'package:flutter_test/flutter_test.dart';
import 'package:seed_ui/seed_ui.dart';

void main() {
  group('DateFields', () {
    test('reads which parts a format names', () {
      final full = DateFields.of('yyyy-MM-dd');
      expect(full.year, isTrue);
      expect(full.month, isTrue);
      expect(full.day, isTrue);
      expect(full.time, isFalse);

      expect(DateFields.of('yyyy-MM').day, isFalse);
      expect(DateFields.of('yyyy-MM-dd HH:mm').time, isTrue);
      expect(DateFields.of('EEE, d MMM').weekday, isTrue);
    });

    test('literal text names nothing', () {
      // '[day]' is a word, not a day.
      final fields = DateFields.of('yyyy[day]');
      expect(fields.day, isFalse);
      expect(fields.year, isTrue);
    });
  });

  group('the date arithmetic a panel needs', () {
    test('daysInMonth knows February', () {
      expect(daysInMonth(2026, 2), 28);
      expect(daysInMonth(2024, 2), 29, reason: 'a leap year');
      expect(daysInMonth(2000, 2), 29, reason: 'divisible by 400');
      expect(daysInMonth(1900, 2), 28, reason: 'divisible by 100, not 400');
      expect(daysInMonth(2026, 12), 31);
    });

    test('a leap February is a full month, and its grid still six weeks', () {
      // The hundred-and-four-hundred rules come from DateTime itself rather
      // than a formula of ours, so they are right for free — but the panel
      // has to carry the extra day.
      expect(daysInMonth(2024, 2), 29);
      expect(daysInMonth(2100, 2), 28, reason: 'a century that is not a leap');
      expect(daysInMonth(2400, 2), 29);

      final grid = monthGrid(2024, 2);
      expect(grid.length, 42);
      expect(grid.where((d) => d.month == 2).length, 29);
      expect(grid.any((d) => d.month == 2 && d.day == 29), isTrue);
    });

    test('addMonths clamps to the leap length, not to 28', () {
      expect(addMonths(DateTime(2024, 1, 31), 1), DateTime(2024, 2, 29));
      // And the other way: a 29th stepped a year on has nowhere to land.
      expect(addMonths(DateTime(2024, 2, 29), 12), DateTime(2025, 2, 28));
    });

    test('addMonths clamps rather than skipping a month', () {
      // The 31st plus one month is the end of February, not the 3rd of March.
      expect(
        addMonths(DateTime(2026, 1, 31), 1),
        DateTime(2026, 2, 28),
      );
      expect(
        addMonths(DateTime(2026, 5, 31), -1),
        DateTime(2026, 4, 30),
      );
    });

    test('addMonths crosses the year in both directions', () {
      expect(addMonths(DateTime(2026, 12, 15), 1), DateTime(2027, 1, 15));
      expect(addMonths(DateTime(2026), -1), DateTime(2025, 12));
      expect(addMonths(DateTime(2026, 6, 10), 18), DateTime(2027, 12, 10));
    });

    test('addMonths keeps the clock', () {
      expect(
        addMonths(DateTime(2026, 1, 15, 14, 30), 1),
        DateTime(2026, 2, 15, 14, 30),
      );
    });

    test('dateOnly drops the clock, so two same days are equal', () {
      final a = DateTime(2026, 3, 4, 14, 32);
      final b = DateTime(2026, 3, 4, 9);
      expect(a == b, isFalse);
      expect(dateOnly(a), dateOnly(b));
      expect(isSameDay(a, b), isTrue);
    });
  });

  group('monthGrid', () {
    test('is always six weeks, so the panel never changes height', () {
      for (final month in [1, 2, 5, 8, 12]) {
        expect(monthGrid(2026, month).length, 42, reason: 'month $month');
      }
      // February 2026 starts on a Sunday and has 28 days — the tightest fit
      // there is, and still six rows.
      expect(monthGrid(2026, 2).length, 42);
    });

    test('starts on the first day of the week asked for', () {
      final monday = monthGrid(2026, 3);
      expect(monday.first.weekday, DateTime.monday);

      final sunday = monthGrid(2026, 3, firstDayOfWeek: DateTime.sunday);
      expect(sunday.first.weekday, DateTime.sunday);

      final saturday = monthGrid(2026, 3, firstDayOfWeek: DateTime.saturday);
      expect(saturday.first.weekday, DateTime.saturday);
    });

    test('holds every day of the month, in order and unbroken', () {
      final grid = monthGrid(2026, 3);
      final inMonth = grid.where((d) => d.month == 3).toList();
      expect(inMonth.length, 31);
      expect(inMonth.first.day, 1);
      expect(inMonth.last.day, 31);

      for (var i = 1; i < grid.length; i++) {
        expect(
          grid[i].difference(grid[i - 1]).inDays,
          1,
          reason: 'a gap before ${grid[i]}',
        );
      }
    });

    test('the days either side belong to the neighbouring months', () {
      // March 2026 starts on a Sunday, so a Monday-first grid leads with the
      // tail of February.
      final grid = monthGrid(2026, 3);
      expect(grid.first.month, 2);
      expect(grid.last.month, 4);
    });

    test('a month starting on the first day of the week leads with itself', () {
      // June 2026 starts on a Monday.
      expect(DateTime(2026, 6).weekday, DateTime.monday);
      final grid = monthGrid(2026, 6);
      expect(grid.first, DateTime(2026, 6));
    });

    test('weekdayOrder heads the columns in the same order', () {
      expect(weekdayOrder(), [1, 2, 3, 4, 5, 6, 7]);
      expect(
        weekdayOrder(firstDayOfWeek: DateTime.sunday),
        [7, 1, 2, 3, 4, 5, 6],
      );
      expect(
        weekdayOrder(firstDayOfWeek: DateTime.saturday),
        [6, 7, 1, 2, 3, 4, 5],
      );
    });
  });

  group('formatDate', () {
    final date = DateTime(2026, 3, 4, 14, 5, 6);

    test('pads to the width the format asks for', () {
      expect(formatDate(date, 'yyyy-MM-dd'), '2026-03-04');
      expect(formatDate(date, 'd/M/yyyy'), '4/3/2026');
      expect(formatDate(date, 'yy'), '26');
    });

    test('writes the names a locale gives it', () {
      expect(formatDate(date, 'd MMM yyyy'), '4 Mar 2026');
      expect(formatDate(date, 'EEE'), 'Wed');
      expect(
        formatDate(date, 'MMM', months: const [
          'янв',
          'фев',
          'мар',
          'апр',
          'май',
          'июн',
          'июл',
          'авг',
          'сен',
          'окт',
          'ноя',
          'дек',
        ]),
        'мар',
      );
    });

    test('a name is not chewed up by the numeric passes', () {
      // 'Mar' carries an 'a', and 'a' is the meridiem token.
      expect(formatDate(date, 'MMM'), 'Mar');
      expect(formatDate(DateTime(2026, 8, 1), 'MMM'), 'Aug');
    });

    test('one format can carry both halves', () {
      expect(formatDate(date, 'yyyy-MM-dd HH:mm'), '2026-03-04 14:05');
      // M is the month, m the minute — case is what tells them apart.
      expect(formatDate(date, 'MM mm'), '03 05');
    });

    test('a bracketed word is left alone', () {
      expect(formatDate(date, 'd[ of ]MMM'), '4 of Mar');
    });
  });

  group('parseDate', () {
    test('reads what it wrote', () {
      for (final format in ['yyyy-MM-dd', 'd/M/yyyy', 'dd.MM.yyyy']) {
        final d = DateTime(2026, 3, 4);
        expect(parseDate(formatDate(d, format), format), d, reason: format);
      }
    });

    test('is lenient about width while typing', () {
      expect(parseDate('2026-1-5', 'yyyy-MM-dd'), DateTime(2026, 1, 5));
    });

    test('follows the order the format writes', () {
      expect(parseDate('04/03/2026', 'dd/MM/yyyy'), DateTime(2026, 3, 4));
      expect(parseDate('03/04/2026', 'MM/dd/yyyy'), DateTime(2026, 3, 4));
    });

    test('refuses a day that month does not have', () {
      // DateTime itself would roll this into March, landing the typo
      // somewhere else entirely.
      expect(parseDate('2026-02-31', 'yyyy-MM-dd'), isNull);
      expect(parseDate('2026-02-29', 'yyyy-MM-dd'), isNull);
      expect(parseDate('2024-02-29', 'yyyy-MM-dd'), DateTime(2024, 2, 29));
    });

    test('refuses what is not a date', () {
      expect(parseDate('2026-13-01', 'yyyy-MM-dd'), isNull);
      expect(parseDate('nope', 'yyyy-MM-dd'), isNull);
      expect(parseDate('', 'yyyy-MM-dd'), isNull);
      expect(parseDate('2026', 'yyyy-MM-dd'), isNull, reason: 'too few');
    });

    test('reads a month by name', () {
      expect(parseDate('4 Mar 2026', 'd MMM yyyy'), DateTime(2026, 3, 4));
      expect(parseDate('4 Nope 2026', 'd MMM yyyy'), isNull);
    });

    test('a two-digit year is this century', () {
      expect(parseDate('26-03-04', 'yy-MM-dd'), DateTime(2026, 3, 4));
    });
  });
}
