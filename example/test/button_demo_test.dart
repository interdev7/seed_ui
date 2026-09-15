import 'package:flutter/material.dart' as m;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seed_ui/seed_ui.dart';
import 'package:seed_ui_example/components/general/button_demo.dart';

void main() {
  testWidgets('every button in the demo builds', (tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ConfigProvider(
        child: m.MaterialApp(
          navigatorKey: UiKit.navigatorKey,
          home: const m.Scaffold(
            body: SingleChildScrollView(child: ButtonDemo()),
          ),
        ),
      ),
    );
    // Not pumpAndSettle: the page carries a loading button, and a spinner
    // never settles.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(tester.takeException(), isNull);
    expect(find.text('The words on a solid fill'), findsOneWidget);
    // The three ways of saying it: worked out, overruled for the theme, and
    // said on one label.
    expect(find.text('Pay now'), findsNWidgets(3));
    expect(find.text('Brown, on this one button'), findsOneWidget);
  });
}
