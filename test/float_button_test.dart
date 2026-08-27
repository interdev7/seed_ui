import 'dart:math' as math;

import 'package:flutter/material.dart'
    hide ThemeData, Checkbox, Radio, RadioGroup, Switch, Tooltip, Drawer;
import 'package:flutter_test/flutter_test.dart';
import 'package:seed_ui/seed_ui.dart';

/// A group parked in the corner [at], the way a float button is really used.
Widget _host(Widget child, {Alignment at = Alignment.bottomRight}) =>
    ConfigProvider(
      child: MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              Align(
                alignment: at,
                child: Padding(padding: const EdgeInsets.all(24), child: child),
              ),
            ],
          ),
        ),
      ),
    );

const _item = Size.square(48);
const _gap = 12.0;

/// Away from the bottom-right corner: up and to the left.
const _upLeft = Offset(-1, -1);

/// Away from the top-left corner.
const _downRight = Offset(1, 1);

void main() {
  group('layout geometry', () {
    test('a column climbs, one item plus one gap at a time', () {
      const layout = FloatButtonLayout.vertical();
      final first = layout.offsetFor(0, 3, _item, _upLeft, _gap);
      final second = layout.offsetFor(1, 3, _item, _upLeft, _gap);

      expect(first.dx, 0);
      expect(first.dy, -60, reason: 'one 48 item and one 12 gap, upwards');
      expect(second.dy, -120);
    });

    test('a column follows the corner it is parked in', () {
      const layout = FloatButtonLayout.vertical();
      expect(layout.offsetFor(0, 3, _item, _upLeft, _gap).dy, lessThan(0));
      expect(
          layout.offsetFor(0, 3, _item, _downRight, _gap).dy, greaterThan(0));
    });

    test('a column hangs its labels sideways, never above', () {
      // Perpendicular to the run: a label above an item in a column would
      // land on the item above it.
      const layout = FloatButtonLayout.vertical();
      for (var i = 0; i < 3; i++) {
        expect(
          layout.labelPlacementFor(i, 3, _item, _upLeft, _gap),
          FloatButtonLabelPlacement.left,
        );
        expect(
          layout.labelPlacementFor(i, 3, _item, _downRight, _gap),
          FloatButtonLabelPlacement.right,
        );
      }
    });

    test('a row hangs its labels above or below, never sideways', () {
      const layout = FloatButtonLayout.horizontal();
      expect(
        layout.labelPlacementFor(0, 3, _item, _upLeft, _gap),
        FloatButtonLabelPlacement.top,
      );
      expect(
        layout.labelPlacementFor(0, 3, _item, _downRight, _gap),
        FloatButtonLabelPlacement.bottom,
      );
    });

    test('a fan keeps every item the same distance out', () {
      const layout = FloatButtonLayout.fan(radius: 100);
      for (var i = 0; i < 4; i++) {
        expect(
          layout.offsetFor(i, 4, _item, _upLeft, _gap).distance,
          closeTo(100, 0.001),
        );
      }
    });

    test('a fan aims away from the corner and spreads around that', () {
      const layout = FloatButtonLayout.fan(radius: 100);
      final angles = [
        for (var i = 0; i < 3; i++)
          () {
            final o = layout.offsetFor(i, 3, _item, _upLeft, _gap);
            return math.atan2(o.dy, o.dx);
          }(),
      ];

      // Parked bottom right, the arc runs from due left to due up, centred on
      // the diagonal between them.
      expect(angles[1], closeTo(-3 * math.pi / 4, 0.001));
      expect(angles[0], closeTo(-math.pi, 0.001));
      expect(angles[2], closeTo(-math.pi / 2, 0.001));
    });

    test('a fan sends each label out along its own spoke', () {
      const layout = FloatButtonLayout.fan(radius: 100);
      // The item on the left arm wants its label out to the left; the one on
      // the top arm wants it above. One answer for the whole group would be
      // wrong for most of it.
      expect(
        layout.labelPlacementFor(0, 3, _item, _upLeft, _gap),
        FloatButtonLabelPlacement.left,
      );
      expect(
        layout.labelPlacementFor(2, 3, _item, _upLeft, _gap),
        FloatButtonLabelPlacement.top,
      );
    });

    test('jitter scatters, but the same way every time', () {
      const still = FloatButtonLayout.fan(radius: 100);
      const shaken = FloatButtonLayout.fan(radius: 100, jitter: 1, seed: 7);

      final a = shaken.offsetFor(1, 4, _item, _upLeft, _gap);
      final b = shaken.offsetFor(1, 4, _item, _upLeft, _gap);
      expect(a, b, reason: 'a group must open the same way twice');
      expect(
        a,
        isNot(still.offsetFor(1, 4, _item, _upLeft, _gap)),
        reason: 'and it must actually move',
      );
    });

    test('a different seed is a different scatter', () {
      const one = FloatButtonLayout.fan(radius: 100, jitter: 1, seed: 1);
      const two = FloatButtonLayout.fan(radius: 100, jitter: 1, seed: 2);
      expect(
        one.offsetFor(1, 4, _item, _upLeft, _gap),
        isNot(two.offsetFor(1, 4, _item, _upLeft, _gap)),
      );
    });

    test('jitter cannot push two items into each other', () {
      // The promise is that the stray is bounded by half the gap, so items
      // that cleared each other on the arc still clear each other after it.
      const still = FloatButtonLayout.fan(radius: 100);
      const shaken = FloatButtonLayout.fan(radius: 100, jitter: 1, seed: 3);
      for (var i = 0; i < 6; i++) {
        final drift = (shaken.offsetFor(i, 6, _item, _upLeft, _gap) -
                still.offsetFor(i, 6, _item, _upLeft, _gap))
            .distance;
        expect(drift, lessThanOrEqualTo(_gap / 2 * math.sqrt2));
      }
    });

    test('a grid wraps at its column count', () {
      const layout = FloatButtonLayout.grid(2);
      final third = layout.offsetFor(2, 4, _item, _upLeft, _gap);
      final first = layout.offsetFor(0, 4, _item, _upLeft, _gap);
      expect(third.dx, first.dx, reason: 'item 2 starts a new row');
      expect(third.dy.abs(), greaterThan(first.dy.abs()));
    });

    test('a custom layout is asked, not second-guessed', () {
      const layout = FloatButtonLayout.custom(_ladder);
      expect(
          layout.offsetFor(2, 4, _item, _upLeft, _gap), const Offset(20, 40));
      expect(
        layout.labelPlacementFor(2, 4, _item, _upLeft, _gap),
        FloatButtonLabelPlacement.bottom,
      );
    });
  });

  group('opening and closing', () {
    testWidgets('a group keeps its items to itself until it is opened',
        (tester) async {
      await tester.pumpWidget(
        _host(
          FloatButtonGroup(
            children: [FloatButton(icon: const UserIcon(), onPressed: () {})],
          ),
        ),
      );
      expect(find.byType(UserIcon), findsNothing);

      await tester.tap(find.byType(FloatButtonGroup));
      await tester.pumpAndSettle();
      expect(find.byType(UserIcon), findsOneWidget);
    });

    testWidgets('an item does its work and folds the group away',
        (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _host(
          FloatButtonGroup(
            children: [
              FloatButton(icon: const UserIcon(), onPressed: () => taps++),
            ],
          ),
        ),
      );
      await tester.tap(find.byType(FloatButtonGroup));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(UserIcon));
      await tester.pumpAndSettle();
      expect(taps, 1);
      expect(
        find.byType(UserIcon),
        findsNothing,
        reason: 'a menu left open would hide the result of the tap',
      );
    });

    testWidgets('a tap on open ground closes the group', (tester) async {
      await tester.pumpWidget(
        _host(
          FloatButtonGroup(
            children: [FloatButton(icon: const UserIcon(), onPressed: () {})],
          ),
        ),
      );
      await tester.tap(find.byType(FloatButtonGroup));
      await tester.pumpAndSettle();

      await tester.tapAt(const Offset(60, 60));
      await tester.pumpAndSettle();
      expect(find.byType(UserIcon), findsNothing);
    });

    testWidgets('a controlled group waits to be told', (tester) async {
      final asked = <bool>[];
      await tester.pumpWidget(
        _host(
          FloatButtonGroup(
            open: true,
            onOpenChange: asked.add,
            children: [FloatButton(icon: const UserIcon(), onPressed: () {})],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(UserIcon), findsOneWidget);

      await tester.tapAt(const Offset(60, 60));
      await tester.pumpAndSettle();
      expect(asked, [false], reason: 'it reports, and leaves the say to us');
      expect(
        find.byType(UserIcon),
        findsOneWidget,
        reason: 'open was never withdrawn',
      );
    });
  });

  group('on screen', () {
    testWidgets('a scroll folds the group away', (tester) async {
      // The geometry is read once per opening, so a group left open over a
      // moving page would hang in mid-air, pointing at nothing.
      await tester.pumpWidget(
        ConfigProvider(
          child: MaterialApp(
            home: Scaffold(
              body: ListView(
                children: [
                  const SizedBox(height: 400),
                  Center(
                    child: FloatButtonGroup(
                      children: [
                        FloatButton(icon: const UserIcon(), onPressed: () {}),
                      ],
                    ),
                  ),
                  const SizedBox(height: 800),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byType(FloatButtonGroup));
      await tester.pumpAndSettle();
      expect(find.byType(UserIcon), findsOneWidget);

      await tester.drag(find.byType(ListView), const Offset(0, -80));
      await tester.pumpAndSettle();
      expect(find.byType(UserIcon), findsNothing);
    });

    testWidgets('a column parked bottom right climbs', (tester) async {
      await tester.pumpWidget(
        _host(
          FloatButtonGroup(
            children: [FloatButton(icon: const UserIcon(), onPressed: () {})],
          ),
        ),
      );
      final trigger = tester.getCenter(find.byType(FloatButtonGroup));
      await tester.tap(find.byType(FloatButtonGroup));
      await tester.pumpAndSettle();

      expect(tester.getCenter(find.byType(UserIcon)).dy, lessThan(trigger.dy));
    });

    testWidgets('a column parked top left descends', (tester) async {
      await tester.pumpWidget(
        _host(
          FloatButtonGroup(
            children: [FloatButton(icon: const UserIcon(), onPressed: () {})],
          ),
          at: Alignment.topLeft,
        ),
      );
      final trigger = tester.getCenter(find.byType(FloatButtonGroup));
      await tester.tap(find.byType(FloatButtonGroup));
      await tester.pumpAndSettle();

      expect(
        tester.getCenter(find.byType(UserIcon)).dy,
        greaterThan(trigger.dy),
      );
    });

    testWidgets('a label hangs clear of the button it names', (tester) async {
      await tester.pumpWidget(
        _host(
          FloatButton(
            icon: const UserIcon(),
            label: const Text('Profile'),
            onPressed: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      final button = tester.getRect(find.byType(UserIcon));
      final label = tester.getRect(find.text('Profile'));
      expect(
        label.right,
        lessThan(button.left),
        reason: 'to the left, and outside the button entirely',
      );
      expect(label.center.dy, closeTo(button.center.dy, 1));
    });

    testWidgets('a label in a group takes the side the layout gives it',
        (tester) async {
      await tester.pumpWidget(
        _host(
          FloatButtonGroup(
            layout: const FloatButtonLayout.horizontal(),
            children: [
              FloatButton(
                icon: const UserIcon(),
                label: const Text('Profile'),
                onPressed: () {},
              ),
            ],
          ),
        ),
      );
      await tester.tap(find.byType(FloatButtonGroup));
      await tester.pumpAndSettle();

      // A row, so the label goes above rather than to the side.
      final button = tester.getRect(find.byType(UserIcon));
      final label = tester.getRect(find.text('Profile'));
      expect(label.bottom, lessThan(button.top));
    });
  });

  group('theme', () {
    testWidgets('a token sets the size of every float button', (tester) async {
      await tester.pumpWidget(
        ConfigProvider(
          theme: ThemeData(
            components: const ComponentsConfig(
              floatButton: FloatButtonToken(size: 72),
            ),
          ),
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: FloatButton(icon: const UserIcon(), onPressed: () {}),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.getSize(find.byType(FloatButton)), const Size(72, 72));
    });

    testWidgets('defaults reach a button that names nothing', (tester) async {
      await tester.pumpWidget(
        ConfigProvider(
          defaults: const ComponentDefaults(
            floatButton: FloatButtonDefaults(disabled: true),
          ),
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: FloatButton(icon: const UserIcon(), onPressed: () {}),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.widget<Button>(find.byType(Button)).disabled,
        isTrue,
      );
    });
  });
}

Offset _ladder(int index, int count) => Offset(index * 10, index * 20);
