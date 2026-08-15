import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seed_ui/seed_ui.dart';

Widget _wrap(Widget child) => ConfigProvider(
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Center(child: child),
      ),
    );

void main() {
  testWidgets('renders each item content in order', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const Timeline(
          items: [
            TimelineItem(content: Text('First')),
            TimelineItem(content: Text('Second')),
            TimelineItem(content: Text('Third')),
          ],
        ),
      ),
    );
    expect(find.text('First'), findsOneWidget);
    expect(find.text('Second'), findsOneWidget);
    expect(find.text('Third'), findsOneWidget);
  });

  testWidgets('a custom dot replaces the default ring', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const Timeline(
          items: [
            TimelineItem(dot: Text('★'), content: Text('Starred')),
          ],
        ),
      ),
    );
    expect(find.text('★'), findsOneWidget);
  });

  testWidgets('labels render alongside content', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const Timeline(
          items: [
            TimelineItem(label: Text('2015-09-01'), content: Text('Event')),
          ],
        ),
      ),
    );
    expect(find.text('2015-09-01'), findsOneWidget);
    expect(find.text('Event'), findsOneWidget);
  });

  testWidgets('pending appends a trailing node', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const Timeline(
          pending: Text('Recording...'),
          items: [TimelineItem(content: Text('Done'))],
        ),
      ),
    );
    expect(find.text('Done'), findsOneWidget);
    expect(find.text('Recording...'), findsOneWidget);
    // The spinner never settles — drive frames explicitly.
    await tester.pump(const Duration(milliseconds: 100));
  });

  testWidgets('alternate mode still shows every item', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const Timeline(
          mode: TimelineMode.alternate,
          items: [
            TimelineItem(content: Text('A')),
            TimelineItem(content: Text('B')),
            TimelineItem(content: Text('C')),
          ],
        ),
      ),
    );
    expect(find.text('A'), findsOneWidget);
    expect(find.text('B'), findsOneWidget);
    expect(find.text('C'), findsOneWidget);
  });

  testWidgets('per-item height fixes the item length', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const Align(
          alignment: Alignment.topLeft,
          child: Timeline(
            items: [
              TimelineItem(content: Text('Tall'), height: 100),
              TimelineItem(content: Text('Next')),
            ],
          ),
        ),
      ),
    );
    // The second row starts 100px down, proving the first item's fixed height.
    expect(tester.getRect(find.text('Next')).top, greaterThanOrEqualTo(100));
  });

  testWidgets('per-item contentOpacity wraps the content', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const Timeline(
          items: [
            TimelineItem(content: Text('Faded'), contentOpacity: 0.45),
          ],
        ),
      ),
    );
    final opacity = tester.widget<Opacity>(
      find.ancestor(of: find.text('Faded'), matching: find.byType(Opacity)),
    );
    expect(opacity.opacity, 0.45);
  });

  group('Rail inset and dot variant', () {
    List<RailPainter> painters(WidgetTester tester) => tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((p) => p.painter)
        .whereType<RailPainter>()
        .toList();

    Future<void> pump(WidgetTester tester, {double? inset}) =>
        tester.pumpWidget(
          _wrap(
            SizedBox(
              width: 400,
              child: Timeline(
                token: TimelineToken(
                  railInset: inset == null ? null : RailInsets.all(inset),
                ),
                items: const [
                  TimelineItem(content: Text('One')),
                  TimelineItem(content: Text('Two')),
                  TimelineItem(content: Text('Three')),
                ],
              ),
            ),
          ),
        );

    testWidgets('by default the thread runs unbroken through the dots',
        (tester) async {
      await pump(tester);
      // The middle node's two runs meet at the dot's centre.
      final middle = painters(tester)[1].segments;
      expect(middle.first.end, closeTo(middle.last.start, 0.01));
    });

    testWidgets('an inset pulls the line back from the dot', (tester) async {
      await pump(tester, inset: 4);
      final middle = painters(tester)[1].segments;
      expect(
        middle.last.start - middle.first.end,
        greaterThan(8),
        reason: 'the dot is 10 across, so its edges alone are 10 apart',
      );
    });

    testWidgets('an inset wider than the run above the dot does not invert',
        (tester) async {
      await pump(tester, inset: 40);
      for (final painter in painters(tester)) {
        for (final segment in painter.segments) {
          expect(
            segment.end,
            greaterThan(segment.start),
            reason: 'a line of negative length',
          );
        }
      }
    });

    testWidgets('an item can take its own dot variant', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const SizedBox(
            width: 400,
            child: Timeline(
              items: [
                TimelineItem(content: Text('One')),
                TimelineItem(
                  content: Text('Two'),
                  dotVariant: TimelineVariant.filled,
                ),
              ],
            ),
          ),
        ),
      );

      // The run is outlined; the second dot is filled, so it has no border and
      // its fill is the accent rather than the container colour.
      final dots = tester
          .widgetList<Container>(find.byType(Container))
          .map((c) => c.decoration)
          .whereType<BoxDecoration>()
          .where((d) => d.shape == BoxShape.circle)
          .toList();

      expect(dots.first.border, isNotNull);
      expect(dots[1].border, isNull);
      expect(dots[1].color, isNot(dots.first.color));
    });
  });

  testWidgets('titleSpan sets the distance from the dot to the content',
      (tester) async {
    Future<double> contentLeft(double? span) async {
      await tester.pumpWidget(
        _wrap(
          SizedBox(
            width: 400,
            child: Timeline(
              titleSpan: span,
              items: const [TimelineItem(content: Text('One'))],
            ),
          ),
        ),
      );
      return tester.getRect(find.text('One')).left;
    }

    final byDefault = await contentLeft(null);
    expect(
      await contentLeft(32),
      closeTo(byDefault + 20, 0.5),
      reason: 'the default is 12',
    );
    expect(await contentLeft(72), closeTo(byDefault + 60, 0.5));
  });

  testWidgets('rail insets can differ above and below a dot', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const SizedBox(
          width: 400,
          child: Timeline(
            token: TimelineToken(railInset: RailInsets.vertical(bottom: 4)),
            items: [
              TimelineItem(content: Text('One')),
              TimelineItem(content: Text('Two')),
              TimelineItem(content: Text('Three')),
            ],
          ),
        ),
      ),
    );

    final middle = tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((p) => p.painter)
        .whereType<RailPainter>()
        .toList()[1]
        .segments;

    // The top side was left alone, so that run still reaches the dot's centre;
    // the bottom one is pushed clear of it.
    final centre = middle.first.end;
    expect(middle.last.start - centre, greaterThan(8));
  });

  group('TimelineGroupController', () {
    test('starts closed unless told otherwise', () {
      expect(TimelineGroupController().expanded, isFalse);
      expect(TimelineGroupController(expanded: true).expanded, isTrue);
    });

    test('open, close and toggle move the flag', () {
      final c = TimelineGroupController();
      c.open();
      expect(c.expanded, isTrue);
      c.close();
      expect(c.expanded, isFalse);
      c.toggle();
      expect(c.expanded, isTrue);
      c.toggle();
      expect(c.expanded, isFalse);
    });

    test('only a real change notifies', () {
      final c = TimelineGroupController();
      var notifications = 0;
      c.addListener(() => notifications++);

      // Already closed: closing again is not a change.
      c.close();
      expect(notifications, 0);

      c.open();
      expect(notifications, 1);

      // Already open.
      c.open();
      expect(notifications, 1);

      c.toggle();
      expect(notifications, 2);
    });
  });

  group('TimelineGroupItem', () {
    testWidgets('the run past collapsedCount is folded to nothing',
        (tester) async {
      final controller = TimelineGroupController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        _wrap(
          Timeline(
            items: [
              const TimelineItem(content: Text('Before')),
              TimelineGroupItem(
                controller: controller,
                items: const [
                  TimelineItem(content: Text('Head')),
                  TimelineItem(content: Text('Hidden A')),
                  TimelineItem(content: Text('Hidden B')),
                ],
              ),
              const TimelineItem(content: Text('After')),
            ],
          ),
        ),
      );

      // Ungrouped nodes and the group's head are laid out as usual. Collapsed
      // content stays mounted at zero height rather than leaving the tree, so
      // presence proves nothing — the run's height does.
      expect(find.text('Before'), findsOneWidget);
      expect(find.text('Head'), findsOneWidget);
      expect(find.text('After'), findsOneWidget);

      final collapsed = tester.getSize(find.byType(Timeline)).height;

      controller.open();
      await tester.pumpAndSettle();
      final expanded = tester.getSize(find.byType(Timeline)).height;

      expect(expanded, greaterThan(collapsed));
    });

    testWidgets('initiallyExpanded reveals the whole run', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const Timeline(
            items: [
              TimelineGroupItem(
                initiallyExpanded: true,
                items: [
                  TimelineItem(content: Text('Head')),
                  TimelineItem(content: Text('Tail')),
                ],
              ),
            ],
          ),
        ),
      );

      expect(find.text('Head'), findsOneWidget);
      expect(find.text('Tail'), findsOneWidget);
    });

    testWidgets('a controller opens and closes the group', (tester) async {
      final controller = TimelineGroupController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        _wrap(
          Timeline(
            items: [
              TimelineGroupItem(
                controller: controller,
                items: const [
                  TimelineItem(content: Text('Head')),
                  TimelineItem(content: Text('Tail')),
                ],
              ),
            ],
          ),
        ),
      );

      final shut = tester.getSize(find.byType(Timeline)).height;

      controller.open();
      await tester.pumpAndSettle();
      final open = tester.getSize(find.byType(Timeline)).height;
      expect(open, greaterThan(shut));

      controller.close();
      await tester.pumpAndSettle();
      expect(tester.getSize(find.byType(Timeline)).height, closeTo(shut, 0.5));
    });

    testWidgets('collapsedCount: 0 folds the whole group away', (tester) async {
      final controller = TimelineGroupController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        _wrap(
          Timeline(
            items: [
              TimelineGroupItem(
                controller: controller,
                collapsedCount: 0,
                items: const [
                  TimelineItem(content: Text('Only')),
                ],
              ),
            ],
          ),
        ),
      );

      // Nothing is left to show, so the run collapses to no height at all.
      expect(tester.getSize(find.byType(Timeline)).height, closeTo(0, 0.5));

      controller.open();
      await tester.pumpAndSettle();
      expect(tester.getSize(find.byType(Timeline)).height, greaterThan(0));
    });

    test('a negative collapsedCount is rejected', () {
      expect(
        () => TimelineGroupItem(
          collapsedCount: -1,
          items: const [TimelineItem(content: Text('x'))],
        ),
        throwsAssertionError,
      );
    });

    testWidgets('groups fold along the axis on a horizontal run',
        (tester) async {
      final controller = TimelineGroupController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        _wrap(
          Timeline(
            orientation: TimelineOrientation.horizontal,
            items: [
              TimelineGroupItem(
                controller: controller,
                items: const [
                  TimelineItem(content: Text('Head')),
                  TimelineItem(content: Text('Tail')),
                ],
              ),
            ],
          ),
        ),
      );

      // A horizontal group clips along its width, not its height.
      final shut = tester.getSize(find.byType(Timeline)).width;

      controller.open();
      await tester.pumpAndSettle();
      expect(tester.getSize(find.byType(Timeline)).width, greaterThan(shut));
    });
  });

  group('Orientation and order', () {
    testWidgets('a horizontal run lays its nodes left to right',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          const Timeline(
            orientation: TimelineOrientation.horizontal,
            items: [
              TimelineItem(content: Text('First')),
              TimelineItem(content: Text('Second')),
              TimelineItem(content: Text('Third')),
            ],
          ),
        ),
      );

      final first = tester.getCenter(find.text('First'));
      final second = tester.getCenter(find.text('Second'));
      final third = tester.getCenter(find.text('Third'));

      expect(second.dx, greaterThan(first.dx));
      expect(third.dx, greaterThan(second.dx));
      // A horizontal run does not stack.
      expect(second.dy, closeTo(first.dy, 0.5));
    });

    testWidgets('reverse flips the order of the nodes', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const Timeline(
            reverse: true,
            items: [
              TimelineItem(content: Text('First')),
              TimelineItem(content: Text('Second')),
            ],
          ),
        ),
      );

      // Written first, drawn last.
      expect(
        tester.getCenter(find.text('First')).dy,
        greaterThan(tester.getCenter(find.text('Second')).dy),
      );
    });

    testWidgets('reverse puts a pending node at the top', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const Timeline(
            reverse: true,
            pending: Text('Working…'),
            items: [
              TimelineItem(content: Text('Done')),
            ],
          ),
        ),
      );

      expect(
        tester.getCenter(find.text('Working…')).dy,
        lessThan(tester.getCenter(find.text('Done')).dy),
      );
    });

    testWidgets('a horizontal run shows labels on the far side',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          const Timeline(
            orientation: TimelineOrientation.horizontal,
            items: [
              TimelineItem(label: Text('Label'), content: Text('Content')),
            ],
          ),
        ),
      );

      expect(find.text('Label'), findsOneWidget);
      expect(find.text('Content'), findsOneWidget);
      // The label sits across the axis from the content.
      expect(
        tester.getCenter(find.text('Label')).dy,
        isNot(closeTo(tester.getCenter(find.text('Content')).dy, 1)),
      );
    });
  });
}
