import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart'
    hide ThemeData, Checkbox, Radio, RadioGroup, Switch, Tooltip, Drawer, Step;
import 'package:flutter_test/flutter_test.dart';
import 'package:seed_ui/seed_ui.dart';

Widget _host(Widget child) => ConfigProvider(
      theme: ThemeData.light,
      child: MaterialApp(home: Scaffold(body: child)),
    );

const _items = [
  StepItem(title: Text('Cart'), content: Text('3 items')),
  StepItem(title: Text('Payment')),
  StepItem(title: Text('Done')),
];

/// Every box the run paints an edge with, in paint order.
List<BoxDecoration> _decorations(WidgetTester tester) => [
      ...tester
          .widgetList<Container>(find.byType(Container))
          .map((c) => c.decoration)
          .whereType<BoxDecoration>(),
      ...tester
          .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
          .map((c) => c.decoration)
          .whereType<BoxDecoration>(),
    ];

/// How close a path comes to a point, walked along its own metrics.
double _nearest(Path path, Offset probe) {
  var best = double.infinity;
  for (final metric in path.computeMetrics()) {
    for (var d = 0.0; d <= metric.length; d += 0.25) {
      final gap = (metric.getTangentForOffset(d)!.position - probe).distance;
      if (gap < best) best = gap;
    }
  }
  return best;
}

/// Counts what a painter actually draws, so "one line per join" is a fact
/// rather than a hope.
class _CountingCanvas implements Canvas {
  int strokes = 0;
  int fills = 0;
  final List<Path> fillPaths = [];
  final List<Path> strokePaths = [];
  final List<Color> strokeColours = [];

  @override
  void drawPath(Path path, Paint paint) {
    if (paint.style == PaintingStyle.stroke) {
      strokes++;
      strokePaths.add(path);
      strokeColours.add(paint.color);
    } else {
      fills++;
      fillPaths.add(path);
    }
  }

  @override
  void noSuchMethod(Invocation invocation) {}
}

/// Whether a panel strip is actually scrollable — it always sits in a scroll
/// view, which only scrolls when the strip outgrows the room.
/// A navigation run paints its blocks and its markers with the same widget;
/// the blocks are the wide ones.
List<Rect> _blockRects(WidgetTester tester) {
  final found = find.byType(AnimatedContainer);
  return [
    for (var i = 0; i < found.evaluate().length; i++)
      tester.getRect(found.at(i)),
  ].where((r) => r.width > 60).toList();
}

bool _scrolls(WidgetTester tester) {
  final view = find.byType(SingleChildScrollView);
  if (view.evaluate().isEmpty) return false;
  return tester.getRect(find.byType(IntrinsicWidth).first).width >
      tester.getRect(view.first).width + 0.5;
}

/// Records every rail run drawn: a rail is painted as a rect, so its edges are
/// exactly where the painter puts them.
class _LineCanvas implements Canvas {
  _LineCanvas(this.lengths, [this.rects]);

  final List<double> lengths;
  final List<Rect>? rects;

