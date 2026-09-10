import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart' as m;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seed_ui/seed_ui.dart';
import 'package:seed_ui/src/components/data_entry/date_picker.dart'
    show DayGrid;
// The tag is the kit's own chrome rather than public surface.
import 'package:seed_ui/src/utils/value_tag.dart' show ValueTag;

// A six-week grid shows the days either side of the month too, so 1–12 and
// 20–31 can each appear twice. The days in the middle appear once, and those
// are the ones these tests press.
Widget _host(Widget child) => ConfigProvider(
      child: m.MaterialApp(
        navigatorKey: UiKit.navigatorKey,
        home: m.Scaffold(body: Center(child: child)),
      ),
    );

Future<void> _openPanel(WidgetTester tester) async {
  await tester.tap(find.byType(MultiDatePicker));
  await tester.pumpAndSettle();
}

void main() {
  _controlledTests();
  group('collecting several days', () {
    testWidgets('the panel stays open, so a second day is one more tap',
        (tester) async {
      List<DateTime>? held;
      await tester.pumpWidget(
        _host(MultiDatePicker(onChanged: (v) => held = v)),
      );
      await _openPanel(tester);

      await tester.tap(find.text('15'));
      await tester.pumpAndSettle();
      expect(find.byType(DayGrid), findsOneWidget, reason: 'still open');
      expect(held, hasLength(1));

      await tester.tap(find.text('18'));
      await tester.pumpAndSettle();
      expect(held, hasLength(2));
    });

    testWidgets('pressing a day already in takes it out', (tester) async {
      List<DateTime>? held;
      await tester.pumpWidget(
        _host(MultiDatePicker(onChanged: (v) => held = v)),
      );
      await _openPanel(tester);
      await tester.tap(find.text('15'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('15'));
      await tester.pumpAndSettle();
      expect(held, isEmpty);
    });

    testWidgets('the days come back in order, however they were pressed',
        (tester) async {
      List<DateTime>? held;
      await tester.pumpWidget(
        _host(MultiDatePicker(onChanged: (v) => held = v)),
      );
      await _openPanel(tester);
      for (final day in ['21', '14', '16']) {
        await tester.tap(find.text(day));
        await tester.pumpAndSettle();
      }
      // A run of dates is read in order; sorting on the way out would be
      // every caller's job otherwise.
      expect(held!.map((d) => d.day), [14, 16, 21]);
    });

    testWidgets('the same day twice over is held once', (tester) async {
      final now = DateTime.now();
      await tester.pumpWidget(
        _host(
          MultiDatePicker(
            defaultValues: [
              DateTime(now.year, now.month, 4),
              DateTime(now.year, now.month, 4, 14, 32),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      // The clock is dropped on the way in, so two of the same day are one.
      expect(find.byType(ValueTag), findsOneWidget);
    });
  });

  group('what the field shows', () {
    testWidgets('a tag for each day, each with a cross that removes it',
        (tester) async {
      List<DateTime>? held;
      final now = DateTime.now();
      await tester.pumpWidget(
        _host(
          MultiDatePicker(
            defaultValues: [
              DateTime(now.year, now.month, 4),
              DateTime(now.year, now.month, 9),
            ],
            onChanged: (v) => held = v,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(ValueTag), findsNWidgets(2));

      await tester.tap(
        find.descendant(
          of: find.byType(ValueTag).first,
          matching: find.byType(CustomPaint),
        ),
      );
      await tester.pumpAndSettle();
      expect(held, hasLength(1));
      expect(held!.single.day, 9);
    });

    testWidgets('maxTagCount names some and counts the rest', (tester) async {
      final now = DateTime.now();
      await tester.pumpWidget(
        _host(
          MultiDatePicker(
            maxTagCount: 2,
            defaultValues: [
              for (var d = 1; d <= 5; d++) DateTime(now.year, now.month, d),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(ValueTag), findsNWidgets(3));
      expect(find.text('+3'), findsOneWidget);
    });

    testWidgets('a picker holding nothing says so', (tester) async {
      await tester.pumpWidget(
        _host(const MultiDatePicker(placeholder: 'Pick your shifts')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Pick your shifts'), findsOneWidget);
      expect(find.byType(ValueTag), findsNothing);
    });
  });

  group('what it refuses', () {
    testWidgets('maxCount bars the rest once the list is full', (tester) async {
      List<DateTime>? held;
      await tester.pumpWidget(
        _host(MultiDatePicker(maxCount: 2, onChanged: (v) => held = v)),
      );
      await _openPanel(tester);
      await tester.tap(find.text('15'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('16'));
      await tester.pumpAndSettle();

      // Barred rather than silently refusing: a limit nobody can see reads
      // as a bug.
      await tester.tap(find.text('17'));
      await tester.pumpAndSettle();
      expect(held, hasLength(2));

      // And one already in can still be taken out.
      await tester.tap(find.text('16'));
      await tester.pumpAndSettle();
      expect(held, hasLength(1));
    });

    testWidgets('a blocked day is not taken', (tester) async {
      List<DateTime>? held;
      final now = DateTime.now();
      await tester.pumpWidget(
        _host(
          MultiDatePicker(
            minDate: DateTime(now.year, now.month, 15),
            onChanged: (v) => held = v,
          ),
        ),
      );
      await _openPanel(tester);
      await tester.tap(find.text('13'));
      await tester.pumpAndSettle();
      expect(held, isNull);
    });
  });

  group('clearing', () {
    testWidgets('the mark drops the lot', (tester) async {
      final now = DateTime.now();
      List<DateTime>? held;
      await tester.pumpWidget(
        _host(
          MultiDatePicker(
            defaultValues: [
              DateTime(now.year, now.month, 4),
              DateTime(now.year, now.month, 9),
            ],
            onChanged: (v) => held = v,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      await gesture.moveTo(tester.getCenter(find.byType(MultiDatePicker)));
      await tester.pumpAndSettle();

      await tester.tapAt(
        tester.getCenter(
          find.byWidgetPredicate(
            (w) =>
                w is CustomPaint &&
                w.painter.runtimeType.toString() == 'ClearIconPainter',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(held, isEmpty);
    });
  });
}

void _controlledTests() {
  group('driven from outside', () {
    /// The fill behind a day in the panel, so a mark can be told from none.
    Color? fillUnder(WidgetTester tester, String day) {
      final box = tester.widget<AnimatedContainer>(
        find
            .ancestor(
              of: find.text(day),
              matching: find.byType(AnimatedContainer),
            )
            .first,
      );
      return (box.decoration! as BoxDecoration).color;
    }

    testWidgets('the panel marks the day on the tap that took it',
        (tester) async {
      // The panel lives in the overlay and is redrawn on its own. Redrawn
      // during the tap, it reads a `values` the owner has been handed but
      // not yet rebuilt with — so it marked the list as it stood one tap
      // ago, and pressing the second day lit the first.
      var held = <DateTime>[];
      await tester.pumpWidget(
        _host(
          StatefulBuilder(
            builder: (context, setState) => MultiDatePicker(
              values: held,
              onChanged: (v) => setState(() => held = v),
            ),
          ),
        ),
      );
      await _openPanel(tester);

      final plain = fillUnder(tester, '19');
      await tester.tap(find.text('15'));
      await tester.pumpAndSettle();
      expect(held, hasLength(1));
      expect(fillUnder(tester, '15'), isNot(plain), reason: 'marked at once');

      await tester.tap(find.text('16'));
      await tester.pumpAndSettle();
      expect(held, hasLength(2));
      expect(fillUnder(tester, '15'), isNot(plain));
      expect(fillUnder(tester, '16'), isNot(plain));
    });

    testWidgets('an owner that refuses the change is shown refusing it',
        (tester) async {
      // The other half of handing the value over: the panel shows what the
      // owner settled on, not what the tap asked for.
      await tester.pumpWidget(
        _host(
          MultiDatePicker(values: const [], onChanged: (_) {}),
        ),
      );
      await _openPanel(tester);
      final plain = fillUnder(tester, '19');
      await tester.tap(find.text('15'));
      await tester.pumpAndSettle();
      expect(fillUnder(tester, '15'), plain);
    });
  });
}
