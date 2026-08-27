import 'dart:math' as math;

import 'package:flutter/material.dart'
    hide ThemeData, Checkbox, Radio, RadioGroup, Switch, Tooltip, Drawer;
import 'package:flutter/services.dart';
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

/// The group these tests keep opening: one item, marked with an icon that is
/// easy to find and hard to confuse with the trigger's.
FloatButtonGroup<String> _group({
  FloatButtonLayout? layout,
  String? label,
  bool? dismissible,
  bool? closeOnSelect,
  bool? open,
  ValueChanged<bool>? onOpenChange,
  FloatButtonController? controller,
  FloatButtonToken? token,
}) =>
    FloatButtonGroup<String>(
      layout: layout,
      dismissible: dismissible,
      closeOnSelect: closeOnSelect,
      open: open,
      onOpenChange: onOpenChange,
      controller: controller,
      token: token,
      items: [
        FloatButtonItem(value: 'a', icon: const UserIcon(), label: label),
      ],
    );

Future<void> _open(WidgetTester tester) async {
  await tester.tap(find.byType(FloatButtonGroup<String>));
  await tester.pumpAndSettle();
}

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

    /// The closest two items come to each other, centre to centre.
    double tightest(FloatButtonLayout layout, int count) {
      final at = [
        for (var i = 0; i < count; i++)
          layout.offsetFor(i, count, _item, _upLeft, _gap),
      ];
      var least = double.infinity;
      for (var i = 0; i < count; i++) {
        for (var j = i + 1; j < count; j++) {
          least = math.min(least, (at[i] - at[j]).distance);
        }
      }
      return least;
    }

    test('a fan stands its items clear of each other', () {
      // The default radius is worked out from the count: the more items share
      // a sweep, the further out they must go. An earlier version used a fixed
      // distance, and four items overlapped by eleven pixels.
      const layout = FloatButtonLayout.fan();
      for (var count = 2; count <= 6; count++) {
        expect(
          tightest(layout, count),
          greaterThanOrEqualTo(_item.longestSide),
          reason: '$count items must not touch',
        );
      }
    });

    test('jitter cannot push two items into each other', () {
      // The promise is not a number of pixels, it is that they never meet —
      // so that is what is asked.
      // Swept across seeds, because one arrangement proves nothing: the
      // question is whether *any* scatter the generator can produce collides.
      for (final jitter in const [0.25, 0.5, 1.0]) {
        for (var count = 2; count <= 6; count++) {
          for (var seed = 0; seed < 40; seed++) {
            final layout = FloatButtonLayout.fan(jitter: jitter, seed: seed);
            expect(
              tightest(layout, count),
              greaterThanOrEqualTo(_item.longestSide),
              reason: 'jitter $jitter, $count items, seed $seed',
            );
          }
        }
      }
    });

    test('jitter is worth seeing', () {
      // Bounded is not the same as invisible. An earlier cap came from the
      // gap rather than from the arc, and moved items by seven pixels.
      const still = FloatButtonLayout.fan();
      const shaken = FloatButtonLayout.fan(jitter: 1, seed: 3);
      final moved = (shaken.offsetFor(1, 4, _item, _upLeft, _gap) -
              still.offsetFor(1, 4, _item, _upLeft, _gap))
          .distance;
      expect(moved, greaterThan(_item.longestSide / 2));
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
      await tester.pumpWidget(_host(_group()));
      expect(find.byType(UserIcon), findsNothing);

      await tester.tap(find.byType(FloatButtonGroup<String>));
      await tester.pumpAndSettle();
      expect(find.byType(UserIcon), findsOneWidget);
    });

    testWidgets('an item reports through both handlers, and folds the group',
        (tester) async {
      var own = 0;
      final seen = <String?>[];
      await tester.pumpWidget(
        _host(
          FloatButtonGroup<String>(
            onItemTap: seen.add,
            items: [
              FloatButtonItem(
                value: 'upload',
                icon: const UserIcon(),
                onTap: () => own++,
              ),
            ],
          ),
        ),
      );
      await _open(tester);

      await tester.tap(find.byType(UserIcon));
      await tester.pumpAndSettle();
      expect(own, 1, reason: "the item's own handler ran");
      expect(seen, ['upload'], reason: 'and the group heard the value');
      expect(
        find.byType(UserIcon),
        findsNothing,
        reason: 'a menu left open would hide the result of the tap',
      );
    });

    testWidgets('the page may rebuild while the group is open', (tester) async {
      // An overlay entry may not be marked dirty during a build, and
      // didUpdateWidget runs inside one.
      var taps = 0;
      await tester.pumpWidget(
        _host(
          StatefulBuilder(
            builder: (context, setState) => FloatButtonGroup<String>(
              closeOnSelect: false,
              onItemTap: (_) => setState(() => taps++),
              items: const [FloatButtonItem(value: 'a', icon: UserIcon())],
            ),
          ),
        ),
      );
      await _open(tester);

      await tester.tap(find.byType(UserIcon));
      await tester.pumpAndSettle();
      expect(taps, 1);
      expect(tester.takeException(), isNull);
    });

    testWidgets('closeOnSelect: false leaves the group standing',
        (tester) async {
      await tester.pumpWidget(_host(_group(closeOnSelect: false)));
      await _open(tester);

      await tester.tap(find.byType(UserIcon));
      await tester.pumpAndSettle();
      expect(find.byType(UserIcon), findsOneWidget);
    });

    testWidgets('a tap on open ground closes the group', (tester) async {
      await tester.pumpWidget(_host(_group()));
      await _open(tester);

      await tester.tapAt(const Offset(60, 60));
      await tester.pumpAndSettle();
      expect(find.byType(UserIcon), findsNothing);
    });

    testWidgets('dismissible: false ignores a tap on open ground',
        (tester) async {
      await tester.pumpWidget(_host(_group(dismissible: false)));
      await _open(tester);

      await tester.tapAt(const Offset(60, 60));
      await tester.pumpAndSettle();
      expect(find.byType(UserIcon), findsOneWidget);
    });

    testWidgets('escape closes it even so', (tester) async {
      // A menu with no way out from the keyboard is a trap, and no setting
      // may make one.
      await tester.pumpWidget(_host(_group(dismissible: false)));
      await _open(tester);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(UserIcon), findsNothing);
    });

    testWidgets('a controlled group waits to be told', (tester) async {
      final asked = <bool>[];
      await tester.pumpWidget(
        _host(_group(open: true, onOpenChange: asked.add)),
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

  group('controller', () {
    testWidgets('opens and closes from outside the build', (tester) async {
      final fab = FloatButtonController();
      addTearDown(fab.dispose);
      await tester.pumpWidget(_host(_group(controller: fab)));
      expect(find.byType(UserIcon), findsNothing);

      fab.open();
      await tester.pumpAndSettle();
      expect(find.byType(UserIcon), findsOneWidget);

      fab.close();
      await tester.pumpAndSettle();
      expect(find.byType(UserIcon), findsNothing);
    });

    testWidgets('a group born with an open controller opens', (tester) async {
      final fab = FloatButtonController(open: true);
      addTearDown(fab.dispose);
      await tester.pumpWidget(_host(_group(controller: fab)));
      await tester.pumpAndSettle();
      expect(find.byType(UserIcon), findsOneWidget);
    });

    test('a controller and an open flag together are refused', () {
      // Two owners of one truth disagree sooner or later.
      expect(
        () => FloatButtonGroup<String>(
          controller: FloatButtonController(),
          open: true,
          items: const [],
        ),
        throwsAssertionError,
      );
    });
  });

  group('items', () {
    testWidgets('itemBuilder wraps what the group built', (tester) async {
      await tester.pumpWidget(
        _host(
          FloatButtonGroup<String>(
            itemBuilder: (context, item, child) => ColoredBox(
              color: const Color(0xFF00FF00),
              child: child,
            ),
            items: const [FloatButtonItem(value: 'a', icon: UserIcon())],
          ),
        ),
      );
      await _open(tester);

      expect(
        find.ancestor(
          of: find.byType(UserIcon),
          matching: find.byType(ColoredBox),
        ),
        findsWidgets,
      );
    });

    testWidgets('a key is fastened to the item, for a Tour to aim at',
        (tester) async {
      final key = GlobalKey();
      await tester.pumpWidget(
        _host(
          FloatButtonGroup<String>(
            items: [
              FloatButtonItem(key: key, value: 'a', icon: const UserIcon()),
            ],
          ),
        ),
      );
      await _open(tester);

      expect(find.byKey(key), findsOneWidget);
      expect(
        find.descendant(of: find.byKey(key), matching: find.byType(UserIcon)),
        findsOneWidget,
      );
    });

    testWidgets('a label becomes the caption beside the button',
        (tester) async {
      await tester.pumpWidget(
        _host(
          const FloatButtonGroup<String>(
            items: [
              FloatButtonItem(value: 'a', icon: UserIcon(), label: 'Upload'),
            ],
          ),
        ),
      );
      await _open(tester);

      final button = tester.getRect(find.byType(UserIcon));
      final label = tester.getRect(find.text('Upload'));
      expect(label.right, lessThan(button.left), reason: 'a column: sideways');
    });

    testWidgets('an item may differ from its group in colour', (tester) async {
      await tester.pumpWidget(
        _host(
          const FloatButtonGroup<String>(
            color: ButtonColor.primary,
            items: [
              FloatButtonItem(
                value: 'a',
                icon: UserIcon(),
                color: ButtonColor.danger,
              ),
            ],
          ),
        ),
      );
      await _open(tester);

      final button = tester.widget<Button>(
        find.ancestor(of: find.byType(UserIcon), matching: find.byType(Button)),
      );
      expect(button.color, ButtonColor.danger);
    });

    testWidgets('a disabled item is deaf', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _host(
          FloatButtonGroup<String>(
            items: [
              FloatButtonItem(
                value: 'a',
                icon: const UserIcon(),
                disabled: true,
                onTap: () => taps++,
              ),
            ],
          ),
        ),
      );
      await _open(tester);

      await tester.tap(find.byType(UserIcon), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(taps, 0);
      expect(find.byType(UserIcon), findsOneWidget);
    });
  });

  group('on screen', () {
    testWidgets('a scroll re-aims the group rather than dropping it',
        (tester) async {
      // Closing would be the cheap answer to a stale origin, and the wrong
      // one: a group told it may not be dismissed must not dismiss itself.
      // Driven through a controller, not a drag: an open group covers the
      // page, so a gesture would never reach the list.
      final scroll = ScrollController();
      addTearDown(scroll.dispose);
      await tester.pumpWidget(
        ConfigProvider(
          child: MaterialApp(
            home: Scaffold(
              body: ListView(
                controller: scroll,
                children: [
                  const SizedBox(height: 400),
                  Center(child: _group(dismissible: false)),
                  const SizedBox(height: 800),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byType(FloatButtonGroup<String>));
      await tester.pumpAndSettle();
      final before = tester.getCenter(find.byType(UserIcon));

      scroll.jumpTo(80);
      await tester.pumpAndSettle();

      expect(find.byType(UserIcon), findsOneWidget, reason: 'still open');
      expect(
        tester.getCenter(find.byType(UserIcon)).dy,
        closeTo(before.dy - 80, 1),
        reason: 'and it travelled with the trigger',
      );
    });

    testWidgets('a column parked bottom right climbs', (tester) async {
      await tester.pumpWidget(_host(_group()));
      final trigger = tester.getCenter(find.byType(FloatButtonGroup<String>));
      await _open(tester);

      expect(tester.getCenter(find.byType(UserIcon)).dy, lessThan(trigger.dy));
    });

    testWidgets('a column parked top left descends', (tester) async {
      await tester.pumpWidget(_host(_group(), at: Alignment.topLeft));
      final trigger = tester.getCenter(find.byType(FloatButtonGroup<String>));
      await _open(tester);

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

    testWidgets('a label in a row goes above, not beside', (tester) async {
      await tester.pumpWidget(
        _host(
          _group(
            layout: const FloatButtonLayout.horizontal(),
            label: 'Profile',
          ),
        ),
      );
      await _open(tester);

      final button = tester.getRect(find.byType(UserIcon));
      final label = tester.getRect(find.text('Profile'));
      expect(label.bottom, lessThan(button.top));
    });
  });

  group('theme', () {
    testWidgets('the curve token shapes the opening', (tester) async {
      Future<double> travelAtHalfway(Curve? curve) async {
        await tester.pumpWidget(
          _host(_group(token: FloatButtonToken(curve: curve))),
        );
        final trigger = tester.getCenter(find.byType(FloatButtonGroup<String>));
        await tester.tap(find.byType(FloatButtonGroup<String>));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        final travelled =
            (tester.getCenter(find.byType(UserIcon)) - trigger).distance;
        // An open panel outlives the pump, so put it away before the next one.
        await tester.tapAt(const Offset(60, 60));
        await tester.pumpAndSettle();
        return travelled;
      }

      final eased = await travelAtHalfway(null);
      final straight = await travelAtHalfway(Curves.linear);
      expect(
        eased,
        greaterThan(straight),
        reason: 'the kit eases out, so half the time is more than half the way',
      );
    });

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
      expect(tester.widget<Button>(find.byType(Button)).disabled, isTrue);
    });

    testWidgets('defaults carry dismissible too', (tester) async {
      await tester.pumpWidget(
        ConfigProvider(
          defaults: const ComponentDefaults(
            floatButton: FloatButtonDefaults(dismissible: false),
          ),
          child: MaterialApp(
            home: Scaffold(
              body: Stack(
                children: [
                  Align(alignment: Alignment.bottomRight, child: _group()),
                ],
              ),
            ),
          ),
        ),
      );
      await _open(tester);
      await tester.tapAt(const Offset(60, 60));
      await tester.pumpAndSettle();
      expect(find.byType(UserIcon), findsOneWidget);
    });
  });
}

Offset _ladder(int index, int count) => Offset(index * 10, index * 20);
