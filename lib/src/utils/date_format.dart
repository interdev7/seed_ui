import 'package:flutter/foundation.dart';

/// Which fields a date format asks for, and so what a picker collects.
///
/// The grammar extends the one `TimeFields` reads, so a single string can name
/// both halves — `'yyyy-MM-dd HH:mm'` — and the two sets do not collide:
///
/// | Token | Means | Example |
/// | --- | --- | --- |
/// | `yyyy` / `yy` | year | `2026`, `26` |
/// | `MMM` | month, short name | `Jan` |
/// | `MM` / `M` | month, number | `01`, `1` |
/// | `dd` / `d` | day of month | `05`, `5` |
/// | `EEE` | weekday, short name | `Mon` |
/// | `HH` `h` `mm` `ss` `a` | the time, as `TimeFields` reads them | |
/// | `[...]` | literal text | `[on]` |
///
/// `M` is the month and `m` the minute, as every other date library has it —
/// case is what tells them apart, so `'MM'` and `'mm'` mean different things
/// on purpose.
@immutable
class DateFields {
  /// Works out which fields [format] names.
  factory DateFields.of(String format) {
    final bare = format.replaceAll(_escaped, '');
    return DateFields._(
      year: bare.contains('y'),
      month: bare.contains('M'),
      day: bare.contains('d'),
      weekday: bare.contains('E'),
      time: bare.contains('H') ||
          bare.contains('h') ||
          bare.contains('m') ||
          bare.contains('s'),
    );
  }

  const DateFields._({
    required this.year,
    required this.month,
    required this.day,
    required this.weekday,
    required this.time,
  });

  /// Whether a year is named.
  final bool year;

  /// Whether a month is named.
  final bool month;

  /// Whether a day of the month is named.
  final bool day;

  /// Whether a weekday name is named.
  final bool weekday;

  /// Whether any part of the clock is named.
  final bool time;

  @override
  bool operator ==(Object other) =>
      other is DateFields &&
      other.year == year &&
      other.month == month &&
      other.day == day &&
      other.weekday == weekday &&
      other.time == time;

  @override
  int get hashCode => Object.hash(year, month, day, weekday, time);
}

final RegExp _escaped = RegExp(r'\[[^\]]*\]');

/// Stands in for lifted-out literal text while the fields are substituted.
final String _hole = String.fromCharCode(0);

/// Stands in for a month name while the numeric fields are substituted.
///
/// Distinct from [_hole] and from each other: one marker for both would make
/// them impossible to tell apart afterwards. Control characters, because no
/// format can contain one to be confused with.
final String _monthMark = String.fromCharCode(1);

/// Stands in for a weekday name. See [_monthMark].
final String _weekdayMark = String.fromCharCode(2);

/// The day [date] falls on, with the clock set to midnight.
///
/// Comparing dates by `==` is only meaningful once the time is gone, and a
/// picker that keeps a stray 14:32 on a value would hand back two "same" days
/// that are not equal.
DateTime dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

