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
}
