import 'package:flutter/material.dart'
    hide Slider, RangeSlider, ThemeData, Checkbox, Radio, Switch, Tooltip;
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
              SliderMark(20, Text('twenty')),
              SliderMark(80, Text('eighty')),
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
              SliderMark(0, Text('none')),
              SliderMark(100, Text('all')),
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
                      SliderMark(0, Text('cold')),
                      SliderMark(100, Text('hot')),
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
                      SliderMark(0, Text('bottom')),
                      SliderMark(100, Text('top')),
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

    testWidgets('the copy it measures with is neither read nor tapped', (
      tester,
    ) async {
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
                    marks: const [SliderMark(50, Text('half'))],
                    onChanged: (_) {},
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // The width comes from a silent duplicate of the labels. It is in the
      // tree, so a finder sees two, but a screen reader must not.
      final semantics = tester.getSemantics(find.byType(Slider));
      expect(
        semantics.toString().split('half').length - 1,
        lessThanOrEqualTo(1),
        reason: 'the marks must not be announced twice',
      );
    });
  });
}
