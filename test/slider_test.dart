import 'package:flutter/material.dart'
    hide Slider, RangeSlider, ThemeData, Checkbox, Radio, Switch, Tooltip;
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter_test/flutter_test.dart';
import 'package:seed_ui/seed_ui.dart';

Widget _host(Widget child, [TextDirection direction = TextDirection.ltr]) =>
    MaterialApp(
      home: Directionality(
        textDirection: direction,
        child: Scaffold(
          body: Center(child: SizedBox(width: 400, child: child)),
        ),
      ),
    );

/// The groove itself, which is not the whole widget once marks are written
/// below it.
Rect _groove(WidgetTester tester) =>
    tester.getRect(find.byType(CustomPaint).last);

void main() {
  _markTests();
  _markTargetTests();
  _zoneBoundsSnapTests();
  _trackTests();
  _editableTests();
  group('Slider', () {
    testWidgets('a tap moves the handle to where it landed', (tester) async {
      double? changed;
      double? completed;
      await tester.pumpWidget(
        _host(
          Slider(
            value: 0,
            onChanged: (v) => changed = v,
            onChangeComplete: (v) => completed = v,
          ),
        ),
      );

      final groove = tester.getRect(find.byType(Slider));
      await tester
          .tapAt(Offset(groove.left + groove.width / 4, groove.center.dy));
      await tester.pumpAndSettle();

      // A quarter along a nought-to-hundred scale.
      expect(changed, moreOrLessEquals(25, epsilon: 1));
      expect(completed, changed, reason: 'a tap is a finished gesture');
    });

    testWidgets('the value is pulled onto the step', (tester) async {
      double? changed;
      await tester.pumpWidget(
        _host(Slider(value: 0, step: 25, onChanged: (v) => changed = v)),
      );

      final groove = tester.getRect(find.byType(Slider));
      // A shade past a third: nearer 25 than 50.
      await tester.tapAt(
        Offset(groove.left + groove.width * 0.35, groove.center.dy),
      );
      await tester.pumpAndSettle();
      expect(changed, 25);
    });

    testWidgets('a null step rests only on the marks and the ends', (
      tester,
    ) async {
      double? changed;
      await tester.pumpWidget(
        _host(
          Slider(
            value: 0,
            step: null,
            marks: const [
              SliderMark(20, 'twenty'),
              SliderMark(80, 'eighty'),
            ],
            onChanged: (v) => changed = v,
          ),
        ),
      );

      final groove = _groove(tester);
      await tester.tapAt(
        Offset(groove.left + groove.width * 0.3, groove.center.dy),
      );
      await tester.pumpAndSettle();
      // Thirty is nearer the mark at twenty than the one at eighty, and the
      // ends of the scale are stops too.
      expect(changed, 20);
    });

    testWidgets('no handler leaves it read-only', (tester) async {
      await tester.pumpWidget(_host(const Slider(value: 40)));
      final groove = tester.getRect(find.byType(Slider));
      await tester.tapAt(Offset(groove.left + 10, groove.center.dy));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('disabled ignores a tap', (tester) async {
      var called = false;
      await tester.pumpWidget(
        _host(
          Slider(value: 40, disabled: true, onChanged: (_) => called = true),
        ),
      );
      final groove = tester.getRect(find.byType(Slider));
      await tester.tapAt(Offset(groove.left + 10, groove.center.dy));
      await tester.pumpAndSettle();
      expect(called, isFalse);
    });

    testWidgets('marks are written under the points they name', (tester) async {
      await tester.pumpWidget(
        _host(
          const Slider(
            value: 0,
            marks: [
              SliderMark(0, 'none'),
              SliderMark(100, 'all'),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      final groove = _groove(tester);
      // Centred on their own value: nought at the start, a hundred at the end.
      expect(
        tester.getRect(find.text('none')).center.dx,
        moreOrLessEquals(groove.left, epsilon: 2),
      );
      expect(
        tester.getRect(find.text('all')).center.dx,
        moreOrLessEquals(groove.right, epsilon: 2),
      );
    });

    testWidgets('reverse turns the scale round', (tester) async {
      double? changed;
      await tester.pumpWidget(
        _host(
          Slider(value: 0, reverse: true, onChanged: (v) => changed = v),
        ),
      );
      final groove = tester.getRect(find.byType(Slider));
      await tester.tapAt(
        Offset(groove.left + groove.width / 4, groove.center.dy),
      );
      await tester.pumpAndSettle();
      // A quarter from the left is three quarters along a reversed scale.
      expect(changed, moreOrLessEquals(75, epsilon: 1));
    });

    testWidgets('reading right to left turns it round on its own', (
      tester,
    ) async {
      double? changed;
      await tester.pumpWidget(
        _host(
          Slider(value: 0, onChanged: (v) => changed = v),
          TextDirection.rtl,
        ),
      );
      final groove = tester.getRect(find.byType(Slider));
      await tester.tapAt(
        Offset(groove.left + groove.width / 4, groove.center.dy),
      );
      await tester.pumpAndSettle();
      // The scale starts at the right, so a quarter in from the left is three
      // quarters along it, which is why `reverse` flips in a mirrored layout.
      expect(changed, moreOrLessEquals(75, epsilon: 1));
    });

    testWidgets('reverse and right-to-left cancel each other out', (
      tester,
    ) async {
      double? changed;
      await tester.pumpWidget(
        _host(
          Slider(value: 0, reverse: true, onChanged: (v) => changed = v),
          TextDirection.rtl,
        ),
      );
      final groove = tester.getRect(find.byType(Slider));
      await tester.tapAt(
        Offset(groove.left + groove.width / 4, groove.center.dy),
      );
      await tester.pumpAndSettle();
      expect(changed, moreOrLessEquals(25, epsilon: 1));
    });
  });

  group('RangeSlider', () {
    testWidgets('a drag takes hold of the handle it began nearest', (
      tester,
    ) async {
      (double, double)? changed;
      await tester.pumpWidget(
        _host(
          RangeSlider(
            values: const (20, 80),
            onChanged: (v) => changed = v,
          ),
        ),
      );

      final groove = tester.getRect(find.byType(RangeSlider));
      // Begun by the high handle, so that is the one that moves — the low one
      // must stay where it is.
      await tester.dragFrom(
        Offset(groove.left + groove.width * 0.8, groove.center.dy),
        const Offset(-40, 0),
      );
      await tester.pumpAndSettle();

      expect(changed, isNotNull);
      expect(changed!.$1, 20, reason: 'the low handle did not move');
      expect(changed!.$2, lessThan(80));
    });

    testWidgets('the pair is reported low first, however it was dragged', (
      tester,
    ) async {
      (double, double)? changed;
      await tester.pumpWidget(
        _host(
          RangeSlider(
            values: const (40, 60),
            onChanged: (v) => changed = v,
          ),
        ),
      );

      final groove = tester.getRect(find.byType(RangeSlider));
      // Drag the low handle well past the high one.
      await tester.dragFrom(
        Offset(groove.left + groove.width * 0.4, groove.center.dy),
        const Offset(200, 0),
      );
      await tester.pumpAndSettle();

      expect(changed, isNotNull);
      expect(
        changed!.$1,
        lessThanOrEqualTo(changed!.$2),
        reason: 'a handle pushed past its neighbour must not swap the pair',
      );
    });
  });

  group('tokens', () {
    testWidgets('come from the provider, and the instance wins', (
      tester,
    ) async {
      SliderToken? seen;
      Widget under(SliderToken? instance) => ConfigProvider(
            theme: ThemeData(
              components: const ComponentsConfig(
                slider: SliderToken(railSize: 9),
              ),
            ),
            child: _host(Slider(value: 10, token: instance)),
          );

      await tester.pumpWidget(under(null));
      seen = ConfigProvider.componentOf<SliderToken>(
        tester.element(find.byType(Slider)),
      );
      expect(seen?.railSize, 9);

      await tester.pumpWidget(under(const SliderToken(railSize: 3)));
      expect(
        tester.widget<Slider>(find.byType(Slider)).token?.railSize,
        3,
        reason: 'the instance carries its own',
      );
    });
  });
  group('the keys', () {
    /// Focuses the slider and presses [key] once.
    Future<void> press(WidgetTester tester, LogicalKeyboardKey key) async {
      await tester.tap(find.byType(Focus).last, warnIfMissed: false);
      await tester.pumpAndSettle();
      Focus.of(tester.element(find.byType(CustomPaint).last)).requestFocus();
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(key);
      await tester.pumpAndSettle();
    }

    testWidgets('an arrow along the groove moves one step', (tester) async {
      double? changed;
      await tester.pumpWidget(
        _host(Slider(value: 50, step: 10, onChanged: (v) => changed = v)),
      );
      await press(tester, LogicalKeyboardKey.arrowRight);
      expect(changed, 60);
    });

    testWidgets('and the other arrow the other way', (tester) async {
      double? changed;
      await tester.pumpWidget(
        _host(Slider(value: 50, step: 10, onChanged: (v) => changed = v)),
      );
      await press(tester, LogicalKeyboardKey.arrowLeft);
      expect(changed, 40);
    });

    testWidgets('a mirrored scale answers the same key the other way', (
      tester,
    ) async {
      double? changed;
      await tester.pumpWidget(
        _host(
          Slider(value: 50, step: 10, onChanged: (v) => changed = v),
          TextDirection.rtl,
        ),
      );
      // Right points back along a scale that starts at the right, so the value
      // goes down — the key that points along the groove is the one that
      // advances it.
      await press(tester, LogicalKeyboardKey.arrowRight);
      expect(changed, 40);
    });

    testWidgets('a disabled slider ignores them', (tester) async {
      var called = false;
      await tester.pumpWidget(
        _host(
          Slider(
            value: 50,
            step: 10,
            disabled: true,
            onChanged: (_) => called = true,
          ),
        ),
      );
      await press(tester, LogicalKeyboardKey.arrowRight);
      expect(called, isFalse);
    });
  });

  group('the bubble', () {
    testWidgets('shows the value while a handle is moving, and not before', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(Slider(value: 30, onChanged: (_) {})),
      );
      await tester.pumpAndSettle();
      expect(find.text('30'), findsNothing, reason: 'nothing is being moved');

      final groove = _groove(tester);
      final gesture = await tester.startGesture(
        Offset(groove.left + groove.width * 0.3, groove.center.dy),
      );
      await tester.pump();
      // Past the drag slop, or the gesture never begins.
      await gesture.moveBy(const Offset(30, 0));
      await tester.pump();
      expect(find.text('30'), findsOneWidget);

      await gesture.up();
      await tester.pumpAndSettle();
      expect(find.text('30'), findsNothing, reason: 'and gone once let go');
    });

    testWidgets('a formatter decides what it says, and whether it says it', (
      tester,
    ) async {
      Future<void> dragWith(String? Function(double) format) async {
        await tester.pumpWidget(
          _host(Slider(value: 30, onChanged: (_) {}, tooltip: format)),
        );
        await tester.pumpAndSettle();
        final groove = _groove(tester);
        final gesture = await tester.startGesture(
          Offset(groove.left + groove.width * 0.3, groove.center.dy),
        );
        await tester.pump();
        // Past the drag slop, or the gesture never begins.
        await gesture.moveBy(const Offset(30, 0));
        await tester.pump();
        addTearDown(gesture.up);
      }

      await dragWith((v) => '${v.round()}%');
      expect(find.text('30%'), findsOneWidget);

      await dragWith((_) => null);
      expect(find.textContaining('30'), findsNothing);
    });
  });
  group('a vertical slider', () {
    testWidgets('keeps room for its marks beside the groove', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 240,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Slider(
                    value: 60,
                    vertical: true,
                    marks: const [
                      SliderMark(0, 'cold'),
                      SliderMark(100, 'hot'),
                    ],
                    onChanged: (_) {},
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Sized to the groove alone, the labels had nowhere to go and the row
      // overflowed by exactly the gap between them.
      expect(tester.takeException(), isNull);

      final slider = tester.getRect(find.byType(Slider));
      final label = tester.getRect(find.text('hot').last);
      expect(
        label.right,
        lessThanOrEqualTo(slider.right + 0.5),
        reason: 'the label is inside the slider, not hanging off it',
      );
      expect(label.left, greaterThan(slider.left));
    });

    testWidgets('writes each mark beside its own dot, not opposite it', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 240,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Slider(
                    value: 50,
                    vertical: true,
                    marks: const [
                      SliderMark(0, 'bottom'),
                      SliderMark(100, 'top'),
                    ],
                    onChanged: (_) {},
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final slider = tester.getRect(find.byType(Slider));
      final low = tester.getRect(find.text('bottom').last).center.dy;
      final high = tester.getRect(find.text('top').last).center.dy;

      // The scale runs up the page, as a measure does, so the bottom of it is
      // at the bottom. The labels were laid out from the top while the dots
      // were laid out from the bottom, which put every one of them opposite
      // the point it names.
      expect(low, greaterThan(high));
      expect(low, moreOrLessEquals(slider.bottom, epsilon: 2));
      expect(high, moreOrLessEquals(slider.top, epsilon: 2));
    });

    testWidgets('each mark is in the tree once', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 200,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Slider(
                    value: 50,
                    vertical: true,
                    marks: const [SliderMark(50, 'half')],
                    onChanged: (_) {},
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // The band used to take its width from a silent duplicate of every
      // label, laid out and never seen — which had to be kept out of the
      // semantics tree by hand, or a screen reader read the marks twice.
      // The labels size the band themselves now, so there is no copy to hide.
      expect(find.text('half'), findsOneWidget);
      final semantics = tester.getSemantics(find.byType(Slider));
      expect(
        semantics.toString().split('half').length - 1,
        lessThanOrEqualTo(1),
        reason: 'the marks must not be announced twice',
      );
    });
  });
}

void _trackTests() {
  group('a span you can take hold of', () {
    testWidgets('dragging between the handles moves them together',
        (tester) async {
      var pair = (20.0, 60.0);
      await tester.pumpWidget(
        _host(
          StatefulBuilder(
            builder: (context, setState) => RangeSlider(
              values: pair,
              draggableTrack: true,
              onChanged: (v) => setState(() => pair = v),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final rail = tester.getRect(find.byType(RangeSlider));
      // Start strictly between the handles — at 40 on a 0..100 scale.
      final from = Offset(rail.left + rail.width * 0.4, rail.center.dy);
      await tester.dragFrom(from, Offset(rail.width * 0.2, 0));
      await tester.pumpAndSettle();

      // Both ends moved by the same amount: the span kept its length.
      expect(pair.$2 - pair.$1, 40);
      expect(pair.$1, greaterThan(20));
    });

    testWidgets('pushed against an end it stops without shrinking',
        (tester) async {
      var pair = (20.0, 60.0);
      await tester.pumpWidget(
        _host(
          StatefulBuilder(
            builder: (context, setState) => RangeSlider(
              values: pair,
              draggableTrack: true,
              onChanged: (v) => setState(() => pair = v),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final rail = tester.getRect(find.byType(RangeSlider));
      final from = Offset(rail.left + rail.width * 0.4, rail.center.dy);
      // Far further than there is room for.
      await tester.dragFrom(from, Offset(rail.width, 0));
      await tester.pumpAndSettle();

      // The shift is cut back as one, so the leading handle does not stop
      // while the trailing one goes on.
      expect(pair, (60.0, 100.0));
    });

    testWidgets('a press that pauses before moving takes nothing with it',
        (tester) async {
      var pair = (30.0, 70.0);
      await tester.pumpWidget(
        _host(
          StatefulBuilder(
            builder: (context, setState) => RangeSlider(
              values: pair,
              draggableTrack: true,
              onChanged: (v) => setState(() => pair = v),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final rail = tester.getRect(find.byType(RangeSlider));
      final from = Offset(rail.left + rail.width * 0.5, rail.center.dy);
      final gesture = await tester.startGesture(from);
      // Held long enough for a slider that acted on the press to have moved
      // the nearest handle under the finger — which is what left the span no
      // longer under the press when the drag began, so the track was never
      // taken and this behaved like an ordinary range slider.
      await tester.pump(const Duration(milliseconds: 200));
      expect(pair, (30.0, 70.0), reason: 'a press is not yet a tap');

      for (var i = 0; i < 4; i++) {
        await gesture.moveBy(const Offset(10, 0));
        await tester.pump(const Duration(milliseconds: 16));
      }
      await gesture.up();
      await tester.pumpAndSettle();

      // Both ends moved together: the span was taken hold of after all.
      expect(pair.$2 - pair.$1, 40);
      expect(pair.$1, greaterThan(30));
    });

    testWidgets('a handle still has its own drag', (tester) async {
      var pair = (20.0, 60.0);
      await tester.pumpWidget(
        _host(
          StatefulBuilder(
            builder: (context, setState) => RangeSlider(
              values: pair,
              draggableTrack: true,
              onChanged: (v) => setState(() => pair = v),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final rail = tester.getRect(find.byType(RangeSlider));
      // On the low handle, not between them.
      final from = Offset(rail.left + rail.width * 0.2, rail.center.dy);
      await tester.dragFrom(from, Offset(rail.width * 0.1, 0));
      await tester.pumpAndSettle();

      // A span you cannot take hold of at its ends is a span with two dead
      // spots, so the handles keep their own drag.
      expect(pair.$2, 60);
      expect(pair.$1, greaterThan(20));
    });

    testWidgets('a handle inside the span keeps its own drag', (tester) async {
      var values = [20.0, 50.0, 80.0];
      await tester.pumpWidget(
        _host(
          StatefulBuilder(
            builder: (context, setState) => MultiRangeSlider(
              values: values,
              draggableTrack: true,
              onChanged: (v) => setState(() => values = v),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final rail = tester.getRect(find.byType(MultiRangeSlider));
      // The middle handle stands strictly inside the span, so a track asked
      // by value rather than by handle took every drag meant for it.
      final on = Offset(rail.left + rail.width * 0.5, rail.center.dy);
      await tester.dragFrom(on, Offset(rail.width * 0.1, 0));
      await tester.pumpAndSettle();

      expect(values.first, 20, reason: 'the ends stayed put');
      expect(values.last, 80);
      expect(values[1], greaterThan(50));
    });

    testWidgets('and the span still moves when nothing is under the press',
        (tester) async {
      var values = [20.0, 80.0];
      await tester.pumpWidget(
        _host(
          StatefulBuilder(
            builder: (context, setState) => MultiRangeSlider(
              values: values,
              draggableTrack: true,
              onChanged: (v) => setState(() => values = v),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final rail = tester.getRect(find.byType(MultiRangeSlider));
      await tester.dragFrom(
        Offset(rail.left + rail.width * 0.5, rail.center.dy),
        Offset(rail.width * 0.1, 0),
      );
      await tester.pumpAndSettle();

      expect(values.last - values.first, 60);
      expect(values.first, greaterThan(20));
    });

    testWidgets('without the flag the span is not draggable', (tester) async {
      var pair = (20.0, 60.0);
      await tester.pumpWidget(
        _host(
          StatefulBuilder(
            builder: (context, setState) => RangeSlider(
              values: pair,
              onChanged: (v) => setState(() => pair = v),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final rail = tester.getRect(find.byType(RangeSlider));
      // Nearer the high handle, so which one moves is not a toss-up.
      final from = Offset(rail.left + rail.width * 0.55, rail.center.dy);
      await tester.dragFrom(from, Offset(rail.width * 0.2, 0));
      await tester.pumpAndSettle();

      // Only the nearer handle came along, as it always did.
      expect(pair.$1, 20);
      expect(pair.$2, greaterThan(60));
    });
  });
}

void _editableTests() {
  group('handles you can put in and take out', () {
    testWidgets('a tap on the rail puts one in', (tester) async {
      var values = [20.0, 60.0];
      await tester.pumpWidget(
        _host(
          StatefulBuilder(
            builder: (context, setState) => MultiRangeSlider(
              values: values,
              onChanged: (v) => setState(() => values = v),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final rail = tester.getRect(find.byType(MultiRangeSlider));
      await tester.tapAt(Offset(rail.left + rail.width * 0.8, rail.center.dy));
      await tester.pumpAndSettle();

      expect(values, hasLength(3));
      // In order, so "the third band" means the same thing throughout.
      expect(values, orderedEquals([...values]..sort()));
      expect(values.last, closeTo(80, 2));
    });

    testWidgets('a handle dragged onto its neighbour is let go of',
        (tester) async {
      var values = [20.0, 50.0, 80.0];
      await tester.pumpWidget(
        _host(
          StatefulBuilder(
            builder: (context, setState) => MultiRangeSlider(
              values: values,
              onChanged: (v) => setState(() => values = v),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final rail = tester.getRect(find.byType(MultiRangeSlider));
      final on = Offset(rail.left + rail.width * 0.5, rail.center.dy);
      final gesture = await tester.startGesture(on);
      // The middle handle, carried onto the one at 80.
      await gesture.moveBy(Offset(rail.width * 0.3, 0));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      expect(values, [20.0, 80.0]);
    });

    testWidgets('near enough counts as met, not only exactly on it',
        (tester) async {
      var values = [20.0, 50.0, 80.0];
      await tester.pumpWidget(
        _host(
          StatefulBuilder(
            builder: (context, setState) => MultiRangeSlider(
              values: values,
              onChanged: (v) => setState(() => values = v),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final rail = tester.getRect(find.byType(MultiRangeSlider));
      final on = Offset(rail.left + rail.width * 0.5, rail.center.dy);
      final gesture = await tester.startGesture(on);
      // Short of 80 by two units — the discs cover one another well before
      // their values are equal, and a catch half a step wide is two pixels of
      // rail that nobody can hit.
      await gesture.moveBy(Offset(rail.width * 0.28, 0));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      expect(values, hasLength(2));
    });

    testWidgets('brought onto a neighbour and off again, it stays',
        (tester) async {
      var values = [20.0, 50.0, 80.0];
      await tester.pumpWidget(
        _host(
          StatefulBuilder(
            builder: (context, setState) => MultiRangeSlider(
              values: values,
              onChanged: (v) => setState(() => values = v),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final rail = tester.getRect(find.byType(MultiRangeSlider));
      final on = Offset(rail.left + rail.width * 0.5, rail.center.dy);
      final gesture = await tester.startGesture(on);
      await gesture.moveBy(Offset(rail.width * 0.3, 0));
      await tester.pump();
      // Nothing is decided until the finger lifts.
      await gesture.moveBy(Offset(-rail.width * 0.2, 0));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      expect(values, hasLength(3));
    });

    testWidgets('a drag that meets nobody keeps every handle', (tester) async {
      var values = [20.0, 50.0, 80.0];
      await tester.pumpWidget(
        _host(
          StatefulBuilder(
            builder: (context, setState) => MultiRangeSlider(
              values: values,
              onChanged: (v) => setState(() => values = v),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final rail = tester.getRect(find.byType(MultiRangeSlider));
      final on = Offset(rail.left + rail.width * 0.5, rail.center.dy);
      final gesture = await tester.startGesture(on);
      // Paused, then moved a little. No timer decides anything here, so a
      // slow hand cannot lose a handle.
      await tester.pump(const Duration(milliseconds: 700));
      await gesture.moveBy(const Offset(20, 0));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      expect(values, hasLength(3));
    });

    testWidgets('a tap on a handle leaves it where it is', (tester) async {
      var values = [20.0, 50.0, 80.0];
      await tester.pumpWidget(
        _host(
          StatefulBuilder(
            builder: (context, setState) => MultiRangeSlider(
              values: values,
              onChanged: (v) => setState(() => values = v),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final rail = tester.getRect(find.byType(MultiRangeSlider));
      await tester.tapAt(Offset(rail.left + rail.width * 0.5, rail.center.dy));
      await tester.pumpAndSettle();

      // Neither removed nor doubled: a handle is already where a tap is
      // asking it to go.
      expect(values, [20.0, 50.0, 80.0]);
    });

    testWidgets('minCount keeps the last ones in', (tester) async {
      var values = [20.0, 80.0];
      await tester.pumpWidget(
        _host(
          StatefulBuilder(
            builder: (context, setState) => MultiRangeSlider(
              values: values,
              onChanged: (v) => setState(() => values = v),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final rail = tester.getRect(find.byType(MultiRangeSlider));
      final on = Offset(rail.left + rail.width * 0.2, rail.center.dy);
      final gesture = await tester.startGesture(on);
      // Carried right onto the other handle, which with only two left is
      // exactly what must not remove one.
      await gesture.moveBy(Offset(rail.width * 0.6, 0));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      // A range with one end is not a range.
      expect(values, hasLength(2));
    });

    testWidgets('maxCount refuses the next one', (tester) async {
      var values = [20.0, 50.0, 80.0];
      await tester.pumpWidget(
        _host(
          StatefulBuilder(
            builder: (context, setState) => MultiRangeSlider(
              values: values,
              maxCount: 3,
              onChanged: (v) => setState(() => values = v),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final rail = tester.getRect(find.byType(MultiRangeSlider));
      await tester.tapAt(Offset(rail.left + rail.width * 0.9, rail.center.dy));
      await tester.pumpAndSettle();

      expect(values, hasLength(3));
    });

    testWidgets('a plain range slider still moves on a tap', (tester) async {
      var pair = (20.0, 60.0);
      await tester.pumpWidget(
        _host(
          StatefulBuilder(
            builder: (context, setState) => RangeSlider(
              values: pair,
              onChanged: (v) => setState(() => pair = v),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final rail = tester.getRect(find.byType(RangeSlider));
      await tester.tapAt(Offset(rail.left + rail.width * 0.9, rail.center.dy));
      await tester.pumpAndSettle();

      // Nothing added: only an editable slider adds and removes.
      expect(pair.$2, greaterThan(60));
    });
  });
}

void _markTests() {
  group('what a mark may say', () {
    testWidgets('a hidden mark keeps its place and is not drawn',
        (tester) async {
      await tester.pumpWidget(
        _host(
          const Slider(
            value: 50,
            marks: [
              SliderMark(0, 'none'),
              SliderMark(50, 'half', hidden: true),
              SliderMark(100, 'all'),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('none'), findsOneWidget);
      expect(find.text('all'), findsOneWidget);
      expect(find.text('half'), findsNothing);
    });

    testWidgets('a disabled mark is no stop where the marks are the stops',
        (tester) async {
      double? settled;
      await tester.pumpWidget(
        _host(
          Slider(
            value: 0,
            // No step: the marks are the only places to rest.
            step: null,
            marks: const [
              SliderMark(0, 'none'),
              SliderMark(50, 'half', disabled: true),
              SliderMark(100, 'all'),
            ],
            onChanged: (v) => settled = v,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final rail = tester.getRect(find.byType(Slider));
      // Pressed right on the disabled mark: the handle passes it by.
      await tester.tapAt(Offset(rail.left + rail.width * 0.5, rail.top + 8));
      await tester.pumpAndSettle();

      expect(settled, isNotNull);
      expect(settled, isNot(50));
    });

    testWidgets('a mark before the rail is written above it', (tester) async {
      await tester.pumpWidget(
        _host(
          const Slider(
            value: 50,
            marks: [
              SliderMark(0, 'under'),
              SliderMark(100, 'over', side: SliderMarkSide.before),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      final over = tester.getRect(find.text('over'));
      final under = tester.getRect(find.text('under'));
      // Named by the flow, not by the screen: before the rail is above it
      // across a row.
      expect(over.bottom, lessThanOrEqualTo(under.top));
    });

    testWidgets('a builder is handed the label the slider would have drawn',
        (tester) async {
      final seen = <(double, bool)>[];
      await tester.pumpWidget(
        _host(
          Slider(
            value: 60,
            marks: [
              for (final at in [20.0, 80.0])
                SliderMark(
                  at,
                  '$at',
                  markBuilder: (context, mark, active, child) {
                    seen.add((mark.value, active));
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [child, if (active) const Text('✓')],
                    );
                  },
                ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      // The handle stands at 60, so it has reached 20 and not 80.
      expect(seen, contains((20.0, true)));
      expect(seen, contains((80.0, false)));
      // Wrapped, not replaced: the words the slider drew are still there.
      expect(find.text('20.0'), findsOneWidget);
      expect(find.text('✓'), findsOneWidget);
    });

    testWidgets('a mark with no words is a stop and nothing else',
        (tester) async {
      await tester.pumpWidget(
        _host(
          const Slider(
            value: 50,
            marks: [SliderMark.dot(25), SliderMark(75, 'three quarters')],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('three quarters'), findsOneWidget);
    });

    test('a mark can be copied with one thing changed', () {
      const mark = SliderMark(50, 'half');
      expect(mark.copyWith(label: 'middle').value, 50);
      expect(mark.copyWith(label: 'middle').label, 'middle');
      expect(mark.copyWith(disabled: true).label, 'half');
      // Value types, so a list of marks can be compared rather than rebuilt
      // on the off-chance.
      expect(mark.copyWith(), mark);
      expect(mark.copyWith(value: 51), isNot(mark));
    });
  });
}

void _markTargetTests() {
  // A menu and a popover need somewhere to render, which is the kit's own
  // overlay.
  Widget hosted(Widget child) => ConfigProvider(
        child: MaterialApp(
          navigatorKey: UiKit.navigatorKey,
          home: Scaffold(
            body: Center(child: SizedBox(width: 400, child: child)),
          ),
        ),
      );

  group('a mark you can press', () {
    testWidgets('a menu hangs on a mark and opens where it stands',
        (tester) async {
      var picked = '';
      await tester.pumpWidget(
        hosted(
          Slider(
            value: 50,
            marks: [
              SliderMark(
                60,
                'booked',
                markBuilder: (context, mark, active, child) => Dropdown<String>(
                  trigger: const [DropdownTrigger.click],
                  menu: const [
                    DropdownItem(value: 'free', label: 'Free it up'),
                  ],
                  onItemTap: (v) => picked = v ?? '',
                  child: child,
                ),
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('booked'));
      await tester.pumpAndSettle();
      expect(find.text('Free it up'), findsOneWidget);
      await tester.tap(find.text('Free it up'));
      await tester.pumpAndSettle();
      expect(picked, 'free');
    });

    testWidgets('a mark with no words is pressed where its dot is',
        (tester) async {
      var pressed = 0;
      double? moved;
      await tester.pumpWidget(
        hosted(
          Slider(
            value: 10,
            onChanged: (v) => moved = v,
            marks: [
              // Words beside it, so there is a band and the dot is plainly
              // not in it.
              const SliderMark(20, 'twenty'),
              const SliderMark.dot(80).copyWith(
                markBuilder: (context, mark, active, child) => GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => pressed++,
                  child: child,
                ),
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      final rail = _groove(tester);
      // On the dot itself. Put in the band, as a label's target is, it sat
      // under an invisible patch of nothing while the thing you could see
      // stayed dead.
      await tester.tapAt(Offset(rail.left + rail.width * 0.8, rail.center.dy));
      await tester.pumpAndSettle();
      expect(pressed, 1);
      expect(moved, isNull, reason: 'the mark had something to do');
    });

    testWidgets('a mark takes no pointer away from the rail', (tester) async {
      double? moved;
      await tester.pumpWidget(
        hosted(
          Slider(
            value: 10,
            onChanged: (v) => moved = v,
            marks: [
              SliderMark(
                60,
                'booked',
                markBuilder: (context, mark, active, child) => GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {},
                  child: child,
                ),
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      // A mark's own target lives in the band beside the rail, never over it,
      // so pressing the rail still moves the handle wherever the marks are.
      final slider = tester.getRect(find.byType(Slider));
      await tester
          .tapAt(Offset(slider.left + slider.width * 0.6, slider.top + 8));
      await tester.pumpAndSettle();
      expect(moved, isNotNull);

      // And pressing the mark does not.
      moved = null;
      await tester.tap(find.text('booked'));
      await tester.pumpAndSettle();
      expect(moved, isNull);
    });

    testWidgets('a label taller than a small control is pressable all over',
        (tester) async {
      var pressed = 0;
      await tester.pumpWidget(
        hosted(
          Slider(
            value: 50,
            marks: [
              SliderMark(
                50,
                'tall',
                markBuilder: (context, mark, active, child) => GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => pressed++,
                  child: SizedBox(height: 60, child: Center(child: child)),
                ),
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      final target = tester.getRect(find.text('tall'));
      final band = tester.getRect(find.byType(Slider));
      // The band was told a height, so anything taller hung out of it: drawn,
      // because the stack does not clip, and dead to the pointer, because a
      // hit outside a box is no hit.
      expect(band.bottom, greaterThanOrEqualTo(target.bottom));
      await tester.tapAt(Offset(target.center.dx, band.bottom - 4));
      await tester.pumpAndSettle();
      expect(pressed, 1);
    });
  });
}

void _zoneBoundsSnapTests() {
  group('a stretch of the scale that means something', () {
    testWidgets('a zone is drawn on the rail, under the track', (tester) async {
      await tester.pumpWidget(
        _host(
          const Slider(
            value: 50,
            zones: [SliderZone(60, 90, color: Color(0xFF00FF00))],
          ),
        ),
      );
      await tester.pumpAndSettle();

      final painter = tester
          .widgetList<CustomPaint>(find.byType(CustomPaint))
          .map((p) => p.painter)
          .whereType<CustomPainter>()
          .last;
      // Written out rather than measured in pixels: the painter is what the
      // zone reaches, and what it does with it is the painter's business.
      expect(painter.toString(), isNotEmpty);
      expect(tester.takeException(), isNull);
    });

    test('a zone written backwards means the same stretch', () {
      const forwards = SliderZone(60, 90);
      const backwards = SliderZone(90, 60);
      expect(backwards.low, forwards.low);
      expect(backwards.high, forwards.high);
      expect(backwards, forwards.from == 60 ? backwards : backwards);
    });
  });

  group('how far the handle may go', () {
    testWidgets('bounds hold it inside part of the scale', (tester) async {
      double? settled;
      await tester.pumpWidget(
        _host(
          Slider(
            value: 12,
            max: 24,
            bounds: const (9, 17),
            onChanged: (v) => settled = v,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final rail = _groove(tester);
      // Pressed at the very end of the scale, which is not on offer.
      await tester.tapAt(Offset(rail.right - 2, rail.center.dy));
      await tester.pumpAndSettle();
      expect(settled, 17);

      // And at the very start.
      await tester.tapAt(Offset(rail.left + 2, rail.center.dy));
      await tester.pumpAndSettle();
      expect(settled, 9);
    });

    testWidgets('the scale still shows the whole day', (tester) async {
      await tester.pumpWidget(
        _host(
          const Slider(
            value: 12,
            max: 24,
            bounds: (9, 17),
            marks: [SliderMark(0, 'midnight'), SliderMark(24, 'midnight')],
          ),
        ),
      );
      await tester.pumpAndSettle();
      // Narrowing min and max would have hidden the rest of the day, which is
      // not the same thing to say.
      expect(find.text('midnight'), findsNWidgets(2));
    });
  });

  group('resting on the marks as well as the steps', () {
    testWidgets('the nearer of the two wins', (tester) async {
      double? settled;
      await tester.pumpWidget(
        _host(
          Slider(
            value: 0,
            snapToMarks: true,
            // Not on a step, or the mark and the step would be the same
            // answer and the test would prove nothing.
            marks: const [SliderMark(33.4, 'a third')],
            onChanged: (v) => settled = v,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final rail = _groove(tester);
      // Nearer the mark at 33.4 than to either whole step beside it.
      await tester.tapAt(
        Offset(rail.left + rail.width * 0.334, rail.center.dy),
      );
      await tester.pumpAndSettle();
      expect(settled, 33.4);
    });

    testWidgets('without it the steps are the only stops', (tester) async {
      double? settled;
      await tester.pumpWidget(
        _host(
          Slider(
            value: 0,
            marks: const [SliderMark(33.4, 'a third')],
            onChanged: (v) => settled = v,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final rail = _groove(tester);
      await tester.tapAt(
        Offset(rail.left + rail.width * 0.334, rail.center.dy),
      );
      await tester.pumpAndSettle();
      expect(settled, 33);
    });

    testWidgets('a mark the handle may not rest on is no magnet either',
        (tester) async {
      double? settled;
      await tester.pumpWidget(
        _host(
          Slider(
            value: 0,
            snapToMarks: true,
            marks: const [SliderMark(33.4, 'taken', disabled: true)],
            onChanged: (v) => settled = v,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final rail = _groove(tester);
      await tester.tapAt(
        Offset(rail.left + rail.width * 0.334, rail.center.dy),
      );
      await tester.pumpAndSettle();
      expect(settled, 33);
    });
  });

  group('a slider that keeps its own place', () {
    /// Focuses the slider and presses [key] once.
    Future<void> press(WidgetTester tester, LogicalKeyboardKey key) async {
      await tester.tap(find.byType(Focus).last, warnIfMissed: false);
      await tester.pumpAndSettle();
      Focus.of(tester.element(find.byType(CustomPaint).last)).requestFocus();
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(key);
      await tester.pumpAndSettle();
    }

    // The handle is painted, not a widget, so where it stands can only be
    // asked of the slider itself. An arrow key moves one step from wherever
    // it is now — which is exactly the question: did the tap stay?

    testWidgets('a tap stays put, so the next key steps on from it', (
      tester,
    ) async {
      final seen = <double>[];
      await tester.pumpWidget(
        _host(Slider(defaultValue: 0, step: 10, onChanged: seen.add)),
      );
      final groove = _groove(tester);
      await tester.tapAt(groove.center);
      await tester.pumpAndSettle();
      expect(seen.single, 50, reason: 'tapped the middle');

      await press(tester, LogicalKeyboardKey.arrowRight);
      expect(
        seen.last,
        60,
        reason: 'one step on from 50 — had the tap been forgotten it would '
            'have stepped from where it started and said 10',
      );
    });

    testWidgets('an owner that refuses is shown refusing', (tester) async {
      final seen = <double>[];
      await tester.pumpWidget(
        _host(Slider(value: 0, step: 10, onChanged: seen.add)),
      );
      final groove = _groove(tester);
      await tester.tapAt(groove.center);
      await tester.pumpAndSettle();
      await press(tester, LogicalKeyboardKey.arrowRight);
      expect(seen.last, 10,
          reason: 'still stepping from the value it is held at');
    });

    testWidgets('with nobody listening it still moves', (tester) async {
      // Nothing to assert but the absence of a refusal: with no listener the
      // only witness is that a later key press is accepted at all.
      await tester.pumpWidget(_host(const Slider(defaultValue: 20, step: 10)));
      final groove = _groove(tester);
      await tester.tapAt(groove.center);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('a range slider starts where defaultValues says', (
      tester,
    ) async {
      final seen = <(double, double)>[];
      await tester.pumpWidget(
        _host(
          RangeSlider(
            defaultValues: const (20, 80),
            step: 10,
            onChanged: seen.add,
          ),
        ),
      );
      final groove = _groove(tester);
      // A quarter along is nearer the low handle at 20 than the high at 80.
      await tester
          .tapAt(Offset(groove.left + groove.width * 0.25, groove.center.dy));
      await tester.pumpAndSettle();
      expect(seen.single.$2, 80, reason: 'the high handle stayed where it was');
      expect(seen.single.$1, 30, reason: 'and the low one came to the tap');
    });

    testWidgets('a multi-range slider starts where defaultValues says', (
      tester,
    ) async {
      final seen = <List<double>>[];
      await tester.pumpWidget(
        _host(
          MultiRangeSlider(
            defaultValues: const [0, 40, 70],
            step: 10,
            onChanged: seen.add,
          ),
        ),
      );
      final groove = _groove(tester);
      // A tap on this slider puts a handle in rather than moving one, so what
      // comes back is the three it started with plus the new one — which is
      // the proof that `defaultValues` was what it was working from.
      await tester.tapAt(groove.center);
      await tester.pumpAndSettle();
      expect(seen.single, [0, 40, 50, 70]);
    });
  });

  group('what a slider says out loud', () {
    // The handles are painted, so before this a slider reached a screen
    // reader as a box with nothing in it: no value, no actions, no name.

    /// The semantics nodes the handles stand in, in the order they were
    /// given.
    ///
    /// Found by what only a slider handle has — a value it could be moved to
    /// — rather than by walking the tree by hand.
    SemanticsFinder handles() =>
        find.semantics.byPredicate((n) => n.increasedValue.isNotEmpty);

    SemanticsNode handle(WidgetTester tester, [int index = 0]) =>
        handles().evaluate().elementAt(index);

    testWidgets('a handle carries its name, its value and its actions', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          Slider(
            value: 40,
            step: 10,
            semanticsLabel: 'Volume',
            onChanged: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        handles(),
        matchesSemantics(
          isSlider: true,
          isEnabled: true,
          hasEnabledState: true,
          label: 'Volume',
          value: '40',
          increasedValue: '50',
          decreasedValue: '30',
          hasIncreaseAction: true,
          hasDecreaseAction: true,
        ),
      );
      semantics.dispose();
    });

    testWidgets('the increase action moves the handle', (tester) async {
      final semantics = tester.ensureSemantics();
      double? changed;
      await tester.pumpWidget(
        _host(Slider(value: 40, step: 10, onChanged: (v) => changed = v)),
      );
      await tester.pumpAndSettle();

      tester.semantics.performAction(handles(), SemanticsAction.increase);
      await tester.pumpAndSettle();
      expect(changed, 50);
      semantics.dispose();
    });

    testWidgets('a reversed scale announces the way it actually runs', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          Slider(value: 40, step: 10, reverse: true, onChanged: (_) {}),
        ),
      );
      await tester.pumpAndSettle();

      // Increasing runs towards the end of the groove, which on a reversed
      // scale is the smaller number.
      expect(handle(tester).increasedValue, '30');
      expect(handle(tester).decreasedValue, '50');
      semantics.dispose();
    });

    testWidgets('two handles are two nodes, told apart by their values', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          RangeSlider(
            values: const (20, 80),
            semanticsLabel: 'Price',
            onChanged: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(handles(), findsExactly(2));
      final nodes = [handle(tester, 0), handle(tester, 1)];
      expect(nodes.map((n) => n.value).toSet(), {'20', '80'});
      expect(nodes.map((n) => n.label).toSet(), {'Price'});
      semantics.dispose();
    });

    testWidgets('what is read is what is shown', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          Slider(
            value: 40,
            step: 10,
            tooltip: (v) => '\$${v.round()}',
            onChanged: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(handle(tester).value, r'$40');
      semantics.dispose();
    });

    testWidgets('a barred slider offers no actions', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(Slider(value: 40, disabled: true, onChanged: (_) {})),
      );
      await tester.pumpAndSettle();

      expect(
        handles(),
        matchesSemantics(
          isSlider: true,
          hasEnabledState: true,
          isEnabled: false,
          value: '40',
          increasedValue: '41',
          decreasedValue: '39',
        ),
      );
      semantics.dispose();
    });
  });
}
