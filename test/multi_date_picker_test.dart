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
  _tagDrawingTests();
  _widthTests();
  _responsiveTests();
  _responsiveWidthTests();
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
      // Worded as a `Select` holding more than it shows words it.
      expect(find.text('+ 3 ...'), findsOneWidget);
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

void _tagDrawingTests() {
  group('tags drawn by the caller', () {
    testWidgets('a builder is handed the day, its label and the default tag',
        (tester) async {
      final now = DateTime.now();
      final seen = <DateTag>[];
      List<DateTime>? held;
      await tester.pumpWidget(
        _host(
          MultiDatePicker(
            defaultValues: [
              DateTime(now.year, now.month, 4),
              DateTime(now.year, now.month, 9),
            ],
            onChanged: (v) => held = v,
            tagBuilder: (context, tag, child) {
              seen.add(tag);
              return tag.date.day == 4
                  ? GestureDetector(
                      onTap: tag.onRemove,
                      child: Text('mine ${tag.label}'),
                    )
                  : child;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(seen, hasLength(2));
      // The label is the picker's own writing, so a tag drawn by hand reads
      // like the ones beside it.
      expect(seen.first.label, contains('-04'));
      expect(seen.first.enabled, isTrue);

      // One replaced, one left as the picker drew it.
      expect(find.textContaining('mine '), findsOneWidget);
      expect(find.byType(ValueTag), findsOneWidget);

      // And a tag drawn by hand can still take its day out.
      await tester.tap(find.textContaining('mine '));
      await tester.pumpAndSettle();
      expect(held, hasLength(1));
    });

    testWidgets('a barred field offers no way to remove', (tester) async {
      final now = DateTime.now();
      final seen = <DateTag>[];
      await tester.pumpWidget(
        _host(
          MultiDatePicker(
            disabled: true,
            defaultValues: [DateTime(now.year, now.month, 4)],
            tagBuilder: (context, tag, child) {
              seen.add(tag);
              return child;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      // A tag nobody may remove should not offer to be removed.
      expect(seen.single.onRemove, isNull);
      expect(seen.single.enabled, isFalse);
    });

    testWidgets('removeIcon replaces the mark and not the target',
        (tester) async {
      final now = DateTime.now();
      List<DateTime>? held;
      await tester.pumpWidget(
        _host(
          MultiDatePicker(
            defaultValues: [DateTime(now.year, now.month, 4)],
            onChanged: (v) => held = v,
            removeIcon: const Text('✕', key: ValueKey('mark')),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('mark')), findsOneWidget);

      // Still in the same place, and still removes the day: a picture cannot
      // be swapped in for something that does nothing.
      await tester.tap(find.byKey(const ValueKey('mark')));
      await tester.pumpAndSettle();
      expect(held, isEmpty);
    });
  });
}

void _widthTests() {
  group('how wide the field runs', () {
    // A key per case: pumped twice in one test, the same picker keeps the
    // state it was built with, and `defaultValues` would be the first call's.
    var run = 0;
    Future<Size> sized(WidgetTester tester, Widget picker,
        {double room = 800}) async {
      await tester.pumpWidget(
        _host(
          SizedBox(
            width: room,
            child:
                Align(child: KeyedSubtree(key: ValueKey(run++), child: picker)),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return tester.getSize(find.byType(MultiDatePicker));
    }

    testWidgets('a field holding nothing is as wide as its placeholder',
        (tester) async {
      final short = await sized(
        tester,
        const MultiDatePicker(placeholder: 'Days'),
      );
      final long = await sized(
        tester,
        const MultiDatePicker(placeholder: 'Pick the days you are working'),
      );

      // Taken, not given: a field left to itself used to fill the page
      // whatever it was holding.
      expect(short.width, lessThan(400));
      expect(long.width, greaterThan(short.width));
    });

    testWidgets('it grows with the days it holds', (tester) async {
      final now = DateTime.now();
      final one = await sized(
        tester,
        MultiDatePicker(defaultValues: [DateTime(now.year, now.month, 4)]),
      );
      final three = await sized(
        tester,
        MultiDatePicker(
          defaultValues: [
            for (var d = 4; d <= 6; d++) DateTime(now.year, now.month, d),
          ],
        ),
      );
      expect(three.width, greaterThan(one.width));
    });

    testWidgets('offered less, the tags wrap rather than the field spilling',
        (tester) async {
      final now = DateTime.now();
      final roomy = await sized(
        tester,
        MultiDatePicker(
          defaultValues: [
            for (var d = 4; d <= 9; d++) DateTime(now.year, now.month, d),
          ],
        ),
      );
      final tight = await sized(
        tester,
        MultiDatePicker(
          defaultValues: [
            for (var d = 4; d <= 9; d++) DateTime(now.year, now.month, d),
          ],
        ),
        room: 260,
      );

      expect(tester.takeException(), isNull, reason: 'nothing overflowed');
      expect(tight.width, lessThanOrEqualTo(260));
      // The height is where the tags went.
      expect(tight.height, greaterThan(roomy.height));
    });

    testWidgets('told a width, it fills it', (tester) async {
      final told = await sized(
        tester,
        const SizedBox(
          width: 420,
          child: MultiDatePicker(placeholder: 'Days'),
        ),
      );
      expect(told.width, 420);
    });
  });
}

void _responsiveTests() {
  group('tags kept to one line', () {
    Widget picker(int days, {required double width}) {
      final now = DateTime.now();
      return SizedBox(
        width: width,
        child: MultiDatePicker(
          maxTagCountResponsive: true,
          defaultValues: [
            for (var d = 1; d <= days; d++) DateTime(now.year, now.month, d),
          ],
        ),
      );
    }

    testWidgets('what fits is named and the rest is counted', (tester) async {
      await tester.pumpWidget(_host(picker(8, width: 300)));
      await tester.pumpAndSettle();

      // Worked out from the room the field has, not from a number decided in
      // advance.
      final counted = find.textContaining('...');
      expect(counted, findsOneWidget);
      final said = tester.widget<Text>(counted).data!;
      final hidden = int.parse(RegExp(r'\d+').firstMatch(said)!.group(0)!);
      expect(hidden, greaterThan(0));
      expect(hidden, lessThan(8));
    });

    testWidgets('a wider field names more of them', (tester) async {
      Future<int> hiddenIn(double width) async {
        await tester.pumpWidget(
          _host(KeyedSubtree(
              key: ValueKey(width), child: picker(8, width: width))),
        );
        await tester.pumpAndSettle();
        final counted = find.textContaining('...');
        if (counted.evaluate().isEmpty) return 0;
        final said = tester.widget<Text>(counted).data!;
        return int.parse(RegExp(r'\d+').firstMatch(said)!.group(0)!);
      }

      expect(await hiddenIn(560), lessThan(await hiddenIn(240)));
    });

    testWidgets('the field stays one line tall', (tester) async {
      await tester.pumpWidget(_host(picker(1, width: 300)));
      await tester.pumpAndSettle();
      final one = tester.getSize(find.byType(MultiDatePicker)).height;

      await tester.pumpWidget(
        _host(KeyedSubtree(
            key: const ValueKey('many'), child: picker(12, width: 300))),
      );
      await tester.pumpAndSettle();
      final many = tester.getSize(find.byType(MultiDatePicker)).height;

      // Nothing wraps, so nothing makes the field taller — which is the whole
      // point of keeping to one line.
      expect(many, one);
      expect(tester.takeException(), isNull);
    });

    testWidgets('wrapping is still the default', (tester) async {
      final now = DateTime.now();
      await tester.pumpWidget(
        _host(
          SizedBox(
            width: 300,
            child: MultiDatePicker(
              defaultValues: [
                for (var d = 1; d <= 12; d++) DateTime(now.year, now.month, d),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      // Every day named, and the field as tall as it needs to be.
      expect(find.textContaining('...'), findsNothing);
      expect(
        tester.getSize(find.byType(MultiDatePicker)).height,
        greaterThan(40),
      );
    });
  });
}

void _responsiveWidthTests() {
  group('one line, and no width to be told', () {
    Widget loose(Widget child) => _host(
          SizedBox(
            width: 700,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [child],
            ),
          ),
        );

    Widget picker(int days, {Key? key}) {
      final now = DateTime.now();
      return MultiDatePicker(
        key: key,
        maxTagCountResponsive: true,
        defaultValues: [
          for (var d = 1; d <= days; d++) DateTime(now.year, now.month, d),
        ],
      );
    }

    testWidgets('given no width it still takes only what it holds',
        (tester) async {
      await tester.pumpWidget(loose(picker(2)));
      await tester.pumpAndSettle();
      final two = tester.getSize(find.byType(MultiDatePicker)).width;

      await tester.pumpWidget(loose(picker(5, key: const ValueKey('five'))));
      await tester.pumpAndSettle();
      final five = tester.getSize(find.byType(MultiDatePicker)).width;

      // Claiming the width it was offered is what made a line under a loose
      // parent grow instead of collapsing: everything fitted, so nothing hid.
      expect(two, lessThan(700));
      expect(five, greaterThan(two));
      expect(five, lessThanOrEqualTo(700));
    });

    testWidgets('and hides what will not fit when the room runs out',
        (tester) async {
      final now = DateTime.now();
      await tester.pumpWidget(
        _host(
          SizedBox(
            width: 220,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                MultiDatePicker(
                  maxTagCountResponsive: true,
                  defaultValues: [
                    for (var d = 1; d <= 8; d++)
                      DateTime(now.year, now.month, d),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('...'), findsOneWidget);
      expect(
        tester.getSize(find.byType(MultiDatePicker)).width,
        lessThanOrEqualTo(220),
      );
    });
  });
}
