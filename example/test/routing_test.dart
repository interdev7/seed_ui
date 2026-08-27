import 'package:flutter/material.dart'
    hide ThemeData, Checkbox, Radio, RadioGroup, Switch, Tooltip, Drawer;
import 'package:flutter_test/flutter_test.dart';
import 'package:seed_ui_example/main.dart';

/// The gallery always has something animating — a spinner, a countdown — so
/// `pumpAndSettle` never returns. A few frames are enough to route.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  testWidgets('a demo page has home beneath it, so Back returns there', (
    tester,
  ) async {
    // The demo routes are children of home, not siblings: as siblings, `go`
    // replaced the stack and the system Back left the app.
    await tester.pumpWidget(const DemoApp());
    await _settle(tester);

    await tester.tap(find.text('Button').first);
    await _settle(tester);
    expect(find.text('Button'), findsWidgets, reason: 'the demo opened');

    final context = tester.element(find.byType(Navigator).last);
    expect(
      Navigator.of(context).canPop(),
      isTrue,
      reason: 'nothing to pop back to means Back leaves the app',
    );

    Navigator.of(context).pop();
    await _settle(tester);
    expect(find.text('New Year Theme 🎄'), findsOneWidget, reason: 'home');
  });

  testWidgets('a demo opened cold can still go back', (tester) async {
    // A deep link has no history of its own; the branch is what gives it one.
    await tester.pumpWidget(const DemoApp(initialLocation: '/demo/button'));
    await _settle(tester);

    final context = tester.element(find.byType(Navigator).last);
    expect(Navigator.of(context).canPop(), isTrue);

    Navigator.of(context).pop();
    await _settle(tester);
    expect(find.text('New Year Theme 🎄'), findsOneWidget);
  });
}
