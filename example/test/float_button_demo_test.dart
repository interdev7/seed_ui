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

void main() {
  testWidgets('the layout picker changes how the group opens', (tester) async {
    await _pump(tester);

    // The stage under 'Layouts' starts on the fan.
    final stage = find.byType(FloatButtonGroup).first;
    final trigger = tester.getCenter(stage);
    await tester.tap(stage);
    await tester.pumpAndSettle();

    // The button, not its label: in a column the label hangs off to the side,
    // so measuring the text would be measuring the wrong thing.
    Offset centreOf(String name) => tester.getCenter(
      find.ancestor(of: find.text(name), matching: find.byType(FloatButton)),
    );
    double xOf(String name) => centreOf(name).dx;
    final fan = centreOf('Edit');
    expect(
      (fan - trigger).distance,
      greaterThan(40),
      reason: 'the item travelled out of the trigger',
    );
    expect(
      xOf('Edit'),
      isNot(closeTo(xOf('Bin'), 1)),
      reason: 'an arc spreads its items across, not in a line',
    );

    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();

    await tester.tap(find.text('vertical'));
    await tester.pumpAndSettle();
    await tester.tap(stage);
    await tester.pumpAndSettle();

    // A column stands squarely over the trigger; the fan did not.
    expect(centreOf('Edit'), isNot(fan));
    expect(xOf('Edit'), closeTo(trigger.dx, 1));
    expect(xOf('Bin'), closeTo(trigger.dx, 1));
  });

  testWidgets('the outside button drives its group', (tester) async {
    await _pump(tester);

    await tester.tap(find.text('Open it'));
    await tester.pumpAndSettle();
    expect(find.text('Close it'), findsOneWidget);

    await tester.tap(find.text('Close it'));
    await tester.pumpAndSettle();
    expect(find.text('Open it'), findsOneWidget);
  });
}
