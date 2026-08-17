import 'package:flutter/material.dart'
    hide ThemeData, Checkbox, Radio, Switch, Tooltip, Drawer;
import 'package:flutter_test/flutter_test.dart';
import 'package:seed_ui/seed_ui.dart';
// The formatter is package-internal, but every awkward case is reachable
// through it directly and none of them is through a running clock.
import 'package:seed_ui/src/components/data_display/countdown.dart'
    show countdownClock, formatDuration;

Widget _host(Widget child) =>
    MaterialApp(home: Scaffold(body: Center(child: child)));

/// Drives the widget's clock and the test's timers together.
///
/// `tester.pump` moves fake timers but not `DateTime.now`, so without this the
/// count would never advance no matter how long the test waited.
class _Clock {
  _Clock(this.now);

  DateTime now;

  Future<void> advance(WidgetTester tester, Duration d) async {
    now = now.add(d);
    await tester.pump(d);
  }
}

void main() {
  late _Clock clock;

  setUp(() {
    clock = _Clock(DateTime(2026, 8, 17, 12));
    countdownClock = () => clock.now;
  });

  tearDown(() => countdownClock = DateTime.now);

  group('formatDuration', () {
    test('pads to the width of the token run', () {
      const d = Duration(hours: 2, minutes: 5, seconds: 7);
      expect(formatDuration(d, 'HH:mm:ss'), '02:05:07');
      expect(formatDuration(d, 'H:m:s'), '2:5:7');
      expect(formatDuration(d, 'HHH'), '002');
    });

    test('a unit left out of the format rolls into the next one down', () {
      const d = Duration(days: 1, hours: 2);
      // No days token, so the day has nowhere to go but the hours.
      expect(formatDuration(d, 'HH:mm:ss'), '26:00:00');
      expect(formatDuration(d, 'D[d] HH:mm:ss'), '1d 02:00:00');
      // And with neither, into the minutes.
      expect(formatDuration(d, 'mm'), '1560');
    });

    test('square brackets are kept as written', () {
      const d = Duration(hours: 2, minutes: 5);
      // The letters inside would otherwise be read as tokens: `m` is minutes,
      // `s` seconds, `D` days.
      expect(formatDuration(d, 'H[h] m[m]'), '2h 5m');
      expect(formatDuration(d, '[days:] D'), 'days: 0');
      expect(formatDuration(Duration.zero, '[HH:mm:ss]'), 'HH:mm:ss');
    });

    test('several bracketed runs come back in their own order', () {
      expect(
        formatDuration(const Duration(hours: 1, minutes: 2), '[a]H[b]m[c]'),
        'a1b2c',
      );
    });

    test('milliseconds are what is left after the seconds', () {
      const d = Duration(seconds: 3, milliseconds: 45);
      expect(formatDuration(d, 'ss.SSS'), '03.045');
      expect(formatDuration(d, 'SSSS'), '3045');
    });

    test('zero is written out, not left blank', () {
      expect(formatDuration(Duration.zero, 'HH:mm:ss'), '00:00:00');
    });
  });

  group('Countdown', () {
    testWidgets('counts down, on the second, and stops at zero', (
      tester,
    ) async {
      var finished = 0;
      final target = clock.now.add(const Duration(seconds: 3));

      await tester.pumpWidget(
        _host(
          Countdown(
            target: target,
            format: 'mm:ss',
            onFinish: () => finished++,
          ),
        ),
      );
      expect(find.text('00:03'), findsOneWidget);

      await clock.advance(tester, const Duration(seconds: 1));
      expect(find.text('00:02'), findsOneWidget);

      await clock.advance(tester, const Duration(seconds: 2));
      expect(find.text('00:00'), findsOneWidget);
      await tester.pump();
      expect(finished, 1, reason: 'once it has run out, and only once');

      // Nothing left running to fire again, or to leak past the test.
      await clock.advance(tester, const Duration(seconds: 5));
      expect(finished, 1);
      expect(find.text('00:00'), findsOneWidget);
    });

    testWidgets('a target already past reads zero from the start', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          Countdown(
            target: clock.now.subtract(const Duration(hours: 1)),
            format: 'HH:mm:ss',
          ),
        ),
      );
      // Not negative time: a countdown that has run out has run out.
      expect(find.text('00:00:00'), findsOneWidget);
    });

    testWidgets('counting up has no end, and never calls onFinish', (
      tester,
    ) async {
      var finished = 0;
      await tester.pumpWidget(
        _host(
          Countdown(
            target: clock.now,
            type: CountdownType.up,
            format: 'mm:ss',
            onFinish: () => finished++,
          ),
        ),
      );
      expect(find.text('00:00'), findsOneWidget);

      await clock.advance(tester, const Duration(seconds: 2));
      expect(find.text('00:02'), findsOneWidget);
      expect(finished, 0);

      await clock.advance(tester, const Duration(seconds: 1));
      expect(find.text('00:03'), findsOneWidget);
    });

    testWidgets('onChange reports the time behind the text', (tester) async {
      final seen = <Duration>[];
      await tester.pumpWidget(
        _host(
          Countdown(
            target: clock.now.add(const Duration(seconds: 5)),
            format: 'mm:ss',
            onChange: seen.add,
          ),
        ),
      );
      await clock.advance(tester, const Duration(seconds: 2));
      expect(seen, isNotEmpty);
      expect(seen.last.inSeconds, lessThanOrEqualTo(3));

      await clock.advance(tester, const Duration(seconds: 4));
    });

    testWidgets('the builder wraps the time', (tester) async {
      await tester.pumpWidget(
        _host(
          Countdown(
            target: clock.now.add(const Duration(minutes: 1)),
            format: 'mm:ss',
            builder: (context, formatted) => Text('left: $formatted'),
          ),
        ),
      );
      expect(find.text('left: 01:00'), findsOneWidget);
      await clock.advance(tester, const Duration(minutes: 2));
    });

    testWidgets('a new target restarts the count', (tester) async {
      Widget at(Duration d) => _host(
            Countdown(target: clock.now.add(d), format: 'mm:ss'),
          );

      await tester.pumpWidget(at(const Duration(seconds: 5)));
      expect(find.text('00:05'), findsOneWidget);

      await tester.pumpWidget(at(const Duration(seconds: 30)));
      expect(find.text('00:30'), findsOneWidget);
      await clock.advance(tester, const Duration(seconds: 31));
    });

    testWidgets('a part second still counts as a whole one left', (
      tester,
    ) async {
      // Three and a half seconds away. You have four seconds left, not three:
      // formatting the remainder as it stands throws the part away and opens
      // the countdown one short of its own length.
      await tester.pumpWidget(
        _host(
          Countdown(
            target: clock.now.add(const Duration(milliseconds: 3500)),
            format: 'mm:ss',
          ),
        ),
      );
      expect(find.text('00:04'), findsOneWidget);

      // And it turns over on the target's own half-second, not the clock's.
      await clock.advance(tester, const Duration(milliseconds: 400));
      expect(find.text('00:04'), findsOneWidget);
      await clock.advance(tester, const Duration(milliseconds: 200));
      expect(find.text('00:03'), findsOneWidget);
    });

    testWidgets('counting up shows the whole seconds gone, not the next one', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          Countdown(
            target: clock.now,
            type: CountdownType.up,
            format: 'mm:ss',
          ),
        ),
      );
      await clock.advance(tester, const Duration(milliseconds: 1900));
      // One and nine tenths elapsed is one second gone, not two.
      expect(find.text('00:01'), findsOneWidget);
    });

    testWidgets('a format asking for fractions shows them, and moves', (
      tester,
    ) async {
      // Which of the two clocks drives this — a ticker for sub-second formats,
      // a re-aimed timer otherwise — is a matter of how many times the widget
      // wakes, not of what it draws, and a test clock that jumps cannot tell
      // them apart. Only the drawn result is asserted here.
      var ticks = 0;
      await tester.pumpWidget(
        _host(
          Countdown(
            target: clock.now.add(const Duration(seconds: 2)),
            format: 'ss.SSS',
            onChange: (_) => ticks++,
          ),
        ),
      );
      expect(find.text('02.000'), findsOneWidget);

      ticks = 0;
      await clock.advance(tester, const Duration(milliseconds: 120));
      expect(find.text('01.880'), findsOneWidget);
      expect(ticks, greaterThan(0), reason: 'and reported it moving');

      await clock.advance(tester, const Duration(milliseconds: 1880));
      expect(find.text('00.000'), findsOneWidget);
    });

    testWidgets('tokens come from the provider, and the instance wins', (
      tester,
    ) async {
      const fromProvider = Color(0xFF722ED1);
      const fromInstance = Color(0xFFFA8C16);

      Color colour() => tester.widget<Text>(find.byType(Text)).style!.color!;

      Widget under(CountdownToken? instance) => ConfigProvider(
            theme: ThemeData(
              components: const ComponentsConfig(
                countdown: CountdownToken(color: fromProvider),
              ),
            ),
            child: _host(
              Countdown(
                target: clock.now.add(const Duration(minutes: 5)),
                token: instance,
              ),
            ),
          );

      await tester.pumpWidget(under(null));
      expect(colour(), fromProvider);

      await tester.pumpWidget(under(const CountdownToken(color: fromInstance)));
      expect(colour(), fromInstance);

      await clock.advance(tester, const Duration(minutes: 6));
    });
  });
  group('CountdownController', () {
    testWidgets(
        'pausing holds the count still, and resuming goes on from '
        'where it stopped', (tester) async {
      final c = CountdownController(
        target: clock.now.add(const Duration(seconds: 30)),
      );
      addTearDown(c.dispose);

      await tester.pumpWidget(_host(Countdown(controller: c, format: 'mm:ss')));
      expect(find.text('00:30'), findsOneWidget);

      await clock.advance(tester, const Duration(seconds: 5));
      expect(find.text('00:25'), findsOneWidget);

      c.pause();
      await tester.pump();
      expect(c.isPaused, isTrue);

      // Ten seconds of wall clock pass with the count held.
      await clock.advance(tester, const Duration(seconds: 10));
      expect(find.text('00:25'), findsOneWidget);

      c.resume();
      await tester.pump();
      expect(c.isPaused, isFalse);
      // Twenty-five still left: the pause is given back, not charged.
      expect(find.text('00:25'), findsOneWidget);

      await clock.advance(tester, const Duration(seconds: 5));
      expect(find.text('00:20'), findsOneWidget);
    });

    testWidgets('add lengthens the count, and a negative one cuts it short', (
      tester,
    ) async {
      final c = CountdownController(
        target: clock.now.add(const Duration(seconds: 30)),
      );
      addTearDown(c.dispose);

      await tester.pumpWidget(_host(Countdown(controller: c, format: 'mm:ss')));
      c.add(const Duration(seconds: 30));
      await tester.pump();
      expect(find.text('01:00'), findsOneWidget);

      c.add(const Duration(seconds: -45));
      await tester.pump();
      expect(find.text('00:15'), findsOneWidget);
    });

    testWidgets('time added during a pause is added to where it stopped', (
      tester,
    ) async {
      final c = CountdownController(
        target: clock.now.add(const Duration(seconds: 30)),
      );
      addTearDown(c.dispose);

      await tester.pumpWidget(_host(Countdown(controller: c, format: 'mm:ss')));
      await clock.advance(tester, const Duration(seconds: 5));
      c.pause();
      await tester.pump();
      expect(find.text('00:25'), findsOneWidget);

      // Ten seconds go by with the count held, then half a minute is added.
      await clock.advance(tester, const Duration(seconds: 10));
      c.add(const Duration(seconds: 30));
      await tester.pump();
      // Fifty-five: added to the twenty-five it stands at, not to the fifteen
      // the wall clock has run down to behind its back.
      expect(find.text('00:55'), findsOneWidget);
    });

    testWidgets('restart begins again, and releases a pause', (tester) async {
      var finished = 0;
      final c = CountdownController(
        target: clock.now.add(const Duration(seconds: 3)),
      );
      addTearDown(c.dispose);

      await tester.pumpWidget(
        _host(
          Countdown(
            controller: c,
            format: 'mm:ss',
            onFinish: () => finished++,
          ),
        ),
      );
      await clock.advance(tester, const Duration(seconds: 4));
      expect(find.text('00:00'), findsOneWidget);
      expect(finished, 1);

      c.pause();
      await tester.pump();
      c.restart(const Duration(seconds: 10));
      await tester.pump();
      expect(c.isPaused, isFalse, reason: 'a fresh start is a running one');
      expect(find.text('00:10'), findsOneWidget);

      // And it runs, and finishes again.
      await clock.advance(tester, const Duration(seconds: 5));
      expect(find.text('00:05'), findsOneWidget);
      await clock.advance(tester, const Duration(seconds: 6));
      expect(finished, 2);
    });

    testWidgets('a new target counts against it', (tester) async {
      final c = CountdownController(
        target: clock.now.add(const Duration(seconds: 30)),
      );
      addTearDown(c.dispose);

      await tester.pumpWidget(_host(Countdown(controller: c, format: 'mm:ss')));
      c.target = clock.now.add(const Duration(minutes: 2));
      await tester.pump();
      expect(find.text('02:00'), findsOneWidget);
    });

    testWidgets('value is what is on screen', (tester) async {
      final c = CountdownController(
        target: clock.now.add(const Duration(seconds: 30)),
      );
      addTearDown(c.dispose);

      await tester.pumpWidget(_host(Countdown(controller: c, format: 'mm:ss')));
      expect(c.value, const Duration(seconds: 30));

      await clock.advance(tester, const Duration(seconds: 5));
      expect(c.value, const Duration(seconds: 25));
    });

    testWidgets('counting up can be paused too', (tester) async {
      final c = CountdownController(target: clock.now);
      addTearDown(c.dispose);

      await tester.pumpWidget(
        _host(
          Countdown(controller: c, type: CountdownType.up, format: 'mm:ss'),
        ),
      );
      await clock.advance(tester, const Duration(seconds: 5));
      expect(find.text('00:05'), findsOneWidget);

      c.pause();
      await tester.pump();
      await clock.advance(tester, const Duration(seconds: 10));
      expect(find.text('00:05'), findsOneWidget);

      c.resume();
      await clock.advance(tester, const Duration(seconds: 2));
      expect(find.text('00:07'), findsOneWidget);
    });

    test('a target and a controller are one moment too many', () {
      expect(
        () => Countdown(target: DateTime.now(), controller: null),
        returnsNormally,
      );
      expect(
        () => Countdown(
          target: DateTime.now(),
          controller: CountdownController(target: DateTime.now()),
        ),
        throwsAssertionError,
      );
      expect(Countdown.new, throwsAssertionError);
    });
  });
}
