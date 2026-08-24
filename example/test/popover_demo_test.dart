import 'package:flutter/material.dart'
    hide ThemeData, Tooltip, Card, Drawer, Switch;
import 'package:flutter_test/flutter_test.dart';
import 'package:seed_ui/seed_ui.dart';

import 'package:seed_ui_example/components/data_display/popover_demo.dart';

Future<void> _pump(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1000, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  // The kit renders floating layers into one overlay, reached through this
  // key — the same wiring a real app does in main().
  await tester.pumpWidget(
    const ConfigProvider(
      child: MaterialApp(
        navigatorKey: UiKit.navigatorKey,
        home: Scaffold(body: SingleChildScrollView(child: PopoverDemo())),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a trigger opens its own card', (tester) async {
    await _pump(tester);

    expect(find.text('And tap again to put it away.'), findsNothing);
    await tester.tap(find.text('Tap me'));
    await tester.pumpAndSettle();
    expect(find.text('And tap again to put it away.'), findsOneWidget);

    // The caret is drawn pointing at the trigger.
    expect(find.byKey(const Key('softPopoverArrow')), findsOneWidget);

    // A tap outside puts it away again.
    await tester.tapAt(const Offset(900, 1300));
    await tester.pumpAndSettle();
    expect(find.text('And tap again to put it away.'), findsNothing);
  });

  testWidgets('every placement opens on screen', (tester) async {
    await _pump(tester);

    for (final placement in PopoverPlacement.values) {
      await tester.tap(find.text(placement.name));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open with the settings'));
      await tester.pumpAndSettle();

      final bubble = tester.getRect(find.text('placement: ${placement.name}'));
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
      expect(tester.takeException(), isNull, reason: placement.name);

      await tester.tapAt(const Offset(900, 1300));
      await tester.pumpAndSettle();
    }
  });

  testWidgets('the controlled one follows its switch', (tester) async {
    await _pump(tester);

    expect(find.text('Open while the switch is on.'), findsNothing);
    const key = Key('popoverControlledSwitch');
    await tester.tap(find.byKey(key));
    await tester.pumpAndSettle();
    expect(find.text('Open while the switch is on.'), findsOneWidget);

    await tester.tap(find.byKey(key));
    await tester.pumpAndSettle();
    expect(find.text('Open while the switch is on.'), findsNothing);
  });

  testWidgets('a barrier catches what is behind it', (tester) async {
    await _pump(tester);

    await tester.tap(find.text('Open over a barrier'));
    await tester.pumpAndSettle();
    expect(find.text('The page behind is dimmed and inert.'), findsOneWidget);

    await tester.tapAt(const Offset(900, 1300));
    await tester.pumpAndSettle();
    expect(find.text('The page behind is dimmed and inert.'), findsNothing);
  });

  testWidgets('a card you can act on', (tester) async {
    await _pump(tester);

    await tester.tap(find.text('Share'));
    await tester.pumpAndSettle();

    expect(find.text('Share this page'), findsOneWidget);
    await tester.tap(find.text('Like (0)'));
    await tester.pumpAndSettle();
    expect(
      find.text('Like (1)'),
      findsOneWidget,
      reason: 'the surface is interactive',
    );
  });
}
