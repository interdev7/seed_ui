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
  FloatButtonDirection? direction,
  int count = 1,
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
      direction: direction,
      dismissible: dismissible,
      closeOnSelect: closeOnSelect,
      open: open,
      onOpenChange: onOpenChange,
      controller: controller,
      token: token,
      items: [
        for (var i = 0; i < count; i++)
          FloatButtonItem(
            value: 'i$i',
            icon: const UserIcon(),
            label: label,
          ),
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
  group('which way it opens', () {
    test('a fan told neither side opens symmetrically', () {
      // The point of a zero component. Four corners could not say "straight
      // up", so a group at the foot of a screen tipped into one of them.
      const up = Offset(0, -1);
      final at = [
        for (var i = 0; i < 4; i++)
          const FloatButtonLayout.fan().offsetFor(i, 4, _item, up, _gap),
      ];
      expect(at.first.dx, closeTo(-at.last.dx, 0.001), reason: 'straddles');
      expect(at.first.dy, closeTo(at.last.dy, 0.001), reason: 'and is level');
      for (final o in at) {
        expect(o.dy, lessThan(0), reason: 'all of it above the trigger');
      }
    });

    test('a grid told neither side centres its columns', () {
      const up = Offset(0, -1);
      final xs = {
        for (var i = 0; i < 4; i++)
          const FloatButtonLayout.grid(2).offsetFor(i, 4, _item, up, _gap).dx,
      };
      expect(xs.length, 2);
      expect(xs.reduce((a, b) => a + b), closeTo(0, 0.001),
          reason: 'the two columns straddle the trigger');
    });

    test('a run has no travel across itself, so it takes the usual way', () {
      // Told "up", a row still has to go somewhere sideways.
      const up = Offset(0, -1);
      final row =
          const FloatButtonLayout.horizontal().offsetFor(0, 3, _item, up, _gap);
      expect(row.dx, lessThan(0));
      expect(row.dy, 0);

      const left = Offset(-1, 0);
      final column =
          const FloatButtonLayout.vertical().offsetFor(0, 3, _item, left, _gap);
      expect(column.dy, lessThan(0));
      expect(column.dx, 0);
    });

    testWidgets('a group at the foot of the screen fans straight up',
        (tester) async {
      await tester.pumpWidget(
        _host(
          _group(layout: const FloatButtonLayout.fan(), count: 4),
          at: Alignment.bottomCenter,
        ),
      );
      final trigger = tester.getCenter(find.byType(FloatButtonGroup<String>));
      await _open(tester);

      final xs = [
        for (var i = 0; i < 4; i++)
          tester.getRect(find.byType(UserIcon).at(i)).center.dx - trigger.dx,
      ];
      expect(xs.first, closeTo(-xs.last, 1),
          reason: 'as far one way as the other');
      expect(xs.first, lessThan(0));
      expect(xs.last, greaterThan(0));
    });

    testWidgets('a group in the corner still goes up and to the left',
        (tester) async {
      await tester.pumpWidget(
        _host(_group(layout: const FloatButtonLayout.fan(), count: 4)),
      );
      final trigger = tester.getCenter(find.byType(FloatButtonGroup<String>));
      await _open(tester);

      for (var i = 0; i < 4; i++) {
        final c = tester.getRect(find.byType(UserIcon).at(i)).center;
        expect(c.dx, lessThanOrEqualTo(trigger.dx + 1));
        expect(c.dy, lessThanOrEqualTo(trigger.dy + 1));
      }
    });

    testWidgets('a named direction is taken as given', (tester) async {
      // Parked bottom right, where it would otherwise go up and left.
      await tester.pumpWidget(
        _host(
          _group(
            layout: const FloatButtonLayout.vertical(),
            direction: FloatButtonDirection.bottom,
          ),
        ),
      );
      final trigger = tester.getCenter(find.byType(FloatButtonGroup<String>));
      await _open(tester);
      expect(
        tester.getCenter(find.byType(UserIcon)).dy,
        greaterThan(trigger.dy),
        reason: 'told to go down, it went down',
      );
    });

    testWidgets('defaults carry a direction too', (tester) async {
      await tester.pumpWidget(
        ConfigProvider(
          defaults: const ComponentDefaults(
            floatButton:
                FloatButtonDefaults(direction: FloatButtonDirection.bottom),
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
      final trigger = tester.getCenter(find.byType(FloatButtonGroup<String>));
      await _open(tester);
      expect(
          tester.getCenter(find.byType(UserIcon)).dy, greaterThan(trigger.dy));
    });

    testWidgets('a row with nowhere to run folds into rows', (tester) async {
      // Twelve of them want more width than there is either side of a centred
      // trigger, and no direction fixes that — the far half would sit off the
      // screen where it can be neither reached nor seen.
      await tester.pumpWidget(
        _host(
          _group(layout: const FloatButtonLayout.horizontal(), count: 12),
          at: Alignment.bottomCenter,
        ),
      );
      final trigger = tester.getCenter(find.byType(FloatButtonGroup<String>));
      await _open(tester);

      final rows = <double>{};
      for (var i = 0; i < 12; i++) {
        final r = tester.getRect(find.byType(UserIcon).at(i));
        expect(r.left, greaterThanOrEqualTo(0), reason: 'item $i is on screen');
        expect(r.right, lessThanOrEqualTo(800));
        rows.add((r.center.dy - trigger.dy).roundToDouble());
      }
      expect(rows.length, greaterThan(1), reason: 'it wrapped');
    });

    testWidgets('a column with nowhere to run folds too', (tester) async {
      // Both axes have an end: a tall column overruns a screen as surely as a
      // long row does. Fifteen, because with fourteen a block measured by the
      // run's spacing and one measured by the block's own come out the same,
      // and the test would not know the difference.
      const count = 15;
      await tester.pumpWidget(
        _host(
          _group(layout: const FloatButtonLayout.vertical(), count: count),
          at: Alignment.bottomCenter,
        ),
      );
      final trigger = tester.getCenter(find.byType(FloatButtonGroup<String>));
      await _open(tester);

      final columns = <double>{};
      final rows = <double>{};
      for (var i = 0; i < count; i++) {
        final r = tester.getRect(find.byType(UserIcon).at(i));
        expect(r.top, greaterThanOrEqualTo(0), reason: 'item $i is on screen');
        expect(r.bottom, lessThanOrEqualTo(600));
        columns.add((r.center.dx - trigger.dx).roundToDouble());
        rows.add((r.center.dy - trigger.dy).roundToDouble());
      }
      expect(columns.length, greaterThan(1), reason: 'it folded sideways');

      // Two invariants, both read off the screen rather than assumed: the
      // block fits the room it was given, and it folds no further than it had
      // to — one column fewer would not have fitted.
      final ladder = rows.toList()..sort();
      final step = (ladder[1] - ladder[0]).abs();
      final room = trigger.dy;
      expect(rows.length * step, lessThanOrEqualTo(room),
          reason: 'the block fits above the trigger');
      expect(
        (count / (columns.length - 1)).ceil() * step,
        greaterThan(room),
        reason: 'one column fewer would have overrun the screen',
      );
    });

    testWidgets('a column that fits is left as a column', (tester) async {
      // Seven fit the height above a centred trigger and would not fit the
      // width beside it — so a fold here would mean the run had been measured
      // against the wrong axis altogether.
      await tester.pumpWidget(
        _host(
          _group(layout: const FloatButtonLayout.vertical(), count: 7),
          at: Alignment.bottomCenter,
        ),
      );
      final trigger = tester.getCenter(find.byType(FloatButtonGroup<String>));
      await _open(tester);

      for (var i = 0; i < 7; i++) {
        expect(
          tester.getRect(find.byType(UserIcon).at(i)).center.dx,
          closeTo(trigger.dx, 1),
          reason: 'still one column',
        );
      }
    });

    testWidgets('a row that fits is left as a row', (tester) async {
      await tester.pumpWidget(
        _host(
          _group(layout: const FloatButtonLayout.horizontal(), count: 4),
          at: Alignment.bottomCenter,
        ),
      );
      final trigger = tester.getCenter(find.byType(FloatButtonGroup<String>));
      await _open(tester);

      for (var i = 0; i < 4; i++) {
        expect(
          tester.getRect(find.byType(UserIcon).at(i)).center.dy,
          closeTo(trigger.dy, 1),
          reason: 'still one row',
        );
      }
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

    testWidgets('a second tap on the trigger closes it, and it stays shut',
        (tester) async {
      await tester.pumpWidget(_host(_group()));
      await _open(tester);

      await tester.tap(find.byType(FloatButtonGroup<String>));
      await tester.pumpAndSettle();
      expect(find.byType(UserIcon), findsNothing);
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
                  Center(child: _group()),
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

    testWidgets('a label is its own size, not the button\'s', (tester) async {
      // An OverflowBox inherits the minimum constraints as well as the
      // maximum ones. Left unset they came from the button, and a caption
      // shorter than the button was stretched out to it — padding the text
      // away from what it names, and giving it a footprint that ran through
      // the item next door.
      await tester.pumpWidget(
        _host(
          FloatButton(
            icon: const UserIcon(),
            label: const Text('Edit'),
            onPressed: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      final button = tester.getSize(find.byType(Button));
      final label = tester.getSize(find.text('Edit'));
      expect(label.height, lessThan(button.height / 2));
    });

    testWidgets('a grid keeps its captions out of its buttons', (tester) async {
      await tester.pumpWidget(
        _host(
          const FloatButtonGroup<String>(
            layout: FloatButtonLayout.grid(2),
            items: [
              FloatButtonItem(value: 'a', icon: UserIcon(), label: 'One'),
              FloatButtonItem(value: 'b', icon: UserIcon(), label: 'Two'),
              FloatButtonItem(value: 'c', icon: UserIcon(), label: 'Three'),
              FloatButtonItem(value: 'd', icon: UserIcon(), label: 'Four'),
            ],
          ),
        ),
      );
      await _open(tester);

      // A caption is a sibling of its button inside the item, not a
      // descendant of it, so pair them through the FloatButton they share.
      Rect buttonOf(String caption) => tester.getRect(
            find.descendant(
              of: find.ancestor(
                of: find.text(caption),
                matching: find.byType(FloatButton),
              ),
              matching: find.byType(Button),
            ),
          );

      const captions = ['One', 'Two', 'Three', 'Four'];
      for (final caption in captions) {
        final label = tester.getRect(find.text(caption));
        for (final other in captions) {
          if (other == caption) continue;
          expect(
            label.overlaps(buttonOf(other)),
            isFalse,
            reason: '"$caption" runs through "$other"',
          );
        }
      }
    });

    testWidgets('a group with room above it opens upwards', (tester) async {
      // Half the screen is the wrong question: a group a third of the way
      // down has plenty of room above and no reason to open away from it.
      await tester.pumpWidget(_host(_group(), at: const Alignment(0, -0.3)));
      final trigger = tester.getCenter(find.byType(FloatButtonGroup<String>));
      await _open(tester);

      expect(tester.getCenter(find.byType(UserIcon)).dy, lessThan(trigger.dy));
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

  group('size', () {
    testWidgets('a preset walks the token scale', (tester) async {
      Future<Size> at(ControlSize? size) async {
        await tester.pumpWidget(
          _host(
            FloatButton(
              size: size,
              icon: const UserIcon(),
              onPressed: () {},
            ),
          ),
        );
        await tester.pumpAndSettle();
        return tester.getSize(find.byType(FloatButton));
      }

      expect((await at(SoftSize.small)).width, 40);
      expect((await at(null)).width, 48);
      expect((await at(SoftSize.large)).width, 56);
    });

    testWidgets('a measurement is taken as given', (tester) async {
      await tester.pumpWidget(
        _host(
          FloatButton(
            size: const ControlSize.height(72),
            icon: const UserIcon(),
            onPressed: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      // A circle's height is its diameter.
      expect(tester.getSize(find.byType(FloatButton)), const Size(72, 72));
    });

    testWidgets('a group sizes its items alike, and spaces them by it',
        (tester) async {
      await tester.pumpWidget(
        _host(
          const FloatButtonGroup<String>(
            size: ControlSize.height(72),
            items: [
              FloatButtonItem(value: 'a', icon: UserIcon()),
              FloatButtonItem(
                  value: 'b', icon: SearchIcon(color: Color(0xFF000000))),
            ],
          ),
        ),
      );
      await _open(tester);

      expect(tester.getSize(find.byType(UserIcon).hitTestable()), isNotNull);
      final first = tester.getRect(
        find.ancestor(
          of: find.byType(UserIcon),
          matching: find.byType(Button),
        ),
      );
      expect(first.size, const Size(72, 72));

      final second = tester.getRect(
        find.ancestor(
          of: find.byType(SearchIcon),
          matching: find.byType(Button),
        ),
      );
      // A column: one item, then one gap, both taken from the bigger size.
      expect((second.center - first.center).distance, closeTo(72 + 12, 0.5));
    });
  });

  group('the page underneath', () {
    testWidgets('gets a tap that dismisses, and nothing else with it',
        (tester) async {
      // One gesture, one thing: the tap puts the menu away and stops there.
      // Pressing what was underneath as well would be two actions at once —
      // and an outside control that toggles would then see the group already
      // shut and open it straight back up.
      var behind = 0;
      await tester.pumpWidget(
        ConfigProvider(
          child: MaterialApp(
            home: Scaffold(
              body: Stack(
                children: [
                  Positioned(
                    left: 20,
                    top: 20,
                    child: Button(
                      onPressed: () => behind++,
                      child: const Text('Behind'),
                    ),
                  ),
                  Align(alignment: Alignment.bottomRight, child: _group()),
                ],
              ),
            ),
          ),
        ),
      );
      await _open(tester);

      await tester.tap(find.text('Behind'));
      await tester.pumpAndSettle();
      expect(find.byType(UserIcon), findsNothing, reason: 'the menu closed');
      expect(behind, 0, reason: 'and the page was not pressed as well');

      // With the menu away, the page answers again.
      await tester.tap(find.text('Behind'));
      await tester.pumpAndSettle();
      expect(behind, 1);
    });

    testWidgets('a control outside that toggles does not fight the barrier',
        (tester) async {
      final fab = FloatButtonController();
      addTearDown(fab.dispose);
      await tester.pumpWidget(
        ConfigProvider(
          child: MaterialApp(
            home: Scaffold(
              body: Stack(
                children: [
                  Positioned(
                    left: 20,
                    top: 20,
                    child: Button(
                      onPressed: fab.toggle,
                      child: const Text('Toggle'),
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: _group(controller: fab),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Toggle'));
      await tester.pumpAndSettle();
      expect(find.byType(UserIcon), findsOneWidget, reason: 'it opened');

      await tester.tap(find.text('Toggle'));
      await tester.pumpAndSettle();
      expect(
        find.byType(UserIcon),
        findsNothing,
        reason: 'and it stayed shut rather than flickering back open',
      );
    });

    testWidgets('still scrolls while the group is open', (tester) async {
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
      await _open(tester);

      await tester.drag(find.byType(ListView), const Offset(0, -80));
      await tester.pumpAndSettle();
      expect(scroll.offset, closeTo(80, 1),
          reason: 'the drag reached the list through the barrier');
      expect(
        find.byType(UserIcon),
        findsOneWidget,
        reason: 'a drag is not a dismissing tap, so the group stayed open',
      );
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
