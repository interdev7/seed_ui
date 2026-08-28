import 'package:flutter/material.dart'
    hide ThemeData, Checkbox, Radio, RadioGroup, Switch, Tooltip, Drawer;
import 'package:flutter_test/flutter_test.dart';
import 'package:seed_ui/seed_ui.dart';

Widget _host(Widget child) => MaterialApp(
      home: Scaffold(body: Center(child: child)),
    );

const _options = [
  SegmentedOption(value: 'list', label: 'List'),
  SegmentedOption(value: 'grid', label: 'Grid'),
  SegmentedOption(value: 'map', label: 'Map'),
];

void main() {
  _scrollButtonTests();

  testWidgets('renders every segment label', (tester) async {
    await tester.pumpWidget(
      _host(
        Segmented<String>(
          value: 'list',
          options: _options,
          onChanged: (_) {},
        ),
      ),
    );

    expect(find.text('List'), findsOneWidget);
    expect(find.text('Grid'), findsOneWidget);
    expect(find.text('Map'), findsOneWidget);
  });

  testWidgets('tapping a segment reports its value', (tester) async {
    String? picked;
    await tester.pumpWidget(
      _host(
        Segmented<String>(
          value: 'list',
          options: _options,
          onChanged: (v) => picked = v,
        ),
      ),
    );

    await tester.tap(find.text('Grid'));
    expect(picked, 'grid');
  });

  testWidgets('tapping the already-selected segment does nothing',
      (tester) async {
    var calls = 0;
    await tester.pumpWidget(
      _host(
        Segmented<String>(
          value: 'list',
          options: _options,
          onChanged: (_) => calls++,
        ),
      ),
    );

    await tester.tap(find.text('List'));
    expect(calls, 0);
  });

  testWidgets('a null onChanged disables selection', (tester) async {
    await tester.pumpWidget(
      _host(
        const Segmented<String>(
          value: 'list',
          options: _options,
        ),
      ),
    );
    // No handler → tapping is inert; nothing to assert beyond no crash.
    await tester.tap(find.text('Grid'));
    await tester.pump();
  });

  testWidgets('a disabled segment is not selectable', (tester) async {
    String? picked;
    await tester.pumpWidget(
      _host(
        Segmented<String>(
          value: 'list',
          options: const [
            SegmentedOption(value: 'list', label: 'List'),
            SegmentedOption(value: 'grid', label: 'Grid', disabled: true),
          ],
          onChanged: (v) => picked = v,
        ),
      ),
    );

    await tester.tap(find.text('Grid'));
    expect(picked, isNull);
  });

  testWidgets('works with a non-string value type', (tester) async {
    int? picked;
    await tester.pumpWidget(
      _host(
        Segmented<int>(
          value: 1,
          options: const [
            SegmentedOption(value: 1, label: 'One'),
            SegmentedOption(value: 2, label: 'Two'),
          ],
          onChanged: (v) => picked = v,
        ),
      ),
    );

    await tester.tap(find.text('Two'));
    expect(picked, 2);
  });

  testWidgets('the thumb animates to the selected segment', (tester) async {
    await tester.pumpWidget(
      _host(
        Segmented<String>(
          value: 'list',
          options: _options,
          onChanged: (_) {},
        ),
      ),
    );
    // The thumb is measured after the first frame.
    await tester.pump();
    await tester.pump();

    Rect thumbRect() => tester.getRect(find.byType(AnimatedPositioned));
    final start = thumbRect();

    // Rebuild with a later selection; the thumb should slide, so mid-animation
    // it is neither at the start nor yet at the end.
    await tester.pumpWidget(
      _host(
        Segmented<String>(
          value: 'map',
          options: _options,
          onChanged: (_) {},
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    final mid = thumbRect();
    expect(mid.left, greaterThan(start.left));

    await tester.pump(const Duration(milliseconds: 300));
    final end = thumbRect();
    expect(end.left, greaterThan(mid.left));
  });

  testWidgets('renders vertically', (tester) async {
    await tester.pumpWidget(
      _host(
        const Segmented<String>(
          value: 'list',
          direction: Axis.vertical,
          options: _options,
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    // Segments stack: 'List' sits above 'Map'.
    expect(
      tester.getCenter(find.text('List')).dy,
      lessThan(tester.getCenter(find.text('Map')).dy),
    );
  });

  testWidgets('a custom child renders in place of label/icon', (tester) async {
    await tester.pumpWidget(
      _host(
        Segmented<String>(
          value: 'a',
          onChanged: (_) {},
          options: const [
            SegmentedOption(value: 'a', child: Text('CUSTOM')),
            SegmentedOption(value: 'b', label: 'B'),
          ],
        ),
      ),
    );
    expect(find.text('CUSTOM'), findsOneWidget);
  });

  testWidgets('a long label wraps instead of overflowing in a narrow block',
      (tester) async {
    await tester.pumpWidget(
      _host(
        const SizedBox(
          width: 240,
          child: Segmented<int>(
            block: true,
            size: SoftSize.large,
            value: 1,
            options: [
              SegmentedOption(value: 0, label: 'Compact'),
              SegmentedOption(value: 1, label: 'Cozy'),
              SegmentedOption(value: 2, label: 'Comfortable'),
            ],
          ),
        ),
      ),
    );
    await tester.pump();

    // No RenderFlex overflow, and the full label is present (wrapped).
    expect(tester.takeException(), isNull);
    expect(find.text('Comfortable'), findsOneWidget);
  });

  testWidgets('a long label is not clipped', (tester) async {
    await tester.pumpWidget(
      _host(
        const Segmented<int>(
          value: 1,
          options: [
            SegmentedOption(value: 0, label: 'Compact'),
            SegmentedOption(value: 1, label: 'Comfortable'),
          ],
        ),
      ),
    );
    await tester.pump();
    // Content-sized segments never clip: no overflow error is thrown, and the
    // full label is laid out.
    expect(tester.takeException(), isNull);
    expect(find.text('Comfortable'), findsOneWidget);
  });

  testWidgets('a segmented control is as wide as its options, unless block',
      (tester) async {
    // The control is inline-flex: a stretch Column hands down a tight
    // width, and the track must not take it.
    Future<double> widthIn({required bool block}) async {
      await tester.pumpWidget(
        _host(
          SizedBox(
            width: 600,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Segmented<int>(
                  block: block,
                  value: 1,
                  options: const [
                    SegmentedOption(value: 1, label: 'A'),
                    SegmentedOption(value: 2, label: 'B'),
                  ],
                  onChanged: (_) {},
                ),
              ],
            ),
          ),
        ),
      );
      // The widget's own box may fill the slot it was given; what matters is
      // the track it paints.
      return tester
          .getRect(
            find
                .descendant(
                  of: find.byType(Segmented<int>),
                  matching: find.byType(Container),
                )
                .first,
          )
          .width;
    }

    final natural = await widthIn(block: false);
    final filled = await widthIn(block: true);

    expect(natural, lessThan(300), reason: 'got $natural of 600');
    expect(filled, 600);
  });

  group('A run wider than its box', () {
    const many = [
      SegmentedOption(value: 0, label: 'Overview'),
      SegmentedOption(value: 1, label: 'Analytics'),
      SegmentedOption(value: 2, label: 'Reports'),
      SegmentedOption(value: 3, label: 'Settings'),
      SegmentedOption(value: 4, label: 'Members'),
    ];

    testWidgets('scrolls instead of overflowing', (tester) async {
      await tester.pumpWidget(
        _host(
          const SizedBox(
            width: 300,
            child: Segmented<int>(value: 0, options: many),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // An overflow would have been reported as an exception by the renderer.
      expect(tester.takeException(), isNull);

      // The control fills the box it was given rather than spilling past it.
      expect(tester.getSize(find.byType(Segmented<int>)).width, 300);

      // Every segment is still built — reachable by scrolling, not dropped.
      expect(find.text('Members'), findsOneWidget);
    });

    testWidgets('the run really does scroll', (tester) async {
      await tester.pumpWidget(
        _host(
          const SizedBox(
            width: 300,
            child: Segmented<int>(value: 0, options: many),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final before = tester.getTopLeft(find.text('Overview')).dx;
      await tester.drag(find.text('Overview'), const Offset(-120, 0));
      await tester.pumpAndSettle();

      expect(tester.getTopLeft(find.text('Overview')).dx, lessThan(before));
    });

    testWidgets('with room to spare it stays content-sized', (tester) async {
      await tester.pumpWidget(
        _host(
          const SizedBox(
            width: 900,
            child: Segmented<int>(value: 0, options: many),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Scrolling must not turn the control greedy when it fits.
      expect(
        tester.getSize(find.byType(Segmented<int>)).width,
        lessThan(900),
      );
    });

    testWidgets('block still fills the width it is given', (tester) async {
      await tester.pumpWidget(
        _host(
          const SizedBox(
            width: 300,
            child: Segmented<int>(value: 0, options: many, block: true),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.byType(Segmented<int>)).width, 300);
    });
  });

  group('Elevation in both themes', () {
    Color trackOf(WidgetTester tester) {
      final box = tester.widgetList<Container>(find.byType(Container)).first;
      return (box.decoration! as BoxDecoration).color!;
    }

    Color thumbOf(WidgetTester tester) {
      final thumb = tester
          .widgetList<DecoratedBox>(find.byType(DecoratedBox))
          .firstWhere((d) => (d.decoration as BoxDecoration).boxShadow != null);
      return (thumb.decoration as BoxDecoration).color!;
    }

    double luminance(Color c) => c.computeLuminance();

    for (final dark in [false, true]) {
      testWidgets(
          'the thumb sits above the track in a ${dark ? 'dark' : 'light'} theme',
          (tester) async {
        await tester.pumpWidget(
          ConfigProvider(
            theme: ThemeData(dark: dark),
            child: _host(
              Segmented<String>(
                value: 'list',
                options: _options,
                onChanged: (_) {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // "Above" is the same relation in both themes: the elevated surface is
        // the lighter one. A translucent fill for the track inverted this in
        // dark, leaving the shadow as the only separation.
        expect(luminance(thumbOf(tester)),
            greaterThan(luminance(trackOf(tester))));
      });
    }

    testWidgets('and the gap is wider than a hairline in dark', (tester) async {
      await tester.pumpWidget(
        ConfigProvider(
          theme: ThemeData(dark: true),
          child: _host(
            Segmented<String>(
              value: 'list',
              options: _options,
              onChanged: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final d = luminance(thumbOf(tester)) - luminance(trackOf(tester));
      expect(d, greaterThan(0.005));
    });
  });
  group('when there is not enough room', () {
    const long = [
      SegmentedOption(value: 0, label: 'Compact'),
      SegmentedOption(value: 1, label: 'Cozy'),
      SegmentedOption(value: 2, label: 'Comfortable'),
    ];

    testWidgets('a content-sized run keeps its labels whole and scrolls', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 160,
                child:
                    Segmented<int>(value: 1, options: long, onChanged: (_) {}),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Squeezed into far less room than it wants, and still no overflow.
      expect(tester.takeException(), isNull);
      expect(
        find.descendant(
          of: find.byType(Segmented<int>),
          matching: find.byType(SingleChildScrollView),
        ),
        findsOneWidget,
        reason: 'the run scrolls rather than shrinking its segments',
      );

      // Every label at its natural width: a segment is as wide as its text.
      final wide = tester.getSize(find.text('Comfortable')).width;
      final narrow = tester.getSize(find.text('Cozy')).width;
      expect(wide, greaterThan(narrow));
    });

    testWidgets('a block run shares the width instead, and cuts what spills', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 160,
                child: Segmented<int>(
                  value: 1,
                  block: true,
                  options: long,
                  onChanged: (_) {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      // Block is the deliberate opposite: equal shares of the width, and what
      // will not fit is cut with an ellipsis rather than the run scrolling.
      expect(
        find.descendant(
          of: find.byType(Segmented<int>),
          matching: find.byType(SingleChildScrollView),
        ),
        findsNothing,
      );
      expect(tester.getSize(find.byType(Segmented<int>)).width, 160);

      // One line, whatever the label. Wrapping made the whole strip grow a
      // second line to suit its longest word.
      final label = tester.widget<Text>(find.text('Comfortable'));
      expect(label.maxLines, 1);
      expect(label.overflow, TextOverflow.ellipsis);
    });

    testWidgets('a block run fills loose constraints, not only tight ones', (
      tester,
    ) async {
      // How a demo card hands its contents down: room to the edge, but not an
      // instruction to reach it. Block still means the full width.
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              child: Align(
                alignment: AlignmentDirectional.topStart,
                child: Segmented<int>(
                  value: 1,
                  block: true,
                  onChanged: (_) {},
                  options: const [
                    SegmentedOption(value: 0, label: 'A'),
                    SegmentedOption(value: 1, label: 'B'),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.getSize(find.byType(Segmented<int>)).width, 400);
    });

    testWidgets('a block run stays one control tall however long the label', (
      tester,
    ) async {
      Future<double> heightFor(String longest) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 150,
                  child: Segmented<int>(
                    value: 1,
                    block: true,
                    onChanged: (_) {},
                    options: [
                      const SegmentedOption(value: 0, label: 'A'),
                      const SegmentedOption(value: 1, label: 'B'),
                      SegmentedOption(value: 2, label: longest),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        return tester.getSize(find.byType(Segmented<int>)).height;
      }

      final short = await heightFor('C');
      final long = await heightFor('An extremely long label indeed');
      expect(long, short, reason: 'the strip does not grow a second line');
    });
  });
}

/// A run of five, too wide for the box the tests put it in.
const _long = ['Compact', 'Cozy', 'Comfortable', 'Extra', 'Extra Large'];

Widget _run({
  double width = 220,
  bool block = false,
  bool? scrollButtons,
  Axis? direction,
  TextDirection dir = TextDirection.ltr,
  ValueChanged<int>? onChanged,
}) =>
    ConfigProvider(
      child: MaterialApp(
        home: Directionality(
          textDirection: dir,
          child: Scaffold(
            body: Center(
              child: SizedBox(
                width: width,
                child: Segmented<int>(
                  value: 0,
                  size: SoftSize.small,
                  block: block,
                  direction: direction,
                  scrollButtons: scrollButtons,
                  onChanged: onChanged ?? (_) {},
                  options: [
                    for (var i = 0; i < _long.length; i++)
                      SegmentedOption(value: i, label: _long[i]),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

int _arrows(String label) => find.bySemanticsLabel(label).evaluate().length;

/// The labels a reader can actually see: inside the viewport, and not behind
/// one of the buttons laid over its ends.
List<String> _readable(WidgetTester tester) {
  var view = tester.getRect(find.byType(SingleChildScrollView));
  // Cut by where each button actually is, not by which one it is: a mirrored
  // run puts "next" on the left.
  for (final label in const ['Previous', 'Next']) {
    final arrow = find.bySemanticsLabel(label);
    if (arrow.evaluate().isEmpty) continue;
    final r = tester.getRect(arrow);
    view = r.center.dx < view.center.dx
        ? Rect.fromLTRB(r.right, view.top, view.right, view.bottom)
        : Rect.fromLTRB(view.left, view.top, r.left, view.bottom);
  }
  return [
    for (final l in _long)
      if (tester.getRect(find.text(l)).left >= view.left - 0.5 &&
          tester.getRect(find.text(l)).right <= view.right + 0.5)
        l,
  ];
}

void _scrollButtonTests() {
  group('scroll buttons', () {
    testWidgets('a run that fits offers none', (tester) async {
      await tester.pumpWidget(_run(width: 900));
      await tester.pumpAndSettle();
      expect(_arrows('Previous'), 0);
      expect(_arrows('Next'), 0);
    });

    testWidgets('only the end with something hidden offers one',
        (tester) async {
      await tester.pumpWidget(_run());
      await tester.pumpAndSettle();
      // At rest the run starts at its beginning, so there is nothing behind.
      expect(_arrows('Previous'), 0);
      expect(_arrows('Next'), 1);
    });

    testWidgets('a step brings on exactly the next hidden segment',
        (tester) async {
      await tester.pumpWidget(_run());
      await tester.pumpAndSettle();
      final before = _readable(tester);
      final nextHidden = _long[_long.indexOf(before.last) + 1];

      await tester.tap(find.bySemanticsLabel('Next'));
      await tester.pumpAndSettle();

      final after = _readable(tester);
      expect(after, contains(nextHidden));
      expect(
        after,
        isNot(contains(_long[_long.indexOf(nextHidden) + 1])),
        reason: 'one at a time, not a page',
      );
    });

    testWidgets('and a step back brings on the one behind', (tester) async {
      await tester.pumpWidget(_run());
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Next'));
      await tester.pumpAndSettle();
      final before = _readable(tester);
      final behind = _long[_long.indexOf(before.first) - 1];

      await tester.tap(find.bySemanticsLabel('Previous'));
      await tester.pumpAndSettle();
      expect(_readable(tester), contains(behind));
    });

    testWidgets('each arrow goes when its end runs out', (tester) async {
      await tester.pumpWidget(_run());
      await tester.pumpAndSettle();

      var steps = 0;
      while (_arrows('Next') > 0 && steps < 10) {
        await tester.tap(find.bySemanticsLabel('Next'));
        await tester.pumpAndSettle();
        steps++;
      }
      expect(steps, lessThan(10), reason: 'the run ends');
      expect(_arrows('Previous'), 1, reason: 'everything is behind now');
      expect(_readable(tester), contains(_long.last));

      while (_arrows('Previous') > 0 && steps < 20) {
        await tester.tap(find.bySemanticsLabel('Previous'));
        await tester.pumpAndSettle();
        steps++;
      }
      expect(_arrows('Next'), 1);
      expect(_readable(tester), contains(_long.first));
    });

    testWidgets('a tap on an arrow does not choose the segment beneath it',
        (tester) async {
      var chosen = -1;
      await tester.pumpWidget(_run(onChanged: (v) => chosen = v));
      await tester.pumpAndSettle();

      await tester.tap(find.bySemanticsLabel('Next'));
      await tester.pumpAndSettle();
      expect(chosen, -1);
    });

    testWidgets('scrollButtons: false leaves the run bare', (tester) async {
      await tester.pumpWidget(_run(scrollButtons: false));
      await tester.pumpAndSettle();
      expect(_arrows('Next'), 0);
    });

    testWidgets('a block run and a column never scroll, and so never ask',
        (tester) async {
      await tester.pumpWidget(_run(block: true));
      await tester.pumpAndSettle();
      expect(_arrows('Next'), 0);

      await tester.pumpWidget(_run(direction: Axis.vertical));
      await tester.pumpAndSettle();
      expect(_arrows('Next'), 0);
    });

    testWidgets('a mirrored run steps the way it reads', (tester) async {
      await tester.pumpWidget(_run(dir: TextDirection.rtl));
      await tester.pumpAndSettle();

      final view = tester.getRect(find.byType(SingleChildScrollView));
      final next = tester.getRect(find.bySemanticsLabel('Next'));
      expect(
        next.left < view.center.dx,
        isTrue,
        reason: 'right to left, so onwards is leftwards',
      );

      final before = _readable(tester);
      await tester.tap(find.bySemanticsLabel('Next'));
      await tester.pumpAndSettle();
      expect(_readable(tester), isNot(before));
      expect(_arrows('Previous'), 1);
    });
  });
}
