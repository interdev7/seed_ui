import 'package:flutter/material.dart'
    hide ThemeData, Checkbox, Radio, RadioGroup, Switch, Tooltip, Drawer, Card;
import 'package:flutter_test/flutter_test.dart';
import 'package:seed_ui/seed_ui.dart';

/// A trigger with a layer whose content reads changing state.
class _Host extends StatefulWidget {
  const _Host({super.key, this.placement = PopoverPlacement.top});

  final PopoverPlacement placement;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  bool open = false;
  int count = 0;

  @override
  Widget build(BuildContext context) {
    final t = context.softToken;
    return ConfigProvider(
      child: MaterialApp(
        navigatorKey: UiKit.navigatorKey,
        home: Scaffold(
          body: Center(
            child: PopoverLayer(
              open: open,
              placement: widget.placement,
              onOpenChanged: (v) => setState(() => open = v),
              arrowColor: t.colorBgElevated,
              content: (context) => Container(
                color: t.colorBgElevated,
                padding: const EdgeInsets.all(12),
                child: DefaultTextStyle(
                  style: TextStyle(color: t.colorText, fontSize: t.fontSize),
                  child: GestureDetector(
                    onTap: () => setState(() => count++),
                    child: Text('count $count'),
                  ),
                ),
              ),
              child: GestureDetector(
                onTap: () => setState(() => open = !open),
                child: const Text('trigger'),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

void main() {
  testWidgets('it opens only when told to: there is no trigger of its own',
      (tester) async {
    await tester.pumpWidget(const _Host());
    await tester.pumpAndSettle();
    expect(find.text('count 0'), findsNothing);

    // The caller owns the gesture — Tooltip binds hover to it, Dropdown a tap.
    await tester.tap(find.text('trigger'));
    await tester.pumpAndSettle();
    expect(find.text('count 0'), findsOneWidget);
  });

  testWidgets('an open popover follows the state its content reads',
      (tester) async {
    await tester.pumpWidget(const _Host());
    await tester.pumpAndSettle();
    await tester.tap(find.text('trigger'));
    await tester.pumpAndSettle();

    // Tapping inside changes the page's state; the surface is in an overlay,
    // which a rebuild of the page does not reach — it used to sit there stale.
    await tester.tap(find.text('count 0'));
    await tester.pumpAndSettle();
    expect(find.text('count 1'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a tap outside puts it away', (tester) async {
    await tester.pumpWidget(const _Host());
    await tester.pumpAndSettle();
    await tester.tap(find.text('trigger'));
    await tester.pumpAndSettle();

    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();
    expect(find.text('count 0'), findsNothing);
  });

  testWidgets('every placement puts the surface on screen', (tester) async {
    for (final placement in PopoverPlacement.values) {
      // A fresh key each time, or the state — including whether it is open —
      // is carried over from the placement before.
      await tester.pumpWidget(
        _Host(key: ValueKey<PopoverPlacement>(placement), placement: placement),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('trigger'));
      await tester.pumpAndSettle();

      final bubble = tester.getRect(find.text('count 0'));
      final screen = tester.getRect(find.byType(MaterialApp));
      expect(
        bubble.left,
        greaterThanOrEqualTo(screen.left - 0.5),
        reason: placement.name,
      );
      expect(
        bubble.right,
        lessThanOrEqualTo(screen.right + 0.5),
        reason: placement.name,
      );
      expect(
        bubble.top,
        greaterThanOrEqualTo(screen.top - 0.5),
        reason: placement.name,
      );
      expect(
        bubble.bottom,
        lessThanOrEqualTo(screen.bottom + 0.5),
        reason: placement.name,
      );

      // Tear the page down between placements: an open surface outlives the
      // host it belongs to, and its own gestures would answer to a state that
      // is no longer there.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    }
  });

  group('a barrier that dims', () {
    Widget host({required VoidCallback onTap, required bool open}) =>
        ConfigProvider(
          child: MaterialApp(
            navigatorKey: UiKit.navigatorKey,
            home: Scaffold(
              body: Center(
                child: PopoverLayer(
                  open: open,
                  onOpenChanged: (_) {},
                  barrierColor: const Color(0x40000000),
                  content: (context) => const Text('the card'),
                  child: GestureDetector(
                    onTap: onTap,
                    child: const Text('the trigger'),
                  ),
                ),
              ),
            ),
          ),
        );

    testWidgets('dims the trigger along with the rest of the page',
        (tester) async {
      await tester.pumpWidget(host(onTap: () {}, open: true));
      await tester.pumpAndSettle();

      final wash = tester.getRect(find.byType(ColoredBox).last);
      final trigger = tester.getRect(find.text('the trigger'));
      // The dimming is one piece across the page, the trigger included: a lit
      // rectangle over a dimmed page reads as a mistake.
      expect(wash.contains(trigger.center), isTrue);
      expect(
        tester.widget<ColoredBox>(find.byType(ColoredBox).last).color,
        const Color(0x40000000),
      );
    });

    testWidgets('lets a tap through to the trigger under it', (tester) async {
      var taps = 0;
      await tester.pumpWidget(host(onTap: () => taps++, open: true));
      await tester.pumpAndSettle();
      await tester.tap(find.text('the trigger'), warnIfMissed: false);
      await tester.pumpAndSettle();
      // The hole is about the hand: the trigger stays live while the card is
      // open, dimmed or not.
      expect(taps, 1);
    });
  });
}
