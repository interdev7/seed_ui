import 'dart:async';

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../../theme/config_provider.dart';
import '../../theme/design_token.dart';

/// Which way a [Countdown] runs.
enum CountdownType {
  /// Towards the target, stopping at zero. The default.
  down,

  /// Away from it, counting how long ago it passed.
  up,
}

/// Per-component design tokens for [Countdown].
///
/// Every field is an override; a null one falls back to the value derived from
/// the global theme. Supply one globally through `ConfigProvider(components:
/// [CountdownToken(...)])`, or per instance via [Countdown.token].
@immutable
class CountdownToken {
  /// Creates a [CountdownToken].
  const CountdownToken({this.fontSize, this.color, this.fontWeight});

  /// Size of the figures (`fontSize`).
  final double? fontSize;

  /// Colour of the figures (`color`).
  final Color? color;

  /// Weight of the figures (`fontWeight`).
  final FontWeight? fontWeight;

  _ResolvedCountdownToken _resolve(Token t) => _ResolvedCountdownToken(
        fontSize: fontSize ?? t.fontSizeXL,
        color: color ?? t.colorText,
        fontWeight: fontWeight ?? FontWeight.w400,
      );
}

@immutable
class _ResolvedCountdownToken {
  const _ResolvedCountdownToken({
    required this.fontSize,
    required this.color,
    required this.fontWeight,
  });

  final double fontSize;
  final Color color;
  final FontWeight fontWeight;
}

/// A running count of the time to a moment, or since one.
///
/// ```dart
/// Countdown(target: DateTime.now().add(const Duration(hours: 2)))
/// Countdown(target: launchedAt, type: CountdownType.up, format: 'D[d] HH:mm:ss')
/// ```
///
/// The [format] decides both what is drawn and how often: a format asking for
/// milliseconds is redrawn every frame, one that stops at seconds once a
/// second, on the second. Nothing is redrawn while the drawn text would not
/// change, so an hours-and-minutes countdown costs almost nothing to leave on
/// screen.
///
/// Named `Countdown` rather than `Timer` because `dart:async` already has a
/// `Timer`, and the file that shows this widget is usually the same file that
/// needs the other one.
class Countdown extends StatefulWidget {
  /// Creates a [Countdown].
  const Countdown({
    super.key,
    required this.target,
    this.type = CountdownType.down,
    this.format = 'HH:mm:ss',
    this.onFinish,
    this.onChange,
    this.builder,
    this.token,
  });

  /// The moment counted towards, or from.
  final DateTime target;

  /// Whether the count runs towards [target] or away from it.
  final CountdownType type;

  /// How the remaining time is written out.
  ///
  /// | Token | Unit |
  /// | --- | --- |
  /// | `Y` | Years |
  /// | `M` | Months |
  /// | `D` | Days |
  /// | `H` | Hours |
  /// | `m` | Minutes |
  /// | `s` | Seconds |
  /// | `S` | Milliseconds |
  ///
  /// Each unit takes what it can from what the larger ones left, so a format
  /// that omits a unit rolls it into the next one down: `HH:mm:ss` shows
  /// `26:00:00` for a day and two hours, where `D[d] HH:mm:ss` shows
  /// `1d 02:00:00`. A run of a token is the width it is padded to — `ss` gives
  /// `07`, `s` gives `7`.
  ///
  /// Text in square brackets is kept as written, which is how a unit letter
  /// gets drawn as itself: `H[h] m[m]` gives `2h 5m`.
  final String format;

  /// Called once, when a downward count reaches the target. Never called
  /// counting up, which has no end to reach.
  final VoidCallback? onFinish;

  /// Called with the time left, or elapsed, whenever the count is redrawn.
  final ValueChanged<Duration>? onChange;

  /// Wraps the formatted time — a place for a label, a prefix, an icon.
  ///
  /// Without one the time is drawn on its own.
  final Widget Function(BuildContext context, String formatted)? builder;

  /// Per-instance token overrides.
  final CountdownToken? token;

  @override
  State<Countdown> createState() => _CountdownState();
}

