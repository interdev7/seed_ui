import 'dart:ui' show ImageByteFormat;

import 'package:flutter/material.dart'
    hide Badge, ThemeData, Checkbox, Radio, RadioGroup, Switch, Tooltip, Drawer;
import 'package:flutter/rendering.dart'
    show RenderParagraph, RenderRepaintBoundary;
import 'package:flutter_localizations/flutter_localizations.dart';
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
  group('a tour panel', () {
    /// The direction comes from the app's locale, not from a Directionality
    /// wrapped round it: MaterialApp installs its own from the localizations,
    /// and without the global delegates that is always left to right. It is
    /// also the only way to reach the panel, which draws into the navigator's
    /// overlay — above anything placed inside `home`.
    Widget tour(TextDirection direction, GlobalKey target) => MaterialApp(
          locale: Locale(direction == TextDirection.rtl ? 'ar' : 'en'),
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en'), Locale('ar')],
          home: Scaffold(
            body: Stack(
              children: [
                Positioned(
                  left: 60,
                  top: 200,
                  child: SizedBox(key: target, width: 120, height: 40),
                ),
                Positioned(
                  left: 0,
                  top: 0,
                  child: Tour(
                    open: true,
                    steps: [
                      TourStep(
                        target: target,
                        title: const Text('A step with a fairly long title'),
                        description: const Text('And a description under it.'),
                      ),
                      TourStep(target: target, title: const Text('Second')),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );

    testWidgets('closes from the trailing corner, clear of the title', (
      tester,
    ) async {
      for (final direction in TextDirection.values) {
        final target = GlobalKey();
        await tester.pumpWidget(tour(direction, target));
        await tester.pumpAndSettle();

        final close = tester.getRect(find.byKey(const Key('softTourClose')));
        final title = tester.getRect(
          find.text('A step with a fairly long title'),
        );
        final why = '$direction';

        // The cross sits in the panel's trailing corner, and the title stops
        // short of it rather than running underneath.
        if (direction == TextDirection.ltr) {
          expect(close.left, greaterThan(title.right - 1), reason: why);
        } else {
          expect(close.right, lessThan(title.left + 1), reason: why);
        }
      }
    });
  });
  group('a progress bar', () {
    /// The filled part of the bar, and the percent beside it, measured from
    /// each direction's own leading edge.
    Future<(double fillFromLeading, double textFromTrailing)> measure(
      WidgetTester tester,
      Widget bar,
      TextDirection direction,
    ) async {
      await tester.pumpWidget(
        _host(SizedBox(width: 400, child: bar), direction),
      );
      await tester.pumpAndSettle();

      final box = tester.getRect(find.byType(Progress));
      var fill = double.infinity;
      for (final element in find.byType(DecoratedBox).evaluate()) {
        final r = tester.getRect(find.byWidget(element.widget));
        if (r.width <= 1) continue;
        final edge = direction == TextDirection.ltr
            ? r.left - box.left
            : box.right - r.right;
        if (edge < fill) fill = edge;
      }
      final text = tester.getRect(find.textContaining('%').first);
      return (
        fill,
        direction == TextDirection.ltr
            ? box.right - text.right
            : text.left - box.left,
      );
    }

    testWidgets('fills from the leading edge, either way round', (
      tester,
    ) async {
      for (final bar in <Widget>[
        const Progress(percent: 0.3),
        const Progress(percent: 0.4, steps: ProgressSteps(5)),
      ]) {
        final ltr = await measure(tester, bar, TextDirection.ltr);
        final rtl = await measure(tester, bar, TextDirection.rtl);
        // Read from each direction's own leading edge the two must agree: the
        // bar grows away from where the reading starts, and the percent
        // follows it on the far side.
        expect(rtl.$1, moreOrLessEquals(ltr.$1, epsilon: 1));
        expect(rtl.$2, moreOrLessEquals(ltr.$2, epsilon: 1));
      }
    });

    testWidgets('a circle is deliberately not mirrored', (tester) async {
      Future<Rect> circle(TextDirection direction) async {
        await tester.pumpWidget(
          _host(
            const SizedBox(
              width: 200,
              child: Progress(percent: 0.3, type: ProgressType.circle),
            ),
            direction,
          ),
        );
        await tester.pumpAndSettle();
        return tester.getRect(find.textContaining('%').first);
      }

      // Ant Design mirrors the line and the text that follows it, and leaves
      // the arc alone: it starts at the top and runs clockwise in either
      // language. Nothing here should move.
      expect(await circle(TextDirection.rtl), await circle(TextDirection.ltr));
    });
  });
  group('a progress radius', () {
    test('named by side, it is that side whichever way the bar reads', () {
      const bySide = ProgressBorderRadius.horizontal(left: 8);
      for (final direction in TextDirection.values) {
        final r = bySide.toBorderRadius(direction);
        expect(r.topLeft.x, 8, reason: '$direction');
        expect(r.topRight.x, 0, reason: '$direction');
      }
    });

    test('named by reading order, it follows the reading order', () {
      const leading = ProgressBorderRadius.horizontalDirectional(start: 8);

      final ltr = leading.toBorderRadius(TextDirection.ltr);
      expect(ltr.topLeft.x, 8);
      expect(ltr.topRight.x, 0);

      // The bar grows the other way, so its leading corners are the right
      // ones. This is what `isFirst` in a stepRadius callback means, and a
      // radius named by side cannot say it.
      final rtl = leading.toBorderRadius(TextDirection.rtl);
      expect(rtl.topRight.x, 8);
      expect(rtl.topLeft.x, 0);
    });

    test('two radii that name the corners differently are not equal', () {
      expect(
        const ProgressBorderRadius.horizontal(left: 8),
        isNot(const ProgressBorderRadius.horizontalDirectional(start: 8)),
      );
    });

    testWidgets('a step run rounds the end it starts from', (tester) async {
      Future<BorderRadius> firstStep(TextDirection direction) async {
        await tester.pumpWidget(
          _host(
            SizedBox(
              width: 320,
              child: Progress(
                percent: 1,
                strokeWidth: 16,
                steps: ProgressSteps(
                  4,
                  gap: 6,
                  stepRadius: (isFirst, percent) => isFirst == true
                      ? const ProgressBorderRadius.horizontalDirectional(
                          start: 8,
                        )
                      : ProgressBorderRadius.zero,
                ),
              ),
            ),
            direction,
          ),
        );
        await tester.pumpAndSettle();

        final box = tester.getRect(find.byType(Progress));
        // The step nearest the edge the run starts from.
        // Each segment is clipped to its own corners, so the clip is where
        // the radius actually lands.
        BorderRadius? nearest;
        var best = double.infinity;
        for (final element in find.byType(ClipRRect).evaluate()) {
          final radius = (element.widget as ClipRRect).borderRadius;
          if (radius is! BorderRadius) continue;
          final r = tester.getRect(find.byWidget(element.widget));
          if (r.width <= 1) continue;
          final edge = direction == TextDirection.ltr
              ? r.left - box.left
              : box.right - r.right;
          if (edge < best) {
            best = edge;
            nearest = radius;
          }
        }
        return nearest!;
      }

      expect((await firstStep(TextDirection.ltr)).topLeft.x, 8);
      expect((await firstStep(TextDirection.rtl)).topRight.x, 8);
    });
  });
  group('a run of panels', () {
    testWidgets('points the way the run reads', (tester) async {
      /// The colour on the strip's centre line, a little either side of the
      /// middle, read from the painted pixels — the shape is drawn, not laid
      /// out, so nothing else can see it.
      Future<(int before, int after)> acrossTheSeam(
        TextDirection direction,
      ) async {
        await tester.pumpWidget(
          _host(
            const RepaintBoundary(
              child: SizedBox(
                width: 400,
                child: Steps(
                  type: StepsType.panel,
                  current: 0,
                  items: [
                    StepItem(title: Text('One')),
                    StepItem(title: Text('Two')),
                  ],
                ),
              ),
            ),
            direction,
          ),
        );
        await tester.pumpAndSettle();

        final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byType(RepaintBoundary).first,
        );

        late int before;
        late int after;
        // Rasterising is real async work, which a widget test's fake clock
        // does not resolve on its own.
        await tester.runAsync(() async {
          final image = await boundary.toImage();
          final data = await image.toByteData(format: ImageByteFormat.rawRgba);

          int at(double fraction) {
            final x = (image.width * fraction).round();
            final y = image.height ~/ 2;
            final i = (y * image.width + x) * 4;
            return (data!.getUint8(i) << 16) |
                (data.getUint8(i + 1) << 8) |
                data.getUint8(i + 2);
          }

          before = at(0.40);
          after = at(0.60);
          image.dispose();
        });
        return (before, after);
      }

      // The current panel is filled and the one ahead is not, so the two sides
      // of the strip differ. Which side carries the fill is the whole question:
      // the run starts where the reading starts.
      final ltr = await acrossTheSeam(TextDirection.ltr);
      final rtl = await acrossTheSeam(TextDirection.rtl);

      // Not an exact mirror pixel for pixel — the first panel has no notch
      // and the last no point — so what is asserted is which side carries the
      // fill, which is the whole question.
      final filled = ltr.$1;
      expect(ltr.$2, isNot(filled), reason: 'the step ahead is not filled');
      expect(
        rtl.$2,
        filled,
        reason: 'the run starts where the reading starts',
      );
      expect(rtl.$1, isNot(filled));
    });
  });
  group('a rail inset', () {
    /// The drawn length of each horizontal rail, read from the painter that
    /// draws it: the line is the slot less the gaps it keeps at either end.
    Future<List<double>> lines(
      WidgetTester tester,
      double inset,
      TextDirection direction,
    ) async {
      await tester.pumpWidget(
        _host(
          SizedBox(
            width: 700,
            child: Steps(
              current: 1,
              items: const [
                StepItem(title: Text('One')),
                StepItem(title: Text('Two')),
                StepItem(title: Text('Three')),
              ],
              token: StepsToken(railInset: RailInsets.all(inset)),
            ),
          ),
          direction,
        ),
      );
      await tester.pumpAndSettle();

      final out = <double>[];
      for (final element in find.byType(CustomPaint).evaluate()) {
        final painter = (element.widget as CustomPaint).painter;
        if (painter is! RailPainter || painter.axis != Axis.horizontal) {
          continue;
        }
        final slot = tester.getRect(find.byWidget(element.widget));
        out.add(slot.width - painter.startInset - painter.endInset);
      }
      return out;
    }

    testWidgets('shortens the line, by the same amount either way round', (
      tester,
    ) async {
      for (final direction in TextDirection.values) {
        final flush = await lines(tester, 0, direction);
        final inset = await lines(tester, 8, direction);
        expect(flush, isNotEmpty, reason: '$direction drew no rails');
        expect(inset.length, flush.length, reason: '$direction');

        for (var i = 0; i < flush.length; i++) {
          // Eight at each end, so sixteen off a line that has it to give. A
          // line already at its floor keeps it — that is the floor's job.
          expect(
            inset[i],
            anyOf(moreOrLessEquals(flush[i] - 16, epsilon: 1), flush[i]),
            reason: '$direction rail $i: ${flush[i]} then ${inset[i]}',
          );
        }
      }
    });

    testWidgets('takes the same room whichever way the run reads', (
      tester,
    ) async {
      // The gaps are the same at both ends here, so the two directions must
      // produce the same set of lengths.
      for (final inset in [0.0, 8.0, 16.0]) {
        expect(
          await lines(tester, inset, TextDirection.rtl),
          await lines(tester, inset, TextDirection.ltr),
          reason: 'inset $inset',
        );
      }
    });
  });
  group('a run of rails', () {
    /// The gaps in the ink along the rail's own row, as (start, width) pairs
    /// measured from the edge the run starts at.
    ///
    /// Read from the painted pixels because this is about where the line
    /// breaks, which no rectangle reports: the halves either meet or they do
    /// not.
    Future<List<String>> breaks(
      WidgetTester tester,
      TextDirection direction,
    ) async {
      await tester.pumpWidget(
        _host(
          const RepaintBoundary(
            child: SizedBox(
              width: 340,
              child: Steps(
                size: SoftSize.small,
                responsive: false,
                current: 1,
                token: StepsToken(railInset: RailInsets.all(3)),
                items: [
                  StepItem(title: Text('Account')),
                  StepItem(title: Text('Card')),
                  StepItem(title: Text('Ship')),
                ],
              ),
            ),
          ),
          direction,
        ),
      );
      await tester.pumpAndSettle();

      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find
            .descendant(
              of: find.byType(Center),
              matching: find.byType(RepaintBoundary),
            )
            .first,
      );

      final out = <String>[];
      await tester.runAsync(() async {
        final image = await boundary.toImage();
        final data = await image.toByteData(format: ImageByteFormat.rawRgba);
        int at(int x, int y) {
          final i = (y * image.width + x) * 4;
          return (data!.getUint8(i) << 16) |
              (data.getUint8(i + 1) << 8) |
              data.getUint8(i + 2);
        }

        final background = at(0, 0);
        // The row carrying the most ink is the one the rails run along.
        var row = 0;
        var most = 0;
        for (var y = 0; y < image.height; y++) {
          var n = 0;
          for (var x = 0; x < image.width; x++) {
            if (at(x, y) != background) n++;
          }
          if (n > most) {
            most = n;
            row = y;
          }
        }

        var lastInk = -1;
        for (var x = 0; x < image.width; x++) {
          if (at(x, row) == background) continue;
          if (lastInk >= 0 && x - lastInk > 1) {
            final from =
                direction == TextDirection.ltr ? lastInk + 1 : image.width - x;
            out.add('$from+${x - lastInk - 1}');
          }
          lastInk = x;
        }
        image.dispose();
      });
      out.sort();
      return out;
    }

    testWidgets('the halves of a rail meet at the same places either way', (
      tester,
    ) async {
      // Each rail between two markers is drawn as two halves, and each half
      // keeps its gap on the side facing a marker. The painter insets by side
      // while the row orders by reading direction; where those disagreed the
      // gap turned inward, breaking the line in the middle and running the
      // ends flush into the markers instead.
      expect(
        await breaks(tester, TextDirection.rtl),
        await breaks(tester, TextDirection.ltr),
      );
    });
  });
  group('a tree', () {
    testWidgets('steps its guides in from the edge it starts at', (
      tester,
    ) async {
      /// Where the depth guides cross the row of a leaf three levels down,
      /// measured from the edge the tree starts at.
      ///
      /// A leaf row is chosen because it carries no switcher: the chevron is a
      /// glyph and never mirrors itself, and it would drown the very lines
      /// this is looking for.
      Future<List<int>> guideColumns(TextDirection direction) async {
        await tester.pumpWidget(
          _host(
            const RepaintBoundary(
              child: SizedBox(
                width: 320,
                child: Tree(
                  showLine: true,
                  defaultExpandedKeys: ['a', 'a2'],
                  nodes: [
                    TreeNode(
                      key: 'a',
                      title: Text('Alpha'),
                      children: [
                        TreeNode(
                          key: 'a2',
                          title: Text('Two'),
                          children: [
                            TreeNode(key: 'a2x', title: Text('Deep')),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            direction,
          ),
        );
        await tester.pumpAndSettle();

        final boundary = tester.renderObject<RenderRepaintBoundary>(
          find
              .descendant(
                of: find.byType(Center),
                matching: find.byType(RepaintBoundary),
              )
              .first,
        );
        final panel = tester.getRect(find.byType(Tree));
        final row = tester.getRect(find.text('Deep')).center.dy - panel.top;

        final out = <int>[];
        await tester.runAsync(() async {
          final image = await boundary.toImage();
          final data = await image.toByteData(format: ImageByteFormat.rawRgba);
          final y = row.round().clamp(0, image.height - 1);
          int at(int x) {
            final i = (y * image.width + x) * 4;
            return (data!.getUint8(i) << 16) |
                (data.getUint8(i + 1) << 8) |
                data.getUint8(i + 2);
          }

          final background = at(image.width ~/ 2);
          for (var x = 0; x < image.width; x++) {
            final lead =
                direction == TextDirection.ltr ? x : image.width - 1 - x;
            if (at(lead) != background) out.add(x);
          }
          image.dispose();
        });
        return out;
      }

      // Each guide is one indent further in than the last. Placed by side
      // rather than by reading order they stayed on the left of a mirrored
      // tree while the rows themselves turned over.
      final ltr = await guideColumns(TextDirection.ltr);
      expect(ltr, isNotEmpty, reason: 'no guides were drawn to compare');
      expect(await guideColumns(TextDirection.rtl), ltr);
    });
  });
  group('a switch', () {
    /// Where the thumb rests, as a distance from the track's leading edge.
    Future<double> thumb(
      WidgetTester tester,
      TextDirection direction, {
      required bool on,
    }) async {
      await tester.pumpWidget(
        _host(Switch(value: on, onChanged: (_) {}), direction),
      );
      await tester.pumpAndSettle();

      final track = tester.getRect(find.byType(Switch));
      // The thumb is the white disc inside the track.
      Rect? knob;
      for (final element in find.byType(AnimatedContainer).evaluate()) {
        final r = tester.getRect(find.byWidget(element.widget));
        if (r.width >= track.width - 1) continue;
        if (knob == null || r.width < knob.width) knob = r;
      }
      return direction == TextDirection.ltr
          ? knob!.left - track.left
          : track.right - knob!.right;
    }

    testWidgets('rests at the start and travels to the end', (tester) async {
      for (final direction in TextDirection.values) {
        final off = await thumb(tester, direction, on: false);
        final on = await thumb(tester, direction, on: true);
        // Measured from each direction's own leading edge the two agree: the
        // thumb sits at the start when off and has moved along when on.
        expect(off, lessThan(on), reason: '$direction');
      }

      // And the same distances either way round, which a side-named thumb
      // cannot manage — it would sit at the far end of a mirrored track.
      expect(
        await thumb(tester, TextDirection.rtl, on: false),
        moreOrLessEquals(
          await thumb(tester, TextDirection.ltr, on: false),
          epsilon: 1,
        ),
      );
    });
  });
  group('a run of avatars', () {
    testWidgets('laps the way it reads', (tester) async {
      /// How far the second face follows the first, in reading order.
      Future<double> lap(TextDirection direction) async {
        await tester.pumpWidget(
          _host(
            const AvatarGroup(
              children: [
                Avatar(child: Text('A')),
                Avatar(child: Text('B')),
              ],
            ),
            direction,
          ),
        );
        await tester.pumpAndSettle();
        final first = tester.getRect(find.text('A'));
        final second = tester.getRect(find.text('B'));
        return direction == TextDirection.ltr
            ? second.center.dx - first.center.dx
            : first.center.dx - second.center.dx;
      }

      // Each face is clipped back towards the edge the run starts at, so the
      // overlap has to fall the way the row reads — clipped leftwards in a
      // mirrored run, the faces lap the wrong one over the other.
      final ltr = await lap(TextDirection.ltr);
      expect(ltr, greaterThan(0));
      expect(await lap(TextDirection.rtl), moreOrLessEquals(ltr, epsilon: 1));
    });
  });
  group('a horizontal sortable list', () {
    testWidgets('spaces its items after each, not to the right of each', (
      tester,
    ) async {
      /// The gap between the first two items, and which side of the first one
      /// it falls on, in reading order.
      Future<double> gapAfterFirst(TextDirection direction) async {
        await tester.pumpWidget(
          _host(
            SizedBox(
              height: 60,
              child: SortableList(
                direction: Axis.horizontal,
                gap: 20,
                onReorder: (_, __) {},
                children: const [
                  SizedBox(key: ValueKey('a'), width: 40, child: Text('A')),
                  SizedBox(key: ValueKey('b'), width: 40, child: Text('B')),
                ],
              ),
            ),
            direction,
          ),
        );
        await tester.pumpAndSettle();

        final first = tester.getRect(find.text('A'));
        final second = tester.getRect(find.text('B'));
        // Positive when B follows A the way the row reads.
        return direction == TextDirection.ltr
            ? second.left - first.right
            : first.left - second.right;
      }

      // Twenty either way round. Placed by side, the gap lands between the
      // first item and the edge behind it in a mirrored row, and the two items
      // come out touching.
      expect(await gapAfterFirst(TextDirection.ltr),
          moreOrLessEquals(20, epsilon: 1));
      expect(await gapAfterFirst(TextDirection.rtl),
          moreOrLessEquals(20, epsilon: 1));
    });

    testWidgets('a column is spaced below each item, not beside it', (
      tester,
    ) async {
      // The other arm of the same choice: down the page there is no leading
      // edge to reckon with, and the gap simply falls under each item.
      await tester.pumpWidget(
        _host(
          SizedBox(
            width: 200,
            child: SortableList(
              gap: 20,
              onReorder: (_, __) {},
              children: const [
                SizedBox(key: ValueKey('a'), height: 40, child: Text('A')),
                SizedBox(key: ValueKey('b'), height: 40, child: Text('B')),
              ],
            ),
          ),
          TextDirection.ltr,
        ),
      );
      await tester.pumpAndSettle();

      expect(
        tester.getRect(find.text('B')).top -
            tester.getRect(find.text('A')).bottom,
        moreOrLessEquals(20, epsilon: 1),
      );
    });
  });

  group('a switch with labels', () {
    testWidgets('keeps its label clear of wherever the thumb rests', (
      tester,
    ) async {
      /// How far the label sits from the track's leading edge.
      Future<double> label(TextDirection direction, {required bool on}) async {
        await tester.pumpWidget(
          _host(
            Switch(
              value: on,
              onChanged: (_) {},
              checkedChild: const Text('I'),
              uncheckedChild: const Text('O'),
            ),
            direction,
          ),
        );
        await tester.pumpAndSettle();
        final track = tester.getRect(find.byType(Switch));
        final text = tester.getRect(find.text(on ? 'I' : 'O'));
        return direction == TextDirection.ltr
            ? text.left - track.left
            : track.right - text.right;
      }

      for (final on in [true, false]) {
        // Read from each direction's own leading edge the two agree: the
        // label sits the same distance in whichever way the track reads.
        expect(
          await label(TextDirection.rtl, on: on),
          moreOrLessEquals(await label(TextDirection.ltr, on: on), epsilon: 1),
          reason: on ? 'on' : 'off',
        );
      }

      // And the two states put it on opposite sides, since it hugs the end
      // away from the thumb.
      expect(
        await label(TextDirection.ltr, on: true),
        lessThan(await label(TextDirection.ltr, on: false)),
      );
    });
  });
}
