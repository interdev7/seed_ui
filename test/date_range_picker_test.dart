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
