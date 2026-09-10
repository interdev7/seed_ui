import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart' as m;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seed_ui/seed_ui.dart';
// The panel's grids back the pickers' chrome rather than being part of the
// public surface, so they are reached through the implementation library.
import 'package:seed_ui/src/components/data_entry/date_picker.dart'
    show DayGrid;
import 'package:seed_ui/src/icons/icons.dart' show RangeArrowPainter;

Widget _host(Widget child) => ConfigProvider(
      child: m.MaterialApp(
        navigatorKey: UiKit.navigatorKey,
        home: m.Scaffold(body: Center(child: child)),
      ),
    );

Future<void> _openPanel(WidgetTester tester) async {
  await tester.tap(find.byType(DateRangePicker));
  await tester.pumpAndSettle();
}

void main() {
  _arrowTests();
  _bandTests();
  _narrowTests();
  _litTests();
  group('a range is two dates', () {
    test('the ends are put in order, whichever way round they come', () {
      final forwards = DateRange(DateTime(2026, 3, 4), DateTime(2026, 3, 9));
      final backwards = DateRange(DateTime(2026, 3, 9), DateTime(2026, 3, 4));
      // Dragging backwards through a calendar means the same stretch.
      expect(backwards, forwards);
      expect(forwards.start, DateTime(2026, 3, 4));
      expect(forwards.end, DateTime(2026, 3, 9));
    });

    test('a range counts both its ends', () {
      expect(DateRange(DateTime(2026, 3, 4), DateTime(2026, 3, 4)).days, 1);
      expect(DateRange(DateTime(2026, 3, 4), DateTime(2026, 3, 9)).days, 6);
    });

    test('the clock is dropped, so two days compare equal', () {
      final withTime =
          DateRange(DateTime(2026, 3, 4, 14, 32), DateTime(2026, 3, 9, 1));
      expect(withTime, DateRange(DateTime(2026, 3, 4), DateTime(2026, 3, 9)));
    });

    test('it says which days it holds', () {
      final range = DateRange(DateTime(2026, 3, 4), DateTime(2026, 3, 9));
      expect(range.holds(DateTime(2026, 3, 4)), isTrue, reason: 'the start');
      expect(range.holds(DateTime(2026, 3, 9)), isTrue, reason: 'the end');
      expect(range.holds(DateTime(2026, 3, 6)), isTrue);
      expect(range.holds(DateTime(2026, 3, 3)), isFalse);
      expect(range.holds(DateTime(2026, 3, 10)), isFalse);
    });
  });

  group('picking a range', () {
    testWidgets('the panel shows two months, not one', (tester) async {
      await tester.pumpWidget(
        _host(DateRangePicker(
            value: DateRange(
          DateTime(2026, 3, 4),
          DateTime(2026, 3, 9),
        ))),
      );
      await _openPanel(tester);
      // A range that crosses a month is the ordinary case, and turning the
      // page mid-drag loses the thread.
      expect(find.text('Mar 2026'), findsOneWidget);
      expect(find.text('Apr 2026'), findsOneWidget);
    });

    testWidgets('nothing is handed back until both ends are in',
        (tester) async {
      DateRange? chosen;
      var calls = 0;
      await tester.pumpWidget(
        _host(
          DateRangePicker(
            onChanged: (v) {
              calls++;
              chosen = v;
            },
          ),
        ),
      );
      await _openPanel(tester);

      await tester.tap(find.text('10').first);
      await tester.pumpAndSettle();
      expect(calls, 0, reason: 'one end is not a range');

      await tester.tap(find.text('17').first);
      await tester.pumpAndSettle();
      expect(calls, 1);
      expect(chosen!.days, 8);
    });

    testWidgets('the panel closes once the range is whole', (tester) async {
      await tester.pumpWidget(_host(const DateRangePicker()));
      await _openPanel(tester);
      await tester.tap(find.text('10').first);
      await tester.pumpAndSettle();
      expect(find.byType(DayGrid), findsNWidgets(2), reason: 'still open');
      await tester.tap(find.text('17').first);
      await tester.pumpAndSettle();
      expect(find.byType(DayGrid), findsNothing);
    });

    testWidgets('a range picked backwards turns itself over', (tester) async {
      DateRange? chosen;
      await tester.pumpWidget(
        _host(DateRangePicker(onChanged: (v) => chosen = v)),
      );
      await _openPanel(tester);
      await tester.tap(find.text('17').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('10').first);
      await tester.pumpAndSettle();
      expect(chosen!.start.day, 10);
      expect(chosen!.end.day, 17);
    });
  });

  group('what the panel refuses', () {
    testWidgets('minDays bars the days that would make too short a range',
        (tester) async {
      DateRange? chosen;
      await tester.pumpWidget(
        _host(DateRangePicker(minDays: 5, onChanged: (v) => chosen = v)),
      );
      await _openPanel(tester);
      await tester.tap(find.text('10').first);
      await tester.pumpAndSettle();

      // Barred rather than refused after the fact: a refusal that arrives
      // after the tap is one nobody saw coming.
      await tester.tap(find.text('12').first);
      await tester.pumpAndSettle();
      expect(chosen, isNull);

      await tester.tap(find.text('14').first);
      await tester.pumpAndSettle();
      expect(chosen!.days, 5);
    });

    testWidgets('maxDays bars the days beyond it', (tester) async {
      DateRange? chosen;
      await tester.pumpWidget(
        _host(DateRangePicker(maxDays: 3, onChanged: (v) => chosen = v)),
      );
      await _openPanel(tester);
      await tester.tap(find.text('10').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('20').first);
      await tester.pumpAndSettle();
      expect(chosen, isNull);
    });

    testWidgets('minDate and maxDate close the ends off', (tester) async {
      DateRange? chosen;
      await tester.pumpWidget(
        _host(
          DateRangePicker(
            minDate: DateTime(2026, 3, 10),
            maxDate: DateTime(2026, 3, 20),
            defaultValue: DateRange(
              DateTime(2026, 3, 12),
              DateTime(2026, 3, 14),
            ),
            onChanged: (v) => chosen = v,
          ),
        ),
      );
      await _openPanel(tester);
      await tester.tap(find.text('5').first);
      await tester.pumpAndSettle();
      expect(chosen, isNull);
    });
  });

  group('presets', () {
    testWidgets('a preset takes its whole stretch', (tester) async {
      DateRange? chosen;
      await tester.pumpWidget(
        _host(
          DateRangePicker(
            onChanged: (v) => chosen = v,
            presets: [
              DateRangePreset(
                'That week',
                DateRange(DateTime(2026, 3, 2), DateTime(2026, 3, 8)),
              ),
            ],
          ),
        ),
      );
      await _openPanel(tester);
      await tester.tap(find.text('That week'));
      await tester.pumpAndSettle();
      expect(chosen!.days, 7);
    });

    testWidgets('a preset is asked for its range when it is taken',
        (tester) async {
      var asked = 0;
      DateRange? chosen;
      await tester.pumpWidget(
        _host(
          DateRangePicker(
            onChanged: (v) => chosen = v,
            presets: [
              DateRangePreset.of('The last few days', () {
                asked++;
                return DateRange(
                  DateTime(2026, 3, 1),
                  DateTime(2026, 3, asked),
                );
              }),
            ],
          ),
        ),
      );
      await _openPanel(tester);
      final drawn = asked;
      await tester.tap(find.text('The last few days'));
      await tester.pumpAndSettle();
      // Worked out at the moment it is taken: "the last seven days" means
      // seven days ending now, not seven ending when the field was drawn.
      expect(chosen!.end.day, drawn + 1);
    });
  });

  group('clearing', () {
    testWidgets('the mark drops the range', (tester) async {
      DateRange? value = DateRange(DateTime(2026, 3, 4), DateTime(2026, 3, 9));
      await tester.pumpWidget(
        _host(
          StatefulBuilder(
            builder: (context, setState) => DateRangePicker(
              value: value,
              onChanged: (v) => setState(() => value = v),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      await gesture.moveTo(tester.getCenter(find.byType(DateRangePicker)));
      await tester.pumpAndSettle();

      final mark = find.byWidgetPredicate(
        (w) =>
            w is CustomPaint &&
            w.painter.runtimeType.toString() == 'ClearIconPainter',
      );
      await tester.tapAt(tester.getCenter(mark));
      await tester.pumpAndSettle();
      expect(value, isNull);
    });
  });
}

void _arrowTests() {
  group('the mark between the halves', () {
    testWidgets('sits exactly between the two halves', (tester) async {
      await tester.pumpWidget(
        _host(
          SizedBox(
            width: 420,
            child: DateRangePicker(
              value: DateRange(DateTime(2026, 3, 4), DateTime(2026, 3, 9)),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final arrow = tester.getRect(
        find.byWidgetPredicate(
          (w) => w is CustomPaint && w.painter is RangeArrowPainter,
        ),
      );
      final start = tester.getRect(find.text('2026-03-04'));
      final end = tester.getRect(find.text('2026-03-09'));

      // The same gap on each side. The halves are one width, which is what
      // puts the mark between them rather than nearer one date.
      expect(start.width, end.width);
      expect(
        arrow.left - start.right,
        moreOrLessEquals(end.left - arrow.right, epsilon: 0.5),
      );
      expect(
        arrow.center.dx,
        moreOrLessEquals((start.left + end.right) / 2, epsilon: 0.5),
      );
    });

    testWidgets('each date is centred in its half', (tester) async {
      // Told a width, the halves are wider than the dates in them. Pushed to
      // the start, the left date sits away from the mark and the right one
      // against it, and the mark stops reading as between them — so the
      // measurement above would still hold and the field would still look
      // wrong. This is the part the eye sees.
      await tester.pumpWidget(
        _host(
          SizedBox(
            width: 500,
            child: DateRangePicker(
              value: DateRange(DateTime(2026, 3, 4), DateTime(2026, 3, 9)),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final halves = tester.widgetList<Text>(
        find.descendant(
          of: find.byType(DateRangePicker),
          matching: find.byType(Text),
        ),
      );
      expect(halves, hasLength(2));
      for (final half in halves) {
        expect(half.textAlign, TextAlign.center);
      }
    });
  });
}

void _bandTests() {
  group('the band across a range', () {
    /// Opens the panel and takes a range inside one month.
    Future<void> takeRange(WidgetTester tester) async {
      await _openPanel(tester);
      await tester.tap(find.text('10').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('17').first);
      await tester.pumpAndSettle();
      await _openPanel(tester);
    }

    testWidgets('leaves a line of air between the weeks', (tester) async {
      await tester.pumpWidget(_host(const DateRangePicker()));
      await takeRange(tester);

      Rect bandUnder(String day) => tester.getRect(
            find
                .ancestor(
                  of: find.text(day).first,
                  matching: find.byType(DecoratedBox),
                )
                .first,
          );

      // Two days a week apart, so the same column of the grid. The band under
      // one has to stop before the band under the other begins, or six weeks
      // read as one grey block instead of six.
      final upper = bandUnder('10');
      final lower = bandUnder('17');
      expect(lower.top, greaterThan(upper.bottom));
    });

    testWidgets('a day inside the band does not flash grey under the pointer',
        (tester) async {
      await tester.pumpWidget(_host(const DateRangePicker()));
      await takeRange(tester);

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      // A day in the middle of the range.
      await gesture.moveTo(tester.getCenter(find.text('14').first));
      await tester.pumpAndSettle();

      final pill = tester.widget<AnimatedContainer>(
        find
            .ancestor(
              of: find.text('14').first,
              matching: find.byType(AnimatedContainer),
            )
            .first,
      );
      final colour = (pill.decoration! as BoxDecoration).color!;
      // Grey over the band is a flash of the wrong colour every time the
      // pointer crosses a day. The hover belongs to the same family as the
      // band under it.
      expect(colour.b, greaterThan(colour.r));
    });
  });
}

void _narrowTests() {
  group('on a narrow screen', () {
    /// A phone-shaped window for the length of one test.
    void phone(WidgetTester tester) {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
    }

    testWidgets('the second month goes under the first, not off the side',
        (tester) async {
      phone(tester);
      await tester.pumpWidget(_host(const DateRangePicker()));
      await _openPanel(tester);

      final grids = find.byType(DayGrid);
      expect(grids, findsNWidgets(2), reason: 'both months are drawn');
      final first = tester.getRect(grids.at(0));
      final second = tester.getRect(grids.at(1));

      // Under, not beside. A month that does not fit is a month nobody can
      // see: the panel is as wide as it is drawn, so there is nothing to
      // scroll sideways to.
      expect(second.top, greaterThan(first.bottom));
      expect(second.left, first.left);
    });

    testWidgets('the panel keeps inside the window', (tester) async {
      phone(tester);
      await tester.pumpWidget(_host(const DateRangePicker()));
      await _openPanel(tester);
      expect(tester.takeException(), isNull);

      final panel = tester.getRect(find.byType(DayGrid).first);
      expect(panel.right, lessThanOrEqualTo(390));
    });

    testWidgets('side by side again when there is room', (tester) async {
      await tester.pumpWidget(_host(const DateRangePicker()));
      await _openPanel(tester);
      final grids = find.byType(DayGrid);
      final first = tester.getRect(grids.at(0));
      final second = tester.getRect(grids.at(1));
      expect(second.left, greaterThan(first.right));
      expect(second.top, first.top);
    });

    testWidgets('the rail lies along the top rather than down the side',
        (tester) async {
      phone(tester);
      await tester.pumpWidget(
        _host(
          DateRangePicker(
            presets: [
              DateRangePreset(
                'That week',
                DateRange(DateTime(2026, 3, 2), DateTime(2026, 3, 8)),
              ),
            ],
          ),
        ),
      );
      await _openPanel(tester);

      // Beside the calendar it would take back the room the stacking just
      // found.
      final preset = tester.getRect(find.text('That week'));
      final grid = tester.getRect(find.byType(DayGrid).first);
      expect(preset.bottom, lessThanOrEqualTo(grid.top));
    });
  });
}

void _litTests() {
  group('the half the panel is waiting on', () {
    testWidgets('keeps room between the tint and the words', (tester) async {
      await tester.pumpWidget(_host(const DateRangePicker()));
      await _openPanel(tester);

      // The leading half is lit while it is the one being filled in.
      final words = find.text('Start date');
      expect(words, findsOneWidget);
      final tint = tester.getRect(
        find.ancestor(of: words, matching: find.byType(DecoratedBox)).first,
      );
      final text = tester.getRect(words);

      // Drawn hard against the letters, the mark reads as a box too small for
      // what is in it rather than as the half being pointed at.
      expect(text.left - tint.left, greaterThan(0));
      expect(tint.right - text.right, greaterThan(0));
      expect(text.top - tint.top, greaterThan(0));
      expect(tint.bottom - text.bottom, greaterThan(0));
    });

    testWidgets('the words are not squeezed into an ellipsis by the room',
        (tester) async {
      await tester.pumpWidget(_host(const DateRangePicker()));
      await _openPanel(tester);
      // Offered no width of its own, the field asks for what the words need
      // and the room around them — not for the words alone.
      final text = tester.renderObject<RenderBox>(find.text('Start date'));
      expect(text.size.width, greaterThan(0));
      expect(tester.takeException(), isNull);
    });
  });
}