class _CountdownState extends State<Countdown>
    with SingleTickerProviderStateMixin {
  /// Frames, for a format that shows fractions of a second.
  Ticker? _ticker;

  /// A single shot re-aimed at the next moment the text will change, for one
  /// that does not. Not a repeating timer: that drifts, and it would in any
  /// case be aimed at the wrong instant — the text turns over relative to the
  /// target, which rarely falls on a whole second of the wall clock.
  Timer? _timer;

  String _shown = '';
  bool _finished = false;

  /// The smallest unit the format asks for, in milliseconds. Everything the
  /// widget does is quantised to it: what is displayed, and when to look
  /// again.
  int get _step {
    final shown = _tokensIn(widget.format);
    for (final (name, unit) in _units.reversed) {
      if (shown.contains(name)) return unit;
    }
    return Duration.millisecondsPerSecond;
  }

  bool get _perFrame => _step < Duration.millisecondsPerSecond;

  @override
  void initState() {
    super.initState();
    _shown = _format(_value());
    _start();
  }

  @override
  void didUpdateWidget(Countdown old) {
    super.didUpdateWidget(old);
    if (widget.target != old.target ||
        widget.type != old.type ||
        widget.format != old.format) {
      _stop();
      _finished = false;
      _shown = _format(_value());
      _start();
    }
  }

  @override
  void dispose() {
    _stop();
    super.dispose();
  }

  void _start() {
    if (_raw() == Duration.zero && widget.type == CountdownType.down) {
      _finish();
      return;
    }
    if (_perFrame) {
      _ticker = createTicker((_) => _tick())..start();
    } else {
      _arm();
    }
  }

  void _stop() {
    _ticker?.dispose();
    _ticker = null;
    _timer?.cancel();
    _timer = null;
  }

  /// Sleeps exactly as long as the drawn text will stay the same.
  void _arm() {
    _timer = Timer(_untilChange(), () {
      _tick();
      if (mounted && !_finished) _arm();
    });
  }

  Duration _untilChange() {
    final ms = _raw().inMilliseconds;
    final step = _step;
    final next = widget.type == CountdownType.down
        // Counting down, the text turns over as the remainder falls through
        // the multiple of the step below the one now displayed.
        ? ms - ((ms + step - 1) ~/ step - 1) * step
        // Counting up, as the elapsed time reaches the next one above.
        : (ms ~/ step + 1) * step - ms;
    return Duration(milliseconds: next.clamp(1, step));
  }

  /// The true distance to the target, unrounded and never negative: a
  /// countdown that has run out has run out, rather than going on into
  /// negative time.
  Duration _raw() {
    final now = countdownClock();
    final d = widget.type == CountdownType.down
        ? widget.target.difference(now)
        : now.difference(widget.target);
    return d.isNegative ? Duration.zero : d;
  }

  /// What is drawn.
  ///
  /// A countdown rounds up to the step, so three seconds away reads three
  /// seconds until one of them has actually gone. Rounding down — which is
  /// what simply formatting the remainder does — makes a fresh countdown open
  /// one short of its own length. Counting up rounds down, because two and a
  /// half seconds elapsed is two.
  Duration _value() {
    final ms = _raw().inMilliseconds;
    if (widget.type == CountdownType.up) return Duration(milliseconds: ms);
    final step = _step;
    return Duration(milliseconds: ((ms + step - 1) ~/ step) * step);
  }

  void _tick() {
    if (!mounted) return;
    final value = _value();
    final text = _format(value);

    // The clock moves far more often than the drawn text does, so the rebuild
    // is spent only when the text differs.
    if (text != _shown) {
      setState(() => _shown = text);
      widget.onChange?.call(value);
    }

    if (widget.type == CountdownType.down && _raw() == Duration.zero) {
      _finish();
    }
  }

  void _finish() {
    if (_finished) return;
    _finished = true;
    _stop();
    if (widget.onFinish == null) return;
    // Out of the frame: the callback commonly rebuilds an ancestor, which must
    // not happen while this one is still being built.
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onFinish!.call();
    });
  }

  String _format(Duration d) => formatDuration(d, widget.format);

  @override
  Widget build(BuildContext context) {
    final t = context.softToken;
    final r = (widget.token ??
            ConfigProvider.componentOf<CountdownToken>(context) ??
            const CountdownToken())
        ._resolve(t);

    return widget.builder?.call(context, _shown) ??
        Text(
          _shown,
          style: TextStyle(
            fontSize: r.fontSize,
            color: r.color,
            fontWeight: r.fontWeight,
          ),
        );
  }
}

/// The clock a [Countdown] measures against.
///
/// Wall clock rather than accumulated ticks, so a count stays right across a
/// suspended app rather than losing the time it slept. That leaves it beyond
/// the reach of the test clock, which fakes timers but not [DateTime.now], so
/// this is the seam tests move instead.
@visibleForTesting
DateTime Function() countdownClock = DateTime.now;

/// The unit each token stands for, largest first. Order is the whole of the
/// arithmetic: every unit takes what it can from what the ones above it left,
/// so a format that omits days rolls them into the hours.
const List<(String, int)> _units = [
  ('Y', Duration.millisecondsPerDay * 365),
  ('M', Duration.millisecondsPerDay * 30),
  ('D', Duration.millisecondsPerDay),
  ('H', Duration.millisecondsPerHour),
  ('m', Duration.millisecondsPerMinute),
  ('s', Duration.millisecondsPerSecond),
  ('S', 1),
];

final RegExp _escaped = RegExp(r'\[[^\]]*\]');

Set<String> _tokensIn(String format) {
  final bare = format.replaceAll(_escaped, '');
  return {
    for (final (name, _) in _units)
      if (bare.contains(name)) name,
  };
}

/// Writes [d] out according to [format]. See [Countdown.format].
///
/// Exposed to the package rather than kept inside the widget so the formatting
/// can be tested on its own, where every awkward case is reachable without
/// waiting for a clock.
String formatDuration(Duration d, String format) {
  // Bracketed runs are lifted out before anything else, so a literal `[m]`
  // cannot be mistaken for the minutes token. A NUL stands in for each while
  // the units are substituted; no format can contain one to be confused with.
  const hole = '\u0000';
  final kept = _escaped
      .allMatches(format)
      .map((m) => m[0]!.substring(1, m[0]!.length - 1))
      .toList();
  var out = format.replaceAll(_escaped, hole);

  var left = d.inMilliseconds;
  for (final (name, unit) in _units) {
    if (!out.contains(name)) continue;
    final value = left ~/ unit;
    left -= value * unit;
    out = out.replaceAllMapped(
      RegExp('$name+'),
      (m) => '$value'.padLeft(m[0]!.length, '0'),
    );
  }

  var i = 0;
  return out.replaceAllMapped(RegExp(hole), (_) => kept[i++]);
}
