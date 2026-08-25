import 'package:flutter/foundation.dart';

/// Which fields a time format asks for, and so which columns a picker shows.
///
/// Derived from the format rather than configured separately: a picker showing
/// a seconds column that the format then discards would be lying about what it
/// collects.
///
/// The grammar follows `formatDuration`, which the kit already uses for
/// `Countdown`, so one set of letters serves the whole package:
///
/// | Token | Means | Example |
/// | --- | --- | --- |
/// | `H` / `HH` | hour, 0-23 | `9`, `09` |
/// | `h` / `hh` | hour, 1-12 | `9`, `09` |
/// | `m` / `mm` | minute | `5`, `05` |
/// | `s` / `ss` | second | `5`, `05` |
/// | `A` | meridiem, upper case | `AM` |
/// | `a` | meridiem, lower case | `am` |
/// | `[...]` | literal text | `[at]` |
///
/// A time of day is a [Duration] since midnight. That is the kit's convention:
/// Dart has no time-of-day type outside Material, which this package is
/// deliberately built without, and a `Duration` needs no conversion to be
/// compared, added to, or handed to `formatDuration`.
@immutable
class TimeFields {
  /// Works out which fields [format] names.
  factory TimeFields.of(String format) {
    final bare = format.replaceAll(_escaped, '');
    return TimeFields._(
      hour: bare.contains('H') || bare.contains('h'),
      minute: bare.contains('m'),
      second: bare.contains('s'),
      meridiem: bare.contains('a') || bare.contains('A'),
    );
  }

  const TimeFields._({
    required this.hour,
    required this.minute,
    required this.second,
    required this.meridiem,
  });

  /// Whether an hour is named.
  final bool hour;

  /// Whether a minute is named.
  final bool minute;

  /// Whether a second is named.
  final bool second;

  /// Whether the format runs on a 12-hour clock.
  final bool meridiem;

  /// The finest unit the format keeps.
  ///
  /// Anything finer is dropped when a value is chosen, so a picker offering
  /// only hours and minutes cannot hand back stray seconds.
  Duration get resolution {
    if (second) return const Duration(seconds: 1);
    if (minute) return const Duration(minutes: 1);
    return const Duration(hours: 1);
  }

  @override
  bool operator ==(Object other) =>
      other is TimeFields &&
      other.hour == hour &&
      other.minute == minute &&
      other.second == second &&
      other.meridiem == meridiem;

  @override
  int get hashCode => Object.hash(hour, minute, second, meridiem);
}

final RegExp _escaped = RegExp(r'\[[^\]]*\]');

/// Stands in for lifted-out literal text while the fields are substituted.
///
/// A NUL, because no format can contain one to be confused with it.
final String _hole = String.fromCharCode(0);

/// Rounds [time] down to what [fields] can express, and wraps it into a day.
Duration normalizeTime(Duration time, TimeFields fields) {
  final unit = fields.resolution.inMilliseconds;
  var ms = time.inMilliseconds % Duration.millisecondsPerDay;
  if (ms < 0) ms += Duration.millisecondsPerDay;
  return Duration(milliseconds: ms - ms % unit);
}

/// Writes [time] out according to [format].
///
/// [am] and [pm] carry the meridiem words so a locale can say them its own
/// way. They are used only when the format names `a` or `A`.
String formatTime(
  Duration time,
  String format, {
  String am = 'AM',
  String pm = 'PM',
}) {
  // Bracketed runs are lifted out first, so a literal `[am]` cannot be read as
  // the meridiem token.
  final kept = _escaped
      .allMatches(format)
      .map((m) => m[0]!.substring(1, m[0]!.length - 1))
      .toList();
  var out = format.replaceAll(_escaped, _hole);

  final wrapped = Duration(
    milliseconds: time.inMilliseconds % Duration.millisecondsPerDay,
  );
  final hour24 = wrapped.inHours;
  final minute = wrapped.inMinutes % 60;
  final second = wrapped.inSeconds % 60;
  // Midnight and noon both read as 12 on a 12-hour clock, never as 0.
  final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
  final isPm = hour24 >= 12;

  String pad(int value, int width) => '$value'.padLeft(width, '0');

  out = out
      .replaceAllMapped(RegExp('H+'), (m) => pad(hour24, m[0]!.length))
      .replaceAllMapped(RegExp('h+'), (m) => pad(hour12, m[0]!.length))
      .replaceAllMapped(RegExp('m+'), (m) => pad(minute, m[0]!.length))
      .replaceAllMapped(RegExp('s+'), (m) => pad(second, m[0]!.length))
      .replaceAll('A', isPm ? pm.toUpperCase() : am.toUpperCase())
      .replaceAll('a', isPm ? pm.toLowerCase() : am.toLowerCase());

  var i = 0;
  return out.replaceAllMapped(RegExp(_hole), (_) => kept[i++]);
}

/// Reads [text] back against [format], or null when it does not say a time.
///
/// Lenient about width — `9:5` reads the same as `09:05` — because a field is
/// read while it is still being typed. Strict about range: an hour of 25 or a
/// minute of 60 is not a time, and returning null is what lets a field keep
/// the last good value instead of jumping somewhere absurd.
Duration? parseTime(
  String text,
  String format, {
  String am = 'AM',
  String pm = 'PM',
}) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return null;

  final fields = TimeFields.of(format);
  final digits = RegExp(r'\d+').allMatches(trimmed).map((m) => m[0]!).toList();

  final wanted = <String>[
    if (fields.hour) 'hour',
    if (fields.minute) 'minute',
    if (fields.second) 'second',
  ];
  if (digits.length != wanted.length) return null;

  var hour = 0;
  var minute = 0;
  var second = 0;
  for (var i = 0; i < wanted.length; i++) {
    final value = int.tryParse(digits[i]);
    if (value == null) return null;
    switch (wanted[i]) {
      case 'hour':
        hour = value;
      case 'minute':
        minute = value;
      case 'second':
        second = value;
    }
  }

  if (minute > 59 || second > 59) return null;

  if (fields.meridiem) {
    final lower = trimmed.toLowerCase();
    final saidPm = lower.contains(pm.toLowerCase());
    final saidAm = lower.contains(am.toLowerCase());
    // Exactly one of the two must be said: "9:00" alone is ambiguous on a
    // 12-hour clock, and guessing would silently pick the wrong half-day.
    if (saidAm == saidPm) return null;
    if (hour < 1 || hour > 12) return null;
    hour = hour % 12 + (saidPm ? 12 : 0);
  } else if (hour > 23) {
    return null;
  }

  return Duration(hours: hour, minutes: minute, seconds: second);
}
