import 'package:flutter/material.dart'
    hide Badge, ThemeData, Checkbox, Radio, RadioGroup, Switch, Tooltip, Drawer;
import 'package:flutter/rendering.dart' show RenderParagraph;
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

/// The tabs actually inside the bar's viewport, each with how far its leading
/// edge sits from the bar's own. A snapped bar has one of them at zero.
///
/// Filtered to what is on screen: a scroll view builds all its children, so
/// the finder reaches tabs far outside the viewport too.
List<(String label, double edge)> _visibleTabs(
  WidgetTester tester,
  TextDirection direction,
) {
  final bar = tester.getRect(find.byType(SingleChildScrollView).first);
  final out = <(String, double)>[];
  for (var i = 1; i <= 14; i++) {
    final label = 'Section $i';
    final finder = find.text(label);
    if (!tester.any(finder)) continue;
    final tab = tester.getRect(finder);
    // Wholly inside, not merely overlapping: a tab straddling the edge has
    // its centre outside the bar, and a tap aimed there misses.
    if (tab.left < bar.left - 0.5 || tab.right > bar.right + 0.5) continue;
    out.add((
      label,
      direction == TextDirection.ltr
          ? tab.left - bar.left
          : bar.right - tab.right,
    ));
  }
  return out;
}

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
  group('a pagination', () {
    testWidgets('a run of pages too wide for its room scrolls, not overflows', (
      tester,
    ) async {
      // Wide figures and a narrow box: the case that used to paint the debug
      // stripes and hide the pages past the edge.
      await tester.pumpWidget(
        ConfigProvider(
          locale: SeedLocalizations.ar,
          child: _host(
            const SizedBox(
              width: 200,
              child: Pagination(
                total: 500,
                pageSize: 10,
                current: 5,
                showSizeChanger: true,
              ),
            ),
            TextDirection.rtl,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(
        find.descendant(
          of: find.byType(Pagination),
          matching: find.byType(SingleChildScrollView),
        ),
        findsWidgets,
      );
    });
  });
  group('a select', () {
    /// How far the content sits from each edge of the box.
    Future<(double leading, double trailing)> insets(
      TextDirection direction,
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const SizedBox(
            width: 240,
            child: Select<String>(
              value: ['a'],
              options: [SelectOption(value: 'a', label: Text('Alpha'))],
            ),
          ),
          direction,
        ),
      );
      await tester.pumpAndSettle();
      final box = tester.getRect(find.byType(Select<String>));
      final label = tester.getRect(find.text('Alpha'));
      return direction == TextDirection.ltr
          ? (label.left - box.left, box.right - label.right)
          : (box.right - label.right, label.left - box.left);
    }

    testWidgets('gives the label its inset and the arrow the narrower one', (
      tester,
    ) async {
      final ltr = await insets(TextDirection.ltr, tester);
      final rtl = await insets(TextDirection.rtl, tester);
      // Measured from the reading edges, the two directions must agree. A
      // physical pair of paddings swaps them over instead.
      expect(rtl.$1, moreOrLessEquals(ltr.$1, epsilon: 0.5));
      expect(rtl.$2, moreOrLessEquals(ltr.$2, epsilon: 0.5));
    });
  });

  group('an input', () {
    /// How far the placeholder sits from the field's leading edge.
    Future<double> placeholderInset(
      WidgetTester tester,
      TextDirection direction, {
      TextAlign align = TextAlign.start,
    }) async {
      await tester.pumpWidget(
        _host(
          SizedBox(
            width: 300,
            child: Input(placeholder: 'Type here', textAlign: align),
          ),
          direction,
        ),
      );
      await tester.pumpAndSettle();
      final field = tester.getRect(find.byType(Input));
      final hint = tester.getRect(find.text('Type here'));
      return direction == TextDirection.ltr
          ? hint.left - field.left
          : field.right - hint.right;
    }

    testWidgets('starts its placeholder where the typing will start', (
      tester,
    ) async {
      // Measured from each direction's leading edge, the two must agree. The
      // typed text follows TextAlign.start on its own; the placeholder is
      // drawn separately and was pinned to the left whatever the direction.
      final ltr = await placeholderInset(tester, TextDirection.ltr);
      final rtl = await placeholderInset(tester, TextDirection.rtl);
      expect(rtl, moreOrLessEquals(ltr, epsilon: 1));
    });

    testWidgets('a placeholder asked for by side stays on that side', (
      tester,
    ) async {
      // left and right name a side outright, so they do not mirror.
      Future<double> leftInset(TextDirection direction) async {
        await tester.pumpWidget(
          _host(
            const SizedBox(
              width: 300,
              child: Input(placeholder: 'Type here', textAlign: TextAlign.left),
            ),
            direction,
          ),
        );
        await tester.pumpAndSettle();
        return tester.getRect(find.text('Type here')).left -
            tester.getRect(find.byType(Input)).left;
      }

      expect(
        await leftInset(TextDirection.rtl),
        moreOrLessEquals(await leftInset(TextDirection.ltr), epsilon: 1),
      );
    });

    testWidgets('puts its attached button after the field, in reading order', (
      tester,
    ) async {
      for (final direction in TextDirection.values) {
        await tester.pumpWidget(
          _host(
            const SizedBox(
              width: 280,
              child: Input(
                search: SearchConfig(enterButtonLabel: Text('Go')),
              ),
            ),
            direction,
          ),
        );
        await tester.pumpAndSettle();

        final field = tester.getRect(find.byType(EditableText));
        final button = tester.getRect(find.text('Go'));
        final why = '$direction';
        // The button follows the field as the language reads, so it is to the
        // right of it one way round and to the left the other.
        if (direction == TextDirection.ltr) {
          expect(button.center.dx, greaterThan(field.center.dx), reason: why);
        } else {
          expect(button.center.dx, lessThan(field.center.dx), reason: why);
        }
      }
    });
  });
  group('a bar of tabs', () {
    List<TabItem> run() => [
          for (var i = 1; i <= 14; i++)
            TabItem(key: '$i', label: Text('Section $i'), content: Text('P$i')),
        ];

    /// Scrolls into the middle of the run, taps the tab furthest from the
    /// leading edge, and reports where that tab ended up.
    Future<double> tapFarTab(
      WidgetTester tester,
      TextDirection direction,
    ) async {
      await tester.pumpWidget(
        _host(
          SizedBox(width: 320, child: Tabs(items: run())),
          direction,
        ),
      );
      await tester.pumpAndSettle();

      // Far enough in that the tapped tab has somewhere to travel: a tab
      // already near the edge lands on zero whatever the arithmetic, which is
      // how a mirrored offset can pass unnoticed.
      await tester.fling(
        find.byType(SingleChildScrollView).first,
        Offset(direction == TextDirection.ltr ? -400 : 400, 0),
        1200,
      );
      await tester.pumpAndSettle();

      final visible = _visibleTabs(tester, direction);
      var furthest = visible.first;
      for (final tab in visible) {
        if (tab.$2 > furthest.$2) furthest = tab;
      }
      final target = furthest.$1;
      expect(furthest.$2, greaterThan(40), reason: 'it has room to move');

      await tester.tap(find.text(target));
      await tester.pumpAndSettle();

      final bar = tester.getRect(find.byType(SingleChildScrollView).first);
      final tab = tester.getRect(find.text(target));
      return direction == TextDirection.ltr
          ? tab.left - bar.left
          : bar.right - tab.right;
    }

    testWidgets('brings the tapped tab to the edge the bar starts at', (
      tester,
    ) async {
      // Measured from each direction's own leading edge, the two must agree.
      // Treating the scroll offset as a distance from the left sent every
      // scroll to the mirror image of where it belonged.
      expect(
        await tapFarTab(tester, TextDirection.ltr),
        moreOrLessEquals(0, epsilon: 1),
      );
      expect(
        await tapFarTab(tester, TextDirection.rtl),
        moreOrLessEquals(0, epsilon: 1),
      );
    });

    testWidgets('and snapping settles on a tab either way round', (
      tester,
    ) async {
      for (final direction in TextDirection.values) {
        await tester.pumpWidget(
          _host(
            SizedBox(width: 320, child: Tabs(items: run(), snap: true)),
            direction,
          ),
        );
        await tester.pumpAndSettle();

        final bar = find.byType(SingleChildScrollView).first;
        await tester.fling(bar, const Offset(-300, 0), 2000);
        await tester.pumpAndSettle();

        final position =
            tester.widget<SingleChildScrollView>(bar).controller!.position;
        // Either against a tab, or against the end of the run — both are
        // places the bar is allowed to rest.
        final atEnd = (position.pixels - position.maxScrollExtent).abs() < 1 ||
            position.pixels < 1;
        final onATab = _visibleTabs(
          tester,
          direction,
        ).any((tab) => tab.$2.abs() < 1);
        expect(
          atEnd || onATab,
          isTrue,
          reason: '$direction rested at ${position.pixels}',
        );
      }
    });
  });
  group('a timeline', () {
    testWidgets('joins its horizontal items up, whichever way the run reads', (
      tester,
    ) async {
      /// The gap between neighbouring dots. A rail painted towards the wrong
      /// end leaves the run in pieces.
      Future<List<double>> dotGaps(TextDirection direction) async {
        await tester.pumpWidget(
          _host(
            const SizedBox(
              width: 500,
              child: Timeline(
                orientation: TimelineOrientation.horizontal,
                items: [
                  TimelineItem(content: Text('One')),
                  TimelineItem(content: Text('Two')),
                  TimelineItem(content: Text('Three')),
                ],
              ),
            ),
            direction,
          ),
        );
        await tester.pumpAndSettle();

        final centres = [
          for (final label in ['One', 'Two', 'Three'])
            tester.getRect(find.text(label)).center.dx,
        ]..sort();
        return [
          for (var i = 1; i < centres.length; i++) centres[i] - centres[i - 1],
        ];
      }

      final ltr = await dotGaps(TextDirection.ltr);
      final rtl = await dotGaps(TextDirection.rtl);
      // The run is the same run, laid out backwards: read left to right on
      // screen its gaps come in the opposite order, since each gap is set by
      // the pair of items it separates. Anything else means the items are no
      // longer spaced by their own widths.
      expect(rtl, hasLength(ltr.length));
      final mirrored = ltr.reversed.toList();
      for (var i = 0; i < mirrored.length; i++) {
        expect(
          rtl[i],
          moreOrLessEquals(mirrored[i], epsilon: 1),
          reason: 'gap $i',
        );
      }
    });

    testWidgets('runs its first item\'s thread towards the next one', (
      tester,
    ) async {
      /// The rail segments the first item paints, read off its painter.
      Future<List<RailSegment>> firstItemRail(TextDirection direction) async {
        await tester.pumpWidget(
          _host(
            const SizedBox(
              width: 500,
              child: Timeline(
                orientation: TimelineOrientation.horizontal,
                items: [
                  TimelineItem(content: Text('One')),
                  TimelineItem(content: Text('Two')),
                  TimelineItem(content: Text('Three')),
                ],
              ),
            ),
            direction,
          ),
        );
        await tester.pumpAndSettle();

        final painters = tester
            .widgetList<CustomPaint>(
              find.descendant(
                of: find.byType(Timeline),
                matching: find.byType(CustomPaint),
              ),
            )
            .map((c) => c.painter)
            .whereType<RailPainter>()
            .toList();
        expect(painters, isNotEmpty, reason: 'the rail is painted');
        return painters.first.segments;
      }

      // The first item has no thread behind it and one ahead. Which side
      // "ahead" is depends on the way the row reads, and painting it always
      // rightwards sent the first item's thread off the outer edge, leaving
      // the run in pieces.
      final ltr = await firstItemRail(TextDirection.ltr);
      expect(ltr, hasLength(1));
      expect(ltr.single.end, double.infinity, reason: 'ahead is rightwards');

      final rtl = await firstItemRail(TextDirection.rtl);
      expect(rtl, hasLength(1));
      expect(rtl.single.start, 0, reason: 'ahead is leftwards');
      expect(rtl.single.end, isNot(double.infinity));
    });

    testWidgets('reads its text towards the axis, not away from it', (
      tester,
    ) async {
      // Two lines of different lengths in the column that stands before the
      // axis: the short one must line up with the long one on the side facing
      // the line, not on the far side.
      for (final direction in TextDirection.values) {
        await tester.pumpWidget(
          _host(
            const SizedBox(
              width: 420,
              child: Timeline(
                mode: TimelineMode.right,
                items: [
                  TimelineItem(
                    title: Text('A considerably longer title'),
                    description: Text('short'),
                  ),
                ],
              ),
            ),
            direction,
          ),
        );
        await tester.pumpAndSettle();

        final axis = tester.getRect(find.byType(Timeline)).center.dx;
        final long = tester.getRect(find.text('A considerably longer title'));
        final short = tester.getRect(find.text('short'));

        // Whichever side of the line the column landed on, the two lines meet
        // on the edge nearest it.
        final near = (long.center.dx < axis)
            ? (long.right - short.right).abs()
            : (long.left - short.left).abs();
        expect(near, lessThan(1), reason: '$direction');
      }
    });

    testWidgets('keeps both columns the same distance from the axis', (
      tester,
    ) async {
      for (final direction in TextDirection.values) {
        await tester.pumpWidget(
          _host(
            const SizedBox(
              width: 400,
              child: Timeline(
                mode: TimelineMode.alternate,
                items: [
                  TimelineItem(title: Text('First')),
                  TimelineItem(title: Text('Second')),
                ],
              ),
            ),
            direction,
          ),
        );
        await tester.pumpAndSettle();

        final axis = tester.getRect(find.byType(Timeline)).center.dx;
        final first = tester.getRect(find.text('First'));
        final second = tester.getRect(find.text('Second'));

        // Alternate puts one on each side of the line. Whichever side each
        // lands on, its inner edge should stand the same distance off.
        final gapFirst =
            (first.center.dx < axis) ? axis - first.right : first.left - axis;
        final gapSecond = (second.center.dx < axis)
            ? axis - second.right
            : second.left - axis;

        expect(
          gapFirst,
          moreOrLessEquals(gapSecond, epsilon: 1),
          reason: '$direction: $gapFirst vs $gapSecond',
        );
      }
    });
  });
  group('a timeline item', () {
    testWidgets('title and description read towards the axis alike', (
      tester,
    ) async {
      for (final direction in TextDirection.values) {
        await tester.pumpWidget(
          _host(
            const SizedBox(
              width: 500,
              child: Timeline(
                mode: TimelineMode.alternate,
                items: [
                  TimelineItem(
                    title: Text('Planning'),
                    // Long enough to fill its column and wrap, which is the
                    // case a box alignment cannot place: only the paragraph's
                    // own alignment decides where those lines sit.
                    description: Text('Scope, budget and team setup'),
                  ),
                ],
              ),
            ),
            direction,
          ),
        );
        await tester.pumpAndSettle();

        // The resolved alignment, not the box: a short title's box is put
        // against the axis by the column whatever its lines do, so measuring
        // rectangles cannot tell the two apart.
        TextAlign alignOf(String text) =>
            tester.renderObject<RenderParagraph>(find.text(text)).textAlign;

        final why = '$direction';
        expect(
          alignOf('Scope, budget and team setup'),
          alignOf('Planning'),
          reason: '$why: the block must read one way, not two',
        );
        // And that way is towards the axis. This item sits before it.
        expect(alignOf('Planning'), TextAlign.end, reason: why);
      }
    });
  });
}