/// Whether [a] and [b] fall on the same day.
bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// Whether [a] and [b] fall in the same month.
bool isSameMonth(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month;

/// How many days [month] of [year] has. February included.
int daysInMonth(int year, int month) => DateTime(year, month + 1, 0).day;

/// [date] moved by [months], clamped to the end of the month it lands in.
///
/// The 31st plus one month is the 28th of February, not the 3rd of March: a
/// picker stepping through months must not skip one.
DateTime addMonths(DateTime date, int months) {
  final total = date.year * 12 + (date.month - 1) + months;
  final year = total ~/ 12;
  final month = total % 12 + 1;
  final day = date.day <= daysInMonth(year, month)
      ? date.day
      : daysInMonth(year, month);
  return DateTime(year, month, day, date.hour, date.minute, date.second);
}

/// The six weeks a month panel shows, as 42 days from Monday-or-whichever.
///
/// Always six rows, so the panel does not change height from month to month —
/// a grid that grew a row in March would shift everything under it. The days
/// either side belong to the neighbouring months and are drawn faintly.
///
/// [firstDayOfWeek] is 1 for Monday through 7 for Sunday, matching
/// [DateTime.weekday].
List<DateTime> monthGrid(int year, int month, {int firstDayOfWeek = 1}) {
  assert(
    firstDayOfWeek >= 1 && firstDayOfWeek <= 7,
    'firstDayOfWeek is 1 (Monday) through 7 (Sunday)',
  );
  final first = DateTime(year, month);
  // How far back to the start of the week the 1st sits in.
  final lead = (first.weekday - firstDayOfWeek + 7) % 7;
  final start = first.subtract(Duration(days: lead));
  return [
    for (var i = 0; i < 42; i++)
      DateTime(start.year, start.month, start.day + i),
  ];
}

/// The seven weekday numbers a panel heads its columns with, in order.
List<int> weekdayOrder({int firstDayOfWeek = 1}) =>
    [for (var i = 0; i < 7; i++) (firstDayOfWeek - 1 + i) % 7 + 1];

/// Writes [date] out according to [format].
///
/// [months] and [weekdays] carry the short names, so a locale can say them its
/// own way. Both are indexed from January and from Monday.
String formatDate(
  DateTime date,
  String format, {
  List<String> months = _englishMonths,
  List<String> weekdays = _englishWeekdays,
  String am = 'AM',
  String pm = 'PM',
}) {
  final kept = _escaped
      .allMatches(format)
      .map((m) => m[0]!.substring(1, m[0]!.length - 1))
      .toList();
  var out = format.replaceAll(_escaped, _hole);

  String pad(int value, int width) => '$value'.padLeft(width, '0');

  final hour12 = date.hour % 12 == 0 ? 12 : date.hour % 12;
  final isPm = date.hour >= 12;

  // Names first: their letters would otherwise be eaten by the numeric
  // passes — 'Mar' carries an 'a' and an 'r'.
  out = out.replaceAll('MMM', _monthMark).replaceAll('EEE', _weekdayMark);

  out = out
      .replaceAllMapped(
        RegExp('y+'),
        (m) => m[0]!.length <= 2
            ? pad(date.year % 100, 2)
            : pad(date.year, m[0]!.length),
      )
      .replaceAllMapped(RegExp('M+'), (m) => pad(date.month, m[0]!.length))
      .replaceAllMapped(RegExp('d+'), (m) => pad(date.day, m[0]!.length))
      .replaceAllMapped(RegExp('H+'), (m) => pad(date.hour, m[0]!.length))
      .replaceAllMapped(RegExp('h+'), (m) => pad(hour12, m[0]!.length))
      .replaceAllMapped(RegExp('m+'), (m) => pad(date.minute, m[0]!.length))
      .replaceAllMapped(RegExp('s+'), (m) => pad(date.second, m[0]!.length))
      .replaceAll('A', isPm ? pm.toUpperCase() : am.toUpperCase())
      .replaceAll('a', isPm ? pm.toLowerCase() : am.toLowerCase());

  out = out
      .replaceAll(_monthMark, months[date.month - 1])
      .replaceAll(_weekdayMark, weekdays[date.weekday - 1]);

  var i = 0;
  return out.replaceAllMapped(RegExp(_hole), (_) => kept[i++]);
}

/// Reads [text] back against [format], or null when it does not say a date.
///
/// Lenient about width — `2026-1-5` reads the same as `2026-01-05` — because a
/// field is read while it is still being typed. Strict about what a date is: a
/// 31st of February is refused rather than rolled into March, which is what
/// [DateTime] itself would do and what would make a typo land somewhere else
/// entirely.
DateTime? parseDate(
  String text,
  String format, {
  List<String> months = _englishMonths,
  DateTime? fallback,
}) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return null;

  final fields = DateFields.of(format);
  final named = RegExp('MMM').hasMatch(format.replaceAll(_escaped, ''));

  var month = 0;
  var rest = trimmed;
  if (named) {
    final at = months.indexWhere(
      (m) => rest.toLowerCase().contains(m.toLowerCase()),
    );
    if (at < 0) return null;
    month = at + 1;
    rest = rest.replaceAll(RegExp(months[at], caseSensitive: false), ' ');
  }

  final digits = RegExp(r'\d+').allMatches(rest).map((m) => m[0]!).toList();
  final wanted = <String>[
    if (fields.year) 'year',
    if (fields.month && !named) 'month',
    if (fields.day) 'day',
  ];
  // Anything the format also names past the date — a time — is read by the
  // time half and does not belong here.
  if (digits.length < wanted.length) return null;

  // The order the format writes them in is the order they were typed in.
  final order = _fieldOrder(format, named: named);
  var year = fallback?.year ?? DateTime.now().year;
  var day = 1;
  for (var i = 0; i < order.length && i < digits.length; i++) {
    final value = int.tryParse(digits[i]);
    if (value == null) return null;
    switch (order[i]) {
      case 'year':
        year = value < 100 ? 2000 + value : value;
      case 'month':
        month = value;
      case 'day':
        day = value;
    }
  }

  if (month < 1 || month > 12) return null;
  if (day < 1 || day > daysInMonth(year, month)) return null;
  return DateTime(year, month, day);
}

/// The date fields in the order [format] writes them.
List<String> _fieldOrder(String format, {required bool named}) {
  final bare = format.replaceAll(_escaped, '');
  final seen = <String>[];
  for (var i = 0; i < bare.length; i++) {
    final ch = bare[i];
    final token = switch (ch) {
      'y' => 'year',
      'M' => named ? null : 'month',
      'd' => 'day',
      _ => null,
    };
    if (token != null && !seen.contains(token)) seen.add(token);
  }
  return seen;
}

const List<String> _englishMonths = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

const List<String> _englishWeekdays = [
  'Mon',
  'Tue',
  'Wed',
  'Thu',
  'Fri',
  'Sat',
  'Sun',
];