  @override
  void drawRect(Rect rect, Paint paint) {
    lengths.add(rect.width);
    rects?.add(rect);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  group('Steps', () {
    testWidgets('numbers the steps and marks the ones behind as finished',
        (tester) async {
      await tester.pumpWidget(_host(const Steps(current: 1, items: _items)));

      // Step 1 is done, so it shows a tick rather than its number; step 3 has
      // not been reached and still shows one.
      expect(find.text('1'), findsNothing);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('Cart'), findsOneWidget);
    });

    testWidgets('initial shifts the numbering', (tester) async {
      await tester.pumpWidget(
        _host(const Steps(current: 0, initial: 3, items: _items)),
      );

      expect(find.text('4'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('the rail behind the current step is accented', (tester) async {
      await tester.pumpWidget(
        _host(
          const SizedBox(
            width: 600,
            child: Steps(current: 1, items: _items),
          ),
        ),
      );

      final rails = tester
          .widgetList<CustomPaint>(find.byType(CustomPaint))
          .map((p) => p.painter)
          .whereType<RailPainter>()
          .toList();

      final colours = [
        for (final rail in rails) ...rail.segments.map((s) => s.color),
      ];
      final t = ThemeData.light.token;
      expect(colours, contains(t.primary.base), reason: 'travelled');
      expect(colours, contains(t.colorSplit), reason: 'still ahead');
    });

    testWidgets('the rail is a separator: it never touches a marker',
        (tester) async {
      // The rail is drawn with a gap at both ends, so it reads as a
      // separator between steps rather than a stalk growing out of a circle.
      for (final type in [StepsType.standard, StepsType.dot]) {
        for (final orientation in StepsOrientation.values) {
          await tester.pumpWidget(
            _host(
              SizedBox(
                width: 700,
                child: Steps(
                  type: type,
                  orientation: orientation,
                  current: 1,
                  items: _items,
                ),
              ),
            ),
          );

          final painters = tester
              .widgetList<CustomPaint>(find.byType(CustomPaint))
              .map((p) => p.painter)
              .whereType<RailPainter>()
              .toList();

          expect(painters, isNotEmpty, reason: '$type / $orientation');
          for (final rail in painters) {
            final gapped = rail.startInset > 0 ||
                rail.endInset > 0 ||
                rail.segments.every((s) => s.start > 0);
            expect(
              gapped,
              isTrue,
              reason: 'rail runs into the marker in $type / $orientation',
            );
          }
        }
      }
    });

    testWidgets('tapping a step reports it, unless it is disabled',
        (tester) async {
      final taps = <int>[];
      await tester.pumpWidget(
        _host(
          Steps(
            current: 0,
            onChange: taps.add,
            items: const [
              StepItem(title: Text('One')),
              StepItem(title: Text('Two')),
              StepItem(title: Text('Three'), disabled: true),
            ],
          ),
        ),
      );

      await tester.tap(find.text('Two'));
      await tester.tap(find.text('Three'));
      await tester.pump();

      expect(taps, [1]);
    });

    testWidgets('hovering a step lifts its marker and text, and eases into it',
        (tester) async {
      await tester.pumpWidget(
        _host(
          SizedBox(
            width: 700,
            child: Steps(current: 0, onChange: (_) {}, items: _items),
          ),
        ),
      );

      BoxDecoration markerOf(String number) => tester
          .widget<AnimatedContainer>(
            find
                .ancestor(
                  of: find.text(number),
                  matching: find.byType(AnimatedContainer),
                )
                .first,
          )
          .decoration! as BoxDecoration;

      final resting = markerOf('2').color;

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      await gesture.moveTo(tester.getCenter(find.text('Payment')));
      await tester.pumpAndSettle();

      // The marker answers the hover too, not just the text.
      expect(markerOf('2').color, isNot(resting));
      expect(markerOf('2').color, ThemeData.light.token.primary.bgHover);

      // And the text is animated rather than switched.
      expect(
        find.ancestor(
          of: find.text('Payment'),
          matching: find.byType(AnimatedDefaultTextStyle),
        ),
        findsWidgets,
      );
    });

    testWidgets('a marker never flashes on its way to the hover tint',
        (tester) async {
      await tester.pumpWidget(
        _host(
          SizedBox(
            width: 700,
            child: Steps(current: 0, onChange: (_) {}, items: _items),
          ),
        ),
      );

      double luminance() {
        final decoration = tester
            .widget<AnimatedContainer>(
              find
                  .ancestor(
                    of: find.text('2'),
                    matching: find.byType(AnimatedContainer),
                  )
                  .first,
            )
            .decoration! as BoxDecoration;
        // Read the value actually on screen, not the target.
        final painted = tester
            .widgetList<DecoratedBox>(
              find.ancestor(
                of: find.text('2'),
                matching: find.byType(DecoratedBox),
              ),
            )
            .first
            .decoration as BoxDecoration;
        expect(decoration.shape, BoxShape.circle);
        return Color.alphaBlend(
          painted.color ?? const Color(0x00000000),
          const Color(0xFFFFFFFF),
        ).computeLuminance();
      }

      final resting = luminance();

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      await gesture.moveTo(tester.getCenter(find.text('Payment')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      final midway = luminance();
      await tester.pumpAndSettle();
      final hovered = luminance();

      // A translucent fill lerped to an opaque one dips through a dark grey.
      expect(
        midway,
        greaterThan(hovered - 0.05),
        reason: 'marker dipped to $midway between $resting and $hovered',
      );
    });

    testWidgets('the step in play ignores hover', (tester) async {
      await tester.pumpWidget(
        _host(
          SizedBox(
            width: 700,
            child: Steps(current: 1, onChange: (_) {}, items: _items),
          ),
        ),
      );

      BoxDecoration marker() => tester
          .widget<AnimatedContainer>(
            find
                .ancestor(
                  of: find.text('2'),
                  matching: find.byType(AnimatedContainer),
                )
                .first,
          )
          .decoration! as BoxDecoration;

      final resting = marker().color;

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      await gesture.moveTo(tester.getCenter(find.text('Payment')));
      await tester.pumpAndSettle();

      // The rule is `:not(-active):hover` — the current step's colours
      // are the point of the component and must not wobble under the pointer.
      expect(marker().color, resting);
    });

    testWidgets('a vertical step is only hit where it is drawn',
        (tester) async {
      final taps = <int>[];
      await tester.pumpWidget(
        _host(
          SizedBox(
            width: 600,
            child: Steps(
              orientation: StepsOrientation.vertical,
              current: 0,
              onChange: taps.add,
              items: _items,
            ),
          ),
        ),
      );

      // The run is 600 wide but its steps are not: a tap far to the right of
      // the text is on the page, not on a step.
      final row = tester.getRect(find.text('Cart'));
      await tester.tapAt(Offset(560, row.center.dy));
      await tester.pump();
      expect(taps, isEmpty);

      // 'Payment' is the second step, index 1.
      await tester.tap(find.text('Payment'));
      await tester.pump();
      expect(taps, [1]);
    });

    testWidgets('an uncontrolled run keeps its own current step',
        (tester) async {
      await tester.pumpWidget(
        _host(
          Steps(
            defaultCurrent: 0,
            onChange: (_) {},
            items: _items,
          ),
        ),
      );

      expect(find.text('1'), findsOneWidget);
      await tester.tap(find.text('Payment'));
      await tester.pump();

      // Step 1 is behind us now: a tick replaced its number.
      expect(find.text('1'), findsNothing);
    });

    testWidgets('the controller walks and clamps at both ends', (tester) async {
      final controller = StepsController();
      addTearDown(controller.dispose);

      await tester
          .pumpWidget(_host(Steps(controller: controller, items: _items)));

      controller.previous();
      await tester.pump();
      expect(controller.current, 0, reason: 'cannot go before the first');

      controller.next();
      controller.next();
      controller.next();
      controller.next();
      await tester.pump();
      expect(controller.current, 2, reason: 'cannot go past the last');
    });

    testWidgets('status: error stops the run at the current step',
        (tester) async {
      await tester.pumpWidget(
        _host(
          const Steps(
            current: 1,
            status: StepStatus.error,
            items: _items,
          ),
        ),
      );

      final t = ThemeData.light.token;
      final fills = _decorations(tester).map((d) => d.color).toList();
      expect(fills, contains(t.error.base));
    });

    testWidgets('an item may override its own status', (tester) async {
      await tester.pumpWidget(
        _host(
          const Steps(
            current: 0,
            items: [
              StepItem(title: Text('One')),
              StepItem(title: Text('Two'), status: StepStatus.error),
            ],
          ),
        ),
      );

      final t = ThemeData.light.token;
      expect(_decorations(tester).map((d) => d.color), contains(t.error.base));
    });

    testWidgets('a panel strip strokes every line exactly once',
        (tester) async {
      // Each panel *and* the arrow between them is stroked, so an
      // outlined run doubles its seams. Ours paints the strip in one pass, so
      // the count is checkable: one outline plus one chevron per seam.
      await tester.pumpWidget(
        _host(
          const SizedBox(
            width: 700,
            child: Steps(
              type: StepsType.panel,
              variant: StepsVariant.outlined,
              current: 1,
              items: _items,
            ),
          ),
        ),
      );

      final painter = tester
          .widgetList<CustomPaint>(find.byType(CustomPaint))
          .map((p) => p.painter)
          .firstWhere((p) => p.runtimeType.toString() == '_PanelStripPainter');

      final canvas = _CountingCanvas();
      painter!.paint(canvas, const Size(700, 90));

      // One stroke per panel's own edges, plus one per join — and not a line
      // more. Letting both neighbours stroke the join is where
      // its doubled seams come from.
      expect(canvas.strokes, _items.length + (_items.length - 1));
      expect(canvas.fills, _items.length, reason: 'one fill per panel');

      // And no panel carries a border of its own to double it up.
      final bordered = _decorations(tester).where(
        (d) =>
            d.shape == BoxShape.rectangle &&
            d.border != null &&
            d.border != const Border(),
      );
      expect(bordered, isEmpty);
    });

    testWidgets('a panel points into the next one', (tester) async {
      // The shape the panel arrow draws: the trailing edge is a point
      // that reaches into the neighbour, and the neighbour is notched to take
      // it. Checked on the painted path itself rather than by eye.
      await tester.pumpWidget(
        _host(
          const SizedBox(
            width: 600,
            child: Steps(type: StepsType.panel, current: 0, items: _items),
          ),
        ),
      );

      final painter = tester
          .widgetList<CustomPaint>(find.byType(CustomPaint))
          .map((p) => p.painter)
          .firstWhere((p) => p.runtimeType.toString() == '_PanelStripPainter');

      const size = Size(600, 100);
      final canvas = _CountingCanvas();
      painter!.paint(canvas, size);

      final first = canvas.fillPaths.first;
      final seam = size.width / _items.length; // where panel 1 would end square

      // At mid-height the panel reaches past the square seam — that is the
      // point…
      expect(first.contains(Offset(seam + 8, size.height / 2)), isTrue);
      // …and near the top it does not, because the point tapers.
      expect(first.contains(Offset(seam + 8, 4)), isFalse);

      // The neighbour is missing exactly that wedge.
      final second = canvas.fillPaths[1];
      expect(second.contains(Offset(seam + 4, size.height / 2)), isFalse);
      expect(second.contains(Offset(seam + 4, 4)), isTrue);
    });

    testWidgets('the selected panel owns the seam in front of it',
        (tester) async {
      // The join is drawn once, so it has to pick a colour. The selected panel
      // wins: its outline is the one the eye follows, and without this its
      // leading point would keep the previous step's grey.
      Future<List<Color>> seamColours(int current) async {
        await tester.pumpWidget(
          _host(
            SizedBox(
              width: 700,
              child: Steps(
                type: StepsType.panel,
                variant: StepsVariant.outlined,
                current: current,
                items: _items,
              ),
            ),
          ),
        );

        final painter = tester
            .widgetList<CustomPaint>(find.byType(CustomPaint))
            .map((p) => p.painter)
            .firstWhere(
              (p) => p.runtimeType.toString() == '_PanelStripPainter',
            );
        final canvas = _CountingCanvas();
        painter!.paint(canvas, const Size(700, 90));
        // The seams are the last strokes drawn.
        return canvas.strokeColours
            .sublist(_items.length)
            .whereType<Color>()
            .toList();
      }

      final t = ThemeData.light.token;
      int argb(Color c) => c.toARGB32();

      // The join in front of the selected step takes its colour…
      expect(argb((await seamColours(1)).first), argb(t.primary.base));
      expect(argb((await seamColours(2))[1]), argb(t.primary.base));
      // …while a join between two steps that are both still waiting stays grey.
      expect(argb((await seamColours(0))[1]), argb(t.colorBorder));
    });

    testWidgets('the first panel rounds its corners the way its fill does',
        (tester) async {
      // Two arcs join any two points; the one centred *on* the corner bulges
      // outward and reads as a kink. The outline has to sweep the same way the
      // fill does.
      await tester.pumpWidget(
        _host(
          const SizedBox(
            width: 700,
            child: Steps(
              type: StepsType.panel,
              variant: StepsVariant.outlined,
              current: 0,
              items: _items,
            ),
          ),
        ),
      );

      final painter = tester
          .widgetList<CustomPaint>(find.byType(CustomPaint))
          .map((p) => p.painter)
          .firstWhere((p) => p.runtimeType.toString() == '_PanelStripPainter');
      final canvas = _CountingCanvas();
      const size = Size(700, 100);
      painter!.paint(canvas, size);

      final radius = ThemeData.light.token.borderRadius;
      const h = 100.0;
      // Midpoint of a proper bottom-left corner…
      final proper = Offset(
        radius - radius * 0.7071,
        h - radius + radius * 0.7071,
      );
      // …and of the arc that bulges the other way.
      final bulged = Offset(radius * 0.7071, h - radius * 0.7071);

      for (final path in [canvas.fillPaths.first, canvas.strokePaths.first]) {
        expect(_nearest(path, proper), lessThan(0.5));
        expect(_nearest(path, bulged), greaterThan(1));
      }
    });

    testWidgets('a panel strip shares the room, or scrolls when there is none',
        (tester) async {
      // Room to spare: the panels split it.
      await tester.pumpWidget(
        _host(
          const SizedBox(
            width: 900,
            child: Steps(type: StepsType.panel, current: 0, items: _items),
          ),
        ),
      );
      expect(_scrolls(tester), isFalse);
      final roomy = tester.getRect(find.text('Cart'));

      // A phone-width run cannot fit three panels at their floor, so the strip
      // keeps its size and scrolls instead of crushing them.
      await tester.pumpWidget(
        _host(
          const SizedBox(
            width: 360,
            child: Steps(type: StepsType.panel, current: 0, items: _items),
          ),
        ),
      );
      final scroller = find.byType(SingleChildScrollView);
      expect(_scrolls(tester), isTrue);
      expect(
        tester.widget<SingleChildScrollView>(scroller).scrollDirection,
        Axis.horizontal,
      );

      // The floor is yours to set, and it is the floor that decides while the
      // text is short enough to sit under it.
      await tester.pumpWidget(
        _host(
          const SizedBox(
            width: 500,
            child: Steps(
              type: StepsType.panel,
              current: 0,
              items: [
                StepItem(title: Text('One')),
                StepItem(title: Text('Two')),
                StepItem(title: Text('Three')),
              ],
              token: StepsToken(panelMinWidth: 100),
            ),
          ),
        ),
      );
      expect(_scrolls(tester), isFalse);
      expect(tester.getRect(find.text('One')).left, lessThan(roomy.left + 1));
    });

    testWidgets('a vertical panel strip points downward', (tester) async {
      // The same shape turned a quarter: each panel points down into the next,
      // and the next is notched to take it.
      await tester.pumpWidget(
        _host(
          const SizedBox(
            width: 400,
            child: Steps(
              type: StepsType.panel,
              variant: StepsVariant.outlined,
              orientation: StepsOrientation.vertical,
              current: 1,
              items: _items,
            ),
          ),
        ),
      );

      final painter = tester
          .widgetList<CustomPaint>(find.byType(CustomPaint))
          .map((p) => p.painter)
          .firstWhere((p) => p.runtimeType.toString() == '_PanelStripPainter');

      const size = Size(400, 300);
      final canvas = _CountingCanvas();
      painter!.paint(canvas, size);

      final first = canvas.fillPaths.first;
      final seam = size.height / _items.length;

      // The point reaches past the square join, down the middle…
      expect(first.contains(Offset(size.width / 2, seam + 6)), isTrue);
      // …and tapers, so the far side of the panel ends at the join.
      expect(first.contains(const Offset(6, 6 + 100)), isFalse);

      expect(canvas.strokes, _items.length + (_items.length - 1));
    });

    testWidgets('a dot run draws dots instead of numbers', (tester) async {
      await tester.pumpWidget(
        _host(
          const SizedBox(
            width: 600,
            child: Steps(type: StepsType.dot, current: 1, items: _items),
          ),
        ),
      );

      expect(find.text('2'), findsNothing);
      expect(find.text('Payment'), findsOneWidget);
    });

    testWidgets('a horizontal rail starts at the title, not at the content',
        (tester) async {
      // The rail goes in the header row, beside the title. A long
      // description then flows underneath instead of shoving the line towards
      // the next step.
      await tester.pumpWidget(
        _host(
          const SizedBox(
            width: 800,
            child: Steps(
              current: 1,
              items: [
                StepItem(
                  title: Text('Cart'),
                  content: Text('a much longer content line'),
                ),
                StepItem(title: Text('Payment')),
                StepItem(title: Text('Done')),
              ],
            ),
          ),
        ),
      );

      final title = tester.getRect(find.text('Cart'));
      final content = tester.getRect(find.text('a much longer content line'));
      final rail = tester.getRect(
        find
            .byWidgetPredicate(
              (w) => w is CustomPaint && w.painter is RailPainter,
            )
            .first,
      );

      expect(rail.left, closeTo(title.right, 1));
      expect(
        content.right,
        greaterThan(rail.left),
        reason: 'the content runs on under the rail',
      );
      expect(content.left, closeTo(title.left, 1));
      expect(content.top, greaterThan(title.bottom - 1));
      expect(rail.width, greaterThan(20));
    });

    testWidgets('a marker, its title and the rail share one axis',
        (tester) async {
      // The header row is `align-items: center`, so a 32px circle and
      // a 25px line of type meet on the same centre line — and the rail, which
      // lives in that row, lands on it too.
      await tester.pumpWidget(
        _host(
          const SizedBox(
            width: 800,
            child: Steps(current: 1, items: _items),
          ),
        ),
      );

      final marker = tester.getRect(
        find
            .ancestor(
              of: find.text('2'),
              matching: find.byType(AnimatedContainer),
            )
            .first,
      );
      final title = tester.getRect(find.text('Payment'));
      final rail = tester.getRect(
        find
            .byWidgetPredicate(
              (w) => w is CustomPaint && w.painter is RailPainter,
            )
            .first,
      );

      expect(title.center.dy, closeTo(marker.center.dy, 0.5));
      expect(rail.center.dy, closeTo(marker.center.dy, 0.5));
    });

    testWidgets('a vertical step lines its marker up with its title too',
        (tester) async {
      // The vertical heading band is as tall as the taller of the
      // marker and the title line, with the marker centred in it — so the two
      // share an axis whatever the type size is.
      for (final size in [SoftSize.middle, SoftSize.small]) {
        await tester.pumpWidget(
          _host(
            SizedBox(
              width: 500,
              child: Steps(
                orientation: StepsOrientation.vertical,
                size: size,
                current: 1,
                items: _items,
              ),
            ),
          ),
        );

        final marker = tester.getRect(
          find
              .ancestor(
                of: find.text('2'),
                matching: find.byType(AnimatedContainer),
              )
              .first,
        );
        final title = tester.getRect(find.text('Payment'));
        expect(
          title.center.dy,
          closeTo(marker.center.dy, 0.5),
          reason: '$size',
        );
      }
    });

    testWidgets('an inline run has no gaps at all: every dot meets its rails',
        (tester) async {
      // The marker slot used to be as wide as the *current* dot, so every other
      // dot sat centred in it with a pixel of air on each side — visible at the
      // ends of a run, where only one rail hides it.
      await tester.pumpWidget(
        _host(
          const SizedBox(
            width: 600,
            child: Steps(
              type: StepsType.inline,
              current: 1,
              items: [
                StepItem(title: Text('One')),
                StepItem(title: Text('Two')),
                StepItem(title: Text('Three')),
                StepItem(title: Text('Four')),
              ],
            ),
          ),
        ),
      );

      final marks = <(double, double)>[];
      final rails = find.byWidgetPredicate(
        (w) => w is CustomPaint && w.painter is RailPainter,
      );
      for (var i = 0; i < rails.evaluate().length; i++) {
        final box = tester.getRect(rails.at(i));
        final painter =
            tester.widget<CustomPaint>(rails.at(i)).painter as RailPainter;
        marks
            .add((box.left + painter.startInset, box.right - painter.endInset));
      }
      final dots = find.byType(AnimatedContainer);
      for (var i = 0; i < dots.evaluate().length; i++) {
        final rect = tester.getRect(dots.at(i));
        if (rect.width > 20) continue;
        marks.add((rect.left, rect.right));
      }
      marks.sort((a, b) => a.$1.compareTo(b.$1));

      for (var i = 1; i < marks.length; i++) {
        expect(
          marks[i].$1,
          closeTo(marks[i - 1].$2, 0.5),
          reason: 'a gap opened before piece $i of the run',
        );
      }
    });

    testWidgets('the run between two dots is one line, not two with a void',
        (tester) async {
      // A dot run draws the stretch between two markers as two halves, one per
      // step. Only the ends that meet a marker may keep the gap — an inner one
      // would leave a hole in the middle of the line.
      await tester.pumpWidget(
        _host(
          const SizedBox(
            width: 600,
            child: Steps(type: StepsType.dot, current: 1, items: _items),
          ),
        ),
      );

      final rails = find.byWidgetPredicate(
        (w) => w is CustomPaint && w.painter is RailPainter,
      );

      final drawn = <(double, double)>[];
      for (var i = 0; i < rails.evaluate().length; i++) {
        final box = tester.getRect(rails.at(i));
        final painter =
            tester.widget<CustomPaint>(rails.at(i)).painter as RailPainter;
        drawn
            .add((box.left + painter.startInset, box.right - painter.endInset));
      }

      expect(
        drawn.length,
        (_items.length - 1) * 2,
        reason: 'two halves per join',
      );
      // Each pair meets in the middle.
      for (var i = 0; i < drawn.length; i += 2) {
        expect(
          drawn[i].$2,
          closeTo(drawn[i + 1].$1, 0.5),
          reason: 'a void opened between the halves of join ${i ~/ 2}',
        );
      }
    });

    testWidgets('inline steps keep their rails and drop their content',
        (tester) async {
      await tester.pumpWidget(
        _host(
          const SizedBox(
            width: 700,
            child: Steps(type: StepsType.inline, current: 1, items: _items),
          ),
        ),
      );

      expect(find.text('Cart'), findsOneWidget);
      expect(find.text('3 items'), findsNothing, reason: 'content is hidden');

      final rails = tester
          .widgetList<CustomPaint>(find.byType(CustomPaint))
          .where((p) => p.painter is RailPainter)
          .toList();
      expect(rails, isNotEmpty, reason: 'inline runs still have rails');
    });

    testWidgets('a narrow horizontal run stands up', (tester) async {
      await tester.pumpWidget(
        _host(
          const SizedBox(
            width: 300,
            child: Steps(current: 0, items: _items),
          ),
        ),
      );

      // Vertical runs stack their steps, so the first title sits above the last.
      final first = tester.getTopLeft(find.text('Cart'));
      final last = tester.getTopLeft(find.text('Done'));
      expect(last.dy, greaterThan(first.dy));
      expect(last.dx, closeTo(first.dx, 1));
    });

    testWidgets('token overrides reach the markers', (tester) async {
      await tester.pumpWidget(
        _host(
          const Steps(
            current: 0,
            items: _items,
            token: StepsToken(iconSize: 48),
          ),
        ),
      );

      final marker = tester
          .widgetList<AnimatedContainer>(
            find.ancestor(
              of: find.text('1'),
              matching: find.byType(AnimatedContainer),
            ),
          )
          .first;
      expect(marker.constraints?.maxWidth ?? 0, 48);
    });
  });

  group('Progress ring', () {
    testWidgets('the ring is the kit\'s own Progress, wrapping the marker',
        (tester) async {
      await tester.pumpWidget(
        _host(
          const SizedBox(
            width: 600,
            child: Steps(
              current: 1,
              percent: 0.6,
              items: [
                StepItem(title: Text('One')),
                StepItem(title: Text('Two')),
              ],
            ),
          ),
        ),
      );

      final ring = tester.widget<Progress>(find.byType(Progress));
      expect(ring.percent, 0.6);
      expect(ring.child, isNotNull, reason: 'the marker rides in the middle');
      // The marker is inside the ring, not beside it.
      expect(
        find.descendant(of: find.byType(Progress), matching: find.text('2')),
        findsOneWidget,
      );
    });

    testWidgets('a progress template keeps its own look', (tester) async {
      await tester.pumpWidget(
        _host(
          const SizedBox(
            width: 600,
            child: Steps(
              current: 0,
              percent: 0.4,
              progress: Progress(
                percent: 0,
                type: ProgressType.dashboard,
                color: Color(0xFF00FF00),
                strokeWidth: 7,
              ),
              items: [
                StepItem(title: Text('One')),
                StepItem(title: Text('Two'))
              ],
            ),
          ),
        ),
      );

      final ring = tester.widget<Progress>(find.byType(Progress));
      expect(ring.type, ProgressType.dashboard);
      expect(ring.color, const Color(0xFF00FF00));
      expect(ring.strokeWidth, 7);
      // Steps supplies the value and the marker, and nothing else.
      expect(ring.percent, 0.4);
      expect(ring.child, isNotNull);
    });

    testWidgets('a line progress is refused: a ring goes round a marker',
        (tester) async {
      final errors = <String>[];
      final previous = FlutterError.onError;
      FlutterError.onError =
          (details) => errors.add(details.exceptionAsString());
      await tester.pumpWidget(
        _host(
          const SizedBox(
            width: 600,
            child: Steps(
              progress: Progress(percent: 0.5),
              items: [StepItem(title: Text('One'))],
            ),
          ),
        ),
      );
      FlutterError.onError = previous;

      // The assert says so in debug — it is what a caller sees. A release
      // build has no assert and falls back to a circle instead of blowing up
      // on the unbounded width a line bar would demand.
      expect(errors.first, contains('circle or a dashboard'));
    });

    testWidgets('a template alone carries its own percent', (tester) async {
      await tester.pumpWidget(
        _host(
          const SizedBox(
            width: 600,
            child: Steps(
              current: 0,
              progress: Progress(percent: 0.25, type: ProgressType.circle),
              items: [
                StepItem(title: Text('One')),
                StepItem(title: Text('Two'))
              ],
            ),
          ),
        ),
      );

      expect(tester.widget<Progress>(find.byType(Progress)).percent, 0.25);
    });

    testWidgets('a vertical run leaves the ring its room', (tester) async {
      // The marker slot is sized for the marker; a ring is wider, and a run
      // that did not reserve for it squeezed the ring down to the marker,
      // hiding it — which is what a phone-width run turns into.
      await tester.pumpWidget(
        _host(
          const SizedBox(
            width: 360,
            child: Steps(
              orientation: StepsOrientation.vertical,
              current: 1,
              percent: 0.6,
              items: [
                StepItem(title: Text('One')),
                StepItem(title: Text('Two')),
                StepItem(title: Text('Three')),
              ],
            ),
          ),
        ),
      );

      final ring = tester.getRect(find.byType(Progress));
      final marker = tester.getRect(find.text('2'));
      expect(ring.width, greaterThan(marker.width));
      expect(ring.width, 32 + stepsRingPadding);
    });

    testWidgets('only the step in play is ringed', (tester) async {
      await tester.pumpWidget(
        _host(
          const SizedBox(
            width: 600,
            child: Steps(
              current: 1,
              percent: 0.6,
              items: [
                StepItem(title: Text('One')),
                StepItem(title: Text('Two')),
                StepItem(title: Text('Three')),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(Progress), findsOneWidget);
    });
  });

  testWidgets('panelMinWidth is a floor: it bites only when room runs out',
      (tester) async {
    Future<(int, double)> run(double width, double floor) async {
      await tester.pumpWidget(
        _host(
          SizedBox(
            width: width,
            child: Steps(
              type: StepsType.panel,
              current: 1,
              token: StepsToken(panelMinWidth: floor),
              items: const [
                StepItem(title: Text('Cart')),
                StepItem(title: Text('Delivery')),
                StepItem(title: Text('Payment')),
                StepItem(title: Text('Done')),
              ],
            ),
          ),
        ),
      );
      // The pitch between two panels is the width each one got. Measured
      // between the second and third: the first has no arrow notched into its
      // start, so its neighbour's text sits an arrow further along.
      final pitch = tester.getRect(find.text('Payment')).left -
          tester.getRect(find.text('Delivery')).left;
      return (_scrolls(tester) ? 1 : 0, pitch);
    }

    // Room to spare: the panels share it and the floor changes nothing.
    final (roomyScroll, roomyPitch) = await run(760, 100);
    expect(roomyScroll, 0);
    expect(roomyPitch, closeTo(190, 1));

    // Above the floor the strip keeps its size and scrolls instead.
    final (tightScroll, tightPitch) = await run(360, 260);
    expect(tightScroll, 1);
    expect(tightPitch, closeTo(260, 1));
  });

  testWidgets('size reaches the panels: a small run is tighter',
      (tester) async {
    Future<double> textLeft(SoftSize size) async {
      await tester.pumpWidget(
        _host(
          SizedBox(
            width: 760,
            child: Steps(
              type: StepsType.panel,
              size: size,
              current: 1,
              items: const [
                StepItem(title: Text('Cart')),
                StepItem(title: Text('Delivery')),
              ],
            ),
          ),
        ),
      );
      // The first panel's text starts one padding in.
      return tester.getRect(find.text('Cart')).left;
    }

    final middle = await textLeft(SoftSize.middle);
    final small = await textLeft(SoftSize.small);
    expect(small, lessThan(middle), reason: 'small padding: $small vs $middle');
  });

  testWidgets('a horizontal run keeps one axis when a title wraps',
      (tester) async {
    // Squeezed — a phone with `responsive: false` — the titles wrap to
    // different numbers of lines. Centring each marker on its own title turned
    // the run into a staircase; the header band keeps them all on one axis.
    await tester.pumpWidget(
      _host(
        const SizedBox(
          width: 360,
          child: Steps(
            size: SoftSize.small,
            responsive: false,
            current: 1,
            items: [
              StepItem(title: Text('Account'), icon: Icon(Icons.person)),
              StepItem(title: Text('Card'), icon: Icon(Icons.credit_card)),
              StepItem(title: Text('Ship'), icon: Icon(Icons.local_shipping)),
            ],
          ),
        ),
      ),
    );

    final icons = find.byType(Icon);
    final tops = [
      for (var i = 0; i < icons.evaluate().length; i++)
        tester.getRect(icons.at(i)).top,
    ];
    expect(tops.toSet().length, 1, reason: 'markers at $tops');

    final rails = find
        .byWidgetPredicate((w) => w is CustomPaint && w.painter is RailPainter);
    final railTops = [
      for (var i = 0; i < rails.evaluate().length; i++)
        tester.getRect(rails.at(i)).top,
    ];
    expect(railTops.toSet().length, 1, reason: 'rails at $railTops');

    // And the titles still start at the top of the band, not below it.
    expect(
      tester.getRect(find.text('Account')).top,
      closeTo(tester.getRect(find.text('Ship')).top, 0.5),
    );
  });

  group('Width floor', () {
    Widget run(double width, {StepsToken? token}) => _host(
          SizedBox(
            width: width,
            child: Steps(
              size: SoftSize.small,
              responsive: false,
              current: 1,
              token: token,
              items: const [
                StepItem(title: Text('Account'), icon: Icon(Icons.person)),
                StepItem(title: Text('Card'), icon: Icon(Icons.credit_card)),
                StepItem(title: Text('Ship'), icon: Icon(Icons.local_shipping)),
              ],
            ),
          ),
        );

    testWidgets('a narrowing run stacks first and scrolls only when it must',
        (tester) async {
      Rect marker() => tester.getRect(find.byType(AnimatedContainer).first);
      Rect title() => tester.getRect(find.text('Account'));

      await tester.pumpWidget(run(900));
      expect(find.byType(SingleChildScrollView), findsNothing);
      expect(
        title().left,
        greaterThan(marker().right),
        reason: 'roomy: the title sits beside its marker',
      );
      final roomy = title().height;

      // Too narrow to keep the text beside the markers: it goes under them,
      // which costs the reader less than a scrollbar.
      await tester.pumpWidget(run(360));
      expect(find.byType(SingleChildScrollView), findsNothing);
      expect(title().top, greaterThan(marker().bottom));
      expect(title().height, lessThanOrEqualTo(roomy * 2));

      // Narrower than even a stacked step can take: now it scrolls.
      await tester.pumpWidget(run(150));
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('itemMinWidth sets the floor', (tester) async {
      await tester
          .pumpWidget(run(900, token: const StepsToken(itemMinWidth: 400)));
      expect(
        find.byType(SingleChildScrollView),
        findsOneWidget,
        reason: '3 × 400 does not fit 900',
      );

      await tester
          .pumpWidget(run(360, token: const StepsToken(itemMinWidth: 80)));
      expect(
        find.byType(SingleChildScrollView),
        findsNothing,
        reason: '3 × 80 fits 360',
      );
    });

    testWidgets('a navigation run scrolls when its blocks will not fit',
        (tester) async {
      Future<void> pump(double width) => tester.pumpWidget(
            _host(
              SizedBox(
                width: width,
                child: Steps(
                  type: StepsType.navigation,
                  current: 1,
                  onChange: (_) {},
                  items: const [
                    StepItem(title: Text('Details'), subTitle: Text('00:02')),
                    StepItem(title: Text('Review'), subTitle: Text('00:05')),
                    StepItem(title: Text('Publish')),
                  ],
                ),
              ),
            ),
          );

      // The default test surface is 800 wide, which is narrower than this run
      // wants; give it a window a desktop would have.
      tester.view.physicalSize = const Size(1400, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      // The strip always sits in a scroll view; what matters is whether it
      // has anything to scroll.
      await pump(1200);
      expect(_scrolls(tester), isFalse);

      await pump(360);
      expect(_scrolls(tester), isTrue);
      // The floor budgets for the subtitle, which cannot shrink; without that
      // it pushed the title out of the row and the header overflowed.
      expect(tester.takeException(), isNull);
      expect(tester.getRect(find.text('Details')).width, greaterThan(0));
    });

    testWidgets('inline keeps its miniature shape and never scrolls',
        (tester) async {
      await tester.pumpWidget(
        _host(
          const SizedBox(
            width: 200,
            child: Steps(
              type: StepsType.inline,
              current: 1,
              items: [
                StepItem(title: Text('One')),
                StepItem(title: Text('Two')),
                StepItem(title: Text('Three')),
              ],
            ),
          ),
        ),
      );
      expect(find.byType(SingleChildScrollView), findsNothing);
    });
  });

  group('Size', () {
    Future<Rect> markerOf(WidgetTester tester, ControlSize size) async {
      await tester.pumpWidget(
        _host(
          SizedBox(
            width: 700,
            child: Steps(
              size: size,
              current: 1,
              items: const [
                StepItem(title: Text('One')),
                StepItem(title: Text('Two')),
              ],
            ),
          ),
        ),
      );
      // The marker animates its diameter, so let it arrive before measuring.
      await tester.pumpAndSettle();
      return tester.getRect(find.byType(AnimatedContainer).first);
    }

    testWidgets('the presets step the marker up', (tester) async {
      expect((await markerOf(tester, SoftSize.small)).width, 24);
      expect((await markerOf(tester, SoftSize.middle)).width, 32);
      expect((await markerOf(tester, SoftSize.large)).width, 40);
    });

    testWidgets('a number is the marker diameter, and the type follows it',
        (tester) async {
      expect((await markerOf(tester, const ControlSize.fixed(48))).width, 48);

      // The type keeps up with the circle beside it: a 48px marker takes the
      // large scale, a 20px one the small.
      double titleHeight() => tester.getRect(find.text('Two')).height;
      await markerOf(tester, const ControlSize.fixed(48));
      final big = titleHeight();
      await markerOf(tester, const ControlSize.fixed(20));
      expect(titleHeight(), lessThan(big));
    });
  });

  group('Rail length', () {
    /// The line as it is actually drawn: the slot less the painter's insets.
    Future<List<Rect>> rails(
      WidgetTester tester,
      StepsOrientation orientation, {
      double? length,
      StepsType type = StepsType.standard,
      List<StepItem>? items,
    }) async {
      await tester.pumpWidget(
        _host(
          SizedBox(
            width: 700,
            child: Steps(
              orientation: orientation,
              type: type,
              current: 1,
              token: StepsToken(railLength: length),
              items: items ??
                  const [
                    StepItem(title: Text('Cart')),
                    StepItem(title: Text('Delivery')),
                    StepItem(title: Text('Payment')),
                  ],
            ),
          ),
        ),
      );
      final found = find.byWidgetPredicate(
        (w) => w is CustomPaint && w.painter is RailPainter,
      );
      return [
        for (var i = 0; i < found.evaluate().length; i++)
          () {
            final box = tester.getRect(found.at(i));
            final painter =
                tester.widget<CustomPaint>(found.at(i)).painter as RailPainter;
            return orientation == StepsOrientation.horizontal
                ? Rect.fromLTRB(
                    box.left + painter.startInset,
                    box.top,
                    box.right - painter.endInset,
                    box.bottom,
                  )
                : Rect.fromLTRB(
                    box.left,
                    box.top + painter.startInset,
                    box.right,
                    box.bottom - painter.endInset,
                  );
          }(),
      ];
    }

    testWidgets('left alone, rails take what the titles leave', (tester) async {
      final free = await rails(tester, StepsOrientation.horizontal);
      // Titles differ in length, so the rails do too.
      expect(free.map((r) => r.width).toSet().length, greaterThan(1));
    });

    testWidgets('a named length is the line you see, in both orientations',
        (tester) async {
      for (final length in [40.0, 120.0]) {
        final across =
            await rails(tester, StepsOrientation.horizontal, length: length);
        expect(across.map((r) => r.width), everyElement(closeTo(length, 0.5)));

        final down =
            await rails(tester, StepsOrientation.vertical, length: length);
        expect(down.map((r) => r.height), everyElement(closeTo(length, 0.5)));
      }
    });

    testWidgets('a rail always reaches the next marker, however wide the text',
        (tester) async {
      // Content wider than the header: the step grows, and the rail is the
      // part that gives — a line stopping short of a marker is a broken line.
      const wide = [
        StepItem(title: Text('Cart'), content: Text('3 items · 4 200 ₽')),
        StepItem(title: Text('Delivery'), content: Text('Pick a date')),
        StepItem(title: Text('Payment'), content: Text('Card or on delivery')),
      ];
      final drawn = await rails(
        tester,
        StepsOrientation.horizontal,
        length: 40,
        items: wide,
      );

      final markers = find.byType(AnimatedContainer);
      final lefts = [
        for (var i = 0; i < markers.evaluate().length; i++)
          tester.getRect(markers.at(i)).left,
      ]..sort();

      for (var i = 0; i < drawn.length; i++) {
        expect(
          drawn[i].width,
          greaterThanOrEqualTo(40 - 0.5),
          reason: 'never shorter than it was told to be',
        );
        // It ends one inset short of the marker it runs towards.
        expect(drawn[i].right, closeTo(lefts[i + 1] - 16, 1));
      }
    });

    testWidgets('a vertical rail reaches down to the next marker',
        (tester) async {
      final drawn = await rails(tester, StepsOrientation.vertical, length: 40);
      final markers = find.byType(AnimatedContainer);
      final tops = [
        for (var i = 0; i < markers.evaluate().length; i++)
          tester.getRect(markers.at(i)).top,
      ]..sort();

      for (var i = 0; i < drawn.length; i++) {
        expect(drawn[i].bottom, closeTo(tops[i + 1] - 6, 1.5));
      }
    });

    testWidgets('a dot run splits the length between its two halves',
        (tester) async {
      final halves = await rails(
        tester,
        StepsOrientation.horizontal,
        length: 60,
        type: StepsType.dot,
      );

      // Each half is at least its share, and the two halves of a run meet, so
      // the line between two dots is one line however wide the titles are.
      expect(
        halves.map((r) => r.width),
        everyElement(greaterThanOrEqualTo(30 - 0.5)),
      );
      for (var i = 1; i < halves.length; i += 2) {
        expect(halves[i].left, closeTo(halves[i - 1].right, 0.5));
      }
    });

    testWidgets('fixed rails make the run scroll rather than squeeze',
        (tester) async {
      await rails(tester, StepsOrientation.horizontal, length: 400);
      expect(find.byType(SingleChildScrollView), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('a caller who names a placement keeps it, however narrow',
      (tester) async {
    // The run only decides for itself where nobody has decided for it.
    await tester.pumpWidget(
      _host(
        const SizedBox(
          width: 300,
          child: Steps(
            responsive: false,
            titlePlacement: StepTitlePlacement.horizontal,
            current: 1,
            items: [
              StepItem(title: Text('Cart')),
              StepItem(title: Text('Delivery')),
              StepItem(title: Text('Payment')),
            ],
          ),
        ),
      ),
    );

    final marker = tester.getRect(find.byType(AnimatedContainer).first);
    expect(tester.getRect(find.text('Cart')).left, greaterThan(marker.right));
  });

  group('Vertical panels', () {
    Widget stretched(List<StepItem> items) => _host(
          SizedBox(
            width: 700,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Steps(
                  type: StepsType.panel,
                  orientation: StepsOrientation.vertical,
                  current: 1,
                  items: items,
                ),
              ],
            ),
          ),
        );

    testWidgets('are as wide as the widest of them, not as the page',
        (tester) async {
      await tester.pumpWidget(
        stretched(const [
          StepItem(title: Text('Cart'), content: Text('3 items')),
          StepItem(title: Text('Delivery'), content: Text('Pick a date')),
          StepItem(title: Text('Payment')),
        ]),
      );

      final strip = tester.getRect(find.byType(IntrinsicWidth).first);
      expect(
        strip.width,
        lessThan(400),
        reason: 'a stretch parent must not blow one panel across the page',
      );

      // And they are all the same width, as they are across the page.
      final lefts = ['Cart', 'Delivery', 'Payment']
          .map((s) => tester.getRect(find.text(s)).left)
          .toSet();
      expect(lefts.length, 1);
    });

    testWidgets('keep the floor when their text is tiny', (tester) async {
      await tester.pumpWidget(
        stretched(const [
          StepItem(title: Text('A')),
          StepItem(title: Text('B')),
        ]),
      );

      expect(
        tester.getRect(find.byType(IntrinsicWidth).first).width,
        greaterThanOrEqualTo(160),
      );
    });
  });

  group('Panel size', () {
    Future<Rect> strip(
      WidgetTester tester, {
      required StepsOrientation orientation,
      required List<StepItem> items,
      double? width,
      double? height,
      double page = 700,
    }) async {
      await tester.pumpWidget(
        _host(
          SizedBox(
            width: page,
            child: Steps(
              type: StepsType.panel,
              orientation: orientation,
              current: 1,
              token: StepsToken(panelWidth: width, panelHeight: height),
              items: items,
            ),
          ),
        ),
      );
      return tester.getRect(find.byType(IntrinsicWidth).first);
    }

    const short = [
      StepItem(title: Text('A')),
      StepItem(title: Text('B')),
      StepItem(title: Text('C')),
    ];
    const long = [
      StepItem(title: Text('Cart'), content: Text('3 items 4200 today')),
      StepItem(title: Text('Delivery'), content: Text('Pick a date')),
      StepItem(title: Text('Payment'), content: Text('Card')),
    ];

    testWidgets('panels take their size from the longest text', (tester) async {
      final tight = await strip(
        tester,
        orientation: StepsOrientation.horizontal,
        items: short,
      );
      final roomy = await strip(
        tester,
        orientation: StepsOrientation.horizontal,
        items: long,
      );
      expect(
        roomy.width,
        greaterThan(tight.width),
        reason: 'longer content asks for more room',
      );

      // And the panels are equal to each other: the
      // longest one sets the width for all.
      final lefts = ['Cart', 'Delivery', 'Payment']
          .map((s) => tester.getRect(find.text(s)).left)
          .toList();
      // The first panel has no arrow notched into its start, so its
      // neighbour's text sits one arrow further along than the next pair's.
      expect(lefts[1] - lefts[0], closeTo((lefts[2] - lefts[1]) + 16, 1));
    });

    testWidgets('a named width is kept, whatever room there is',
        (tester) async {
      for (final orientation in StepsOrientation.values) {
        final across = await strip(
          tester,
          orientation: orientation,
          items: long,
          width: 120,
        );
        expect(
          across.width,
          closeTo(orientation == StepsOrientation.horizontal ? 360 : 120, 1),
          reason: '$orientation',
        );
      }
    });

    testWidgets('a named height is kept in both orientations', (tester) async {
      final across = await strip(
        tester,
        orientation: StepsOrientation.horizontal,
        items: long,
        height: 140,
      );
      expect(across.height, closeTo(140, 1));

      final down = await strip(
        tester,
        orientation: StepsOrientation.vertical,
        items: long,
        height: 140,
      );
      expect(down.height, closeTo(140 * 3, 1));
    });
  });

  group('Navigation size', () {
    Future<Rect> block(
      WidgetTester tester, {
      ControlSize size = SoftSize.middle,
      double? width,
      double? height,
    }) async {
      tester.view.physicalSize = const Size(1400, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        _host(
          SizedBox(
            width: 1200,
            child: Steps(
              type: StepsType.navigation,
              size: size,
              current: 1,
              token: StepsToken(itemWidth: width, itemHeight: height),
              items: const [
                StepItem(title: Text('Details'), subTitle: Text('00:02')),
                StepItem(title: Text('Review'), subTitle: Text('00:05')),
                StepItem(title: Text('Publish')),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      // The blocks; a marker is an AnimatedContainer too, and smaller.
      return _blockRects(tester).first;
    }

    testWidgets('the presets scale a block, marker and type together',
        (tester) async {
      final small = await block(tester, size: SoftSize.small);
      final middle = await block(tester);
      final large = await block(tester, size: SoftSize.large);

      expect(small.height, lessThan(middle.height));
      expect(large.height, greaterThan(middle.height));
    });

    testWidgets('a named width and height are kept', (tester) async {
      expect((await block(tester, width: 160)).width, closeTo(160, 0.5));
      expect((await block(tester, height: 80)).height, closeTo(80, 0.5));
    });

    testWidgets('left alone, blocks take their size from their text',
        (tester) async {
      // Equal to each other, and wide enough for the longest of them.
      await block(tester);
      final widths = _blockRects(tester).map((r) => r.width).toList();
      for (final w in widths) {
        expect(w, closeTo(widths.first, 0.5), reason: 'widths $widths');
      }
      expect(
        widths.first,
        greaterThan(tester.getRect(find.text('Details')).width),
      );
    });
  });

  testWidgets('rail insets can differ end to end', (tester) async {
    // A side left null keeps the component's own gap; only the named one moves.
    Future<Rect> railOf(RailInsets? insets) async {
      await tester.pumpWidget(
        _host(
          SizedBox(
            width: 700,
            child: Steps(
              current: 1,
              token: StepsToken(railInset: insets),
              items: const [
                StepItem(title: Text('One')),
                StepItem(title: Text('Two')),
              ],
            ),
          ),
        ),
      );
      final found = find.byWidgetPredicate(
        (w) => w is CustomPaint && w.painter is RailPainter,
      );
      final box = tester.getRect(found.first);
      final painter =
          tester.widget<CustomPaint>(found.first).painter as RailPainter;
      return Rect.fromLTRB(
        box.left + painter.startInset,
        box.top,
        box.right - painter.endInset,
        box.bottom,
      );
    }

    final byDefault = await railOf(null);
    final flushLeft = await railOf(const RailInsets.horizontal(left: 0));

    // The line now starts where the marker leaves off, and still stops short
    // of the next one by the gap it always had.
    expect(flushLeft.left, lessThan(byDefault.left));
    expect(flushLeft.right, closeTo(byDefault.right, 0.5));
  });

  group('maxCount', () {
    Future<List<String>> shown(
      WidgetTester tester, {
      required int total,
      required int current,
      int? maxCount,
      ValueChanged<int>? onChange,
      List<StepItem>? items,
    }) async {
      tester.view.physicalSize = const Size(1400, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        _host(
          SizedBox(
            width: 1200,
            child: Steps(
              maxCount: maxCount,
              current: current,
              responsive: false,
              onChange: onChange,
              items: items ??
                  [
                    for (var i = 1; i <= total; i++)
                      StepItem(title: Text('Step $i')),
                  ],
            ),
          ),
        ),
      );

      return [
        for (var i = 1; i <= total; i++)
          if (find.text('Step $i').evaluate().isNotEmpty) '$i',
      ];
    }

    testWidgets('folds a long run, keeping the first, the last and the current',
        (tester) async {
      // The priority: current's neighbours first, then one in
      // from each end.
      expect(
        await shown(tester, total: 7, current: 0, maxCount: 5),
        ['1', '2', '6', '7'],
      );
      expect(
        await shown(tester, total: 7, current: 3, maxCount: 5),
        ['1', '4', '7'],
      );
      expect(
        await shown(tester, total: 7, current: 6, maxCount: 5),
        ['1', '2', '6', '7'],
      );
    });

    testWidgets('is ignored where it has nothing to fold', (tester) async {
      // Fits already.
      expect(
        (await shown(tester, total: 4, current: 1, maxCount: 5)).length,
        4,
      );
      // Below three there is no room for first, current and last, so the kit
      // leaves the run alone.
      expect(
        (await shown(tester, total: 7, current: 3, maxCount: 2)).length,
        7,
      );
    });

    testWidgets('taps report the caller\'s own indexes', (tester) async {
      var tapped = -1;
      await shown(
        tester,
        total: 7,
        current: 3,
        maxCount: 5,
        onChange: (i) => tapped = i,
      );

      await tester.tap(find.text('Step 7'));
      expect(tapped, 6, reason: 'the last step, not its place on screen');

      await tester.tap(find.text('Step 4'));
      expect(tapped, 3);
    });

    testWidgets('an ellipsis stands for the hidden steps and is inert',
        (tester) async {
      var tapped = -1;
      await shown(
        tester,
        total: 7,
        current: 3,
        maxCount: 5,
        onChange: (i) => tapped = i,
      );

      final dots = find.byWidgetPredicate(
        (w) =>
            w is CustomPaint &&
            w.painter.runtimeType.toString() == '_EllipsisPainter',
      );
      expect(dots, findsNWidgets(2), reason: 'one per hidden stretch');

      await tester.tap(dots.first);
      await tester.pump();
      expect(tapped, -1, reason: 'an ellipsis is not a step');
    });

    testWidgets('a hidden failure still colours its ellipsis', (tester) async {
      await shown(
        tester,
        total: 7,
        current: 6,
        maxCount: 5,
        items: [
          for (var i = 1; i <= 7; i++)
            StepItem(
              title: Text('Step $i'),
              // Step 4 fails, and it is one of the hidden ones.
              status: i == 4 ? StepStatus.error : null,
            ),
        ],
      );

      final marker = tester.widget<AnimatedContainer>(
        find
            .ancestor(
              of: find.byWidgetPredicate(
                (w) =>
                    w is CustomPaint &&
                    w.painter.runtimeType.toString() == '_EllipsisPainter',
              ),
              matching: find.byType(AnimatedContainer),
            )
            .first,
      );

      final fill = (marker.decoration! as BoxDecoration).color!;
      final error = ThemeData.light.token.error;
      expect(
        fill.toARGB32(),
        isNot(ThemeData.light.token.colorFillTertiary.toARGB32()),
      );
      expect(
        fill.toARGB32(),
        anyOf(error.bg.toARGB32(), error.base.toARGB32()),
      );
    });
  });

  group('Overflow: fold', () {
    Future<List<String>> run(
      WidgetTester tester, {
      required double width,
      StepsOverflow overflow = StepsOverflow.fold,
      int? maxCount,
      int total = 9,
    }) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        _host(
          SizedBox(
            width: width,
            child: Steps(
              overflow: overflow,
              maxCount: maxCount,
              current: 3,
              responsive: false,
              items: [
                for (var i = 1; i <= total; i++)
                  StepItem(title: Text('Step $i')),
              ],
            ),
          ),
        ),
      );

      return [
        for (var i = 1; i <= total; i++)
          if (find.text('Step $i').evaluate().isNotEmpty) '$i',
      ];
    }

    testWidgets('the narrower the run, the fewer steps it keeps',
        (tester) async {
      final roomy = await run(tester, width: 1200);
      final tight = await run(tester, width: 700);

      expect(roomy.length, lessThan(9), reason: 'nine will not fit 1200');
      expect(tight.length, lessThan(roomy.length));
      // Whatever it folds, the ends and the step in play stay.
      for (final shown in [roomy, tight]) {
        expect(shown, contains('1'));
        expect(shown, contains('4'));
        expect(shown, contains('9'));
      }
    });

    testWidgets('folding is instead of scrolling, not as well as',
        (tester) async {
      await run(tester, width: 700, overflow: StepsOverflow.scroll);
      expect(find.byType(SingleChildScrollView), findsOneWidget);

      await run(tester, width: 700);
      expect(find.byType(SingleChildScrollView), findsNothing);
    });

    testWidgets('a named maxCount still wins', (tester) async {
      final shown = await run(tester, width: 1200, maxCount: 3);
      expect(shown, ['1', '4', '9']);
    });

    testWidgets('a vertical run folds by the height it is given',
        (tester) async {
      await tester.pumpWidget(
        _host(
          SizedBox(
            height: 200,
            width: 400,
            child: Steps(
              overflow: StepsOverflow.fold,
              orientation: StepsOrientation.vertical,
              current: 3,
              items: [
                for (var i = 1; i <= 9; i++) StepItem(title: Text('Step $i')),
              ],
            ),
          ),
        ),
      );

      final shown = [
        for (var i = 1; i <= 9; i++)
          if (find.text('Step $i').evaluate().isNotEmpty) '$i',
      ];
      expect(shown.length, lessThan(9));
      expect(shown, containsAll(['1', '4', '9']));
    });
  });

  testWidgets('a rail keeps its length by giving up its gaps first',
      (tester) async {
    // A line squeezed to a stub reads as a speck, not a connection, so the
    // room at its ends goes first.
    const painter = RailPainter(
      axis: Axis.horizontal,
      thickness: 1,
      startInset: 16,
      endInset: 16,
      minLength: 32,
      segments: [
        RailSegment(start: 0, end: double.infinity, color: Color(0xFF000000)),
      ],
    );

    final drawn = <double>[];
    final canvas = _LineCanvas(drawn);

    // Roomy: the insets are kept in full.
    painter.paint(canvas, const Size(100, 2));
    expect(drawn.single, closeTo(100 - 32, 0.5));

    // Tight: 40 wide cannot hold 32 of line and 32 of gaps, so the gaps halve.
    drawn.clear();
    painter.paint(canvas, const Size(40, 2));
    expect(drawn.single, closeTo(32, 0.5));

    // Narrower than the minimum itself: all line, no gaps.
    drawn.clear();
    painter.paint(canvas, const Size(20, 2));
    expect(drawn.single, closeTo(20, 0.5));
  });

  group('A folded run reads true', () {
    Future<void> pump(
      WidgetTester tester, {
      StepsType type = StepsType.standard,
    }) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        _host(
          SizedBox(
            width: 1200,
            child: Steps(
              type: type,
              maxCount: 5,
              // Nothing finished, so every marker wears its number rather than a
              // tick.
              current: 0,
              responsive: false,
              items: [
                for (var i = 1; i <= 9; i++) StepItem(title: Text('Step $i')),
              ],
            ),
          ),
        ),
      );
    }

    testWidgets('a marker wears its step\'s number, not its place on screen',
        (tester) async {
      await pump(tester);

      // The last step is Step 9 and its circle says 9 — numbering by position
      // would have put a 5 beside that title.
      expect(find.text('9'), findsOneWidget);
      final marker = tester.getRect(find.text('9'));
      final title = tester.getRect(find.text('Step 9'));
      expect(
        marker.right,
        lessThanOrEqualTo(title.left + 1),
        reason: 'the 9 belongs to the step titled Step 9',
      );
      // Standing on the first step, the fold keeps 1 2 3 … 8 9.
      expect(
        marker.left,
        greaterThan(tester.getRect(find.text('Step 2')).left),
      );
    });

    testWidgets('an ellipsis in a dot run gets room to read as one',
        (tester) async {
      await pump(tester, type: StepsType.dot);

      final glyph = tester.getRect(
        find.byWidgetPredicate(
          (w) =>
              w is CustomPaint &&
              w.painter.runtimeType.toString() == '_EllipsisPainter',
        ),
      );

      // Three dots squeezed into a dot's own 8px slot came out as a smudge on
      // the rail; the marker is wider than a dot now.
      expect(glyph.width, greaterThan(12));
    });
  });

  test('a rail lands on the pixel grid, not across it', () {
    // A hairline centred on a whole coordinate straddles two rows of pixels
    // and is drawn as two half-strength lines — a pale line under a paler one.
    const painter = RailPainter(
      axis: Axis.horizontal,
      thickness: 1,
      segments: [
        RailSegment(start: 0, end: double.infinity, color: Color(0xFF000000)),
      ],
    );

    final rects = <Rect>[];
    painter.paint(_LineCanvas([], rects), const Size(100, 32));

    expect(rects.single.top, rects.single.top.roundToDouble());
    expect(rects.single.bottom, rects.single.bottom.roundToDouble());
    expect(rects.single.height, 1);
  });
  group('the rail keeps room for its own gaps', () {
    /// The drawn length of each rail in a vertical run, and the run's height.
    Future<(List<double> lines, double height)> run(
      WidgetTester tester,
      double inset,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 320,
              child: Steps(
                orientation: StepsOrientation.vertical,
                current: 1,
                items: const [
                  StepItem(title: Text('One')),
                  StepItem(title: Text('Two')),
                  StepItem(title: Text('Three')),
                ],
                token: StepsToken(railInset: RailInsets.all(inset)),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final lines = <double>[];
      for (final element in find.byType(CustomPaint).evaluate()) {
        final painter = (element.widget as CustomPaint).painter;
        if (painter is! RailPainter || painter.axis != Axis.vertical) continue;
        final slot = tester.getRect(find.byWidget(element.widget));
        lines.add(slot.height - painter.startInset - painter.endInset);
      }
      return (lines, tester.getRect(find.byType(Steps)).height);
    }

    testWidgets('a generous inset does not swallow the line', (tester) async {
      for (final inset in [0.0, 8.0, 16.0, 32.0, 64.0]) {
        final (lines, _) = await run(tester, inset);
        expect(lines, isNotEmpty, reason: 'inset $inset drew no rail');
        for (final line in lines) {
          // Taking only the leftover, a rail beside a short step had its whole
          // slot eaten by the gaps and came out negative — drawn as nothing,
          // which is why every inset past a small one looked alike.
          expect(
            line,
            greaterThan(0),
            reason: 'inset $inset left a line of $line',
          );
        }
      }
    });

    testWidgets('the run grows to make room for a wider gap', (tester) async {
      final (_, tight) = await run(tester, 0);
      final (_, roomy) = await run(tester, 32);
      // The line cannot shrink past its floor, so the step lengthens instead.
      expect(roomy, greaterThan(tight));
    });
  });
  group('a panel run floor', () {
    /// The width of the painted strip, which is what the floor decides once
    /// the panels have run out of room to share.
    Future<double> strip(
        WidgetTester tester, double width, double floor) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: AlignmentDirectional.topStart,
              child: SizedBox(
                width: width,
                child: Steps(
                  type: StepsType.panel,
                  current: 1,
                  items: const [
                    StepItem(title: Text('One')),
                    StepItem(title: Text('Two')),
                    StepItem(title: Text('Three')),
                  ],
                  token: StepsToken(panelMinWidth: floor),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      for (final element in find.byType(CustomPaint).evaluate()) {
        final painter = (element.widget as CustomPaint).painter;
        if (painter == null) continue;
        if (!painter.runtimeType.toString().contains('PanelStrip')) continue;
        return tester.getRect(find.byWidget(element.widget)).width;
      }
      throw StateError('no panel strip was painted');
    }

    testWidgets('raises the panels once the room runs out', (tester) async {
      // Three panels in three hundred pixels is a hundred each, under every
      // floor here, so each setting lifts them and the strip grows past the
      // box — which is what gives it something to scroll.
      final low = await strip(tester, 300, 100);
      final middling = await strip(tester, 300, 160);
      final high = await strip(tester, 300, 260);
      expect(middling, greaterThan(low));
      expect(high, greaterThan(middling));
      expect(low, greaterThanOrEqualTo(300));
    });

    testWidgets('does nothing where the panels are already wider', (
      tester,
    ) async {
      // Given room to share, the panels are past every floor on their own and
      // it has nothing to raise. A demo that shows the setting here looks
      // broken while behaving correctly.
      expect(
        await strip(tester, 900, 260),
        await strip(tester, 900, 100),
      );
    });
  });
}
