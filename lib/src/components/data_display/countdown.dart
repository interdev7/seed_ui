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
/// the global theme. Supply one globally through `ThemeData(components:
/// ComponentsConfig(countdown: CountdownToken(...)))`,
/// or per instance via [Countdown.token].
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

/// A handle on a running [Countdown], for driving it from outside the build.
///
/// The moment counted against can be changed by rebuilding the widget with a
/// new `target`; a controller is not needed for that. What it is needed for is
/// **pausing** — the count runs on the wall clock, and there is no way to hold
/// it still by describing it. Everything else here is the same handle used for
/// the things that go with pausing: adding time, restarting, reading where the
/// count stands.
///
/// ```dart
/// final controller = CountdownController(
///   target: DateTime.now().add(const Duration(minutes: 5)),
/// );
///
/// Countdown(controller: controller)
/// // …later
/// controller.pause();
/// controller.add(const Duration(seconds: 30));
/// ```
///
/// Dispose of it with the [State] that made it.
class CountdownController extends ChangeNotifier {
  /// Creates a [CountdownController] counting against [target].
  CountdownController({required DateTime target}) : _target = target;

  DateTime _target;
  DateTime? _pausedAt;
  Duration _value = Duration.zero;

  /// The moment being counted towards, or from.
  DateTime get target => _target;

  /// Counts against a new moment, from wherever the clock now stands.
  set target(DateTime value) {
    if (value == _target) return;
    _target = value;
    notifyListeners();
  }

  /// Whether the count is standing still.
  bool get isPaused => _pausedAt != null;

  /// What the countdown last drew, as a duration.
  ///
  /// Written by the widget as it ticks, so it is the value on screen rather
  /// than a second, separately rounded reading of the clock.
  Duration get value => _value;

  /// The instant the count should be measured against: frozen while paused.
  DateTime get now => _pausedAt ?? countdownClock();

  /// Holds the count still. Does nothing if it is already held.
  void pause() {
    if (_pausedAt != null) return;
    _pausedAt = countdownClock();
    notifyListeners();
  }

  /// Lets it run on from where it stopped.
  ///
  /// The target moves by however long the pause lasted, which is what makes
  /// the count resume rather than jump forward by the time spent stopped.
  void resume() {
    final at = _pausedAt;
    if (at == null) return;
    _pausedAt = null;
    _target = _target.add(countdownClock().difference(at));
    notifyListeners();
  }

  /// Moves the target by [delta] — lengthening a countdown, or cutting it
  /// short with a negative one.
  void add(Duration delta) {
    _target = _target.add(delta);
    notifyListeners();
  }

  /// Starts again, counting against [from] from now. Releases a pause.
  void restart(Duration from) {
    _pausedAt = null;
    _target = countdownClock().add(from);
    notifyListeners();
  }

  /// Records what was drawn. Called by the widget; not part of the handle.
  void _report(Duration value) => _value = value;
}

/// Defaults for every [Countdown] under a `ConfigProvider`.
///
/// House style for countdowns.
@immutable
class CountdownDefaults {
  /// Creates a [CountdownDefaults].
  const CountdownDefaults({this.type});

  /// Whether time runs down or up.
  final CountdownType? type;
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
    this.target,
    this.controller,
    this.type,
    this.format = 'HH:mm:ss',
    this.onFinish,
    this.onChange,
    this.builder,
    this.token,
  }) : assert(
          (target == null) != (controller == null),
          'Give either a target or a controller, not both: two moments to '
          'count against is one too many.',
        );

  /// The moment counted towards, or from. Null when a [controller] holds it.
  final DateTime? target;

  /// Drives the count from outside the build — pausing above all, which no
  /// arrangement of properties can express. See [CountdownController].
  final CountdownController? controller;

  /// Whether the count runs towards [target] or away from it.
  final CountdownType? type;

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
  /// The defaults set for this component in the subtree, if any.
  CountdownDefaults? get _defaults =>
      ConfigProvider.defaultsOf<CountdownDefaults>(context);

  /// This widget's word, then the subtree's, then the kit's.
  CountdownType get _type =>
      widget.type ?? _defaults?.type ?? CountdownType.down;

  /// Frames, for a format that shows fractions of a second.
  Ticker? _ticker;

  /// A single shot re-aimed at the next moment the text will change, for one
  /// that does not. Not a repeating timer: that drifts, and it would in any
  /// case be aimed at the wrong instant — the text turns over relative to the
  /// target, which rarely falls on a whole second of the wall clock.
  Timer? _timer;

  String _shown = '';
  bool _finished = false;

  CountdownController? get _controller => widget.controller;

  /// The moment counted against, wherever it is kept.
  DateTime get _target => _controller?.target ?? widget.target!;

  /// The instant to measure from: a controller freezes it while paused.
  DateTime get _now => _controller?.now ?? countdownClock();

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
    _controller?.addListener(_onController);
  }

  /// The type the clock is running under, as of the last settled dependency.
  ///
  /// The first tick is set up here rather than in [initState]: the type may
  /// come from the provider's defaults, and inherited widgets cannot be read
  /// that early. A later change of the ambient default lands here too, and
  /// restarts the clock the same way a changed prop would.
  CountdownType? _running;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final type = _type;
    if (_running == type) return;
    final first = _running == null;
    _running = type;
    _stop();
    _finished = false;
    if (first) _controller?._report(_value());
    _shown = _format(_value());
    if (_controller?.isPaused ?? false) return;
    _start();
  }

  /// The controller changed the target, or paused. Either way the schedule
  /// that was standing is no longer the right one.
  void _onController() {
    if (!mounted) return;
    _stop();
    _finished = false;
    final text = _format(_value());
    if (text != _shown) setState(() => _shown = text);
    if (_controller!.isPaused) return;
    _start();
  }

  @override
  void didUpdateWidget(Countdown old) {
    super.didUpdateWidget(old);
    if (widget.controller != old.controller) {
      old.controller?.removeListener(_onController);
      widget.controller?.addListener(_onController);
    }
    if (_target != (old.controller?.target ?? old.target) ||
        widget.type != old.type ||
        widget.format != old.format) {
      _stop();
      _finished = false;
      _shown = _format(_value());
      if (_controller?.isPaused ?? false) return;
      _start();
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(_onController);
    _stop();
    super.dispose();
  }

  void _start() {
    if (_raw() == Duration.zero && _type == CountdownType.down) {
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
    final next = _type == CountdownType.down
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
    final now = _now;
    final d = _type == CountdownType.down
        ? _target.difference(now)
        : now.difference(_target);
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
    if (_type == CountdownType.up) return Duration(milliseconds: ms);
    final step = _step;
    return Duration(milliseconds: ((ms + step - 1) ~/ step) * step);
  }

  void _tick() {
    if (!mounted) return;
    final value = _value();
    final text = _format(value);

    // The clock moves far more often than the drawn text does, so the rebuild
    // is spent only when the text differs.
    _controller?._report(value);
    if (text != _shown) {
      setState(() => _shown = text);
      widget.onChange?.call(value);
    }

    if (_type == CountdownType.down && _raw() == Duration.zero) {
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

    final shown = context.seedLocale.figures(_shown);
    return widget.builder?.call(context, shown) ??
        Text(
          shown,
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
