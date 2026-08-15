import 'package:flutter/material.dart'
    hide ThemeData, Checkbox, Radio, RadioGroup, Switch, Tooltip, Drawer;
import 'package:flutter_test/flutter_test.dart';
import 'package:seed_ui/seed_ui.dart';

Widget _host(Widget child) => MaterialApp(
      home: Scaffold(body: Center(child: child)),
    );

void main() {
  testWidgets('tapping toggles and reports the new value', (tester) async {
    bool? seen;
    await tester.pumpWidget(
      _host(
        Switch(value: false, onChanged: (v) => seen = v),
      ),
    );

    await tester.tap(find.byType(Switch));
    expect(seen, isTrue);
  });

  testWidgets('reports false when toggled off', (tester) async {
    bool? seen;
    await tester.pumpWidget(
      _host(
        Switch(value: true, onChanged: (v) => seen = v),
      ),
    );

    await tester.tap(find.byType(Switch));
    expect(seen, isFalse);
  });

  testWidgets('disabled does not toggle', (tester) async {
    var calls = 0;
    await tester.pumpWidget(
      _host(
        Switch(value: false, disabled: true, onChanged: (_) => calls++),
      ),
    );

    await tester.tap(find.byType(Switch));
    expect(calls, 0);
  });

  testWidgets('loading blocks toggling and shows a spinner', (tester) async {
    var calls = 0;
    await tester.pumpWidget(
      _host(
        Switch(value: false, loading: true, onChanged: (_) => calls++),
      ),
    );

    expect(find.byType(Spinner), findsOneWidget);
    await tester.tap(find.byType(Switch));
    expect(calls, 0);
  });

  testWidgets('a null onChanged is inert', (tester) async {
    await tester.pumpWidget(_host(const Switch(value: true)));
    await tester.tap(find.byType(Switch));
    await tester.pump();
  });

  testWidgets('renders checked and unchecked labels', (tester) async {
    await tester.pumpWidget(
      _host(
        Switch(
          value: true,
          onChanged: (_) {},
          checkedChild: const Text('ON'),
          uncheckedChild: const Text('OFF'),
        ),
      ),
    );

    expect(find.text('ON'), findsOneWidget);
  });
}
