import 'package:flutter/material.dart'
    hide Badge, ThemeData, Checkbox, Radio, RadioGroup, Switch, Tooltip, Drawer;
import 'package:flutter_test/flutter_test.dart';
import 'package:seed_ui/seed_ui.dart';

Widget _host(Widget child, TextDirection direction) => MaterialApp(
      home: Directionality(
        textDirection: direction,
        child: Scaffold(body: Center(child: child)),
      ),
    );

/// Every decorated box a widget draws, in tree order.
Iterable<BoxDecoration> _decorations(WidgetTester tester, Type of) => tester
    .widgetList<Container>(
      find.descendant(of: find.byType(of), matching: find.byType(Container)),
    )
    .map((c) => c.decoration)
    .whereType<BoxDecoration>();

void main() {
  group('a run of radio buttons', () {
    const options = [
      RadioOption(value: 'a', label: Text('A')),
      RadioOption(value: 'b', label: Text('B')),
      RadioOption(value: 'c', label: Text('C')),
    ];

    /// The corner radii of the run's buttons, resolved for [direction] and
    /// ordered as they appear on screen from left to right.
    Future<List<BorderRadius>> radii(
      WidgetTester tester,
      TextDirection direction,
    ) async {
      await tester.pumpWidget(
        _host(
          const RadioGroup<String>(
            value: 'a',
            options: options,
            optionType: RadioOptionType.button,
          ),
          direction,
        ),
      );
      final boxes = find.descendant(
        of: find.byType(RadioGroup<String>),
        matching: find.byType(Container),
      );
      // Sorted by where each box actually sits, so both directions are read
      // the same way: leftmost first, whatever the run's own order.
      final ordered = <(double, BorderRadius)>[];
      var i = 0;
      for (final d in _decorations(tester, RadioGroup<String>)) {
        final radius = d.borderRadius?.resolve(direction);
        if (radius != null) {
          ordered.add((tester.getTopLeft(boxes.at(i)).dx, radius));
        }
        i++;
      }
      ordered.sort((a, b) => a.$1.compareTo(b.$1));
      return ordered.map((e) => e.$2).toList();
    }

    testWidgets('is rounded at its ends and square where buttons meet', (
      tester,
    ) async {
      for (final direction in TextDirection.values) {
        final r = await radii(tester, direction);
        expect(r, isNotEmpty, reason: '$direction drew no buttons');

        // Leftmost: round on the left, square on the right — whichever way the
        // run reads, since this is measured by position on screen.
        expect(r.first.topLeft.x, greaterThan(0), reason: '$direction');
        expect(r.first.topRight, Radius.zero, reason: '$direction');

        // Rightmost, the mirror of it. The bug this guards was two rounded
        // edges meeting in the middle of the run and square ones at its ends.
        expect(r.last.topRight.x, greaterThan(0), reason: '$direction');
        expect(r.last.topLeft, Radius.zero, reason: '$direction');
      }
    });
  });

  group('a badge', () {
    /// Where the pill's centre sits, and where the corner it is pinned to is.
    Future<(Offset pill, Offset corner)> pinned(
      WidgetTester tester,
      int count,
      TextDirection direction,
    ) async {
      await tester.pumpWidget(
        _host(
          Badge(count: count, child: const SizedBox(width: 60, height: 60)),
          direction,
        ),
      );
      await tester.pumpAndSettle();
      final child = tester.getRect(find.byType(SizedBox).first);
      final pill = tester.getCenter(
        find
            .descendant(
                of: find.byType(Badge), matching: find.byType(Container))
            .first,
      );
      final corner = Offset(
        direction == TextDirection.rtl ? child.left : child.right,
        child.top,
      );
      return (pill, corner);
    }

    testWidgets('sits centred on the trailing corner, whichever side it is', (
      tester,
    ) async {
      for (final direction in TextDirection.values) {
        final (pill, corner) = await pinned(tester, 7, direction);
        // Half of it hangs off, which puts its centre exactly on the corner.
        // Anchoring to the trailing edge but always pushing the overhang
        // rightwards leaves it short of the corner, inside the child.
        expect(pill.dx, moreOrLessEquals(corner.dx, epsilon: 0.5),
            reason: '$direction');
        expect(pill.dy, moreOrLessEquals(corner.dy, epsilon: 0.5),
            reason: '$direction');
      }
    });

    testWidgets('a count is centred in its place, in any figures', (
      tester,
    ) async {
      // The reel measures the glyphs it will draw. Under the test font every
      // glyph is the same box, so this cannot tell Latin figures from
      // Arabic-Indic ones — it holds the structure, not the metrics, and the
      // Arabic case has to be looked at rather than asserted.
      await tester.pumpWidget(
        ConfigProvider(
          locale: SeedLocalizations.ar,
          child: _host(const Badge(count: 42), TextDirection.rtl),
        ),
      );
      await tester.pumpAndSettle();

      final four = tester.getRect(find.text('\u0664'));
      final two = tester.getRect(find.text('\u0662'));
      expect(four.width, two.width, reason: 'every place is the same cell');
      expect(four.height, two.height);
      expect(four.height, greaterThan(0), reason: 'nothing clipped away');
    });
  });

  group('a ribbon', () {
    Future<(Rect band, Rect child)> ribbon(
      WidgetTester tester,
      RibbonPlacement placement,
      TextDirection direction,
    ) async {
      await tester.pumpWidget(
        _host(
          SizedBox(
            width: 300,
            height: 120,
            child: Ribbon(
              placement: placement,
              text: const Text('Hot'),
              child: const SizedBox.expand(),
            ),
          ),
          direction,
        ),
      );
      return (
        tester.getRect(find.text('Hot')),
        tester.getRect(find.byType(Ribbon)),
      );
    }

    testWidgets('runs off the end it was given, whichever side that is', (
      tester,
    ) async {
      final ltrEnd =
          await ribbon(tester, RibbonPlacement.end, TextDirection.ltr);
      expect(ltrEnd.$1.center.dx, greaterThan(ltrEnd.$2.center.dx));

      // The trailing end of a right-to-left layout is its left.
      final rtlEnd =
          await ribbon(tester, RibbonPlacement.end, TextDirection.rtl);
      expect(rtlEnd.$1.center.dx, lessThan(rtlEnd.$2.center.dx));

      final rtlStart =
          await ribbon(tester, RibbonPlacement.start, TextDirection.rtl);
      expect(rtlStart.$1.center.dx, greaterThan(rtlStart.$2.center.dx));
    });

    testWidgets('the fold stays under the band it belongs to', (tester) async {
      for (final direction in TextDirection.values) {
        for (final placement in RibbonPlacement.values) {
          await ribbon(tester, placement, direction);
          final band = tester.getRect(find.text('Hot'));
          final fold = tester.getRect(
            find
                .descendant(
                  of: find.byType(Ribbon),
                  matching: find.byType(CustomPaint),
                )
                .last,
          );
          final why = '$placement in $direction';
          // Below the band, and on the same side of it — the fold is the band
          // turning the corner, not a second shape wandering off.
          expect(fold.top, greaterThanOrEqualTo(band.bottom - 1), reason: why);
          expect(
            (fold.center.dx - band.center.dx).abs(),
            lessThan(band.width),
            reason: why,
          );
        }
      }
    });
  });
}
