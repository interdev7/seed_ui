import 'package:flutter/material.dart'
    hide ThemeData, Checkbox, Radio, RadioGroup, Switch, Tooltip, Drawer;
import 'package:flutter_test/flutter_test.dart';
import 'package:seed_ui/seed_ui.dart';
import 'package:seed_ui_example/components/data_entry/time_picker_demo.dart';

void main() {
  testWidgets('the TimePicker page builds, and its panel opens', (
    tester,
  ) async {
    await tester.pumpWidget(
      ConfigProvider(
        child: MaterialApp(
          navigatorKey: UiKit.navigatorKey,
          home: const Scaffold(
            body: SingleChildScrollView(child: TimePickerDemo()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    // Every group put a picker on the page.
    expect(find.byType(TimePicker), findsWidgets);

    await tester.tap(find.byType(TimePicker).first);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Now'), findsOneWidget);
  });

  testWidgets('the page lays out on a narrow screen too', (tester) async {
    // The pickers size themselves, so a row of them overflows once the page
    // is narrow enough — which is what Wrap is for. A phone-width pass is the
    // only way that shows up before it reaches a screen.
    tester.view.physicalSize = const Size(400, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ConfigProvider(
        child: MaterialApp(
          navigatorKey: UiKit.navigatorKey,
          home: const Scaffold(
            body: SingleChildScrollView(child: TimePickerDemo()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
