import 'package:flutter/material.dart'
    hide Badge, ThemeData, Tooltip, Card, Drawer, Switch;
import 'package:flutter_test/flutter_test.dart';
import 'package:seed_ui/seed_ui.dart';
import 'package:seed_ui_example/components/general/float_button_demo.dart';

Future<void> _pump(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1000, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ConfigProvider(
      child: MaterialApp(
        navigatorKey: UiKit.navigatorKey,
        home: const Scaffold(
          body: SingleChildScrollView(child: FloatButtonDemo()),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// The button, not its label: in a column the label hangs off to the side, so
/// measuring the text would be measuring the wrong thing.
Offset _centreOf(WidgetTester tester, String name) => tester.getCenter(
  find.ancestor(of: find.text(name), matching: find.byType(FloatButton)),
);

void main() {
  testWidgets('the layout picker changes how the group opens', (tester) async {
    await _pump(tester);

    final stage = find.byType(FloatButtonGroup<FabAction>).first;
    final trigger = tester.getCenter(stage);
    await tester.tap(stage);
    await tester.pumpAndSettle();

    final fan = _centreOf(tester, 'Edit');
    expect(
      (fan - trigger).distance,
      greaterThan(40),
      reason: 'the item travelled out of the trigger',
    );
    expect(
      _centreOf(tester, 'Edit').dx,
      isNot(closeTo(_centreOf(tester, 'Delete').dx, 1)),
      reason: 'an arc spreads its items across, not in a line',
    );

    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();

    await tester.tap(find.text('vertical'));
    await tester.pumpAndSettle();
    await tester.tap(stage);
    await tester.pumpAndSettle();

    // A column stands squarely over the trigger; the fan did not.
    expect(_centreOf(tester, 'Edit'), isNot(fan));
    expect(_centreOf(tester, 'Edit').dx, closeTo(trigger.dx, 1));
    expect(_centreOf(tester, 'Delete').dx, closeTo(trigger.dx, 1));
  });

  testWidgets('a tapped item is reported back to the page', (tester) async {
    await _pump(tester);

    expect(find.textContaining('Last tapped'), findsNothing);
    await tester.tap(find.byType(FloatButtonGroup<FabAction>).first);
    await tester.pumpAndSettle();

    // The label sits in an IgnorePointer — it names the button, it is not
    // the button — so the tap goes to the button itself.
    await tester.tap(
      find.ancestor(of: find.text('Share'), matching: find.byType(FloatButton)),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Last tapped: share'), findsOneWidget);
  });

  testWidgets('the curve picker changes how the items travel', (tester) async {
    await _pump(tester);

    Future<double> travelAtHalfway(String curve) async {
      await tester.tap(find.text(curve));
      await tester.pumpAndSettle();
      final stage = find.byType(FloatButtonGroup<FabAction>).first;
      final trigger = tester.getCenter(stage);
      await tester.tap(stage);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      final travelled = (_centreOf(tester, 'Edit') - trigger).distance;
      await tester.tapAt(const Offset(20, 20));
      await tester.pumpAndSettle();
      return travelled;
    }

    // Halfway through, a linear opening has covered less ground than one that
    // eases out.
    expect(
      await travelAtHalfway('easeOut'),
      greaterThan(await travelAtHalfway('linear')),
    );
  });

  testWidgets('the controller opens and closes its own group', (tester) async {
    await _pump(tester);

    final group = find.byType(FloatButtonGroup<FabAction>).at(1);
    await tester.ensureVisible(find.text('Toggle'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(tester.widgetList(find.byType(FloatButton)).length, greaterThan(1));

    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    expect(group, findsOneWidget);
  });
}
